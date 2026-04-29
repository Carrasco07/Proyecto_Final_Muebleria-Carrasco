import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart'; // Asegúrate de haber hecho 'flutter pub get'
import 'menu_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // VENTANA EMERGENTE CON LA CALAVERITA 💀
  void _mostrarErrorCalaverita(String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animación de calaverita (vía URL para no ocupar espacio en assets)
            Lottie.network(
              'https://assets9.lottiefiles.com/packages/lf20_T68Y4h.json',
              height: 180,
              repeat: true,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red, size: 80),
            ),
            const SizedBox(height: 15),
            const Text(
              "¡ACCESO DENEGADO!",
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(context),
              child: const Text("REINTENTAR", style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // FUNCIÓN PARA VALIDAR CONTRA FIREBASE
  Future<void> _login() async {
    // 1. Validar campos vacíos
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _mostrarErrorCalaverita("¡No puedes dejar campos vacíos! Rellena todo o no entras.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Intentar autenticar
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 3. Si es correcto, ir al menú de Mueblería Carrasco
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MenuScreen()),
        );
      }
    } on FirebaseAuthException catch (_) {
      // 4. Si los datos están mal, sale la calaverita
      _mostrarErrorCalaverita("Credenciales incorrectas. Solo admins de Mueblería Carrasco. 💀");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const Icon(Icons.admin_panel_settings, size: 100, color: Colors.brown),
              const SizedBox(height: 10),
              const Text(
                "Mueblería Carrasco",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.brown),
              ),
              const Text("Acceso Administrativo", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 50),
              
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Correo Electrónico",
                  prefixIcon: const Icon(Icons.email, color: Colors.brown),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  prefixIcon: const Icon(Icons.lock, color: Colors.brown),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "ENTRAR",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}