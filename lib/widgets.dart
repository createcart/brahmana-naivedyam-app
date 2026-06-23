import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'theme.dart';

/// Shimmer skeleton shown while the menu loads.
class MenuShimmer extends StatelessWidget {
  const MenuShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisExtent: 230,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFFF1E9DA),
        highlightColor: const Color(0xFFFBF6EC),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 12, color: Colors.white),
              const SizedBox(height: 8),
              Container(height: 12, width: 90, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact − [n] + stepper.
class QtyStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onInc;
  final VoidCallback onDec;
  const QtyStepper({
    super.key,
    required this.quantity,
    required this.onInc,
    required this.onDec,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Brand.saffron,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, onDec),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Padding(
              key: ValueKey(quantity),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('$quantity',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
          _btn(Icons.add, onInc),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) => InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      );
}

/// A cart icon with an animated count badge.
class CartBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const CartBadge({super.key, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.shopping_cart_outlined),
          color: Brand.ink,
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: AnimatedScale(
              scale: 1,
              duration: const Duration(milliseconds: 250),
              curve: Curves.elasticOut,
              child: Container(
                key: ValueKey(count),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: const BoxDecoration(
                  color: Brand.leaf,
                  shape: BoxShape.circle,
                ),
                child: Text('$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
      ],
    );
  }
}

/// Slim "Powered by CreateCart" strip shown on every page.
class PoweredByBar extends StatelessWidget {
  const PoweredByBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Brand.cream,
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 13, color: Brand.muted),
          SizedBox(width: 5),
          Text('Powered by ', style: TextStyle(color: Brand.muted, fontSize: 11.5)),
          Text('CreateCart',
              style: TextStyle(color: Brand.saffron, fontSize: 11.5, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// A friendly empty / error state.
class InfoState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  const InfoState({super.key, required this.icon, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Brand.marigold),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Brand.muted)),
            ],
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}
