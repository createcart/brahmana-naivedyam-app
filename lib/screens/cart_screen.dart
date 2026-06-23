import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../cart_model.dart';
import '../config.dart';
import '../theme.dart';
import '../widgets.dart';
import 'checkout.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<CartModel>();
    final cart = model.cart;
    final t = cart.totals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () => model.clear(),
              child: const Text('Clear', style: TextStyle(color: Brand.tomato)),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? InfoState(
              icon: Icons.shopping_basket_outlined,
              title: 'Your cart is empty',
              subtitle: 'Add something tasty 🍛',
              action: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Browse the menu'),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 18, color: Brand.border),
                    itemBuilder: (_, i) {
                      final l = cart.items[i];
                      return Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: Brand.warmWhite,
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(l.icon ?? '🍽️', style: const TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text('${rupees(l.unitPrice)} × ${l.quantity} = ${rupees(l.lineTotal)}',
                                    style: const TextStyle(color: Brand.muted, fontSize: 12.5)),
                              ],
                            ),
                          ),
                          QtyStepper(
                            quantity: l.quantity,
                            onInc: () => model.increment(l.itemId),
                            onDec: () => model.decrement(l.itemId),
                          ),
                        ],
                      ).animate().fadeIn(duration: 250.ms);
                    },
                  ),
                ),
                _summary(context, model, t),
              ],
            ),
    );
  }

  Widget _summary(BuildContext context, CartModel model, t) {
    Widget row(String a, String b, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(a,
                  style: TextStyle(
                      color: strong ? Brand.ink : Brand.muted,
                      fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
                      fontSize: strong ? 18 : 14)),
              Text(b,
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: strong ? 18 : 14)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row('Subtotal', rupees(t.subtotal)),
          if (t.discountTotal > 0) row('Discount', '−${rupees(t.discountTotal)}'),
          if (t.taxTotal > 0) row('Tax', rupees(t.taxTotal)),
          if (t.chargesTotal > 0) row('Charges', rupees(t.chargesTotal)),
          const Divider(height: 18, color: Brand.border),
          row('Total', rupees(t.grandTotal), strong: true),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => runCheckout(context),
              icon: const Icon(Icons.lock_outline, size: 18),
              label: const Text('Proceed to checkout'),
            ),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => _whatsappOrder(context, model),
            icon: const Icon(Icons.chat, size: 16, color: Brand.leaf),
            label: const Text('or order on WhatsApp', style: TextStyle(color: Brand.leaf)),
          ),
          const Text('Secure payment via Razorpay',
              style: TextStyle(color: Brand.muted, fontSize: 11.5)),
        ],
      ),
    );
  }

  // Alternative to in-app payment: send the cart on WhatsApp.
  void _whatsappOrder(BuildContext context, CartModel model) {
    final lines = model.cart.items
        .map((l) => '• ${l.quantity}× ${l.name} (${rupees(l.lineTotal)})')
        .join('\n');
    final msg = Uri.encodeComponent(
        'Hi! I\'d like to order from ${AppConfig.businessName}:\n$lines\n\nTotal: ${rupees(model.cart.totals.grandTotal)}');
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_rounded, size: 44, color: Brand.leaf),
            const SizedBox(height: 12),
            Text('Order on WhatsApp',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text(
              'Prefer chat? Send your cart on WhatsApp and we\'ll confirm and deliver to your location.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Brand.muted),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Brand.leaf),
                onPressed: () async {
                  final uri = Uri.parse('https://wa.me/${AppConfig.whatsapp}?text=$msg');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.chat),
                label: const Text('Order on WhatsApp'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
