// lib/page/chat_list_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apkbarberon/services/api_config.dart';
import 'package:apkbarberon/page/chat_page.dart';

class ChatListPage extends StatefulWidget {
  // telepon dipertahankan agar pemanggilan lama tetap kompatibel, tapi
  // identitas sebenarnya diambil dari customer_id di SharedPreferences.
  final String? telepon;
  const ChatListPage({Key? key, this.telepon}) : super(key: key);

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;
  int? _customerId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _customerId = prefs.getInt('customer_id') ?? prefs.getInt('pelanggan_id');
    await _fetchChats();
  }

  Future<void> _fetchChats() async {
    if (_customerId == null || _customerId == 0) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse(Api.chatList),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'customer_id': _customerId}),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() {
          _chats = (data['data'] as List?)
                  ?.map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              [];
        });
      }
    } catch (_) {
      // diam — tampilkan kosong
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _shortTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final sameDay =
          dt.year == now.year && dt.month == now.month && dt.day == now.day;
      if (sameDay) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'pending':
        return 'Menunggu';
      case 'accepted':
        return 'Diterima';
      case 'on_the_way':
        return 'Menuju lokasi';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'rejected':
        return 'Ditolak';
      default:
        return s ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchChats,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _chats.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Text('Belum ada percakapan',
                            style: TextStyle(color: theme.hintColor)),
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: _chats.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: theme.dividerColor.withOpacity(0.4)),
                    itemBuilder: (context, i) {
                      final c = _chats[i];
                      final name = c['barber_name'] ?? 'Tukang Pangkas';
                      final last = (c['last_message'] ?? '').toString();
                      final logo = (c['logo'] ?? '').toString();
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.15),
                          backgroundImage: logo.isNotEmpty
                              ? NetworkImage('$kServer/clip_perfect/$logo')
                              : null,
                          child: logo.isEmpty
                              ? Text(
                                  name.toString().isNotEmpty
                                      ? name.toString()[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        title: Text(name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          last.isEmpty
                              ? _statusLabel(c['order_status'])
                              : last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          _shortTime(c['last_time']),
                          style:
                              TextStyle(fontSize: 12, color: theme.hintColor),
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                orderId: c['order_id'],
                                chatWithName: name,
                              ),
                            ),
                          );
                          _fetchChats(); // segarkan saat kembali
                        },
                      );
                    },
                  ),
      ),
    );
  }
}