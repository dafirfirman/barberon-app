// lib/page/notification/notification_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

import 'package:apkbarberon/services/api_config.dart';
import 'package:apkbarberon/page/chat_page.dart';
import 'package:apkbarberon/page/tracking_page.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({Key? key}) : super(key: key);

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  int? _customerId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _customerId = prefs.getInt('customer_id') ?? prefs.getInt('pelanggan_id');
    await _fetch();
  }

  Future<void> _fetch() async {
    if (_customerId == null || _customerId == 0) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse(Api.myOrders),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'customer_id': _customerId}),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        final all = (data['data'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [];
        // hanya pesanan aktif; selesai/batal/ditolak ada di History
        setState(() {
          _orders = all.where((o) {
            final s = (o['status'] ?? '').toString();
            return s == 'pending' || s == 'accepted' || s == 'on_the_way';
          }).toList();
        });
      }
    } catch (_) {
      // diam
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- helpers tampilan ----------
  String _rupiah(int v) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(v);

  String _waktu(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('d MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }

  Map<String, dynamic> _statusInfo(String s) {
    switch (s) {
      case 'pending':
        return {'label': 'Menunggu konfirmasi', 'color': Colors.orange, 'icon': Icons.hourglass_top};
      case 'accepted':
        return {'label': 'Diterima', 'color': Colors.blue, 'icon': Icons.check_circle_outline};
      case 'on_the_way':
        return {'label': 'Menuju lokasi', 'color': Colors.teal, 'icon': Icons.directions_run};
      case 'completed':
        return {'label': 'Selesai', 'color': Colors.green, 'icon': Icons.done_all};
      case 'rejected':
        return {'label': 'Ditolak', 'color': Colors.red, 'icon': Icons.cancel_outlined};
      case 'cancelled':
        return {'label': 'Dibatalkan', 'color': Colors.grey, 'icon': Icons.block};
      default:
        return {'label': s, 'color': Colors.grey, 'icon': Icons.info_outline};
    }
  }

// ignore: unused_element

  // ---------- rating ----------
  void _showRatingDialog(Map<String, dynamic> order) {
    double rating = 5;
    final reviewC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Beri Penilaian'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBar.builder(
                initialRating: 5,
                minRating: 1,
                allowHalfRating: false,
                itemCount: 5,
                itemBuilder: (_, __) =>
                    const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (v) => rating = v,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reviewC,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Ulasan (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _submitRating(order['order_id'], rating, reviewC.text.trim());
              },
              child: const Text('Kirim'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitRating(int orderId, double rating, String review) async {
    try {
      final res = await http.post(
        Uri.parse(Api.submitRating),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'order_id': orderId, 'rating': rating, 'review': review}),
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Terima kasih atas penilaiannya')));
        _fetch();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Gagal menilai')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal terhubung ke server')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Saya',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
                ? ListView(children: [
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.3),
                    Center(
                        child: Text('Belum ada pesanan aktif',
                            style: TextStyle(color: theme.hintColor))),
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _orders.length,
                    itemBuilder: (context, i) => _orderCard(_orders[i]),
                  ),
      ),
    );
  }

  void _openTracking(Map<String, dynamic> o) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrackingPage(
          orderId: o['order_id'],
          barberName: o['barber_name'] ?? 'Tukang Pangkas',
        ),
      ),
    ).then((_) => _fetch());
  }

  Widget _orderCard(Map<String, dynamic> o) {
    final theme = Theme.of(context);
    final status = (o['status'] ?? '').toString();
    final info = _statusInfo(status);
    final Color color = info['color'];
    final trackable =
        status == 'pending' || status == 'accepted' || status == 'on_the_way';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: trackable ? () => _openTracking(o) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(o['barber_name'] ?? 'Tukang Pangkas',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(info['icon'], size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(info['label'],
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if ((o['service_address'] ?? '').toString().isNotEmpty)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: theme.hintColor),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(o['service_address'],
                        style: TextStyle(color: theme.hintColor, fontSize: 13))),
              ]),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.payments_outlined, size: 16, color: theme.hintColor),
              const SizedBox(width: 6),
              Text(_rupiah(o['total_price'] ?? 0),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(_waktu(o['created_at']),
                  style: TextStyle(color: theme.hintColor, fontSize: 12)),
            ]),
            if (status == 'accepted' ||
                status == 'on_the_way' ||
                (status == 'completed' && o['rated'] != true)) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (status == 'accepted' || status == 'on_the_way') ...[
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrackingPage(
                            orderId: o['order_id'],
                            barberName: o['barber_name'] ?? 'Tukang Pangkas',
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.near_me_rounded, size: 18),
                      label: const Text('Lacak'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            orderId: o['order_id'],
                            chatWithName: o['barber_name'] ?? 'Tukang Pangkas',
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('Chat'),
                    ),
                  ],
                  if (status == 'completed' && o['rated'] != true)
                    ElevatedButton.icon(
                      onPressed: () => _showRatingDialog(o),
                      icon: const Icon(Icons.star, size: 18),
                      label: const Text('Beri Penilaian'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}