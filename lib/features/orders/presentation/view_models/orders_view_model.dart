import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/orders_local_data_source.dart';
import '../../data/datasources/orders_remote_data_source.dart';
import '../../data/repositories/orders_repository_impl.dart';
import '../../domain/repositories/orders_repository.dart';

final dioProvider = Provider<Dio>((ref) => DioClient.create());

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

final ordersRemoteDataSourceProvider = Provider<OrdersRemoteDataSource>(
  (ref) => OrdersRemoteDataSource(ref.watch(dioProvider)),
);

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final ordersLocalDataSourceProvider = Provider<OrdersLocalDataSource>(
  (ref) => OrdersLocalDataSource(ref.watch(appDatabaseProvider)),
);

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepositoryImpl(
    remoteDataSource: ref.watch(ordersRemoteDataSourceProvider),
    localDataSource: ref.watch(ordersLocalDataSourceProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
  ),
);

final ordersViewModelProvider =
    AsyncNotifierProvider<OrdersViewModel, OrdersSnapshot>(
      OrdersViewModel.new,
      // Retry is user-initiated through the screen's retry action or refresh.
      retry: (_, _) => null,
    );

/// Exposes loading, success and error states to the orders screens.
class OrdersViewModel extends AsyncNotifier<OrdersSnapshot> {
  StreamSubscription<bool>? _connectivitySubscription;
  AppLifecycleListener? _lifecycleListener;
  Future<void>? _refreshInFlight;
  bool? _lastHasNetwork;

  @override
  Future<OrdersSnapshot> build() async {
    final connectivityService = ref.watch(connectivityServiceProvider);
    unawaited(_connectivitySubscription?.cancel());
    _connectivitySubscription = connectivityService.onConnectionChanged.listen(
      (hasNetwork) => unawaited(_handleConnectionChange(hasNetwork)),
      onError: (error, stackTrace) => unawaited(refresh()),
    );
    _lifecycleListener?.dispose();
    _lifecycleListener = AppLifecycleListener(onResume: _checkOnResume);
    ref.onDispose(() {
      unawaited(_connectivitySubscription?.cancel());
      _lifecycleListener?.dispose();
    });

    try {
      final snapshot = await ref.watch(ordersRepositoryProvider).getOrders();
      _lastHasNetwork = !snapshot.isOffline;
      return snapshot;
    } on OrdersUnavailableException catch (error) {
      _lastHasNetwork = !error.isOffline;
      rethrow;
    }
  }

  /// Repeats the load and exposes any failure as an AsyncValue error.
  Future<void> refresh() {
    final currentRefresh = _refreshInFlight;
    if (currentRefresh != null) return currentRefresh;

    final refresh = _refreshOrders();
    _refreshInFlight = refresh;
    return refresh.whenComplete(() {
      if (identical(_refreshInFlight, refresh)) _refreshInFlight = null;
    });
  }

  Future<void> _refreshOrders() async {
    final result = await AsyncValue.guard(
      () => ref.read(ordersRepositoryProvider).getOrders(),
    );
    state = result;

    final snapshot = result.value;
    if (snapshot != null) {
      _lastHasNetwork = !snapshot.isOffline;
      return;
    }

    final error = result.error;
    if (error is OrdersUnavailableException) {
      _lastHasNetwork = !error.isOffline;
    }
  }

  Future<void> _handleConnectionChange(bool hasNetwork) async {
    final previousConnection = _lastHasNetwork;
    _lastHasNetwork = hasNetwork;

    // First event ever: only refresh if we're offline and have no data yet.
    if (previousConnection == null) {
      if (!hasNetwork && state.value == null) await refresh();
      return;
    }

    // No real change — nothing to do.
    if (previousConnection == hasNetwork) return;

    // Connection restored: refresh to load fresh data.
    // If a refresh was already in flight when we came back online, the network
    // might have flipped again before it finished — do a second pass to be sure.
    if (hasNetwork) {
      final hadRefreshInFlight = _refreshInFlight != null;
      await refresh();
      if (hadRefreshInFlight && _lastHasNetwork != true) await refresh();
      return;
    }

    // Connection lost: refresh so the UI reflects the offline state.
    await refresh();
  }

  Future<void> _checkOnResume() async {
    final hasNetwork = await ref.read(connectivityServiceProvider).hasNetwork();
    await _handleConnectionChange(hasNetwork);
  }
}
