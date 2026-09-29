import 'package:fb_core/fb_core.dart';
import 'package:fb_ui/fb_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';

String _nextAfterCart(AppState st) => st.isGuest
    ? '/auth?next=${Uri.encodeComponent(st.service == ServiceType.delivery ? '/checkout/address' : '/checkout/rewards')}'
    : (st.service == ServiceType.delivery ? '/checkout/address' : '/checkout/rewards');

/// C11 — cart with invalid-line detection (unavailable / price withdrawn).
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final st = AppScope.state(context);
    final s = context.s;
    final tt = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: st.cart,
      builder: (context, _) {
        final cart = st.cart;
        final invalid = st.menu == null ? const <CartLine>[] : cart.invalidLines(st.menu!);
        return Scaffold(
          appBar: AppBar(title: Text(s('cart'))),
          body: cart.isEmpty
              ? StateView(icon: Icons.shopping_bag_outlined, title: s('cart_empty'), message: s('cart_empty_sub'), action: s('browse_menu'), onAction: () => context.go('/menu'))
              : ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), children: [
                  for (final (i, l) in cart.lines.indexed)
                    StaggerIn(
                      index: i,
                      child: Dismissible(
                        key: ValueKey(l.signature),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => cart.remove(l),
                        background: Container(alignment: AlignmentDirectional.centerEnd, padding: const EdgeInsets.all(20), child: const Icon(Icons.delete_outline_rounded, color: FbColors.red)),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: FbRadius.cardAll,
                            border: invalid.contains(l) ? Border.all(color: FbColors.red, width: 1.5) : null,
                          ),
                          child: Row(children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(color: FbDrinkPalettes.forKey(l.product.categoryId).$1.withValues(alpha: .35), borderRadius: BorderRadius.circular(16)),
                              child: FittedBox(child: DrinkArt(palette: FbDrinkPalettes.forKey(l.product.categoryId), size: 70)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(l.product.name.of(s.locale), style: tt.titleSmall),
                                if (l.size != null) Text(l.size!.name.of(s.locale), style: tt.bodySmall),
                                for (final a in l.addons) Text('+ ${a.addon.name.of(s.locale)}', style: tt.bodySmall),
                                if (l.notes != null) Text('“${l.notes}”', style: tt.bodySmall),
                                if (invalid.contains(l)) Text(s('cart_item_invalid'), style: tt.bodySmall!.copyWith(color: FbColors.red)),
                                Text(s.money(l.lineTotal), style: tt.labelLarge!.copyWith(color: FbColors.red)),
                              ]),
                            ),
                            QtyStepper(value: l.qty, min: 0, onChanged: (v) => cart.setQty(l, v)),
                          ]),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  PriceBreakdownView(breakdown: st.repo.pricingPolicy.compute(subtotal: cart.subtotal)),
                ]),
          bottomNavigationBar: cart.isEmpty
              ? null
              : SafeArea(
                  minimum: const EdgeInsets.all(20),
                  child: FbButton(
                    label: s('checkout'),
                    trailing: s.money(cart.subtotal),
                    expand: true,
                    onPressed: invalid.isEmpty ? () => context.push(_nextAfterCart(st)) : null,
                  ),
                ),
        );
      },
    );
  }
}

/// C20 — sign-in / account recovery (demo OTP; no real SMS is sent).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.next});
  final String? next;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final phone = TextEditingController();
  final code = TextEditingController();
  bool sent = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.state(context);
    final s = context.s;
    final tt = Theme.of(context).textTheme;
    final phoneOk = RegExp(r'^\+?[0-9 ]{9,15}$').hasMatch(phone.text.trim());
    return Scaffold(
      appBar: AppBar(title: Text(s('sign_in'))),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        Text(s('sign_in_sub'), style: tt.bodyLarge),
        const SizedBox(height: 16),
        TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: s('phone'), hintText: '05X XXX XXXX', prefixIcon: const Icon(Icons.phone_iphone_rounded)),
        ),
        AnimatedSize(
          duration: FbMotion.d(context, FbDurations.base),
          child: sent
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(
                    controller: code,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    maxLength: 6,
                    decoration: InputDecoration(labelText: s('otp'), errorText: error, helperText: AppScope.of(context).config.isDemo ? s('otp_demo') : null),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 20),
        FbButton(
          label: sent ? s('continue') : s('send_code'),
          expand: true,
          onPressed: !phoneOk
              ? null
              : () {
                  if (!sent) return setState(() => sent = true);
                  if (code.text.trim() != '123456') return setState(() => error = s('otp_wrong'));
                  st.signIn(phone.text.trim());
                  context.pushReplacement(widget.next ?? '/account');
                },
        ),
        const SizedBox(height: 24),
        ExpansionTile(
          title: Text(s('recover_account'), style: tt.titleSmall),
          children: [Padding(padding: const EdgeInsets.all(12), child: Text(s('recover_sub'), style: tt.bodyMedium))],
        ),
      ]),
    );
  }
}

