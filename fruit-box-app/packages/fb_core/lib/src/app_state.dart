import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cart.dart';
import 'models.dart';
import 'repository.dart';

/// Customer-side session state shared by the app and the website.
class AppState extends ChangeNotifier {
  AppState(this.repo);
  final FbRepository repo;
  final cart = Cart();
  SharedPreferences? _prefs;

  String locale = 'ar';
  bool onboarded = false;
  bool introSeen = false;
  String? branchId;
  ServiceType service = ServiceType.pickup;
  final Set<String> favorites = {};
  /// null = follow the OS setting.
  bool? reduceMotionOverride;
  String? signedInPhone; // demo auth
  bool notificationsAllowed = false;

  List<Branch> branches = const [];
  Menu? menu;
  bool loading = false;
  FbError? error;

  bool get isGuest => signedInPhone == null;
  Branch? get branch {
    for (final b in branches) {
      if (b.id == branchId) return b;
    }
    return null;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    locale = _prefs!.getString('locale') ?? 'ar';
    onboarded = _prefs!.getBool('onboarded') ?? false;
    introSeen = _prefs!.getBool('introSeen') ?? false;
    branchId = _prefs!.getString('branchId');
    service = _prefs!.getString('service') == 'delivery' ? ServiceType.delivery : ServiceType.pickup;
    favorites.addAll(_prefs!.getStringList('favorites') ?? const []);
    final rm = _prefs!.getString('reduceMotion');
    reduceMotionOverride = rm == null ? null : rm == 'on';
    signedInPhone = _prefs!.getString('phone');
    await refresh();
  }

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      branches = await repo.branches();
      if (branchId != null) {
        menu = await repo.menu(branchId!);
        cart.bindBranch(branchId!);
      }
    } on FbError catch (e) {
      error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setLocale(String l) {
    locale = l;
    _prefs?.setString('locale', l);
    notifyListeners();
  }

  Future<void> selectBranch(String id) async {
    branchId = id;
    _prefs?.setString('branchId', id);
    cart.bindBranch(id);
    await refresh();
  }

  void setService(ServiceType s) {
    service = s;
    _prefs?.setString('service', s.name);
    notifyListeners();
  }

  void completeOnboarding() {
    onboarded = true;
    _prefs?.setBool('onboarded', true);
    notifyListeners();
  }

  void markIntroSeen() {
    introSeen = true;
    _prefs?.setBool('introSeen', true);
  }

  void toggleFavorite(String productId) {
    favorites.contains(productId) ? favorites.remove(productId) : favorites.add(productId);
    _prefs?.setStringList('favorites', favorites.toList());
    notifyListeners();
  }

  void setReduceMotion(bool? v) {
    reduceMotionOverride = v;
    v == null ? _prefs?.remove('reduceMotion') : _prefs?.setString('reduceMotion', v ? 'on' : 'off');
    notifyListeners();
  }

  void allowNotifications() {
    notificationsAllowed = true;
    notifyListeners();
  }

  void signIn(String phone) {
    signedInPhone = phone;
    _prefs?.setString('phone', phone);
    notifyListeners();
  }

  void signOut() {
    signedInPhone = null;
    _prefs?.remove('phone');
    notifyListeners();
  }
}
