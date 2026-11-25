import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/order.dart';

class OrderItemsSection extends StatelessWidget {
  const OrderItemsSection({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrderSectionTitle(
          title: 'الأصناف',
          detail: itemsCountLabel(order.items.length),
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

class OrderTotalSection extends StatelessWidget {
  const OrderTotalSection({super.key, required this.order});

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
                  itemsCountLabel(order.items.length),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Text(
            formatYemeniRial(order.total),
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
                      '${item.quantity} × ${formatYemeniRial(item.price)} للوحدة',
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
                formatYemeniRial(item.price * item.quantity),
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

class DeliveryAddressSection extends StatelessWidget {
  const DeliveryAddressSection({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OrderSectionTitle(title: 'عنوان التوصيل'),
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

class OrderSectionTitle extends StatelessWidget {
  const OrderSectionTitle({super.key, required this.title, this.detail});

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

String formatYemeniRial(double amount) {
  return '${NumberFormat('#,##0.##', 'ar').format(amount)} ر.ي';
}

String itemsCountLabel(int count) => switch (count) {
  0 => 'لا توجد أصناف',
  1 => 'صنف واحد',
  2 => 'صنفان',
  < 11 => '$count أصناف',
  _ => '$count صنفًا',
};
