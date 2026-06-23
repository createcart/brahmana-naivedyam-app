import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../auth_model.dart';
import '../cart_model.dart';
import '../config.dart';
import '../location_service.dart';
import '../payment_service.dart';
import '../theme.dart';

/// Collects delivery details, then runs checkout → Razorpay (or mock) → verify.
Future<void> runCheckout(BuildContext context) async {
  final cart = context.read<CartModel>();
  final auth = context.read<AuthModel>();
  if (cart.cart.items.isEmpty) return;

  final details = await showModalBottomSheet<_Details>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _DetailsSheet(
      total: cart.cart.totals.grandTotal,
      initialName: auth.name ?? '',
      initialEmail: auth.email ?? '',
    ),
  );
  if (details == null || !context.mounted) return;

  await _pay(context, cart, auth, details);
}

Future<void> _pay(BuildContext context, CartModel cart, AuthModel auth, _Details d) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator(color: Brand.saffron)),
  );

  final customer = {
    'name': d.name,
    'phone': d.phone,
    'address': d.address,
    if (d.email.isNotEmpty) 'email': d.email,
    if (d.lat != null) 'lat': d.lat,
    if (d.lng != null) 'lng': d.lng,
  };

  RazorpayCheckout? rzp;
  try {
    final order = await cart.api.checkout();
    Map<String, dynamic> result;

    if (order['provider'] == 'mock') {
      final mp = (order['mock_payment'] as Map).cast<String, dynamic>();
      result = await cart.api.verifyPayment(
        orderId: order['order_id'].toString(),
        paymentId: mp['payment_id'].toString(),
        signature: mp['signature'].toString(),
        customer: customer,
        idToken: auth.idToken,
      );
    } else {
      rzp = RazorpayCheckout();
      final pr = await rzp.open(
        key: order['key_id'].toString(),
        amount: (order['amount'] as num).toInt(),
        currency: (order['currency'] ?? 'INR').toString(),
        orderId: order['order_id'].toString(),
        name: (order['name'] ?? AppConfig.businessName).toString(),
        prefill: {'name': d.name, 'email': d.email, 'contact': d.phone},
      );
      if (!context.mounted) return;
      if (pr.cancelled) {
        Navigator.pop(context); // dismiss loader
        _toast(context, 'Payment cancelled');
        return;
      }
      if (!pr.success) {
        Navigator.pop(context);
        _toast(context, pr.error ?? 'Payment failed');
        return;
      }
      result = await cart.api.verifyPayment(
        orderId: pr.orderId!,
        paymentId: pr.paymentId!,
        signature: pr.signature!,
        customer: customer,
        idToken: auth.idToken,
      );
    }

    await cart.reloadCart();
    if (!context.mounted) return;
    Navigator.pop(context); // dismiss loader
    final oid = (result['delivery_order_id'] ?? result['order_id']).toString();
    await _success(context, oid);
  } on ApiException catch (e) {
    if (context.mounted) {
      Navigator.pop(context);
      _toast(context, e.detail);
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context);
      _toast(context, 'Something went wrong');
    }
  } finally {
    rzp?.dispose();
  }
}

void _toast(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

Future<void> _success(BuildContext context, String orderId) async {
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Brand.cream,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Brand.leaf, size: 64),
          const SizedBox(height: 12),
          Text('Payment successful!', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text('Order #${orderId.length > 6 ? orderId.substring(orderId.length - 6) : orderId}',
              style: const TextStyle(color: Brand.muted)),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}

class _Details {
  final String name, phone, address, email;
  final double? lat, lng;
  _Details(this.name, this.phone, this.address, this.email, {this.lat, this.lng});
}

class _DetailsSheet extends StatefulWidget {
  final double total;
  final String initialName, initialEmail;
  const _DetailsSheet({required this.total, required this.initialName, required this.initialEmail});
  @override
  State<_DetailsSheet> createState() => _DetailsSheetState();
}

class _DetailsSheetState extends State<_DetailsSheet> {
  late final _name = TextEditingController(text: widget.initialName);
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _search = TextEditingController();
  double? _lat, _lng;
  bool _locating = false, _searching = false;
  List<Place> _results = [];
  String? _err;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _useCurrent() async {
    setState(() { _locating = true; _err = null; });
    final p = await LocationService.current();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (p == null) { _err = "Couldn't get location — allow permission or search instead."; return; }
      _lat = p.lat; _lng = p.lng; _address.text = p.label; _results = [];
    });
  }

  Future<void> _runSearch() async {
    final q = _search.text.trim();
    if (q.isEmpty) return;
    setState(() { _searching = true; _err = null; });
    final res = await LocationService.search(q);
    if (!mounted) return;
    setState(() { _searching = false; _results = res; if (res.isEmpty) _err = 'No places found.'; });
  }

  void _pick(Place p) {
    setState(() { _lat = p.lat; _lng = p.lng; _address.text = p.label; _results = []; _search.clear(); });
  }

  void _submit() {
    if (_phone.text.trim().length < 10) {
      setState(() => _err = 'Enter a valid phone for order updates');
      return;
    }
    if (_address.text.trim().isEmpty && _lat == null) {
      setState(() => _err = 'Set your delivery location');
      return;
    }
    Navigator.pop(
      context,
      _Details(_name.text.trim(), _phone.text.trim(), _address.text.trim(), widget.initialEmail,
          lat: _lat, lng: _lng),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).viewInsets.bottom;
    InputDecoration dec(String h, {Widget? suffix}) => InputDecoration(
          hintText: h,
          filled: true,
          fillColor: Colors.white,
          suffixIcon: suffix,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Brand.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Brand.saffron)),
        );
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + pad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery details', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(controller: _name, decoration: dec('Your name')),
            const SizedBox(height: 10),
            TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: dec('Phone (for order updates)')),
            const SizedBox(height: 14),
            const Text('Delivery location', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _locating ? null : _useCurrent,
              icon: _locating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Brand.leaf))
                  : const Icon(Icons.my_location, color: Brand.leaf),
              label: const Text('Use my current location'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Brand.ink,
                  side: const BorderSide(color: Brand.border),
                  shape: const StadiumBorder(),
                  minimumSize: const Size(double.infinity, 46)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _runSearch(),
              decoration: dec('Search address / area / landmark',
                  suffix: IconButton(
                    icon: _searching
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search),
                    onPressed: _runSearch,
                  )),
            ),
            if (_results.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6),
                constraints: const BoxConstraints(maxHeight: 190),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Brand.border)),
                child: ListView(
                  shrinkWrap: true,
                  children: _results
                      .map((p) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined, color: Brand.saffron, size: 20),
                            title: Text(p.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                            onTap: () => _pick(p),
                          ))
                      .toList(),
                ),
              ),
            const SizedBox(height: 10),
            TextField(controller: _address, maxLines: 2, decoration: dec('Delivery address / landmark')),
            if (_lat != null)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Row(children: [
                  Icon(Icons.check_circle, color: Brand.leaf, size: 16),
                  SizedBox(width: 6),
                  Text('Location pinned', style: TextStyle(color: Brand.leaf, fontSize: 12.5, fontWeight: FontWeight.w600)),
                ]),
              ),
            if (_err != null) ...[
              const SizedBox(height: 8),
              Text(_err!, style: const TextStyle(color: Brand.tomato, fontSize: 12.5)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.lock_outline, size: 18),
                label: Text('Pay ${rupees(widget.total)}'),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Secure payment via Razorpay',
                  style: TextStyle(color: Brand.muted, fontSize: 11.5)),
            ),
          ],
        ),
      ),
    );
  }
}
