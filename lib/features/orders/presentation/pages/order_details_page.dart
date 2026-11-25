import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/order.dart';
import '../widgets/order_details_header.dart';
import '../widgets/order_details_sections.dart';
import '../widgets/order_progress_timeline.dart';

class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({super.key, required this.order});

  final Order order;

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  );
  late final CurvedAnimation _heroEntry = _entry(0, .36);
  late final CurvedAnimation _addressEntry = _entry(.08, .44);
  late final CurvedAnimation _progressEntry = _entry(.1, .56);
  late final CurvedAnimation _itemsEntry = _entry(.4, .8);
  late final CurvedAnimation _totalEntry = _entry(.55, .95);
  bool _entryStarted = false;
  bool _successDialogShown = false;

  void _showDeliverySuccessDialog() {
    if (!mounted || _successDialogShown) return;
    _successDialogShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.statusDelivered,
            size: 48,
          ),
          title: const Text('تم توصيل طلبك بنجاح'),
          content: const Text('شكرًا لاختيارك وصّل.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('حسنًا'),
            ),
          ],
        ),
      );
    });
  }

  CurvedAnimation _entry(double begin, double end) => CurvedAnimation(
    parent: _entryController,
    curve: Interval(begin, end, curve: Curves.easeOutCubic),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entryStarted) return;
    _entryStarted = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entryController.value = 1;
    } else {
      _entryController.forward();
    }
  }

  @override
  void dispose() {
    _heroEntry.dispose();
    _addressEntry.dispose();
    _progressEntry.dispose();
    _itemsEntry.dispose();
    _totalEntry.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطلب')),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 30),
        children: [
          _SectionEntrance(
            key: const ValueKey('details-order-header'),
            animation: _heroEntry,
            child: OrderDetailsHeader(order: widget.order),
          ),
          _SectionEntrance(
            key: const ValueKey('details-delivery-address'),
            animation: _addressEntry,
            child: DeliveryAddressSection(order: widget.order),
          ),
          const SizedBox(height: AppTheme.space24),
          _SectionEntrance(
            key: const ValueKey('details-progress'),
            animation: _progressEntry,
            child: OrderProgressTimeline(
              order: widget.order,
              onJourneyCompleted: _showDeliverySuccessDialog,
            ),
          ),
          const SizedBox(height: AppTheme.space24),
          _SectionEntrance(
            key: const ValueKey('details-items'),
            animation: _itemsEntry,
            child: OrderItemsSection(order: widget.order),
          ),
          const SizedBox(height: AppTheme.space16),
          _SectionEntrance(
            key: const ValueKey('details-total'),
            animation: _totalEntry,
            child: OrderTotalSection(order: widget.order),
          ),
        ],
      ),
    );
  }
}

class _SectionEntrance extends StatelessWidget {
  const _SectionEntrance({
    super.key,
    required this.animation,
    required this.child,
  });

  static final Tween<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, .045),
    end: Offset.zero,
  );

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: _offset.animate(animation),
        child: child,
      ),
    );
  }
}
