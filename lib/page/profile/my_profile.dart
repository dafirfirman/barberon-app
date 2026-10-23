import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class MyProfile extends StatefulWidget {
  final String email;

  const MyProfile({Key? key, required this.email}) : super(key: key);

  @override
  _MyProfileState createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  String? _nama;
  String? _nomorTelepon;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    final response = await http.get(
      Uri.parse("http://192.168.1.13/Niceadmin/api/api_get_user_data.php?email=${widget.email}"),
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      setState(() {
        _nama = userData['data']['nama'];
        _nomorTelepon = userData['data']['telp'];
      });
      
    } else {
      throw Exception('Failed to load user data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        backgroundColor: Color.fromARGB(255, 252, 214, 3),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nama: ${_nama ?? 'Loading...'}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Telepon: ${_nomorTelepon ?? 'Loading...'}',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
