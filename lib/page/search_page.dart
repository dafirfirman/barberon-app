// lib/page/search_page.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:apkbarberon/services/api_config.dart';
import 'package:apkbarberon/page/barber_detail_page.dart';

class _Cat {
  final String key;
  final String label;
  final IconData icon;
  const _Cat(this.key, this.label, this.icon);
}

const List<_Cat> _categories = [
  _Cat('', 'Semua', Icons.grid_view_rounded),
  _Cat('potong', 'Potong Rambut', Icons.content_cut),
  _Cat('cat', 'Cat Rambut', Icons.palette_outlined),
  _Cat('perawatan', 'Perawatan', Icons.spa_outlined),
];

String _catShort(String c) {
  switch (c) {
    case 'potong':
      return 'Potong';
    case 'cat':
      return 'Cat';
    case 'perawatan':
      return 'Perawatan';
    default:
      return c;
  }
}

Color _catColor(String c) {
  switch (c) {
    case 'potong':
      return const Color(0xFF2E7D9A);
    case 'cat':
      return const Color(0xFF9C27B0);
    case 'perawatan':
      return const Color(0xFF2E7D32);
    default:
      return Colors.grey;
  }
}

class SearchPage extends StatefulWidget {
  final String categoryKey;
  const SearchPage({Key? key, this.categoryKey = ''}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  Position? _currentPosition;
  String _currentAddress = '';
  bool _isLoading = false;
  bool _sortByRating = false;
  bool _searchNearby = false;
  String _category = '';
  List<dynamic> _barbershops = [];
  List<dynamic> _filtered = [];
  final TextEditingController _keywordC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _category = widget.categoryKey;
    _getCurrentLocation();
    _fetchBarbershops();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _currentPosition = pos);
      _reverseGeocode(pos);
    } catch (e) {
      debugPrint('Gagal lokasi: $e');
    }
  }

  Future<void> _reverseGeocode(Position pos) async {
    try {
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks[0];
        setState(() => _currentAddress =
            "${p.street ?? ''}, ${p.subLocality ?? ''}, ${p.locality ?? ''}");
      }
    } catch (_) {}
  }

  Future<void> _fetchBarbershops() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.post(Uri.parse(Api.search), body: {
        'keyword': _keywordC.text.trim(),
        'category': _category,
      }).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        List<dynamic> list = [];
        if (body is Map && body['data'] != null) {
          list = body['data'];
        } else if (body is List) {
          list = body;
        }
        if (mounted) {
          setState(() {
            _barbershops = list;
            _applySort();
          });
        }
      } else {
        _snack('Gagal memuat data (${res.statusCode})');
      }
    } catch (e) {
      debugPrint('Error fetch: $e');
      _snack('Gagal memuat data pangkas');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applySort() {
    var list = List.from(_barbershops);
    if (_sortByRating) {
      list.sort((a, b) {
        final ra = double.tryParse('${a['rating'] ?? 0}') ?? 0;
        final rb = double.tryParse('${b['rating'] ?? 0}') ?? 0;
        return rb.compareTo(ra);
      });
    }
    if (_searchNearby && _currentPosition != null) {
      list.sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));
    }
    setState(() => _filtered = list);
  }

  void _selectCategory(String key) {
    setState(() => _category = key);
    _fetchBarbershops();
  }

  double _distanceTo(Map item) {
    if (_currentPosition == null) return double.infinity;
    final lat = double.tryParse('${item['latitude'] ?? ''}');
    final lng = double.tryParse('${item['longitude'] ?? ''}');
    if (lat == null || lng == null) return double.infinity;
    return _haversine(
        _currentPosition!.latitude, _currentPosition!.longitude, lat, lng);
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  String _rupiah(num v) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(v);

  String _photoUrl(Map b) {
    final logo = (b['logo'] ?? '').toString();
    if (logo.startsWith('http')) return logo;
    if (logo.isNotEmpty) return '$kServer/clip_perfect/$logo';
    return '';
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Pangkas',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentAddress.trim().replaceAll(',', '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(children: [
                        const Icon(Icons.location_on,
                            color: Colors.red, size: 15),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(_currentAddress,
                              style: TextStyle(
                                  color: theme.hintColor, fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    ),
                  TextField(
                    controller: _keywordC,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _fetchBarbershops(),
                    decoration: InputDecoration(
                      hintText: 'Cari nama, alamat, atau layanan...',
                      prefixIcon:
                          Icon(Icons.search, color: theme.primaryColor),
                      suffixIcon: _isLoading
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.primaryColor)),
                            )
                          : IconButton(
                              icon:
                                  Icon(Icons.tune, color: theme.primaryColor),
                              onPressed: _fetchBarbershops,
                            ),
                      filled: true,
                      fillColor:
                          theme.colorScheme.surfaceVariant.withOpacity(0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = _categories[i];
                  final active = c.key == _category;
                  return GestureDetector(
                    onTap: () => _selectCategory(c.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active
                            ? theme.primaryColor
                            : theme.colorScheme.surfaceVariant
                                .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(children: [
                        Icon(c.icon,
                            size: 16,
                            color:
                                active ? Colors.black87 : theme.hintColor),
                        const SizedBox(width: 6),
                        Text(c.label,
                            style: TextStyle(
                              color:
                                  active ? Colors.black87 : theme.hintColor,
                              fontWeight: active
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 13,
                            )),
                      ]),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(children: [
                Expanded(
                  child: _sortChip(
                    label: 'Rating Tertinggi',
                    icon: Icons.star_rounded,
                    active: _sortByRating,
                    onTap: () {
                      setState(() {
                        _sortByRating = !_sortByRating;
                        if (_sortByRating) _searchNearby = false;
                      });
                      _applySort();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _sortChip(
                    label: 'Terdekat',
                    icon: Icons.near_me_rounded,
                    active: _searchNearby,
                    onTap: () {
                      if (_currentPosition == null) {
                        _snack('Lokasi belum aktif');
                        return;
                      }
                      setState(() {
                        _searchNearby = !_searchNearby;
                        if (_searchNearby) _sortByRating = false;
                      });
                      _applySort();
                    },
                  ),
                ),
              ]),
            ),
            Expanded(
              child: _isLoading && _filtered.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? _emptyState(theme)
                      : RefreshIndicator(
                          onRefresh: _fetchBarbershops,
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 6, 16, 16),
                            itemCount: _filtered.length,
                            itemBuilder: (context, idx) => _barberCard(
                                Map<String, dynamic>.from(_filtered[idx])),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(ThemeData theme) {
    return ListView(children: [
      SizedBox(height: MediaQuery.of(context).size.height * 0.18),
      Icon(Icons.content_cut, size: 64, color: theme.hintColor),
      const SizedBox(height: 12),
      Center(
        child: Text(
          _category.isEmpty
              ? 'Belum ada tukang pangkas online'
              : 'Belum ada yang menyediakan ${_catShort(_category)}',
          style: TextStyle(color: theme.hintColor, fontSize: 15),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 6),
      Center(
        child: Text('Tarik ke bawah untuk segarkan',
            style: TextStyle(color: theme.hintColor, fontSize: 12)),
      ),
    ]);
  }

  Widget _sortChip({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? theme.primaryColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? theme.primaryColor : theme.dividerColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: active ? theme.primaryColor : theme.hintColor),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  color: active ? theme.primaryColor : theme.hintColor,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }

  Widget _barberCard(Map<String, dynamic> b) {
    final theme = Theme.of(context);
    final basePrice = double.tryParse('${b['price'] ?? 0}') ?? 0;
    double? distance;
    if (_currentPosition != null) {
      final d = _distanceTo(b);
      if (d != double.infinity) distance = d;
    }
    final photo = _photoUrl(b);
    final online = (b['is_online'] ?? 0).toString() == '1';
    final cats = (b['categories'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetail(b),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 76,
                      height: 76,
                      child: photo.isNotEmpty
                          ? Image.network(photo, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _avatarFallback(theme, b))
                          : _avatarFallback(theme, b),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(
                                b['barber_name'] ?? 'Tukang Pangkas',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (online)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Online',
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ]),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.star_rounded,
                              size: 15, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text('${b['rating'] ?? '0.0'}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          if (distance != null) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.near_me_rounded,
                                size: 14, color: theme.hintColor),
                            const SizedBox(width: 3),
                            Text('${distance.toStringAsFixed(1)} km',
                                style: TextStyle(
                                    color: theme.hintColor, fontSize: 12)),
                          ],
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
              if (cats.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: cats.map<Widget>((c) {
                    final cc = _catColor(c.toString());
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: cc.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_catShort(c.toString()),
                          style: TextStyle(
                              color: cc,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mulai dari',
                            style: TextStyle(
                                color: theme.hintColor, fontSize: 11)),
                        Text(_rupiah(basePrice),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: theme.primaryColor)),
                        Text('belum termasuk biaya jarak',
                            style: TextStyle(
                                color: theme.hintColor, fontSize: 10)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _openDetail(b),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                    child: const Text('Lihat',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(ThemeData theme, Map b) {
    final name = (b['barber_name'] ?? '?').toString();
    return Container(
      color: theme.primaryColor.withOpacity(0.15),
      alignment: Alignment.center,
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 28)),
    );
  }

  void _openDetail(Map<String, dynamic> b) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BarberDetailPage(
            barberId: b['id'],
            barberName: b['barber_name'] ?? 'Tukang Pangkas'),
      ),
    );
  }
}