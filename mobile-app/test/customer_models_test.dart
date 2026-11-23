import 'package:flutter_test/flutter_test.dart';
import 'package:ark_cafe_mobile/customer/customer_app.dart';

void main() {
  test('menu product uses shared API category and numeric price', () {
    final product = Product.fromJson({
      'id': 1,
      'name': 'Iced Latte',
      'price': '160.00',
      'description': 'coffee, milk, sugar',
      'categories': {'name': 'Coffee'},
    });
    expect(product.id, 1);
    expect(product.category, 'Coffee');
    expect(product.price, 160);
    expect(money(product.price), '₱160.00');
  });

  test('cart preserves customization and recomputes subtotal', () {
    final product = Product(1, 'Iced Latte', '', 160, 'Coffee');
    final item = CartItem(product, 'Less sugar', 2);
    expect(item.note, 'Less sugar');
    expect(item.subtotal, 320);
    item.quantity = 3;
    expect(item.subtotal, 480);
  });
}
