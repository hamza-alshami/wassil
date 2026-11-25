import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final presentation = _StatusPresentation.from(status);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 11, 6),
      decoration: BoxDecoration(
        color: presentation.background,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: presentation.foreground.withValues(alpha: .1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(presentation.icon, size: 14, color: presentation.foreground),
          const SizedBox(width: 5),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              presentation.label,
              key: ValueKey(presentation.label),
              maxLines: 1,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: presentation.foreground,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPresentation {
  const _StatusPresentation({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  factory _StatusPresentation.from(String rawStatus) {
    final status = rawStatus.trim().toLowerCase().replaceAll('-', '_');
    return switch (status) {
      'pending' => const _StatusPresentation(
        label: 'قيد الانتظار',
        icon: Icons.schedule_rounded,
        foreground: AppTheme.statusPending,
        background: AppTheme.statusPendingSurface,
      ),
      'confirmed' || 'processing' || 'preparing' => const _StatusPresentation(
        label: 'قيد التجهيز',
        icon: Icons.inventory_2_outlined,
        foreground: AppTheme.statusPending,
        background: AppTheme.statusPendingSurface,
      ),
      'shipped' ||
      'delivering' ||
      'in_transit' ||
      'on_the_way' ||
      'out_for_delivery' => const _StatusPresentation(
        label: 'في الطريق',
        icon: Icons.local_shipping_outlined,
        foreground: AppTheme.statusActive,
        background: AppTheme.statusActiveSurface,
      ),
      'delivered' || 'تم التوصيل' => const _StatusPresentation(
        label: 'تم التوصيل',
        icon: Icons.check_circle_outline_rounded,
        foreground: AppTheme.statusDelivered,
        background: AppTheme.statusDeliveredSurface,
      ),
      'cancelled' || 'canceled' || 'ملغي' => const _StatusPresentation(
        label: 'ملغي',
        icon: Icons.cancel_outlined,
        foreground: AppTheme.statusCancelled,
        background: AppTheme.statusCancelledSurface,
      ),
      _ => _unknownStatus(rawStatus),
    };
  }

  static _StatusPresentation _unknownStatus(String status) {
    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(status);
    return _StatusPresentation(
      label: isArabic ? status : 'حالة غير معروفة',
      icon: Icons.info_outline_rounded,
      foreground: const Color(0xFF65756D),
      background: const Color(0xFFEDF1EE),
    );
  }
}
