import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/repositories/orders_repository.dart';
import 'orders_states.dart';

/// App-bar style header that shows the order count badge and connectivity
/// banner once data is loaded.
class OrdersHeader extends StatelessWidget {
  const OrdersHeader({super.key, required this.snapshot});

  final OrdersSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final count = snapshot?.orders.length;
    final countLabel = switch (count) {
      null => null,
      0 => 'لا توجد طلبات',
      1 => 'طلب واحد',
      2 => 'طلبان',
      < 11 => '$count طلبات',
      _ => '$count طلب',
    };
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 21),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_mall_outlined,
                  size: 21,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'وصّل',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'متابعة الطلبات',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (countLabel != null)
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(11, 7, 11, 7),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Text(
                        countLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'طلباتي',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      'تابع طلباتك وحالة التوصيل',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (snapshot != null) ...[
            const SizedBox(height: AppTheme.space16),
            OrdersConnectivityBanner(snapshot: snapshot!),
          ],
        ],
      ),
    );
  }
}
