import 'dart:convert';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'models.dart';

class ApiException implements Exception {
  final int status;
  final String detail;
  ApiException(this.status, this.detail);
  @override
  String toString() => detail;
}

/// REST client for createcart-api — the Dart twin of the web `CreateCart.Store`.
/// Reads are public; cart ops act on a per-device cart id.
class CreateCartApi {
  final String base;
  final String tenant;
  final String cartId;

  CreateCartApi({
    required this.cartId,
    this.base = AppConfig.apiBase,
    this.tenant = AppConfig.tenant,
  });

  Uri _u(String path) => Uri.parse('$base/api/$tenant$path');
  Uri _c(String path) => Uri.parse('$base/api/$tenant/carts/$cartId$path');

  Future<dynamic> _get(Uri u) async =>
      _handle(await http.get(u, headers: {'Accept': 'application/json'}));

  Future<dynamic> _post(Uri u, [Map<String, dynamic>? body]) async => _handle(
        await http.post(u,
            headers: {'Content-Type': 'application/json'},
            body: body == null ? null : jsonEncode(body)),
      );

  Future<dynamic> _getAuthed(Uri u, String token) async =>
      _handle(await http.get(u, headers: {'Accept': 'application/json', 'X-Auth-Token': token}));

  dynamic _handle(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return r.body.isEmpty ? null : jsonDecode(r.body);
    }
    String detail = r.reasonPhrase ?? 'Request failed';
    try {
      final j = jsonDecode(r.body);
      if (j is Map && j['detail'] != null) detail = j['detail'].toString();
    } catch (_) {}
    throw ApiException(r.statusCode, detail);
  }

  // ── menu (public) ──────────────────────────────────────────────
  Future<List<MenuItem>> listItems() async {
    final data = await _get(_u('/items')) as List;
    return data.map((e) => MenuItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── cart ───────────────────────────────────────────────────────
  // Mutations only POST; callers reconcile with a single getCart() afterwards,
  // so a +/- is one mutation + one read (not three round-trips).
  Future<CartView> getCart() async => CartView.fromJson(await _get(_c('')));

  Future<void> addToCart(String itemId, [int qty = 1]) =>
      _post(_c('/items'), {'item_id': itemId, 'quantity': qty});

  Future<void> increment(String itemId) =>
      _post(_c('/items/$itemId/increment'), {'by': 1});

  Future<void> decrement(String itemId) =>
      _post(_c('/items/$itemId/decrement'), {'by': 1});

  Future<void> clearCart() => _post(_c('/clear'));

  // ── checkout / payment (Phase 2) ───────────────────────────────
  /// Price the cart server-side and create a payment order.
  /// Returns {provider, key_id, order_id, amount(paise), currency, name, ...}.
  Future<Map<String, dynamic>> checkout() async =>
      (await _post(_c('/checkout')) as Map).cast<String, dynamic>();

  /// Verify a completed payment; links to the account when [idToken] is given.
  /// Returns {status:'paid', delivery_order_id, amount, ...}.
  Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    Map<String, dynamic>? customer,
    String? idToken,
  }) async =>
      (await _post(_u('/payments/verify'), {
        'order_id': orderId,
        'payment_id': paymentId,
        'signature': signature,
        if (customer != null) 'customer': customer,
        if (idToken != null) 'id_token': idToken,
      }) as Map)
          .cast<String, dynamic>();

  // ── customer auth + history (Phase 2) ──────────────────────────
  Future<Map<String, dynamic>> googleLogin(String idToken) async =>
      (await _post(Uri.parse('$base/api/auth/google'), {'id_token': idToken}) as Map)
          .cast<String, dynamic>();

  Future<List<Map<String, dynamic>>> myOrders(String idToken) async {
    final data = await _getAuthed(_u('/my-orders'), idToken);
    return (data as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  // ── delivery tracking (used by Orders once an order exists) ─────
  Future<Map<String, dynamic>> getDelivery(String orderId) async =>
      (await _get(_u('/deliveries/$orderId')) as Map).cast<String, dynamic>();
}
