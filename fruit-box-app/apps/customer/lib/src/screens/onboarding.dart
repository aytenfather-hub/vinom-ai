import 'package:fb_core/fb_core.dart';
import 'package:fb_ui/fb_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';

/// C01 — first launch plays the intro once; later launches go straight in.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final st = AppScope.state(context);
    void next() {
      st.markIntroSeen();
      context.go(st.onboarded ? '/home' : '/onboarding/language');
    }

    if (st.introSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) next();
      });
      return const ColoredBox(color: FbColors.cream);
    }
    return Scaffold(
      body: Stack(children: [
        FbIntro(onDone: next, logo: const BrandLogo(width: 220)),
        PositionedDirectional(
          bottom: 40,
          start: 0,
          end: 0,
          child: Center(child: Text(context.s('tagline'), style: Theme.of(context).textTheme.titleMedium!.copyWith(color: FbColors.brown))),
        ),
        PositionedDirectional(top: 12, end: 12, child: SafeArea(child: TextButton(onPressed: next, child: Text(context.s('skip'))))),
      ]),
    );
  }
}

/// C02 — language.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final st = AppScope.state(context);
    final tt = Theme.of(context).textTheme;
    Widget option(String code, String title, String sub) {
      final on = st.locale == code;
      return Semantics(
        selected: on,
        button: true,
        child: Squeeze(
          onTap: () => st.setLocale(code),
          child: AnimatedContainer(
            duration: FbMotion.d(context, FbDurations.base),
            curve: FbCurves.pour,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: on ? FbColors.cocoa : Colors.white,
              borderRadius: FbRadius.cardAll,
              border: Border.all(color: on ? FbColors.cocoa : FbColors.line, width: 1.5),
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: tt.titleMedium!.copyWith(color: on ? FbColors.cream : FbColors.cocoa, fontFamily: code == 'ar' ? 'Cairo' : 'Poppins', package: 'fb_ui')),
                  Text(sub, style: tt.bodySmall!.copyWith(color: on ? FbColors.pink : FbColors.muted)),
                ]),
              ),
              Icon(on ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: on ? FbColors.pink : FbColors.muted),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 24),
            const Center(child: BrandLogo(width: 170)),
            const SizedBox(height: 28),
            Text(context.s('choose_language'), style: tt.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            StaggerIn(index: 0, child: option('ar', 'العربية', 'من اليمين إلى اليسار')),
            const SizedBox(height: 12),
            StaggerIn(index: 1, child: option('en', 'English', 'Left to right')),
            const Spacer(),
            FbButton(label: context.s('continue'), expand: true, onPressed: () => context.go('/onboarding/branch')),
          ]),
        ),
      ),
    );
  }
}

/// C03 — region & branch. Pending/closed branches are visible but not selectable for ordering.
class BranchScreen extends StatefulWidget {
  const BranchScreen({super.key});
  @override
  State<BranchScreen> createState() => _BranchScreenState();
}

