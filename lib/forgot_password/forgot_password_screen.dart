import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  TextEditingController emailController = TextEditingController();
  bool _isEmailValid = false;

  bool _isValidEmail(String email) {
    String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    RegExp regex = RegExp(emailPattern);
    return regex.hasMatch(email);
  }

  Future<void> sendResetPasswordRequest(String email) async {
  if (!_isValidEmail(email)) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Email tidak valid."),
      backgroundColor: Colors.red,
    ));
    return;
  }

  String baseURL = "http://192.168.1.8/Niceadmin/api/api_forgot_password.php";

  try {
    var response = await http.post(
      Uri.parse(baseURL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      var data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Kesalahan format respons dari server."),
          backgroundColor: Colors.red,
        ));
        return;
      }

      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Link reset password telah dikirim ke email anda."),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['message']),
          backgroundColor: Colors.red,
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: ${response.statusCode}"),
        backgroundColor: Colors.red,
      ));
    }
  } catch (e) {
    print('Exception: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Gagal menghubungi server."),
      backgroundColor: Colors.red,
    ));
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lupa Password', style: TextStyle(color: Color.fromARGB(255, 6, 1, 255))),
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : Colors.grey[900], 
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: const Color.fromARGB(255, 6, 1, 255)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: emailController,
              onChanged: (value) {
                setState(() {
                  _isEmailValid = _isValidEmail(value);
                });
              },
              decoration: InputDecoration(
                suffixIcon: _isEmailValid
                    ? Icon(Icons.check, color: Colors.green)
                    : Icon(Icons.check, color: Colors.red),
                prefixIcon: Icon(Icons.email,
                    color: Color.fromARGB(255, 23, 184, 23)),
                labelText: 'Email',
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 23, 184, 23),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color.fromARGB(255, 23, 184, 23)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color.fromARGB(255, 236, 236, 236)),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            Container(
              height: 55,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 255, 0, 0),
                    Color.fromARGB(255, 4, 0, 255),
                  ],
                ),
              ),
              child: TextButton(
                onPressed: () {
                  sendResetPasswordRequest(emailController.text);
                },
                child: const Text(
                  'Kirim Link Reset Password',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
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
