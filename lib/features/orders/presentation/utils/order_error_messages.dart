import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../domain/repositories/orders_repository.dart';

/// Converts any orders-loading error into a user-facing Arabic message.
String orderErrorMessage(Object error) {
  debugPrint('Orders load failed: ${error.runtimeType}');

  if (error is FormatException) {
    return 'وصلتنا بيانات غير مكتملة. اسحب للأسفل أو أعد المحاولة.';
  }

  if (error is OrdersUnavailableException) {
    if (error.isOffline) {
      return 'لا يوجد اتصال بالإنترنت ولا توجد طلبات محفوظة بعد. اتصل بالإنترنت ثم أعد المحاولة.';
    }
    final code = error.statusCode == null ? '' : ' (${error.statusCode})';
    return 'تعذر تحميل الطلبات من الخادم$code. حاول مجدداً.';
  }

  if (error is StateError ||
      error.toString().contains('MOCKAPI_KEY is missing')) {
    return 'إعداد مفتاح API غير موجود. شغّل التطبيق بإعداد المفتاح المحلي.';
  }

  if (error is DioException) {
    if (error.response == null) {
      return switch (error.type) {
        DioExceptionType.connectionTimeout =>
          'انتهت مهلة الاتصال بالخادم. حاول مجدداً.',
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          'انتهت مهلة استجابة الخادم. حاول مجدداً.',
        DioExceptionType.badCertificate =>
          'تعذر التحقق من شهادة الاتصال بالخادم.',
        DioExceptionType.connectionError =>
          'تعذر الوصول إلى الخادم. تحقق من الإنترنت وحاول مجدداً.',
        _ => 'تعذر الاتصال بالخادم. حاول مجدداً.',
      };
    }
    return switch (error.response?.statusCode) {
      401 => 'رفض الخادم مفتاح API. تحقّق من إعداد التشغيل المحلي.',
      403 => 'مفتاح API لا يملك صلاحية الوصول إلى هذا المشروع.',
      404 => 'لم يُعثر على مسار الطلبات في MockAPI.',
      final code =>
        'تعذر تحميل الطلبات (رمز الخطأ ${code ?? 'غير معروف'}).',
    };
  }

  return 'حدث خطأ أثناء تحميل الطلبات. حاول مجدداً.';
}
