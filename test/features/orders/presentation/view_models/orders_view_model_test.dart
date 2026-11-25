import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wassel/core/network/connectivity_service.dart';
import 'package:wassel/features/orders/domain/entities/order.dart';
import 'package:wassel/features/orders/domain/repositories/orders_repository.dart';
import 'package:wassel/features/orders/presentation/view_models/orders_view_model.dart';

void main() {
  late ProviderContainer container;
  late _FakeOrdersRepository repository;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    repository = _FakeOrdersRepository();
    container = ProviderContainer(
      // Avoid platform channels; connectivity is controlled by this fake.
      overrides: [
        ordersRepositoryProvider.overrideWithValue(repository),
        connectivityServiceProvider.overrideWithValue(
          _FakeConnectivityService(),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('exposes loading before the initial load completes', () async {
    final response = Completer<OrdersSnapshot>();
    repository.enqueue(() => response.future);

    container.read(ordersViewModelProvider);
    expect(container.read(ordersViewModelProvider), isA<AsyncLoading>());

    response.complete(_snapshot());
    await container.read(ordersViewModelProvider.future);
    expect(container.read(ordersViewModelProvider).value?.orders, hasLength(1));
  });

  test('exposes a repository failure as an error state', () async {
    final response = Completer<OrdersSnapshot>();
    repository.enqueue(() => response.future);
    container.read(ordersViewModelProvider);

    response.completeError(StateError('load failed'));
    await expectLater(
      container.read(ordersViewModelProvider.future),
      throwsA(isA<StateError>()),
    );
    expect(container.read(ordersViewModelProvider), isA<AsyncError>());
  });

  test(
    'refresh replaces the current snapshot with the latest result',
    () async {
      repository
        ..enqueue(() async => _snapshot(orderNumber: 'W-1'))
        ..enqueue(() async => _snapshot(orderNumber: 'W-2'));
      await container.read(ordersViewModelProvider.future);

      await container.read(ordersViewModelProvider.notifier).refresh();

      expect(
        container
            .read(ordersViewModelProvider)
            .value
            ?.orders
            .single
            .orderNumber,
        'W-2',
      );
      expect(repository.calls, 2);
    },
  );

  test('retains offline cache metadata from the repository snapshot', () async {
    repository.enqueue(
      () async => _snapshot(isFromCache: true, isOffline: true),
    );

    final result = await container.read(ordersViewModelProvider.future);

    expect(result.isFromCache, isTrue);
    expect(result.isOffline, isTrue);
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
  bool isFromCache = false,
  bool isOffline = false,
}) => OrdersSnapshot(
  orders: [
    Order(
      orderNumber: orderNumber,
      date: null,
      total: 2500,
      status: 'in_transit',
      customerName: 'محمد أحمد',
      address: 'شارع الزبيري، صنعاء',
      items: const [OrderItem(name: 'قهوة عربية', quantity: 1, price: 2500)],
      timeline: const [
        OrderTimelineStep(title: 'تم استلام الطلب', completed: true),
      ],
    ),
  ],
  isFromCache: isFromCache,
  isOffline: isOffline,
);
