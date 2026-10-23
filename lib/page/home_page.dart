// lib/page/home_page.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apkbarberon/services/api_config.dart';
import 'package:apkbarberon/page/profile_page.dart';
import 'package:apkbarberon/page/search_page.dart';
import 'package:apkbarberon/page/chat_list_page.dart';
import 'package:apkbarberon/page/notification_page.dart';
import 'package:apkbarberon/page/history_page.dart';
import 'package:apkbarberon/page/help_page.dart';
import 'package:apkbarberon/page/barber_detail_page.dart';

class HomePage extends StatefulWidget {
  final Function(ThemeMode) updateThemeMode;
  const HomePage({Key? key, required this.updateThemeMode}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _telepon;
  int _navIndex = 0;
  int _catIndex = 0;
  int _promoIndex = 0;

  Position? _pos;
  List<Map<String, dynamic>> _barbers = [];
  bool _loading = false;

  late PageController _promoC;
  Timer? _promoTimer;

  final List<String> _promoImages = [
    'assets/images/promo1.webp',
    'assets/images/promo2.webp',
    'assets/images/promo3.png',
  ];

  final List<Map<String, dynamic>> _cats = [
    {'label': 'Semua', 'icon': Icons.grid_view_rounded, 'key': ''},
    {'label': 'Potong', 'icon': Icons.content_cut, 'key': 'potong'},
    {'label': 'Cat', 'icon': Icons.color_lens_outlined, 'key': 'cat'},
    {'label': 'Perawatan', 'icon': Icons.spa_outlined, 'key': 'perawatan'},
  ];

  @override
  void initState() {
    super.initState();
    _promoC = PageController(viewportFraction: 0.9);
    _init();
    _startPromo();
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoC.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _telepon = prefs.getString('telepon');
    await _getLocation();
    await _loadBarbers();
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;
      _pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (_) {}
  }

  void _startPromo() {
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_promoC.hasClients && _promoImages.isNotEmpty) {
        final next = (_promoIndex + 1) % _promoImages.length;
        _promoC.animateToPage(next,
            duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
    });
  }

