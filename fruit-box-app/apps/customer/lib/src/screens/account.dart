import 'package:fb_core/fb_core.dart';
import 'package:fb_ui/fb_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';

/// C19 — account (guest or signed-in), settings, links.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final st = scope.notifier!;
    final s = context.s;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(s('account'))),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 120), children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: FbColors.cocoa, borderRadius: FbRadius.cardAll),
          child: Row(children: [
            const CircleAvatar(radius: 26, backgroundColor: FbColors.mint, child: Icon(Icons.person_rounded, color: FbColors.cocoa)),
            const SizedBox(width: 14),
            Expanded(child: Text(st.isGuest ? s('guest') : st.signedInPhone!, style: tt.titleMedium!.copyWith(color: FbColors.cream), textDirection: TextDirection.ltr)),
            if (st.isGuest) FbButton(label: s('sign_in'), variant: FbButtonVariant.onDark, size: 40, onPressed: () => context.push('/auth')),
          ]),
        ),
        const SizedBox(height: 12),
        _Tile(Icons.favorite_border_rounded, s('favorites'), () => context.push('/favorites')),
        _Tile(Icons.notifications_none_rounded, s('notifications'), () => context.push('/notifications')),
        _Tile(Icons.storefront_outlined, s('choose_branch'), () => context.push('/onboarding/branch')),
        _Tile(Icons.support_agent_rounded, s('support'), () => context.push('/support')),
        const SizedBox(height: 8),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.translate_rounded),
              title: Text(s('language')),
              trailing: SegmentedButton<String>(
                segments: const [ButtonSegment(value: 'ar', label: Text('ع')), ButtonSegment(value: 'en', label: Text('EN'))],
                selected: {st.locale},
                onSelectionChanged: (v) => st.setLocale(v.first),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.motion_photos_off_outlined),
              title: Text(s('reduce_motion')),
              value: st.reduceMotionOverride ?? FbMotion.reduced(context),
              onChanged: st.setReduceMotion,
            ),
          ]),
        ),
        if (scope.config.isDemo) _Tile(Icons.science_outlined, s('demo_tools'), () => context.push('/dev/tools')),
        if (!st.isGuest) _Tile(Icons.logout_rounded, s('sign_out'), st.signOut),
      ]),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.title, this.onTap);
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Card(child: ListTile(leading: Icon(icon, color: FbColors.brown), title: Text(title), trailing: const Icon(Icons.chevron_right_rounded), onTap: onTap)),
      );
}

/// C21 — notifications incl. permission-denied state.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final st = AppScope.state(context);
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s('notifications'))),
      body: Column(children: [
        if (!st.notificationsAllowed)
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: FbColors.oat, borderRadius: FbRadius.cardAll),
            child: Row(children: [
              const Icon(Icons.notifications_off_outlined, color: FbColors.brown),
              const SizedBox(width: 10),
              Expanded(child: Text(s('notifications_denied'))),
              TextButton(
                onPressed: st.allowNotifications,
                child: Text(s('enable')),
              ),
            ]),
          ),
        Expanded(child: StateView(icon: Icons.notifications_none_rounded, title: s('notifications_empty'))),
      ]),
    );
  }
}

/// C22 — support. The target support e-mail is shown as "being set up" — nothing is sent.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final cfg = AppScope.of(context).config;
    final s = context.s;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(s('support'))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.mail_outline_rounded),
            title: Text(cfg.supportEmail, textDirection: TextDirection.ltr),
            subtitle: cfg.emailSendingEnabled ? null : Text(s('support_email_pending'), style: tt.bodySmall),
          ),
        ),
        const SizedBox(height: 12),
        Text(s('recover_sub'), style: tt.bodyMedium),
      ]),
    );
  }
}

/// Test tools (demo builds only): reproduce offline, closed branch, payment failure, test delivery.
class DemoToolsScreen extends StatefulWidget {
  const DemoToolsScreen({super.key});
  @override
  State<DemoToolsScreen> createState() => _DemoToolsScreenState();
}

