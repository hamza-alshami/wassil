import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final orders = snapshot?.orders ?? const <Order>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'وصّل',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'طلباتي',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF153D35),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'تابع طلباتك وحالة التوصيل',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF66736E),
                    ),
                  ),
                  if (snapshot != null) ...[
                    const SizedBox(height: 14),
                    OrdersConnectivityBanner(snapshot: snapshot),
                  ],
                  const SizedBox(height: 18),
                  _OrdersSummary(count: orders.length),
                ],
              ),
            ),
            Expanded(
              child: ordersState.when(
                data: (snapshot) {
                  final data = snapshot.orders;
                  if (data.isEmpty) {
                    return OrdersEmptyState(onRefresh: () => _refresh(ref));
                  }
                  return RefreshIndicator(
                    onRefresh: () => _refresh(ref),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: data.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final order = data[index];
                        return OrderCard(
                          order: order,
                          onTap: () => _openOrder(context, order),
                        );
                      },
                    ),
                  );
                },
                error: (error, _) => OrdersErrorState(
                  message: _errorMessage(error),
                  onRetry: () => _refresh(ref),
                ),
                loading: () => const OrdersLoadingState(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) {
    return ref.read(ordersViewModelProvider.notifier).refresh();
  }

  void _openOrder(BuildContext context, Order order) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => OrderDetailsPage(order: order)),
    );
  }

  String _errorMessage(Object error) {
    debugPrint('Orders load failed: ${error.runtimeType}');
    if (error is FormatException) {
      return 'تعذر قراءة بيانات الطلبات من الخادم.';
    }
    if (error is OrdersUnavailableException) {
      if (error.isOffline) {
        return 'لا يوجد اتصال بالإنترنت ولا توجد طلبات محفوظة بعد. اتصل بالإنترنت ثم أعد المحاولة.';
      }
      return 'تعذر تحميل الطلبات من الخادم${error.statusCode == null ? '' : ' (${error.statusCode})'}. أعد المحاولة.';
    }
    if (error is StateError ||
        error.toString().contains('MOCKAPI_KEY is missing')) {
      return 'إعداد مفتاح API غير موجود. شغّل التطبيق باستخدام MOCKAPI_KEY.';
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
          return 'رفض الخادم مفتاح API. تحقّق من MOCKAPI_KEY في إعداد التشغيل.';
        case 403:
          return 'مفتاح API لا يملك صلاحية الوصول إلى هذا المشروع.';
        case 404:
          return 'لم يُعثر على المسار /orders في MockAPI.';
      }
      return 'تعذر تحميل الطلبات (رمز الخطأ ${error.response?.statusCode ?? 'غير معروف'}).';
    }
    return 'حدث خطأ أثناء تحميل الطلبات. حاول مجدداً.';
  }
}

class _OrdersSummary extends StatelessWidget {
  const _OrdersSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDDF3E8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, color: Color(0xFF153D35)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'عدد الطلبات',
              style: TextStyle(
                color: Color(0xFF153D35),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$count',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF153D35),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
