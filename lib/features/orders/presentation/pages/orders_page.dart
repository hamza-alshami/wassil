import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/order.dart';
import '../utils/order_error_messages.dart';
import '../view_models/orders_view_model.dart';
import '../widgets/order_card.dart';
import '../widgets/orders_header.dart';
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
            message: orderErrorMessage(error),
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
              SliverToBoxAdapter(child: OrdersHeader(snapshot: snapshot)),
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
}
