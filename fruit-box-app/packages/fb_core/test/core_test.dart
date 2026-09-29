import 'dart:io';

import 'package:fb_core/fb_core.dart';
import 'package:flutter_test/flutter_test.dart';

String _seed(String f) => File('assets/seed/$f').readAsStringSync();

DemoRepository demo() => DemoRepository(menuJson: _seed('seed_menu_new_shahama.json'), branchesJson: _seed('seed_branches.json'));

void main() {
  group('seed menu (observed reference)', () {
    test('14 categories, 110 items, 38 fixed, 72 by selection', () async {
      final m = (await demo().menu(DemoRepository.demoBranchId))!;
      expect(m.categories.length, 14);
      expect(m.products.length, 110);
      expect(m.products.where((p) => p.priceMode == PriceMode.fixed).length, 38);
      expect(m.products.where((p) => p.priceMode == PriceMode.bySelection).length, 72);
      expect(m.products.where((p) => p.priceMode == PriceMode.bySelection && p.price != null), isEmpty, reason: 'no invented prices');
    });

    test('by-selection items are not orderable', () async {
      final m = (await demo().menu(DemoRepository.demoBranchId))!;
      expect(m.byId('cat_01_item_01')!.orderable, isFalse);
      expect(m.byId('cat_03_item_01')!.orderable, isTrue);
    });

    test('observed dessert offer is NOT applied (unapproved)', () async {
      final r = demo();
      final m = (await r.menu(DemoRepository.demoBranchId))!;
      expect(m.byId('cat_13_item_01')!.displayPrice, const Money(4500));
      expect(await r.liveOffers(DemoRepository.demoBranchId), isEmpty);
    });

    test('New Shahama menu is not copied to other branches', () async {
      final r = demo();
      final branches = await r.branches();
      expect(branches.length, 11);
      for (final b in branches.where((b) => b.id != DemoRepository.demoBranchId)) {
        expect(await r.menu(b.id), isNull);
        expect(b.status, BranchStatus.pendingOwnerData);
        expect(b.address, isNull, reason: 'no invented addresses');
        expect(b.phone, isNull, reason: 'no invented phones');
        expect(b.hours, isEmpty, reason: 'no invented hours');
      }
    });
  });

  group('money & pricing', () {
    test('formats AED in both languages', () {
      expect(const Money(3000).format('ar'), '30 د.إ');
      expect(const Money(2250).format('en'), 'AED 22.50');
    });

    test('VAT included 5% matches the server (60 AED → 2.86)', () {
      final b = const PricingPolicy().compute(subtotal: const Money(6000));
      expect(b.vat, const Money(286));
      expect(b.total, const Money(6000));
    });

    test('VAT exclusive adds on top', () {
      final b = const PricingPolicy(pricesIncludeVat: false).compute(subtotal: const Money(10000), deliveryFee: const Money(500));
      expect(b.vat, const Money(525));
      expect(b.total, const Money(11025));
    });

    test('options, add-ons and quantity roll into the line total', () {
      const p = Product(id: 't', categoryId: 'c', sort: 1, name: L10nText('اختبار'), priceMode: PriceMode.fixed,
          sizes: [ProductSize(id: 'l', name: L10nText('كبير'), price: Money(2500))],
          addons: [Addon(id: 'h', name: L10nText('عسل'), price: Money(300), maxQty: 2)]);
      final line = CartLine(product: p, size: p.sizes.first, addons: [SelectedAddon(p.addons.first, 2)], qty: 3);
      expect(line.unitPrice, const Money(3100));
      expect(line.lineTotal, const Money(9300));
    });

    test('an add-on without an approved price blocks the line', () {
      const p = Product(id: 't', categoryId: 'c', sort: 1, name: L10nText('x'), priceMode: PriceMode.fixed, price: Money(1000),
          addons: [Addon(id: 'a', name: L10nText('y'), price: null)]);
      expect(CartLine(product: p, addons: [SelectedAddon(p.addons.first, 1)]).unitPrice, isNull);
    });
  });

  group('cart', () {
    test('merges identical lines and clears on branch switch', () async {
      final m = (await demo().menu(DemoRepository.demoBranchId))!;
      final cart = Cart()..bindBranch('br_04');
      cart.add(CartLine(product: m.byId('cat_03_item_01')!));
      cart.add(CartLine(product: m.byId('cat_03_item_01')!, qty: 2));
      expect(cart.lines.length, 1);
      expect(cart.count, 3);
      expect(cart.subtotal, const Money(9000));
      cart.bindBranch('br_05');
      expect(cart.isEmpty, isTrue);
    });
  });

  group('orders (demo backend)', () {
    test('server re-prices and rejects unorderable items', () async {
      final r = demo();
      final m = (await r.menu(DemoRepository.demoBranchId))!;
      final o = await r.placeOrder(PlaceOrderRequest(branchId: 'br_04', service: ServiceType.pickup, lines: [CartLine(product: m.byId('cat_03_item_01')!, qty: 2)]));
      expect(o.breakdown.total, const Money(6000));
      expect(o.status, OrderStatus.pendingPayment);
      expect(
          () => r.placeOrder(PlaceOrderRequest(branchId: 'br_04', service: ServiceType.pickup, lines: [CartLine(product: m.byId('cat_01_item_01')!)])),
          throwsA(isA<FbError>().having((e) => e.code, 'code', FbError.priceNotApproved)));
    });

    test('delivery is refused until a fee is approved', () async {
      final r = demo();
      final m = (await r.menu('br_04'))!;
      expect(() => r.placeOrder(PlaceOrderRequest(branchId: 'br_04', service: ServiceType.delivery, lines: [CartLine(product: m.byId('cat_03_item_01')!)])),
          throwsA(isA<FbError>().having((e) => e.code, 'code', FbError.deliveryNotConfigured)));
    });

    test('closed branch, offline and payment failure states', () async {
      final r = demo();
      final m = (await r.menu('br_04'))!;
      final req = PlaceOrderRequest(branchId: 'br_04', service: ServiceType.pickup, lines: [CartLine(product: m.byId('cat_03_item_01')!)]);
      r.switches.paymentFailure = true;
      final o = await r.placeOrder(req);
      expect(() => r.pay(o.id), throwsA(isA<FbError>().having((e) => e.code, 'code', FbError.paymentFailed)));
      r.switches.branchClosed = true;
      expect(() => r.placeOrder(req), throwsA(isA<FbError>()));
      r.switches.offline = true;
      expect(() => r.branches(), throwsA(isA<FbError>().having((e) => e.code, 'code', FbError.offline)));
    });

    test('server error strings map to codes', () {
      final e = FbError.fromServer('PRODUCT_UNAVAILABLE:cat_03_item_02');
      expect(e.code, 'PRODUCT_UNAVAILABLE');
      expect(e.detail, 'cat_03_item_02');
    });
  });

  group('offers & hours', () {
    test('only approved offers inside their window are live', () {
      final now = DateTime(2026, 10, 1, 12);
      Offer o(ApprovalStatus s, DateTime? a, DateTime? b) => Offer(id: 'o', title: const L10nText('x'), productIds: const [], status: s, startsAt: a, endsAt: b);
      expect(o(ApprovalStatus.approved, DateTime(2026, 9, 30), DateTime(2026, 10, 2)).isLive(now, 'br_04'), isTrue);
      expect(o(ApprovalStatus.draft, DateTime(2026, 9, 30), DateTime(2026, 10, 2)).isLive(now, 'br_04'), isFalse);
      expect(o(ApprovalStatus.approved, DateTime(2026, 9, 1), DateTime(2026, 9, 30)).isLive(now, 'br_04'), isFalse);
      expect(o(ApprovalStatus.approved, null, null).isLive(now, 'br_04'), isFalse);
    });

    test('hours crossing midnight; unknown hours are null (not guessed)', () {
      const b = Branch(id: 'x', name: L10nText('x'), hours: [OpeningHours(weekday: 4, opensMinutes: 16 * 60, closesMinutes: 2 * 60)]);
      expect(b.isOpenAt(DateTime(2026, 10, 1, 23, 30)), isTrue); // Thu
      expect(b.isOpenAt(DateTime(2026, 10, 2, 1, 30)), isTrue); // Fri early
      expect(b.isOpenAt(DateTime(2026, 10, 2, 2, 30)), isFalse);
      expect(const Branch(id: 'y', name: L10nText('y')).isOpenAt(DateTime(2026, 10, 1, 12)), isNull);
    });
  });

  group('configuration', () {
    test('defaults are safe: target domain only, no e-mail, no payments', () {
      final c = FbConfig.fromEnvironment()..validate();
      expect(c.targetDomain, 'fruitbox.com');
      expect(c.supportEmail, 'info@fruitbox.com');
      expect(c.emailSendingEnabled, isFalse);
      expect(c.paymentsEnabled, isFalse);
      expect(c.publicUrl('/menu'), '/menu', reason: 'no absolute production links before domain is confirmed');
    });

    test('blocked domain is rejected', () {
      const c = FbConfig(targetDomain: 'futitbox.com', supportEmail: 'x', emailSendingEnabled: false, domainConfirmed: false,
          paymentsMode: 'disabled', backend: 'demo', supabaseUrl: '', supabaseAnonKey: '');
      expect(c.validate, throwsStateError);
    });

    test('e-mail cannot be enabled before the domain is confirmed', () {
      const c = FbConfig(targetDomain: 'fruitbox.com', supportEmail: 'info@fruitbox.com', emailSendingEnabled: true, domainConfirmed: false,
          paymentsMode: 'disabled', backend: 'demo', supabaseUrl: '', supabaseAnonKey: '');
      expect(c.validate, throwsStateError);
    });
  });
}
