import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

const _brown = Color(0xFF79513B);
String money(num value) => '₱${value.toStringAsFixed(2)}';

class Product {
  Product(this.id, this.name, this.description, this.price, this.category);
  final int id;
  final String name, description, category;
  final double price;
  factory Product.fromJson(Map<String, dynamic> j) => Product(
    (j['id'] as num).toInt(),
    j['name']?.toString() ?? 'Product',
    j['description']?.toString() ?? '',
    double.tryParse(j['price'].toString()) ?? 0,
    j['categories'] is Map
      ? j['categories']['name']?.toString() ?? 'Other' : 'Other',
  );
}
class CartItem {
  CartItem(this.product, this.note, [this.quantity = 1]);
  final Product product;
  final String note;
  int quantity;
  double get subtotal => product.price * quantity;
}
class Api {
  static const base = String.fromEnvironment('API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api');
  static Future<dynamic> request(String path, {Object? body}) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final uri = Uri.parse('$base$path');
    final response = await (body == null
      ? http.get(uri, headers: headers)
      : http.post(uri, headers: headers, body: jsonEncode(body)))
      .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 404 || response.statusCode == 405) {
        throw Exception('Backend endpoint not implemented: $path');
      }
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body);
  }
  static Future<List<Product>> menu() async {
    final data = await request('/products') as List;
    return data.map((j) => Product.fromJson(
      Map<String, dynamic>.from(j as Map))).toList();
  }
  // Backend must authenticate, check ownership and recompute totals.
  static Future<int> placeOrder(List<CartItem> lines, String method) async {
    final data = await request('/orders', body: {
      'payment_method': method,
      'items': lines.map((line) => {
        'product_id': line.product.id,
        'quantity': line.quantity,
        'customization': line.note,
      }).toList(),
    }) as Map;
    final order = data['order'] is Map ? data['order'] as Map : data;
    return (order['id'] as num).toInt();
  }
  // Must only return orders owned by token's authenticated customer.
  static Future<List<dynamic>> history() async =>
    await request('/orders/mine') as List;
}

class CustomerApp extends StatefulWidget {
  const CustomerApp({super.key});
  @override
  State<CustomerApp> createState() => _CustomerAppState();
}
class _CustomerAppState extends State<CustomerApp> {
  final auth = Supabase.instance.client.auth;
  final cart = <CartItem>[];
  int tab = 0;
  String category = 'All';
  String search = '';
  List<Product> menu = [];
  bool loading = false;
  String? error;
  List<dynamic> orders = [];
  bool fetchingOrders = false;

