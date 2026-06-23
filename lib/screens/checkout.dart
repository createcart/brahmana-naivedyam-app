import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../auth_model.dart';
import '../cart_model.dart';
import '../config.dart';
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
  _Details(this.name, this.phone, this.address, this.email);
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
  String? _err;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _submit() {
    if (_phone.text.trim().length < 10) {
      setState(() => _err = 'Enter a valid phone for order updates');
      return;
    }
    if (_address.text.trim().isEmpty) {
      setState(() => _err = 'Enter a delivery address');
      return;
    }
    Navigator.pop(
      context,
      _Details(_name.text.trim(), _phone.text.trim(), _address.text.trim(), widget.initialEmail),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).viewInsets.bottom;
    InputDecoration dec(String h) => InputDecoration(
          hintText: h,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Brand.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Brand.saffron)),
        );
    return Padding(
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
          const SizedBox(height: 10),
          TextField(controller: _address, maxLines: 2, decoration: dec('Delivery address / landmark')),
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
    );
  }
}
