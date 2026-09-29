import 'package:fb_core/fb_core.dart';
import 'package:fb_ui/fb_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';

/// Adds a product, flies a drop to the cart and confirms. Shared by cards and the product page.
void addToCart(BuildContext context, CartLine line, GlobalKey from) {
  final scope = AppScope.of(context);
  scope.notifier!.cart.add(line);
  FlyToCart.run(context, from: from, to: scope.cartKey, color: FbDrinkPalettes.forKey(line.product.categoryId).$2);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      duration: const Duration(seconds: 2),
      content: Text('${context.s('added_to_cart')} · ${line.product.name.of(context.s.locale)}'),
      action: SnackBarAction(label: context.s('view_cart'), textColor: FbColors.pink, onPressed: () => context.push('/cart')),
    ));
}

/// Shared menu-level states: loading, offline/error, no menu for branch.
Widget? menuState(BuildContext context) {
  final st = AppScope.state(context);
  final s = context.s;
  if (st.loading && st.menu == null) {
    return GridView.count(
      padding: const EdgeInsets.all(20),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: .72,
      children: List.generate(6, (_) => const Skeleton(radius: 22)),
    );
  }
  if (st.error != null && st.menu == null) {
    final off = st.error!.code == FbError.offline;
    return StateView(icon: off ? Icons.wifi_off_rounded : Icons.error_outline_rounded, title: off ? s('offline') : s.error(st.error!), message: off ? s('offline_sub') : null, action: s('retry'), onAction: st.refresh);
  }
  if (st.menu == null) {
    return StateView(icon: Icons.storefront_outlined, title: s('branch_pending'), action: s('choose_branch'), onAction: () => context.push('/onboarding/branch'));
  }
  return null;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _keys = <String, GlobalKey>{};
  GlobalKey _k(String id) => _keys.putIfAbsent(id, GlobalKey.new);

  @override
  Widget build(BuildContext context) {
    final st = AppScope.state(context);
    final s = context.s;
    final tt = Theme.of(context).textTheme;
    final state = menuState(context);
    final m = st.menu;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: FbColors.red,
          onRefresh: st.refresh,
          child: CustomScrollView(slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(children: [
                  const BrandLogo(width: 120),
                  const Spacer(),
                  IconButton.filledTonal(tooltip: s('notifications'), onPressed: () => context.push('/notifications'), icon: const Icon(Icons.notifications_none_rounded)),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 8),
                  Text(s('greeting'), style: tt.headlineMedium),
                  const SizedBox(height: 10),
                  Squeeze(
                    onTap: () => context.push('/onboarding/branch'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: FbColors.mintTint, borderRadius: BorderRadius.circular(FbRadius.pill)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(st.service == ServiceType.pickup ? Icons.storefront_rounded : Icons.delivery_dining_rounded, size: 18, color: FbColors.mintDeep),
                        const SizedBox(width: 6),
                        Text('${s(st.service.name)} · ${st.branch?.name.of(s.locale) ?? ''}', style: tt.labelMedium),
                        const Icon(Icons.expand_more_rounded, size: 18),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Semantics(
                    button: true,
                    label: s('search'),
                    child: Squeeze(
                      onTap: () => context.push('/search'),
                      child: InputDecorator(
                        decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: s('search_hint')),
                        child: Text(s('search_hint'), style: tt.bodyMedium!.copyWith(color: FbColors.muted)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Brand hero — not an offer; offers only appear when approved.
                  StaggerIn(
                    index: 0,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(color: FbColors.mint, borderRadius: BorderRadius.circular(28)),
                      child: Stack(children: [
                        PositionedDirectional(end: -10, bottom: -8, child: DrinkArt(palette: FbDrinkPalettes.strawberry, size: 160)),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(s('tagline'), style: tt.titleLarge!.copyWith(color: FbColors.cocoa)),
                            const SizedBox(height: 10),
                            FbButton(label: s('browse_menu'), size: 42, onPressed: () => context.go('/menu')),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
            if (state != null)
              SliverFillRemaining(hasScrollBody: false, child: SizedBox(height: 360, child: state))
            else ...[
              SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 20), sliver: SliverToBoxAdapter(child: SectionHeader(s('categories'), action: s('see_all'), onAction: () => context.go('/menu')))),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: m!.categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (c, i) => FbChoiceChip(label: m.categories[i].name.of(s.locale), selected: false, onTap: () => context.push('/menu/${m.categories[i].id}')),
                  ),
                ),
              ),
              SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 20), sliver: SliverToBoxAdapter(child: SectionHeader(s('new_items')))),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 250,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: m.products.where((p) => p.isNew).length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (c, i) {
                      final p = m.products.where((p) => p.isNew).elementAt(i);
                      return SizedBox(
                        width: 170,
                        child: StaggerIn(
                          index: i,
                          child: ProductCard(
                            product: p,
                            addKey: _k(p.id),
                            favorite: st.favorites.contains(p.id),
                            onFavorite: () => st.toggleFavorite(p.id),
                            onTap: () => context.push('/product/${p.id}'),
                            onAdd: () => addToCart(context, CartLine(product: p), _k(p.id)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ]),
        ),
      ),
    );
  }
}

/// C06 — all categories.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final st = AppScope.state(context);
    final s = context.s;
    final tt = Theme.of(context).textTheme;
    final state = menuState(context);
    return Scaffold(
      appBar: AppBar(title: Text(s('menu')), actions: [IconButton(tooltip: s('search'), onPressed: () => context.push('/search'), icon: const Icon(Icons.search_rounded))]),
      body: state ??
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth > 700 ? 4 : 2;
            final m = st.menu!;
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.05),
              itemCount: m.categories.length,
              itemBuilder: (context, i) {
                final cat = m.categories[i];
                final items = m.productsIn(cat.id);
                final orderable = items.where((p) => p.orderable).length;
                final pal = FbDrinkPalettes.forKey(cat.id);
                return StaggerIn(
                  index: i,
                  child: Squeeze(
                    onTap: () => context.push('/menu/${cat.id}'),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: pal.$1.withValues(alpha: .35), borderRadius: FbRadius.cardAll),
                      child: Stack(children: [
                        PositionedDirectional(end: -6, bottom: -6, child: DrinkArt(palette: pal, size: 76, topping: false)),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(cat.name.of(s.locale), style: tt.titleSmall, maxLines: 2),
                          const SizedBox(height: 4),
                          Text(s.isAr ? '${items.length} صنفاً' : '${items.length} items', style: tt.bodySmall),
                          if (orderable < items.length)
                            Text(s.isAr ? '$orderable متاح للطلب' : '$orderable orderable', style: tt.bodySmall!.copyWith(color: FbColors.brown)),
                        ]),
                      ]),
                    ),
                  ),
                );
              },
            );
          }),
    );
  }
}

