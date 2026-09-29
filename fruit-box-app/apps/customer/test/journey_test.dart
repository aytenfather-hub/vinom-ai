import 'dart:io';

import 'package:fb_core/fb_core.dart';
import 'package:fb_ui/fb_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruitbox_customer/src/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _seed(String f) => File('../../packages/fb_core/assets/seed/$f').readAsStringSync();

Future<void> _loadFonts() async {
  for (final (fam, files) in [
    ('packages/fb_ui/Cairo', ['400', '600', '700', '800', '900']),
    ('packages/fb_ui/Poppins', ['400', '600', '700', '800']),
  ]) {
    final l = FontLoader(fam);
    for (final w in files) {
      final name = fam.split('/').last;
      l.addFont(Future.value(ByteData.sublistView(File('../../packages/fb_ui/fonts/$name-$w.ttf').readAsBytesSync())));
    }
    await l.load();
  }
}

DemoRepository _repo() => DemoRepository(menuJson: _seed('seed_menu_new_shahama.json'), branchesJson: _seed('seed_branches.json'))..switches.secondsPerStep = 1;

Future<(AppState, DemoRepository)> _boot(WidgetTester t, {Size size = const Size(390, 844), String? locale, Map<String, Object> prefs = const {}, bool settle = true}) async {
  SharedPreferences.setMockInitialValues({...prefs, 'locale': ?locale});
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final repo = _repo();
  final st = AppState(repo);
  await t.runAsync(st.init);
  await t.pumpWidget(CustomerApp(state: st, config: FbConfig.fromEnvironment()));
  await t.pump();
  if (settle) await t.pumpAndSettle();
  return (st, repo);
}