/// C12 — address (maps not enabled: manual entry).
class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});
  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  late final c = TextEditingController(text: AppScope.of(context).draft.address);
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final draft = AppScope.of(context).draft;
    return Scaffold(
      appBar: AppBar(title: Text(s('address'))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(
          height: 140,
          decoration: BoxDecoration(color: FbColors.mintTint, borderRadius: FbRadius.cardAll),
          alignment: Alignment.center,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.map_outlined, size: 40, color: FbColors.mintDeep),
            const SizedBox(height: 6),
            Text(s('maps_off'), style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        const SizedBox(height: 16),
        TextField(controller: c, minLines: 2, maxLines: 4, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: s('address'), hintText: s('address_hint'))),
      ]),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: FbButton(
          label: s('continue'),
          expand: true,
          onPressed: c.text.trim().length < 8
              ? null
              : () {
                  draft.address = c.text.trim();
                  context.push('/checkout/rewards');
                },
        ),
      ),
    );
  }
}

/// C13 — coupons & points.
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});
  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final c = TextEditingController();
  String? error;
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final st = scope.notifier!;
    final s = context.s;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(s('rewards'))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: TextField(controller: c, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(labelText: s('coupon_code'), errorText: error))),
          const SizedBox(width: 10),
          FbButton(
            label: s('apply'),
            variant: FbButtonVariant.secondary,
            loading: busy,
            onPressed: () async {
              setState(() {
                busy = true;
                error = null;
              });
              try {
                scope.draft.appliedCoupon = await st.repo.validateCoupon(c.text.trim(), st.branchId!);
                scope.draft.coupon = c.text.trim();
              } on FbError catch (e) {
                error = s.error(e);
              }
              if (mounted) setState(() => busy = false);
            },
          ),
        ]),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: FbColors.oat, borderRadius: FbRadius.cardAll),
          child: Row(children: [
            const Icon(Icons.stars_rounded, color: FbColors.brown),
            const SizedBox(width: 10),
            Expanded(child: Text(s('points_off'), style: tt.bodyMedium)),
          ]),
        ),
      ]),
      bottomNavigationBar: SafeArea(minimum: const EdgeInsets.all(20), child: FbButton(label: s('continue'), expand: true, onPressed: () => context.push('/checkout/review'))),
    );
  }
}

