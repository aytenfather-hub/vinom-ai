import 'package:fb_core/fb_core.dart';
import 'package:flutter/material.dart';

import 'illustrations.dart';
import 'motion.dart';
import 'strings.dart';
import 'tokens.dart';

/// The approved logo, untouched. Minimum digital width 120 px (brand guide).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width = 160, this.onDark = false});
  final double width;
  final bool onDark;
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Fruit Box',
        image: true,
        child: Image.asset(onDark ? 'assets/brand/logo_dark.png' : 'assets/brand/logo.png',
            package: 'fb_ui', width: width < 120 ? 120 : width, filterQuality: FilterQuality.medium),
      );
}

enum FbButtonVariant { primary, secondary, ghost, onDark }

/// Button with states: enabled, pressed (squeeze), loading, disabled.
class FbButton extends StatelessWidget {
  const FbButton({super.key, required this.label, this.onPressed, this.variant = FbButtonVariant.primary, this.loading = false, this.icon, this.trailing, this.expand = false, this.size = 52});
  final String label;
  final VoidCallback? onPressed;
  final FbButtonVariant variant;
  final bool loading;
  final IconData? icon;
  final String? trailing;
  final bool expand;
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final (bg, fg, border) = switch (variant) {
      FbButtonVariant.primary => (FbColors.red, FbColors.cream, Colors.transparent),
      FbButtonVariant.secondary => (Colors.transparent, FbColors.cocoa, FbColors.cocoa),
      FbButtonVariant.ghost => (FbColors.oat, FbColors.cocoa, Colors.transparent),
      FbButtonVariant.onDark => (FbColors.cream, FbColors.cocoa, Colors.transparent),
    };
    final text = Theme.of(context).textTheme.labelLarge!.copyWith(color: fg);
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: trailing != null ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (loading)
            SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
          else if (icon != null)
            Icon(icon, color: fg, size: 20),
          if (loading || icon != null) const SizedBox(width: 8),
          Flexible(child: Text(label, style: text, overflow: TextOverflow.ellipsis)),
        ]),
        if (trailing != null) RollingText(trailing!, style: text),
      ],
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Squeeze(
        onTap: onPressed,
        enabled: enabled,
        child: AnimatedOpacity(
          duration: FbDurations.quick,
          opacity: enabled || loading ? 1 : .45,
          child: Container(
            height: size,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(FbRadius.pill),
              border: Border.all(color: border, width: 2),
              boxShadow: variant == FbButtonVariant.primary && enabled
                  ? [BoxShadow(color: FbColors.red.withValues(alpha: .28), blurRadius: 24, offset: const Offset(0, 10))]
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// M5 — selectable chip that fills like juice from the leading edge.
class FbChoiceChip extends StatelessWidget {
  const FbChoiceChip({super.key, required this.label, required this.selected, this.onTap, this.price, this.enabled = true});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final String? price;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme.labelMedium!;
    final d = FbMotion.d(context, FbDurations.base);
    return Semantics(
      selected: selected,
      button: true,
      enabled: enabled,
      child: Squeeze(
        enabled: enabled,
        onTap: onTap,
        child: AnimatedOpacity(
          duration: d,
          opacity: enabled ? 1 : .45,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(FbRadius.pill),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(FbRadius.pill),
                border: Border.all(color: selected ? FbColors.cocoa : FbColors.line, width: 1.5),
                color: Colors.white,
              ),
              child: Stack(children: [
                Positioned.fill(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AnimatedFractionallySizedBox(
                      duration: d,
                      curve: FbCurves.pour,
                      widthFactor: selected ? 1 : 0,
                      heightFactor: 1,
                      child: const ColoredBox(color: FbColors.cocoa),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    AnimatedSize(
                      duration: d,
                      child: selected ? const Padding(padding: EdgeInsetsDirectional.only(end: 6), child: Icon(Icons.check_rounded, size: 16, color: FbColors.cream)) : const SizedBox.shrink(),
                    ),
                    Text(label, style: t.copyWith(color: selected ? FbColors.cream : FbColors.cocoa)),
                    if (price != null) Text('  $price', style: t.copyWith(color: selected ? FbColors.pink : FbColors.brown, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Price label. Never shows an unapproved price: null ⇒ "by selection".
class PriceTag extends StatelessWidget {
  const PriceTag({super.key, required this.product, this.big = false});
  final Product product;
  final bool big;
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final tt = Theme.of(context).textTheme;
    final p = product.displayPrice;
    if (p == null) return Text(s('price_by_selection'), style: tt.bodySmall);
    final style = (big ? tt.titleLarge : tt.titleSmall)!.copyWith(color: FbColors.red, fontWeight: FontWeight.w900);
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [
      Text(s.money(p), style: style),
      if (product.offerPrice != null && product.price != null)
        Text(s.money(product.price), style: tt.bodySmall!.copyWith(decoration: TextDecoration.lineThrough)),
    ]);
  }
}

/// Product card: image slot (original photo or labelled illustration), name, price, add.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap, this.onAdd, this.addKey, this.favorite = false, this.onFavorite, this.dense = false});
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onAdd;
  final GlobalKey? addKey;
  final bool favorite;
  final VoidCallback? onFavorite;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final tt = Theme.of(context).textTheme;
    final palette = FbDrinkPalettes.forKey(product.categoryId);
    return Semantics(
      button: true,
      label: product.name.of(s.locale),
      child: Squeeze(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: FbRadius.cardAll,
            boxShadow: [BoxShadow(color: FbColors.cocoa.withValues(alpha: .08), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AspectRatio(
              aspectRatio: dense ? 1.4 : 1.1,
              child: Stack(children: [
                Positioned.fill(
                  child: Hero(
                    tag: 'art-${product.id}',
                    child: Container(
                      decoration: BoxDecoration(color: palette.$1.withValues(alpha: .28), borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.center,
                      child: product.imageUrl != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(product.imageUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity))
                          : Padding(padding: const EdgeInsets.all(8), child: FittedBox(child: DrinkArt(palette: palette, size: 110))),
                    ),
                  ),
                ),
                if (product.isNew) PositionedDirectional(top: 6, start: 6, child: _Badge(s('new_badge'))),
                if (onFavorite != null)
                  PositionedDirectional(
                    top: 2,
                    end: 2,
                    child: IconButton(
                      tooltip: s('favorites'),
                      onPressed: onFavorite,
                      icon: AnimatedSwitcher(
                        duration: FbMotion.d(context, FbDurations.quick),
                        transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: FbCurves.squeeze), child: c),
                        child: Icon(favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, key: ValueKey(favorite), color: FbColors.red, size: 20),
                      ),
                    ),
                  ),
                if (!product.available)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(color: FbColors.cream.withValues(alpha: .7), borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.center,
                      child: Text(s('unavailable'), style: tt.labelSmall),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 8),
            Text(product.name.of(s.locale), style: tt.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: PriceTag(product: product)),
              if (onAdd != null && product.orderable)
                Semantics(
                  button: true,
                  label: s('add_to_cart'),
                  child: Squeeze(
                    key: addKey,
                    onTap: onAdd,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: FbColors.mint, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                  ),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: FbColors.yellow, borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: FbColors.cocoa)),
      );
}

class FbBadge extends _Badge {
  const FbBadge(super.text, {super.key});
}

/// Empty / error / offline / closed states — one consistent pattern.
class StateView extends StatelessWidget {
  const StateView({super.key, required this.icon, required this.title, this.message, this.action, this.onAction, this.tone = FbColors.mintTint});
  final IconData icon;
  final String title;
  final String? message;
  final String? action;
  final VoidCallback? onAction;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: StaggerIn(
          index: 0,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 96, height: 96, decoration: BoxDecoration(color: tone, shape: BoxShape.circle), child: Icon(icon, size: 42, color: FbColors.cocoa)),
            const SizedBox(height: 18),
            Text(title, style: tt.titleMedium, textAlign: TextAlign.center),
            if (message != null) ...[const SizedBox(height: 6), Text(message!, style: tt.bodyMedium, textAlign: TextAlign.center)],
            if (action != null) ...[const SizedBox(height: 20), FbButton(label: action!, onPressed: onAction, variant: FbButtonVariant.secondary)],
          ]),
        ),
      ),
    );
  }
}

class DemoRibbon extends StatelessWidget {
  const DemoRibbon({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        child: Container(
          width: double.infinity,
          color: FbColors.yellow,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(context.s('demo_ribbon'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: FbColors.cocoa)),
        ),
      );
}

class QtyStepper extends StatelessWidget {
  const QtyStepper({super.key, required this.value, required this.onChanged, this.min = 1, this.max = 50});
  final int value;
  final ValueChanged<int> onChanged;
  final int min, max;
  @override
  Widget build(BuildContext context) {
    Widget b(IconData i, int v, bool on, String label) => Semantics(
          button: true,
          label: label,
          child: Squeeze(
            enabled: on,
            onTap: () => onChanged(v),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: on ? FbColors.mint : FbColors.line, borderRadius: BorderRadius.circular(11)),
              child: Icon(i, size: 18, color: on ? Colors.white : FbColors.muted),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(FbRadius.pill), border: Border.all(color: FbColors.line)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        b(Icons.remove_rounded, value - 1, value > min, '-'),
        SizedBox(width: 36, child: RollingText('$value', style: Theme.of(context).textTheme.titleSmall)),
        b(Icons.add_rounded, value + 1, value < max, '+'),
      ]),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Row(children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!, style: Theme.of(context).textTheme.labelMedium!.copyWith(color: FbColors.mintDeep))),
        ]),
      );
}

/// Receipt-style breakdown shown before confirming (items, options, fees, VAT, total).
class PriceBreakdownView extends StatelessWidget {
  const PriceBreakdownView({super.key, required this.breakdown, this.deliveryFeeLabel});
  final PriceBreakdown breakdown;
  final String? deliveryFeeLabel;
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final tt = Theme.of(context).textTheme;
    Widget row(String k, String v, {bool strong = false, Color? c}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Expanded(child: Text(k, style: strong ? tt.titleMedium : tt.bodyMedium)),
            RollingText(v, style: (strong ? tt.titleMedium : tt.labelMedium)!.copyWith(color: c)),
          ]),
        );
    return Column(children: [
      row(s('subtotal'), s.money(breakdown.subtotal)),
      if (!breakdown.discount.isZero) row(s('discount'), '− ${s.money(breakdown.discount)}', c: FbColors.leaf),
      if (deliveryFeeLabel != null) row(s('delivery_fee'), deliveryFeeLabel!),
      row(breakdown.vatIncluded ? s('vat_included') : s('vat_added'), s.money(breakdown.vat)),
      const Divider(height: 18),
      row(s('total'), s.money(breakdown.total), strong: true, c: FbColors.red),
      Align(alignment: AlignmentDirectional.centerStart, child: Text(s('vat_pending'), style: tt.bodySmall)),
    ]);
  }
}
