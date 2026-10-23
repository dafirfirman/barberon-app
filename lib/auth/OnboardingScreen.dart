import 'package:flutter/material.dart';
import 'package:apkbarberon/auth/login_page.dart';
import 'package:apkbarberon/auth/get_started_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Brand colours
    const Color primary = Color(0xFF00D8FF); // tosca
    const Color bgStart = Color(0xFF02121A);
    const Color bgMid = Color(0xFF042A36);
    const Color bgEnd = Color(0xFF003F57);

    final media = MediaQuery.of(context);
    final deviceH = media.size.height;
    final deviceW = media.size.width;
    final textScale = media.textScaleFactor.clamp(1.0, 1.3);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgStart, bgMid, bgEnd],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            // limit width for very wide screens (tablet)
            final maxWidth = constraints.maxWidth > 800 ? 700.0 : constraints.maxWidth;
            // adaptive sizing
            final logoWrapper = (maxWidth * 0.46).clamp(120.0, 320.0);
            final logoImage = logoWrapper * 0.64;
            final titleSize = (maxWidth / 12).clamp(20.0, 38.0) * (1 / textScale);
            final subtitleSize = (maxWidth / 28).clamp(12.0, 18.0) * (1 / textScale);
            final verticalPadding = (deviceH * 0.04).clamp(12.0, 36.0);

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: maxWidth * 0.07, vertical: verticalPadding),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // decorative blobs (behind) - using stack with overflow hidden on small screens
                        SizedBox(
                          height: deviceH * 0.02,
                        ),

                        // logo + title + description
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo wrapper (rounded rect so logo never gets cut)
                            Container(
                              width: logoWrapper,
                              height: logoWrapper,
                              padding: EdgeInsets.all(logoWrapper * 0.16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withOpacity(0.24),
                                    blurRadius: 30,
                                    offset: const Offset(0, 12),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: logoImage,
                                  height: logoImage,
                                  fit: BoxFit.contain,
                                  semanticLabel: 'BarberGo logo',
                                ),
                              ),
                            ),

                            SizedBox(height: deviceH * 0.03),

                            // Title
                            Text(
                              'BarberGo',
                              style: GoogleFonts.poppins(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),

                            SizedBox(height: deviceH * 0.015),

                            // Subtitle / description
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: maxWidth * 0.06),
                              child: Text(
                                'Nikmati kemudahan memesan jasa pangkas rambut kapan saja, dengan tukang profesional yang siap melayani.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: subtitleSize,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: deviceH * 0.05),

                        // Buttons (responsive)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginPage()),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: Colors.white.withOpacity(0.14)),
                                  padding: EdgeInsets.symmetric(vertical: deviceH * 0.018),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  'Lewati',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: (subtitleSize * 1.02).clamp(13.0, 16.0),
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: deviceW * 0.03),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const GetStartedScreen()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.black87,
                                  padding: EdgeInsets.symmetric(vertical: deviceH * 0.018),
                                  elevation: 8,
                                  shadowColor: primary.withOpacity(0.45),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Lanjut',
                                      style: GoogleFonts.poppins(
                                        fontSize: (subtitleSize * 1.02).clamp(13.0, 16.0),
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: (subtitleSize * 1.02).clamp(14.0, 18.0), color: Colors.black87),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: deviceH * 0.02),

                        // Tiny hint text
                        Text(
                          'Dengan melanjutkan, Anda menyetujui Syarat & Ketentuan kami.',
                          style: GoogleFonts.poppins(fontSize: (subtitleSize * 0.85).clamp(11.0, 13.0), color: Colors.white38),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: deviceH * 0.01),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
