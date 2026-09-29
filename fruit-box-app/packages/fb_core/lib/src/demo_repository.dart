import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'cart.dart';
import 'models.dart';
import 'money.dart';
import 'pricing.dart';
import 'repository.dart';

/// Switches that let testers reproduce edge cases without a backend.
class DemoSwitches {
  bool offline = false;
  bool branchClosed = false;
  bool paymentFailure = false;
  /// Enables a TEST delivery option (fee 0, clearly labelled). Off by default
  /// because no delivery fee has been approved.
  bool testDelivery = false;
  /// Order status auto-advance speed (seconds per step).
  int secondsPerStep = 4;
}

/// Offline demo backend built from the OBSERVED Talabat reference for New
/// Shahama. It is for building and testing only: every screen that uses it
/// shows a "demo — observed, unapproved prices" ribbon. Items priced
/// "by selection" have no price and cannot be ordered. The observed dessert
/// offer is NOT applied (it is unapproved).
class DemoRepository implements FbRepository {
  DemoRepository({this.menuJson, this.branchesJson, this.now = DateTime.now});

  static const demoBranchId = 'br_04'; // الشهامة الجديدة — the only branch with observed data
  /// Optional JSON overrides (tests); otherwise loaded from package assets.
  final String? menuJson;
  final String? branchesJson;
  final DateTime Function() now;
  final switches = DemoSwitches();

  List<Branch>? _branches;
  Menu? _menu;
  final List<Offer> _offers = [];
  final Map<String, Order> _orders = {};
  final Map<String, StreamController<Order>> _watchers = {};
  int _nextNumber = 1001;

  @override
  PricingPolicy get pricingPolicy => const PricingPolicy(vatRateBasisPoints: 500, pricesIncludeVat: true);

  Future<void> _load() async {
    if (_menu != null) return;
    final mj = menuJson ?? await rootBundle.loadString('packages/fb_core/assets/seed/seed_menu_new_shahama.json');
    final bj = branchesJson ?? await rootBundle.loadString('packages/fb_core/assets/seed/seed_branches.json');
    final m = jsonDecode(mj) as Map<String, dynamic>;
    final b = jsonDecode(bj) as Map<String, dynamic>;

    _branches = [
      for (final br in (b['branches'] as List).cast<Map<String, dynamic>>())
        Branch(
          id: br['id'] as String,
          name: L10nText(br['name_ar_observed'] as String, br['name_en'] as String?),
          status: br['id'] == demoBranchId ? BranchStatus.active : BranchStatus.pendingOwnerData,
          services: br['id'] == demoBranchId ? {ServiceType.pickup} : const {},
          hasApprovedMenu: br['id'] == demoBranchId,
        ),
    ];

    final cats = <Category>[];
    final products = <Product>[];
    for (final c in (m['categories'] as List).cast<Map<String, dynamic>>()) {
      cats.add(Category(id: c['id'] as String, sort: c['sort'] as int, name: L10nText(c['name_ar_observed'] as String, c['name_en'] as String?)));
      for (final it in (c['items'] as List).cast<Map<String, dynamic>>()) {
        final fils = it['base_price_fils'] as int?;
        products.add(Product(
          id: it['id'] as String,
          categoryId: c['id'] as String,
          sort: it['sort'] as int,
          name: L10nText(it['name_ar_observed'] as String, it['name_en'] as String?),
          priceMode: it['price_mode'] == 'fixed' ? PriceMode.fixed : PriceMode.bySelection,
          price: fils == null ? null : Money(fils),
          isNew: c['id'] == 'cat_03',
        ));
      }
      if (_hasObservedOffer(c)) {
        _offers.add(Offer(
          id: 'offer_desserts_observed',
          title: const L10nText('الحلويات بنصف السعر (مرصود)'),
          productIds: [for (final it in (c['items'] as List).cast<Map<String, dynamic>>()) it['id'] as String],
          status: ApprovalStatus.draft, // unapproved ⇒ never shown to customers
        ));
      }
    }
    _menu = Menu(branchId: demoBranchId, categories: cats, products: products, isObservedDemoData: true);
  }

  static bool _hasObservedOffer(Map<String, dynamic> c) =>
      (c['items'] as List).cast<Map<String, dynamic>>().any((i) => i['observed_offer'] != null);

  void _guardOnline() {
    if (switches.offline) throw const FbError(FbError.offline);
  }

  /// Exposed for admin/signage demo stores.
  List<Offer> get allOffersForAdmin => List.unmodifiable(_offers);

  @override
  Future<List<Branch>> branches() async {
    await _load();
    _guardOnline();
    return [
      for (final b in _branches!)
        if (b.id == demoBranchId)
          b.copyWith(
            status: switches.branchClosed ? BranchStatus.temporarilyClosed : BranchStatus.active,
            services: {ServiceType.pickup, if (switches.testDelivery) ServiceType.delivery},
            deliveryFee: switches.testDelivery ? Money.zero : null,
            clearDeliveryFee: !switches.testDelivery,
          )
        else
          b,
    ];
  }

