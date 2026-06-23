import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_model.dart';
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
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartModel()..init()),
        ChangeNotifierProvider(create: (_) => AuthModel()..restore()),
      ],
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
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _index = 0), // tap logo/brand -> Home
          child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Brand.marigold, width: 2),
              ),
              child: Image.asset('assets/logo.jpg', fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppConfig.businessName,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(AppConfig.teluguName,
                    style: TextStyle(color: Brand.saffron, fontSize: 11)),
              ],
            ),
          ],
          ),
        ),
        actions: [
          const _AccountAction(),
          CartBadge(
            count: count,
            onTap: () async {
              final r = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
              if (r == 'menu' && mounted) setState(() => _index = 1);
            },
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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PoweredByBar(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu), label: 'Menu'),
              NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountAction extends StatelessWidget {
  const _AccountAction();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthModel>();
    if (!auth.isSignedIn) {
      return IconButton(
        tooltip: 'Sign in',
        icon: const Icon(Icons.account_circle_outlined, color: Brand.ink),
        onPressed: auth.busy ? null : () => auth.signIn(),
      );
    }
    final photo = auth.photoUrl;
    return PopupMenuButton<String>(
      tooltip: auth.name ?? 'Account',
      onSelected: (v) {
        if (v == 'out') auth.signOut();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(auth.name ?? 'Signed in', style: const TextStyle(fontWeight: FontWeight.w700)),
              if (auth.email != null)
                Text(auth.email!, style: const TextStyle(color: Brand.muted, fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'out', child: Text('Sign out')),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: Brand.leafLight,
          backgroundImage: (photo != null && photo.isNotEmpty) ? NetworkImage(photo) : null,
          child: (photo == null || photo.isEmpty)
              ? Text(
                  (auth.name != null && auth.name!.trim().isNotEmpty)
                      ? auth.name!.trim()[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Brand.leaf, fontWeight: FontWeight.w800))
              : null,
        ),
      ),
    );
  }
}
