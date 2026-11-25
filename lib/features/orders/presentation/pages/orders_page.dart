import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';
import '../view_models/orders_view_model.dart';
import '../widgets/order_card.dart';
import '../widgets/orders_states.dart';
import 'order_details_page.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(ordersViewModelProvider);
    final snapshot = ordersState.value;
    final content = ordersState.when<List<Widget>>(
      data: (value) {
        if (value.orders.isEmpty) {
          return [
            const SliverFillRemaining(
              hasScrollBody: false,
              child: OrdersEmptyState(),
            ),
          ];
        }
        return [
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 2, 20, 28),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final order = value.orders[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: OrderCard(
                    key: ValueKey(order.orderNumber),
                    order: order,
                    onTap: () => _openOrder(context, order),
                  ),
                );
              }, childCount: value.orders.length),
            ),
          ),
        ];
      },
      error: (error, _) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: OrdersErrorState(
            message: _errorMessage(error),
            onRetry: () => _refresh(ref),
          ),
        ),
      ],
      loading: () => [const SliverToBoxAdapter(child: OrdersLoadingState())],
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator.adaptive(
          onRefresh: () => _refresh(ref),
          color: AppTheme.primary,
          backgroundColor: AppTheme.surface,
          displacement: 34,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _OrdersHeader(snapshot: snapshot)),
              ...content,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) {
    return ref.read(ordersViewModelProvider.notifier).refresh();
  }

  void _openOrder(BuildContext context, Order order) {
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) =>
            OrderDetailsPage(order: order),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .025),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  String _errorMessage(Object error) {
    debugPrint('Orders load failed: ${error.runtimeType}');
    if (error is FormatException) {
      return 'وصلتنا بيانات غير مكتملة. اسحب للأسفل أو أعد المحاولة.';
    }
    if (error is OrdersUnavailableException) {
      if (error.isOffline) {
        return 'لا يوجد اتصال بالإنترنت ولا توجد طلبات محفوظة بعد. اتصل بالإنترنت ثم أعد المحاولة.';
      }
      return 'تعذر تحميل الطلبات من الخادم${error.statusCode == null ? '' : ' (${error.statusCode})'}. حاول مجدداً.';
    }
    if (error is StateError ||
        error.toString().contains('MOCKAPI_KEY is missing')) {
      return 'إعداد مفتاح API غير موجود. شغّل التطبيق بإعداد المفتاح المحلي.';
    }
    if (error is DioException && error.response == null) {
      return switch (error.type) {
        DioExceptionType.connectionTimeout =>
          'انتهت مهلة الاتصال بالخادم. حاول مجدداً.',
        DioExceptionType.sendTimeout || DioExceptionType.receiveTimeout =>
          'انتهت مهلة استجابة الخادم. حاول مجدداً.',
        DioExceptionType.badCertificate =>
          'تعذر التحقق من شهادة الاتصال بالخادم.',
        DioExceptionType.connectionError =>
          'تعذر الوصول إلى الخادم. تحقق من الإنترنت وحاول مجدداً.',
        _ => 'تعذر الاتصال بالخادم. حاول مجدداً.',
      };
    }
    if (error is DioException) {
      switch (error.response?.statusCode) {
        case 401:
          return 'رفض الخادم مفتاح API. تحقّق من إعداد التشغيل المحلي.';
        case 403:
          return 'مفتاح API لا يملك صلاحية الوصول إلى هذا المشروع.';
        case 404:
          return 'لم يُعثر على مسار الطلبات في MockAPI.';
      }
      return 'تعذر تحميل الطلبات (رمز الخطأ ${error.response?.statusCode ?? 'غير معروف'}).';
    }
    return 'حدث خطأ أثناء تحميل الطلبات. حاول مجدداً.';
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({required this.snapshot});

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
      padding: const EdgeInsetsDirectional.fromSTEB(22, 10, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.local_mall_outlined,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'وصّل',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.3,
                ),
              ),
              const Spacer(),
              if (countLabel != null)
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 15,
                        color: AppTheme.muted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        countLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 25),
          Text(
            'طلباتي',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'كل تفاصيل طلباتك، في مكان واحد.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.muted,
              height: 1.45,
            ),
          ),
          if (snapshot != null) ...[
            const SizedBox(height: 17),
            OrdersConnectivityBanner(snapshot: snapshot!),
          ],
        ],
      ),
    );
  }
}
