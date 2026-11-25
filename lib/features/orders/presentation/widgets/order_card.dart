import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/order.dart';
import 'order_status_badge.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'طلب #${order.orderNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF153D35),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OrderStatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 17),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDate(context, order.date),
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF66736E),
                      ),
                    ),
                  ),
                  Text(
                    _formatYemeniRial(order.total),
                    style: textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF153D35),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xFF153D35),
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

  String _formatYemeniRial(double amount) {
    final formattedAmount = NumberFormat('#,##0.##', 'ar').format(amount);
    return '$formattedAmount ر.ي';
  }
}
