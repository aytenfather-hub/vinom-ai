import 'package:fb_core/fb_core.dart';
import 'package:fb_ui/fb_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';

List<OrderStatus> stepsFor(ServiceType s) => [
      OrderStatus.placed,
      OrderStatus.accepted,
      OrderStatus.preparing,
      s == ServiceType.delivery ? OrderStatus.outForDelivery : OrderStatus.ready,
      OrderStatus.completed,
    ];

/// C17 — live tracking (M8).
class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context) {
    final st = AppScope.state(context);
    final s = context.s;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(s('track_order'))),
      body: StreamBuilder<Order>(
        stream: st.repo.watchOrder(orderId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: FbColors.red));
          final o = snap.data!;
          final steps = stepsFor(o.service);
          final idx = steps.indexOf(o.status);
          final ended = o.status == OrderStatus.cancelled || o.status == OrderStatus.rejected;
          return ListView(padding: const EdgeInsets.all(20), children: [
            Text('${s('order_number')} #${o.number}', style: tt.bodySmall),
            RollingText(s.orderStatus(o.status), style: tt.headlineMedium),
            const SizedBox(height: 14),
            if (!ended) JuiceProgress(value: idx < 0 ? 0 : (idx + 1) / steps.length),
            const SizedBox(height: 20),
            for (final (i, step) in steps.indexed)
              _Step(
                title: s.orderStatus(step),
                time: o.history.where((h) => h.status == step).map((h) => TimeOfDay.fromDateTime(h.at).format(context)).firstOrNull,
                state: ended ? 0 : (i < idx ? 2 : i == idx ? 1 : 0),
                last: i == steps.length - 1,
              ),
            if (ended) Text('${s.orderStatus(o.status)}${o.cancelReason == null ? '' : ' — ${o.cancelReason}'}', style: tt.titleSmall!.copyWith(color: FbColors.red)),
            const SizedBox(height: 16),
            PriceBreakdownView(breakdown: o.breakdown),
            const SizedBox(height: 16),
            if (o.status == OrderStatus.completed) FbButton(label: s('rate_order'), variant: FbButtonVariant.secondary, expand: true, onPressed: () => context.push('/order/${o.id}/rate')),
            if (o.status == OrderStatus.placed || o.status == OrderStatus.pendingPayment)
              TextButton(onPressed: () => st.repo.cancel(o.id, 'customer'), child: Text(s('cancel'), style: const TextStyle(color: FbColors.red))),
          ]);
        },
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.title, required this.time, required this.state, required this.last});
  final String title;
  final String? time;
  final int state; // 0 todo, 1 now, 2 done
  final bool last;
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final color = switch (state) { 2 => FbColors.mint, 1 => FbColors.red, _ => FbColors.line };
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Column(children: [
          AnimatedContainer(
            duration: FbMotion.d(context, FbDurations.smooth),
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: state == 1 ? [BoxShadow(color: FbColors.red.withValues(alpha: .25), blurRadius: 0, spreadRadius: 6)] : null),
            child: state == 2 ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
          ),
          if (!last) Expanded(child: Container(width: 2, color: state == 2 ? FbColors.mint : FbColors.line)),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18, top: 2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: tt.titleSmall!.copyWith(color: state == 0 ? FbColors.muted : FbColors.cocoa)),
              if (time != null) Text(time!, style: tt.bodySmall),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// C18 — history & reorder (re-checks availability and current prices).
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final st = AppScope.state(context);
    final s = context.s;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(s('orders'))),
      body: FutureBuilder<List<Order>>(
        future: st.repo.myOrders(),
        builder: (context, snap) {
          if (snap.hasError) return StateView(icon: Icons.wifi_off_rounded, title: s('offline'), action: s('retry'), onAction: () => (context as Element).markNeedsBuild());
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: FbColors.red));
          final list = snap.data!;
          if (list.isEmpty) return StateView(icon: Icons.receipt_long_outlined, title: s('no_orders'), action: s('browse_menu'), onAction: () => context.go('/menu'));
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final o = list[i];
              return StaggerIn(
                index: i,
                child: Squeeze(
                  onTap: () => context.push('/order/${o.id}'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: FbRadius.cardAll),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text('#${o.number} · ${s.orderStatus(o.status)}', style: tt.titleSmall)),
                        Text(s.money(o.breakdown.total), style: tt.labelLarge!.copyWith(color: FbColors.red)),
                      ]),
                      Text(o.lines.map((l) => '${l.qty}× ${l.name.of(s.locale)}').join('، '), style: tt.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (!o.isActive)
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton.icon(
                            icon: const Icon(Icons.replay_rounded, size: 18),
                            label: Text(s('reorder')),
                            onPressed: () {
                              var removed = false;
                              for (final l in o.lines) {
                                final p = st.menu?.byId(l.productId);
                                if (p == null || !p.orderable) {
                                  removed = true;
                                  continue;
                                }
                                st.cart.add(CartLine(product: p, qty: l.qty, notes: l.notes));
                              }
                              if (removed) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s('reorder_changed'))));
                              context.push('/cart');
                            },
                          ),
                        ),
                    ]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// C22 — rating.
class RateScreen extends StatefulWidget {
  const RateScreen({super.key, required this.orderId});
  final String orderId;
  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen> {
  int stars = 0;
  bool sent = false;
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s('rate_order'))),
      body: sent
          ? StateView(icon: Icons.favorite_rounded, title: s('thanks_rating'), tone: FbColors.blushTint)
          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    iconSize: 44,
                    tooltip: '$i',
                    onPressed: () => setState(() => stars = i),
                    icon: AnimatedScale(
                      scale: i <= stars ? 1.1 : 1,
                      duration: FbMotion.d(context, FbDurations.quick),
                      curve: FbCurves.squeeze,
                      child: Icon(i <= stars ? Icons.star_rounded : Icons.star_border_rounded, color: FbColors.yellow),
                    ),
                  ),
              ]),
              const SizedBox(height: 20),
              FbButton(label: s('save'), onPressed: stars == 0 ? null : () => setState(() => sent = true)),
            ]),
    );
  }
}
