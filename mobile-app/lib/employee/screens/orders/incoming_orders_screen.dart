import 'package:material_ui/material_ui.dart';

import '../../employee_api.dart';
import '../login/employee_login_screen.dart';

String _formatStatusLabel(String raw) {
  final clean = raw.trim();
  if (clean.isEmpty) return 'Pending';
  return clean[0].toUpperCase() + clean.substring(1).toLowerCase();
}

class IncomingOrdersScreen extends StatefulWidget {
  const IncomingOrdersScreen({
    super.key,
    this.orders,
    this.isLoading = false,
  });

  static const routeName = '/employee-incoming-orders';
  static final sampleOrders = [
    IncomingOrder(
      id: 1042,
      number: '1042',
      customerName: 'Mia Santos',
      orderedAt: DateTime.now().subtract(const Duration(minutes: 8)),
      status: 'Preparing',
      paymentMethod: 'cash',
      paymentStatus: 'paid',
      referenceNumber: 'CASH-1042',
      items: const [
        OrderedProduct(name: 'Cappuccino', quantity: 1, unitPrice: 145),
        OrderedProduct(name: 'Butter croissant', quantity: 2, unitPrice: 90),
      ],
    ),
  ];

  final List<IncomingOrder>? orders;
  final bool isLoading;

  @override
  State<IncomingOrdersScreen> createState() => _IncomingOrdersScreenState();
}

class _IncomingOrdersScreenState extends State<IncomingOrdersScreen> {
  final EmployeeApi _api = EmployeeApi();
  List<IncomingOrder> _orders = [];
  bool _loading = false;
  String? _error;

  bool get _isAuthenticated =>
      EmployeeSession.token != null && EmployeeSession.token!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.orders != null) {
      _orders = List.of(widget.orders!);
    } else if (_isAuthenticated) {
      _loadOrders();
    } else {
      _orders = List.of(IncomingOrdersScreen.sampleOrders);
    }
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.fetchOrders();
      if (!mounted) return;
      setState(() => _orders = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.isLoading || _loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming orders'),
        actions: [
          if (_isAuthenticated)
            IconButton(
              tooltip: 'Refresh',
              onPressed: busy ? null : _loadOrders,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: _buildContent(context, busy),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool busy) {
    if (busy) {
      return const _OrdersState(
        icon: null,
        message: 'Loading orders...',
        isLoading: true,
      );
    }

    if (_error != null) {
      return _OrdersState(
        icon: Icons.error_outline,
        message: _error!,
      );
    }

    if (_orders.isEmpty) {
      return const _OrdersState(
        icon: Icons.receipt_long_outlined,
        message: 'There are no orders to display.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!_isAuthenticated && widget.orders == null) ...[
          const _SampleDataNotice(),
          const SizedBox(height: 12),
        ],
        for (final order in _orders)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _IncomingOrderCard(
              order: order,
              onTap: () => _showOrderDetails(context, order),
            ),
          ),
      ],
    );
  }

  void _showOrderDetails(BuildContext context, IncomingOrder order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _OrderDetailsSheet(order: order),
    );
  }
}

class IncomingOrder {
  const IncomingOrder({
    this.id = 0,
    required this.number,
    required this.customerName,
    required this.orderedAt,
    required this.status,
    this.paymentMethod = 'cash',
    this.paymentStatus = 'pending',
    this.referenceNumber = '',
    this.serverTotal,
    required this.items,
  });

  final int id;
  final String number;
  final String customerName;
  final DateTime orderedAt;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String referenceNumber;
  final double? serverTotal;
  final List<OrderedProduct> items;

  double get total {
    if (serverTotal != null && serverTotal! > 0) return serverTotal!;
    return items.fold(0, (sum, item) => sum + item.quantity * item.unitPrice);
  }

