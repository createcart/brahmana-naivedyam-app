# Brahmana Naivedyam — Flutter app

The **Brahmana Naivedyam** storefront as a native mobile app (Flutter), using the
**same architecture and database** as the website: a thin client over the shared
[`createcart-api`](https://github.com/createcart/createcart-api), which talks to
the same Supabase Postgres. No new backend — same menu, same data.

```
Flutter app ──HTTP──► createcart-api ──► Supabase (Postgres)
 (this repo)          (shared service)     (same data as the website)
```

## What's in v1 (core)
- **Home** — auto-scrolling hero slider (reuses the website's slider images via its
  `manifest.json`), brand, Call / WhatsApp contact.
- **Menu** — live items from the API, search + "Available now" filter, **optimistic
  add / +/−** (instant UI, reconciles in the background), loading **shimmer**.
- **Cart** — line items, live totals, quantity steppers; checkout bridges to
  **WhatsApp ordering** for now (mirrors the website's "launching soon" flow).
- **Orders** — track any order by id via the delivery API (live status + timeline).
- Material 3 theme in the brand palette, animations throughout (`flutter_animate`).

## Phase 2 (next pass)
- Google sign-in (native), **MSG91 OTP**, **Razorpay** payment, signed-in
  **order history** (`/my-orders`). The API + data already support these.

## Project layout
```
lib/
├─ config.dart        # API base, tenant, contact (the only thing to edit per env)
├─ theme.dart         # brand palette + Material 3 theme
├─ models.dart        # MenuItem, CartView, CartLine, CartTotals (API JSON)
├─ api.dart           # CreateCartApi — Dart twin of the web CreateCart.Store
├─ cart_model.dart    # ChangeNotifier: menu + cart + optimistic ops
├─ widgets.dart       # shimmer, qty stepper, animated cart badge, states
├─ main.dart          # app + nav shell (app bar + bottom nav)
└─ screens/           # home / menu / cart / orders
```

## Run it
**Prerequisites:** [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.3+),
Android Studio + Android SDK, and an emulator or a USB device.

```bash
cd D:\createcart\brahmana-app

# 1. generate the native platform folders (this repo ships only lib/ + pubspec;
#    flutter create preserves your lib/ and pubspec.yaml, it just adds android/ ios/)
flutter create --platforms=android,ios --org in.createcart .

# 2. dependencies
flutter pub get

# 3. run on a connected device / emulator
flutter run
```

To build an installable APK: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`.

### Android internet permission
After `flutter create`, ensure `android/app/src/main/AndroidManifest.xml` has, above
`<application>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
(Flutter adds this for debug automatically; add it so **release** builds can reach the API.)

## Pointing at a different API
Edit `lib/config.dart`:
- **Production (default):** `apiBase = 'https://createcart-api.vercel.app'` — works on a real device out of the box.
- **Local API:** Android **emulator** → `http://10.0.2.2:8000`; real device on your Wi-Fi → `http://<your-PC-LAN-IP>:8000` (and run the API with CORS allowing all / your origin).

## Notes
- Built and verified by code review; compile/run requires the Flutter toolchain
  (not available in the authoring environment) — use the steps above in Android Studio / CLI.
- Adding a slider image? It's driven by the **website's** `img/slider/manifest.json`,
  so updating the site updates the app's hero automatically.
