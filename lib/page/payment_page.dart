// lib/page/payment_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

import 'package:apkbarberon/services/api_config.dart';

class PaymentPage extends StatefulWidget {
  final int orderId;
  final String redirectUrl;
  const PaymentPage(
      {Key? key, required this.orderId, required this.redirectUrl})
      : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late final WebViewController _controller;
  Timer? _poll;
  bool _checking = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.redirectUrl));
    // polling status pembayaran tiap 5 detik
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _check());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _check({bool manual = false}) async {
    if (_done) return;
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final res = await http.post(
        Uri.parse(Api.checkPayment),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'order_id': widget.orderId}),
      );
      final data = jsonDecode(res.body);
      final status = (data['payment_status'] ?? '').toString();
      if (status == 'paid') {
        _done = true;
        _poll?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Pembayaran berhasil! 🎉')));
          Navigator.pop(context, true);
        }
      } else if (status == 'failed' || status == 'expired') {
        if (mounted && manual) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pembayaran gagal/kedaluwarsa.')));
        }
      } else if (manual) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Pembayaran belum terdeteksi. Coba lagi sebentar.')));
        }
      }
    } catch (_) {
      if (manual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal cek status pembayaran.')));
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _confirmExit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan pembayaran?'),
        content: const Text(
            'Pembayaran belum selesai. Kamu bisa melanjutkannya nanti dari Pesanan Saya.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Lanjut Bayar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Keluar')),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _confirmExit();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran'),
          leading: IconButton(
              icon: const Icon(Icons.close), onPressed: _confirmExit),
        ),
        body: Column(
          children: [
            Expanded(child: WebViewWidget(controller: _controller)),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        _checking ? null : () => _check(manual: true),
                    icon: _checking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh),
                    label: Text(_checking
                        ? 'Mengecek...'
                        : 'Saya sudah bayar / Cek status'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}