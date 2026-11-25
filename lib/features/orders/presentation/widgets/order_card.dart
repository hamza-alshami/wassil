import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/order.dart';
import 'order_status_badge.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderLabel = 'طلب #${order.orderNumber}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(17, 16, 17, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Hero(
                      tag: 'order-number-${order.orderNumber}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          orderLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .05,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  OrderStatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: AppTheme.space12),
              const Divider(height: 1),
              const SizedBox(height: AppTheme.space12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppTheme.muted,
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: Text(
                      _formatDate(context, order.date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatYemeniRial(order.total),
                        maxLines: 1,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'إجمالي الطلب',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 17,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return 'تاريخ غير متوفر';
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  // formatYemeniRial lives in core/utils/formatters.dart
}
