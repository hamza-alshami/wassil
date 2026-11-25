import 'package:dio/dio.dart';

/// Reads and validates orders returned by the remote API.
class OrdersRemoteDataSource {
  OrdersRemoteDataSource(this.dio);

  final Dio dio;

  /// Returns order objects nested in the API response's `data` field.
  Future<List<Map<String, dynamic>>> getOrders() async {
    final response = await dio.get('/orders');
    final responseData = response.data;

    if (responseData is! Map || responseData['data'] is! List) {
      throw const FormatException(
        'Expected a data object containing a list of orders',
      );
    }

    final ordersData = responseData['data'] as List;

    return ordersData
        .map((item) {
          if (item is! Map) {
            throw const FormatException('Each order must be an object');
          }
          return Map<String, dynamic>.from(item);
        })
        .toList(growable: false);
  }
}