/// C07 — one category.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.categoryId});
  final String categoryId;
  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _keys = <String, GlobalKey>{};
  @override
  Widget build(BuildContext context) {
    final st = AppScope.state(context);
    final s = context.s;
    final state = menuState(context);
    final m = st.menu;
    final cat = m?.categories.where((c) => c.id == widget.categoryId).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(cat?.name.of(s.locale) ?? s('menu'))),
      body: state ??
          (cat == null
              ? StateView(icon: Icons.search_off_rounded, title: s('no_results'))
              : ProductGrid(products: m!.productsIn(cat.id), keys: _keys)),
    );
  }
}

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.products, required this.keys});
  final List<Product> products;
  final Map<String, GlobalKey> keys;
  @override
  Widget build(BuildContext context) {
    final st = AppScope.state(context);
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 900 ? 4 : c.maxWidth > 600 ? 3 : 2;
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .66),
        itemCount: products.length,
        itemBuilder: (context, i) {
          final p = products[i];
          final k = keys.putIfAbsent(p.id, GlobalKey.new);
          return StaggerIn(
            index: i,
            child: ProductCard(
              product: p,
              addKey: k,
              favorite: st.favorites.contains(p.id),
              onFavorite: () => st.toggleFavorite(p.id),
              onTap: () => context.push('/product/${p.id}'),
              onAdd: () => addToCart(context, CartLine(product: p), k),
            ),
          );
        },
      );
    });
  }
}