  factory IncomingOrder.fromJson(Map<String, dynamic> json) {
    final rawId = (json['order_id'] ?? json['id'] ?? 0).toString();
    final parsedId = int.tryParse(rawId) ?? 0;
    final rawItems = json['items'] is List
        ? json['items'] as List
        : (json['order_items'] is List ? json['order_items'] as List : []);
    final payment = json['payment'] is Map ? json['payment'] as Map : null;

    return IncomingOrder(
      id: parsedId,
      number: rawId,
      customerName: (json['customer_name'] ?? 'Customer').toString(),
      orderedAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
              DateTime.now(),
      status: _formatStatusLabel((json['order_status'] ?? json['status'] ?? 'pending').toString()),
      paymentMethod: (json['payment_method'] ?? 'cash').toString(),
      paymentStatus: (payment?['verification_status'] ?? json['payment_status'] ?? 'pending').toString(),
      referenceNumber: (payment?['reference_number'] ?? 'Not provided').toString(),
      serverTotal: double.tryParse((json['total_amount'] ?? '').toString()),
      items: rawItems
          .whereType()
          .map((e) => OrderedProduct.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  IncomingOrder copyWith({
    String? status,
    String? paymentStatus,
  }) =>
      IncomingOrder(
        id: id,
        number: number,
        customerName: customerName,
        orderedAt: orderedAt,
        status: status ?? this.status,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        referenceNumber: referenceNumber,
        serverTotal: serverTotal,
        items: items,
      );
}

class OrderedProduct {
  const OrderedProduct({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String name;
  final int quantity;
  final double unitPrice;

  double get lineTotal => quantity * unitPrice;

  factory OrderedProduct.fromJson(Map<String, dynamic> json) {
    return OrderedProduct(
      name: (json['product_name'] ?? json['name'] ?? 'Item').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: double.tryParse(
            (json['unit_price'] ?? json['price'] ?? 0).toString(),
          ) ??
          0,
    );
  }
}

class _SampleDataNotice extends StatelessWidget {
  const _SampleDataNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: colors.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'SAMPLE ORDERS · For UI preview only; not live backend data.',
              style: TextStyle(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingOrderCard extends StatelessWidget {
  const _IncomingOrderCard({
    required this.order,
    required this.onTap,
  });

  final IncomingOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.number}',
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  OrderStatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                order.customerName,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              for (final item in order.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('${item.quantity} × ${item.name}'),
                ),
              const Divider(height: 20),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 8,
                children: [
                  _OrderDateTime(orderedAt: order.orderedAt),
                  Text(
                    _money(order.total),
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('View details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalized = _formatStatusLabel(status);
    final background = switch (normalized) {
      'Pending' => colors.primaryContainer,
      'Ready' => colors.tertiaryContainer,
      'Cancelled' => colors.errorContainer,
      'Completed' => colors.surfaceContainerHighest,
      _ => colors.secondaryContainer,
    };
    final foreground = switch (normalized) {
      'Pending' => colors.onPrimaryContainer,
      'Ready' => colors.onTertiaryContainer,
      'Cancelled' => colors.onErrorContainer,
      'Completed' => colors.onSurfaceVariant,
      _ => colors.onSecondaryContainer,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        normalized,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _OrderDateTime extends StatelessWidget {
  const _OrderDateTime({required this.orderedAt});

  final DateTime orderedAt;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(orderedAt);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(orderedAt),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );

    return Text(
      '$date · $time',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _OrderDetailsSheet extends StatelessWidget {
  const _OrderDetailsSheet({required this.order});

  final IncomingOrder order;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Order #${order.number}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    OrderStatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  label: 'Customer',
                  value: order.customerName,
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Order time',
                  value: _formatOrderDateTime(context, order.orderedAt),
                ),
                const SizedBox(height: 20),
                Text(
                  'Items',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${item.quantity} × ${item.name}'),
                        ),
                        Text(_money(item.lineTotal)),
                      ],
                    ),
                  ),
                const Divider(height: 28),
                _DetailRow(
                  label: 'Total',
                  value: _money(order.total),
                  emphasize: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        Text(value, style: style),
      ],
    );
  }
}

class _OrdersState extends StatelessWidget {
  const _OrdersState({
    required this.icon,
    required this.message,
    this.isLoading = false,
  });

  final IconData? icon;
  final String message;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const CircularProgressIndicator()
            else
              Icon(icon, size: 44, color: colors.primary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _formatOrderDateTime(BuildContext context, DateTime orderedAt) {
  final localizations = MaterialLocalizations.of(context);
  final date = localizations.formatMediumDate(orderedAt);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(orderedAt),
    alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
  );
  return '$date · $time';
}

String _money(num amount) => '₱${amount.toStringAsFixed(2)}';