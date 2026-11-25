import '../../domain/entities/order.dart';

/// Maps an order's status or completed timeline to the four visible journey steps.
abstract final class OrderProgressStageResolver {
  static const int lastStageIndex = 3;

  static bool isCancelled(String status) {
    final normalized = _normalize(status);
    return normalized == 'cancelled' ||
        normalized == 'canceled' ||
        normalized == 'ملغي';
  }

  static bool isDelivered(String status) {
    final normalized = _normalize(status);
    return normalized == 'delivered' ||
        normalized == 'تم التوصيل' ||
        normalized == 'تم توصيل الطلب';
  }

  static int targetStageFor(Order order) {
    final status = _normalize(order.status);
    return switch (status) {
      'pending' ||
      'received' ||
      'order_received' ||
      'قيد الانتظار' ||
      'تم استلام الطلب' ||
      'تم استلام طلبك' => 0,
      'confirmed' || 'تم التأكيد' || 'تم تأكيد الطلب' => 1,
      'processing' || 'preparing' || 'قيد التجهيز' => 2,
      'shipped' ||
      'delivering' ||
      'in_transit' ||
      'on_the_way' ||
      'out_for_delivery' ||
      'في الطريق' ||
      'جاري التوصيل' => lastStageIndex,
      'delivered' || 'تم التوصيل' || 'تم توصيل الطلب' => lastStageIndex,
      'cancelled' || 'canceled' || 'ملغي' => 0,
      _ => _targetFromTimeline(order.timeline),
    };
  }

  static int _targetFromTimeline(List<OrderTimelineStep> timeline) {
    const stageWords = [
      ['استلام', 'received'],
      ['تأكيد', 'confirmed'],
      ['تجهيز', 'prepared', 'preparing'],
      ['توصيل', 'تسليم', 'delivery', 'delivered'],
    ];
    var reached = 0;

    for (final words in stageWords) {
      final stageIsComplete = timeline.any(
        (step) => step.completed && words.any(_normalize(step.title).contains),
      );
      if (!stageIsComplete) break;
      reached++;
    }

    return reached.clamp(0, lastStageIndex);
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll('-', '_');
}
