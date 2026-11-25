import 'package:flutter/material.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.trim().toLowerCase().replaceAll('-', '_');
    final isDelivered =
        normalizedStatus == 'delivered' || status == 'تم التوصيل';
    final isCancelled =
        normalizedStatus == 'cancelled' ||
        normalizedStatus == 'canceled' ||
        status == 'ملغي';
    final label = switch (normalizedStatus) {
      'pending' => 'قيد الانتظار',
      'confirmed' => 'تم التأكيد',
      'processing' || 'preparing' => 'قيد التجهيز',
      'shipped' ||
      'delivering' ||
      'in_transit' ||
      'on_the_way' ||
      'out_for_delivery' => 'في الطريق',
      'delivered' => 'تم التوصيل',
      'cancelled' || 'canceled' => 'ملغي',
      _ =>
        RegExp(r'[\u0600-\u06FF]').hasMatch(status)
            ? status
            : 'حالة غير معروفة',
    };
    final backgroundColor = isDelivered
        ? const Color(0xFFE4F4EA)
        : isCancelled
        ? const Color(0xFFFCE8E6)
        : const Color(0xFFFFF3D9);
    final foregroundColor = isDelivered
        ? const Color(0xFF246B45)
        : isCancelled
        ? const Color(0xFFB3261E)
        : const Color(0xFF8A5A00);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
