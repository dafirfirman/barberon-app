// lib/page/chat_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:apkbarberon/services/api_config.dart';

class ChatPage extends StatefulWidget {
  final int orderId;
  final String chatWithName;

  const ChatPage({
    Key? key,
    required this.orderId,
    required this.chatWithName,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _msgC = TextEditingController();
  final ScrollController _scrollC = ScrollController();
  Timer? _poll;
  bool _loading = true;
  bool _sending = false;
  int _lastId = 0;

  @override
  void initState() {
    super.initState();
    _fetch(initial: true);
    // polling tiap 3 detik untuk pesan baru
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _fetch());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _msgC.dispose();
    _scrollC.dispose();
    super.dispose();
  }

  Future<void> _fetch({bool initial = false}) async {
    try {
      final res = await http.post(
        Uri.parse(Api.getMessages),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'order_id': widget.orderId, 'after_id': _lastId}),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        final list = (data['data'] as List?) ?? [];
        if (list.isNotEmpty) {
          setState(() {
            for (final m in list) {
              _messages.add(Map<String, dynamic>.from(m));
              _lastId = m['id'];
            }
          });
          _scrollToBottom();
        }
      }
    } catch (_) {
      // diam
    } finally {
      if (initial && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _msgC.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final res = await http.post(
        Uri.parse(Api.sendMessage),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'order_id': widget.orderId, 'message': text}),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _msgC.clear();
        final m = Map<String, dynamic>.from(data['data']);
        setState(() {
          _messages.add(m);
          _lastId = m['id'];
        });
        _scrollToBottom();
      } else {
        _snack(data['message'] ?? 'Gagal mengirim');
      }
    } catch (_) {
      _snack('Gagal terhubung ke server');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollC.hasClients) {
        _scrollC.animateTo(
          _scrollC.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String _time(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatWithName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text('Mulai percakapan',
                            style: TextStyle(color: theme.hintColor)))
                    : ListView.builder(
                        controller: _scrollC,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          final isMe = m['sender'] == 'customer';
                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 14),
                              constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.72),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? primary
                                    : theme.colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft:
                                      Radius.circular(isMe ? 16 : 4),
                                  bottomRight:
                                      Radius.circular(isMe ? 4 : 16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    m['message'] ?? '',
                                    style: TextStyle(
                                        color: isMe
                                            ? Colors.black87
                                            : theme.textTheme.bodyLarge?.color),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _time(m['created_at']),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe
                                          ? Colors.black54
                                          : theme.hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgC,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tulis pesan...',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor:
                            theme.colorScheme.surfaceVariant.withOpacity(0.4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: primary,
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : IconButton(
                            icon: const Icon(Icons.send, color: Colors.black87),
                            onPressed: _send,
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
}