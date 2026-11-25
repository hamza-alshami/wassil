import 'package:flutter/material.dart';

import '../../domain/repositories/orders_repository.dart';

class OrdersConnectivityBanner extends StatelessWidget {
  const OrdersConnectivityBanner({super.key, required this.snapshot});

  final OrdersSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final isOfflineCache = snapshot.isFromCache && snapshot.isOffline;
    final isCached = snapshot.isFromCache;
    final backgroundColor = isOfflineCache
        ? const Color(0xFFFFF3D9)
        : const Color(0xFFDDF3E8);
    final foregroundColor = isOfflineCache
        ? const Color(0xFF805500)
        : const Color(0xFF153D35);
    final icon = isCached
        ? Icons.cloud_off_outlined
        : Icons.cloud_done_outlined;
    final message = isOfflineCache
        ? 'أنت غير متصل بالإنترنت – تعرض آخر بيانات محفوظة'
        : isCached
        ? 'تعذر تحديث البيانات – تعرض آخر نسخة محفوظة'
        : 'متصل بالإنترنت';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: foregroundColor),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isCached) ...[
                  const SizedBox(height: 3),
                  const Text(
                    'قد تكون البيانات قديمة.',
                    style: TextStyle(color: Color(0xFF66736E), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrdersLoadingState extends StatelessWidget {
  const OrdersLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class OrdersEmptyState extends StatelessWidget {
  const OrdersEmptyState({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 100),
          Icon(Icons.inbox_outlined, size: 52, color: Color(0xFF80918A)),
          SizedBox(height: 16),
          Center(child: Text('لا توجد طلبات حتى الآن')),
          SizedBox(height: 8),
          Center(child: Text('اسحب للأسفل لتحديث القائمة')),
        ],
      ),
    );
  }
}

class OrdersErrorState extends StatelessWidget {
  const OrdersErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Color(0xFF80918A),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
