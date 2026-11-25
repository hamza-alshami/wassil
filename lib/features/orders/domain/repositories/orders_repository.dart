import '../entities/order.dart';

abstract interface class OrdersRepository {
  /// Loads a fresh snapshot or falls back to the most recently saved one.
  Future<OrdersSnapshot> getOrders();
}

/// Orders plus metadata that describes their source to the presentation layer.
class OrdersSnapshot {
  const OrdersSnapshot({
    required this.orders,
    required this.isFromCache,
    required this.isOffline,
    this.savedAt,
  });

  final List<Order> orders;
  final bool isFromCache;
  final bool isOffline;
  final DateTime? savedAt;
}

/// Indicates remote loading failed and no local snapshot was available.
class OrdersUnavailableException implements Exception {
  const OrdersUnavailableException({required this.isOffline, this.statusCode});

  final bool isOffline;
  final int? statusCode;
}
