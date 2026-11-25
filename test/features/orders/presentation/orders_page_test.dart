import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wassel/app/wassel_app.dart';
import 'package:wassel/core/network/connectivity_service.dart';
import 'package:wassel/features/orders/domain/entities/order.dart';
import 'package:wassel/features/orders/domain/repositories/orders_repository.dart';
import 'package:wassel/features/orders/presentation/view_models/orders_view_model.dart';

void main() {
  late _FakeOrdersRepository repository;

  setUp(() {
    repository = _FakeOrdersRepository();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersRepositoryProvider.overrideWithValue(repository),
          connectivityServiceProvider.overrideWithValue(
            _FakeConnectivityService(),
          ),
        ],
        child: const WasselApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows orders returned by the repository', (tester) async {
    repository.enqueue(() async => _snapshot());
    await pumpApp(tester);

    expect(find.text('طلباتي'), findsOneWidget);
    expect(find.text('طلب #W-1042'), findsOneWidget);
    expect(find.text('عدد الطلبات'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('متصل بالإنترنت'), findsOneWidget);
  });

  testWidgets('shows loading until the repository response arrives', (
    tester,
  ) async {
    final response = Completer<OrdersSnapshot>();
    repository.enqueue(() => response.future);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersRepositoryProvider.overrideWithValue(repository),
          connectivityServiceProvider.overrideWithValue(
            _FakeConnectivityService(),
          ),
        ],
        child: const WasselApp(),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    response.complete(_snapshot());
    await tester.pumpAndSettle();
    expect(find.text('طلب #W-1042'), findsOneWidget);
  });

  testWidgets('shows an error message and retry action', (tester) async {
    repository.enqueue(
      () async => throw const OrdersUnavailableException(isOffline: true),
    );
    await pumpApp(tester);

    expect(find.textContaining('لا يوجد اتصال بالإنترنت'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('retry requests a fresh snapshot', (tester) async {
    repository
      ..enqueue(
        () async => throw const OrdersUnavailableException(isOffline: true),
      )
      ..enqueue(() async => _snapshot());
    await pumpApp(tester);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
    expect(find.text('طلب #W-1042'), findsOneWidget);
  });

  testWidgets('shows the empty state for an empty snapshot', (tester) async {
    repository.enqueue(() async => _snapshot(orders: const []));
    await pumpApp(tester);

    expect(find.text('لا توجد طلبات حتى الآن'), findsOneWidget);
  });

  testWidgets('opens details for the selected order', (tester) async {
    repository.enqueue(() async => _snapshot());
    await pumpApp(tester);
    await tester.tap(find.text('طلب #W-1042'));
    await tester.pumpAndSettle();

    expect(find.text('تفاصيل الطلب'), findsOneWidget);
    expect(find.text('قهوة عربية'), findsOneWidget);
    expect(find.text('شارع الزبيري، صنعاء'), findsOneWidget);
  });

  testWidgets('shows cached offline status in the connectivity banner', (
    tester,
  ) async {
    repository.enqueue(
      () async => _snapshot(isFromCache: true, isOffline: true),
    );
    await pumpApp(tester);

    expect(
      find.text('أنت غير متصل بالإنترنت – تعرض آخر بيانات محفوظة'),
      findsOneWidget,
    );
    expect(find.text('قد تكون البيانات قديمة.'), findsOneWidget);
  });

  testWidgets('pull to refresh asks the repository for a new snapshot', (
    tester,
  ) async {
    repository
      ..enqueue(() async => _snapshot())
      ..enqueue(() async => _snapshot(orderNumber: 'W-2043'));
    await pumpApp(tester);
    expect(repository.calls, 1);

    await tester.drag(find.byType(ListView), const Offset(0, 420));
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
    expect(find.text('طلب #W-2043'), findsOneWidget);
  });
}

class _FakeOrdersRepository implements OrdersRepository {
  final List<Future<OrdersSnapshot> Function()> _responses = [];
  int calls = 0;

  void enqueue(Future<OrdersSnapshot> Function() response) {
    _responses.add(response);
  }

  @override
  Future<OrdersSnapshot> getOrders() {
    calls++;
    return _responses.removeAt(0)();
  }
}

class _FakeConnectivityService extends ConnectivityService {
  @override
  Future<bool> hasNetwork() async => true;

  @override
  Stream<bool> get onConnectionChanged => const Stream<bool>.empty();
}

OrdersSnapshot _snapshot({
  String orderNumber = 'W-1042',
  List<Order>? orders,
  bool isFromCache = false,
  bool isOffline = false,
}) => OrdersSnapshot(
  orders:
      orders ??
      [
        Order(
          orderNumber: orderNumber,
          date: null,
          total: 2500,
          status: 'in_transit',
          customerName: 'محمد أحمد',
          address: 'شارع الزبيري، صنعاء',
          items: const [
            OrderItem(name: 'قهوة عربية', quantity: 1, price: 2500),
          ],
          timeline: const [
            OrderTimelineStep(title: 'تم استلام الطلب', completed: true),
          ],
        ),
      ],
  isFromCache: isFromCache,
  isOffline: isOffline,
);
