import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apkbarberon/auth/OnboardingScreen.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _slideUp = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 400),
                pageBuilder: (_, animation, __) =>
                    FadeTransition(opacity: animation, child: const OnboardingScreen()),
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF00D8FF);

    final size = MediaQuery.of(context).size;
    final boxSize = size.width * 0.45; // ukuran kotak/logo wrapper

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF02121A),
              Color(0xFF042A36),
              Color(0xFF003F57),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Opacity(
                opacity: _fade.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // LOGO: kotak putih + rounded besar (tidak memotong logo)
                    Transform.scale(
                      scale: _scale.value,
                      child: Container(
                        width: boxSize,
                        height: boxSize,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30), // <— Tidak memotong logo
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.30),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    SlideTransition(
                      position: _slideUp,
                      child: Column(
                        children: [
                          Text(
                            'BarberGo',
                            style: GoogleFonts.poppins(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Grooming made easy',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
