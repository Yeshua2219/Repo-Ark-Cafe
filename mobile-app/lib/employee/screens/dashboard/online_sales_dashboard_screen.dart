import 'package:material_ui/material_ui.dart';

import '../orders/incoming_orders_screen.dart';
import '../payments/payment_verification_screen.dart';

class OnlineSalesDashboardScreen extends StatelessWidget {
  const OnlineSalesDashboardScreen({
    super.key,
    this.orders,
    this.isLoading = false,
  });

  static const routeName = '/employee-online-sales';

  final List<IncomingOrder>? orders;
  final bool isLoading;

  List<IncomingOrder> _onlineOrders() {
    final onlineOrderNumbers = PaymentVerificationScreen.samplePayments
        .map((payment) => payment.order.number)
        .toSet();
    final result = (orders ?? IncomingOrdersScreen.sampleOrders)
        .where((order) => onlineOrderNumbers.contains(order.number))
        .toList()
      ..sort((a, b) => b.orderedAt.compareTo(a.orderedAt));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final sales = _onlineOrders();

    return Scaffold(
      appBar: AppBar(title: const Text('Online sales')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: _buildContent(context, sales),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<IncomingOrder> sales) {
    if (isLoading) {
      return const _SalesState(
        message: 'Loading sample sales data...',
        isLoading: true,
      );
    }

    if (sales.isEmpty) {
      return const _SalesState(
        icon: Icons.bar_chart_outlined,
        message: 'There is no sample online sales data to display.',
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final todaySales = sales
        .where((order) =>
            !order.orderedAt.isBefore(today) &&
            order.orderedAt.isBefore(tomorrow))
        .toList();
    final weekSales = sales
        .where((order) =>
            !order.orderedAt.isBefore(weekStart) &&
            order.orderedAt.isBefore(tomorrow))
        .toList();
    final totalSales = _total(sales);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SampleSalesNotice(),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 700
                ? 4
                : constraints.maxWidth >= 320
                    ? 2
                    : 1;
            final spacing = 12.0;
            final cardWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _SalesMetric(
                    label: 'Total online sales',
                    value: _money(totalSales),
                    icon: Icons.payments_outlined,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _SalesMetric(
                    label: 'Total orders',
                    value: '${sales.length}',
                    icon: Icons.receipt_long_outlined,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _SalesMetric(
                    label: 'Completed orders',
                    value:
                        '${sales.where((order) => order.status == 'Completed').length}',
                    icon: Icons.check_circle_outline,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _SalesMetric(
                    label: 'Pending orders',
                    value:
                        '${sales.where((order) => order.status == 'Pending').length}',
                    icon: Icons.pending_outlined,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = 12.0;
            final summaryWidth = constraints.maxWidth >= 560
                ? (constraints.maxWidth - gap) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: summaryWidth,
                  child: _PeriodSummary(
                    title: 'Today · demo sales',
                    amount: _total(todaySales),
                    orderCount: todaySales.length,
                  ),
                ),
                SizedBox(
                  width: summaryWidth,
                  child: _PeriodSummary(
                    title: 'This week · demo sales',
                    amount: _total(weekSales),
                    orderCount: weekSales.length,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _DailySalesChart(sales: sales, today: today),
        const SizedBox(height: 20),
        Text(
          'Recent transactions',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < sales.length; index++) ...[
                _RecentTransactionRow(order: sales[index]),
                if (index < sales.length - 1)
                  const Divider(height: 1, indent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SampleSalesNotice extends StatelessWidget {
  const _SampleSalesNotice();

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
              'SAMPLE DATA · Demo order totals only. These figures are not '
              'live or verified paid sales.',
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

class _SalesMetric extends StatelessWidget {
  const _SalesMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodSummary extends StatelessWidget {
  const _PeriodSummary({
    required this.title,
    required this.amount,
    required this.orderCount,
  });

  final String title;
  final double amount;
  final int orderCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$orderCount sample ${orderCount == 1 ? 'order' : 'orders'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _money(amount),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailySalesChart extends StatelessWidget {
  const _DailySalesChart({
    required this.sales,
    required this.today,
  });

  final List<IncomingOrder> sales;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final amount = _total(
        sales.where((order) => _sameDay(order.orderedAt, date)).toList(),
      );
      return (date: date, amount: amount);
    });
    final maxAmount = days.fold<double>(
      0,
      (maximum, day) => day.amount > maximum ? day.amount : maximum,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Daily online sales · sample data',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Last 7 days · bar labels show sample amounts',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final day in days)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _chartMoney(day.amount),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: 22,
                                  height: _barHeight(day.amount, maxAmount),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_weekdayLetter(day.date.weekday)} ${day.date.day}',
                              maxLines: 1,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _barHeight(double amount, double maxAmount) {
    if (maxAmount == 0 || amount == 0) return 4;
    return 96 * amount / maxAmount;
  }

  String _weekdayLetter(int weekday) =>
      const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][weekday - 1];
}

class _RecentTransactionRow extends StatelessWidget {
  const _RecentTransactionRow({required this.order});

  final IncomingOrder order;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(order.orderedAt);

    return ListTile(
      title: Text('Order #${order.number}'),
      subtitle: Text('$date · ${order.status}'),
      trailing: Text(
        _money(order.total),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      leading: Icon(
        Icons.receipt_long_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _SalesState extends StatelessWidget {
  const _SalesState({
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

double _total(List<IncomingOrder> orders) =>
    orders.fold(0, (total, order) => total + order.total);

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String _chartMoney(num amount) => '₱${amount.toStringAsFixed(0)}';

String _money(num amount) => '₱${amount.toStringAsFixed(2)}';
