// lib/services/api_config.dart
//
// SATU tempat alamat server. Semua endpoint PHP ada di SATU folder: barbergo/.
// Kalau IP berubah (pindah WiFi), cukup ubah baris kServer di bawah.

const String kServer = 'https://lightblue-jackal-936139.hostingersite.com/Niceadmin';
const String kBaseUrl = '$kServer/barbergo';

/// Semua endpoint cukup: '$kBaseUrl/<nama_file>.php'
class Api {
  // Auth (OTP WhatsApp)
  static const String sendOtp        = '$kBaseUrl/customer_send_otp.php';
  static const String verifyOtp      = '$kBaseUrl/customer_verify_otp.php';
  static const String completeSignup = '$kBaseUrl/customer_complete_signup.php';

  // Beranda & pencarian
  static const String rekomendasi = '$kBaseUrl/api_rekomendasi.php';
  static const String search      = '$kBaseUrl/api_search.php';
  static const String barberDetail = '$kBaseUrl/customer_barber_detail.php';

  // Pemesanan
  static const String order = '$kBaseUrl/api_order.php';
  static const String orderStatus = '$kBaseUrl/customer_order_status.php';

  // Pembayaran online (Midtrans)
  static const String createPayment = '$kBaseUrl/create_payment.php';
  static const String checkPayment  = '$kBaseUrl/check_payment.php';

  // Chat (per order_id)
  static const String chatList    = '$kBaseUrl/customer_get_chats.php';
  static const String getMessages = '$kBaseUrl/customer_get_messages.php';
  static const String sendMessage = '$kBaseUrl/customer_send_message.php';

  // Notifikasi / pesanan saya
  static const String myOrders = '$kBaseUrl/customer_get_orders.php';
  static const String submitRating = '$kBaseUrl/customer_submit_rating.php';
  static const String customerNotifications = '$kBaseUrl/getCustomerNotifications.php';
  static const String deleteNotification    = '$kBaseUrl/deleteNotification.php';

  // Profil
  static const String updateProfile      = '$kBaseUrl/customer_update_profile.php';
}