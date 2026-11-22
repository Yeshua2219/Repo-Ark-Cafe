import 'package:flutter/material.dart';

class IncomingOrdersScreen extends StatelessWidget {
  const IncomingOrdersScreen({
    super.key,
    this.orders,
    this.isLoading = false,
  });

  static const routeName = '/employee-incoming-orders';
  static final sampleOrders = [
    IncomingOrder(
      number: '1042',
      customerName: 'Mia Santos',
      orderedAt: DateTime.now().subtract(const Duration(minutes: 8)),
      status: 'Preparing',
      items: const [
        OrderedProduct(name: 'Cappuccino', quantity: 1, unitPrice: 145),
        OrderedProduct(name: 'Butter croissant', quantity: 2, unitPrice: 90),
      ],
    ),
    IncomingOrder(
      number: '1041',
      customerName: 'Paolo Reyes',
      orderedAt: DateTime.now().subtract(const Duration(minutes: 17)),
      status: 'Pending',
      items: const [
        OrderedProduct(name: 'Iced Spanish latte', quantity: 2, unitPrice: 165),
        OrderedProduct(name: 'Banana bread', quantity: 1, unitPrice: 110),
      ],
    ),
    IncomingOrder(
      number: '1040',
      customerName: 'Andrea Lim',
      orderedAt: DateTime.now().subtract(const Duration(minutes: 31)),
      status: 'Ready',
      items: const [
        OrderedProduct(name: 'Matcha latte', quantity: 1, unitPrice: 175),
        OrderedProduct(name: 'Tuna melt', quantity: 1, unitPrice: 210),
      ],
    ),
  ];

  final List<IncomingOrder>? orders;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final visibleOrders = orders ?? sampleOrders;

    return Scaffold(
      appBar: AppBar(title: const Text('Incoming orders')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: _buildContent(context, visibleOrders),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, List<IncomingOrder> visibleOrders) {
    if (isLoading) {
      return const _OrdersState(
        icon: null,
        message: 'Loading sample orders...',
        isLoading: true,
      );
    }

    if (visibleOrders.isEmpty) {
      return const _OrdersState(
        icon: Icons.receipt_long_outlined,
        message: 'There are no sample orders to display.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SampleDataNotice(),
        const SizedBox(height: 12),
        for (final order in visibleOrders)
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
    required this.number,
    required this.customerName,
    required this.orderedAt,
    required this.status,
    required this.items,
  });

  final String number;
  final String customerName;
  final DateTime orderedAt;
  final String status;
  final List<OrderedProduct> items;

  double get total =>
      items.fold(0, (sum, item) => sum + item.quantity * item.unitPrice);

  IncomingOrder copyWith({String? status}) => IncomingOrder(
        number: number,
        customerName: customerName,
        orderedAt: orderedAt,
        status: status ?? this.status,
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
    final background = switch (status) {
      'Pending' => colors.primaryContainer,
      'Ready' => colors.tertiaryContainer,
      'Cancelled' => colors.errorContainer,
      'Completed' => colors.surfaceContainerHighest,
      _ => colors.secondaryContainer,
    };
    final foreground = switch (status) {
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
        status,
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
                const SizedBox(height: 16),
                Text(
                  'Sample order · Not connected to live order data',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
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