/// C08 — search & filter.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String q = '';
  String filter = 'all';
  final _keys = <String, GlobalKey>{};

  static String _norm(String s) => s
      .replaceAll(RegExp('[أإآا]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .toLowerCase();

  @override
  Widget build(BuildContext context) {
    final st = AppScope.state(context);
    final s = context.s;
    final m = st.menu;
    final results = (m?.products ?? const <Product>[]).where((p) {
      final hit = q.isEmpty || _norm(p.name.of(s.locale)).contains(_norm(q)) || _norm(p.name.ar).contains(_norm(q));
      final f = switch (filter) { 'orderable' => p.orderable, 'new' => p.isNew, _ => true };
      return hit && f;
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          onChanged: (v) => setState(() => q = v.trim()),
          decoration: InputDecoration(hintText: s('search_hint'), prefixIcon: const Icon(Icons.search_rounded)),
        ),
      ),
      body: Column(children: [
        SizedBox(
          height: 52,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6), children: [
            for (final f in const ['all', 'orderable', 'new'])
              Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: FbChoiceChip(label: s('filter_$f'), selected: filter == f, onTap: () => setState(() => filter = f))),
          ]),
        ),
        Expanded(
          child: menuState(context) ??
              (results.isEmpty
                  ? StateView(icon: Icons.search_off_rounded, title: s('no_results'), message: s('no_results_sub'))
                  : ProductGrid(products: results, keys: _keys)),
        ),
      ]),
    );
  }
}

