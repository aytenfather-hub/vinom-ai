import 'package:supabase/supabase.dart';

import 'models.dart';
import 'money.dart';
import 'pricing.dart';
import 'repository.dart';

/// Production repository backed by the Supabase project in backend/supabase.
/// Uses only the public anon key; every rule is enforced by RLS and the
/// SECURITY DEFINER functions. NOT yet exercised against a live project —
/// see docs/06-status.md.
class SupabaseRepository implements FbRepository {
  SupabaseRepository(this.client);
  final SupabaseClient client;

  @override
  PricingPolicy get pricingPolicy => const PricingPolicy();

  FbError _map(Object e) => e is PostgrestException ? FbError.fromServer(e.message) : FbError('UNKNOWN', '$e');

  static ServiceType _service(String s) => s == 'delivery' ? ServiceType.delivery : ServiceType.pickup;
  static OrderStatus _status(String s) => switch (s) {
        'pending_payment' => OrderStatus.pendingPayment,
        'placed' => OrderStatus.placed,
        'accepted' => OrderStatus.accepted,
        'preparing' => OrderStatus.preparing,
        'ready' => OrderStatus.ready,
        'out_for_delivery' => OrderStatus.outForDelivery,
        'completed' => OrderStatus.completed,
        'cancelled' => OrderStatus.cancelled,
        _ => OrderStatus.rejected,
      };

  @override
  Future<List<Branch>> branches() async {
    try {
      final rows = await client.from('branches').select('*, branch_hours(*), branch_delivery_settings(*)');
      return [
        for (final r in rows)
          Branch(
            id: r['id'],
            name: L10nText(r['name_ar'], r['name_en']),
            address: r['address_ar'] == null ? null : L10nText(r['address_ar'], r['address_en']),
            phone: r['phone'],
            lat: (r['lat'] as num?)?.toDouble(),
            lng: (r['lng'] as num?)?.toDouble(),
            services: {for (final s in (r['services'] as List)) _service(s as String)},
            status: switch (r['status']) {
              'active' => BranchStatus.active,
              'temporarily_closed' => BranchStatus.temporarilyClosed,
              'closed' => BranchStatus.closed,
              _ => BranchStatus.pendingOwnerData,
            },
            hours: [
              for (final h in (r['branch_hours'] as List? ?? const []))
                OpeningHours(weekday: h['weekday'], opensMinutes: _min(h['opens']), closesMinutes: _min(h['closes'])),
            ],
            deliveryFee: _fee(r['branch_delivery_settings']),
            hasApprovedMenu: true,
          ),
      ];
    } catch (e) {
      throw _map(e);
    }
  }

  static int _min(String hhmm) {
    final p = hhmm.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  static Money? _fee(dynamic s) {
    final m = s is List ? (s.isEmpty ? null : s.first) : s;
    return m == null || m['delivery_fee_fils'] == null ? null : Money(m['delivery_fee_fils']);
  }

  @override
  Future<Menu?> menu(String branchId) async {
    try {
      final json = await client.rpc('public_menu', params: {'p_branch': branchId});
      if (json == null) return null;
      final cats = <Category>[];
      final products = <Product>[];
      for (final c in (json['categories'] as List)) {
        cats.add(Category(id: c['id'], sort: c['sort'], name: L10nText(c['name_ar'], c['name_en'])));
        var i = 0;
        for (final p in (c['items'] as List)) {
          products.add(Product(
            id: p['id'],
            categoryId: c['id'],
            sort: i++,
            name: L10nText(p['name_ar'], p['name_en']),
            priceMode: p['price_mode'] == 'fixed' ? PriceMode.fixed : PriceMode.bySelection,
            price: p['price_fils'] == null ? null : Money(p['price_fils']),
            offerPrice: p['offer_price_fils'] == null ? null : Money(p['offer_price_fils']),
            description: p['description_ar'] == null ? null : L10nText(p['description_ar'], p['description_en']),
            imageUrl: p['image_path'],
            available: p['available'] ?? true,
          ));
        }
      }
      return Menu(branchId: branchId, categories: cats, products: products);
    } catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<List<Offer>> liveOffers(String branchId) async {
    final rows = await client.from('offers').select(); // RLS returns approved & live only
    return [
      for (final r in rows)
        if (r['branch_ids'] == null || (r['branch_ids'] as List).contains(branchId))
          Offer(
            id: r['id'],
            title: L10nText(r['title_ar'], r['title_en']),
            productIds: (r['product_ids'] as List).cast<String>(),
            status: ApprovalStatus.approved,
            startsAt: DateTime.parse(r['starts_at']),
            endsAt: DateTime.parse(r['ends_at']),
          ),
    ];
  }

  @override
  Future<Coupon> validateCoupon(String code, String branchId) async =>
      // Coupons are validated server-side inside place_order (not readable by clients).
      Coupon(code: code.toUpperCase(), percent: null);

  @override
  Future<Order> placeOrder(PlaceOrderRequest r) async {
    try {
      final row = await client.rpc('place_order', params: {
        'p_branch': r.branchId,
        'p_service': r.service.name,
        'p_items': [
          for (final l in r.lines)
            {
              'product_id': l.product.id,
              'size_id': l.size?.id,
              'qty': l.qty,
              'notes': l.notes,
              'addons': [for (final a in l.addons) {'id': a.addon.id, 'qty': a.qty}],
            }
        ],
        'p_coupon': r.coupon,
        'p_notes': r.notes,
      });
      return _order(row);
    } catch (e) {
      throw _map(e);
    }
  }

  Order _order(Map<String, dynamic> r) => Order(
        id: r['id'],
        number: r['number'],
        branchId: r['branch_id'],
        service: _service(r['service']),
        status: _status(r['status']),
        paymentStatus: switch (r['payment_status']) { 'paid' => PaymentStatus.paid, 'failed' => PaymentStatus.failed, _ => PaymentStatus.pending },
        lines: const [],
        breakdown: PriceBreakdown(
          subtotal: Money(r['subtotal_fils']),
          discount: Money(r['discount_fils']),
          deliveryFee: Money(r['delivery_fee_fils']),
          vat: Money(r['vat_fils']),
          total: Money(r['total_fils']),
          vatIncluded: true,
        ),
        createdAt: DateTime.parse(r['created_at']),
      );

  @override
  Future<Order> pay(String orderId) async =>
      throw const FbError(FbError.paymentsDisabled); // payment provider not selected yet

  @override
  Future<Order> cancel(String orderId, String reason) async {
    try {
      return _order(await client.rpc('set_order_status', params: {'p_order': orderId, 'p_to': 'cancelled', 'p_reason': reason}));
    } catch (e) {
      throw _map(e);
    }
  }

  @override
  Stream<Order> watchOrder(String orderId) =>
      client.from('orders').stream(primaryKey: ['id']).eq('id', orderId).where((rows) => rows.isNotEmpty).map((rows) => _order(rows.first));

  @override
  Future<List<Order>> myOrders() async {
    final rows = await client.from('orders').select().order('created_at', ascending: false);
    return [for (final r in rows) _order(r)];
  }
}
