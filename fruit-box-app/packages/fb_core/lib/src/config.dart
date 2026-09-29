/// Build-time configuration. Every value can be overridden with
/// `--dart-define=KEY=value`. Domain and e-mail are TARGET values only: the
/// app never sends e-mail or links production to them unless explicitly
/// enabled after the owner confirms ownership.
class FbConfig {
  const FbConfig({
    required this.targetDomain,
    required this.supportEmail,
    required this.emailSendingEnabled,
    required this.domainConfirmed,
    required this.paymentsMode,
    required this.backend,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  factory FbConfig.fromEnvironment() => const FbConfig(
        targetDomain: String.fromEnvironment('FB_APP_DOMAIN', defaultValue: 'fruitbox.com'),
        supportEmail: String.fromEnvironment('FB_SUPPORT_EMAIL', defaultValue: 'info@fruitbox.com'),
        emailSendingEnabled: bool.fromEnvironment('FB_EMAIL_SENDING_ENABLED'),
        domainConfirmed: bool.fromEnvironment('FB_DOMAIN_CONFIRMED'),
        paymentsMode: String.fromEnvironment('FB_PAYMENTS_MODE', defaultValue: 'disabled'),
        backend: String.fromEnvironment('FB_BACKEND', defaultValue: 'demo'),
        supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
        supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      );

  /// Domains that must never be used in brand or product links.
  static const blockedDomains = {'futitbox.com'};

  final String targetDomain;
  final String supportEmail;
  final bool emailSendingEnabled;
  final bool domainConfirmed;
  final String paymentsMode; // disabled | sandbox | live
  final String backend; // demo | supabase
  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get isDemo => backend == 'demo';
  bool get paymentsEnabled => paymentsMode == 'sandbox' || paymentsMode == 'live';

  /// Public links are only absolute once the domain is confirmed; before that
  /// the app uses relative paths / the current host.
  String publicUrl(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    return domainConfirmed ? 'https://$targetDomain$p' : p;
  }

  /// Throws if a blocked domain is configured anywhere.
  void validate() {
    for (final d in blockedDomains) {
      if (targetDomain.contains(d) || supportEmail.contains(d) || supabaseUrl.contains(d)) {
        throw StateError('Blocked domain "$d" must not be used in configuration.');
      }
    }
    if (emailSendingEnabled && !domainConfirmed) {
      throw StateError('E-mail sending requires FB_DOMAIN_CONFIRMED=true.');
    }
    if (backend == 'supabase' && (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty)) {
      throw StateError('FB_BACKEND=supabase requires SUPABASE_URL and SUPABASE_ANON_KEY.');
    }
  }
}
