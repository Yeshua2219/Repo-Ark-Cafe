import 'package:flutter/material.dart';

import 'screens/dashboard/employee_dashboard_screen.dart';
import 'screens/dashboard/online_sales_dashboard_screen.dart';
import 'screens/expenses/miscellaneous_expense_screen.dart';
import 'screens/login/employee_login_screen.dart';
import 'screens/orders/incoming_orders_screen.dart';
import 'screens/orders/order_status_management_screen.dart';
import 'screens/payments/payment_verification_screen.dart';

class EmployeeApp extends StatelessWidget {
  const EmployeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    const coffeeBrown = Color(0xFF79513B);
    const warmCream = Color(0xFFFAF6F0);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ARK Cafe Employee',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: coffeeBrown),
        scaffoldBackgroundColor: warmCream,
        appBarTheme: const AppBarTheme(
          backgroundColor: warmCream,
          foregroundColor: Color(0xFF33251E),
        ),
      ),
      home: const EmployeeLoginScreen(),
      routes: {
        EmployeeDashboardScreen.routeName: (_) =>
            const EmployeeDashboardScreen(),
        MiscellaneousExpenseScreen.routeName: (_) =>
            const MiscellaneousExpenseScreen(),
        OnlineSalesDashboardScreen.routeName: (_) =>
            const OnlineSalesDashboardScreen(),
        IncomingOrdersScreen.routeName: (_) => const IncomingOrdersScreen(),
        OrderStatusManagementScreen.routeName: (_) =>
            const OrderStatusManagementScreen(),
        PaymentVerificationScreen.routeName: (_) =>
            const PaymentVerificationScreen(),
      },
    );
  }
}
