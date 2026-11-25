import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/order.dart';

class OrderProgressTimeline extends StatefulWidget {
  const OrderProgressTimeline({super.key, required this.order});

  final Order order;

  @override
  State<OrderProgressTimeline> createState() => _OrderProgressTimelineState();
}

class _OrderProgressTimelineState extends State<OrderProgressTimeline>
    with SingleTickerProviderStateMixin {
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

  late final AnimationController _controller;
  late int _targetStage;
  late bool _isCancelled;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _targetStage = _targetStageFor(widget.order);
    _isCancelled = _isCancelledStatus(widget.order.status);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 720 * math.max(1, _targetStage)),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasStarted) return;
    _hasStarted = true;
    _startJourney();
  }

  @override
  void didUpdateWidget(covariant OrderProgressTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextTargetStage = _targetStageFor(widget.order);
    final nextIsCancelled = _isCancelledStatus(widget.order.status);
    if (oldWidget.order.orderNumber == widget.order.orderNumber &&
        _targetStage == nextTargetStage &&
        _isCancelled == nextIsCancelled) {
      return;
    }

    _targetStage = nextTargetStage;
    _isCancelled = nextIsCancelled;
    _controller
      ..stop()
      ..duration = Duration(milliseconds: 720 * math.max(1, _targetStage))
      ..reset();
    _startJourney();
  }

  void _startJourney() {
    if (_isCancelled ||
        _targetStage == 0 ||
        MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppTheme.space16,
        AppTheme.space16,
        AppTheme.space16,
        AppTheme.space12,
      ),
      decoration: AppTheme.surfaceDecoration(),
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
              if (_isCancelled)
                const _CancelledLabel()
              else
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final stage = _currentStage(_journeyProgress);
                    final isDelivered =
                        _normalizedStatus == 'delivered' &&
                        _controller.isCompleted;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        isDelivered
                            ? 'اكتمل الطلب'
                            : 'المرحلة ${stage + 1} من 4',
                        key: ValueKey('${stage}_$isDelivered'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space20),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = _journeyProgress;
              final stage = _currentStage(progress);
              final isDelivered =
                  _normalizedStatus == 'delivered' && _controller.isCompleted;
              final fillFraction = (progress / 3).clamp(0.0, 1.0);

              return LayoutBuilder(
                builder: (context, constraints) {
                  final trackInset = constraints.maxWidth / 8;
                  final trackWidth = math.max(
                    0.0,
                    constraints.maxWidth - (trackInset * 2),
                  );
                  final indicatorStart =
                      (trackInset + (trackWidth * fillFraction) - 7)
                          .clamp(0.0, math.max(0.0, constraints.maxWidth - 14))
                          .toDouble();

                  return SizedBox(
                    height: 82,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        PositionedDirectional(
                          start: trackInset,
                          end: trackInset,
                          top: 17,
                          child: SizedBox(
                            height: 3,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: AppTheme.outline,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: FractionallySizedBox(
                                    widthFactor: fillFraction,
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
                        if (!_isCancelled && _targetStage > 0)
                          PositionedDirectional(
                            start: indicatorStart,
                            top: 11,
                            child: const _MovingIndicator(),
                          ),
                        Row(
                          children: [
                            for (var index = 0; index < _labels.length; index++)
                              Expanded(
                                child: _ProgressStep(
                                  key: ValueKey(
                                    'timeline-stage-$index-${_stageState(index: index, progress: progress, currentStage: stage, isDelivered: isDelivered).name}',
                                  ),
                                  label: _labels[index],
                                  icon: _icons[index],
                                  state: _stageState(
                                    index: index,
                                    progress: progress,
                                    currentStage: stage,
                                    isDelivered: isDelivered,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          if (_isCancelled) ...[
            const SizedBox(height: AppTheme.space8),
            const Text(
              'أُلغي هذا الطلب قبل اكتمال رحلة التوصيل.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  double get _journeyProgress => _targetStage * _controller.value;

  String get _normalizedStatus =>
      widget.order.status.trim().toLowerCase().replaceAll('-', '_');

  int _currentStage(double progress) {
    if (_isCancelled) return 0;
    return progress.floor().clamp(0, _labels.length - 1);
  }

  _StageState _stageState({
    required int index,
    required double progress,
    required int currentStage,
    required bool isDelivered,
  }) {
    if (_isCancelled) {
      return index == 0 ? _StageState.complete : _StageState.future;
    }
    if (isDelivered || index < progress.floor()) return _StageState.complete;
    if (index == currentStage) return _StageState.current;
    return _StageState.future;
  }

  static bool _isCancelledStatus(String status) {
    final normalized = status.trim().toLowerCase().replaceAll('-', '_');
    return normalized == 'cancelled' ||
        normalized == 'canceled' ||
        normalized == 'ملغي';
  }

  static int _targetStageFor(Order order) {
    final status = order.status.trim().toLowerCase().replaceAll('-', '_');
    return switch (status) {
      'pending' || 'قيد الانتظار' => 0,
      'confirmed' || 'processing' || 'preparing' || 'قيد التجهيز' => 1,
      'shipped' ||
      'delivering' ||
      'in_transit' ||
      'on_the_way' ||
      'out_for_delivery' ||
      'في الطريق' => 2,
      'delivered' || 'تم التوصيل' => 3,
      'cancelled' || 'canceled' || 'ملغي' => 0,
      _ => _targetFromTimeline(order.timeline),
    };
  }

  static int _targetFromTimeline(List<OrderTimelineStep> timeline) {
    final completedTitles = timeline
        .where((step) => step.completed)
        .map((step) => step.title.toLowerCase())
        .toList(growable: false);
    const stageWords = [
      ['استلام', 'received'],
      ['تأكيد', 'confirmed'],
      ['تجهيز', 'prepared', 'preparing'],
      ['توصيل', 'تسليم', 'delivery', 'delivered'],
    ];
    var reached = 0;
    for (final words in stageWords) {
      if (!completedTitles.any((title) => words.any(title.contains))) break;
      reached++;
    }
    return (reached - 1).clamp(0, _labels.length - 1);
  }
}

enum _StageState { complete, current, future }

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    super.key,
    required this.label,
    required this.icon,
    required this.state,
  });

  final String label;
  final IconData icon;
  final _StageState state;

  @override
  Widget build(BuildContext context) {
    final isComplete = state == _StageState.complete;
    final isCurrent = state == _StageState.current;
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
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(13),
            border: isCurrent
                ? Border.all(color: AppTheme.primary.withValues(alpha: .22))
                : null,
            boxShadow: isCurrent ? AppTheme.softShadows : null,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              isComplete ? Icons.check_rounded : icon,
              key: ValueKey(isComplete),
              size: 18,
              color: isComplete ? Colors.white : foreground,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space8),
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

class _MovingIndicator extends StatelessWidget {
  const _MovingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.surface, width: 2),
        boxShadow: AppTheme.softShadows,
      ),
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
        color: AppTheme.statusCancelledSurface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.close_rounded, size: 13, color: AppTheme.statusCancelled),
          SizedBox(width: 4),
          Text(
            'ملغي',
            style: TextStyle(
              color: AppTheme.statusCancelled,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
