import 'dart:convert';

import 'package:http/http.dart' as http;

import '../customer/customer_api.dart';
import 'screens/login/employee_login_screen.dart';
import 'screens/orders/incoming_orders_screen.dart';

/// Employee-only backend client. Never stores a service-role key in Flutter.
class EmployeeApi {
  EmployeeApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> get _headers {
    final token = EmployeeSession.token;
    if (token == null || token.isEmpty) {
      throw StateError('Please sign in with an authorized employee account.');
    }
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _request(
    String method, String path, {Object? body}
  ) async {
    final uri = Uri.parse('${CustomerApi.baseUrl}$path');
    late http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: _headers)
              .timeout(const Duration(seconds: 15));
        case 'POST':
          response = await _client.post(
            uri, headers: _headers, body: jsonEncode(body),
          ).timeout(const Duration(seconds: 15));
        case 'PUT':
          response = await _client.put(
            uri, headers: _headers, body: jsonEncode(body),
          ).timeout(const Duration(seconds: 15));
        case 'PATCH':
          response = await _client.patch(
            uri, headers: _headers, body: jsonEncode(body),
          ).timeout(const Duration(seconds: 15));
        case 'DELETE':
          response = await _client.delete(uri, headers: _headers)
              .timeout(const Duration(seconds: 15));
        default:
          throw ArgumentError('Unsupported HTTP method');
      }
    } catch (error) {
      throw Exception('Cannot connect to ARK Cafe backend: $error');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw FormatException('Unexpected response from ARK Cafe backend.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Request failed (HTTP ${response.statusCode}).';
      throw Exception(message);
    }
    return decoded;
  }

  Future<List<IncomingOrder>> fetchOrders() async {
    final result = await _request('GET', '/orders');
    if (result is! List) {
      throw const FormatException('Invalid orders response.');
    }
    return result.map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      final payments = row['payments'];
      if (payments is List && payments.isNotEmpty && payments.first is Map) {
        row['payment'] = Map<String, dynamic>.from(payments.first as Map);
      }
      return IncomingOrder.fromJson(row);
    }).toList();
  }

  Future<IncomingOrder> updateOrderStatus(int orderId, String status) async {
    await _request('PATCH', '/orders/$orderId/status',
        body: {'status': status.toLowerCase()});
    final orders = await fetchOrders();
    for (final order in orders) {
      if (order.id == orderId) return order;
    }
    throw StateError('Status was sent, but the updated order could not be '
        'reloaded. Refresh the orders list before retrying.');
  }

  /// Staff confirmation is required before reporting cash as received.
  /// The backend checks the authenticated employee/admin role again.
  Future<void> updatePaymentStatus(
    int orderId,
    String status, {
    bool cashReceived = false,
  }) async {
    if (status != 'approved' && status != 'rejected') {
      throw ArgumentError('Invalid payment decision.');
    }
    await _request('PATCH', '/orders/$orderId/payment', body: {
      'status': status,
      'cash_received': cashReceived,
    });
  }

  Future<List<ExpenseItem>> fetchExpenses() async {
    final result = await _request('GET', '/expenses');
    if (result is! List) {
      throw const FormatException('Invalid expenses response.');
    }
    return result.map((raw) => ExpenseItem.fromJson(
      Map<String, dynamic>.from(raw as Map),
    )).toList();
  }

  Future<ExpenseItem> createExpense({
    required String category,
    required String description,
    required double amount,
    required DateTime date,
  }) async {
    final result = await _request('POST', '/expenses', body: {
      'category': category,
      'description': description,
      'amount': amount,
      'expense_date': _date(date),
    });
    return ExpenseItem.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<ExpenseItem> updateExpense({
    required int id,
    required String category,
    required String description,
    required double amount,
    required DateTime date,
  }) async {
    final result = await _request('PUT', '/expenses/$id', body: {
      'category': category,
      'description': description,
      'amount': amount,
      'expense_date': _date(date),
    });
    return ExpenseItem.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<void> deleteExpense(int id) async {
    await _request('DELETE', '/expenses/$id');
  }

  String _date(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void dispose() => _client.close();
}

class ExpenseItem {
  const ExpenseItem({
    required this.id,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
  });

  final int id;
  final String category;
  final String description;
  final double amount;
  final DateTime date;

  factory ExpenseItem.fromJson(Map<String, dynamic> json) => ExpenseItem(
    id: (json['id'] as num).toInt(),
    category: (json['category'] ?? 'Other').toString(),
    description: (json['description'] ?? '').toString(),
    amount: double.tryParse((json['amount'] ?? 0).toString()) ?? 0,
    date: DateTime.tryParse(
      (json['expense_date'] ?? json['date'] ?? '').toString(),
    ) ?? DateTime.now(),
  );

  ExpenseItem copyWith({
    int? id,
    String? category,
    String? description,
    double? amount,
    DateTime? date,
  }) => ExpenseItem(
    id: id ?? this.id,
    category: category ?? this.category,
    description: description ?? this.description,
    amount: amount ?? this.amount,
    date: date ?? this.date,
  );
}
