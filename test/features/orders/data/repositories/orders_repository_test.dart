import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wassel/core/database/app_database.dart';
import 'package:wassel/core/network/connectivity_service.dart';
import 'package:wassel/core/network/dio_client.dart';
import 'package:wassel/features/orders/data/datasources/orders_local_data_source.dart';
import 'package:wassel/features/orders/data/datasources/orders_remote_data_source.dart';
import 'package:wassel/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:wassel/features/orders/domain/entities/order.dart';
import 'package:wassel/features/orders/domain/repositories/orders_repository.dart';

void main() {
  late AppDatabase appDatabase;
  late OrdersLocalDataSource localDataSource;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    appDatabase = AppDatabase(databasePath: inMemoryDatabasePath);
    localDataSource = OrdersLocalDataSource(appDatabase);
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test('fetches orders and saves the full snapshot in SQLite', () async {
    final repository = _repositoryWithResponse(localDataSource);

    final result = await repository.getOrders();
    final cached = await localDataSource.getCachedOrders(isOffline: true);

    expect(result.isFromCache, isFalse);
    expect(result.orders, hasLength(1));
    expect(cached, isNotNull);
    expect(cached!.orders.single.orderNumber, 'W-2048');
    expect(cached.orders.single.date, DateTime.utc(2026, 11, 20));
    expect(cached.orders.single.total, 7500);
    expect(cached.orders.single.status, 'in_transit');
    expect(cached.orders.single.customerName, 'محمد أحمد');
    expect(cached.orders.single.address, 'شارع الزبيري، صنعاء');
    expect(
      cached.orders.single.items
          .map((item) => (item.name, item.quantity, item.price))
          .toList(),
      [('قهوة عربية', 2, 2500.0), ('تمر', 1, 2500.0)],
    );
    expect(
      cached.orders.single.timeline
          .map((step) => (step.title, step.completed))
          .toList(),
      [('تم استلام الطلب', true), ('في الطريق', false)],
    );
  });

  test('sorts remote orders from newest to oldest before caching', () async {
    final oldest = _remoteOrderJson()
      ..['orderNumber'] = 'W-OLD'
      ..['date'] = '2026-11-18T00:00:00.000Z';
    final newest = _remoteOrderJson()
      ..['orderNumber'] = 'W-NEW'
      ..['date'] = '2026-11-22T00:00:00.000Z';
    final middle = _remoteOrderJson()
      ..['orderNumber'] = 'W-MIDDLE'
      ..['date'] = '2026-11-20T00:00:00.000Z';
    final repository = _repositoryWithResponse(
      localDataSource,
      orders: [oldest, newest, middle],
    );

    final result = await repository.getOrders();

    expect(
      result.orders.map((order) => order.orderNumber),
      ['W-NEW', 'W-MIDDLE', 'W-OLD'],
    );
    final cached = await localDataSource.getCachedOrders(isOffline: true);
    expect(
      cached!.orders.map((order) => order.orderNumber),
      ['W-NEW', 'W-MIDDLE', 'W-OLD'],
    );
  });

  test('falls back to the saved snapshot when the API is offline', () async {
    final savedAt = DateTime.utc(2026, 11, 20, 10);
    await localDataSource.replaceOrders([_cachedOrder()], savedAt: savedAt);
    final repository = _repositoryWithNetworkFailure(localDataSource);

    final result = await repository.getOrders();

    expect(result.isFromCache, isTrue);
    expect(result.isOffline, isTrue);
    expect(result.savedAt, savedAt);
    expect(result.orders.single.items, hasLength(2));
    expect(result.orders.single.timeline, hasLength(2));
    expect(result.orders.single.address, 'شارع الزبيري، صنعاء');
  });

  test('uses cached data when API authentication is rejected', () async {
    await localDataSource.replaceOrders([
      _cachedOrder(),
    ], savedAt: DateTime.utc(2026, 11, 20));
    final repository = _repositoryWithHttpFailure(localDataSource, 401);

    final result = await repository.getOrders();

    expect(result.isFromCache, isTrue);
    expect(result.isOffline, isFalse);
    expect(result.orders.single.orderNumber, 'W-2048');
  });

  test('falls back to SQLite when the API key is missing', () async {
    await localDataSource.replaceOrders([
      _cachedOrder(),
    ], savedAt: DateTime.utc(2026, 11, 20));
    final dio = DioClient.create(apiKey: '')
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
              ),
            );
          },
        ),
      );
    final repository = OrdersRepositoryImpl(
      remoteDataSource: OrdersRemoteDataSource(dio),
      localDataSource: localDataSource,
      connectivityService: _FakeConnectivityService(),
    );

    final result = await repository.getOrders();

    expect(dio.options.headers.containsKey('x-api-key'), isFalse);
    expect(result.isFromCache, isTrue);
    expect(result.isOffline, isTrue);
    expect(result.orders.single.orderNumber, 'W-2048');
  });

  test(
    'uses cached data when the remote response has an invalid shape',
    () async {
      await localDataSource.replaceOrders([
        _cachedOrder(),
      ], savedAt: DateTime.utc(2026, 11, 20));
      final repository = _repositoryWithInvalidPayload(localDataSource);

      final result = await repository.getOrders();

      expect(result.isFromCache, isTrue);
      expect(result.isOffline, isFalse);
      expect(result.orders.single.orderNumber, 'W-2048');
    },
  );

  test('preserves the previous snapshot if an API refresh fails', () async {
    await localDataSource.replaceOrders([
      _cachedOrder(),
    ], savedAt: DateTime.utc(2026, 11, 20));
    final repository = _repositoryWithNetworkFailure(localDataSource);

    await repository.getOrders();
    final cached = await localDataSource.getCachedOrders(isOffline: true);

    expect(cached!.orders.single.total, 7500);
    expect(cached.orders.single.items.first.name, 'قهوة عربية');
  });

  test('reports an offline error when no saved snapshot exists', () async {
    final repository = _repositoryWithNetworkFailure(localDataSource);

    await expectLater(
      repository.getOrders(),
      throwsA(
        isA<OrdersUnavailableException>().having(
          (error) => error.isOffline,
          'isOffline',
          isTrue,
        ),
      ),
    );
  });

  test('replaces a previous snapshot without duplicate orders', () async {
    final originalOrder = _cachedOrder();
    final updatedOrder = Order(
      orderNumber: originalOrder.orderNumber,
      date: originalOrder.date,
      total: 9000,
      status: 'delivered',
      customerName: originalOrder.customerName,
      address: originalOrder.address,
      items: const [OrderItem(name: 'قهوة عربية', quantity: 1, price: 9000)],
      timeline: originalOrder.timeline,
    );

    await localDataSource.replaceOrders([
      originalOrder,
    ], savedAt: DateTime.utc(2026, 11, 20));
    await localDataSource.replaceOrders([
      updatedOrder,
    ], savedAt: DateTime.utc(2026, 11, 21));
    final cached = await localDataSource.getCachedOrders(isOffline: true);

    expect(cached!.orders, hasLength(1));
    expect(cached.orders.single.total, 9000);
    expect(cached.orders.single.items, hasLength(1));
  });
}

