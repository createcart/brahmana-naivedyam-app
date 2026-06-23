import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onBrowse;
  const HomeScreen({super.key, required this.onBrowse});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _pager = PageController();
  Timer? _timer;
  int _page = 0;
  List<String> _slides = const [];

  @override
  void initState() {
    super.initState();
    _loadSlides();
  }

  Future<void> _loadSlides() async {
    // Bundled hero images (assets/slider/) — works offline, no website dependency.
    // To add a slide: drop the image in assets/slider/ and list it in manifest.json.
    const fallback = [
      '01-banner.png', '02-coming-soon.png', '04-menu.png', '05-upma.png',
    ];
    List<String> names = fallback;
    try {
      final raw = await rootBundle.loadString('assets/slider/manifest.json');
      final list = jsonDecode(raw);
      if (list is List && list.isNotEmpty) {
        names = list.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _slides = names.map((n) => 'assets/slider/$n').toList());
    _startAuto();
  }

  void _startAuto() {
    _timer?.cancel();
    if (_slides.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pager.hasClients) return;
      _page = (_page + 1) % _slides.length;
      _pager.animateToPage(_page,
          duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pager.dispose();
    super.dispose();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        // ── review pill ──
        Center(
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Brand.border),
              boxShadow: const [
                BoxShadow(color: Color(0x1AF97316), blurRadius: 18, offset: Offset(0, 6)),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('★★★★★', style: TextStyle(color: Brand.marigold, letterSpacing: 1)),
                SizedBox(width: 8),
                Text('Write a Review', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3),

        // ── hero slider ──
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: _slides.isEmpty
                    ? Container(color: Brand.warmWhite)
                    : PageView.builder(
                        controller: _pager,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemCount: _slides.length,
                        itemBuilder: (_, i) => Image.asset(
                          _slides[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              color: Brand.warmWhite,
                              child: const Icon(Icons.image_not_supported_outlined, color: Brand.muted)),
                        ),
                      ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Brand.marigold,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('📍 ${AppConfig.area}',
                    style: TextStyle(fontWeight: FontWeight.w800, color: Brand.ink, fontSize: 12)),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _page ? Colors.white : Colors.white70,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.97, 0.97)),

        const SizedBox(height: 22),
        Text('Order Online', textAlign: TextAlign.center, style: t.headlineMedium),
        const SizedBox(height: 4),
        Text(AppConfig.teluguName,
            textAlign: TextAlign.center,
            style: t.titleMedium?.copyWith(color: Brand.saffron)),
        const SizedBox(height: 6),
        const Text('100% Satvik · freshly made with devotion',
            textAlign: TextAlign.center, style: TextStyle(color: Brand.muted)),

        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: widget.onBrowse,
          icon: const Icon(Icons.restaurant_menu),
          label: const Text('Browse the Menu'),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
            duration: 1800.ms, color: Colors.white24, delay: 600.ms),

        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _launch('tel:${AppConfig.phone}'),
                icon: const Icon(Icons.call, color: Brand.leaf),
                label: const Text('Call'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Brand.ink,
                    side: const BorderSide(color: Brand.border),
                    shape: const StadiumBorder()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _launch(
                    'https://wa.me/${AppConfig.whatsapp}?text=Hi%21%20I%27d%20like%20to%20order.'),
                icon: const Icon(Icons.chat, color: Brand.leaf),
                label: const Text('WhatsApp'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Brand.ink,
                    side: const BorderSide(color: Brand.border),
                    shape: const StadiumBorder()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Text('${AppConfig.tagline}  🙏',
              style: const TextStyle(color: Brand.muted, fontSize: 12.5)),
        ),
      ],
    );
  }
}
