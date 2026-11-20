import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// The backend address is injected at launch. On Android emulator use
/// http://10.0.2.2:5000/api; on a real device use a reachable LAN IP.
class CustomerApi {
  CustomerApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL', defaultValue: 'http://10.0.2.2:5000/api');

  Map<String, String> get _headers {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _request(String method, String path, [Object? body]) async {
    final uri = Uri.parse('$baseUrl$path');
    late http.Response response;
    try {
      response = await (switch (method) {
        'GET' => _client.get(uri, headers: _headers),
        'POST' => _client.post(uri, headers: _headers,
            body: jsonEncode(body)),
        _ => throw ArgumentError('Unsupported method $method'),
      }).timeout(const Duration(seconds: 15));
    } catch (error) {
      throw Exception('Cannot connect to ARK Cafe backend: $error');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Server returned ${response.statusCode}';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {}
      if (response.statusCode == 404 || response.statusCode == 405) {
        throw Exception('This feature needs a backend endpoint ($path). '
            'Ask the backend team to implement it.');
      }
      throw Exception(message);
    }
    return jsonDecode(response.body);
  }

  Future<List<MenuProduct>> fetchMenu() async {
    final result = await _request('GET', '/products');
    if (result is! List) throw const FormatException('Invalid product response');
    return result.map((e) => MenuProduct.fromJson(
      Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Backend contract: POST /api/orders, calculates prices server-side and
  /// resolves customer identity from the verified Bearer token.
  Future<int> placeOrder(List<CartLine> lines, String paymentMethod) async {
    final result = await _request('POST', '/orders', {
      'payment_method': paymentMethod,
      'items': lines.map((e) => {
        'product_id': e.product.id,
        'quantity': e.quantity,
        'customization': e.customization,
      }).toList(),
    });
    if (result is! Map) throw const FormatException('Invalid order response');
    final order = result['order'] is Map ? result['order'] as Map : result;
    final id = order['id'];
    if (id is num) return id.toInt();
    return int.parse(id.toString());
  }

  /// Backend contract: GET /api/orders/mine, scoped to authenticated user.
  Future<List<CustomerOrder>> fetchMyOrders() async {
    final result = await _request('GET', '/orders/mine');
    if (result is! List) throw const FormatException('Invalid orders response');
    return result.map((e) => CustomerOrder.fromJson(
      Map<String, dynamic>.from(e as Map))).toList();
  }

  void dispose() => _client.close();
}

class MenuProduct {
  MenuProduct({required this.id, required this.name, required this.price,
    required this.category, required this.description, this.imageUrl});
  final int id;
  final String name;
  final double price;
  final String category;
  final String description;
  final String? imageUrl;

  factory MenuProduct.fromJson(Map<String, dynamic> json) {
    final cat = json['categories'];
    return MenuProduct(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? 'Unnamed product').toString(),
      price: double.tryParse(json['price'].toString()) ?? 0,
      category: cat is Map ? (cat['name'] ?? 'Other').toString() : 'Other',
      description: (json['description'] ?? '').toString(),
      imageUrl: json['image_url']?.toString(),
    );
  }
}

class CartLine {
  CartLine({required this.product, required this.customization,
    this.quantity = 1});
  final MenuProduct product;
  final String customization;
  int quantity;
  double get subtotal => product.price * quantity;
}

class CustomerOrder {
  CustomerOrder({required this.id, required this.total, required this.status,
    required this.paymentStatus, required this.createdAt, required this.items});
  final int id;
  final double total;
  final String status;
  final String paymentStatus;
  final DateTime? createdAt;
  final List<dynamic> items;
  factory CustomerOrder.fromJson(Map<String, dynamic> json) => CustomerOrder(
    id: (json['id'] as num).toInt(),
    total: double.tryParse(json['total_amount'].toString()) ?? 0,
    status: (json['order_status'] ?? 'pending').toString(),
    paymentStatus: (json['payment_status'] ?? 'pending').toString(),
    createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    items: json['order_items'] is List ? json['order_items'] as List : [],
  );
}
