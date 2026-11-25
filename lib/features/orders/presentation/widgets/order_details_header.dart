import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/order.dart';
import 'order_status_badge.dart';

class OrderDetailsHeader extends StatelessWidget {
  const OrderDetailsHeader({super.key, required this.order});

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
