import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../auth_model.dart';
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
  List<Map<String, dynamic>> _orders = [];
  bool _loading = false;
  String? _error;
  String? _loadedFor; // id token we last loaded for

  Future<void> _loadHistory(String token) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<CartModel>().api;
      final list = await api.myOrders(token);
      list.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
      if (mounted) setState(() => _orders = list);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is ApiException && e.status == 401
            ? 'Your session expired — sign in again.'
            : "Couldn't load your orders.");
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthModel>();

    // Load (once) when signed in / token changes.
    if (auth.isSignedIn && auth.idToken != _loadedFor) {
      _loadedFor = auth.idToken;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory(auth.idToken!));
    }
    if (!auth.isSignedIn) _loadedFor = null;

    return RefreshIndicator(
      color: Brand.saffron,
      onRefresh: () async {
        if (auth.isSignedIn) await _loadHistory(auth.idToken!);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('My Orders', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (!auth.isSignedIn)
            _signInGate(auth)
          else if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: Brand.saffron)),
            )
          else if (_error != null)
            InfoState(icon: Icons.error_outline, title: _error!)
          else if (_orders.isEmpty)
            const InfoState(
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet',
                subtitle: 'Your paid orders will appear here.')
          else
            ..._orders.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OrderCard(o),
                )),
          const SizedBox(height: 8),
          const Divider(color: Brand.border),
          const SizedBox(height: 8),
          _trackByIdHint(),
        ],
      ),
    );
  }

  Widget _signInGate(AuthModel auth) => Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Icon(Icons.login, size: 48, color: Brand.marigold),
              const SizedBox(height: 12),
              Text('Sign in to see your orders',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              const Text('Use the Google account you order with.',
                  textAlign: TextAlign.center, style: TextStyle(color: Brand.muted)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: auth.busy
                    ? null
                    : () async {
                        final ok = await auth.signIn();
                        if (!ok && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sign-in cancelled or not configured')),
                          );
                        }
                      },
                icon: auth.busy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.account_circle),
                label: const Text('Sign in with Google'),
              ),
            ],
          ),
        ),
      );

  Widget _trackByIdHint() => const Text(
        'Tip: pull down to refresh. Orders are tied to your Google account.',
        style: TextStyle(color: Brand.muted, fontSize: 12),
      );
}

class _OrderCard extends StatefulWidget {
  final Map<String, dynamic> o;
  const _OrderCard(this.o);
  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.o;
    final status = (o['status'] ?? 'placed').toString();
    final cancelled = status == 'cancelled';
    final idx = _flow.indexOf(status);
    final fullId = (o['id'] ?? '').toString();
    final shortId = fullId.length > 6 ? fullId.substring(fullId.length - 6) : fullId;
    final items = (o['items'] is List) ? o['items'] as List : const [];
    final amount = o['amount'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #$shortId', style: const TextStyle(fontWeight: FontWeight.w800)),
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
            if (amount != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(rupees((amount is num) ? amount : double.tryParse('$amount') ?? 0),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            const SizedBox(height: 12),
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
                          radius: 12,
                          backgroundColor: done ? Brand.leaf : const Color(0xFFE5E0D5),
                          child: Icon(done ? Icons.check : Icons.circle, size: 11, color: Colors.white),
                        ).animate(target: done ? 1 : 0).scale(begin: const Offset(0.7, 0.7), curve: Curves.elasticOut),
                        const SizedBox(height: 4),
                        Text(_labels[_flow[i]]!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 9, color: done ? Brand.ink : Brand.muted,
                                fontWeight: done ? FontWeight.w700 : FontWeight.w500)),
                      ],
                    ),
                  );
                }),
              ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                onPressed: () => setState(() => _open = !_open),
                child: Text(_open ? 'Hide items' : 'View items (${items.length})',
                    style: const TextStyle(color: Brand.saffron)),
              ),
              if (_open)
                ...items.map((it) {
                  final m = (it as Map).cast<String, dynamic>();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('${m['quantity']}× ${m['name']}',
                        style: const TextStyle(color: Brand.muted, fontSize: 13)),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}
