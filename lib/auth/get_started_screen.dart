// lib/auth/get_started_screen.dart
import 'package:flutter/material.dart';
import 'package:apkbarberon/auth/login_page.dart';
import 'package:google_fonts/google_fonts.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Brand colours
    const Color primary = Color(0xFF00D8FF); // Tosca BarberGo
    const Color bgStart = Color(0xFF02121A);
    const Color bgMid = Color(0xFF042A36);
    const Color bgEnd = Color(0xFF003F57);

    final media = MediaQuery.of(context);
    final deviceH = media.size.height;
    final textScale = media.textScaleFactor.clamp(1.0, 1.25);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgStart, bgMid, bgEnd],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth > 800 ? 700.0 : constraints.maxWidth;
              // gunakan toDouble() karena clamp mengembalikan num
              final wrapperSize = (maxWidth * 0.46).clamp(130.0, 300.0).toDouble();
              final logoSize = (wrapperSize * 0.65).toDouble();

              final titleSize = (maxWidth / 12).clamp(20.0, 34.0) * (1 / textScale);
              final descSize = (maxWidth / 28).clamp(12.0, 16.0) * (1 / textScale);

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: maxWidth * 0.07,
                      vertical: deviceH * 0.045,
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // LOGO WRAPPER (tidak memotong logo)
                          Container(
                            width: wrapperSize,
                            height: wrapperSize,
                            padding: EdgeInsets.all((wrapperSize * 0.16).toDouble()),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24.0),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withOpacity(0.25),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: logoSize,
                              height: logoSize,
                              fit: BoxFit.contain,
                            ),
                          ),

                          SizedBox(height: deviceH * 0.035),

                          // TITLE
                          Text(
                            'BarberGo',
                            style: GoogleFonts.poppins(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),

                          SizedBox(height: deviceH * 0.014),

                          // SUBTITLE
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: maxWidth * 0.05),
                            child: Text(
                              'Tingkatkan penampilanmu dengan layanan pangkas profesional — cepat, mudah, dan terpercaya.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: descSize,
                                color: Colors.white70,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          SizedBox(height: deviceH * 0.06),

                          // ONE BUTTON ONLY
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginPage()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.black87,
                                padding: EdgeInsets.symmetric(vertical: deviceH * 0.02),
                                elevation: 8,
                                shadowColor: primary.withOpacity(0.45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.0),
                                ),
                              ),
                              child: Text(
                                'Mulai Sekarang',
                                style: GoogleFonts.poppins(
                                  fontSize: (descSize * 1.1).clamp(14.0, 18.0),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: deviceH * 0.02),

                          // Tiny disclaimer
                          Text(
                            'Dengan melanjutkan, Anda menyetujui ketentuan kami.',
                            style: GoogleFonts.poppins(
                              fontSize: (descSize * 0.85).clamp(11.0, 13.0),
                              color: Colors.white38,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: deviceH * 0.015),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
