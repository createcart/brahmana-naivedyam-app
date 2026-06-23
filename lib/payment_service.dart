import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentResult {
  final bool success;
  final bool cancelled;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? error;
  PaymentResult({
    this.success = false,
    this.cancelled = false,
    this.paymentId,
    this.orderId,
    this.signature,
    this.error,
  });
}

/// Wraps razorpay_flutter's callback API as a single awaitable open() call.
class RazorpayCheckout {
  final Razorpay _rzp = Razorpay();
  Completer<PaymentResult>? _c;

  RazorpayCheckout() {
    _rzp.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
      _finish(PaymentResult(
        success: true,
        paymentId: r.paymentId,
        orderId: r.orderId,
        signature: r.signature,
      ));
    });
    _rzp.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      if (r.code == Razorpay.PAYMENT_CANCELLED) {
        _finish(PaymentResult(cancelled: true));
      } else {
        _finish(PaymentResult(error: r.message ?? 'Payment failed'));
      }
    });
    _rzp.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) {});
  }

  void _finish(PaymentResult res) {
    if (_c != null && !_c!.isCompleted) _c!.complete(res);
  }

  Future<PaymentResult> open({
    required String key,
    required int amount,
    required String currency,
    required String orderId,
    required String name,
    Map<String, String>? prefill,
  }) {
    _c = Completer<PaymentResult>();
    _rzp.open({
      'key': key,
      'amount': amount,
      'currency': currency,
      'order_id': orderId,
      'name': name,
      if (prefill != null) 'prefill': prefill,
      'theme': {'color': '#F97316'},
    });
    return _c!.future;
  }

  void dispose() => _rzp.clear();
}
