import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Paleta de colores Premium
    const Color azulGrisaceo = Color(0xFF2C3E50);
    const Color grisFondo = Color(0xFFF8F9F9);

    return Scaffold(
      backgroundColor: grisFondo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.go('/login'), 
            icon: const Icon(Icons.logout_rounded, color: azulGrisaceo)
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- TARJETA DE BIENVENIDA CENTRADA (Estilo "Grimorio" mejorado) ---
              LayoutBuilder(
                builder: (context, constraints) {
                  double screenWidth = MediaQuery.of(context).size.width;
                  double cardWidth = screenWidth < 600 ? screenWidth * 0.9 : screenWidth * 0.6;
                  
                  return Container(
                    width: cardWidth,
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Icono distintivo de la marca
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: azulGrisaceo.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chair_outlined, size: 50, color: azulGrisaceo),
                        ),
                        const SizedBox(height: 25),
                        Text(
                          "Bienvenido al Panel de Gestión",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: azulGrisaceo,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "Administra el catálogo de Mueblería Carrasco de forma eficiente y rápida.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.blueGrey.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 35),
                        
                        // BOTÓN DE ACCIÓN PRINCIPAL (Ir a Productos)
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: azulGrisaceo,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 0,
                            ),
                            onPressed: () => context.go('/inventario'),
                            icon: const Icon(Icons.inventory_2_outlined, color: Colors.white),
                            label: const Text(
                              "GESTIONAR INVENTARIO",
                              style: TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              ),
              
              const SizedBox(height: 40),
              
              // TEXTO DE APOYO INFERIOR
              Text(
                "MUEBLERÍA CARRASCO v1.0",
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  color: azulGrisaceo.withOpacity(0.4),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}