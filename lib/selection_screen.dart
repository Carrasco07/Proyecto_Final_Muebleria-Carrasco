import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color azulGrisaceo = Color(0xFF2C3E50);
    const Color grisFondo = Color(0xFFEDEFF2);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0B0C) : grisFondo,
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenHeight = constraints.maxHeight;
          bool isShort = screenHeight < 600;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Icono principal de Mueblería Carrasco
                  Container(
                    padding: EdgeInsets.all(isShort ? 20 : 35),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161B22) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: azulGrisaceo.withOpacity(isDark ? 0.4 : 0.1),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 15),
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
                        Icons.chair_outlined,
                        size: isShort ? 50 : 80,
                        color: isDark ? Colors.amber.shade200 : azulGrisaceo,
                      ),
                    ),
                  ),
                  SizedBox(height: isShort ? 20 : 40),
                  // Título Principal
                  Text(
                    "Mueblería Carrasco",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: isShort ? 28 : 36,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : azulGrisaceo,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Muebles exclusivos con estilo y distinción",
                    style: GoogleFonts.lora(
                      fontSize: isShort ? 12 : 14,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.grey : Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: isShort ? 30 : 60),
                  // Botón 1: Administrador
                  _buildOptionButton(
                    context: context,
                    label: "INICIAR SESIÓN COMO ADMINISTRADOR",
                    icon: Icons.admin_panel_settings,
                    color: azulGrisaceo,
                    textColor: Colors.white,
                    onTap: () => context.push('/login'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  // Botón 2: Cliente
                  _buildOptionButton(
                    context: context,
                    label: "INICIAR SESIÓN COMO CLIENTE",
                    icon: Icons.people_outline,
                    color: isDark ? const Color(0xFF161B22) : Colors.white,
                    textColor: isDark ? Colors.amber.shade200 : azulGrisaceo,
                    borderColor: isDark ? Colors.amber.shade200.withOpacity(0.3) : azulGrisaceo.withOpacity(0.2),
                    onTap: () => context.push('/client_login'),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    Color? borderColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      height: 65,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          side: borderColor != null ? BorderSide(color: borderColor, width: 1.5) : BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, size: 24, color: textColor),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  letterSpacing: 0.8,
                  color: textColor,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: textColor.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}