class _DemoToolsScreenState extends State<DemoToolsScreen> {
  @override
  Widget build(BuildContext context) {
    final st = AppScope.state(context);
    final repo = st.repo;
    final s = context.s;
    if (repo is! DemoRepository) return Scaffold(appBar: AppBar(), body: const SizedBox());
    final sw = repo.switches;
    Widget toggle(String title, bool v, ValueChanged<bool> on) => SwitchListTile(title: Text(title), value: v, onChanged: (x) => setState(() => on(x)));
    return Scaffold(
      appBar: AppBar(title: Text(s('demo_tools'))),
      body: ListView(children: [
        toggle(s.isAr ? 'محاكاة انقطاع الإنترنت' : 'Simulate offline', sw.offline, (v) => sw.offline = v),
        toggle(s.isAr ? 'محاكاة إغلاق الفرع' : 'Simulate closed branch', sw.branchClosed, (v) => sw.branchClosed = v),
        toggle(s.isAr ? 'محاكاة فشل الدفع' : 'Simulate payment failure', sw.paymentFailure, (v) => sw.paymentFailure = v),
        toggle(s.isAr ? 'توصيل تجريبي (رسوم 0 — غير معتمدة)' : 'Test delivery (fee 0 — unapproved)', sw.testDelivery, (v) => sw.testDelivery = v),
        ListTile(
          leading: const Icon(Icons.refresh_rounded),
          title: Text(s.isAr ? 'تطبيق وإعادة التحميل' : 'Apply & reload'),
          onTap: st.refresh,
        ),
        ListTile(leading: const Icon(Icons.animation_rounded), title: Text(s.isAr ? 'معمل الحركة' : 'Motion lab'), onTap: () => context.push('/dev/motion')),
      ]),
    );
  }
}

/// Motion lab: every motion from docs/04-motion.md on one screen (M1, M4–M8, M10).
class MotionLabScreen extends StatefulWidget {
  const MotionLabScreen({super.key});
  @override
  State<MotionLabScreen> createState() => _MotionLabScreenState();
}

class _MotionLabScreenState extends State<MotionLabScreen> {
  final sel = <String>{};
  int size = 1;
  int replay = 0;
  double progress = .4;
  final from = GlobalKey();
  final to = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    const sizes = ['S', 'M', 'L'];
    return Scaffold(
      appBar: AppBar(title: const Text('Motion lab'), actions: [IconButton(key: to, onPressed: null, icon: const Icon(Icons.shopping_bag_outlined))]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('M1 intro', style: tt.titleSmall),
        SizedBox(height: 260, child: ClipRRect(borderRadius: FbRadius.cardAll, child: FbIntro(key: ValueKey('i$replay'), onDone: () {}, logo: const BrandLogo(width: 160)))),
        TextButton(onPressed: () => setState(() => replay++), child: const Text('Replay')),
        Text('M4 size → price roll', style: tt.titleSmall),
        Wrap(spacing: 8, children: [for (var i = 0; i < 3; i++) FbChoiceChip(label: sizes[i], selected: size == i, onTap: () => setState(() => size = i))]),
        RollingText('${[18, 22, 26][size]}.00', style: tt.titleLarge),
        const SizedBox(height: 12),
        Text('M5 add-on chips', style: tt.titleSmall),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final a in const ['A', 'B', 'C']) FbChoiceChip(label: 'Add-on $a', selected: sel.contains(a), onTap: () => setState(() => sel.contains(a) ? sel.remove(a) : sel.add(a))),
        ]),
        const SizedBox(height: 12),
        Text('M6 add to cart', style: tt.titleSmall),
        KeyedSubtree(key: from, child: FbButton(label: 'Add', onPressed: () => FlyToCart.run(context, from: from, to: to, color: FbColors.red))),
        const SizedBox(height: 12),
        Text('M7 order confirmed', style: tt.titleSmall),
        Center(child: OrderConfirmedArt(key: ValueKey('c$replay'), size: 200)),
        Text('M8 tracking', style: tt.titleSmall),
        JuiceProgress(value: progress),
        Slider(value: progress, onChanged: (v) => setState(() => progress = v)),
        Text('M10 skeleton', style: tt.titleSmall),
        const Skeleton(height: 80, radius: 22),
      ]),
    );
  }
}
