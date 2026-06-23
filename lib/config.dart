/// App-wide configuration.
///
/// The app is a thin client over the SAME `createcart-api` the website uses —
/// same multi-tenant API, same Supabase database. No new backend.
class AppConfig {
  /// CreateCart API base.
  ///   • production (default): the deployed Vercel API.
  ///   • local dev: Android emulator -> 'http://10.0.2.2:8000';
  ///               real device -> 'http://<your-PC-LAN-IP>:8000'.
  static const String apiBase = 'https://createcart-api.vercel.app';

  /// The storefront site (reused for hero slider images via its manifest).
  static const String siteBase = 'https://create-cart.vercel.app';

  /// This tenant.
  static const String tenant = 'brahmana-naivedyam';
  static const String businessName = 'Brahmana Naivedyam';
  static const String teluguName = 'బ్రాహ్మణ నైవేద్యం';
  static const String tagline = 'Pure · Fresh · Devotional · Agraharam';
  static const String area = 'Gachibowli, HYD';

  /// Contact.
  static const String phone = '+917675856767';
  static const String whatsapp = '917675856767';
}
