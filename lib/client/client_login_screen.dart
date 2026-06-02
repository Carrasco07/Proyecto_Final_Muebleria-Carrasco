import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ClientLoginScreen extends StatefulWidget {
  const ClientLoginScreen({super.key});

  @override
  State<ClientLoginScreen> createState() => _ClientLoginScreenState();
}

class _ClientLoginScreenState extends State<ClientLoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Controllers for Login
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _isLoginLoading = false;

  // Controllers for Register
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regAddressController = TextEditingController();
  final _regPasswordController = TextEditingController();
  bool _isRegisterLoading = false;

  final Color azulGrisaceo = const Color(0xFF2C3E50);
  final Color grisSuave = const Color(0xFFF2F4F4);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _mostrarErrorAnimado(String mensaje, {bool isSuccess = false}) {
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
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1.2),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Text(
                      isSuccess ? "🎉" : "💀",
                      style: const TextStyle(fontSize: 80),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                isSuccess ? "¡FÉLICITACIONES!" : "¡ERROR!",
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold, 
                  fontSize: 18, 
                  color: isSuccess ? Colors.green : Colors.redAccent
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
                  child: Text(isSuccess ? "CONTINUAR" : "REINTENTAR", style: const TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loginCliente() async {
    final email = _loginEmailController.text.trim();
    final pass = _loginPasswordController.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _mostrarErrorAnimado("Por favor, llena todos los campos de acceso.");
      return;
    }

    setState(() => _isLoginLoading = true);
    try {
      final credentials = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
      
      // Validar si el usuario existe en la colección de 'cliente'
      final doc = await FirebaseFirestore.instance.collection('cliente').doc(credentials.user!.uid).get();
      if (!doc.exists) {
        // Si no existe, revisar si el correo coincide. Si no, denegar
        final snap = await FirebaseFirestore.instance.collection('cliente').where('correo', isEqualTo: email).get();
        if (snap.docs.isEmpty) {
          await FirebaseAuth.instance.signOut();
          _mostrarErrorAnimado("Esta cuenta no está registrada como cliente corporativo.");
          setState(() => _isLoginLoading = false);
          return;
        }
      }

      if (mounted) context.go('/client_dashboard');
    } on FirebaseAuthException catch (_) {
      _mostrarErrorAnimado("Correo electrónico o contraseña incorrectos.");
    } finally {
      if (mounted) setState(() => _isLoginLoading = false);
    }
  }

  Future<void> _registrarCliente() async {
    final name = _regNameController.text.trim();
    final email = _regEmailController.text.trim();
    final phone = _regPhoneController.text.trim();
    final address = _regAddressController.text.trim();
    final pass = _regPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || address.isEmpty || pass.isEmpty) {
      _mostrarErrorAnimado("Por favor, completa todos los campos del registro.");
      return;
    }

    setState(() => _isRegisterLoading = true);
    try {
      // 1. Crear el usuario en Firebase Auth
      final credentials = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
      final uid = credentials.user!.uid;

      // 2. Guardar en la colección 'cliente' en Firestore
      await FirebaseFirestore.instance.collection('cliente').doc(uid).set({
        'id': uid,
        'nombre': name,
        'correo': email,
        'telefono': phone,
        'direccion': address,
        'fecha_registro': DateTime.now().toString().substring(0, 10),
      });

      // 3. Crear notificación de bienvenida
      await FirebaseFirestore.instance.collection('notificaciones').add({
        'titulo': '🆕 Cliente Nuevo Registrado',
        'mensaje': 'El cliente "$name" se ha unido a Mueblería Carrasco desde el portal web.',
        'fecha': FieldValue.serverTimestamp(),
        'leido': false,
        'icono': 'person_add',
      });

      if (mounted) {
        _mostrarErrorAnimado("¡Cuenta de cliente creada exitosamente!", isSuccess: true);
        context.go('/client_dashboard');
      }
    } on FirebaseAuthException catch (e) {
      String errMsg = "Ocurrió un error inesperado al crear tu cuenta.";
      if (e.code == 'email-already-in-use') {
        errMsg = "Este correo electrónico ya está registrado.";
      } else if (e.code == 'weak-password') {
        errMsg = "La contraseña debe tener al menos 6 caracteres.";
      } else if (e.code == 'invalid-email') {
        errMsg = "El correo electrónico ingresado no es válido.";
      }
      _mostrarErrorAnimado(errMsg);
    } finally {
      if (mounted) setState(() => _isRegisterLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0B0C) : Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
          onPressed: () => context.go('/selection'),
          tooltip: 'Regresar',
        ),
        title: Text(
          "Bienvenido a Mueblería Carrasco",
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: azulGrisaceo,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber.shade200,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: "INICIAR SESIÓN", icon: Icon(Icons.login)),
            Tab(text: "CREAR CUENTA", icon: Icon(Icons.person_add_alt_1)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Vista 1: Login
          _buildLoginView(isDark),
          // Vista 2: Registro
          _buildRegisterView(isDark),
        ],
      ),
    );
  }

  Widget _buildLoginView(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_person_outlined, size: 70, color: isDark ? Colors.amber.shade200 : azulGrisaceo),
              const SizedBox(height: 15),
              Text(
                "¡Bienvenido de vuelta!",
                style: GoogleFonts.lora(fontSize: 20, fontStyle: FontStyle.italic, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 40),
              _buildField("Correo Electrónico", Icons.email_outlined, _loginEmailController, isDark),
              const SizedBox(height: 20),
              _buildField("Contraseña", Icons.lock_outline, _loginPasswordController, isDark, isPass: true),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azulGrisaceo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _isLoginLoading ? null : _loginCliente,
                  child: _isLoginLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("INGRESAR AL CATÁLOGO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterView(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.badge_outlined, size: 60, color: isDark ? Colors.amber.shade200 : azulGrisaceo),
              const SizedBox(height: 10),
              Text(
                "Regístrate como Cliente",
                style: GoogleFonts.lora(fontSize: 18, fontStyle: FontStyle.italic, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 35),
              _buildField("Nombre Completo", Icons.person_outline, _regNameController, isDark),
              const SizedBox(height: 16),
              _buildField("Correo Electrónico", Icons.email_outlined, _regEmailController, isDark),
              const SizedBox(height: 16),
              _buildField("Teléfono", Icons.phone_outlined, _regPhoneController, isDark),
              const SizedBox(height: 16),
              _buildField("Dirección de Envío", Icons.home_outlined, _regAddressController, isDark),
              const SizedBox(height: 16),
              _buildField("Elige una Contraseña", Icons.lock_outline, _regPasswordController, isDark, isPass: true),
              const SizedBox(height: 35),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azulGrisaceo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _isRegisterLoading ? null : _registrarCliente,
                  child: _isRegisterLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("CREAR CUENTA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, IconData icon, TextEditingController controller, bool isDark, {bool isPass = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: isDark ? Colors.amber.shade200 : azulGrisaceo),
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF95A5A6)),
        filled: true,
        fillColor: isDark ? const Color(0xFF161B22) : grisSuave,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}
