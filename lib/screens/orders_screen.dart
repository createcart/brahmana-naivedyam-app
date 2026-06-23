import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../cart_model.dart';
import '../theme.dart';
import '../widgets.dart';

const _flow = ['placed', 'confirmed', 'preparing', 'out_for_delivery', 'delivered'];
const _labels = {
  'placed': 'Placed',
  'confirmed': 'Confirmed',
  'preparing': 'Preparing',
  'out_for_delivery': 'On the way',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
};

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _ctrl = TextEditingController();
  Map<String, dynamic>? _order;
  bool _loading = false;
  String? _error;

  Future<void> _track() async {
    final id = _ctrl.text.trim();
    if (id.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _order = null;
    });
    try {
      final api = CreateCartApi(cartId: 'track'); // cart id unused for delivery read
      final data = await api.getDelivery(id);
      setState(() => _order = (data as Map).cast<String, dynamic>());
    } catch (e) {
      setState(() => _error = e is ApiException && e.status == 404
          ? "No order found with that id."
          : "Couldn't fetch that order.");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // touch the model so the tab rebuilds consistently
    context.watch<CartModel>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Track your order', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Text('Enter your order id to see live status.',
            style: TextStyle(color: Brand.muted)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                onSubmitted: (_) => _track(),
                decoration: InputDecoration(
                  hintText: 'Order id',
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Brand.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Brand.saffron)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(onPressed: _track, child: const Text('Track')),
          ],
        ),
        const SizedBox(height: 20),
        if (_loading) const Center(child: CircularProgressIndicator(color: Brand.saffron)),
        if (_error != null)
          InfoState(icon: Icons.error_outline, title: _error!),
        if (_order != null) _tracker(_order!),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Brand.leafLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.login, color: Brand.leaf),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sign in with Google to see all your past orders — coming in the next update.',
                  style: TextStyle(color: Brand.inkSoft, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tracker(Map<String, dynamic> o) {
    final status = (o['status'] ?? 'placed').toString();
    final cancelled = status == 'cancelled';
    final idx = _flow.indexOf(status);
    final timeline = (o['timeline'] is List) ? o['timeline'] as List : const [];
    final fullId = o['id'].toString();
    final shortId = fullId.length > 6 ? fullId.substring(fullId.length - 6) : fullId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #$shortId',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: cancelled ? const Color(0xFFF1F5F9) : Brand.leafLight,
                      borderRadius: BorderRadius.circular(999)),
                  child: Text(_labels[status] ?? status,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: cancelled ? Brand.muted : Brand.leaf)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (cancelled)
              const Text('This order was cancelled.',
                  style: TextStyle(color: Brand.tomato, fontWeight: FontWeight.w700))
            else
              Row(
                children: List.generate(_flow.length, (i) {
                  final done = i <= idx;
                  return Expanded(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: done ? Brand.leaf : const Color(0xFFE5E0D5),
                          child: Icon(done ? Icons.check : Icons.circle,
                              size: 12, color: Colors.white),
                        ).animate(target: done ? 1 : 0).scale(
                            begin: const Offset(0.7, 0.7), curve: Curves.elasticOut),
                        const SizedBox(height: 4),
                        Text(_labels[_flow[i]]!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 9.5,
                                color: done ? Brand.ink : Brand.muted,
                                fontWeight: done ? FontWeight.w700 : FontWeight.w500)),
                      ],
                    ),
                  );
                }),
              ),
            if (timeline.isNotEmpty) ...[
              const Divider(height: 22, color: Brand.border),
              for (final e in timeline.reversed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 96,
                        child: Text(_labels[(e['status'] ?? '').toString()] ?? '${e['status']}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                      Expanded(
                        child: Text('${e['at'] ?? ''}${e['note'] != null ? ' — ${e['note']}' : ''}',
                            style: const TextStyle(color: Brand.muted, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
