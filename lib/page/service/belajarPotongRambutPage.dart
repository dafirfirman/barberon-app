import 'package:flutter/material.dart';

class BelajarPotongRambutPage extends StatelessWidget {
  final int pelangganId;

  const BelajarPotongRambutPage({Key? key, required this.pelangganId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Belajar Potong Rambut'),
      ),
      body: Center(
        child: Text('Halaman Belajar Potong Rambut untuk Pelanggan ID: $pelangganId'),
      ),
    );
  }
}