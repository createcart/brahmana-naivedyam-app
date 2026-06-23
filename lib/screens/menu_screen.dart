import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../cart_model.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _query = '';
  bool _availableOnly = false;
  String? _category;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<CartModel>();

    if (model.menuLoading) return const MenuShimmer();
    if (model.menuError != null) {
      return InfoState(
        icon: Icons.wifi_off_rounded,
        title: "Couldn't load the menu",
        subtitle: model.menuError,
        action: FilledButton(onPressed: model.loadMenu, child: const Text('Retry')),
      );
    }

    final categories =
        model.menu.map((i) => i.category).whereType<String>().toSet().toList()..sort();

    var items = model.menu;
    if (_category != null) items = items.where((i) => i.category == _category).toList();
    if (_availableOnly) items = items.where((i) => i.sellable).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      items = items
          .where((i) =>
              i.name.toLowerCase().contains(q) ||
              (i.nameLocalized ?? '').toLowerCase().contains(q) ||
              i.description.toLowerCase().contains(q))
          .toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search the menu…',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: Brand.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: Brand.saffron)),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _filterChip('All', _category == null && !_availableOnly,
                  () => setState(() { _category = null; _availableOnly = false; })),
              const SizedBox(width: 8),
              _filterChip('Available now', _availableOnly,
                  () => setState(() => _availableOnly = !_availableOnly)),
              for (final c in categories) ...[
                const SizedBox(width: 8),
                _filterChip(c, _category == c,
                    () => setState(() => _category = _category == c ? null : c)),
              ],
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const InfoState(icon: Icons.search_off, title: 'No items match')
              : RefreshIndicator(
                  onRefresh: model.loadMenu,
                  color: Brand.saffron,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 260,
                      mainAxisExtent: 250,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemBuilder: (_, i) => _MenuCard(item: items[i])
                        .animate()
                        .fadeIn(duration: 300.ms, delay: (i * 40).ms)
                        .slideY(begin: 0.12),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, bool on, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: on ? Brand.ink : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? Brand.ink : Brand.border),
          ),
          child: Text(label,
              style: TextStyle(
                  color: on ? Colors.white : Brand.ink, fontWeight: FontWeight.w600)),
        ),
      );
}

class _MenuCard extends StatelessWidget {
  final MenuItem item;
  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<CartModel>();
    final qty = model.qtyOf(item.id);
    final out = !item.sellable;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.imageUrl != null)
                  CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Brand.warmWhite),
                    errorWidget: (_, __, ___) => _emoji(),
                  )
                else
                  _emoji(),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Brand.border)),
                    child: Text(rupees(item.price),
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Brand.saffron)),
                  ),
                ),
                if (out)
                  Container(
                    color: Colors.black26,
                    alignment: Alignment.center,
                    child: const Text('Sold out',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if (item.nameLocalized != null)
                  Text(item.nameLocalized!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Brand.saffron, fontSize: 12)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: out
                        ? const SizedBox.shrink()
                        : qty == 0
                            ? SizedBox(
                                key: const ValueKey('add'),
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () => model.add(item.id),
                                  style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 6)),
                                  child: const Text('Add  +'),
                                ),
                              )
                            : Align(
                                key: const ValueKey('qty'),
                                alignment: Alignment.centerRight,
                                child: QtyStepper(
                                  quantity: qty,
                                  onInc: () => model.increment(item.id),
                                  onDec: () => model.decrement(item.id),
                                ),
                              ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emoji() => Container(
        color: Brand.warmWhite,
        alignment: Alignment.center,
        child: Text(item.icon ?? '🍽️', style: const TextStyle(fontSize: 44)),
      );
}