/// C14 — full cost review before confirming.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool busy = false;
  FbError? error;
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final st = scope.notifier!;
    final s = context.s;
    final tt = Theme.of(context).textTheme;
    final b = st.branch;
    final fee = st.service == ServiceType.delivery ? (b?.deliveryFee ?? Money.zero) : Money.zero;
    final breakdown = st.repo.pricingPolicy.compute(subtotal: st.cart.subtotal, deliveryFee: fee, coupon: scope.draft.appliedCoupon);
    final feeLabel = st.service == ServiceType.delivery ? (scope.config.isDemo ? s('test_delivery_fee') : s.money(fee)) : null;
    return Scaffold(
      appBar: AppBar(title: Text(s('review'))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        _Box(children: [
          Row(children: [
            Icon(st.service == ServiceType.pickup ? Icons.storefront_rounded : Icons.delivery_dining_rounded, color: FbColors.mintDeep),
            const SizedBox(width: 8),
            Expanded(child: Text('${s(st.service.name)} · ${b?.name.of(s.locale) ?? ''}', style: tt.titleSmall)),
          ]),
          if (scope.draft.address != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(scope.draft.address!, style: tt.bodyMedium)),
        ]),
        const SizedBox(height: 12),
        _Box(children: [
          for (final l in st.cart.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${l.qty}×  ', style: tt.labelMedium),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.product.name.of(s.locale), style: tt.labelMedium),
                    if (l.size != null) Text('${l.size!.name.of(s.locale)} · ${s.money(l.size!.price)}', style: tt.bodySmall),
                    for (final a in l.addons) Text('+ ${a.addon.name.of(s.locale)} × ${a.qty} · ${s.money(a.addon.price! * a.qty)}', style: tt.bodySmall),
                    if (l.notes != null) Text('“${l.notes}”', style: tt.bodySmall),
                  ]),
                ),
                Text(s.money(l.lineTotal), style: tt.labelMedium),
              ]),
            ),
        ]),
        const SizedBox(height: 12),
        _Box(children: [PriceBreakdownView(breakdown: breakdown, deliveryFeeLabel: feeLabel)]),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(s.error(error!), style: tt.labelMedium!.copyWith(color: FbColors.red))),
      ]),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: FbButton(
          label: s('place_order'),
          trailing: s.money(breakdown.total),
          expand: true,
          loading: busy,
          onPressed: () async {
            setState(() {
              busy = true;
              error = null;
            });
            try {
              final o = await st.repo.placeOrder(PlaceOrderRequest(
                branchId: st.branchId!,
                service: st.service,
                lines: st.cart.lines,
                coupon: scope.draft.coupon,
                addressText: scope.draft.address,
              ));
              if (context.mounted) context.pushReplacement('/checkout/payment/${o.id}');
            } on FbError catch (e) {
              setState(() => error = e);
            } finally {
              if (mounted) setState(() => busy = false);
            }
          },
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: FbRadius.cardAll),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}

/// C15 — payment. Real payments are not active: demo shows a clearly-labelled simulation.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.orderId});
  final String orderId;
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool busy = false;
  bool failed = false;
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final st = scope.notifier!;
    final s = context.s;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(s('payment'))),
      body: failed
          ? StateView(icon: Icons.credit_card_off_rounded, title: s('payment_failed'), message: s('payment_failed_sub'), tone: FbColors.blushTint)
          : ListView(padding: const EdgeInsets.all(20), children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: FbColors.oat, borderRadius: FbRadius.cardAll),
                child: Row(children: [
                  const Icon(Icons.lock_outline_rounded, color: FbColors.brown),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s('payments_off'), style: tt.bodyMedium)),
                ]),
              ),
              const SizedBox(height: 16),
              for (final m in const ['Apple Pay', 'Google Pay', 'Card'])
                Opacity(opacity: .45, child: Card(child: ListTile(leading: const Icon(Icons.payment_rounded), title: Text(m), trailing: const Icon(Icons.lock_rounded, size: 18)))),
            ]),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: FbButton(
          label: failed ? s('retry') : s('simulate_pay'),
          expand: true,
          loading: busy,
          onPressed: !scope.config.isDemo
              ? null
              : () async {
                  setState(() {
                    busy = true;
                    failed = false;
                  });
                  try {
                    final o = await st.repo.pay(widget.orderId);
                    st.cart.clear();
                    scope.draft.reset();
                    if (context.mounted) context.go('/order/${o.id}/confirmed');
                  } on FbError {
                    setState(() => failed = true);
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
        ),
      ),
    );
  }
}

/// C16 — confirmation moment (M7).
class ConfirmedScreen extends StatelessWidget {
  const ConfirmedScreen({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const OrderConfirmedArt(size: 240),
              const SizedBox(height: 12),
              StaggerIn(index: 3, child: Text(s('order_confirmed'), style: tt.headlineMedium, textAlign: TextAlign.center)),
              StaggerIn(index: 4, child: Text('${s('order_number')} #${orderId.replaceAll('demo-', '')}', style: tt.titleSmall!.copyWith(color: FbColors.brown))),
              const SizedBox(height: 24),
              FbButton(label: s('track_order'), expand: true, onPressed: () => context.go('/order/$orderId')),
              const SizedBox(height: 10),
              FbButton(label: s('home'), variant: FbButtonVariant.ghost, expand: true, onPressed: () => context.go('/home')),
            ]),
          ),
        ),
      ),
    );
  }
}
