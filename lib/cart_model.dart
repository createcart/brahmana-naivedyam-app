import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'config.dart';
import 'models.dart';

/// Holds the menu + cart and exposes optimistic add/inc/dec so the UI feels
/// instant; the API call runs in the background and reconciles afterwards.
class CartModel extends ChangeNotifier {
  late CreateCartApi _api;

  List<MenuItem> menu = [];
  CartView cart = CartView.empty();
  bool menuLoading = true;
  String? menuError;

  int _pending = 0;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'cc_cart_${AppConfig.tenant}';
    var id = prefs.getString(key);
    if (id == null || id.isEmpty) {
      id = 'c-${Random().nextInt(0x7fffffff).toRadixString(36)}${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
      await prefs.setString(key, id);
    }
    _api = CreateCartApi(cartId: id);
    await loadMenu();
  }

  Future<void> loadMenu() async {
    menuLoading = true;
    menuError = null;
    notifyListeners();
    try {
      final results = await Future.wait([_api.listItems(), _api.getCart()]);
      menu = results[0] as List<MenuItem>;
      cart = results[1] as CartView;
      menuError = null;
    } catch (e) {
      menuError = e.toString();
    } finally {
      menuLoading = false;
      notifyListeners();
    }
  }

  int qtyOf(String itemId) {
    for (final l in cart.items) {
      if (l.itemId == itemId) return l.quantity;
    }
    return 0;
  }

  int get count => cart.totals.totalQuantity;

  /// Optimistically change quantity, then sync with the server.
  Future<void> _op(String itemId, int delta, Future<void> Function() call) async {
    _applyOptimistic(itemId, delta);
    _pending++;
    try {
      await call();
    } catch (_) {
      // ignore — the reconcile below restores truth
    } finally {
      _pending--;
      if (_pending == 0) {
        try {
          cart = await _api.getCart();
        } catch (_) {}
        notifyListeners();
      }
    }
  }

  void _applyOptimistic(String itemId, int delta) {
    final items = List<CartLine>.from(cart.items);
    final idx = items.indexWhere((l) => l.itemId == itemId);
    if (idx >= 0) {
      final q = items[idx].quantity + delta;
      if (q <= 0) {
        items.removeAt(idx);
      } else {
        items[idx] = items[idx].copyWith(quantity: q);
      }
    } else if (delta > 0) {
      final m = menu.firstWhere((e) => e.id == itemId,
          orElse: () => MenuItem(id: itemId, name: ''));
      items.add(CartLine(
        itemId: itemId,
        name: m.name,
        unitPrice: m.price,
        quantity: delta,
        lineTotal: m.price * delta,
        icon: m.icon,
      ));
    }
    final qty = items.fold<int>(0, (s, l) => s + l.quantity);
    final subtotal = items.fold<double>(0, (s, l) => s + l.lineTotal);
    cart = CartView(
      items: items,
      totals: CartTotals(
        subtotal: subtotal,
        grandTotal: subtotal + cart.totals.chargesTotal + cart.totals.taxTotal - cart.totals.discountTotal,
        chargesTotal: cart.totals.chargesTotal,
        taxTotal: cart.totals.taxTotal,
        discountTotal: cart.totals.discountTotal,
        totalQuantity: qty,
      ),
    );
    notifyListeners();
  }

  Future<void> add(String itemId) => _op(itemId, 1, () => _api.addToCart(itemId, 1));
  Future<void> increment(String itemId) => _op(itemId, 1, () => _api.increment(itemId));
  Future<void> decrement(String itemId) => _op(itemId, -1, () => _api.decrement(itemId));

  Future<void> clear() async {
    cart = CartView.empty();
    notifyListeners();
    try {
      await _api.clearCart();
      cart = await _api.getCart();
    } catch (_) {}
    notifyListeners();
  }
}
