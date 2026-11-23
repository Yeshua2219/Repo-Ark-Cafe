import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import '../../../customer/customer_api.dart';
import '../expenses/miscellaneous_expense_screen.dart';
import '../login/employee_login_screen.dart';
import '../orders/incoming_orders_screen.dart';
import '../orders/order_status_management_screen.dart';
import '../payments/payment_verification_screen.dart';
import 'online_sales_dashboard_screen.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  static const routeName = '/employee-dashboard';

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  int _openOrdersCount = 8;
  int _pendingPaymentsCount = 3;
  double _expensesTotal = 4280.0;

  bool get _isAuthenticated =>
      EmployeeSession.token != null && EmployeeSession.token!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isAuthenticated) {
      _loadDashboardMetrics();
    }
  }

  Future<void> _loadDashboardMetrics() async {
    if (!_isAuthenticated || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${EmployeeSession.token}',
    };

    try {
      final responses = await Future.wait([
        http
            .get(Uri.parse('${CustomerApi.baseUrl}/orders'), headers: headers)
            .timeout(const Duration(seconds: 15)),
        http
            .get(Uri.parse('${CustomerApi.baseUrl}/expenses'), headers: headers)
            .timeout(const Duration(seconds: 15)),
      ]);

      final ordersRes = responses[0];
      final expensesRes = responses[1];

      if (ordersRes.statusCode >= 200 && ordersRes.statusCode < 300) {
        final decodedOrders = jsonDecode(ordersRes.body);
        final List<dynamic> ordersList = decodedOrders is List
            ? decodedOrders
            : (decodedOrders is Map && decodedOrders['orders'] is List
                ? decodedOrders['orders'] as List
                : []);

        int openCount = 0;
        int pendingPaymentCount = 0;

        for (final item in ordersList) {
          if (item is Map) {
            final status =
                (item['order_status'] ?? item['status'] ?? '').toString().toLowerCase();
            final payStatus =
                (item['payment_status'] ?? '').toString().toLowerCase();

            if (status != 'completed' &&
                status != 'ready' &&
                status != 'cancelled') {
              openCount++;
            }
            if (payStatus == 'pending' || payStatus == 'unverified') {
              pendingPaymentCount++;
            }
          }
        }

        _openOrdersCount = openCount;
        _pendingPaymentsCount = pendingPaymentCount;
      }

      if (expensesRes.statusCode >= 200 && expensesRes.statusCode < 300) {
        final decodedExpenses = jsonDecode(expensesRes.body);
        final List<dynamic> expensesList = decodedExpenses is List
            ? decodedExpenses
            : (decodedExpenses is Map && decodedExpenses['expenses'] is List
                ? decodedExpenses['expenses'] as List
                : []);

        double total = 0;
        for (final item in expensesList) {
          if (item is Map) {
            total += double.tryParse(item['amount'].toString()) ?? 0;
          }
        }
        _expensesTotal = total;
      }

      if (!mounted) return;
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load live metrics: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatPeso(double amount) {
    final fixed = amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '₱$intPart.${parts[1]}';
  }

  void _logout() {
    EmployeeSession.token = null;
    EmployeeSession.user = null;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const EmployeeLoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final staffName = EmployeeSession.user?['name']?.toString() ?? 'Employee';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee dashboard'),
        actions: [
          if (_isAuthenticated) ...[
            IconButton(
              tooltip: 'Refresh',
              onPressed: _isLoading ? null : _loadDashboardMetrics,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Sign out',
              onPressed: _logout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ],
      ),
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
                      _isAuthenticated ? 'Overview · $staffName' : 'Overview',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    if (!_isAuthenticated) ...[
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
                                'DEMO MODE · Frontend testing only; no employee '
                                'is authenticated. SAMPLE DATA · Not connected '
                                'to the backend.',
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
                    ],
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: colors.onErrorContainer),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: metricWidth,
                          child: _SummaryMetric(
                            icon: Icons.receipt_long_outlined,
                            label: 'Orders',
                            value: _isLoading ? '...' : '$_openOrdersCount',
                            detail: _isAuthenticated
                                ? 'Active orders in database'
                                : 'Sample open orders',
                          ),
                        ),
                        SizedBox(
                          width: metricWidth,
                          child: _SummaryMetric(
                            icon: Icons.payments_outlined,
                            label: 'Pending payments',
                            value:
                                _isLoading ? '...' : '$_pendingPaymentsCount',
                            detail: _isAuthenticated
                                ? 'Payments awaiting verification'
                                : 'Sample payments to review',
                          ),
                        ),
                        SizedBox(
                          width: metricWidth,
                          child: _SummaryMetric(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Expenses',
                            value: _isLoading
                                ? '...'
                                : _formatPeso(_expensesTotal),
                            detail: _isAuthenticated
                                ? 'Recorded expenses in database'
                                : 'Sample total this week',
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
                            subtitle: const Text('Update customer order statuses'),
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
                            subtitle: const Text('Verify customer payments'),
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
                            subtitle: const Text('View sales summaries'),
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
                            subtitle: const Text('Manage recorded expenses'),
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