import 'package:flutter/material.dart';

import '../expenses/miscellaneous_expense_screen.dart';
import '../orders/incoming_orders_screen.dart';
import '../orders/order_status_management_screen.dart';
import '../payments/payment_verification_screen.dart';
import 'online_sales_dashboard_screen.dart';

class EmployeeDashboardScreen extends StatelessWidget {
  const EmployeeDashboardScreen({super.key});

  static const routeName = '/employee-dashboard';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Employee dashboard')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final metricWidth = isWide
                  ? (constraints.maxWidth - 24) / 3
                  : constraints.maxWidth;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Overview',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              color: colors.onSecondaryContainer),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'SAMPLE DATA · UI preview only · Not connected '
                              'to the backend',
                              style: TextStyle(
                                color: colors.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: metricWidth,
                          child: const _SummaryMetric(
                            icon: Icons.receipt_long_outlined,
                            label: 'Orders',
                            value: '8',
                            detail: 'Sample open orders',
                          ),
                        ),
                        SizedBox(
                          width: metricWidth,
                          child: const _SummaryMetric(
                            icon: Icons.payments_outlined,
                            label: 'Pending payments',
                            value: '3',
                            detail: 'Sample payments to review',
                          ),
                        ),
                        SizedBox(
                          width: metricWidth,
                          child: const _SummaryMetric(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Expenses',
                            value: '₱4,280.00',
                            detail: 'Sample total this week',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Employee tools',
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
                          ListTile(
                            leading: const Icon(Icons.receipt_long_outlined),
                            title: const Text('Orders'),
                            subtitle: const Text('View incoming orders'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pushNamed(
                              context,
                              IncomingOrdersScreen.routeName,
                            ),
                          ),
                          const Divider(height: 1, indent: 56),
                          ListTile(
                            leading: const Icon(Icons.sync_alt_outlined),
                            title: const Text('Order statuses'),
                            subtitle:
                                const Text('Manage sample order statuses'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pushNamed(
                              context,
                              OrderStatusManagementScreen.routeName,
                            ),
                          ),
                          const Divider(height: 1, indent: 56),
                          ListTile(
                            leading: const Icon(Icons.payments_outlined),
                            title: const Text('Payments'),
                            subtitle: const Text('Review sample payments'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pushNamed(
                              context,
                              PaymentVerificationScreen.routeName,
                            ),
                          ),
                          const Divider(height: 1, indent: 56),
                          ListTile(
                            leading: const Icon(Icons.bar_chart_outlined),
                            title: const Text('Online sales'),
                            subtitle: const Text('View sample sales summaries'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pushNamed(
                              context,
                              OnlineSalesDashboardScreen.routeName,
                            ),
                          ),
                          const Divider(height: 1, indent: 56),
                          ListTile(
                            leading: const Icon(
                                Icons.account_balance_wallet_outlined),
                            title: const Text('Miscellaneous expenses'),
                            subtitle: const Text('Review sample expenses'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pushNamed(
                              context,
                              MiscellaneousExpenseScreen.routeName,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