OrdersRepositoryImpl _repositoryWithResponse(
  OrdersLocalDataSource localDataSource, {
  List<Map<String, dynamic>>? orders,
}
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.mockapi.com'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': orders ?? [_remoteOrderJson()],
              },
            ),
          );
        },
      ),
    );

  return OrdersRepositoryImpl(
    remoteDataSource: OrdersRemoteDataSource(dio),
    localDataSource: localDataSource,
    connectivityService: _FakeConnectivityService(),
  );
}

OrdersRepositoryImpl _repositoryWithNetworkFailure(
  OrdersLocalDataSource localDataSource,
) => _repositoryWithFailure(localDataSource, DioExceptionType.connectionError);

OrdersRepositoryImpl _repositoryWithInvalidPayload(
  OrdersLocalDataSource localDataSource,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.mockapi.com'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(requestOptions: options, data: {'wrong': []}),
          );
        },
      ),
    );

  return OrdersRepositoryImpl(
    remoteDataSource: OrdersRemoteDataSource(dio),
    localDataSource: localDataSource,
    connectivityService: _FakeConnectivityService(),
  );
}

OrdersRepositoryImpl _repositoryWithHttpFailure(
  OrdersLocalDataSource localDataSource,
  int statusCode,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.mockapi.com'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: statusCode,
              ),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );

  return OrdersRepositoryImpl(
    remoteDataSource: OrdersRemoteDataSource(dio),
    localDataSource: localDataSource,
    connectivityService: _FakeConnectivityService(),
  );
}

OrdersRepositoryImpl _repositoryWithFailure(
  OrdersLocalDataSource localDataSource,
  DioExceptionType type,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.mockapi.com'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(DioException(requestOptions: options, type: type));
        },
      ),
    );

  return OrdersRepositoryImpl(
    remoteDataSource: OrdersRemoteDataSource(dio),
    localDataSource: localDataSource,
    connectivityService: _FakeConnectivityService(),
  );
}

class _FakeConnectivityService extends ConnectivityService {
  @override
  Future<bool> hasNetwork() async => true;

  @override
  Stream<bool> get onConnectionChanged => const Stream<bool>.empty();
}

Order _cachedOrder() => const Order(
  orderNumber: 'W-2048',
  date: null,
  total: 7500,
  status: 'in_transit',
  customerName: 'محمد أحمد',
  address: 'شارع الزبيري، صنعاء',
  items: [
    OrderItem(name: 'قهوة عربية', quantity: 2, price: 2500),
    OrderItem(name: 'تمر', quantity: 1, price: 2500),
  ],
  timeline: [
    OrderTimelineStep(title: 'تم استلام الطلب', completed: true),
    OrderTimelineStep(title: 'في الطريق', completed: false),
  ],
);

Map<String, dynamic> _remoteOrderJson() => {
  'orderNumber': 'W-2048',
  'date': '2026-11-20T00:00:00.000Z',
  'total': 7500,
  'status': 'in_transit',
  'customerName': 'محمد أحمد',
  'address': 'شارع الزبيري، صنعاء',
  'items': [
    {'name': 'قهوة عربية', 'quantity': 2, 'price': 2500},
    {'name': 'تمر', 'quantity': 1, 'price': 2500},
  ],
  'timeline': [
    {'title': 'تم استلام الطلب', 'completed': true},
    {'title': 'في الطريق', 'completed': false},
  ],
};