Future<void> _tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(_loadFonts);
  for (final size in const [Size(390, 844), Size(1024, 1366)]) {
    testWidgets('full Arabic RTL journey on ${size.width.toInt()}px: intro → branch → product → cart → sign-in → review → pay → confirmed → tracking', (t) async {
      final (st, _) = await _boot(t, size: size, settle: false);

      // C01 intro plays on first launch and is skippable → C02 language
      expect(find.byType(FbIntro), findsOneWidget);
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('تخطٍّ'));
      await t.pumpAndSettle();
      expect(find.text('اختر لغتك'), findsOneWidget);
      expect(Directionality.of(t.element(find.text('اختر لغتك'))), TextDirection.rtl);
      await _tap(t, find.text('متابعة'));

      // C03 branch: 11 branches, only New Shahama orderable; others pending
      expect(find.text('الشهامة الجديدة'), findsOneWidget);
      expect(find.text('بانتظار اعتماد بيانات الفرع'), findsWidgets);
      await _tap(t, find.text('الشهامة الجديدة'));
      await _tap(t, find.text('متابعة'));

      // C04 service: delivery disabled until fee approved
      expect(find.text('التوصيل غير مفعّل حتى اعتماد الرسوم ومنطقة التغطية'), findsOneWidget);
      await _tap(t, find.text('متابعة'));

      // C05 home
      expect(find.text('وش مزاجك اليوم؟'), findsOneWidget);
      expect(find.text('نسخة تجريبية — أسعار مرصودة غير معتمدة'), findsOneWidget);

      // C09 product (a "new" item, 30 AED)
      await _tap(t, find.text('موز نوتيلا').first);
      expect(find.text('30 د.إ'), findsWidgets);
      expect(find.text('رسم توضيحي — ليس صورة المنتج'), findsOneWidget);
      await _tap(t, find.byIcon(Icons.add_rounded).last);
      expect(find.text('60 د.إ'), findsOneWidget, reason: 'total rolls with quantity');
      await _tap(t, find.text('أضف للسلة'));
      expect(st.cart.count, 2);

      // C11 cart → auth (guest) → rewards → review
      await t.pump(const Duration(seconds: 3));
      await _tap(t, find.byType(FloatingActionButton));
      expect(find.text('المجموع الفرعي'), findsOneWidget);
      await _tap(t, find.text('متابعة الطلب'));
      await t.enterText(find.byType(TextField).first, '0501234567');
      await t.pumpAndSettle();
      await _tap(t, find.text('أرسل الرمز'));
      await t.enterText(find.byType(TextField).at(1), '000000');
      await _tap(t, find.text('متابعة'));
      expect(find.text('الرمز غير صحيح'), findsOneWidget);
      await t.enterText(find.byType(TextField).at(1), '123456');
      await _tap(t, find.text('متابعة'));

      // C13 rewards: invalid coupon; points inactive
      await t.enterText(find.byType(TextField).first, 'SAVE10');
      await _tap(t, find.text('تطبيق'));
      expect(find.text('القسيمة غير صالحة أو منتهية'), findsOneWidget);
      expect(find.text('برنامج النقاط لم يُفعّل بعد'), findsOneWidget);
      await _tap(t, find.text('متابعة'));

      // C14 review: full breakdown before confirming
      expect(find.text('منها ضريبة القيمة المضافة ٥٪'), findsOneWidget);
      expect(find.text('2.86 د.إ'), findsOneWidget);
      expect(find.text('الإجمالي'), findsOneWidget);
      await _tap(t, find.text('تأكيد الطلب والدفع'));

      // C15 payment (simulation) → C16 confirmed → C17 tracking
      expect(find.text('الدفع الإلكتروني غير مفعّل بعد. هذه محاكاة للاختبار فقط.'), findsOneWidget);
      await _tap(t, find.text('محاكاة دفع ناجح'));
      expect(find.text('تم! طلبك وصلنا'), findsOneWidget);
      // tracking has a deliberate continuous "juice" shimmer, so advance time manually
      await t.tap(find.text('تتبّع الطلب'));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('تم استلام الطلب'), findsWidgets);
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('تم قبول الطلب'), findsWidgets, reason: 'status advances live');
      expect(st.cart.isEmpty, isTrue);
      await t.pump(const Duration(seconds: 5)); // let the demo timer finish
    });
  }

  testWidgets('English LTR layout and translated UI', (t) async {
    await _boot(t, locale: 'en', prefs: {'onboarded': true, 'introSeen': true, 'branchId': 'br_04'});
    expect(find.text("What's your mood today?"), findsOneWidget);
    expect(Directionality.of(t.element(find.text("What's your mood today?"))), TextDirection.ltr);
  });

  testWidgets('"price by selection" items cannot be ordered and never show an invented price', (t) async {
    final (st, _) = await _boot(t, prefs: {'onboarded': true, 'introSeen': true, 'branchId': 'br_04'});
    final router = find.byType(Router<Object>);
    expect(router, findsOneWidget);
    st.cart.clear();
    await _tap(t, find.text('المنيو').last);
    await _tap(t, find.text('سلطة الفواكه'));
    expect(find.text('السعر حسب الاختيار'), findsWidgets);
    await _tap(t, find.text('هامبانا').first);
    expect(find.textContaining('بانتظار اعتماد الإدارة'), findsOneWidget);
    final btn = t.widget<FbButton>(find.widgetWithText(FbButton, 'أضف للسلة'));
    expect(btn.onPressed, isNull);
  });

  testWidgets('offline state offers retry', (t) async {
    SharedPreferences.setMockInitialValues({'onboarded': true, 'introSeen': true, 'branchId': 'br_04'});
    final repo = _repo()..switches.offline = true;
    final st = AppState(repo);
    await t.runAsync(st.init);
    await t.pumpWidget(CustomerApp(state: st, config: FbConfig.fromEnvironment()));
    await t.pumpAndSettle();
    expect(find.text('لا يوجد اتصال بالإنترنت'), findsWidgets);
    repo.switches.offline = false;
    await _tap(t, find.text('إعادة المحاولة'));
    expect(find.text('لا يوجد اتصال بالإنترنت'), findsNothing);
  });

  testWidgets('reduced motion: intro completes instantly', (t) async {
    SharedPreferences.setMockInitialValues({'reduceMotion': 'on'});
    final st = AppState(_repo());
    await t.runAsync(st.init);
    await t.pumpWidget(CustomerApp(state: st, config: FbConfig.fromEnvironment()));
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    await t.pumpAndSettle();
    expect(find.text('اختر لغتك'), findsOneWidget);
    expect(find.byType(FbIntro), findsNothing);
  });
}
