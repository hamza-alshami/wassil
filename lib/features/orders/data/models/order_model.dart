import '../../domain/entities/order.dart';

/// Converts API JSON into the domain [Order] entity with field validation.
class OrderModel {
  const OrderModel._(this.order);

  final Order order;

  /// Parses an order object and rejects malformed required values.
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final rawTimeline = json['timeline'];
    if (rawItems is! List || rawTimeline is! List) {
      throw const FormatException('Order items and timeline must be lists');
    }

    final rawDate = json['date']?.toString();
    return OrderModel._(
      Order(
        orderNumber: _requiredText(json['orderNumber'], 'orderNumber'),
        date: rawDate == null ? null : DateTime.tryParse(rawDate),
        total: _number(json['total'], 'total'),
        status: _requiredText(json['status'], 'status'),
        customerName: _optionalText(json['customerName']),
        address: _optionalText(json['address']),
        items: rawItems
            .map((item) {
              if (item is! Map) {
                throw const FormatException('Order item must be an object');
              }
              final itemJson = Map<String, dynamic>.from(item);
              return OrderItem(
                name: _requiredText(itemJson['name'], 'items.name'),
                quantity: _number(
                  itemJson['quantity'],
                  'items.quantity',
                ).toInt(),
                price: _number(itemJson['price'], 'items.price'),
              );
            })
            .toList(growable: false),
        timeline: rawTimeline
            .map((step) {
              if (step is! Map) {
                throw const FormatException('Timeline step must be an object');
              }
              final stepJson = Map<String, dynamic>.from(step);
              final completed = stepJson['completed'];
              if (completed is! bool) {
                throw const FormatException(
                  'Timeline completed must be boolean',
                );
              }
              return OrderTimelineStep(
                title: _requiredText(stepJson['title'], 'timeline.title'),
                completed: completed,
              );
            })
            .toList(growable: false),
      ),
    );
  }

  static String _requiredText(Object? value, String field) {
    if (value == null || value.toString().trim().isEmpty) {
      throw FormatException('Missing or empty field: $field');
    }
    return value.toString();
  }

  static String _optionalText(Object? value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'غير متوفر';
    }
    return value.toString();
  }

  static double _number(Object? value, String field) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Invalid number in field: $field');
  }
}
