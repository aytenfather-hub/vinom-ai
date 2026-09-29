import 'money.dart';

enum PriceMode { fixed, bySelection }

enum ServiceType { delivery, pickup }

enum BranchStatus { pendingOwnerData, active, temporarilyClosed, closed }

enum ApprovalStatus { draft, pendingApproval, approved, archived }

enum OrderStatus { pendingPayment, placed, accepted, preparing, ready, outForDelivery, completed, cancelled, rejected }

enum PaymentStatus { notRequired, pending, paid, failed, refunded }

enum StaffRole { owner, branchManager, orderStaff, contentAdmin }

/// Bilingual text. English may be missing until approved; UI falls back to Arabic.
class L10nText {
  const L10nText(this.ar, [this.en]);
  final String ar;
  final String? en;
  String of(String locale) => locale == 'en' ? (en ?? ar) : ar;
  bool get hasEnglish => en != null && en!.isNotEmpty;
}

class OpeningHours {
  const OpeningHours({required this.weekday, required this.opensMinutes, required this.closesMinutes});
  final int weekday; // 0 = Sunday … 6 = Saturday
  final int opensMinutes;
  final int closesMinutes; // < opens ⇒ closes after midnight
}

class Branch {
  const Branch({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.lat,
    this.lng,
    this.services = const {},
    this.status = BranchStatus.pendingOwnerData,
    this.hours = const [],
    this.deliveryFee,
    this.minOrder,
    this.hasApprovedMenu = false,
  });
  final String id;
  final L10nText name;
  final L10nText? address;
  final String? phone;
  final double? lat, lng;
  final Set<ServiceType> services;
  final BranchStatus status;
  final List<OpeningHours> hours;
  final Money? deliveryFee; // null = not approved ⇒ delivery unavailable
  final Money? minOrder;
  final bool hasApprovedMenu;

  bool get acceptsOrders => status == BranchStatus.active && hasApprovedMenu;
  bool get deliveryConfigured => services.contains(ServiceType.delivery) && deliveryFee != null;

  /// Hours unknown ⇒ null (UI shows "awaiting data", never guesses).
  bool? isOpenAt(DateTime dubaiLocal) {
    if (hours.isEmpty) return null;
    final d = dubaiLocal.weekday % 7; // DateTime: Mon=1..Sun=7 → Sun=0
    final t = dubaiLocal.hour * 60 + dubaiLocal.minute;
    for (final h in hours) {
      if (h.opensMinutes <= h.closesMinutes) {
        if (h.weekday == d && t >= h.opensMinutes && t < h.closesMinutes) return true;
      } else {
        if ((h.weekday == d && t >= h.opensMinutes) || (h.weekday == (d + 6) % 7 && t < h.closesMinutes)) return true;
      }
    }
    return false;
  }

  Branch copyWith({BranchStatus? status, Set<ServiceType>? services, List<OpeningHours>? hours, Money? deliveryFee, bool clearDeliveryFee = false, bool? hasApprovedMenu}) =>
      Branch(
        id: id,
        name: name,
        address: address,
        phone: phone,
        lat: lat,
        lng: lng,
        services: services ?? this.services,
        status: status ?? this.status,
        hours: hours ?? this.hours,
        deliveryFee: clearDeliveryFee ? null : (deliveryFee ?? this.deliveryFee),
        minOrder: minOrder,
        hasApprovedMenu: hasApprovedMenu ?? this.hasApprovedMenu,
      );
}

class Category {
  const Category({required this.id, required this.sort, required this.name});
  final String id;
  final int sort;
  final L10nText name;
}

class ProductSize {
  const ProductSize({required this.id, required this.name, required this.price});
  final String id;
  final L10nText name;
  final Money? price; // null = not approved
}

class Addon {
  const Addon({required this.id, required this.name, required this.price, this.maxQty = 1});
  final String id;
  final L10nText name;
  final Money? price;
  final int maxQty;
}

