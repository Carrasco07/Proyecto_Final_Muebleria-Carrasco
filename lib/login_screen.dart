import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:lottie/lottie.dart'; // Removido por no usarse
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Colores del Proyecto
  final Color azulGrisaceo = const Color(0xFF2C3E50);
  final Color grisSuave = const Color(0xFFF2F4F4);

  // --- FUNCIÓN DE ERROR CON ANIMACIÓN ---
  void _mostrarErrorAnimado(String mensaje) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animación de calavera nativa en Flutter (sin depender de LottieFiles)
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1.2),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: const Text(
                      "💀",
                      style: TextStyle(fontSize: 80),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                "¡ACCESO DENEGADO!",
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold, 
                  fontSize: 18, 
                  color: Colors.redAccent
                ),
              ),
              const SizedBox(height: 10),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF7F8C8D)),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azulGrisaceo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("REINTENTAR", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) context.go('/menu');
    } on FirebaseAuthException catch (_) {
      _mostrarErrorAnimado("Las credenciales ingresadas son incorrectas.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenHeight = constraints.maxHeight;
          bool isShort = screenHeight < 600;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono de administración premium y estilizado
                  Container(
                    padding: EdgeInsets.all(isShort ? 15 : 25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: azulGrisaceo.withOpacity(0.15),
                          blurRadius: 25,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: EdgeInsets.all(isShort ? 12 : 20),
                      decoration: BoxDecoration(
                        color: azulGrisaceo.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: isShort ? 45 : 70, 
                        color: azulGrisaceo,
                      ),
                    ),
                  ),
                  SizedBox(height: isShort ? 10 : 20),
                  Text(
                    "ADMINISTRACIÓN",
                    style: GoogleFonts.montserrat(
                      letterSpacing: 4, 
                      fontWeight: FontWeight.bold, 
                      color: azulGrisaceo,
                      fontSize: isShort ? 12 : 14,
                    ),
                  ),
                  SizedBox(height: isShort ? 25 : 50),
                  _buildTextField("Correo", Icons.email_outlined, _emailController),
                  const SizedBox(height: 20),
                  _buildTextField("Contraseña", Icons.lock_outline, _passwordController, isPass: true),
                  SizedBox(height: isShort ? 20 : 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azulGrisaceo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("ENTRAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isPass = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: azulGrisaceo),
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF95A5A6)),
        filled: true,
        fillColor: grisSuave,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}