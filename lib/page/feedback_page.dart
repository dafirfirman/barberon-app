import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FeedbackPage extends StatefulWidget {
  final int bookingId;

  const FeedbackPage({Key? key, required this.bookingId}) : super(key: key);

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  double _rating = 0;
  TextEditingController _feedbackController = TextEditingController();

  Future<void> _submitRating() async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.5/Niceadmin/api/submitRating.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'booking_id': widget.bookingId,
          'rating': _rating,
          'feedback': _feedbackController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Penilaian berhasil dikirim')),
          );
          Navigator.of(context).pop();
        } else {
          _showErrorDialog(data['message'] ?? 'Gagal mengirim penilaian');
        }
      } else {
        _showErrorDialog('Gagal mengirim penilaian. Kode status: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Exception: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Kesalahan'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Beri Penilaian', style: TextStyle(fontWeight: FontWeight.bold),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            TextField(
              controller: _feedbackController,
              decoration: InputDecoration(hintText: 'Berikan feedback'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitRating,
              child: Text('Kirim'),
            ),
          ],
        ),
      ),
    );
  }
}
