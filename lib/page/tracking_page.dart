// lib/page/tracking_page.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import 'package:apkbarberon/services/api_config.dart';
import 'package:apkbarberon/page/chat_page.dart';

class TrackingPage extends StatefulWidget {
  final int orderId;
  final String barberName;
  const TrackingPage(
      {Key? key, required this.orderId, this.barberName = 'Tukang Pangkas'})
      : super(key: key);

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage>
    with TickerProviderStateMixin {
  final MapController _map = MapController();
  Timer? _poll;

  LatLng? _customer;
  LatLng? _barberShown;
  LatLng? _barberTarget;
  LatLng? _animFrom;
  String _status = 'pending';
  String _barberName = '';
  bool _loading = true;
  bool _firstMapFit = false;

  late final AnimationController _moveAnim; // gerak marker
  late final AnimationController _pulse; // denyut saat menunggu

  @override
  void initState() {
    super.initState();
    _barberName = widget.barberName;
    _moveAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..addListener(_onMoveTick);
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _fetch(initial: true);
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _fetch());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _moveAnim.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _onMoveTick() {
    if (_animFrom == null || _barberTarget == null) return;
    final t = _moveAnim.value;
    setState(() {
      _barberShown = LatLng(
        _animFrom!.latitude + (_barberTarget!.latitude - _animFrom!.latitude) * t,
        _animFrom!.longitude +
            (_barberTarget!.longitude - _animFrom!.longitude) * t,
      );
    });
  }

  Future<void> _fetch({bool initial = false}) async {
    try {
      final res = await http.post(
        Uri.parse(Api.orderStatus),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'order_id': widget.orderId}),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        final d = data['data'];
        final cLat = d['cust_lat'], cLng = d['cust_lng'];
        final bLat = d['barber_lat'], bLng = d['barber_lng'];

        setState(() {
          _status = d['status'] ?? 'pending';
          _barberName = d['barber_name'] ?? _barberName;
          if (cLat != null && cLng != null) {
            _customer =
                LatLng((cLat as num).toDouble(), (cLng as num).toDouble());
          }
        });

        if (bLat != null && bLng != null) {
          final target =
              LatLng((bLat as num).toDouble(), (bLng as num).toDouble());
          if (_barberShown == null) {
            _barberShown = target;
            _barberTarget = target;
          } else if (_barberTarget == null ||
              target.latitude != _barberTarget!.latitude ||
              target.longitude != _barberTarget!.longitude) {
            _animFrom = _barberShown;
            _barberTarget = target;
            _moveAnim.forward(from: 0);
          }
        }

        // auto-fit sekali ketika sudah masuk mode peta
        if (!_firstMapFit &&
            (_status == 'accepted' || _status == 'on_the_way') &&
            _barberShown != null) {
          _firstMapFit = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _fitMap());
        }
      }
    } catch (_) {
    } finally {
      if (initial && mounted) setState(() => _loading = false);
    }
  }

  void _fitMap() {
    final pts = [_customer, _barberShown].whereType<LatLng>().toList();
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      _map.move(pts.first, 15);
      return;
    }
    final midLat = (pts[0].latitude + pts[1].latitude) / 2;
    final midLng = (pts[0].longitude + pts[1].longitude) / 2;
    final dKm = _distanceKm() ?? 1;
    double zoom = 15;
    if (dKm > 8) {
      zoom = 11;
    } else if (dKm > 4) {
      zoom = 12;
    } else if (dKm > 2) {
      zoom = 13;
    } else if (dKm > 1) {
      zoom = 14;
    }
    _map.move(LatLng(midLat, midLng), zoom);
  }

  double? _distanceKm() {
    if (_customer == null || _barberShown == null) return null;
    return _haversine(_customer!.latitude, _customer!.longitude,
        _barberShown!.latitude, _barberShown!.longitude);
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void _openChat() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ChatPage(orderId: widget.orderId, chatWithName: _barberName),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_status == 'pending') return _waitingScreen();
    if (_status == 'accepted' || _status == 'on_the_way') return _mapScreen();
    return _resultScreen(); // completed / rejected / cancelled
  }

  // ---------- MENUNGGU ----------
  Widget _waitingScreen() {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Menunggu Konfirmasi')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: Tween(begin: 0.9, end: 1.1).animate(_pulse),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.content_cut,
                      size: 50, color: theme.primaryColor),
                ),
              ),
              const SizedBox(height: 24),
              Text('Menunggu $_barberName menerima pesananmu...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Text('Begitu diterima, peta lokasi tukang akan terbuka otomatis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.hintColor, fontSize: 13)),
              const SizedBox(height: 24),
              const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.5)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- PETA (REAL-TIME) ----------
  Widget _mapScreen() {
    final theme = Theme.of(context);
    final dist = _distanceKm();
    final onTheWay = _status == 'on_the_way';

    String hint;
    if (dist == null) {
      hint = onTheWay ? 'Tukang dalam perjalanan' : 'Tukang bersiap berangkat';
    } else if (dist <= 0.15) {
      hint = 'Tukang sudah sampai di lokasimu! 🎉';
    } else if (dist <= 0.5) {
      hint = 'Sebentar lagi sampai — sudah sangat dekat';
    } else if (dist <= 1.5) {
      hint = 'Tukang sudah dekat';
    } else {
      hint = 'Tukang menuju lokasimu';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_barberName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: _openChat),
          IconButton(
              icon: const Icon(Icons.my_location), onPressed: _fitMap),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter:
                  _barberShown ?? _customer ?? const LatLng(3.59, 98.67),
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'apkbarberon.app',
              ),
              if (_customer != null && _barberShown != null)
                PolylineLayer(polylines: [
                  Polyline(
                    points: [_barberShown!, _customer!],
                    color: theme.primaryColor,
                    strokeWidth: 4,
                  ),
                ]),
              MarkerLayer(markers: [
                if (_customer != null)
                  Marker(
                    point: _customer!,
                    width: 46,
                    height: 46,
                    child: const Icon(Icons.person_pin_circle,
                        color: Colors.red, size: 46),
                  ),
                if (_barberShown != null)
                  Marker(
                    point: _barberShown!,
                    width: 50,
                    height: 50,
                    child: _barberMarker(theme),
                  ),
              ]),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.12), blurRadius: 16),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.content_cut, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(hint,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ]),
                  if (dist != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.near_me_rounded,
                          color: theme.primaryColor, size: 20),
                      const SizedBox(width: 6),
                      Text('${dist.toStringAsFixed(2)} km dari kamu',
                          style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      if (onTheWay) ...[
                        const Spacer(),
                        Icon(Icons.schedule,
                            size: 16, color: theme.hintColor),
                        const SizedBox(width: 4),
                        Text('± ${(dist / 18 * 60).ceil()} mnt',
                            style: TextStyle(
                                color: theme.hintColor,
                                fontWeight: FontWeight.w600)),
                      ],
                    ]),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openChat,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Chat Tukang Pangkas'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // marker tukang: gambar dari assets (fallback ke ikon gunting bila gambar tak ada)
  Widget _barberMarker(ThemeData theme) {
    return Image.asset(
      'assets/icons/barber_marker.png',
      width: 48,
      height: 48,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.primaryColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
                color: theme.primaryColor.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 1),
          ],
        ),
        child: const Icon(Icons.content_cut, color: Colors.black87, size: 22),
      ),
    );
  }

  // ---------- HASIL (selesai / ditolak / batal) ----------
  Widget _resultScreen() {
    final theme = Theme.of(context);
    IconData icon;
    Color color;
    String title;
    String subtitle;
    switch (_status) {
      case 'completed':
        icon = Icons.done_all;
        color = Colors.green;
        title = 'Pesanan Selesai';
        subtitle = 'Beri penilaian di halaman Pesanan Saya, ya.';
        break;
      case 'rejected':
        icon = Icons.cancel_outlined;
        color = Colors.red;
        title = 'Pesanan Ditolak';
        subtitle = 'Maaf, tukang menolak pesanan ini. Coba tukang lain.';
        break;
      default:
        icon = Icons.block;
        color = Colors.grey;
        title = 'Pesanan Dibatalkan';
        subtitle = 'Pesanan ini dibatalkan.';
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Status Pesanan')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 72, color: color),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.hintColor)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}