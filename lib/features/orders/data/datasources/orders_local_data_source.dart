import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';

/// Persists and restores complete orders, including items and delivery steps.
class OrdersLocalDataSource {
  OrdersLocalDataSource(this.appDatabase);

  final AppDatabase appDatabase;

  /// Replaces the snapshot atomically so failed writes preserve old data.
  Future<void> replaceOrders(
    List<Order> orders, {
    required DateTime savedAt,
  }) async {
    final database = await appDatabase.database;

    await database.transaction((transaction) async {
      await transaction.delete('order_items');
      await transaction.delete('order_timeline');
      await transaction.delete('orders');

      for (
        var orderPosition = 0;
        orderPosition < orders.length;
        orderPosition++
      ) {
        final order = orders[orderPosition];
        await transaction.insert('orders', {
          'order_number': order.orderNumber,
          'position': orderPosition,
          'date': order.date?.toIso8601String(),
          'total': order.total,
          'status': order.status,
          'customer_name': order.customerName,
          'address': order.address,
        });

        for (
          var itemPosition = 0;
          itemPosition < order.items.length;
          itemPosition++
        ) {
          final item = order.items[itemPosition];
          await transaction.insert('order_items', {
            'order_number': order.orderNumber,
            'position': itemPosition,
            'name': item.name,
            'quantity': item.quantity,
            'price': item.price,
          });
        }

        for (
          var stepPosition = 0;
          stepPosition < order.timeline.length;
          stepPosition++
        ) {
          final step = order.timeline[stepPosition];
          await transaction.insert('order_timeline', {
            'order_number': order.orderNumber,
            'position': stepPosition,
            'title': step.title,
            'completed': step.completed ? 1 : 0,
          });
        }
      }

      await transaction.insert('sync_metadata', {
        'id': 1,
        'saved_at': savedAt.toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  /// Returns the last saved snapshot, or null if no sync has completed.
  Future<OrdersSnapshot?> getCachedOrders({required bool isOffline}) async {
    final database = await appDatabase.database;
    final metadataRows = await database.query(
      'sync_metadata',
      where: 'id = ?',
      whereArgs: const [1],
      limit: 1,
    );
    if (metadataRows.isEmpty) return null;

    final orderRows = await database.query('orders', orderBy: 'position ASC');
    final itemRows = await database.query(
      'order_items',
      orderBy: 'order_number ASC, position ASC',
    );
    final timelineRows = await database.query(
      'order_timeline',
      orderBy: 'order_number ASC, position ASC',
    );
    final itemsByOrder = _groupRows(itemRows);
    final timelineByOrder = _groupRows(timelineRows);
    final orders = orderRows
        .map((row) {
          final orderNumber = row['order_number'] as String;
          final dateText = row['date'] as String?;
          return Order(
            orderNumber: orderNumber,
            date: dateText == null ? null : DateTime.tryParse(dateText),
            total: (row['total'] as num).toDouble(),
            status: row['status'] as String,
            customerName: row['customer_name'] as String,
            address: row['address'] as String,
            items: (itemsByOrder[orderNumber] ?? const <Map<String, Object?>>[])
                .map(
                  (item) => OrderItem(
                    name: item['name'] as String,
                    quantity: item['quantity'] as int,
                    price: (item['price'] as num).toDouble(),
                  ),
                )
                .toList(growable: false),
            timeline:
                (timelineByOrder[orderNumber] ?? const <Map<String, Object?>>[])
                    .map(
                      (step) => OrderTimelineStep(
                        title: step['title'] as String,
                        completed: (step['completed'] as int) == 1,
                      ),
                    )
                    .toList(growable: false),
          );
        })
        .toList(growable: false);

    final savedAtText = metadataRows.first['saved_at'] as String;
    return OrdersSnapshot(
      orders: orders,
      isFromCache: true,
      isOffline: isOffline,
      savedAt: DateTime.tryParse(savedAtText),
    );
  }

  Map<String, List<Map<String, Object?>>> _groupRows(
    List<Map<String, Object?>> rows,
  ) {
    final groupedRows = <String, List<Map<String, Object?>>>{};
    for (final row in rows) {
      final orderNumber = row['order_number'] as String;
      groupedRows.putIfAbsent(orderNumber, () => []).add(row);
    }
    return groupedRows;
  }
}
