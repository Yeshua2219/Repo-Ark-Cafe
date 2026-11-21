import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared ARK Cafe design-system colors supplied by the project team.
class ArkColors {
  static const darkBrown = Color(0xFF392A23);
  static const coffeeBrown = Color(0xFF876447);
  static const warmBeige = Color(0xFFE8D7BD);
  static const cream = Color(0xFFF7F5F0);
  static const white = Color(0xFFFFFFFF);
  static const mutedBrown = Color(0xFF928478);
}

const _brown = ArkColors.coffeeBrown;

InputDecoration _arkField(String label, IconData icon, {String? hint}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: ArkColors.coffeeBrown),
      filled: true,
      fillColor: ArkColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ArkColors.warmBeige),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ArkColors.warmBeige),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ArkColors.coffeeBrown, width: 2),
      ),
    );

RoundedRectangleBorder _arkCardShape() => RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: ArkColors.warmBeige),
    );
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
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (path != '/products' && token != null) 'Authorization': 'Bearer $token',
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
        scrollable: true,
        backgroundColor: ArkColors.cream,
        surfaceTintColor: ArkColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: ArkColors.darkBrown,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(children: [
                Icon(Icons.local_cafe_outlined,
                    color: ArkColors.warmBeige, size: 46),
                SizedBox(height: 10),
                Text('ARK CAFE', style: TextStyle(
                  color: ArkColors.white, fontWeight: FontWeight.bold,
                  fontSize: 25, letterSpacing: 3,
                )),
                SizedBox(height: 6),
                Text('CUSTOMER APP', style: TextStyle(
                  color: ArkColors.warmBeige, fontSize: 11, letterSpacing: 3,
                )),
              ]),
            ),
            const SizedBox(height: 22),
            const Text('CUSTOMER ACCESS', style: TextStyle(
              color: ArkColors.coffeeBrown, fontSize: 11,
              letterSpacing: 2, fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 8),
            Text(register ? 'Create your account' : 'Welcome back!',
              style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold,
                color: ArkColors.darkBrown,
              )),
            const SizedBox(height: 6),
            Text(register ? 'Join ARK Cafe to start ordering.'
                : 'Sign in to order your favorite coffee.',
              style: const TextStyle(
                fontSize: 14, color: ArkColors.coffeeBrown,
              )),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (register) ...[
                TextField(controller: name,
                  decoration: _arkField('Full name', Icons.person_outline)),
                const SizedBox(height: 14),
              ],
              TextField(controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: _arkField('Email address', Icons.email_outlined)),
              const SizedBox(height: 14),
              TextField(controller: password, obscureText: true,
                decoration: _arkField('Password', Icons.lock_outline)),
            ],
          ),
        ),
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
    appBar: AppBar(
      backgroundColor: ArkColors.darkBrown,
      foregroundColor: ArkColors.white,
      title: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.local_cafe_outlined, color: ArkColors.warmBeige, size: 30),
        SizedBox(width: 10),
        Text('ARK CAFE', style: TextStyle(
          letterSpacing: 2, fontSize: 18, fontWeight: FontWeight.bold,
        )),
      ]),
      actions: [
        if (auth.currentUser == null) ...[
          TextButton(onPressed: () => signIn(false),
            style: TextButton.styleFrom(foregroundColor: ArkColors.white),
            child: const Text('Login')),
          TextButton(onPressed: () => signIn(true),
            style: TextButton.styleFrom(foregroundColor: ArkColors.warmBeige),
            child: const Text('Join')),
        ] else IconButton(
          tooltip: 'Account',
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () => setState(() => tab = 3)),
        const SizedBox(width: 8),
      ]),
    body: SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: IndexedStack(index: tab, children: [
            menuScreen(),
            cartScreen(),
            ordersScreen(),
            profileScreen(),
          ]),
        ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      backgroundColor: ArkColors.white,
      indicatorColor: ArkColors.warmBeige,
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20), children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ArkColors.darkBrown,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.local_cafe_outlined,
                color: ArkColors.warmBeige, size: 34),
              SizedBox(height: 16),
              Text('WELCOME TO ARK CAFE', style: TextStyle(
                fontSize: 11, letterSpacing: 2,
                fontWeight: FontWeight.w600, color: ArkColors.warmBeige,
              )),
              SizedBox(height: 8),
              Text('Find your next favorite', style: TextStyle(
                fontSize: 25, fontWeight: FontWeight.bold,
                color: ArkColors.white,
              )),
              SizedBox(height: 8),
              Text('Explore the menu and order your favorites.',
                style: TextStyle(color: ArkColors.warmBeige, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(children: [
          const Expanded(child: Text('Our menu', style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold,
            color: ArkColors.darkBrown,
          ))),
          IconButton(
            tooltip: 'Refresh menu',
            onPressed: loading ? null : refreshMenu,
            icon: const Icon(Icons.refresh, color: ArkColors.coffeeBrown),
          ),
        ]),
        const SizedBox(height: 12),
        TextField(onChanged: (s) => setState(() => search = s),
          decoration: _arkField('Search the menu', Icons.search)),
        const SizedBox(height: 12),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
          children: categories.map((c) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(label: Text(c), selected: category == c,
              selectedColor: ArkColors.warmBeige,
              backgroundColor: ArkColors.white,
              labelStyle: const TextStyle(color: ArkColors.darkBrown),
              onSelected: (_) => setState(() => category = c)))).toList())),
        const SizedBox(height: 16),
        if (loading) const Center(child: CircularProgressIndicator()),
        if (!loading && error != null)
          Card(
            color: ArkColors.white,
            elevation: 0,
            shape: _arkCardShape(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Menu unavailable', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: ArkColors.darkBrown,
                  )),
                  const SizedBox(height: 8),
                  const Text('Check that the ARK Cafe backend is running, then try again.'),
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 14),
                  OutlinedButton(onPressed: refreshMenu,
                    child: const Text('Try again')),
                ],
              ),
            ),
          ),
        if (!loading && error == null && filtered.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No matching menu items.'))),
        for (final product in filtered) Card(color: ArkColors.white, elevation: 0,
          shape: _arkCardShape(), child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: ArkColors.warmBeige,
            foregroundColor: ArkColors.darkBrown,
            child: Icon(Icons.coffee),
          ),
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
      for (final item in cart) Card(color: ArkColors.white, elevation: 0,
          shape: _arkCardShape(), child: ListTile(
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
        if (raw is Map) Card(color: ArkColors.white, elevation: 0,
          shape: _arkCardShape(), child: ListTile(
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
      const Text('Your account', style: TextStyle(
        fontSize: 25, fontWeight: FontWeight.bold,
        color: ArkColors.darkBrown,
      )),
      const SizedBox(height: 16),
      Card(
        color: ArkColors.white,
        elevation: 0,
        shape: _arkCardShape(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const CircleAvatar(
              radius: 34, backgroundColor: ArkColors.warmBeige,
              foregroundColor: ArkColors.darkBrown,
              child: Icon(Icons.person_outline, size: 38),
            ),
            const SizedBox(height: 12),
            Text(auth.currentUser?.email ?? 'Guest account',
              textAlign: TextAlign.center, style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold,
                color: ArkColors.darkBrown,
              )),
            const SizedBox(height: 8),
            Text(auth.currentUser == null
              ? 'Sign in to place orders and view your history.'
              : 'Manage your ARK Cafe customer account.',
              textAlign: TextAlign.center),
          ]),
        ),
      ),
      const SizedBox(height: 18),
      if (auth.currentUser == null) ...[
        FilledButton(onPressed: () => signIn(false),
          child: const Text('Sign in')),
        const SizedBox(height: 12),
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
