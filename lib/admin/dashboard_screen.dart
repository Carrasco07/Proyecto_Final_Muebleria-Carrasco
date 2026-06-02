import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/michi_ai_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Color fondoOscuro = const Color(0xFF0A0B0C);
  final Color tarjetaOscura = const Color(0xFF161B22);
  final Color azulProfundo = const Color(0xFF2C3E50);
  bool _isAdmin = false;
  bool _isSuperAdmin = false;
  Map<String, bool> _permissions = {};
  String _userName = "Usuario";
  bool _recibirAlertas = true;

  final Map<String, bool> _defaultPermissions = {
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

  // --- VARIABLES DE MICHI CARPINTERO AI ---
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Map<String, dynamic>> _chatMessages = [];
  final TextEditingController _michiInputController = TextEditingController();
  final ScrollController _michiScrollController = ScrollController();
  bool _michiIsTyping = false;
  final MichiAiService _michiService = MichiAiService();

  void _michiWelcome() {
    if (_chatMessages.isEmpty) {
      _chatMessages.add({
        'sender': 'michi',
        'text': '¡Hola, Omar! 🐈‍⬛🐾 *se estira perezosamente y lija un banquito de madera* ¡Miau! Soy Michi Carpintero, tu fiel ayudante digital en Mueblería Carrasco. ¿Listo para que revisemos el inventario, analicemos las ventas o simplemente platiquemos de carpintería? ¡Tú dime en qué te apoyo hoy! 🪵🪚🪑'
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _michiWelcome();
    _checkRole();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() { _recibirAlertas = prefs.getBool('recibirAlertas') ?? true; });
  }

  Future<void> _checkRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final String email = user.email?.toLowerCase().trim() ?? '';
      final bool isSuper = email == 'omar_admin@gmail.com';

      // 1. Si es superadmin, asignamos permisos de inmediato para evitar bloqueos por fallos de red/Base de Datos
      if (isSuper) {
        String superName = user.email!.split('@')[0].split('_')[0];
        if (superName.isNotEmpty) {
          superName = superName[0].toUpperCase() + superName.substring(1).toLowerCase();
        }
        if (mounted) {
          setState(() {
            _isSuperAdmin = true;
            _isAdmin = true;
            _permissions = {
              'clientes': true,
              'pedidos': true,
              'detalle_pedido': true,
              'empleados': true,
              'productos': true,
              'categorias': true,
              'proveedores': true,
              'inventario': true,
              'almacenes': true,
              'facturas': true,
              'pagos': true,
            };
            _userName = superName;
          });
        }

        // Intentamos leer el nombre real desde Firestore sin bloquear en caso de error
        try {
          var snap = await FirebaseFirestore.instance.collection('empleados').doc(user.uid).get();
          if (!snap.exists) {
            final fallback = await FirebaseFirestore.instance.collection('empleado').where('correo', isEqualTo: email).limit(1).get();
            if (fallback.docs.isNotEmpty) {
              snap = fallback.docs.first;
            }
          }
          if (snap.exists && snap.data()?['nombre'] != null) {
            String rawName = snap.data()!['nombre'];
            if (rawName.isNotEmpty && mounted) {
              setState(() {
                _userName = rawName[0].toUpperCase() + rawName.substring(1).toLowerCase();
              });
            }
          }
        } catch (e) {
          debugPrint("Error buscando nombre de superadmin en base de datos: $e");
        }
        return;
      }

      // 2. Si no es superadmin, ejecutamos el flujo normal protegido con try-catch
      try {
        var snap = await FirebaseFirestore.instance.collection('empleados').doc(user.uid).get();
        if (!snap.exists) {
          final fallback = await FirebaseFirestore.instance.collection('empleado').where('correo', isEqualTo: email).limit(1).get();
          if (fallback.docs.isNotEmpty) {
            snap = fallback.docs.first;
          }
        }

        String rawName = "Usuario";
        if (snap.exists && snap.data()?['nombre'] != null) {
          rawName = snap.data()!['nombre'];
        } else {
          rawName = user.email!.split('@')[0].split('_')[0]; 
        }
        
        if (rawName.isNotEmpty) {
          rawName = rawName[0].toUpperCase() + rawName.substring(1).toLowerCase();
        }

        final bool isAdminCargo = snap.exists && snap.data()?['cargo'] == 'Administrador';
        final permisosData = snap.exists ? (snap.data()?['permisos'] as Map<String, dynamic>?) : null;
        final mergedPermisos = Map<String, bool>.from(_defaultPermissions);
        if (permisosData != null) {
          permisosData.forEach((key, value) {
            mergedPermisos[key.toString()] = value == true;
          });
        }

        if (mounted) {
          setState(() {
            _isSuperAdmin = false;
            _isAdmin = isAdminCargo;
            _permissions = mergedPermisos;
            _userName = rawName;
          });
        }
      } catch (e) {
        debugPrint("Error consultando rol/permisos del usuario: $e");
        if (mounted) {
          setState(() {
            _isSuperAdmin = false;
            _isAdmin = false;
            _permissions = Map<String, bool>.from(_defaultPermissions);
            _userName = user.email!.split('@')[0];
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? fondoOscuro : const Color(0xFFF0F4F8),
      body: Row(
        children: [
          _buildMasterSidebar(isDark),
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildHeader(isDark),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPermissionNotice(isDark),
                        _buildRealKpiRow(isDark),
                        const SizedBox(height: 35),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _hasDashboardMetricsPermission() ? _buildMainCharts(isDark) : _buildNoDashboardData(isDark)),
                            const SizedBox(width: 25),
                            Expanded(flex: 1, child: _buildRightPanel(isDark)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildMichiFAB(isDark),
    );
  }

  Widget _buildMasterSidebar(bool isDark) {
    return Container(
      width: 280,
      decoration: BoxDecoration(color: isDark ? const Color(0xFF0D1117) : azulProfundo, boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)]),
      child: Column(
        children: [
          const SizedBox(height: 50),
          _buildLogo(),
          const SizedBox(height: 30),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                _sidebarSection("PRINCIPAL"),
                _sidebarItem(Icons.dashboard_rounded, "Consola Mando", "/gestion/dashboard", true),
                
                _sidebarSection("COMERCIAL", _sectionHasVisibleItems(['clientes', 'pedidos', 'detalle_pedido', 'empleados'])),
                _sidebarItem(Icons.people_alt_rounded, "Clientes", "/gestion/cliente", false, isVisible: _canView('clientes')),
                _sidebarItem(Icons.assignment_rounded, "Pedidos", "/gestion/pedido", false, isVisible: _canView('pedidos')),
                _sidebarItem(Icons.list_alt_rounded, "Detalle Pedido", "/gestion/detalle_pedido", false, isVisible: _canView('detalle_pedido')),
                _sidebarItem(Icons.badge_rounded, "Empleados", "/gestion/empleado", false, isVisible: _canView('empleados')),

                _sidebarSection("LOGÍSTICA", _sectionHasVisibleItems(['productos', 'categorias', 'proveedores', 'inventario', 'almacenes'])),
                _sidebarItem(Icons.chair_rounded, "Productos", "/gestion/productos", false, isVisible: _canView('productos')),
                _sidebarItem(Icons.category_rounded, "Categorías", "/gestion/categoria", false, isVisible: _canView('categorias')),
                _sidebarItem(Icons.local_shipping_rounded, "Proveedores", "/gestion/proveedor", false, isVisible: _canView('proveedores')),
                _sidebarItem(Icons.inventory_2_rounded, "Inventario", "/gestion/inventario", false, isVisible: _canView('inventario')),
                _sidebarItem(Icons.warehouse_rounded, "Almacenes", "/gestion/almacen", false, isVisible: _canView('almacenes')),

                _sidebarSection("FINANZAS", _sectionHasVisibleItems(['facturas', 'pagos'])),
                _sidebarItem(Icons.description_rounded, "Facturas", "/gestion/factura", false, isVisible: _canView('facturas')),
                _sidebarItem(Icons.payments_rounded, "Pagos", "/gestion/pago", false, isVisible: _canView('pagos')),

                if (_isSuperAdmin) ...[
                  const SizedBox(height: 15),
                  _sidebarSection("ADMINISTRACIÓN", true),
                  _sidebarItem(Icons.shield_outlined, "Gestión de Permisos", "/gestion/permisos", false, isVisible: true),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() => Column(children: [const Icon(Icons.chair_outlined, color: Colors.amber, size: 40), const SizedBox(height: 10), Text("Mueblería Carrasco", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 14))]);
  Widget _sidebarSection(String t, [bool isVisible = true]) { if (!isVisible) return const SizedBox.shrink(); return Padding(padding: const EdgeInsets.only(left: 15, top: 25, bottom: 10), child: Text(t, style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5))); }
  Widget _sidebarItem(IconData i, String t, String r, bool a, {bool isLogout = false, bool isVisible = true}) { if (!isVisible) return const SizedBox.shrink(); return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: InkWell(onTap: () => isLogout ? context.go('/') : context.push(r), borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12), decoration: BoxDecoration(color: a ? Colors.amber.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(i, color: a ? Colors.amber : (isLogout ? Colors.redAccent : Colors.white54), size: 20), const SizedBox(width: 15), Text(t, style: TextStyle(color: a ? Colors.white : (isLogout ? Colors.redAccent : Colors.white70), fontSize: 13))])))); }

  bool _canView(String key) {
    return _isSuperAdmin || (_permissions[key] ?? false);
  }

  bool _hasAnyPermission() {
    return _isSuperAdmin || _permissions.values.any((value) => value);
  }

  bool _hasDashboardMetricsPermission() {
    return _isSuperAdmin ||
        _permissions['pedidos'] == true ||
        _permissions['inventario'] == true ||
        _permissions['clientes'] == true ||
        _permissions['facturas'] == true ||
        _permissions['pagos'] == true;
  }

  bool _sectionHasVisibleItems(List<String> keys) {
    if (_isSuperAdmin) return true;
    return keys.any((key) => _permissions[key] == true);
  }

  Widget _buildPermissionNotice(bool isDark) {
    final title = _isSuperAdmin
        ? 'Acceso completo'
        : (!_hasAnyPermission()
            ? 'Acceso restringido'
            : 'Panel limitado');
    final message = _isSuperAdmin
        ? 'Eres Superadmin. Tienes acceso completo a todos los módulos y métricas del sistema.'
        : (!_hasAnyPermission()
            ? 'No tienes permisos asignados para ver ningún módulo. Contacta al Superadmin para activarlos.'
            : 'Tu acceso está limitado. Solo verás datos y gráficos correspondientes a los módulos que te han sido asignados.');

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(title),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 25),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2330) : const Color(0xFFEEF6FF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isDark ? Colors.blueGrey.withOpacity(0.3) : Colors.blue.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.15) : Colors.blue.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _hasAnyPermission() ? Colors.blue.withOpacity(0.15) : Colors.orange.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _hasAnyPermission() ? Icons.shield_outlined : Icons.block,
                color: _hasAnyPermission() ? Colors.blue : Colors.orange,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: azulProfundo)),
                  const SizedBox(height: 8),
                  Text(message, style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 13, height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDashboardData(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A22) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gráficas restringidas', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : azulProfundo)),
          const SizedBox(height: 12),
          Text(
            'No tienes permisos para ver los widgets de ventas o indicadores generales. Usa los módulos que están disponibles en el menú para administrar tus tablas.',
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_canView('productos')) _buildQuickHintChip('Productos', Icons.chair_rounded),
              if (_canView('categorias')) _buildQuickHintChip('Categorías', Icons.category_rounded),
              if (_canView('proveedores')) _buildQuickHintChip('Proveedores', Icons.local_shipping_rounded),
              if (_canView('inventario')) _buildQuickHintChip('Inventario', Icons.inventory_2_rounded),
              if (_canView('almacenes')) _buildQuickHintChip('Almacenes', Icons.warehouse_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHintChip(String label, IconData icon) {
    return Chip(
      avatar: CircleAvatar(backgroundColor: azulProfundo.withOpacity(0.15), child: Icon(icon, size: 16, color: azulProfundo)),
      label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: azulProfundo)),
      backgroundColor: azulProfundo.withOpacity(0.08),
    );
  }

  Widget _buildRightPanel(bool isDark) {
    if (_hasDashboardMetricsPermission()) {
      return _buildCreativeRightPanel(isDark);
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(color: isDark ? tarjetaOscura : Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ACCESO RÁPIDO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5, color: Colors.grey)),
              const SizedBox(height: 20),
              Text('Solo verás los módulos que tienes autorizados. Usa este espacio para trabajar directamente en tus tablas.', style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 25),
        if (_canView('productos')) _buildActionButtonRow(Icons.chair_rounded, 'Productos', Colors.blue, '/gestion/productos'),
        if (_canView('categorias')) _buildActionButtonRow(Icons.category_rounded, 'Categorías', Colors.indigo, '/gestion/categoria'),
        if (_canView('inventario')) _buildActionButtonRow(Icons.inventory_2_rounded, 'Inventario', Colors.orange, '/gestion/inventario'),
        if (_canView('proveedores')) _buildActionButtonRow(Icons.local_shipping_rounded, 'Proveedores', Colors.purple, '/gestion/proveedor'),
        if (_canView('almacenes')) _buildActionButtonRow(Icons.warehouse_rounded, 'Almacenes', Colors.teal, '/gestion/almacen'),
      ],
    );
  }

  Widget _buildActionButtonRow(IconData icon, String label, Color color, String route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.12),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: () => context.push(route),
        icon: Icon(icon, size: 18, color: color),
        label: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    String displayUserName = _userName;
    if (displayUserName.contains('_')) {
      displayUserName = displayUserName.split('_')[0];
    }
    if (displayUserName.isNotEmpty) {
      displayUserName = displayUserName[0].toUpperCase() + displayUserName.substring(1).toLowerCase();
    }

    return SliverAppBar(
      automaticallyImplyLeading: false,
      backgroundColor: isDark ? fondoOscuro : Colors.white,
      pinned: true,
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text("Operaciones Mueblería Carrasco", style: GoogleFonts.playfairDisplay(color: isDark ? Colors.white : azulProfundo, fontWeight: FontWeight.bold, fontSize: 24), overflow: TextOverflow.ellipsis), 
                Text("Hola, $displayUserName • Monitor Activo", style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold))
              ]
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: isDark ? Colors.amber : azulProfundo), 
                onPressed: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
                tooltip: 'Cambiar Tema',
              ),
              const SizedBox(width: 5),
              IconButton(
                icon: Icon(Icons.tune_rounded, color: isDark ? Colors.white : azulProfundo),
                onPressed: () => _mostrarConfiguracion(isDark),
                tooltip: 'Configuración del sistema',
              ),
              const SizedBox(width: 5),
              StreamBuilder<QuerySnapshot>(
                stream: _db.collection('notificaciones').where('leido', isEqualTo: false).snapshots(),
                builder: (context, snapshot) {
                  int unread = 0;
                  if (snapshot.hasData && _recibirAlertas == true) unread = snapshot.data!.docs.length;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(icon: Icon(unread > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, color: isDark ? Colors.white : azulProfundo), onPressed: () => _abrirPanelNotificaciones(isDark)),
                      if (unread > 0)
                        Positioned(right: 8, top: 12, child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), child: Text(unread > 9 ? '+9' : unread.toString(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))))
                    ],
                  );
                }
              ), 
              const SizedBox(width: 10), 
              PopupMenuButton<String>(
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                color: isDark ? tarjetaOscura : Colors.white,
                child: CircleAvatar(backgroundColor: Colors.amber, child: Text(displayUserName.isNotEmpty ? displayUserName[0].toUpperCase() : "U", style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold))),
                itemBuilder: (context) => [
                  PopupMenuItem<String>(value: 'header', enabled: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(displayUserName, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)), Text(_isSuperAdmin ? "Superdesarrollador" : (_isAdmin ? "Administrador General" : "Vendedor"), style: const TextStyle(fontSize: 10, color: Colors.grey))])),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(value: 'perfil', child: Row(children: [Icon(Icons.badge_outlined, size: 18), SizedBox(width: 10), Text("Mi Perfil Corporativo")])),
                  const PopupMenuItem<String>(value: 'ajustes', child: Row(children: [Icon(Icons.tune_rounded, size: 18), SizedBox(width: 10), Text("Configuración del Sistema")])),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(value: 'logout', child: Row(children: [Icon(Icons.logout, size: 18, color: Colors.redAccent), SizedBox(width: 10), Text("Cerrar Sesión", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))])),
                ],
                onSelected: (value) async {
                  if (value == 'perfil') _mostrarPerfilCorporativo(isDark);
                  else if (value == 'ajustes') _mostrarConfiguracion(isDark);
                  else if (value == 'logout') {
                     await FirebaseAuth.instance.signOut();
                     if (mounted) context.go('/login');
                  }
                },
              ),
            ]
          )
        ]
      ),
    );
  }

  Widget _buildRealKpiRow(bool isDark) {
    final cards = <Widget>[];
    if (_canView('pedidos')) {
      cards.add(_kpiStream("Ventas Netas", "pedido", "total", Icons.trending_up_rounded, [const Color(0xFF6366F1), const Color(0xFF818CF8)], "/gestion/pedido", isSum: true));
      cards.add(const SizedBox(width: 20));
      cards.add(_kpiStream("Ordenes", "pedido", "id", Icons.shopping_bag_rounded, [const Color(0xFFF59E0B), const Color(0xFFFBBF24)], "/gestion/pedido"));
    }
    if (_canView('inventario')) {
      if (cards.isNotEmpty) cards.add(const SizedBox(width: 20));
      cards.add(_kpiStream("Stock Crítico", "inventario", "stock_actual", Icons.warning_rounded, [const Color(0xFFEF4444), const Color(0xFFF87171)], "/gestion/inventario", isCritical: true));
    }
    if (_canView('clientes')) {
      if (cards.isNotEmpty) cards.add(const SizedBox(width: 20));
      cards.add(_kpiStream("Clientes", "cliente", "id", Icons.groups_rounded, [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)], "/gestion/cliente"));
    }

    if (cards.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141A22) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Indicadores deshabilitados', style: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : azulProfundo)),
            const SizedBox(height: 12),
            Text(
              'No tienes permisos para ver los indicadores rápidos de ventas, clientes o inventario. Avanza desde los módulos que tienes autorizados.',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: cards),
    );
  }

  Widget _kpiStream(String title, String collection, String field, IconData icon, List<Color> colors, String ruta, {bool isSum = false, bool isCritical = false}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection(collection).snapshots(),
      builder: (context, snapshot) {
        String value = "...";
        String footer = "Cargando...";
        if (snapshot.hasData) {
          if (isSum) {
            double total = 0;
            for (var doc in snapshot.data!.docs) total += (doc.data() as Map<String, dynamic>)[field] ?? 0.0;
            value = NumberFormat.compactCurrency(symbol: "\$").format(total);
            footer = "Total acumulado";
          } else if (isCritical) {
            int critical = snapshot.data!.docs.where((doc) {
              var d = doc.data() as Map<String, dynamic>;
              return (d['stock_actual'] ?? 0) <= (d['stock_minimo'] ?? 5);
            }).length;
            value = critical.toString().padLeft(2, '0');
            footer = critical > 0 ? "¡Atención inmediata!" : "Todo en orden";
          } else {
            value = snapshot.data!.docs.length.toString().padLeft(2, '0');
            footer = "Registros activos";
          }
        }
        return SizedBox(
          width: 240,
          child: InkWell(
            onTap: () => context.push(ruta),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colors[0].withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(height: 20),
                  Text(
                    value,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    footer,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainCharts(bool isDark) {
    final chartWidgets = <Widget>[];
    if (_canView('pedidos')) {
      chartWidgets.add(_chartContainer("Flujo Financiero (Últimos Pedidos)", isDark, Container(height: 220, child: _realLineChart())));
    }
    if (_canView('inventario')) {
      if (chartWidgets.isNotEmpty) chartWidgets.add(const SizedBox(height: 30));
      chartWidgets.add(Row(children: [Expanded(child: _chartContainer("Top Stock (Inventario)", isDark, Container(height: 180, child: _realPieChart()))), const SizedBox(width: 25), Expanded(child: _chartContainer("Salud de la Empresa", isDark, _buildHealthInfo(isDark)))]));
    }
    if (chartWidgets.isEmpty) {
      return _buildNoDashboardData(isDark);
    }
    return Column(children: chartWidgets);
  }

  Widget _chartContainer(String t, bool d, Widget c) => Container(padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: d ? tarjetaOscura : Colors.white, borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: TextStyle(color: d ? Colors.white : azulProfundo, fontWeight: FontWeight.bold, fontSize: 15)), const SizedBox(height: 25), c]));

  Widget _buildHealthInfo(bool isDark) => Column(children: [Stack(alignment: Alignment.center, children: [const SizedBox(width: 100, height: 100, child: CircularProgressIndicator(value: 0.95, strokeWidth: 10, color: Colors.green)), Text("95%", style: GoogleFonts.montserrat(color: isDark ? Colors.white : azulProfundo, fontSize: 22, fontWeight: FontWeight.bold))]), const SizedBox(height: 15), const Text("Integridad de Datos", style: TextStyle(color: Colors.grey, fontSize: 10))]);

  Widget _buildCreativeRightPanel(bool isDark) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(color: isDark ? tarjetaOscura : Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(children: [
          const Text("BUSINESS PULSE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5, color: Colors.grey)),
          const SizedBox(height: 25),
          Stack(alignment: Alignment.center, children: [
            SizedBox(width: 140, height: 140, child: CircularProgressIndicator(value: 0.85, strokeWidth: 15, backgroundColor: Colors.amber.withOpacity(0.1), color: Colors.amber)),
            const Column(children: [Text("85%", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), Text("Goal", style: TextStyle(fontSize: 10, color: Colors.grey))])
          ]),
          const SizedBox(height: 20),
          const Text("Rendimiento del Día", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      ),
      const SizedBox(height: 25),
      Row(children: [
        Expanded(child: _actionButton(Icons.add_shopping_cart, "Venta", Colors.blue)),
        const SizedBox(width: 15),
        Expanded(child: _actionButton(Icons.inventory, "Stock", Colors.orange)),
      ]),
      const SizedBox(height: 25),
      Container(
        height: 350,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(color: isDark ? tarjetaOscura : Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("SISTEMA NOTIFICA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5, color: Colors.grey)),
            const SizedBox(height: 20),
            Expanded(child: _activityStream()),
          ],
        ),
      ),
    ]);
  }

  Widget _actionButton(IconData i, String l, Color c) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withOpacity(0.3))), child: Column(children: [Icon(i, color: c), const SizedBox(height: 5), Text(l, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 10))]));

  Widget _activityStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('auditoria').orderBy('fecha', descending: true).limit(10).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Text("...");
        return ListView(children: snapshot.data!.docs.map((doc) {
          var d = doc.data() as Map<String, dynamic>;
          return _chatAuditItem(d['accion'] ?? '', d['fecha'] ?? '', d['usuario'] ?? 'Sistema');
        }).toList());
      },
    );
  }

  Widget _chatAuditItem(String t, String h, String u) => Padding(padding: const EdgeInsets.only(bottom: 15), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [CircleAvatar(radius: 12, backgroundColor: Colors.amber.withOpacity(0.2), child: Text(u[0], style: const TextStyle(fontSize: 10, color: Colors.amber))), const SizedBox(width: 10), Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: const BorderRadius.only(topRight: Radius.circular(15), bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)), Text(h, style: const TextStyle(fontSize: 8, color: Colors.grey))])))]));

  Widget _realPieChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('inventario').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
        var docs = snapshot.data!.docs.where((d) => (d.data() as Map<String, dynamic>)['stock_actual'] != null).toList();
        if (docs.isEmpty) return const Center(child: Text("Sin inventario", style: TextStyle(color: Colors.grey)));
        docs.sort((a, b) => ((b.data() as Map<String, dynamic>)['stock_actual'] is int ? (b.data() as Map<String, dynamic>)['stock_actual'] : int.tryParse((b.data() as Map<String, dynamic>)['stock_actual'].toString()) ?? 0).compareTo(((a.data() as Map<String, dynamic>)['stock_actual'] is int ? (a.data() as Map<String, dynamic>)['stock_actual'] : int.tryParse((a.data() as Map<String, dynamic>)['stock_actual'].toString()) ?? 0)));
        var top = docs.take(4).toList();
        List<Color> colors = [Colors.blue, Colors.amber, Colors.green, Colors.purpleAccent];
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, pieTouchResponse) {}),
                  sectionsSpace: 2,
                  centerSpaceRadius: 35,
                  sections: List.generate(top.length, (i) {
                    var data = top[i].data() as Map<String, dynamic>;
                    double val = (data['stock_actual'] is int ? data['stock_actual'] : int.tryParse(data['stock_actual'].toString()) ?? 0).toDouble();
                    return PieChartSectionData(color: colors[i], value: val, title: val > 0 ? val.toInt().toString() : '', radius: 35, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white));
                  })
                ),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOutBack,
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(top.length, (i) {
                  var data = top[i].data() as Map<String, dynamic>;
                  String nombre = data['nombre'] ?? 'Producto ${i+1}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle)), const SizedBox(width: 8), Expanded(child: Text(nombre, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)), Text(" (${data['stock_actual']})", style: const TextStyle(fontSize: 10, color: Colors.grey))]),
                  );
                }),
              )
            )
          ]
        );
      }
    );
  }

  Widget _realLineChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('pedido').orderBy('fecha_pedido', descending: true).limit(7).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
        var docs = snapshot.data!.docs.reversed.toList();
        if (docs.isEmpty) return const Center(child: Text("Sin pedidos recientes", style: TextStyle(color: Colors.grey)));
        List<FlSpot> spots = [];
        for (int i = 0; i < docs.length; i++) {
          var data = docs[i].data() as Map<String, dynamic>;
          double val = data['total'] is double ? data['total'] : double.tryParse(data['total'].toString()) ?? 0.0;
          spots.add(FlSpot(i.toDouble(), val));
        }

        double growth = 0;
        if (spots.length > 1) {
          double last = spots.last.y;
          double prev = spots[spots.length - 2].y;
          if (prev > 0) growth = ((last - prev) / prev) * 100;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (spots.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  children: [
                    Text(NumberFormat.compactCurrency(locale: 'es_MX', symbol: '\$').format(spots.last.y), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: growth >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Row(children: [Icon(growth >= 0 ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: growth >= 0 ? Colors.green : Colors.red), const SizedBox(width: 4), Text("${growth.abs().toStringAsFixed(1)}% vs anterior", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: growth >= 0 ? Colors.green : Colors.red))])),
                  ]
                ),
              ),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false), 
                  titlesData: FlTitlesData(show: false), 
                  borderData: FlBorderData(show: false), 
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) => LineTooltipItem(NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(spot.y), const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))).toList();
                      }
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots, 
                      isCurved: true, 
                      color: Colors.amber, 
                      barWidth: 4, 
                      dotData: FlDotData(show: true), 
                      belowBarData: BarAreaData(
                        show: true, 
                        gradient: LinearGradient(colors: [Colors.amber.withOpacity(0.5), Colors.amber.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
                      )
                    )
                  ]
                ),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
              ),
            ),
          ],
        );
      }
    );
  }

  Future<void> _reiniciarEInicializar() async {
    setState(() => _cargandoDemo = true);
    await _db.collection('auditoria').add({'accion': 'Reseteo General de Sistema', 'fecha': DateFormat('HH:mm:ss').format(DateTime.now()), 'usuario': 'Admin'});
    setState(() => _cargandoDemo = false);
  }

  Future<void> _clearDatabaseExceptEmployees() async {
    setState(() => _cargandoDemo = true);
    final List<String> collectionsToClear = [
      'cliente',
      'pedido',
      'detalle_pedido',
      'factura',
      'pago',
      'notificaciones',
      'auditoria',
      'inventario',
      'productos',
      'categoria',
      'proveedor',
      'almacen',
      'almacenes',
    ];

    try {
      for (final collection in collectionsToClear) {
        final snapshot = await _db.collection(collection).get();
        for (final doc in snapshot.docs) {
          await _db.collection(collection).doc(doc.id).delete();
        }
      }

      await _db.collection('auditoria').add({
        'accion': 'Base de datos reiniciada. Se conservaron empleados.',
        'fecha': DateFormat('HH:mm:ss').format(DateTime.now()),
        'usuario': 'Admin',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registros eliminados. Se conservaron empleados.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al limpiar datos: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      setState(() => _cargandoDemo = false);
    }
  }

  void _mostrarPerfilCorporativo(bool isDark) {
    var user = FirebaseAuth.instance.currentUser;
    showDialog(context: context, builder: (c) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: isDark ? tarjetaOscura : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 40, spreadRadius: 5)],
          border: Border.all(color: Colors.amber.withOpacity(0.3), width: 2)
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("CREDENCIAL CORPORATIVA", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 2)),
            const SizedBox(height: 25),
            Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]), boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 20)]), child: Center(child: Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : "U", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)))),
            const SizedBox(height: 20),
            Text(_userName.isEmpty ? 'Usuario Sistema' : _userName, style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? Colors.white : azulProfundo)),
            Text(_isAdmin ? "ADMINISTRADOR GENERAL" : "AGENTE DE VENTAS", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 25),
            Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Column(children: [
              Row(children: [const Icon(Icons.email_outlined, size: 16, color: Colors.grey), const SizedBox(width: 10), Text(user?.email ?? "Sin correo", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
              const SizedBox(height: 10),
              const Row(children: [Icon(Icons.verified_user_outlined, size: 16, color: Colors.green), SizedBox(width: 10), Text("Estado: Activo y Verificado", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green))])
            ])),
            const SizedBox(height: 25),
            TextButton(onPressed: () => Navigator.pop(c), child: const Text("CERRAR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))
          ]
        )
      )
    ));
  }

  Future<void> _mostrarConfiguracion(bool isDark) async {
    showDialog(context: context, builder: (c) => StatefulBuilder(builder: (context, setModalState) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      backgroundColor: isDark ? tarjetaOscura : Colors.white,
      title: Row(children: [const Icon(Icons.tune_rounded), const SizedBox(width: 10), Text("Configuración del Sistema", style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 20))]),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.notifications_active_outlined, color: isDark ? Colors.white : azulProfundo),
              title: const Text("Recibir Alertas de Inventario", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text("Notificaciones en tiempo real sobre bajo stock o novedades.", style: TextStyle(fontSize: 10, color: Colors.grey)),
              trailing: Switch(
                value: _recibirAlertas,
                activeColor: Colors.amber,
                onChanged: (v) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('recibirAlertas', v);
                  setState(() => _recibirAlertas = v);
                  setModalState(() => _recibirAlertas = v);
                }
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.lock_reset, color: Colors.redAccent),
              title: const Text("Restablecer Contraseña", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 13)),
              subtitle: const Text("Te enviaremos un correo seguro para cambiarla.", style: TextStyle(fontSize: 10, color: Colors.grey)),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () async {
                   var user = FirebaseAuth.instance.currentUser;
                   if (user != null && user.email != null) {
                      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
                      if(mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Correo de restablecimiento enviado a ${user.email}."), backgroundColor: Colors.green));
                      }
                   }
                },
                child: const Text("ENVIAR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))
              ),
            ),
            if (_isSuperAdmin) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: const Text("Reiniciar datos (conservar empleados)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 13)),
                subtitle: const Text("Elimina registros de cliente, ventas, facturas e inventario, pero conserva las cuentas de empleados.", style: TextStyle(fontSize: 10, color: Colors.grey)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Confirmar reinicio de datos'),
                        content: const Text('¿Estás seguro de borrar todos los registros y empezar de cero, conservando solo las cuentas de empleados? Esta acción es irreversible.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('CANCELAR')),
                          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('SI, BORRAR')),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      Navigator.pop(context);
                      await _clearDatabaseExceptEmployees();
                    }
                  },
                  child: const Text("BORRAR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))
                ),
              ),
            ]
          ]
        )
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("CERRAR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))]
    )));
  }

  void _abrirPanelNotificaciones(bool isDark) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Cerrar",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 20,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), bottomLeft: Radius.circular(30)),
            child: Container(
              width: 380,
              height: double.infinity,
              padding: const EdgeInsets.all(25),
              color: isDark ? fondoOscuro : Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Notificaciones", style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 24, color: isDark ? Colors.white : azulProfundo)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (!_recibirAlertas) Container(padding: const EdgeInsets.all(15), margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: const Row(children: [Icon(Icons.notifications_off, color: Colors.orange, size: 20), SizedBox(width: 10), Expanded(child: Text("Las alertas están pausadas en Configuración.", style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)))])),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _db.collection('notificaciones').orderBy('fecha', descending: true).limit(20).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.amber));
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.notifications_none, size: 80, color: Colors.grey.withOpacity(0.3)), const SizedBox(height: 15), const Text("No tienes notificaciones recientes", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))]));
                        
                        var docs = snapshot.data!.docs;
                        return ListView(
                          children: docs.map((doc) {
                            var data = doc.data() as Map<String, dynamic>;
                            bool isRead = data['leido'] == true;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(color: isDark ? tarjetaOscura : Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: isRead ? Colors.transparent : Colors.amber.withOpacity(0.5), width: 1), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                leading: Builder(
                                  builder: (context) {
                                    IconData notificationIcon = Icons.info_outline_rounded;
                                    Color iconColor = Colors.amber;
                                    if (data['icono'] == 'warning') {
                                      notificationIcon = Icons.warning_amber_rounded;
                                      iconColor = Colors.redAccent;
                                    } else if (data['icono'] == 'shopping_bag') {
                                      notificationIcon = Icons.shopping_bag_rounded;
                                      iconColor = Colors.green;
                                    } else if (data['icono'] == 'local_shipping') {
                                      notificationIcon = Icons.local_shipping_rounded;
                                      iconColor = Colors.blue;
                                    } else if (data['icono'] == 'person_add') {
                                      notificationIcon = Icons.person_add_rounded;
                                      iconColor = Colors.purple;
                                    } else if (data['icono'] == 'payments') {
                                      notificationIcon = Icons.payments_rounded;
                                      iconColor = Colors.teal;
                                    } else if (data['icono'] == 'security') {
                                      notificationIcon = Icons.security_rounded;
                                      iconColor = Colors.orange;
                                    } else if (data['icono'] == 'create') {
                                      notificationIcon = Icons.add_circle_outline_rounded;
                                      iconColor = Colors.indigo;
                                    } else if (data['icono'] == 'edit') {
                                      notificationIcon = Icons.edit_note_rounded;
                                      iconColor = Colors.blueGrey;
                                    } else if (data['icono'] == 'delete') {
                                      notificationIcon = Icons.delete_outline_rounded;
                                      iconColor = Colors.redAccent;
                                    }
                                    return CircleAvatar(
                                      backgroundColor: iconColor.withOpacity(0.15),
                                      child: Icon(notificationIcon, color: iconColor, size: 20),
                                    );
                                  }
                                ),
                                title: Text(data['titulo'] ?? 'Aviso', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                                subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text(data['mensaje'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey))),
                                onTap: () {
                                  _db.collection('notificaciones').doc(doc.id).delete();
                                },
                              )
                            );
                          }).toList()
                        );
                      }
                    )
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(15), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Colors.amber),
                        foregroundColor: Colors.amber,
                      ),
                      onPressed: () async {
                         var snap = await _db.collection('notificaciones').get();
                         for(var d in snap.docs) { d.reference.delete(); }
                      },
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: const Text("Marcar todo como leído", style: TextStyle(fontWeight: FontWeight.bold))
                    ),
                  )
                ]
              )
            )
          )
        );
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return SlideTransition(position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(anim), child: child);
      },
    );
  }

  bool _cargandoDemo = false;

  // --- MASCOTA MICHI CARPINTERO AI WIDGETS ---

  void _openMichiChat(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: _buildMichiChatDrawer(isDark),
      ),
    );
  }

  Widget _buildMichiFAB(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10, right: 10),
      child: FloatingActionButton(
        onPressed: () {
          _openMichiChat(isDark);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        hoverElevation: 0,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF1E222A) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ],
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: Stack(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/michi_carpintero.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? const Color(0xFF1E222A) : Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMichiChatDrawer(bool isDark) {
    // Auto-scroll al fondo cuando se abre o cambia el chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_michiScrollController.hasClients) {
        _michiScrollController.animateTo(
          _michiScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return Material(
      color: isDark ? const Color(0xFF0F141C) : const Color(0xFFF7F9FC),
      child: SafeArea(
        child: SizedBox(
          width: 400,
          child: Column(
            children: [
              // Cabecera Premium de Michi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161B22) : azulProfundo,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber, width: 2),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/michi_carpintero.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Michi Carpintero",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "Gatito Asistente ERP 🐾",
                            style: TextStyle(
                              color: Colors.amber.shade200,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Área de Mensajes de Conversación
              Expanded(
                child: ListView.builder(
                  controller: _michiScrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _chatMessages[index];
                    final isMichi = msg['sender'] == 'michi';
                    return Align(
                      alignment: isMichi ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        constraints: const BoxConstraints(maxWidth: 300),
                        decoration: BoxDecoration(
                          color: isMichi 
                            ? (isDark ? const Color(0xFF21262D) : Colors.white)
                            : (isDark ? const Color(0xFF1F6FEB) : azulProfundo),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMichi ? 0 : 16),
                            bottomRight: Radius.circular(isMichi ? 16 : 0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 5,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          style: TextStyle(
                            color: isMichi 
                              ? (isDark ? Colors.white : Colors.black87)
                              : Colors.white,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Indicador de "Escribiendo..." de Michi
              if (_michiIsTyping)
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 10),
                  child: Row(
                    children: [
                      Text(
                        "🐾 Michi está afilando lápices...",
                        style: TextStyle(
                          color: isDark ? Colors.grey : Colors.blueGrey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

              // Barra de Sugerencias Rápidas e Inteligentes (Action Chips)
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                color: isDark ? const Color(0xFF0F141C) : const Color(0xFFF0F4F8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _sugerenciaChip("📋 Cliente Nuevo", "Registra al cliente Carlos Perez con correo carlos@gmail.com", isDark),
                    _sugerenciaChip("🪑 Nuevo Producto", "Crea el producto Silla de Pino con precio 1200 y stock 15", isDark),
                    _sugerenciaChip("🪵 Nueva Categoría", "Crea la categoría Muebles de Cedro", isDark),
                    _sugerenciaChip("📊 Stock Crítico", "¿Cómo está el inventario?", isDark, enviarDirecto: true),
                    _sugerenciaChip("💰 Ventas ERP", "¿Cómo van las ventas?", isDark, enviarDirecto: true),
                  ],
                ),
              ),

              // Barra Inferior de Entrada de Texto
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161B22) : Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _michiInputController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: "Escribe tu mensaje...",
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF10151E) : const Color(0xFFF2F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onSubmitted: (_) {},
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: Icon(Icons.send_rounded, color: isDark ? Colors.amber : azulProfundo),
                      onPressed: () {},
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sugerenciaChip(String label, String texto, bool isDark, {bool enviarDirecto = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () {
          if (enviarDirecto) {
            _michiInputController.text = texto;
            _enviarMensajeAMichi();
          } else {
            setState(() {
              _michiInputController.text = texto;
            });
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Chip(
          label: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.amber.shade200 : azulProfundo,
            ),
          ),
          backgroundColor: isDark ? const Color(0xFF21262D) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        ),
      ),
    );
  }

  void _enviarMensajeAMichi() async {
    final txt = _michiInputController.text.trim();
    if (txt.isEmpty) return;

    _michiInputController.clear();
    setState(() {
      _chatMessages.add({'sender': 'omar', 'text': txt});
      _michiIsTyping = true;
    });

    final respuesta = await _michiService.obtenerRespuesta(txt);
    
    if (mounted) {
      setState(() {
        _michiIsTyping = false;
        _chatMessages.add({'sender': 'michi', 'text': respuesta});
      });
    }
  }
}


