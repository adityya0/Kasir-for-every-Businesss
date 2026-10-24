import 'package:flutter/material.dart';

const colorbase = Color(0xFFC0392B);

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorbase,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: colorbase,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo/logo.png',
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 30),
                const Text(
                  "Memuat Aplikasi...",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

