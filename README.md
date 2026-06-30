# Brahmana Naivedyam — Mobile App

The **Brahmana Naivedyam** (బ్రాహ్మణ నైవేద్యం) storefront as a native **Flutter**
app for Android. It's a thin client over the **same backend and database as the
website** — the shared [`createcart-api`](https://github.com/createcart/createcart-api)
on Supabase Postgres. Same menu, same orders, no new backend.

```
Flutter app ──HTTPS──► createcart-api ──► Supabase (Postgres)
 (this repo)           (shared service)     (same data as the website)
```

## Features
- **Home** — auto-scrolling hero (bundled, never cropped), brand, Call / WhatsApp, tappable logo → Home, "Write a Review" → Google.
- **Menu** — live items from the API, search + **category filters** + "Available now", **optimistic add / +/−** (instant), shimmer loading. **Always fresh** — no caching; auto-refreshes when you open Menu or resume the app, so admin stock/price changes appear right away.
- **Cart** — line items, live totals, quantity steppers; checkout or order on WhatsApp.
- **Checkout** — delivery details with a **location picker**: *Use my current location* (GPS) or **map search** (OpenStreetMap), pinned lat/lng sent with the order. **Razorpay** payment (test mode).
- **Sign in with Google** (native) — account menu in the app bar.
- **Orders** — your past orders + live status timeline (signed in).
- Material 3 brand theme, animations throughout, branded launcher icon + splash, "Powered by CreateCart" on every page.

## Project layout
```
lib/
├─ config.dart          # API base, tenant, contact, review URL (edit per env)
├─ theme.dart           # brand palette + Material 3 theme
├─ models.dart          # MenuItem / CartView / CartLine / CartTotals
├─ api.dart             # CreateCartApi — Dart twin of the web CreateCart.Store
├─ cart_model.dart      # menu + cart + optimistic ops (ChangeNotifier)
├─ auth_model.dart      # Google sign-in (serverClientId = web client id)
├─ payment_service.dart # Razorpay wrapper (callback API → Future)
├─ location_service.dart# GPS (geolocator) + Nominatim search / reverse-geocode
├─ widgets.dart         # shimmer, qty stepper, cart badge, Powered-by bar, states
├─ main.dart            # app + nav shell (app bar + bottom nav)
└─ screens/             # home / menu / cart / checkout / orders
assets/
├─ slider/              # hero images + manifest.json
├─ logo.jpg             # in-app brand logo
└─ logo_icon.png        # source for launcher icon + splash
```

## Run it
**Prerequisites:** Flutter **3.22+** (this was built on 3.44), Android Studio + Android SDK,
**JDK 17+**, and an emulator or USB device.

```bash
flutter pub get
flutter run                 # on a connected device / emulator
flutter build apk --release # → build/app/outputs/flutter-apk/app-release.apk
```

It defaults to the **production** API, so it works on a real device over Wi‑Fi/data
out of the box. For a local API, edit `AppConfig.apiBase` in `lib/config.dart`
(Android emulator → `http://10.0.2.2:8000`; real device → your PC's LAN IP).

## Configuration prerequisites
- **Google Sign-In** needs an **Android OAuth client** in Google Cloud for package
  `in.createcart.brahmana_naivedyam_app` with the signing **SHA-1** (debug SHA-1 for debug
  builds). The web client id is wired as `serverClientId` in `config.dart`.
- **Razorpay** keys live **server-side** on the API (`RAZORPAY_KEY_ID` /
  `RAZORPAY_KEY_SECRET`); the app only receives the public `key_id` from `/checkout`.
- **No secrets** are stored in the app — only public client-side values.

## Notes
- App **display name**: "Brahmana Naivedyam". Android **applicationId**:
  `in.createcart.brahmana_naivedyam_app` (kept stable so the OAuth client + installed identity don't change).
- Maps use keyless **OpenStreetMap (Nominatim)**; swap to Google Places by editing `location_service.dart`.

## Related repos
- **[createcart-api](https://github.com/createcart/createcart-api)** — the backend this app calls.
- **[createcart-sdks](https://github.com/createcart/createcart-sdks)** — the libraries powering it.
- **[brahmana-naivedyam](https://github.com/createcart/brahmana-naivedyam)** — the website (same backend).