class _BranchScreenState extends State<BranchScreen> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final st = AppScope.state(context);
    final s = context.s;
    final tt = Theme.of(context).textTheme;
    final list = st.branches.where((b) => b.name.of(s.locale).contains(q)).toList()
      ..sort((a, b) => (b.acceptsOrders ? 1 : 0).compareTo(a.acceptsOrders ? 1 : 0));
    Widget body;
    if (st.loading && st.branches.isEmpty) {
      body = ListView(padding: const EdgeInsets.all(20), children: List.generate(6, (_) => const Padding(padding: EdgeInsets.only(bottom: 12), child: Skeleton(height: 76, radius: 22))));
    } else if (st.error?.code == FbError.offline) {
      body = StateView(icon: Icons.wifi_off_rounded, title: s('offline'), message: s('offline_sub'), action: s('retry'), onAction: st.refresh);
    } else if (list.isEmpty) {
      body = StateView(icon: Icons.storefront_outlined, title: s('no_branches_match'));
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final b = list[i];
          final selected = b.id == st.branchId;
          final status = switch (b.status) {
            BranchStatus.active => (s('branch_open'), FbColors.leaf),
            BranchStatus.temporarilyClosed || BranchStatus.closed => (s('branch_closed'), FbColors.red),
            BranchStatus.pendingOwnerData => (s('branch_pending'), FbColors.muted),
          };
          return StaggerIn(
            index: i,
            child: Opacity(
              opacity: b.acceptsOrders ? 1 : .6,
              child: Squeeze(
                enabled: b.status != BranchStatus.pendingOwnerData,
                onTap: () => st.selectBranch(b.id),
                child: AnimatedContainer(
                  duration: FbMotion.d(context, FbDurations.base),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: FbRadius.cardAll,
                    border: Border.all(color: selected ? FbColors.red : FbColors.line, width: selected ? 2 : 1.2),
                  ),
                  child: Row(children: [
                    Container(width: 44, height: 44, decoration: const BoxDecoration(color: FbColors.mintTint, shape: BoxShape.circle), child: const Icon(Icons.storefront_rounded, color: FbColors.mintDeep)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(b.name.of(s.locale), style: tt.titleSmall),
                        Text(b.hours.isEmpty && b.status == BranchStatus.active ? s('hours_unknown') : status.$1, style: tt.bodySmall!.copyWith(color: status.$2)),
                      ]),
                    ),
                    if (selected) const Icon(Icons.check_circle_rounded, color: FbColors.red),
                  ]),
                ),
              ),
            ),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(s('choose_branch'))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s('choose_branch_sub'), style: tt.bodyMedium),
            const SizedBox(height: 10),
            TextField(onChanged: (v) => setState(() => q = v), decoration: InputDecoration(hintText: s('search_branches'), prefixIcon: const Icon(Icons.search_rounded))),
          ]),
        ),
        Expanded(child: body),
      ]),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: FbButton(label: s('continue'), expand: true, onPressed: st.branch?.acceptsOrders == true ? () => context.go('/onboarding/service') : null),
      ),
    );
  }
}

/// C04 — delivery or pickup, only as enabled for the branch.
class ServiceScreen extends StatelessWidget {
  const ServiceScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final st = AppScope.state(context);
    final s = context.s;
    final tt = Theme.of(context).textTheme;
    final b = st.branch;
    Widget card(ServiceType t, IconData icon, String title, String sub) {
      final enabled = t == ServiceType.pickup ? (b?.services.contains(ServiceType.pickup) ?? false) : (b?.deliveryConfigured ?? false);
      final on = st.service == t && enabled;
      return Semantics(
        selected: on,
        enabled: enabled,
        button: true,
        child: Squeeze(
          enabled: enabled,
          onTap: () => st.setService(t),
          child: AnimatedContainer(
            duration: FbMotion.d(context, FbDurations.base),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: on ? FbColors.mintTint : Colors.white,
              borderRadius: FbRadius.cardAll,
              border: Border.all(color: on ? FbColors.mintDeep : FbColors.line, width: on ? 2 : 1.2),
            ),
            child: Opacity(
              opacity: enabled ? 1 : .5,
              child: Row(children: [
                Icon(icon, size: 34, color: FbColors.cocoa),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: tt.titleMedium),
                    Text(enabled ? sub : s('delivery_unavailable'), style: tt.bodySmall),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );
    }

    if (b != null && !(b.deliveryConfigured) && st.service == ServiceType.delivery) {
      WidgetsBinding.instance.addPostFrameCallback((_) => st.setService(ServiceType.pickup));
    }
    return Scaffold(
      appBar: AppBar(title: Text(b?.name.of(s.locale) ?? '')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(s('how_to_receive'), style: tt.headlineMedium),
          const SizedBox(height: 20),
          StaggerIn(index: 0, child: card(ServiceType.pickup, Icons.storefront_rounded, s('pickup'), s('pickup_sub'))),
          const SizedBox(height: 12),
          StaggerIn(index: 1, child: card(ServiceType.delivery, Icons.delivery_dining_rounded, s('delivery'), s('delivery_sub'))),
          const Spacer(),
          FbButton(
            label: s('continue'),
            expand: true,
            onPressed: () {
              st.completeOnboarding();
              context.go('/home');
            },
          ),
        ]),
      ),
    );
  }
}
