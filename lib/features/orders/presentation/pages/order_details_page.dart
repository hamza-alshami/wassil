import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/order.dart';
import '../widgets/order_status_badge.dart';

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطلب')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Card(
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
                          style: textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF153D35),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      OrderStatusBadge(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'تاريخ الطلب',
                    value: _formatDate(context, order.date),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('مراحل التوصيل', style: textTheme.titleMedium),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: order.timeline.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('لا توجد مراحل توصيل متاحة.'),
                    )
                  : Column(
                      children: [
                        for (
                          var index = 0;
                          index < order.timeline.length;
                          index++
                        )
                          _TimelineStep(
                            step: order.timeline[index],
                            isLast: index == order.timeline.length - 1,
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Text('الأصناف', style: textTheme.titleMedium),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (order.items.isEmpty)
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text('لا توجد أصناف متاحة.'),
                    ),
                  for (var index = 0; index < order.items.length; index++) ...[
                    _OrderItemRow(item: order.items[index]),
                    if (index < order.items.length - 1)
                      const Divider(height: 22),
                  ],
                  const Divider(height: 26),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'الإجمالي',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        _formatYemeniRial(order.total),
                        style: const TextStyle(
                          color: Color(0xFF153D35),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('التوصيل إلى', style: textTheme.titleMedium),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 19,
                        color: Color(0xFF66736E),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(order.address)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return 'تاريخ غير متوفر';
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  String _formatYemeniRial(double amount) {
    return '${NumberFormat('#,##0.##', 'ar').format(amount)} ر.ي';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF66736E)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Color(0xFF66736E))),
        Expanded(child: Text(value)),
      ],
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'الكمية: ${item.quantity}',
                style: const TextStyle(color: Color(0xFF66736E)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(_formatYemeniRial(item.price * item.quantity)),
      ],
    );
  }

  String _formatYemeniRial(double amount) {
    return '${NumberFormat('#,##0.##', 'ar').format(amount)} ر.ي';
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.step, required this.isLast});

  final OrderTimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = step.completed
        ? const Color(0xFF153D35)
        : const Color(0xFFBCC8C2);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 26,
          child: Column(
            children: [
              Icon(
                step.completed
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 19,
                color: color,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 32,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  color: step.completed
                      ? const Color(0xFF9ACDB1)
                      : const Color(0xFFE2E8E4),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 22, top: 1),
            child: Text(
              step.title,
              style: TextStyle(
                color: step.completed
                    ? const Color(0xFF153D35)
                    : const Color(0xFF66736E),
                fontWeight: step.completed
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
