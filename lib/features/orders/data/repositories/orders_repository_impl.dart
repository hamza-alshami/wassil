import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/connectivity_service.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_local_data_source.dart';
import '../datasources/orders_remote_data_source.dart';
import '../models/order_model.dart';

/// Coordinates remote refreshes and the SQLite fallback for orders.
class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.connectivityService,
  });

  final OrdersRemoteDataSource remoteDataSource;
  final OrdersLocalDataSource localDataSource;
  final ConnectivityService connectivityService;

  @override
  /// Fetches fresh data first and falls back to the last snapshot on Dio errors.
  Future<OrdersSnapshot> getOrders() async {
    final hasNetwork = await connectivityService.hasNetwork();
    if (!hasNetwork) {
      final cachedOrders = await localDataSource.getCachedOrders(
        isOffline: true,
      );
      if (cachedOrders != null) return cachedOrders;
      throw const OrdersUnavailableException(isOffline: true);
    }

    try {
      final ordersJson = await remoteDataSource.getOrders();
      final orders = ordersJson
          .map((json) => OrderModel.fromJson(json).order)
          .toList()
        ..sort((left, right) {
          final leftDate = left.date;
          final rightDate = right.date;
          if (leftDate == null) return rightDate == null ? 0 : 1;
          if (rightDate == null) return -1;
          return rightDate.compareTo(leftDate);
        });
      final savedAt = DateTime.now().toUtc();

      try {
        await localDataSource.replaceOrders(orders, savedAt: savedAt);
      } catch (error) {
        debugPrint('Orders cache write failed: ${error.runtimeType}');
      }

      return OrdersSnapshot(
        orders: orders,
        isFromCache: false,
        isOffline: false,
        savedAt: savedAt,
      );
    } on DioException catch (error) {
      final isOffline = error.response == null;
      final cachedOrders = await localDataSource.getCachedOrders(
        isOffline: isOffline,
      );
      if (cachedOrders != null) return cachedOrders;

      throw OrdersUnavailableException(
        isOffline: isOffline,
        statusCode: error.response?.statusCode,
      );
    } on FormatException {
      final cachedOrders = await localDataSource.getCachedOrders(
        isOffline: false,
      );
      if (cachedOrders != null) return cachedOrders;
      rethrow;
    }
  }
}