/// C09 — product: size, add-ons, notes, quantity; live total; unavailable & by-selection states.
class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.productId});
  final String productId;
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  ProductSize? size;
  final Map<String, int> addons = {};
  int qty = 1;
  final notes = TextEditingController();
  final _addKey = GlobalKey();

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.state(context);
    final s = context.s;
    final tt = Theme.of(context).textTheme;
    final p = st.menu?.byId(widget.productId);
    if (p == null) return Scaffold(appBar: AppBar(), body: menuState(context) ?? StateView(icon: Icons.search_off_rounded, title: s('no_results')));
    size ??= p.sizes.where((z) => z.price != null).firstOrNull;
    final line = CartLine(
      product: p,
      size: size,
      addons: [for (final a in p.addons) if ((addons[a.id] ?? 0) > 0) SelectedAddon(a, addons[a.id]!)],
      qty: qty,
      notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
    );
    final pal = FbDrinkPalettes.forKey(p.categoryId);
    return Scaffold(
      backgroundColor: pal.$1.withValues(alpha: .25),
      appBar: AppBar(actions: [
        IconButton(
          tooltip: s('favorites'),
          onPressed: () => st.toggleFavorite(p.id),
          icon: Icon(st.favorites.contains(p.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: FbColors.red),
        ),
      ]),
      body: ListView(padding: EdgeInsets.zero, children: [
        SizedBox(
          height: 250,
          child: Column(children: [
            Expanded(
              child: Hero(
                tag: 'art-${p.id}',
                child: p.imageUrl != null
                    ? Image.network(p.imageUrl!, fit: BoxFit.contain)
                    : AnimatedScale(
                        scale: size == null || p.sizes.isEmpty ? 1 : .85 + .15 * (p.sizes.indexOf(size!) + 1) / p.sizes.length,
                        duration: FbMotion.d(context, FbDurations.quick),
                        curve: FbCurves.squeeze,
                        child: DrinkArt(palette: pal, size: 220),
                      ),
              ),
            ),
            if (p.imageUrl == null) Text(s('illustration_note'), style: tt.bodySmall),
          ]),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          decoration: const BoxDecoration(color: FbColors.cream, borderRadius: BorderRadius.vertical(top: Radius.circular(FbRadius.sheet))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(p.name.of(s.locale), style: tt.headlineMedium)),
              PriceTag(product: p, big: true),
            ]),
            if (p.description != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(p.description!.of(s.locale), style: tt.bodyLarge)),
            if (!p.available) _Notice(icon: Icons.block_rounded, text: s('unavailable'), tone: FbColors.blushTint),
            if (p.priceMode == PriceMode.bySelection && !p.orderable) _Notice(icon: Icons.info_outline_rounded, text: s('price_by_selection_long'), tone: FbColors.oat),
            if (p.sizes.isNotEmpty) ...[
              SectionHeader(s('size')),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final z in p.sizes)
                  FbChoiceChip(label: z.name.of(s.locale), price: z.price == null ? null : s.money(z.price), selected: size?.id == z.id, enabled: z.price != null, onTap: () => setState(() => size = z)),
              ]),
            ],
            if (p.addons.isNotEmpty) ...[
              SectionHeader(s('addons')),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final a in p.addons)
                  FbChoiceChip(
                    label: a.name.of(s.locale),
                    price: a.price == null ? null : '+${s.money(a.price)}',
                    enabled: a.price != null,
                    selected: (addons[a.id] ?? 0) > 0,
                    onTap: () => setState(() => addons[a.id] = (addons[a.id] ?? 0) > 0 ? 0 : 1),
                  ),
              ]),
            ],
            SectionHeader(s('notes')),
            TextField(controller: notes, maxLength: 200, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: s('notes_hint'))),
            SectionHeader(s('allergens')),
            Text(p.allergens?.of(s.locale) ?? s('allergens_pending'), style: tt.bodyMedium),
          ]),
        ),
      ]),
      bottomNavigationBar: Container(
        color: FbColors.cream,
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Row(children: [
            QtyStepper(value: qty, onChanged: (v) => setState(() => qty = v)),
            const SizedBox(width: 12),
            Expanded(
              child: KeyedSubtree(
                key: _addKey,
                child: FbButton(
                  label: s('add_to_cart'),
                  trailing: line.lineTotal == null ? null : s.money(line.lineTotal),
                  expand: true,
                  onPressed: p.orderable && line.unitPrice != null
                      ? () {
                          addToCart(context, line, _addKey);
                          context.pop();
                        }
                      : null,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, required this.tone});
  final IconData icon;
  final String text;
  final Color tone;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(16)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: FbColors.brown),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ]),
      );
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final st = AppScope.state(context);
    final s = context.s;
    final items = (st.menu?.products ?? const <Product>[]).where((p) => st.favorites.contains(p.id)).toList();
    return Scaffold(
      appBar: AppBar(title: Text(s('favorites'))),
      body: items.isEmpty
          ? StateView(icon: Icons.favorite_border_rounded, title: s('favorites_empty'), action: s('browse_menu'), onAction: () => context.go('/menu'), tone: FbColors.blushTint)
          : ProductGrid(products: items, keys: {}),
    );
  }
}

/// Offers tab: only approved offers inside their window are listed.
class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final st = AppScope.state(context);
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s('offers'))),
      body: FutureBuilder<List<Offer>>(
        future: st.branchId == null ? Future.value(const []) : st.repo.liveOffers(st.branchId!),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: FbColors.red));
          final offers = snap.data!;
          if (offers.isEmpty) return StateView(icon: Icons.local_offer_outlined, title: s('no_offers'), message: s('no_offers_sub'), tone: FbColors.blushTint);
          return ListView(padding: const EdgeInsets.all(20), children: [
            for (final (i, o) in offers.indexed)
              StaggerIn(
                index: i,
                child: Card(child: ListTile(title: Text(o.title.of(s.locale)), subtitle: Text('${o.productIds.length}'))),
              ),
          ]);
        },
      ),
    );
  }
}