  @override
  Future<Menu?> menu(String branchId) async {
    await _load();
    _guardOnline();
    if (branchId != demoBranchId) return null; // never copy New Shahama data to other branches
    return _menu;
  }

  @override
  Future<List<Offer>> liveOffers(String branchId) async {
    await _load();
    final t = now();
    return _offers.where((o) => o.isLive(t, branchId)).toList();
  }

  @override
  Future<Coupon> validateCoupon(String code, String branchId) async {
    _guardOnline();
    throw const FbError(FbError.couponInvalid); // no coupons approved yet
  }

  @override
  Future<Order> placeOrder(PlaceOrderRequest r) async {
    await _load();
    _guardOnline();
    final branch = (await branches()).firstWhere((b) => b.id == r.branchId);
    if (!branch.acceptsOrders) throw const FbError(FbError.branchUnavailable);
    if (branch.status == BranchStatus.temporarilyClosed) throw const FbError(FbError.branchClosed);
    if (r.lines.isEmpty) throw const FbError(FbError.emptyCart);
    if (r.service == ServiceType.delivery && !branch.deliveryConfigured) throw const FbError(FbError.deliveryNotConfigured);
    // Re-price from the menu (never trust the cart's numbers).
    final lines = <OrderLine>[];
    var subtotal = Money.zero;
    for (final l in r.lines) {
      final p = _menu!.byId(l.product.id);
      if (p == null || !p.available) throw FbError(FbError.productUnavailable, l.product.id);
      final fresh = CartLine(product: p, size: l.size, addons: l.addons, qty: l.qty, notes: l.notes);
      final unit = fresh.unitPrice;
      if (unit == null) throw FbError(FbError.priceNotApproved, p.id);
      final total = unit * l.qty;
      subtotal += total;
      lines.add(OrderLine(productId: p.id, name: p.name, qty: l.qty, unit: unit, lineTotal: total, sizeName: l.size?.name, addonNames: [for (final a in l.addons) a.addon.name], notes: l.notes));
    }
    final fee = r.service == ServiceType.delivery ? (branch.deliveryFee ?? Money.zero) : Money.zero;
    final breakdown = pricingPolicy.compute(subtotal: subtotal, deliveryFee: fee);
    final id = 'demo-$_nextNumber';
    final order = Order(
      id: id,
      number: _nextNumber++,
      branchId: r.branchId,
      service: r.service,
      status: OrderStatus.pendingPayment,
      paymentStatus: PaymentStatus.pending,
      lines: lines,
      breakdown: breakdown,
      createdAt: now(),
      history: [OrderStatusEvent(OrderStatus.pendingPayment, now())],
    );
    _orders[id] = order;
    return order;
  }

  /// Demo payment = sandbox simulation. Real payments are not activated.
  @override
  Future<Order> pay(String orderId) async {
    _guardOnline();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final o = _orders[orderId]!;
    if (switches.paymentFailure) {
      _orders[orderId] = o.copyWith(paymentStatus: PaymentStatus.failed);
      throw const FbError(FbError.paymentFailed);
    }
    final placed = o.copyWith(status: OrderStatus.placed, paymentStatus: PaymentStatus.paid, history: [...o.history, OrderStatusEvent(OrderStatus.placed, now())]);
    _orders[orderId] = placed;
    _autoAdvance(orderId);
    return placed;
  }

  void _autoAdvance(String id) {
    final o = _orders[id]!;
    final steps = [
      OrderStatus.accepted,
      OrderStatus.preparing,
      o.service == ServiceType.delivery ? OrderStatus.outForDelivery : OrderStatus.ready,
      OrderStatus.completed,
    ];
    var i = 0;
    Timer.periodic(Duration(seconds: switches.secondsPerStep), (t) {
      final cur = _orders[id]!;
      if (i >= steps.length || !cur.isActive) {
        t.cancel();
        return;
      }
      final next = cur.copyWith(status: steps[i], history: [...cur.history, OrderStatusEvent(steps[i], now())]);
      _orders[id] = next;
      _watchers[id]?.add(next);
      i++;
    });
  }

  @override
  Future<Order> cancel(String orderId, String reason) async {
    final o = _orders[orderId]!;
    if (!{OrderStatus.pendingPayment, OrderStatus.placed}.contains(o.status)) throw const FbError('NOT_ALLOWED');
    final c = o.copyWith(status: OrderStatus.cancelled, cancelReason: reason, history: [...o.history, OrderStatusEvent(OrderStatus.cancelled, now())]);
    _orders[orderId] = c;
    _watchers[orderId]?.add(c);
    return c;
  }

  @override
  Stream<Order> watchOrder(String orderId) {
    final c = _watchers.putIfAbsent(orderId, () => StreamController<Order>.broadcast());
    scheduleMicrotask(() {
      final o = _orders[orderId];
      if (o != null) c.add(o);
    });
    return c.stream;
  }

  @override
  Future<List<Order>> myOrders() async {
    _guardOnline();
    return _orders.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
