import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/order.dart';

class OrderProgressTimeline extends StatelessWidget {
  const OrderProgressTimeline({super.key, required this.order});

  final Order order;

  static const _labels = [
    'استلام\nالطلب',
    'تأكيد\nالطلب',
    'تجهيز\nالطلب',
    'التوصيل',
  ];
  static const _icons = [
    Icons.receipt_long_rounded,
    Icons.verified_outlined,
    Icons.inventory_2_outlined,
    Icons.local_shipping_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final completedCount = _completedStageCount();
    final isCancelled =
        _normalizedStatus == 'cancelled' ||
        _normalizedStatus == 'canceled' ||
        _normalizedStatus == 'ملغي';
    final trackProgress = (completedCount / 3).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 17, 16, 15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'رحلة الطلب',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isCancelled)
                const _CancelledLabel()
              else
                Text(
                  completedCount == 4
                      ? 'اكتمل الطلب'
                      : 'المرحلة ${completedCount + 1} من 4',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 21),
          LayoutBuilder(
            builder: (context, constraints) {
              final trackInset = constraints.maxWidth / 8;
              return SizedBox(
                height: 81,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    PositionedDirectional(
                      start: trackInset,
                      end: trackInset,
                      top: 17,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: trackProgress),
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeInOutCubic,
                        builder: (context, value, _) => SizedBox(
                          height: 3,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE7ECE8),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: FractionallySizedBox(
                                  widthFactor: value,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var index = 0; index < _labels.length; index++)
                          Expanded(
                            child: _ProgressStep(
                              index: index,
                              label: _labels[index],
                              icon: _icons[index],
                              isComplete: index < completedCount,
                              isCurrent:
                                  !isCancelled &&
                                  index == completedCount &&
                                  completedCount < _labels.length,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          if (isCancelled) ...[
            const SizedBox(height: 3),
            const Text(
              'توقفت مراحل التوصيل بعد إلغاء الطلب.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String get _normalizedStatus =>
      order.status.trim().toLowerCase().replaceAll('-', '_');

  int _completedStageCount() {
    return switch (_normalizedStatus) {
      'pending' || 'قيد الانتظار' => 1,
      'confirmed' || 'processing' || 'preparing' || 'قيد التجهيز' => 2,
      'shipped' ||
      'delivering' ||
      'in_transit' ||
      'on_the_way' ||
      'out_for_delivery' ||
      'في الطريق' => 3,
      'delivered' || 'تم التوصيل' => 4,
      'cancelled' || 'canceled' || 'ملغي' => 1,
      _ => _completedFromTimeline(),
    };
  }

  int _completedFromTimeline() {
    final completedTitles = order.timeline
        .where((step) => step.completed)
        .map((step) => step.title.toLowerCase())
        .toList(growable: false);
    var count = 0;
    const stageWords = [
      ['استلام', 'received'],
      ['تأكيد', 'confirmed'],
      ['تجهيز', 'prepared', 'preparing'],
      ['توصيل', 'تسليم', 'delivery', 'delivered'],
    ];
    for (final words in stageWords) {
      if (completedTitles.any((title) => words.any(title.contains))) {
        count++;
      } else {
        break;
      }
    }
    return count.clamp(0, _labels.length);
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.index,
    required this.label,
    required this.icon,
    required this.isComplete,
    required this.isCurrent,
  });

  final int index;
  final String label;
  final IconData icon;
  final bool isComplete;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final foreground = isComplete || isCurrent
        ? AppTheme.primary
        : const Color(0xFFAAB5AE);
    final background = isComplete
        ? AppTheme.primary
        : isCurrent
        ? AppTheme.accent
        : const Color(0xFFF0F3F1);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(13),
            border: isCurrent
                ? Border.all(color: AppTheme.primary.withValues(alpha: .22))
                : null,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: .10),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isComplete ? Icons.check_rounded : icon,
              key: ValueKey(isComplete),
              size: 18,
              color: isComplete ? Colors.white : foreground,
            ),
          ),
        ),
        const SizedBox(height: 9),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isComplete || isCurrent ? AppTheme.ink : AppTheme.muted,
              fontSize: 10.5,
              height: 1.2,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _CancelledLabel extends StatelessWidget {
  const _CancelledLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 9, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEBE9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.close_rounded, size: 13, color: Color(0xFFAD453C)),
          SizedBox(width: 4),
          Text(
            'ملغي',
            style: TextStyle(
              color: Color(0xFFAD453C),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
