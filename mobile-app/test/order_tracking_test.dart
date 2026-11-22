import 'package:flutter_test/flutter_test.dart';
import 'package:ark_cafe_mobile/customer/order_tracking.dart';

void main() {
  test('normalizes backend statuses in the correct sequence', () {
    expect(OrderTracking.stages,
      ['pending', 'confirmed', 'preparing', 'ready', 'completed']);
    expect(OrderTracking.stageIndex(' PENDING '), 0);
    expect(OrderTracking.stageIndex('confirmed'), 1);
    expect(OrderTracking.stageIndex('Preparing'), 2);
    expect(OrderTracking.stageIndex('READY'), 3);
    expect(OrderTracking.stageIndex('completed'), 4);
    expect(OrderTracking.label('ready'), 'Ready');
  });

  test('unknown and cancelled statuses never imply normal progress', () {
    expect(OrderTracking.stageIndex(null), -1);
    expect(OrderTracking.stageIndex('processing'), -1);
    expect(OrderTracking.label('processing'), 'Unknown');
    expect(OrderTracking.stageIndex('cancelled'), -1);
    expect(OrderTracking.isCancelled('CANCELLED'), isTrue);
    expect(OrderTracking.isCancelled('canceled'), isTrue);
    expect(OrderTracking.isCancelled('pending'), isFalse);
  });
}
