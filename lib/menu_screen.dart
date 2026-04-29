import 'package:flutter/material.dart';
import 'inventario_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mueblería Carrasco")),
      body: Center(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20), backgroundColor: Colors.brown),
          icon: const Icon(Icons.table_bar, color: Colors.white),
          label: const Text("GESTIONAR MUEBLES", style: TextStyle(color: Colors.white, fontSize: 18)),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InventarioScreen())),
        ),
      ),
    );
  }
}