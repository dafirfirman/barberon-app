import 'dart:async';
import 'dart:convert';
import 'package:apkbarberon/page/location_picker.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:latlong2/latlong.dart' as latlong;

class CallPage extends StatefulWidget {
  final Map<String, dynamic> barber;

  const CallPage({Key? key, required this.barber}) : super(key: key);

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _fullName;
  late String _phoneNumber;
  String _countryCode = '+62';
  late String _notes;
  String _currentAddress = '';
  latlong.LatLng? _selectedLocation;
  int? _pelangganId;
  double _totalPrice = 0.0;
  double _basePrice = 0.0; // Harga pangkas dari barbers
  double _distanceFee = 0.0; // Biaya jarak
// Jarak dalam km
  
  // Service selection variables
  List<Map<String, dynamic>> _allServices = [];
  List<Map<String, dynamic>> _selectedServices = [];
  bool _isLoadingServices = false;
  bool _isLoadingOrder = false;

  @override
  void initState() {
    super.initState();
    _fullName = '';
    _phoneNumber = '';
    _notes = '';
    _loadPelangganId();
    _getCurrentLocation();
    _loadServices();
  }

  // Mendapatkan ID pelanggan dari SharedPreferences
  Future<void> _loadPelangganId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _pelangganId = prefs.getInt('customer_id');
    });
  }

  // Memuat layanan dari barber
  Future<void> _loadServices() async {
    setState(() {
      _isLoadingServices = true;
    });

    try {
      List<Map<String, dynamic>> services = [];
      
      // Ambil harga pangkas dari tabel barbers
      if (widget.barber['price'] != null && 
          double.tryParse(widget.barber['price'].toString()) != null) {
        _basePrice = double.tryParse(widget.barber['price'].toString()) ?? 0;
      } else if (widget.barber['harga_pangkas'] != null && 
          double.tryParse(widget.barber['harga_pangkas'].toString()) != null) {
        _basePrice = double.tryParse(widget.barber['harga_pangkas'].toString()) ?? 0;
      }
      
      // Tambahkan layanan lainnya dari tabel services (melalui API)
      if (widget.barber['layanan'] != null && widget.barber['layanan'] is List) {
        for (var service in widget.barber['layanan']) {
          if (service is Map) {
            services.add({
              'id': service['id'] ?? service['nama'],
              'nama': service['nama'] ?? '',
              'harga': double.tryParse(service['harga'].toString()) ?? 0,
              'kategori': service['kategori'] ?? '',
              'selected': false,
            });
          }
        }
      }
      
      setState(() {
        _allServices = services;
        _isLoadingServices = false;
      });
      _calculateTotalPrice();
    } catch (e) {
      setState(() {
        _isLoadingServices = false;
      });
      print('Error loading services: $e');
    }
  }

  // Toggle service selection
  void _toggleService(int index) {
    setState(() {
      _allServices[index]['selected'] = !_allServices[index]['selected'];
      
      if (_allServices[index]['selected']) {
        _selectedServices.add(_allServices[index]);
      } else {
        _selectedServices.removeWhere((s) => s['id'] == _allServices[index]['id']);
      }
      
      _calculateTotalPrice();
    });
  }

  // Mendapatkan lokasi saat ini
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _updateAddressFromCoordinates(position.latitude, position.longitude);
    } catch (e) {
      _showErrorSnackbar('Terjadi kesalahan saat mendapatkan lokasi: $e');
    }
  }

  // Mengupdate alamat berdasarkan koordinat
  Future<void> _updateAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress =
              "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
          _selectedLocation = latlong.LatLng(latitude, longitude);
        });
        _calculateTotalPrice();
      } else {
        _showErrorSnackbar('Tidak dapat menemukan alamat untuk koordinat ini.');
      }
    } catch (e) {
      _showErrorSnackbar('Terjadi kesalahan saat mendapatkan alamat: $e');
    }
  }

  // Membuka halaman peta untuk memilih lokasi
  Future<void> _openMap() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const LocationPickerPage(),
    ),
  );

  if (result != null && result is LocationResult) {
    setState(() {
      _selectedLocation = latlong.LatLng(
        result.latLng.latitude,
        result.latLng.longitude,
      );
      _currentAddress = result.address;
    });

    _calculateTotalPrice();
  }
}


  // Menghitung jarak antara dua koordinat
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // Hasilnya dalam kilometer
  }

  // Fungsi kalkulasi harga jarak saja
  double calculateDistanceFee(double distance) {
    if (distance <= 1) {
      return 20000; // Tambah Rp. 20.000 untuk jarak ≤ 1 km
    } else {
      // Tambah Rp. 20.000 + (distance - 1) * 10.000 untuk jarak > 1 km
      return 20000 + ((distance - 1) * 10000);
    }
  }

  // Menghitung total harga
  void _calculateTotalPrice() {
    if (_selectedLocation != null) {
      try {
        // Pastikan latitude dan longitude barber tidak null dan dapat dikonversi ke double
        if (widget.barber['latitude'] != null &&
            widget.barber['longitude'] != null) {
          // Menggunakan tryParse untuk konversi yang aman
          double barberLatitude =
              double.tryParse(widget.barber['latitude'].toString()) ?? 0.0;
          double barberLongitude =
              double.tryParse(widget.barber['longitude'].toString()) ?? 0.0;

          // Menghitung jarak antara lokasi pengguna dan pangkas rambut
          double distance = _calculateDistance(
            _selectedLocation!.latitude,
            _selectedLocation!.longitude,
            barberLatitude,
            barberLongitude,
          );

          // Simpan jarak untuk ditampilkan

          // Hitung biaya jarak
          _distanceFee = calculateDistanceFee(distance);

          // Hitung total harga dari layanan tambahan yang dipilih
          double additionalServicesPrice = 0;
          for (var service in _selectedServices) {
            additionalServicesPrice += service['harga'] ?? 0;
          }

          // Total = harga pangkas + biaya jarak + harga layanan tambahan
          setState(() {
            _totalPrice = _basePrice + _distanceFee + additionalServicesPrice;
          });

          // Debug print
          debugPrint('=== Harga Update ===');
          debugPrint('Harga Pangkas: $_formatHarga(_basePrice)');
          debugPrint('Jarak: ${distance.toStringAsFixed(1)} km');
          debugPrint('Biaya Jarak: $_formatHarga(_distanceFee)');
          debugPrint('Layanan Tambahan: $_formatHarga(additionalServicesPrice)');
          debugPrint('Total Harga: $_formatHarga(_totalPrice)');
        } else {
          _showErrorSnackbar('Koordinat pangkas rambut tidak valid.');
        }
      } catch (e) {
        // Menangani kesalahan konversi jika latitude atau longitude tidak valid
        _showErrorSnackbar('Terjadi kesalahan saat menghitung harga: $e');
      }
    } else {
      _showErrorSnackbar('Lokasi Anda tidak valid.');
    }
  }

  // Menampilkan pesan error
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Memproses pemesanan layanan
  Future<void> _orderService() async {
    try {
      if (_fullName.isEmpty || _phoneNumber.isEmpty) {
        throw Exception('Silakan lengkapi semua informasi yang diperlukan');
      }

      if (_pelangganId == null) {
        throw Exception('ID pelanggan tidak ditemukan');
      }

      final int barberId = int.parse(widget.barber['id'].toString());
      final int customerId = _pelangganId!;

      // Format layanan yang dipilih untuk dikirim ke API
      List<Map<String, dynamic>> formattedServices = _selectedServices.map((service) {
        return {
          'service_id': service['id'],
          'nama': service['nama'],
          'harga': service['harga'],
          'kategori': service['kategori'],
        };
      }).toList();

      setState(() {
        _isLoadingOrder = true;
      });

      final response = await http.post(
        Uri.parse('http://192.168.1.5/Niceadmin/barbergo/api_order.php'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'customer_id': customerId,
          'barber_id': barberId,
          'customer_name': _fullName,
          'customer_phone': '$_countryCode$_phoneNumber',
          'service_address': _currentAddress,
          'latitude': _selectedLocation?.latitude,
          'longitude': _selectedLocation?.longitude,
          'note': _notes,
          'total_price': _totalPrice,
          'layanan': formattedServices, // Kirim layanan tambahan yang dipilih
          'base_price': _basePrice, // Kirim harga pangkas
          'distance_fee': _distanceFee, // Kirim biaya jarak
        }),
      );

      setState(() {
        _isLoadingOrder = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          _showErrorSnackbar('Pemesanan berhasil');
          Navigator.pop(context);
        } else {
          throw Exception(responseData['message'] ?? 'Pemesanan gagal');
        }
      } else {
        throw Exception('Pemesanan gagal. Coba lagi.');
      }
    } catch (e) {
      setState(() {
        _isLoadingOrder = false;
      });
      _showErrorSnackbar('Terjadi kesalahan saat memesan layanan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Hitung jarak untuk ditampilkan
    double? distance;
    if (_selectedLocation != null &&
        widget.barber['latitude'] != null &&
        widget.barber['longitude'] != null) {
      double barberLatitude =
          double.tryParse(widget.barber['latitude'].toString()) ?? 0.0;
      double barberLongitude =
          double.tryParse(widget.barber['longitude'].toString()) ?? 0.0;
      distance = _calculateDistance(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
        barberLatitude,
        barberLongitude,
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : Colors.grey[900],
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Detail Pemanggilan',
          style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tampilkan foto, nama, dan alamat pangkas rambut
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipOval(
                    child: Container(
                      width: 50,
                      height: 50,
                      child: widget.barber['foto'] != null
                          ? Image.network(
                              widget.barber['foto'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.person, size: 50);
                              },
                            )
                          : Image.asset(
                              'assets/images/logo_pangkas.png',
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  title: Text(
                    widget.barber['barber_name'] ?? '',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.barber['address'] ?? '',
                          style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black)),
                      SizedBox(height: 5),
                      Text(widget.barber['phone'] ?? '',
                          style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black)),
                      SizedBox(height: 10),
                      RatingBar.builder(
                        initialRating:
                            double.parse(widget.barber['rating'].toString()),
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemSize: 10.0,
                        itemBuilder: (context, _) =>
                            Icon(Icons.star, color: Colors.amber),
                        onRatingUpdate: (rating) {
                          setState(() {
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Divider(color: isDarkMode ? Colors.white : Colors.black),
              ],
            ),
            
            // Harga Dasar + Biaya Panggilan
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harga Dasar',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black),
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Harga Pangkas:',
                            style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white : Colors.black),
                          ),
                          Text(
                            _formatHarga(_basePrice),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black),
                          ),
                        ],
                      ),
                      if (distance != null) ...[
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              distance <= 1 
                                  ? 'Biaya Panggilan (≤1 km):'
                                  : 'Biaya Panggilan (${distance.toStringAsFixed(1)} km):',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.white : Colors.black),
                            ),
                            Text(
                              distance <= 1 
                                  ? _formatHarga(20000)
                                  : _formatHarga(20000 + ((distance - 1) * 10000)),
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 8),
                      Divider(color: theme.primaryColor),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal:',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor),
                          ),
                          Text(
                            _formatHarga(_basePrice + _distanceFee),
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(color: isDarkMode ? Colors.white : Colors.black),
              ],
            ),
            
            // Pemilihan Layanan Tambahan
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Layanan Tambahan (Opsional)',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black),
                ),
                SizedBox(height: 10),
                _isLoadingServices
                    ? Center(child: CircularProgressIndicator())
                    : _allServices.isEmpty
                        ? Text('Tidak ada layanan tambahan tersedia',
                            style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black))
                        : Column(
                            children: _allServices.asMap().entries.map((entry) {
                              int index = entry.key;
                              Map<String, dynamic> service = entry.value;
                              bool isSelected = service['selected'] ?? false;
                              
                              return Container(
                                margin: EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected 
                                        ? theme.primaryColor 
                                        : (isDarkMode ? Colors.grey : Colors.grey.shade300),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: isSelected 
                                      ? theme.primaryColor.withOpacity(0.1)
                                      : (isDarkMode ? Colors.grey.shade800 : Colors.white),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  title: Text(
                                    service['nama'] ?? '',
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected 
                                          ? theme.primaryColor 
                                          : (isDarkMode ? Colors.white : Colors.black),
                                    ),
                                  ),
                                  subtitle: Text(
                                    _formatHarga(service['harga'] ?? 0),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected 
                                          ? theme.primaryColor 
                                          : (isDarkMode ? Colors.white : Colors.black),
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? Icon(Icons.check_circle, color: theme.primaryColor)
                                      : Icon(Icons.radio_button_unchecked,
                                          color: isDarkMode ? Colors.white : Colors.black),
                                  onTap: () => _toggleService(index),
                                ),
                              );
                            }).toList(),
                          ),
                Divider(color: isDarkMode ? Colors.white : Colors.black),
              ],
            ),
            
            // Total Harga Akhir
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Pembayaran:',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor),
                  ),
                  Text(
                    _formatHarga(_totalPrice),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            
            // Tampilkan alamat pengguna
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Alamat Anda',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black),
                ),
                TextButton(
                  onPressed: _openMap,
                  child: Text('Ubah Alamat',
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black)),
                ),
              ],
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alamat Lengkap:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white70 : Colors.black54),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _currentAddress.isEmpty
                        ? 'Memilih lokasi...'
                        : _currentAddress,
                    style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            
            // Form input data pemanggilan
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        border: UnderlineInputBorder(),
                        filled: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan nama lengkap';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _fullName = value;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: _countryCode,
                          decoration: InputDecoration(
                              labelText: 'Kode Negara',
                              border: OutlineInputBorder(),
                              filled: true,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10)),
                          onChanged: (value) {
                            setState(() {
                              _countryCode = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        flex: 5,
                        child: TextFormField(
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                              labelText: 'Nomor Telepon',
                              border: UnderlineInputBorder(),
                              filled: true,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10)),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Masukkan nomor telepon';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              _phoneNumber = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    maxLines: 3,
                    decoration: InputDecoration(
                        labelText: 'Catatan (opsional)',
                        border: OutlineInputBorder(),
                        filled: true,
                        contentPadding: EdgeInsets.all(10)),
                    onChanged: (value) {
                      setState(() {
                        _notes = value;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 40,
                        width: 100,
                        child: _isLoadingOrder
                            ? Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    _orderService();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 26, 192, 101),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text('Panggil',
                                    style:
                                        TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatHarga(double harga) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(harga);
  }
}