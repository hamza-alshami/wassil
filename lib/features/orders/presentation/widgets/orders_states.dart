import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/repositories/orders_repository.dart';

class OrdersConnectivityBanner extends StatelessWidget {
  const OrdersConnectivityBanner({super.key, required this.snapshot});

  final OrdersSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final isCached = snapshot.isFromCache;
    final isOffline = isCached && snapshot.isOffline;
    final refreshMessage = _cachedMessage(snapshot);
    final foreground = isOffline
        ? AppTheme.statusPending
        : isCached
        ? AppTheme.muted
        : AppTheme.primary;
    final background = isOffline
        ? AppTheme.statusPendingSurface
        : isCached
        ? const Color(0xFFEDF1EE)
        : AppTheme.accent;
    final message = isOffline
        ? 'أنت غير متصل بالإنترنت – تعرض آخر بيانات محفوظة'
        : isCached
        ? refreshMessage
        : 'متصل بالإنترنت';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 14, 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            isOffline
                ? Icons.cloud_off_rounded
                : isCached
                ? Icons.sync_problem_rounded
                : Icons.cloud_done_rounded,
            size: 18,
            color: foreground,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isCached) ...[
                  const SizedBox(height: 2),
                  Text(
                    'قد تكون البيانات قديمة.',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                  ),
                ],
              ],
            ),
          ),
          if (isCached) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppTheme.muted,
            ),
          ],
        ],
      ),
    );
  }

  String _cachedMessage(OrdersSnapshot snapshot) {
    final reason = switch (snapshot.refreshFailure) {
      OrdersRefreshFailure.unauthorized => 'رفض الخادم مفتاح API (401)',
      OrdersRefreshFailure.forbidden => 'مفتاح API لا يملك صلاحية الوصول (403)',
      OrdersRefreshFailure.endpointNotFound => 'مسار الطلبات غير موجود (404)',
      OrdersRefreshFailure.serverUnavailable => 'الخادم غير متاح مؤقتًا',
      OrdersRefreshFailure.invalidResponse => 'استجابة الخادم غير متوافقة',
      OrdersRefreshFailure.other =>
        snapshot.refreshStatusCode == null
            ? 'تعذر الاتصال بالخادم'
            : 'فشل طلب الخادم (${snapshot.refreshStatusCode})',
      null => 'تعذر التحديث',
    };
    return '$reason — تعرض آخر نسخة محفوظة';
  }
}

class OrdersLoadingState extends StatefulWidget {
  const OrdersLoadingState({super.key});

  @override
  State<OrdersLoadingState> createState() => _OrdersLoadingStateState();
}

class _OrdersLoadingStateState extends State<OrdersLoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('orders-loading'),
      label: 'جارٍ تحميل الطلبات',
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) => Opacity(
          opacity: .52 + (_shimmerController.value * .28),
          child: child,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 28),
          child: Column(
            children: [
              for (var index = 0; index < 3; index++) ...[
                const _OrderSkeletonCard(),
                if (index < 2) const SizedBox(height: 11),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSkeletonCard extends StatelessWidget {
  const _OrderSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const _SkeletonLine(width: 112, height: 15),
              const Spacer(),
              _SkeletonLine(width: 78, height: 25, radius: 20),
            ],
          ),
          Row(
            children: const [
              _SkeletonLine(width: 108, height: 12),
              Spacer(),
              _SkeletonLine(width: 82, height: 17),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.width,
    required this.height,
    this.radius = 7,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEEA),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class OrdersEmptyState extends StatelessWidget {
  const OrdersEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 32,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'لا توجد طلبات حتى الآن',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'اسحب الشاشة للأسفل لتحديث القائمة',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.statusCancelledSurface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.cloud_off_outlined,
                  size: 30,
                  color: AppTheme.statusCancelled,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'لم نتمكن من تحميل الطلبات',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.muted,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 19),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
