import 'package:flutter/foundation.dart';

import 'models.dart';
import 'money.dart';

class SelectedAddon {
  const SelectedAddon(this.addon, this.qty);
  final Addon addon;
  final int qty;
}

class CartLine {
  CartLine({required this.product, this.size, this.addons = const [], this.qty = 1, this.notes});
  final Product product;
  final ProductSize? size;
  final List<SelectedAddon> addons;
  int qty;
  final String? notes;

  /// Unit price shown to the customer: size (or base) + offer + add-ons.
  /// Returns null when any component has no approved price.
  Money? get unitPrice {
    final base = size != null ? size!.price : product.displayPrice;
    if (base == null) return null;
    var total = base;
    for (final a in addons) {
      final p = a.addon.price;
      if (p == null) return null;
      total += p * a.qty;
    }
    return total;
  }

  Money? get lineTotal => unitPrice == null ? null : unitPrice! * qty;

  /// Same product + same options ⇒ merge quantities.
  String get signature =>
      '${product.id}|${size?.id}|${addons.map((a) => '${a.addon.id}x${a.qty}').join(',')}|${notes ?? ''}';
}

/// Customer cart. Prices are for display; the server recomputes on checkout.
class Cart extends ChangeNotifier {
  final List<CartLine> _lines = [];
  String? branchId;

  List<CartLine> get lines => List.unmodifiable(_lines);
  bool get isEmpty => _lines.isEmpty;
  int get count => _lines.fold(0, (s, l) => s + l.qty);

  Money get subtotal => _lines.fold(Money.zero, (s, l) => s + (l.lineTotal ?? Money.zero));

  /// Lines that can no longer be ordered (unavailable / price withdrawn).
  List<CartLine> invalidLines(Menu menu) => _lines.where((l) {
        final p = menu.byId(l.product.id);
        return p == null || !p.orderable || l.unitPrice == null;
      }).toList();

  void add(CartLine line) {
    for (final l in _lines) {
      if (l.signature == line.signature) {
        l.qty = (l.qty + line.qty).clamp(1, 50);
        notifyListeners();
        return;
      }
    }
    _lines.add(line);
    notifyListeners();
  }

  void setQty(CartLine line, int qty) {
    if (qty <= 0) {
      _lines.remove(line);
    } else {
      line.qty = qty.clamp(1, 50);
    }
    notifyListeners();
  }

  void remove(CartLine line) {
    _lines.remove(line);
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }

  /// Switching branch empties the cart (prices/availability are per branch).
  void bindBranch(String id) {
    if (branchId != null && branchId != id) _lines.clear();
    branchId = id;
    notifyListeners();
  }
}
