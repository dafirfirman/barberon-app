// lib/page/history_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

import 'package:apkbarberon/services/api_config.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _orders = [];
  Set<String> _hidden = {};
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
    _hidden = (prefs.getStringList('hidden_orders') ?? []).toSet();
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
        setState(() {
          _orders = all.where((o) {
            final s = (o['status'] ?? '').toString();
            final done =
                s == 'completed' || s == 'cancelled' || s == 'rejected';
            return done && !_hidden.contains('${o['order_id']}');
          }).toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _hide(int orderId) async {
    _hidden.add('$orderId');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('hidden_orders', _hidden.toList());
    setState(() {
      _orders.removeWhere((o) => o['order_id'] == orderId);
    });
  }

  String _rupiah(int v) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(v);

  String _waktu(String? raw) {
    if (raw == null) return '';
    try {
      return DateFormat('d MMM yyyy, HH:mm')
          .format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  Map<String, dynamic> _statusInfo(String s) {
    switch (s) {
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

  // ---------- rating ----------
  void _showRatingDialog(Map<String, dynamic> order) {
    double rating = 5;
    final reviewC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Beri Penilaian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RatingBar.builder(
              initialRating: 5,
              minRating: 1,
              allowHalfRating: false,
              itemCount: 5,
              itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (v) => rating = v,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reviewC,
              maxLines: 2,
              decoration: const InputDecoration(
                  hintText: 'Ulasan (opsional)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitRating(order['order_id'], rating, reviewC.text.trim());
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
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
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
                ? ListView(children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    Center(
                        child: Text('Belum ada riwayat',
                            style: TextStyle(color: theme.hintColor))),
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _orders.length,
                    itemBuilder: (context, i) => _card(_orders[i]),
                  ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> o) {
    final theme = Theme.of(context);
    final status = (o['status'] ?? '').toString();
    final info = _statusInfo(status);
    final Color color = info['color'];
    final orderId = o['order_id'] as int;

    return Dismissible(
      key: Key('order_$orderId'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: Colors.red, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        _hide(orderId);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Riwayat dihapus')));
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
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
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.payments_outlined, size: 16, color: theme.hintColor),
                const SizedBox(width: 6),
                Text(_rupiah(o['total_price'] ?? 0),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(_waktu(o['created_at']),
                    style: TextStyle(color: theme.hintColor, fontSize: 12)),
              ]),
              if (status == 'completed') ...[
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // pembayaran online (lihat catatan)
                    OutlinedButton.icon(
                      onPressed: () => _showPayInfo(),
                      icon: const Icon(Icons.account_balance_wallet_outlined,
                          size: 18),
                      label: const Text('Bayar Online'),
                    ),
                    if (o['rated'] != true)
                      ElevatedButton.icon(
                        onPressed: () => _showRatingDialog(o),
                        icon: const Icon(Icons.star, size: 18),
                        label: const Text('Nilai'),
                      )
                    else
                      Row(children: const [
                        Icon(Icons.star, color: Colors.amber, size: 18),
                        SizedBox(width: 4),
                        Text('Sudah dinilai'),
                      ]),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPayInfo() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pembayaran Online',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
                'Pembayaran online (QRIS / e-wallet / transfer) akan segera tersedia. '
                'Untuk saat ini, pembayaran dilakukan tunai setelah selesai.'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Mengerti'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}