import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';

import 'package:apkbarberon/services/api_config.dart';
import 'package:apkbarberon/auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  final String? telepon;
  final Function(ThemeMode) updateThemeMode;

  const ProfilePage({
    Key? key,
    required this.telepon,
    required this.updateThemeMode,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameC = TextEditingController();
  final TextEditingController _emailC = TextEditingController();

  int _customerId = 0;
  String _phone = '';
  File? _photo;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _customerId =
        prefs.getInt('customer_id') ?? prefs.getInt('pelanggan_id') ?? 0;
    _phone = widget.telepon?.isNotEmpty == true
        ? widget.telepon!
        : (prefs.getString('telepon') ?? '');
    _nameC.text = prefs.getString('customer_name') ?? '';
    _emailC.text = prefs.getString('customer_email') ?? '';
    final photoPath = prefs.getString('customer_photo');
    if (photoPath != null && photoPath.isNotEmpty && File(photoPath).existsSync()) {
      _photo = File(photoPath);
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    if (picked == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('customer_photo', picked.path);
    setState(() => _photo = File(picked.path));
  }

  Future<void> _save() async {
    final name = _nameC.text.trim();
    final email = _emailC.text.trim();
    if (name.isEmpty) {
      _snack('Nama tidak boleh kosong');
      return;
    }
    if (_customerId == 0) {
      _snack('Sesi tidak ditemukan, silakan login ulang');
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse(Api.updateProfile),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(
            {'customer_id': _customerId, 'name': name, 'email': email}),
      );
      final data = json.decode(res.body);
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('customer_name', name);
        await prefs.setString('customer_email', email);
        if (mounted) _snack('Profil berhasil diperbarui');
      } else {
        _snack(data['message'] ?? 'Gagal memperbarui profil');
      }
    } catch (_) {
      _snack('Gagal terhubung ke server');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(children: const [
          Icon(Iconsax.logout, color: Colors.red),
          SizedBox(width: 10),
          Text('Keluar'),
        ]),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Keluar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('telepon');
    await prefs.remove('customer_id');
    await prefs.remove('pelanggan_id');
    await prefs.remove('customer_name');
    await prefs.remove('customer_email');
    await prefs.remove('customer_photo');
    await prefs.remove('auth_token');
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 230,
                pinned: true,
                backgroundColor: theme.colorScheme.primary,
                leading: IconButton(
                  icon: const Icon(Iconsax.arrow_left, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(background: _header(theme)),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                  child: Column(
                    children: [
                      _form(theme),
                      const SizedBox(height: 22),
                      _settings(theme),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _header(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.75),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: ClipOval(
                      child: _photo != null
                          ? Image.file(_photo!, fit: BoxFit.cover)
                          : const Icon(Iconsax.user,
                              size: 42, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: Icon(Iconsax.camera,
                          size: 16, color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _nameC.text.isNotEmpty ? _nameC.text : 'Pengguna BarberOn',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold),
            ),
            if (_phone.isNotEmpty)
              Text(_phone,
                  style: TextStyle(color: Colors.white.withOpacity(0.9))),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _form(ThemeData theme) {
    return Column(
      children: [
        _field(Iconsax.user, 'Nama Lengkap', _nameC),
        const SizedBox(height: 14),
        _field(Iconsax.sms, 'Email (opsional)', _emailC,
            keyboard: TextInputType.emailAddress),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _save,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('SIMPAN PERUBAHAN',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _field(IconData icon, String label, TextEditingController c,
      {TextInputType keyboard = TextInputType.text}) {
    final theme = Theme.of(context);
    return TextField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _settings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pengaturan',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ListTile(
                leading:
                    Icon(Iconsax.moon, color: theme.colorScheme.primary),
                title: const Text('Tema Aplikasi'),
                trailing: const Icon(Iconsax.arrow_right_3, size: 18),
                onTap: _themeDialog,
              ),
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.3)),
              ListTile(
                leading: const Icon(Iconsax.logout, color: Colors.red),
                title: const Text('Keluar',
                    style: TextStyle(color: Colors.red)),
                trailing: const Icon(Iconsax.arrow_right_3,
                    size: 18, color: Colors.red),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _themeDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pilih Tema',
                  style:
                      TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _themeOpt(Iconsax.sun_1, 'Terang', ThemeMode.light, theme),
              _themeOpt(Iconsax.moon, 'Gelap', ThemeMode.dark, theme),
              _themeOpt(Iconsax.setting, 'Ikuti Sistem', ThemeMode.system,
                  theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeOpt(IconData icon, String label, ThemeMode mode,
      ThemeData theme) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label),
      onTap: () {
        widget.updateThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }
}