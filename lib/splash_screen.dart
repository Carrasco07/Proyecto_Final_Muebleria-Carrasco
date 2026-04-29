import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Salto al login tras 3 segundos
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const LoginScreen())
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chair_outlined, size: 100, color: Colors.brown),
            const SizedBox(height: 20),
            const Text(
              "Mueblería Carrasco",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.brown),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(color: Colors.brown),
          ],
        ),
      ),
    );
  }
}