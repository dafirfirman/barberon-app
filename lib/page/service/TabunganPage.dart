import 'package:flutter/material.dart';

class TabunganPage extends StatelessWidget {
  final int pelangganId;

  const TabunganPage({Key? key, required this.pelangganId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tabungan'),
      ),
      body: Center(
        child: Text('Halaman Tabungan untuk Pelanggan ID: $pelangganId'),
      ),
    );
  }
}