  @override
  void initState() {
    super.initState();
    auth.onAuthStateChange.listen((_) { if (mounted) setState(() {}); });
    refreshMenu();
  }
  Future<void> refreshMenu() async {
    setState(() { loading = true; error = null; });
    try {
      final result = await Api.menu();
      if (mounted) setState(() { menu = result; });
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); });
    } finally {
      if (mounted) setState(() { loading = false; });
    }
  }
  Future<void> refreshOrders() async {
    if (auth.currentUser == null) return;
    setState(() => fetchingOrders = true);
    try {
      final data = await Api.history();
      if (mounted) setState(() => orders = data);
    } catch (e) {
      if (mounted) message(e.toString());
    } finally {
      if (mounted) setState(() => fetchingOrders = false);
    }
  }
  void message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
  Future<void> signIn(bool register) async {
    final email = TextEditingController();
    final password = TextEditingController();
    final name = TextEditingController();
    bool busy = false;
    await showDialog<void>(context: context, builder: (dialogContext) =>
      StatefulBuilder(builder: (dialogContext, update) => AlertDialog(
        title: Text(register ? 'Create customer account' : 'Customer login'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
          children: [
            if (register) TextField(controller: name,
              decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 12),
            TextField(controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: password, obscureText: true,
              decoration: const InputDecoration(labelText: 'Password')),
          ])),
        actions: [
          TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext),
            child: const Text('Cancel')),
          FilledButton(onPressed: busy ? null : () async {
            if (!email.text.contains('@') || password.text.length < 6 ||
                (register && name.text.trim().isEmpty)) {
              message('Enter valid account details (password: 6+ characters).');
              return;
            }
            update(() => busy = true);
            try {
              if (register) {
                await auth.signUp(
                  email: email.text.trim(),
                  password: password.text,
                  data: {'full_name': name.text.trim()},
                );
              } else {
                await auth.signInWithPassword(
                  email: email.text.trim(), password: password.text);
              }
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              message(register ? 'Registration submitted. Confirm email if required.'
                : 'Signed in.');
              setState(() {});
            } catch (e) { message('Authentication failed: $e'); }
            finally { if (dialogContext.mounted) update(() => busy = false); }
          }, child: Text(register ? 'Register' : 'Login')),
        ],
      )));
    email.dispose(); password.dispose(); name.dispose();
  }
  void customize(Product product) {
    final note = TextEditingController();
    int quantity = 1;
    showDialog<void>(context: context, builder: (ctx) =>
      StatefulBuilder(builder: (ctx, update) => AlertDialog(
        title: Text(product.name),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(product.description.isEmpty ? 'Freshly prepared for you.'
            : product.description),
          const SizedBox(height: 12),
          Text(money(product.price), style: const TextStyle(
            fontWeight: FontWeight.bold, color: _brown, fontSize: 20)),
          const SizedBox(height: 12),
          TextField(controller: note, maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Customization / instructions',
              hintText: 'e.g. less sugar, no ice')),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(onPressed: quantity > 1
              ? () => update(() => quantity--) : null,
              icon: const Icon(Icons.remove_circle_outline)),
            Text('$quantity'),
            IconButton(onPressed: quantity < 30
              ? () => update(() => quantity++) : null,
              icon: const Icon(Icons.add_circle_outline)),
          ])
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel')),
          FilledButton(onPressed: () {
            setState(() {
              final existing = cart.where((e) => e.product.id == product.id &&
                e.note == note.text.trim()).toList();
              if (existing.isEmpty) {
                cart.add(CartItem(product, note.text.trim(), quantity));
              } else { existing.first.quantity += quantity; }
            });
            Navigator.pop(ctx);
            message('Added to cart');
          }, child: const Text('Add to cart')),
        ],
      )));
  }
  Future<void> checkout(String method) async {
    if (cart.isEmpty) return;
    if (auth.currentUser == null) {
      message('Please sign in before placing an order.');
      await signIn(false);
      return;
    }
    try {
      final id = await Api.placeOrder(cart, method);
      if (!mounted) return;
      setState(() { cart.clear(); tab = 2; });
      message('Order #$id submitted.');
      await refreshOrders();
    } catch (e) { if (mounted) message('Unable to place order: $e'); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('☕ ARK Cafe'),
      actions: [
        if (auth.currentUser == null) ...[
          TextButton(onPressed: () => signIn(false), child: const Text('Login')),
          TextButton(onPressed: () => signIn(true), child: const Text('Join')),
        ] else IconButton(
          tooltip: 'Account',
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () => setState(() => tab = 3)),
      ]),
    body: IndexedStack(index: tab, children: [
      menuScreen(),
      cartScreen(),
      ordersScreen(),
      profileScreen(),
    ]),
    bottomNavigationBar: NavigationBar(
      selectedIndex: tab,
      onDestinationSelected: (i) {
        setState(() => tab = i);
        if (i == 2) refreshOrders();
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.local_cafe_outlined), label: 'Menu'),
        NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), label: 'Cart'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    ),
  );
  Widget menuScreen() {
    final categories = ['All', ...menu.map((e) => e.category).toSet()];
    final filtered = menu.where((p) =>
      (category == 'All' || category == p.category) &&
      (p.name.toLowerCase().contains(search.toLowerCase()) ||
       p.description.toLowerCase().contains(search.toLowerCase()))).toList();
    return RefreshIndicator(onRefresh: refreshMenu, child: ListView(
      padding: const EdgeInsets.all(16), children: [
        const Text('Find your next favorite',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(onChanged: (s) => setState(() => search = s),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search), hintText: 'Search the menu',
            border: OutlineInputBorder())),
        const SizedBox(height: 12),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
          children: categories.map((c) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(label: Text(c), selected: category == c,
              onSelected: (_) => setState(() => category = c)))).toList())),
        const SizedBox(height: 16),
        if (loading) const Center(child: CircularProgressIndicator()),
        if (error != null) Text('Menu unavailable: $error'),
        if (!loading && error == null && filtered.isEmpty)
          const Text('No matching menu items.'),
        for (final product in filtered) Card(child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.coffee)),
          title: Text(product.name),
          subtitle: Text('${product.category} · ${product.description}'),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, children: [
              Text(money(product.price),
                style: const TextStyle(fontWeight: FontWeight.bold)),
              const Icon(Icons.add_circle_outline, color: _brown),
            ]),
          onTap: () => customize(product),
        )),
      ],
    ));
  }
  Widget cartScreen() {
    final total = cart.fold<double>(0, (sum, item) => sum + item.subtotal);
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Your cart', style: TextStyle(
        fontSize: 25, fontWeight: FontWeight.bold)),
      if (cart.isEmpty) const Padding(padding: EdgeInsets.all(32),
        child: Center(child: Text('Your cart is empty. Explore the menu!'))),
      for (final item in cart) Card(child: ListTile(
        title: Text(item.product.name),
        subtitle: Text('${item.note.isEmpty ? "No customization" : item.note}\n'
          '${money(item.subtotal)}'),
        isThreeLine: true,
        trailing: SizedBox(width: 116, child: Row(children: [
          IconButton(onPressed: () => setState(() {
            if (item.quantity == 1) { cart.remove(item); }
            else { item.quantity--; }
          }), icon: const Icon(Icons.remove_circle_outline)),
          Text('${item.quantity}'),
          IconButton(onPressed: item.quantity >= 30 ? null
            : () => setState(() => item.quantity++),
            icon: const Icon(Icons.add_circle_outline)),
        ])),
      )),
      const SizedBox(height: 16),
      Text('Estimated total: ${money(total)}',
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      const Text('Payment selection (no payment is processed in-app).'),
      const SizedBox(height: 8),
      FilledButton(onPressed: cart.isEmpty ? null : () => checkout('cash'),
        child: const Text('Place order · Pay cash')),
      OutlinedButton(onPressed: cart.isEmpty ? null : () => checkout('online'),
        child: const Text('Place order · Online payment pending verification')),
    ]);
  }
  Widget ordersScreen() => ListView(padding: const EdgeInsets.all(16),
    children: [
      Row(children: [
        const Expanded(child: Text('Order history', style: TextStyle(
          fontSize: 25, fontWeight: FontWeight.bold))),
        IconButton(onPressed: refreshOrders, icon: const Icon(Icons.refresh)),
      ]),
      if (auth.currentUser == null)
        const Text('Sign in to see your orders.'),
      if (fetchingOrders) const LinearProgressIndicator(),
      if (!fetchingOrders && orders.isEmpty && auth.currentUser != null)
        const Text('No orders loaded yet.'),
      for (final raw in orders)
        if (raw is Map) Card(child: ListTile(
          title: Text('Order #${raw["id"] ?? "?"}'),
          subtitle: Text('Status: ${raw["order_status"] ?? "Pending"}\n'
            'Payment: ${raw["payment_status"] ?? "Pending"}'),
          isThreeLine: true,
          trailing: Text(money(
            double.tryParse(raw['total_amount'].toString()) ?? 0)),
        )),
    ]);
  Widget profileScreen() => ListView(padding: const EdgeInsets.all(20),
    children: [
      const Icon(Icons.account_circle, size: 72, color: _brown),
      const SizedBox(height: 12),
      Text(auth.currentUser?.email ?? 'Guest account',
        textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 18),
      if (auth.currentUser == null) ...[
        FilledButton(onPressed: () => signIn(false),
          child: const Text('Sign in')),
        OutlinedButton(onPressed: () => signIn(true),
          child: const Text('Create account')),
      ] else ...[
        const Text('Manage your customer login and saved orders here.'),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: () async {
          await auth.signOut();
          if (mounted) setState(() { orders.clear(); tab = 0; });
        }, child: const Text('Sign out')),
      ],
    ]);
}
