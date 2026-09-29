import 'cart.dart';
import 'models.dart';
import 'pricing.dart';

/// Error codes shared with the backend (place_order / set_order_status).
class FbError implements Exception {
  const FbError(this.code, [this.detail]);
  final String code;
  final String? detail;

  static const offline = 'OFFLINE';
  static const branchClosed = 'BRANCH_CLOSED';
  static const branchUnavailable = 'BRANCH_UNAVAILABLE';
  static const productUnavailable = 'PRODUCT_UNAVAILABLE';
  static const priceNotApproved = 'PRICE_NOT_APPROVED';
  static const couponInvalid = 'COUPON_INVALID';
  static const paymentFailed = 'PAYMENT_FAILED';
  static const paymentsDisabled = 'PAYMENTS_DISABLED';
  static const deliveryNotConfigured = 'DELIVERY_NOT_CONFIGURED';
  static const authRequired = 'AUTH_REQUIRED';
  static const emptyCart = 'EMPTY_CART';

  /// Server messages look like "PRODUCT_UNAVAILABLE:cat_03_item_02".
  factory FbError.fromServer(String message) {
    final m = RegExp(r'([A-Z_]{4,})(?::(\S+))?').firstMatch(message);
    return m == null ? FbError('UNKNOWN', message) : FbError(m.group(1)!, m.group(2));
  }

  @override
  String toString() => 'FbError($code${detail == null ? '' : ': $detail'})';
}

class PlaceOrderRequest {
  const PlaceOrderRequest({required this.branchId, required this.service, required this.lines, this.coupon, this.addressText, this.notes});
  final String branchId;
  final ServiceType service;
  final List<CartLine> lines;
  final String? coupon;
  final String? addressText;
  final String? notes;
}

abstract class FbRepository {
  Future<List<Branch>> branches();

  /// Approved menu for a branch, or null if the branch has none yet.
  Future<Menu?> menu(String branchId);

  Future<List<Offer>> liveOffers(String branchId);
  PricingPolicy get pricingPolicy;
  Future<Coupon> validateCoupon(String code, String branchId);
  Future<Order> placeOrder(PlaceOrderRequest request);
  Future<Order> pay(String orderId);
  Future<Order> cancel(String orderId, String reason);
  Stream<Order> watchOrder(String orderId);
  Future<List<Order>> myOrders();
}
