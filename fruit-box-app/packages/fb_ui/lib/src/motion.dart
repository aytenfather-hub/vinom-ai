import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'illustrations.dart';
import 'tokens.dart';

/// Central switch for reduced motion (OS setting OR in-app override).
class FbMotion extends InheritedWidget {
  const FbMotion({super.key, required this.reduce, required super.child});
  final bool? reduce; // null = follow OS

  static bool reduced(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<FbMotion>();
    return w?.reduce ?? MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  static Duration d(BuildContext context, Duration full) => reduced(context) ? FbDurations.reduced : full;

  @override
  bool updateShouldNotify(FbMotion old) => old.reduce != reduce;
}

/// M9 — content enters once with a short pour + stagger. Never re-animates on scroll.
class StaggerIn extends StatelessWidget {
  const StaggerIn({super.key, required this.index, required this.child, this.offset = 14});
  final int index;
  final Widget child;
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (FbMotion.reduced(context)) return child;
    final delay = (index.clamp(0, 8)) * 40;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + delay),
      curve: Interval(delay / (360 + delay), 1, curve: FbCurves.pour),
      builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * offset), child: c)),
      child: child,
    );
  }
}

/// M4 — price rolls when it changes.
class RollingText extends StatelessWidget {
  const RollingText(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: FbMotion.d(context, FbDurations.quick),
        transitionBuilder: (c, a) => FbMotion.reduced(context)
            ? FadeTransition(opacity: a, child: c)
            : SlideTransition(position: Tween(begin: const Offset(0, .5), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: FbCurves.squeeze)),
                child: FadeTransition(opacity: a, child: c)),
        child: Text(text, key: ValueKey(text), style: style),
      );
}

/// Press feedback: a gentle squeeze.
class Squeeze extends StatefulWidget {
  const Squeeze({super.key, required this.child, this.onTap, this.enabled = true});
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  @override
  State<Squeeze> createState() => _SqueezeState();
}

class _SqueezeState extends State<Squeeze> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final reduced = FbMotion.reduced(context);
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: widget.enabled ? (_) => setState(() => _down = false) : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _down && !reduced ? .96 : 1,
        duration: FbDurations.instant,
        curve: FbCurves.squeeze,
        child: widget.child,
      ),
    );
  }
}

/// M1 — "Ribbon" intro: mint circle expands, logo springs up, drops scatter.
/// ≤1.4 s, skippable, shown only on first launch; instant under reduced motion.
class FbIntro extends StatefulWidget {
  const FbIntro({super.key, required this.onDone, this.logo});
  final VoidCallback onDone;
  final Widget? logo;
  @override
  State<FbIntro> createState() => _FbIntroState();
}

