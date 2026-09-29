import 'models.dart';
import 'money.dart';

class Coupon {
  const Coupon({required this.code, required this.percent, this.amountOff, this.minSubtotal = Money.zero});
  final String code;
  final int? percent;
  final Money? amountOff;
  final Money minSubtotal;
}

/// Mirrors the server's place_order() arithmetic so the review screen shows
/// exactly what will be charged. The server remains the source of truth.
class PricingPolicy {
  const PricingPolicy({this.vatRateBasisPoints = 500, this.pricesIncludeVat = true});
  final int vatRateBasisPoints;
  final bool pricesIncludeVat;

  PriceBreakdown compute({required Money subtotal, Money deliveryFee = Money.zero, Coupon? coupon}) {
    var discount = Money.zero;
    if (coupon != null && subtotal >= coupon.minSubtotal) {
      if (coupon.percent != null) {
        discount = Money(subtotal.fils * coupon.percent! ~/ 100);
      } else if (coupon.amountOff != null) {
        discount = coupon.amountOff! > subtotal ? subtotal : coupon.amountOff!;
      }
    }
    var total = subtotal - discount + deliveryFee;
    final rate = vatRateBasisPoints;
    Money vat;
    if (pricesIncludeVat) {
      vat = Money((total.fils * rate / (10000 + rate)).round());
    } else {
      vat = Money((total.fils * rate / 10000).round());
      total = total + vat;
    }
    return PriceBreakdown(subtotal: subtotal, discount: discount, deliveryFee: deliveryFee, vat: vat, total: total, vatIncluded: pricesIncludeVat);
  }
}
