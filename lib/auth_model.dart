import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

/// Native Google sign-in. The returned ID token (audience = our web client id)
/// is sent to the API as `X-Auth-Token` for the customer's own data, and as
/// `id_token` at payment verification to link the order to the account.
class AuthModel extends ChangeNotifier {
  final GoogleSignIn _google = GoogleSignIn(
    serverClientId: AppConfig.googleServerClientId,
    scopes: const ['email', 'profile'],
  );

  String? idToken;
  String? name;
  String? email;
  String? photoUrl;
  bool busy = false;

  bool get isSignedIn => idToken != null;

  static const _kTok = 'cc_idtoken';
  static const _kName = 'cc_name';
  static const _kEmail = 'cc_email';
  static const _kPhoto = 'cc_photo';

  Future<void> restore() async {
    final p = await SharedPreferences.getInstance();
    idToken = p.getString(_kTok);
    name = p.getString(_kName);
    email = p.getString(_kEmail);
    photoUrl = p.getString(_kPhoto);
    // Try a silent sign-in to refresh the (1h) ID token in the background.
    if (idToken != null) {
      _google.signInSilently().then((acc) {
        if (acc != null) _apply(acc);
      });
    }
    notifyListeners();
  }

  Future<bool> signIn() async {
    busy = true;
    notifyListeners();
    try {
      final acc = await _google.signIn(); // opens the account chooser
      if (acc == null) return false; // user cancelled
      await _apply(acc);
      return idToken != null;
    } catch (_) {
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _apply(GoogleSignInAccount acc) async {
    final auth = await acc.authentication;
    idToken = auth.idToken;
    name = acc.displayName;
    email = acc.email;
    photoUrl = acc.photoUrl;
    final p = await SharedPreferences.getInstance();
    if (idToken != null) await p.setString(_kTok, idToken!);
    await p.setString(_kName, name ?? '');
    await p.setString(_kEmail, email ?? '');
    await p.setString(_kPhoto, photoUrl ?? '');
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {}
    idToken = null;
    name = null;
    email = null;
    photoUrl = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_kTok);
    await p.remove(_kName);
    await p.remove(_kEmail);
    await p.remove(_kPhoto);
    notifyListeners();
  }
}
