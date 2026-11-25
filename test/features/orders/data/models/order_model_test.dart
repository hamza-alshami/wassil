import 'package:flutter_test/flutter_test.dart';
import 'package:wassel/features/orders/data/models/order_model.dart';

void main() {
  group('OrderModel.fromJson', () {
    test('converts order fields, items, and timeline', () {
      final order = OrderModel.fromJson(_validOrder()).order;

      expect(order.orderNumber, 'W-2048');
      expect(order.date, DateTime.utc(2026, 11, 20));
      expect(order.total, 7500);
      expect(order.status, 'in_transit');
      expect(order.customerName, 'محمد أحمد');
      expect(order.address, 'شارع الزبيري، صنعاء');
      expect(order.items.single.name, 'قهوة عربية');
      expect(order.items.single.quantity, 2);
      expect(order.items.single.price, 2500);
      expect(order.timeline.single.title, 'تم استلام الطلب');
      expect(order.timeline.single.completed, isTrue);
    });

    test('uses safe defaults for optional values', () {
      final json = _validOrder()
        ..remove('date')
        ..remove('customerName')
        ..remove('address');

      final order = OrderModel.fromJson(json).order;

      expect(order.date, isNull);
      expect(order.customerName, 'غير متوفر');
      expect(order.address, 'غير متوفر');
    });

    test('rejects missing required fields and malformed items', () {
      final missingNumber = _validOrder()..remove('orderNumber');
      final malformedItems = _validOrder()..['items'] = ['not an item'];
      final invalidTotal = _validOrder()..['total'] = 'unknown';

      expect(
        () => OrderModel.fromJson(missingNumber),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => OrderModel.fromJson(malformedItems),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => OrderModel.fromJson(invalidTotal),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a timeline step with a non-boolean completed value', () {
      final json = _validOrder()
        ..['timeline'] = [
          {'title': 'تم استلام الطلب', 'completed': 'yes'},
        ];

      expect(() => OrderModel.fromJson(json), throwsA(isA<FormatException>()));
    });
  });
}

Map<String, dynamic> _validOrder() => {
  'orderNumber': 'W-2048',
  'date': '2026-11-20T00:00:00.000Z',
  'total': 7500,
  'status': 'in_transit',
  'customerName': 'محمد أحمد',
  'address': 'شارع الزبيري، صنعاء',
  'items': [
    {'name': 'قهوة عربية', 'quantity': 2, 'price': 2500},
  ],
  'timeline': [
    {'title': 'تم استلام الطلب', 'completed': true},
  ],
};