  Future<void> _loadBarbers() async {
    setState(() => _loading = true);
    try {
      final res = await http.post(Uri.parse(Api.search), body: {
        'keyword': '',
        'category': (_cats[_catIndex]['key'] ?? '').toString(),
      }).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        List list = [];
        if (body is Map && body['data'] != null) {
          list = body['data'];
        } else if (body is List) {
          list = body;
        }
        _barbers = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- helpers ----------
  String _img(String logo) =>
      logo.isEmpty ? '' : '$kServer/clip_perfect/$logo';

  double _distVal(Map b) {
    if (_pos == null) return double.infinity;
    final lat = double.tryParse('${b['latitude'] ?? ''}');
    final lng = double.tryParse('${b['longitude'] ?? ''}');
    if (lat == null || lng == null) return double.infinity;
    return _haversine(_pos!.latitude, _pos!.longitude, lat, lng);
  }

  String _distLabel(Map b) {
    final d = _distVal(b);
    return d == double.infinity ? '' : '${d.toStringAsFixed(1)} km';
  }

  double _haversine(double a1, double o1, double a2, double o2) {
    const p = 0.017453292519943295;
    final x = 0.5 -
        cos((a2 - a1) * p) / 2 +
        cos(a1 * p) * cos(a2 * p) * (1 - cos((o2 - o1) * p)) / 2;
    return 12742 * asin(sqrt(x));
  }

  String _rupiah(dynamic v) {
    final n = (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
    final s = n.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return 'Rp $b';
  }

  List<Map<String, dynamic>> get _byRating {
    final l = List<Map<String, dynamic>>.from(_barbers);
    l.sort((a, b) => (double.tryParse('${b['rating'] ?? 0}') ?? 0)
        .compareTo(double.tryParse('${a['rating'] ?? 0}') ?? 0));
    return l;
  }

  List<Map<String, dynamic>> get _byDistance {
    final l = List<Map<String, dynamic>>.from(_barbers);
    l.sort((a, b) => _distVal(a).compareTo(_distVal(b)));
    return l;
  }

  // ---------- navigation ----------
  void _openSearch() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => SearchPage()));
  void _openOrders() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const NotifikasiPage()));
  void _openDetail(Map<String, dynamic> b) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BarberDetailPage(
              barberId: b['id'],
              barberName: b['barber_name'] ?? 'Tukang Pangkas'),
        ),
      );

  void _openProfile() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfilePage(
              telepon: _telepon ?? '',
              updateThemeMode: widget.updateThemeMode),
        ),
      );

  void _navBottom(int i) {
    setState(() => _navIndex = i);
    switch (i) {
      case 0:
        break;
      case 1:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => ChatListPage(telepon: _telepon)))
            .then((_) => setState(() => _navIndex = 0));
        break;
      case 2:
        Navigator.push(
                context, MaterialPageRoute(builder: (_) => HistoryPage()))
            .then((_) => setState(() => _navIndex = 0));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => HelpPage()))
            .then((_) => setState(() => _navIndex = 0));
        break;
    }
  }

  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 12,
        title: Row(
          children: [
            Image.asset('assets/logo/logohome.png',
                height: 34,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.content_cut, color: theme.primaryColor)),
            const SizedBox(width: 10),
            Expanded(child: _searchBox(theme)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Mode terang' : 'Mode gelap',
            onPressed: () => widget.updateThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark),
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          ),
          IconButton(
            tooltip: 'Pesanan Saya',
            onPressed: _openOrders,
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          GestureDetector(
            onTap: _openProfile,
            child: Padding(
              padding: const EdgeInsets.only(right: 12, left: 4),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: theme.primaryColor.withOpacity(0.15),
                child: Icon(Icons.person, color: theme.primaryColor, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBarbers,
        color: theme.primaryColor,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          children: [
            _greeting(theme),
            const SizedBox(height: 14),
            _categoryRow(theme),
            const SizedBox(height: 18),
            _promo(theme),
            const SizedBox(height: 20),
            _sectionHeader('Rekomendasi untukmu', theme,
                onRefresh: _loadBarbers),
            const SizedBox(height: 10),
            _recommendation(theme),
            const SizedBox(height: 22),
            _sectionHeader('Dekat Anda', theme),
            const SizedBox(height: 10),
            _nearby(theme),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(theme),
      floatingActionButton: FloatingActionButton(
        onPressed: _openOrders,
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.list_alt, color: Colors.black87),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _searchBox(ThemeData theme) {
    return InkWell(
      onTap: _openSearch,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: theme.hintColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Cari pangkas, layanan...',
                  style: GoogleFonts.poppins(
                      color: theme.hintColor, fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.tune, color: Colors.black87, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _greeting(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Halo, selamat datang! 👋',
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text('Cari tukang pangkas online di sekitarmu',
            style:
                GoogleFonts.poppins(fontSize: 13, color: theme.hintColor)),
      ],
    );
  }

  Widget _categoryRow(ThemeData theme) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final c = _cats[i];
          final selected = i == _catIndex;
          return GestureDetector(
            onTap: () {
              setState(() => _catIndex = i);
              _loadBarbers();
            },
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: selected ? theme.primaryColor : theme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: selected
                            ? theme.primaryColor
                            : theme.dividerColor.withOpacity(0.4)),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                                color: theme.primaryColor.withOpacity(0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 6))
                          ]
                        : [],
                  ),
                  child: Icon(c['icon'],
                      color: selected ? Colors.black87 : theme.hintColor,
                      size: 26),
                ),
                const SizedBox(height: 6),
                Text(c['label'],
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _promo(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _promoC,
            itemCount: _promoImages.length,
            onPageChanged: (i) => setState(() => _promoIndex = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  _promoImages[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        theme.primaryColor.withOpacity(0.8),
                        theme.primaryColor.withOpacity(0.4),
                      ]),
                    ),
                    alignment: Alignment.center,
                    child: Text('Promo ${i + 1}',
                        style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _promoImages.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _promoIndex == i ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: _promoIndex == i
                    ? theme.primaryColor
                    : theme.dividerColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, ThemeData theme,
      {VoidCallback? onRefresh}) {
    return Row(
      children: [
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600)),
        const Spacer(),
        if (onRefresh != null)
          InkWell(
            onTap: onRefresh,
            child: Icon(Icons.refresh_rounded,
                size: 20, color: theme.hintColor),
          ),
      ],
    );
  }

  Widget _recommendation(ThemeData theme) {
    if (_loading) {
      return SizedBox(
        height: 196,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => Container(
            width: 160,
            decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }
    final list = _byRating;
    if (list.isEmpty) return _emptyState(theme);
    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _recoCard(list[i], theme),
      ),
    );
  }

  Widget _recoCard(Map<String, dynamic> b, ThemeData theme) {
    final logo = _img((b['logo'] ?? '').toString());
    final dist = _distLabel(b);
    return GestureDetector(
      onTap: () => _openDetail(b),
      child: Container(
        width: 162,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: logo.isNotEmpty
                    ? Image.network(logo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgPlaceholder(theme))
                    : _imgPlaceholder(theme),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Text(b['barber_name'] ?? '-',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
              child: Row(children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 3),
                Text('${b['rating'] ?? 0}',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: theme.hintColor)),
                if (dist.isNotEmpty) ...[
                  Text('  •  ',
                      style: TextStyle(color: theme.hintColor, fontSize: 12)),
                  Icon(Icons.near_me, size: 12, color: theme.primaryColor),
                  const SizedBox(width: 2),
                  Text(dist,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: theme.hintColor)),
                ],
              ]),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: Text('Mulai ${_rupiah(b['price'] ?? 0)}',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nearby(ThemeData theme) {
    if (_loading) {
      return Column(
        children: List.generate(
            2,
            (_) => Container(
                  height: 84,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14)),
                )),
      );
    }
    final list = _byDistance.take(6).toList();
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(children: list.map((b) => _nearbyCard(b, theme)).toList());
  }

  Widget _nearbyCard(Map<String, dynamic> b, ThemeData theme) {
    final logo = _img((b['logo'] ?? '').toString());
    final dist = _distLabel(b);
    return InkWell(
      onTap: () => _openDetail(b),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: logo.isNotEmpty
                    ? Image.network(logo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgPlaceholder(theme))
                    : _imgPlaceholder(theme),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b['barber_name'] ?? '-',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 3),
                    Text('${b['rating'] ?? 0}',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: theme.hintColor)),
                    if (dist.isNotEmpty) ...[
                      Text('  •  ',
                          style:
                              TextStyle(color: theme.hintColor, fontSize: 12)),
                      Text(dist,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: theme.hintColor)),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text('Mulai ${_rupiah(b['price'] ?? 0)}',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.hintColor),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder(ThemeData theme) => Container(
        color: theme.primaryColor.withOpacity(0.12),
        alignment: Alignment.center,
        child: Icon(Icons.content_cut, color: theme.primaryColor, size: 28),
      );

  Widget _emptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.storefront_outlined, size: 44, color: theme.hintColor),
          const SizedBox(height: 8),
          Text('Belum ada tukang pangkas online',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, color: theme.hintColor)),
          const SizedBox(height: 4),
          Text('Coba tarik untuk refresh',
              style:
                  GoogleFonts.poppins(fontSize: 12, color: theme.hintColor)),
        ],
      ),
    );
  }

  Widget _bottomNav(ThemeData theme) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      color: theme.cardColor,
      elevation: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_rounded, 0, 'Home', theme),
            _navItem(Icons.chat_bubble_outline, 1, 'Chat', theme),
            const SizedBox(width: 48),
            _navItem(Icons.history, 2, 'History', theme),
            _navItem(Icons.help_outline, 3, 'Bantuan', theme),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int i, String label, ThemeData theme) {
    final selected = _navIndex == i;
    final color = selected ? theme.primaryColor : theme.hintColor;
    return InkWell(
      onTap: () => _navBottom(i),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.poppins(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }
}