class Product {
  const Product({
    required this.id,
    required this.categoryId,
    required this.sort,
    required this.name,
    required this.priceMode,
    this.price,
    this.offerPrice,
    this.description,
    this.imageUrl,
    this.allergens,
    this.sizes = const [],
    this.addons = const [],
    this.available = true,
    this.isNew = false,
  });
  final String id;
  final String categoryId;
  final int sort;
  final L10nText name;
  final PriceMode priceMode;
  final Money? price; // approved base price, null if none
  final Money? offerPrice; // approved & live offer only
  final L10nText? description;
  final String? imageUrl; // ORIGINAL photo only; null ⇒ brand illustration placeholder
  final L10nText? allergens;
  final List<ProductSize> sizes;
  final List<Addon> addons;
  final bool available;
  final bool isNew;

  /// Can be added to the cart: available and has an approved price path.
  bool get orderable {
    if (!available) return false;
    if (sizes.isNotEmpty) return sizes.any((s) => s.price != null);
    return price != null;
  }

  Money? get displayPrice => offerPrice ?? price;

  Product copyWith({bool? available, Money? price, Money? offerPrice, bool clearOffer = false}) => Product(
        id: id,
        categoryId: categoryId,
        sort: sort,
        name: name,
        priceMode: priceMode,
        price: price ?? this.price,
        offerPrice: clearOffer ? null : (offerPrice ?? this.offerPrice),
        description: description,
        imageUrl: imageUrl,
        allergens: allergens,
        sizes: sizes,
        addons: addons,
        available: available ?? this.available,
        isNew: isNew,
      );
}

class Menu {
  const Menu({required this.branchId, required this.categories, required this.products, this.isObservedDemoData = false});
  final String branchId;
  final List<Category> categories;
  final List<Product> products;
  /// True when prices come from the observed Talabat reference (demo build only).
  final bool isObservedDemoData;

  List<Product> productsIn(String categoryId) =>
      products.where((p) => p.categoryId == categoryId).toList()..sort((a, b) => a.sort.compareTo(b.sort));
  Product? byId(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }
}

class Offer {
  const Offer({required this.id, required this.title, required this.productIds, required this.status, this.startsAt, this.endsAt, this.branchIds});
  final String id;
  final L10nText title;
  final List<String> productIds;
  final ApprovalStatus status;
  final DateTime? startsAt, endsAt;
  final List<String>? branchIds;

  /// Shown to customers / signage only if approved AND inside its window.
  bool isLive(DateTime now, String branchId) =>
      status == ApprovalStatus.approved &&
      startsAt != null &&
      endsAt != null &&
      !now.isBefore(startsAt!) &&
      now.isBefore(endsAt!) &&
      (branchIds == null || branchIds!.contains(branchId));
}

class OrderLine {
  const OrderLine({required this.productId, required this.name, required this.qty, required this.unit, required this.lineTotal, this.sizeName, this.addonNames = const [], this.notes});
  final String productId;
  final L10nText name;
  final int qty;
  final Money unit;
  final Money lineTotal;
  final L10nText? sizeName;
  final List<L10nText> addonNames;
  final String? notes;
}

class OrderStatusEvent {
  const OrderStatusEvent(this.status, this.at);
  final OrderStatus status;
  final DateTime at;
}

class Order {
  const Order({
    required this.id,
    required this.number,
    required this.branchId,
    required this.service,
    required this.status,
    required this.paymentStatus,
    required this.lines,
    required this.breakdown,
    required this.createdAt,
    this.history = const [],
    this.cancelReason,
  });
  final String id;
  final int number;
  final String branchId;
  final ServiceType service;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final List<OrderLine> lines;
  final PriceBreakdown breakdown;
  final DateTime createdAt;
  final List<OrderStatusEvent> history;
  final String? cancelReason;

  bool get isActive => !{OrderStatus.completed, OrderStatus.cancelled, OrderStatus.rejected}.contains(status);

  Order copyWith({OrderStatus? status, PaymentStatus? paymentStatus, List<OrderStatusEvent>? history, String? cancelReason}) => Order(
        id: id,
        number: number,
        branchId: branchId,
        service: service,
        status: status ?? this.status,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        lines: lines,
        breakdown: breakdown,
        createdAt: createdAt,
        history: history ?? this.history,
        cancelReason: cancelReason ?? this.cancelReason,
      );
}

class PriceBreakdown {
  const PriceBreakdown({required this.subtotal, required this.discount, required this.deliveryFee, required this.vat, required this.total, required this.vatIncluded});
  final Money subtotal;
  final Money discount;
  final Money deliveryFee;
  final Money vat;
  final Money total;
  final bool vatIncluded;
}
