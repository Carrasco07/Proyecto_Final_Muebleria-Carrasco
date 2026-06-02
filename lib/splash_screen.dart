import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';

class PantallaSplash extends StatefulWidget {
  const PantallaSplash({super.key});

  @override
  State<PantallaSplash> createState() => _PantallaSplashState();
}

class _PantallaSplashState extends State<PantallaSplash> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    final startTime = DateTime.now();

    try {
      // Inicializar Firebase en segundo plano sin congelar la app
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint("Error al inicializar Firebase: $e");
    }

    try {
      // Inicializar formato de fechas local
      await initializeDateFormatting('es_MX', null);
      Intl.defaultLocale = 'es_MX';
    } catch (e) {
      debugPrint("Error al inicializar localización: $e");
    }

    final elapsed = DateTime.now().difference(startTime);
    const minimumDuration = Duration(seconds: 4);

    if (elapsed < minimumDuration) {
      await Future.delayed(minimumDuration - elapsed);
    }

    if (mounted) {
      context.go('/selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definimos nuestra paleta Minimalista Premium
    const Color azulGrisaceo = Color(0xFF2C3E50); 
    const Color blancoPuro = Colors.white;

    return Scaffold(
      backgroundColor: azulGrisaceo, // Fondo ahora es Azul Grisáceo
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Letra "M" Gigante con estilo elegante
            Text(
              'M',
              style: GoogleFonts.playfairDisplay(
                fontSize: 120,
                fontWeight: FontWeight.bold,
                color: blancoPuro, // Cambio a Blanco
              ),
            ),
            const SizedBox(height: 10),
            // Nombre de la marca con tipografía Serif fina
            Text(
              'Mueblería Carrasco',
              style: GoogleFonts.lora(
                fontSize: 26,
                color: blancoPuro, // Cambio a Blanco
                fontStyle: FontStyle.italic,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 50),
            // Indicador de carga estilizado y delgado
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(blancoPuro),
              ),
            ),
          ],
        ),
      ),
    );
  }
}