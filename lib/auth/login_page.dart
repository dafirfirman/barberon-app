// lib/auth/login_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apkbarberon/page/home_page.dart';
import 'package:apkbarberon/services/api_config.dart';
import 'package:apkbarberon/services/theme_controller.dart';

enum _Step { phone, otp, name }

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color primary = Color(0xFF00D8FF);

  final _phoneC = TextEditingController();
  final _otpC = TextEditingController();
  final _nameC = TextEditingController();

  _Step _step = _Step.phone;
  bool _loading = false;
  String _phone = ''; // nomor ternormalisasi dari server
  String _verifyToken = '';
  String? _devCode; // muncul saat mode tes

  @override
  void dispose() {
    _phoneC.dispose();
    _otpC.dispose();
    _nameC.dispose();
    super.dispose();
  }

  // ---------------- API ----------------
  Future<void> _sendOtp() async {
    final raw = _phoneC.text.trim();
    if (raw.length < 9) {
      _snack('Nomor telepon tidak valid');
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse(Api.sendOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': raw}),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() {
          _phone = data['phone'] ?? raw;
          _devCode = data['dev_code'];
          _step = _Step.otp;
        });
      } else {
        _snack(data['message'] ?? 'Gagal mengirim OTP');
      }
    } catch (_) {
      _snack('Gagal terhubung ke server');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpC.text.trim();
    if (code.length != 6) {
      _snack('OTP harus 6 digit');
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse(Api.verifyOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': _phone, 'code': code}),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        if (data['is_new'] == true) {
          setState(() {
            _verifyToken = data['verify_token'] ?? '';
            _step = _Step.name;
          });
        } else {
          await _saveSession(data['token'], data['data']);
          _goHome();
        }
      } else {
        _snack(data['message'] ?? 'Verifikasi gagal');
      }
    } catch (_) {
      _snack('Gagal terhubung ke server');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeSignup() async {
    final name = _nameC.text.trim();
    if (name.isEmpty) {
      _snack('Nama wajib diisi');
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse(Api.completeSignup),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': _phone,
          'verify_token': _verifyToken,
          'full_name': name,
        }),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        await _saveSession(data['token'], data['data']);
        _goHome();
      } else {
        _snack(data['message'] ?? 'Gagal membuat akun');
      }
    } catch (_) {
      _snack('Gagal terhubung ke server');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSession(String? token, Map<String, dynamic> d) async {
    final prefs = await SharedPreferences.getInstance();
    final customerId = (d['customer_id'] is int)
        ? d['customer_id'] as int
        : int.tryParse('${d['customer_id']}') ?? 0;
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('telepon', d['phone'] ?? _phone);
    await prefs.setInt('customer_id', customerId);
    await prefs.setInt('pelanggan_id', customerId); // alias untuk kode lama
    await prefs.setString('customer_name', d['name'] ?? '');
    if (token != null) await prefs.setString('auth_token', token);
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(updateThemeMode: themeController.setMode),
      ),
      (route) => false,
    );
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final contentWidth = width > 600 ? 420.0 : width * 0.9;

    return Scaffold(
      appBar: _step != _Step.phone
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _step = _step == _Step.name ? _Step.otp : _Step.phone;
                }),
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: SizedBox(
              width: contentWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: contentWidth * 0.42,
                    height: contentWidth * 0.42,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.30),
                          blurRadius: 26,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset('assets/images/logo.png',
                        fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _step == _Step.name ? 'Lengkapi Nama' : 'Masuk ke BarberGo',
                    style: GoogleFonts.poppins(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _step == _Step.phone
                        ? 'Gunakan nomor telepon Anda'
                        : _step == _Step.otp
                            ? 'Masukkan kode OTP yang dikirim'
                            : 'Satu langkah lagi',
                    style: TextStyle(color: theme.hintColor),
                  ),
                  const SizedBox(height: 28),

                  if (_step == _Step.phone) _phoneStep(),
                  if (_step == _Step.otp) _otpStep(),
                  if (_step == _Step.name) _nameStep(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _phoneStep() {
    return Column(
      children: [
        TextField(
          controller: _phoneC,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Nomor Telepon',
            prefixText: '+62 ',
            hintText: '81234567890',
            prefixIcon: Icon(Icons.phone_android_rounded),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        _primaryButton(_loading ? 'Mengirim...' : 'Kirim OTP', _sendOtp),
      ],
    );
  }

  Widget _otpStep() {
    return Column(
      children: [
        if (_devCode != null) _devBanner(),
        TextField(
          controller: _otpC,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, letterSpacing: 6),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            counterText: '',
            hintText: '······',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        _primaryButton(_loading ? 'Memverifikasi...' : 'Verifikasi', _verifyOtp),
        TextButton(
          onPressed: _loading ? null : _sendOtp,
          child: const Text('Kirim ulang OTP'),
        ),
      ],
    );
  }

  Widget _nameStep() {
    return Column(
      children: [
        TextField(
          controller: _nameC,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama Lengkap',
            prefixIcon: Icon(Icons.person_rounded),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        _primaryButton(
            _loading ? 'Memproses...' : 'Selesai & Masuk', _completeSignup),
      ],
    );
  }

  Widget _devBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Mode tes — kode OTP: $_devCode',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => setState(() => _otpC.text = _devCode!),
            child: const Text('Isi otomatis'),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black))
            : Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}