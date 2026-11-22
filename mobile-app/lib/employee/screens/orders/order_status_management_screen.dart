import 'package:flutter/material.dart';

import 'incoming_orders_screen.dart';

class OrderStatusManagementScreen extends StatefulWidget {
  const OrderStatusManagementScreen({
    super.key,
    this.orders,
    this.isLoading = false,
  });

  static const routeName = '/employee-order-statuses';

  final List<IncomingOrder>? orders;
  final bool isLoading;

  @override
  State<OrderStatusManagementScreen> createState() =>
      _OrderStatusManagementScreenState();
}

class _OrderStatusManagementScreenState
    extends State<OrderStatusManagementScreen> {
  late final List<IncomingOrder> _orders =
      widget.orders ?? IncomingOrdersScreen.sampleOrders;

  static List<String> _allowedNextStatuses(String currentStatus) {
    return switch (currentStatus) {
      'Pending' => ['Confirmed', 'Cancelled'],
      'Confirmed' => ['Preparing', 'Cancelled'],
      'Preparing' => ['Ready', 'Cancelled'],
      'Ready' => ['Completed', 'Cancelled'],
      'Completed' || 'Cancelled' => [],
      _ => [],
    };
  }

  void _showStatusOptions(int orderIndex) {
    final order = _orders[orderIndex];
    final nextStatuses = _allowedNextStatuses(order.status);

    if (nextStatuses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #${order.number} is in a final status.'),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Update order #${order.number}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text('Current status: ${order.status}'),
              const SizedBox(height: 12),
              for (final status in nextStatuses)
                ListTile(
                  leading: const Icon(Icons.arrow_forward),
                  title: Text(status),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmStatusUpdate(orderIndex, status);
                  },
                ),
              const SizedBox(height: 4),
              Text(
                'Only valid next statuses are shown. Changes are sample data '
                'and are not sent to the backend.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmStatusUpdate(int orderIndex, String nextStatus) async {
    final order = _orders[orderIndex];
    if (!_allowedNextStatuses(order.status).contains(nextStatus)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Change order #${order.number}?'),
        content: Text(
          'Update status from ${order.status} to $nextStatus? '
          'This changes sample data in this app session only; nothing is '
          'saved to the backend.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep current status'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm demo update'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    if (!_allowedNextStatuses(_orders[orderIndex].status)
        .contains(nextStatus)) {
      return;
    }

    setState(() {
      _orders[orderIndex] = _orders[orderIndex].copyWith(status: nextStatus);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Demo update: order #${order.number} is now $nextStatus. '
          'Not saved to the backend.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order status management')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return const _OrderStatusState(
        message: 'Loading sample orders...',
        isLoading: true,
      );
    }

    if (_orders.isEmpty) {
      return const _OrderStatusState(
        icon: Icons.receipt_long_outlined,
        message: 'There are no sample orders to manage.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SampleStatusNotice(),
        const SizedBox(height: 12),
        for (var index = 0; index < _orders.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OrderStatusCard(
              order: _orders[index],
              onUpdateStatus: () => _showStatusOptions(index),
            ),
          ),
      ],
    );
  }
}

class _SampleStatusNotice extends StatelessWidget {
  const _SampleStatusNotice();

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
              'SAMPLE ORDERS · Status changes are local demo updates only; '
              'they are not saved to the backend.',
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

class _OrderStatusCard extends StatelessWidget {
  const _OrderStatusCard({
    required this.order,
    required this.onUpdateStatus,
  });

  final IncomingOrder order;
  final VoidCallback onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isFinalStatus =
        order.status == 'Completed' || order.status == 'Cancelled';

    return Card(
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
            const SizedBox(height: 12),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${item.quantity} × ${item.name}'),
              ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total',
                    style: textTheme.bodyMedium,
                  ),
                ),
                Text(
                  _money(order.total),
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isFinalStatus)
              Text(
                'Final status · no further updates available',
                textAlign: TextAlign.end,
                style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: onUpdateStatus,
                  icon: const Icon(Icons.sync_alt),
                  label: const Text('Update status'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderStatusState extends StatelessWidget {
  const _OrderStatusState({
    required this.message,
    this.icon,
    this.isLoading = false,
  });

  final String message;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const CircularProgressIndicator()
            else
              Icon(
                icon,
                size: 44,
                color: Theme.of(context).colorScheme.primary,
              ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _money(num amount) => '₱${amount.toStringAsFixed(2)}';
