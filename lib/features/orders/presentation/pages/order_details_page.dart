import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/order.dart';
import '../widgets/order_progress_timeline.dart';
import '../widgets/order_status_badge.dart';

class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({super.key, required this.order});

  final Order order;

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  );
  late final CurvedAnimation _heroEntry = _entry(0, .36);
  late final CurvedAnimation _addressEntry = _entry(.08, .44);
  late final CurvedAnimation _progressEntry = _entry(.1, .56);
  late final CurvedAnimation _itemsEntry = _entry(.4, .8);
  late final CurvedAnimation _totalEntry = _entry(.55, .95);
  bool _entryStarted = false;

  CurvedAnimation _entry(double begin, double end) => CurvedAnimation(
    parent: _entryController,
    curve: Interval(begin, end, curve: Curves.easeOutCubic),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entryStarted) return;
    _entryStarted = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entryController.value = 1;
    } else {
      _entryController.forward();
    }
  }

  @override
  void dispose() {
    _heroEntry.dispose();
    _addressEntry.dispose();
    _progressEntry.dispose();
    _itemsEntry.dispose();
    _totalEntry.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطلب')),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 30),
        children: [
          _SectionEntrance(
            key: const ValueKey('details-order-header'),
            animation: _heroEntry,
            child: _OrderHero(order: widget.order),
          ),
          _SectionEntrance(
            key: const ValueKey('details-delivery-address'),
            animation: _addressEntry,
            child: _DeliverySection(order: widget.order),
          ),
          const SizedBox(height: AppTheme.space24),
          _SectionEntrance(
            key: const ValueKey('details-progress'),
            animation: _progressEntry,
            child: OrderProgressTimeline(order: widget.order),
          ),
          const SizedBox(height: AppTheme.space24),
          _SectionEntrance(
            key: const ValueKey('details-items'),
            animation: _itemsEntry,
            child: _ItemsSection(order: widget.order),
          ),
          const SizedBox(height: AppTheme.space16),
          _SectionEntrance(
            key: const ValueKey('details-total'),
            animation: _totalEntry,
            child: _OrderTotalSection(order: widget.order),
          ),
        ],
      ),
    );
  }
}

class _SectionEntrance extends StatelessWidget {
  const _SectionEntrance({
    super.key,
    required this.animation,
    required this.child,
  });

  static final Tween<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, .045),
    end: Offset.zero,
  );

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: _offset.animate(animation),
        child: child,
      ),
    );
  }
}

class _OrderHero extends StatelessWidget {
  const _OrderHero({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final date = order.date == null
        ? 'تاريخ غير متوفر'
        : MaterialLocalizations.of(context).formatMediumDate(order.date!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [AppTheme.primaryDeep, Color(0xFF245548)],
          ),
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              top: -48,
              end: -24,
              child: _HeroOrb(size: 148, opacity: .065),
            ),
            PositionedDirectional(
              bottom: -74,
              start: 90,
              child: _HeroOrb(size: 178, opacity: .045),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'رقم الطلب',
                          style: TextStyle(
                            color: Color(0xFFC6D8CF),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      OrderStatusBadge(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Hero(
                    tag: 'order-number-${order.orderNumber}',
                    child: Material(
                      color: Colors.transparent,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          order.orderNumber,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .25,
                              ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: Color(0xFFC6D8CF),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        date,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFE4EEE9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroOrb extends StatelessWidget {
  const _HeroOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: opacity)),
        ),
      ),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: 'الأصناف',
          detail: _itemsCountLabel(order.items.length),
        ),
        const SizedBox(height: AppTheme.space12),
        Container(
          decoration: AppTheme.surfaceDecoration(),
          child: Column(
            children: [
              if (order.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'لا توجد أصناف متاحة.',
                      style: TextStyle(color: AppTheme.muted),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(17, 4, 17, 5),
                  child: Column(
                    children: [
                      for (var index = 0; index < order.items.length; index++)
                        _OrderItemRow(
                          item: order.items[index],
                          index: index,
                          isLast: index == order.items.length - 1,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderTotalSection extends StatelessWidget {
  const _OrderTotalSection({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 17, 18, 17),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F2EC),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: const Color(0xFFD6E7DC)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إجمالي الطلب',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  _itemsCountLabel(order.items.length),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Text(
            _formatYemeniRial(order.total),
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({
    required this.item,
    required this.index,
    required this.isLast,
  });

  final OrderItem item;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F6F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.quantity} × ${_formatYemeniRial(item.price)} للوحدة',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatYemeniRial(item.price * item.quantity),
                textDirection: TextDirection.ltr,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (!isLast)
            const Padding(
              padding: EdgeInsetsDirectional.only(start: 41, top: 13),
              child: Divider(height: 1, color: Color(0xFFF0F3F1)),
            ),
        ],
      ),
    );
  }
}

class _DeliverySection extends StatelessWidget {
  const _DeliverySection({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(title: 'عنوان التوصيل'),
        const SizedBox(height: 11),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: AppTheme.surfaceDecoration(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppTheme.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      order.address,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.muted,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.detail});

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (detail != null)
          Text(
            detail!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

String _formatYemeniRial(double amount) {
  return '${NumberFormat('#,##0.##', 'ar').format(amount)} ر.ي';
}

String _itemsCountLabel(int count) => switch (count) {
  0 => 'لا توجد أصناف',
  1 => 'صنف واحد',
  2 => 'صنفان',
  < 11 => '$count أصناف',
  _ => '$count صنفًا',
};
