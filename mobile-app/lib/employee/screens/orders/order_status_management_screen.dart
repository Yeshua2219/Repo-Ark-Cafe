import 'package:material_ui/material_ui.dart';

import '../../employee_api.dart';
import '../login/employee_login_screen.dart';
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
  final EmployeeApi _api = EmployeeApi();
  List<IncomingOrder> _orders = [];
  bool _loading = false;
  bool _saving = false;

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
    setState(() => _loading = true);
    try {
      final list = await _api.fetchOrders();
      if (!mounted) return;
      setState(() => _orders = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static List<String> _allowedNextStatuses(String currentStatus) {
    return switch (currentStatus) {
      'Pending' => ['Confirmed', 'Cancelled'],
      'Confirmed' => ['Preparing', 'Cancelled'],
      'Preparing' => ['Ready', 'Cancelled'],
      'Ready' => ['Completed', 'Cancelled'],
      'Completed' || 'Cancelled' => [],
      _ => ['Confirmed', 'Preparing', 'Ready', 'Completed', 'Cancelled'],
    };
  }

  void _showStatusOptions(int orderIndex) {
    if (_saving) return;
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
        content: Text('Update status from ${order.status} to $nextStatus?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep current status'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm update'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    if (!_isAuthenticated) {
      setState(() {
        _orders[orderIndex] = _orders[orderIndex].copyWith(status: nextStatus);
      });
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = await _api.updateOrderStatus(order.id, nextStatus);
      if (!mounted) return;
      setState(() => _orders[orderIndex] = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #${order.number} updated to ${updated.status}.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.isLoading || _loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order status management'),
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
          constraints: const BoxConstraints(maxWidth: 800),
          child: _buildContent(busy),
        ),
      ),
    );
  }

  Widget _buildContent(bool busy) {
    if (busy) {
      return const _OrderStatusState(
        message: 'Loading orders...',
        isLoading: true,
      );
    }

    if (_orders.isEmpty) {
      return const _OrderStatusState(
        icon: Icons.receipt_long_outlined,
        message: 'There are no orders to manage.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!_isAuthenticated && widget.orders == null) ...[
          const _SampleStatusNotice(),
          const SizedBox(height: 12),
        ],
        for (var index = 0; index < _orders.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OrderStatusCard(
              order: _orders[index],
              disabled: _saving,
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
              'SAMPLE ORDERS · Local preview mode.',
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
    required this.disabled,
    required this.onUpdateStatus,
  });

  final IncomingOrder order;
  final bool disabled;
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
                  onPressed: disabled ? null : onUpdateStatus,
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