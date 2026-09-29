import 'package:fb_core/fb_core.dart';
import 'package:fb_ui/fb_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'screens/account.dart';
import 'screens/browse.dart';
import 'screens/checkout.dart';
import 'screens/onboarding.dart';
import 'screens/orders.dart';

/// Gives every screen access to the session, config and checkout draft.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required this.config, required this.draft, required this.cartKey, required super.child})
      : super(notifier: state);
  final FbConfig config;
  final CheckoutDraft draft;
  final GlobalKey cartKey;

  static AppScope of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<AppScope>()!;
  static AppState state(BuildContext c) => of(c).notifier!;
}

class CheckoutDraft {
  String? address;
  String? coupon;
  Coupon? appliedCoupon;
  String? notes;
  void reset() {
    address = null;
    coupon = null;
    appliedCoupon = null;
    notes = null;
  }
}

class CustomerApp extends StatefulWidget {
  const CustomerApp({super.key, required this.state, required this.config, this.initialLocation});
  final AppState state;
  final FbConfig config;
  final String? initialLocation;
  @override
  State<CustomerApp> createState() => _CustomerAppState();
}

class _CustomerAppState extends State<CustomerApp> {
  final _draft = CheckoutDraft();
  final _cartKey = GlobalKey(debugLabel: 'cart-tab');
  late final GoRouter _router = buildRouter(widget.state, widget.initialLocation);

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      config: widget.config,
      draft: _draft,
      cartKey: _cartKey,
      child: ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) {
          final st = widget.state;
          return FbMotion(
            reduce: st.reduceMotionOverride,
            child: MaterialApp.router(
              title: 'Fruit Box',
              debugShowCheckedModeBanner: false,
              locale: Locale(st.locale),
              supportedLocales: const [Locale('ar'), Locale('en')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              theme: FbTheme.light(st.locale),
              darkTheme: FbTheme.dark(st.locale),
              themeMode: ThemeMode.light,
              routerConfig: _router,
              builder: (context, child) => Column(children: [
                if (widget.config.isDemo) SafeArea(bottom: false, child: const DemoRibbon()),
                Expanded(child: MediaQuery.removePadding(context: context, removeTop: widget.config.isDemo, child: child!)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

/// M2 — section transitions follow reading direction; fade under reduced motion.
CustomTransitionPage<void> fbPage(GoRouterState s, Widget child) => CustomTransitionPage<void>(
      key: s.pageKey,
      child: child,
      transitionDuration: FbDurations.smooth,
      reverseTransitionDuration: FbDurations.base,
      transitionsBuilder: (context, a, sa, c) {
        if (FbMotion.reduced(context)) return FadeTransition(opacity: a, child: c);
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final curved = CurvedAnimation(parent: a, curve: FbCurves.pour, reverseCurve: FbCurves.settle);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(position: Tween(begin: Offset(rtl ? -.08 : .08, 0), end: Offset.zero).animate(curved), child: c),
        );
      },
    );

GoRouter buildRouter(AppState st, [String? initial]) => GoRouter(
      initialLocation: initial ?? '/',
      refreshListenable: st,
      redirect: (context, s) {
        final loc = s.matchedLocation;
        final inOnboarding = loc.startsWith('/onboarding') || loc == '/';
        if (!st.onboarded && !inOnboarding && !loc.startsWith('/dev')) return '/onboarding/language';
        return null;
      },
      routes: [
        GoRoute(path: '/', pageBuilder: (c, s) => fbPage(s, const SplashScreen())),
        GoRoute(path: '/onboarding/language', pageBuilder: (c, s) => fbPage(s, const LanguageScreen())),
        GoRoute(path: '/onboarding/branch', pageBuilder: (c, s) => fbPage(s, const BranchScreen())),
        GoRoute(path: '/onboarding/service', pageBuilder: (c, s) => fbPage(s, const ServiceScreen())),
        StatefulShellRoute.indexedStack(
          builder: (c, s, shell) => MainShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (c, s) => const HomeScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/menu', builder: (c, s) => const MenuScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/offers', builder: (c, s) => const OffersScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/orders', builder: (c, s) => const OrdersScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/account', builder: (c, s) => const AccountScreen())]),
          ],
        ),
        GoRoute(path: '/menu/:id', pageBuilder: (c, s) => fbPage(s, CategoryScreen(categoryId: s.pathParameters['id']!))),
        GoRoute(path: '/search', pageBuilder: (c, s) => fbPage(s, const SearchScreen())),
        GoRoute(path: '/product/:id', pageBuilder: (c, s) => fbPage(s, ProductScreen(productId: s.pathParameters['id']!))),
        GoRoute(path: '/favorites', pageBuilder: (c, s) => fbPage(s, const FavoritesScreen())),
        GoRoute(path: '/cart', pageBuilder: (c, s) => fbPage(s, const CartScreen())),
        GoRoute(path: '/auth', pageBuilder: (c, s) => fbPage(s, AuthScreen(next: s.uri.queryParameters['next']))),
        GoRoute(path: '/checkout/address', pageBuilder: (c, s) => fbPage(s, const AddressScreen())),
        GoRoute(path: '/checkout/rewards', pageBuilder: (c, s) => fbPage(s, const RewardsScreen())),
        GoRoute(path: '/checkout/review', pageBuilder: (c, s) => fbPage(s, const ReviewScreen())),
        GoRoute(path: '/checkout/payment/:id', pageBuilder: (c, s) => fbPage(s, PaymentScreen(orderId: s.pathParameters['id']!))),
        GoRoute(path: '/order/:id/confirmed', pageBuilder: (c, s) => fbPage(s, ConfirmedScreen(orderId: s.pathParameters['id']!))),
        GoRoute(path: '/order/:id', pageBuilder: (c, s) => fbPage(s, TrackingScreen(orderId: s.pathParameters['id']!))),
        GoRoute(path: '/order/:id/rate', pageBuilder: (c, s) => fbPage(s, RateScreen(orderId: s.pathParameters['id']!))),
        GoRoute(path: '/notifications', pageBuilder: (c, s) => fbPage(s, const NotificationsScreen())),
        GoRoute(path: '/support', pageBuilder: (c, s) => fbPage(s, const SupportScreen())),
        GoRoute(path: '/dev/tools', pageBuilder: (c, s) => fbPage(s, const DemoToolsScreen())),
        GoRoute(path: '/dev/motion', pageBuilder: (c, s) => fbPage(s, const MotionLabScreen())),
      ],
    );

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final st = AppScope.state(context);
    final scope = AppScope.of(context);
    return Scaffold(
      body: shell,
      floatingActionButton: ListenableBuilder(
        listenable: st.cart,
        builder: (context, _) => AnimatedScale(
          scale: st.cart.isEmpty ? 0 : 1,
          duration: FbMotion.d(context, FbDurations.base),
          curve: FbCurves.squeeze,
          child: FloatingActionButton.extended(
            key: scope.cartKey,
            heroTag: 'cart-fab',
            backgroundColor: FbColors.cocoa,
            foregroundColor: FbColors.cream,
            onPressed: () => context.push('/cart'),
            icon: Badge(label: Text('${st.cart.count}'), child: const Icon(Icons.shopping_bag_outlined)),
            label: Text('${s('view_cart')} · ${s.money(st.cart.subtotal)}'),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded, color: FbColors.red), label: s('home')),
          NavigationDestination(icon: const Icon(Icons.menu_book_outlined), selectedIcon: const Icon(Icons.menu_book_rounded, color: FbColors.red), label: s('menu')),
          NavigationDestination(icon: const Icon(Icons.local_offer_outlined), selectedIcon: const Icon(Icons.local_offer_rounded, color: FbColors.red), label: s('offers')),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long_rounded, color: FbColors.red), label: s('orders')),
          NavigationDestination(icon: const Icon(Icons.person_outline_rounded), selectedIcon: const Icon(Icons.person_rounded, color: FbColors.red), label: s('account')),
        ],
      ),
    );
  }
}
