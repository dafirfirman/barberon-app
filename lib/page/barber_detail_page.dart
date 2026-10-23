// lib/page/barber_detail_page.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';

import 'package:apkbarberon/services/api_config.dart';
import 'package:apkbarberon/page/tracking_page.dart';
import 'package:apkbarberon/page/payment_page.dart';

class BarberDetailPage extends StatefulWidget {
  final int barberId;
  final String barberName;
  const BarberDetailPage(
      {Key? key, required this.barberId, this.barberName = 'Tukang Pangkas'})
      : super(key: key);

  @override
  State<BarberDetailPage> createState() => _BarberDetailPageState();
}

class _BarberDetailPageState extends State<BarberDetailPage> {
  bool _loading = true;
  Map<String, dynamic> _barber = {};
  List<dynamic> _services = [];
  List<dynamic> _portfolio = [];

  // pemilihan layanan + lokasi
  final Set<int> _selected = {};
  Position? _pos;
  double? _distance; // km
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    _fetch();
    _getLocation();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse(Api.barberDetail),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'barber_id': widget.barberId}),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() {
          _barber = Map<String, dynamic>.from(data['barber'] ?? {});
          _services = data['services'] ?? [];
          _portfolio = data['portfolio'] ?? [];
        });
        _computeDistance();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _getLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _pos = pos;
      _computeDistance();
    } catch (_) {}
  }

  void _computeDistance() {
    if (_pos == null || _barber.isEmpty) return;
    final lat = double.tryParse('${_barber['latitude'] ?? ''}');
    final lng = double.tryParse('${_barber['longitude'] ?? ''}');
    if (lat == null || lng == null) return;
    final d = _haversine(_pos!.latitude, _pos!.longitude, lat, lng);
    setState(() => _distance = d);
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  // biaya jarak DIHITUNG SEKALI saja
  double get _distanceFee {
    if (_distance == null) return 0;
    return _distance! <= 1 ? 20000 : 20000 + ((_distance! - 1) * 10000);
  }

  double get _servicesTotal {
    double t = 0;
    for (final s in _services) {
      if (_selected.contains(s['id'])) {
        t += double.tryParse('${s['price'] ?? 0}') ?? 0;
      }
    }
    return t;
  }

  double get _grandTotal => _servicesTotal + _distanceFee;

  String _img(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$kServer/clip_perfect/$path';
  }

  String _rupiah(num v) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(v);

  String _catLabel(String? c) {
    switch (c) {
      case 'potong':
        return 'Potong Rambut';
      case 'cat':
        return 'Cat Rambut';
      case 'perawatan':
        return 'Perawatan';
      default:
        return 'Lainnya';
    }
  }

  Future<void> _confirmAndOrder() async {
    if (_selected.isEmpty) return;
    final selected =
        _services.where((s) => _selected.contains(s['id'])).toList();

    final method = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text('Konfirmasi Pesanan',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('Tukang: ${_barber['barber_name'] ?? '-'}'),
                const SizedBox(height: 6),
                ...selected.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                          '• ${s['name']}   ${_rupiah(s['price'] ?? 0)}',
                          style: const TextStyle(fontSize: 13)),
                    )),
                const Divider(),
                Row(children: [
                  const Text('Biaya jarak'),
                  const Spacer(),
                  Text(_rupiah(_distanceFee)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Text('Total',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(_rupiah(_grandTotal),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.primaryColor)),
                ]),
                const SizedBox(height: 16),
                Text('Pilih metode pembayaran',
                    style: TextStyle(
                        color: theme.hintColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 10),
                _payOption(ctx, 'online', Icons.qr_code_scanner_rounded,
                    'Bayar Online', 'QRIS / e-wallet / VA (Midtrans)'),
                const SizedBox(height: 10),
                _payOption(ctx, 'cash', Icons.payments_outlined, 'Tunai',
                    'Bayar langsung ke tukang setelah selesai'),
              ],
            ),
          ),
        );
      },
    );

    if (method == null) return;
    await _submitOrder(selected, method);
  }

  Widget _payOption(BuildContext ctx, String value, IconData icon,
      String title, String subtitle) {
    final theme = Theme.of(ctx);
    return InkWell(
      onTap: () => Navigator.pop(ctx, value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: theme.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(subtitle,
                      style:
                          TextStyle(color: theme.hintColor, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Future<void> _submitOrder(List selected, String paymentMethod) async {
    setState(() => _placing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId =
          prefs.getInt('customer_id') ?? prefs.getInt('pelanggan_id') ?? 0;
      final customerName = prefs.getString('customer_name') ?? '';
      final phone = prefs.getString('telepon') ?? '';

      if (customerId == 0) {
        _snack('Sesi login tidak ditemukan, silakan login ulang');
        return;
      }

      String address = 'Lokasi saya';
      if (_pos != null) {
        try {
          final pm =
              await placemarkFromCoordinates(_pos!.latitude, _pos!.longitude);
          if (pm.isNotEmpty) {
            final p = pm.first;
            address =
                '${p.street ?? ''}, ${p.subLocality ?? ''}, ${p.locality ?? ''}';
          }
        } catch (_) {}
      }

      final layanan = selected
          .map((s) => {'service_id': s['id'], 'harga': s['price']})
          .toList();

      final res = await http.post(
        Uri.parse(Api.order),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customer_id': customerId,
          'barber_id': _barber['id'],
          'customer_name': customerName,
          'customer_phone': phone,
          'service_address': address,
          'latitude': _pos?.latitude,
          'longitude': _pos?.longitude,
          'note': '',
          'total_price': _grandTotal,
          'payment_method': paymentMethod,
          'layanan': layanan,
        }),
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;
      if (data['success'] != true) {
        _snack(data['message'] ?? 'Gagal membuat pesanan');
        return;
      }

      final orderId = data['order_id'] is int
          ? data['order_id'] as int
          : int.tryParse('${data['order_id']}') ?? 0;

      // Bayar online dulu sebelum ke pelacakan
      if (paymentMethod == 'online') {
        await _startOnlinePayment(orderId);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TrackingPage(
            orderId: orderId,
            barberName: _barber['barber_name'] ?? 'Tukang Pangkas',
          ),
        ),
      );
    } catch (_) {
      _snack('Gagal terhubung ke server');
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  Future<void> _startOnlinePayment(int orderId) async {
    try {
      final res = await http.post(
        Uri.parse(Api.createPayment),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'order_id': orderId}),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true && data['redirect_url'] != null) {
        final paid = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentPage(
                orderId: orderId, redirectUrl: data['redirect_url']),
          ),
        );
        if (paid != true && mounted) {
          _snack('Pembayaran belum selesai. Bisa dilanjutkan nanti.');
        }
      } else {
        _snack(data['message'] ?? 'Gagal memulai pembayaran');
      }
    } catch (_) {
      _snack('Gagal memulai pembayaran');
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _viewPhoto(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(children: [
          InteractiveViewer(
            child: Center(
              child: Image.network(url,
                  errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(40),
                      child: Icon(Icons.broken_image,
                          color: Colors.white54, size: 48))),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _barber['barber_name'] ?? widget.barberName;
    final logo = _img((_barber['logo'] ?? '').toString());
    final online = (_barber['is_online'] ?? 0).toString() == '1';

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: theme.primaryColor,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 6, color: Colors.black54)
                            ])),
                    background: logo.isNotEmpty
                        ? Image.network(logo, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _coverFallback(theme, name))
                        : _coverFallback(theme, name),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text('${_barber['rating'] ?? 0}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          if (_distance != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.near_me_rounded,
                                size: 16, color: theme.hintColor),
                            const SizedBox(width: 4),
                            Text('${_distance!.toStringAsFixed(1)} km',
                                style: TextStyle(color: theme.hintColor)),
                          ],
                          const SizedBox(width: 12),
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ]),

                        if (_portfolio.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          Text('Hasil Kerja',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _portfolio.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (_, i) {
                                final url =
                                    _img(_portfolio[i]['photo']?.toString());
                                return GestureDetector(
                                  onTap: () => _viewPhoto(url),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(url,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                            width: 120,
                                            height: 120,
                                            color: theme
                                                .colorScheme.surfaceVariant,
                                            child: const Icon(Icons.image,
                                                size: 32))),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        const SizedBox(height: 22),
                        Row(children: [
                          Text('Pilih Layanan',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Text('(ceklis yang diinginkan)',
                              style: TextStyle(
                                  color: theme.hintColor, fontSize: 12)),
                        ]),
                        const SizedBox(height: 10),
                        if (_services.isEmpty)
                          Text('Belum ada layanan',
                              style: TextStyle(color: theme.hintColor))
                        else
                          ..._services.map((s) => _serviceTile(theme, s)),

                        const SizedBox(height: 140),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomSheet: _loading ? null : _bottomBar(theme),
    );
  }

  Widget _serviceTile(ThemeData theme, dynamic s) {
    final id = s['id'] as int;
    final selected = _selected.contains(id);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _selected.remove(id);
          } else {
            _selected.add(id);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? theme.primaryColor.withOpacity(0.10)
              : theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? theme.primaryColor : Colors.transparent,
              width: 1.4),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: selected ? theme.primaryColor : theme.hintColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(_catLabel(s['category']?.toString()),
                      style: TextStyle(color: theme.hintColor, fontSize: 11)),
                  if ((s['description'] ?? '').toString().isNotEmpty)
                    Text(s['description'],
                        style:
                            TextStyle(color: theme.hintColor, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(_rupiah(s['price'] ?? 0),
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: theme.primaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(ThemeData theme) {
    final hasSelection = _selected.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _row('Subtotal layanan', _rupiah(_servicesTotal), theme),
              const SizedBox(height: 4),
              _row(
                  _distance == null
                      ? 'Biaya jarak (mengaktifkan lokasi...)'
                      : 'Biaya jarak (${_distance!.toStringAsFixed(1)} km)',
                  _rupiah(_distanceFee),
                  theme),
              const Divider(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total',
                            style: TextStyle(
                                color: theme.hintColor, fontSize: 12)),
                        Text(_rupiah(_grandTotal),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: theme.primaryColor)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed:
                        (hasSelection && !_placing) ? _confirmAndOrder : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.black87,
                      disabledBackgroundColor:
                          theme.disabledColor.withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _placing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.shopping_bag_outlined),
                    label: Text(_placing ? 'Memproses...' : 'Pesan',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
              if (!hasSelection)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Pilih minimal satu layanan',
                      style: TextStyle(color: theme.hintColor, fontSize: 11)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: theme.hintColor, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _coverFallback(ThemeData theme, String name) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
              fontSize: 64,
              color: Colors.white70,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}