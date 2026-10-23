import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:apkbarberon/auth/login_page.dart';

class RegScreen extends StatefulWidget {
  final String phoneNumber;

  const RegScreen({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  _RegScreenState createState() => _RegScreenState();
}

class _RegScreenState extends State<RegScreen> {
  String email = '';
  String password = '';
  String confirmPassword = '';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isValidEmail(String email) {
    String polaEmail = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$';
    RegExp regex = RegExp(polaEmail);
    return regex.hasMatch(email);
  }

  Future<void> daftarUser(
      String email, String password, String confirmPassword, BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Daftar dengan Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pendaftaran berhasil, silahkan login'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Gagal mendaftar'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> daftarDenganGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Pendaftaran dibatalkan."),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login berhasil dengan akun Google."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Gagal mendaftar dengan Google."),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mendaftar dengan Google."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade800,
                  Colors.blue.shade600,
                  Colors.blue.shade400,
                ],
              ),
            ),
          ),

          _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SizedBox(height: 40),
                      // Logo
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.transparent,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: MediaQuery.of(context).size.width * 0.3,
                            width: MediaQuery.of(context).size.width * 0.3,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(height: 30),

                      // Title
                      Text(
                        'Daftar Akun Baru',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Isi data kamu untuk memulai',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 40),

                      // Form card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Email field
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(
                                    Icons.email,
                                    color: Colors.blue,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Mohon masukkan email';
                                  }
                                  if (!_isValidEmail(value)) {
                                    return 'Mohon masukkan email yang valid';
                                  }
                                  return null;
                                },
                                onChanged: (value) => email = value,
                              ),
                              SizedBox(height: 15),

                              // Password field
                              TextFormField(
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(
                                    Icons.lock,
                                    color: Colors.blue,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => setState(() =>
                                        _isPasswordVisible = !_isPasswordVisible),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Mohon masukkan password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password harus minimal 6 karakter';
                                  }
                                  return null;
                                },
                                onChanged: (value) => password = value,
                              ),
                              SizedBox(height: 15),

                              // Confirm Password field
                              TextFormField(
                                obscureText: !_isConfirmPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Konfirmasi Password',
                                  prefixIcon: Icon(
                                    Icons.lock,
                                    color: Colors.blue,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isConfirmPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => setState(() =>
                                        _isConfirmPasswordVisible =
                                            !_isConfirmPasswordVisible),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Mohon konfirmasi password';
                                  }
                                  if (value != password) {
                                    return 'Password tidak cocok';
                                  }
                                  return null;
                                },
                                onChanged: (value) => confirmPassword = value,
                              ),
                              SizedBox(height: 25),

                              // Register button
                              ElevatedButton(
                                onPressed: () => daftarUser(email, password,
                                    confirmPassword, context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  minimumSize: Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                ),
                                child: Text(
                                  'DAFTAR',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                              SizedBox(height: 25),

                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey.withOpacity(0.5),
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 15),
                                    child: Text(
                                      'ATAU',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey.withOpacity(0.5),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),

                              // Google sign up button
                              OutlinedButton.icon(
                                icon: Image.asset(
                                  'assets/icons/google-symbol.png',
                                  height: 24,
                                  width: 24,
                                ),
                                label: Text(
                                  'Daftar dengan Google',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                onPressed: daftarDenganGoogle,
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 30),
                      // Login prompt
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sudah punya akun? ',
                            style: TextStyle(color: Colors.white),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(),
                              ),
                            ),
                            child: Text(
                              'Masuk disini',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
