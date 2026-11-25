import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wassel/features/orders/domain/entities/order.dart';
import 'package:wassel/features/orders/presentation/widgets/order_progress_timeline.dart';

void main() {
  testWidgets('activates journey stages one at a time up to delivering', (
    tester,
  ) async {
    final order = _order(status: 'delivering');
    await _pumpTimeline(tester, order);

    expect(_stage('0', 'current'), findsOneWidget);
    expect(_stage('1', 'future'), findsOneWidget);
    expect(_stage('2', 'future'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 760));
    expect(_stage('0', 'complete'), findsOneWidget);
    expect(_stage('1', 'current'), findsOneWidget);
    expect(_stage('2', 'future'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(_stage('0', 'complete'), findsOneWidget);
    expect(_stage('1', 'complete'), findsOneWidget);
    expect(_stage('2', 'current'), findsOneWidget);
    expect(_stage('3', 'future'), findsOneWidget);
  });

  testWidgets('marks all stages complete only after delivered animation ends', (
    tester,
  ) async {
    await _pumpTimeline(tester, _order(status: 'delivered'));

    expect(_stage('0', 'current'), findsOneWidget);
    expect(_stage('3', 'future'), findsOneWidget);

    await tester.pumpAndSettle();
    for (var index = 0; index < 4; index++) {
      expect(_stage('$index', 'complete'), findsOneWidget);
    }
    expect(find.text('اكتمل الطلب'), findsOneWidget);
  });

  testWidgets('keeps a cancelled order from completing the delivery route', (
    tester,
  ) async {
    await _pumpTimeline(tester, _order(status: 'cancelled'));
    await tester.pumpAndSettle();

    expect(_stage('0', 'complete'), findsOneWidget);
    expect(_stage('1', 'future'), findsOneWidget);
    expect(_stage('3', 'future'), findsOneWidget);
    expect(
      find.text('أُلغي هذا الطلب قبل اكتمال رحلة التوصيل.'),
      findsOneWidget,
    );
    expect(find.text('اكتمل الطلب'), findsNothing);
  });

  testWidgets(
    'does not restart when the timeline rebuilds for the same order',
    (tester) async {
      final order = _order(status: 'delivering');
      await _pumpTimeline(tester, order);
      await tester.pump(const Duration(milliseconds: 500));
      expect(_stage('0', 'current'), findsOneWidget);

      await tester.pumpWidget(_app(_order(status: 'delivering')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(_stage('0', 'complete'), findsOneWidget);
      expect(_stage('1', 'current'), findsOneWidget);
    },
  );
}

Finder _stage(String index, String state) =>
    find.byKey(ValueKey('timeline-stage-$index-$state'));

Future<void> _pumpTimeline(WidgetTester tester, Order order) async {
  await tester.pumpWidget(_app(order));
  await tester.pump();
}

Widget _app(Order order) {
  return MaterialApp(
    locale: const Locale('ar'),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: OrderProgressTimeline(order: order),
          ),
        ),
      ),
    ),
  );
}

Order _order({required String status}) => Order(
  orderNumber: 'ORD-1200',
  date: DateTime.utc(2026, 11, 25),
  total: 12000,
  status: status,
  customerName: 'أحمد محمد',
  address: 'شارع الزبيري، صنعاء',
  items: const [OrderItem(name: 'قهوة', quantity: 1, price: 12000)],
  timeline: const [
    OrderTimelineStep(title: 'تم استلام الطلب', completed: true),
    OrderTimelineStep(title: 'تم تأكيد الطلب', completed: true),
    OrderTimelineStep(title: 'جارٍ تجهيز الطلب', completed: true),
    OrderTimelineStep(title: 'خرج الطلب للتوصيل', completed: false),
  ],
);
