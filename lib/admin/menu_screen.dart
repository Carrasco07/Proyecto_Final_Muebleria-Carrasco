import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isSuperAdmin = false;
  Map<String, bool> _permissions = {
    'clientes': false,
    'pedidos': false,
    'detalle_pedido': false,
    'empleados': false,
    'productos': false,
    'categorias': false,
    'proveedores': false,
    'inventario': false,
    'almacenes': false,
    'facturas': false,
    'pagos': false,
  };
  final Color azulProfundo = const Color(0xFF2C3E50);

  final List<Map<String, dynamic>> modulos = [
    {'titulo': 'Dashboard', 'icono': Icons.dashboard_rounded, 'color': Colors.blueGrey, 'ruta': '/gestion/dashboard', 'permKey': null},
    {'titulo': 'Productos', 'icono': Icons.chair, 'color': Colors.blue, 'ruta': '/gestion/productos', 'permKey': 'productos'},
    {'titulo': 'Categorías', 'icono': Icons.category, 'color': Colors.indigo, 'ruta': '/gestion/categoria', 'permKey': 'categorias'},
    {'titulo': 'Proveedores', 'icono': Icons.local_shipping, 'color': Colors.purple, 'ruta': '/gestion/proveedor', 'permKey': 'proveedores'},
    {'titulo': 'Almacenes', 'icono': Icons.warehouse, 'color': Colors.brown, 'ruta': '/gestion/almacen', 'permKey': 'almacenes'},
    {'titulo': 'Inventario', 'icono': Icons.storage, 'color': Colors.cyan, 'ruta': '/gestion/inventario', 'permKey': 'inventario'},
    {'titulo': 'Pedidos', 'icono': Icons.assignment, 'color': Colors.red, 'ruta': '/gestion/pedido', 'permKey': 'pedidos'},
    {'titulo': 'Detalle Pedido', 'icono': Icons.list_alt, 'color': Colors.orange, 'ruta': '/gestion/detalle_pedido', 'permKey': 'detalle_pedido'},
    {'titulo': 'Facturas', 'icono': Icons.description, 'color': Colors.blueGrey, 'ruta': '/gestion/factura', 'permKey': 'facturas'},
    {'titulo': 'Pagos', 'icono': Icons.payments, 'color': Colors.green, 'ruta': '/gestion/pago', 'permKey': 'pagos'},
    {'titulo': 'Clientes', 'icono': Icons.people, 'color': Colors.teal, 'ruta': '/gestion/cliente', 'permKey': 'clientes'},
    {'titulo': 'Empleados', 'icono': Icons.badge, 'color': Colors.blueGrey, 'ruta': '/gestion/empleado', 'permKey': 'empleados'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final email = user.email?.toLowerCase() ?? '';
    final isSuper = email == 'omar_admin@gmail.com';
    if (isSuper) {
      if (mounted) {
        setState(() {
          _isSuperAdmin = true;
        });
      }
      return;
    }

    var snap = await _db.collection('empleados').doc(user.uid).get();
    if (!snap.exists) {
      final fallback = await _db.collection('empleado').where('correo', isEqualTo: email).limit(1).get();
      if (fallback.docs.isNotEmpty) {
        snap = fallback.docs.first;
      }
    }

    final permisosData = snap.exists ? (snap.data()?['permisos'] as Map<String, dynamic>?) : null;
    if (permisosData != null) {
      final merged = Map<String, bool>.from(_permissions);
      permisosData.forEach((key, value) {
        merged[key.toString()] = value == true;
      });
      if (mounted) setState(() => _permissions = merged);
    }
  }

  bool _canView(String key) => _isSuperAdmin || (_permissions[key] ?? false);

  @override
  Widget build(BuildContext context) {
    final visibleModules = modulos.where((item) {
      if (_isSuperAdmin) return true;
      final key = item['permKey'] as String?;
      return key == null || _canView(key);
    }).toList();

    final displayModules = _isSuperAdmin
      ? [
          {
            'titulo': 'Gestión de Permisos',
            'icono': Icons.shield_outlined,
            'color': Colors.deepPurple,
            'ruta': '/gestion/permisos',
            'permKey': null,
          },
          ...visibleModules,
        ]
      : visibleModules;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: azulProfundo,
        elevation: 4,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chair_outlined, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text("Mueblería Carrasco", 
              style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark 
                ? Icons.light_mode 
                : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
            tooltip: 'Cambiar Tema',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => context.go('/'),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Text("Panel de Control", 
                    style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: azulProfundo)),
                  const SizedBox(height: 8),
                  Container(width: 50, height: 3, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 10),
                  Text("Administra tu empresa con precisión.", 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blueGrey[400], fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            
            const SizedBox(height: 35),

            LayoutBuilder(
              builder: (context, constraints) {
                int columns = constraints.maxWidth > 1200 ? 6 : (constraints.maxWidth > 900 ? 5 : (constraints.maxWidth > 600 ? 4 : 3));
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.95, // Más compactas
                  ),
                  itemCount: displayModules.length,
                  itemBuilder: (context, index) {
                    final item = displayModules[index];
                    return _AnimatedMenuCard(
                      title: item['titulo'],
                      icon: item['icono'],
                      color: item['color'],
                      onTap: () => context.push(item['ruta']),
                    );
                  },
                );
              }
            ),

            const SizedBox(height: 50),
            Text("SISTEMA CARRASCO v2.5", 
              style: TextStyle(color: Colors.grey[400], letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET DE TARJETA ANIMADA ---
class _AnimatedMenuCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedMenuCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AnimatedMenuCard> createState() => _AnimatedMenuCardState();
}

class _AnimatedMenuCardState extends State<_AnimatedMenuCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: isHovered ? (Matrix4.identity()..scale(1.05)..translate(0, -5)) : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isHovered 
                ? widget.color 
                : (Theme.of(context).brightness == Brightness.dark 
                    ? widget.color.withOpacity(0.2) // Borde sutil del color del módulo en modo oscuro
                    : Colors.black.withOpacity(0.05)),
              width: isHovered ? 2 : 1.5,
            ),
            boxShadow: [
              if (isHovered) 
                BoxShadow(
                  color: widget.color.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.2),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // EFECTO AURA / GLOW
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (Theme.of(context).brightness == Brightness.dark)
                      BoxShadow(
                        color: widget.color.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Icon(
                  widget.icon, 
                  color: widget.color, 
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.title.toUpperCase(), 
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 1.5,
                  fontSize: 10, 
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}