import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  static const String _email = 'barberon2102@gmail.com';
  static const String _phone = '+62 813 6645 1989';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text('Bantuan',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pertanyaan yang Sering Diajukan',
                style: GoogleFonts.poppins(
                    fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  _faqItem(
                    theme,
                    'Bagaimana cara memesan jasa pangkas?',
                    'Buka beranda atau halaman Cari, pilih tukang pangkas yang sedang online, '
                        'centang layanan yang diinginkan, lalu tekan "Pesan" dan konfirmasi.',
                  ),
                  _faqItem(
                    theme,
                    'Bagaimana cara melacak tukang pangkas?',
                    'Setelah pesanan diterima, halaman peta akan terbuka otomatis. '
                        'Anda bisa melihat posisi tukang bergerak real-time beserta jarak dan estimasi waktu tiba. '
                        'Bisa juga dibuka lewat menu "Pesanan Saya".',
                  ),
                  _faqItem(
                    theme,
                    'Bagaimana cara pembayaran?',
                    'Saat ini pembayaran dilakukan secara tunai setelah layanan selesai. '
                        'Pembayaran online akan tersedia menyusul.',
                  ),
                  _faqItem(
                    theme,
                    'Bagaimana cara membatalkan pesanan?',
                    'Pesanan tidak dapat dibatalkan dari sisi pelanggan. Pembatalan hanya bisa '
                        'dilakukan oleh tukang pangkas dengan alasan tertentu.',
                  ),
                  _faqItem(
                    theme,
                    'Apakah ada biaya pembatalan?',
                    'Tidak ada biaya pembatalan apabila pesanan dibatalkan oleh tukang pangkas.',
                  ),
                  _faqItem(
                    theme,
                    'Di mana melihat riwayat pesanan?',
                    'Semua pesanan yang sudah selesai, dibatalkan, atau ditolak ada di menu "History". '
                        'Riwayat juga bisa dihapus dengan menggeser kartunya.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showContactDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.support_agent),
                label: Text('Hubungi Kami',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faqItem(ThemeData theme, String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          iconColor: theme.colorScheme.primary,
          title: Text(question,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(answer,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: theme.hintColor, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Hubungi Kami',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.phone, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                  child: SelectableText(_phone,
                      style: GoogleFonts.poppins(fontSize: 14))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.email_outlined,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                  child: SelectableText(_email,
                      style: GoogleFonts.poppins(fontSize: 14))),
            ]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Tutup',
                style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
    );
  }
}