class _FbIntroState extends State<FbIntro> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: FbDurations.intro);
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (FbMotion.reduced(context)) {
      _c.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward().whenComplete(_finish);
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final circle = FbCurves.pour.transform((t / .45).clamp(0, 1));
          final logo = FbCurves.squeeze.transform(((t - .2) / .45).clamp(0, 1));
          final drops = ((t - .45) / .55).clamp(0.0, 1.0);
          final size = MediaQuery.sizeOf(context);
          final r = math.max(size.width, size.height);
          return ColoredBox(
            color: FbColors.cream,
            child: Stack(alignment: Alignment.center, children: [
              Container(width: r * 1.3 * circle, height: r * 1.3 * circle, decoration: const BoxDecoration(color: FbColors.mintTint, shape: BoxShape.circle)),
              Container(width: 260 * circle, height: 260 * circle, decoration: const BoxDecoration(color: FbColors.mint, shape: BoxShape.circle)),
              CustomPaint(size: const Size(360, 360), painter: DropsPainter(progress: drops)),
              Transform.translate(
                offset: Offset(0, 40 * (1 - logo)),
                child: Transform.scale(scale: .6 + .4 * logo, child: Opacity(opacity: logo.clamp(0, 1), child: widget.logo)),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class DropsPainter extends CustomPainter {
  DropsPainter({required this.progress});
  final double progress;
  static const _colors = [FbColors.pink, FbColors.red, FbColors.yellow, FbColors.leaf, FbColors.mint];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final c = size.center(Offset.zero);
    for (var i = 0; i < 14; i++) {
      final a = i / 14 * math.pi * 2 + .3;
      final dist = 70 + 110 * Curves.easeOut.transform(progress) + (i % 3) * 12;
      final p = c + Offset(math.cos(a), math.sin(a)) * dist;
      final r = (6 + (i % 4) * 2) * (1 - progress * .6);
      canvas.drawCircle(p, r, Paint()..color = _colors[i % _colors.length].withValues(alpha: 1 - progress * .7));
    }
  }

  @override
  bool shouldRepaint(DropsPainter old) => old.progress != progress;
}

/// M6 — a drop in the product colour flies in an arc to the cart target.
class FlyToCart {
  static Future<void> run(BuildContext context, {required GlobalKey from, required GlobalKey to, required Color color}) async {
    HapticFeedback.lightImpact();
    if (FbMotion.reduced(context)) return;
    final overlay = Overlay.maybeOf(context);
    final fb = from.currentContext?.findRenderObject() as RenderBox?;
    final tb = to.currentContext?.findRenderObject() as RenderBox?;
    if (overlay == null || fb == null || tb == null || !fb.attached || !tb.attached) return;
    final start = fb.localToGlobal(fb.size.center(Offset.zero));
    final end = tb.localToGlobal(tb.size.center(Offset.zero));
    late OverlayEntry e;
    e = OverlayEntry(
      builder: (_) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: FbDurations.hero,
        curve: Curves.easeInOutCubic,
        onEnd: () => e.remove(),
        builder: (_, t, _) {
          final ctrl = Offset((start.dx + end.dx) / 2, math.min(start.dy, end.dy) - 120);
          final p = Offset(
            (1 - t) * (1 - t) * start.dx + 2 * (1 - t) * t * ctrl.dx + t * t * end.dx,
            (1 - t) * (1 - t) * start.dy + 2 * (1 - t) * t * ctrl.dy + t * t * end.dy,
          );
          final s = 22 * (1 - t * .6);
          return Positioned(
            left: p.dx - s / 2,
            top: p.dy - s / 2,
            child: IgnorePointer(child: Container(width: s, height: s * 1.2, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(s)))),
          );
        },
      ),
    );
    overlay.insert(e);
  }
}

/// M7 — cup fills bottom→top, ribbon unfurls, drops pop. ~900 ms.
class OrderConfirmedArt extends StatelessWidget {
  const OrderConfirmedArt({super.key, this.size = 220, this.label = ''});
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    final reduced = FbMotion.reduced(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduced ? 1 : 0, end: 1),
      duration: reduced ? Duration.zero : FbDurations.confirm,
      builder: (_, t, _) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(size: Size.square(size), painter: DropsPainter(progress: ((t - .6) / .4).clamp(0, 1))),
          DrinkArt(palette: FbDrinkPalettes.strawberry, size: size * .72, fill: FbCurves.pour.transform((t / .7).clamp(0, 1)), ribbon: ((t - .5) / .5).clamp(0, 1)),
        ]),
      ),
    );
  }
}

/// M8 — juice-filled progress tube; current step pulses slowly.
class JuiceProgress extends StatefulWidget {
  const JuiceProgress({super.key, required this.value, this.height = 10});
  final double value;
  final double height;
  @override
  State<JuiceProgress> createState() => _JuiceProgressState();
}

class _JuiceProgressState extends State<JuiceProgress> with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(seconds: 2));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FbMotion.reduced(context) ? _wave.stop() : _wave.repeat();
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: widget.value.clamp(0, 1)),
        duration: FbMotion.d(context, FbDurations.smooth),
        curve: FbCurves.pour,
        builder: (_, v, _) => AnimatedBuilder(
          animation: _wave,
          builder: (_, _) => CustomPaint(
            size: Size(double.infinity, widget.height),
            painter: _TubePainter(v, _wave.value, Directionality.of(context)),
          ),
        ),
      ),
    );
  }
}

class _TubePainter extends CustomPainter {
  _TubePainter(this.v, this.phase, this.dir);
  final double v, phase;
  final TextDirection dir;
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.height));
    canvas.drawRRect(r, Paint()..color = FbColors.line);
    canvas.save();
    canvas.clipRRect(r);
    final w = size.width * v;
    final rect = dir == TextDirection.rtl ? Rect.fromLTWH(size.width - w, 0, w, size.height) : Rect.fromLTWH(0, 0, w, size.height);
    canvas.drawRect(rect, Paint()..shader = const LinearGradient(colors: [FbColors.red, FbColors.pink, FbColors.mint]).createShader(Offset.zero & size));
    final shineX = rect.left + rect.width * phase;
    canvas.drawRect(Rect.fromLTWH(shineX - 20, 0, 20, size.height), Paint()..color = Colors.white.withValues(alpha: .25));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TubePainter o) => o.v != v || o.phase != phase;
}

/// M10 — skeleton shimmer.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = 12});
  final double? width;
  final double height;
  final double radius;
  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FbMotion.reduced(context) ? _c.stop() : _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + _c.value * 3, 0),
              end: Alignment(_c.value * 3, 0),
              colors: const [FbColors.oat, FbColors.cream, FbColors.oat],
            ),
          ),
        ),
      );
}
