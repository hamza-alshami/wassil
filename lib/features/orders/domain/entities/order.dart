/// A delivery order shown in the orders list and details screen.
class Order {
  const Order({
    required this.orderNumber,
    required this.date,
    required this.total,
    required this.status,
    required this.customerName,
    required this.address,
    required this.items,
    required this.timeline,
  });

  final String orderNumber;
  final DateTime? date;
  final double total;
  final String status;
  final String customerName;
  final String address;
  final List<OrderItem> items;
  final List<OrderTimelineStep> timeline;
}

/// A product and its quantity and unit price within an order.
class OrderItem {
  const OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  final String name;
  final int quantity;
  final double price;
}

/// One named delivery milestone and whether it has been completed.
class OrderTimelineStep {
  const OrderTimelineStep({required this.title, required this.completed});

  final String title;
  final bool completed;
}
