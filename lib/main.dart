import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'cart_model.dart';
import 'config.dart';
import 'screens/cart_screen.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/orders_screen.dart';
import 'theme.dart';
import 'widgets.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CartModel()..init(),
      child: const BrahmanaApp(),
    ),
  );
}

class BrahmanaApp extends StatelessWidget {
  const BrahmanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.businessName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartModel>().count;
    final pages = [
      HomeScreen(onBrowse: () => setState(() => _index = 1)),
      const MenuScreen(),
      const OrdersScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Brand.saffron, Brand.marigold]),
                border: Border.all(color: Brand.marigold, width: 2),
              ),
              alignment: Alignment.center,
              child: const Text('🙏', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(AppConfig.businessName,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(AppConfig.teluguName,
                    style: const TextStyle(color: Brand.saffron, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          CartBadge(
            count: count,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu), label: 'Menu'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
        ],
      ),
    );
  }
}
