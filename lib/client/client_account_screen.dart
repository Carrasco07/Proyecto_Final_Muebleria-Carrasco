import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ClientAccountScreen extends StatefulWidget {
  const ClientAccountScreen({super.key});

  @override
  State<ClientAccountScreen> createState() => _ClientAccountScreenState();
}

class _ClientAccountScreenState extends State<ClientAccountScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _clientData;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  final Color azulGrisaceo = const Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 1. Cargar datos del cliente
      final clientDoc = await _db.collection('cliente').doc(user.uid).get();
      Map<String, dynamic> clientInfo = {};
      if (clientDoc.exists) {
        clientInfo = clientDoc.data()!;
      } else {
        // Buscar por correo como fallback
        final snap = await _db.collection('cliente').where('correo', isEqualTo: user.email).get();
        if (snap.docs.isNotEmpty) clientInfo = snap.docs.first.data();
      }

      // 2. Cargar historial de pedidos del cliente
      final pedidosSnap = await _db.collection('pedido').where('id_cliente', isEqualTo: user.uid).get();
      final List<Map<String, dynamic>> pedidosList = [];

      for (var pedidoDoc in pedidosSnap.docs) {
        final pedidoData = pedidoDoc.data();
        // Cargar detalles de este pedido
        final detallesSnap = await _db.collection('detalle_pedido')
            .where('id_pedido', isEqualTo: pedidoDoc.id).get();
        final List<Map<String, dynamic>> detalles = [];
        for (var d in detallesSnap.docs) {
          final dData = d.data();
          // Obtener nombre del producto
          try {
            final prodDoc = await _db.collection('productos').doc(dData['id_producto']).get();
            dData['nombre_producto'] = prodDoc.data()?['nombre'] ?? 'Producto';
          } catch (_) {
            dData['nombre_producto'] = 'Producto';
          }
          detalles.add(dData);
        }
        pedidosList.add({
          'id': pedidoDoc.id,
          ...pedidoData,
          'detalles': detalles,
        });
      }

      // Ordenar por fecha más reciente primero
      pedidosList.sort((a, b) {
        final aFecha = a['fecha_pedido']?.toString() ?? '';
        final bFecha = b['fecha_pedido']?.toString() ?? '';
        return bFecha.compareTo(aFecha);
      });

      setState(() {
        _clientData = clientInfo;
        _orders = pedidosList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'entregado': return Colors.green;
      case 'en camino': return Colors.blue;
      case 'pendiente': return Colors.orange;
      case 'rechazado': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'entregado': return Icons.check_circle_rounded;
      case 'en camino': return Icons.local_shipping_rounded;
      case 'pendiente': return Icons.pending_rounded;
      case 'rechazado': return Icons.cancel_rounded;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0B0C) : const Color(0xFFF7F8FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Header con Avatar
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: azulGrisaceo,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [azulGrisaceo, const Color(0xFF1A2F45)],
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            // Avatar con inicial
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.amber.shade200,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  (_clientData?['nombre'] ?? 'C')[0].toUpperCase(),
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: azulGrisaceo,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _clientData?['nombre'] ?? 'Cliente',
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _clientData?['correo'] ?? '',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Contenido
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tarjeta de Información Personal
                        _buildSectionTitle('Mi Información', Icons.person_outline, isDark),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF161B22) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildInfoTile(Icons.phone_outlined, 'Teléfono', _clientData?['telefono'] ?? 'No registrado', isDark),
                              _buildDivider(),
                              _buildInfoTile(Icons.home_outlined, 'Dirección', _clientData?['direccion'] ?? 'No registrada', isDark),
                              _buildDivider(),
                              _buildInfoTile(Icons.calendar_today_outlined, 'Cliente desde', _clientData?['fecha_registro'] ?? '—', isDark),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Historial de Compras
                        _buildSectionTitle('Historial de Compras', Icons.receipt_long_outlined, isDark),
                        const SizedBox(height: 5),
                        Text(
                          '${_orders.length} pedido(s) realizados',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                        const SizedBox(height: 15),

                        if (_orders.isEmpty)
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF161B22) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_bag_outlined, size: 45, color: Colors.grey.shade400),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Aún no has realizado ningún pedido',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...List.generate(_orders.length, (i) {
                            final order = _orders[i];
                            final estado = order['estado'] ?? 'Pendiente';
                            final total = double.tryParse(order['total']?.toString() ?? '0') ?? 0;
                            final detalles = order['detalles'] as List<Map<String, dynamic>>;
                            final shortId = '#${order['id'].toString().substring(0, 6).toUpperCase()}';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF161B22) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _statusColor(estado).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(_statusIcon(estado), color: _statusColor(estado), size: 22),
                                  ),
                                  title: Text(
                                    shortId,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order['fecha_pedido'] ?? '',
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _statusColor(estado).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          estado,
                                          style: TextStyle(
                                            color: _statusColor(estado),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Text(
                                    NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(total),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.teal,
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Divider(color: Colors.grey.shade200),
                                          const SizedBox(height: 8),
                                          const Text('Artículos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          const SizedBox(height: 8),
                                          ...detalles.map((detalle) {
                                            final nombreProd = detalle['nombre_producto'] ?? 'Producto';
                                            final qty = detalle['cantidad'] ?? 1;
                                            final subtotal = double.tryParse(detalle['subtotal']?.toString() ?? '0') ?? 0;
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.chair_outlined, size: 16, color: Colors.grey),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text('${qty}x $nombreProd', style: const TextStyle(fontSize: 13)),
                                                  ),
                                                  Text(
                                                    NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(subtotal),
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: azulGrisaceo),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: azulGrisaceo),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => Divider(height: 1, indent: 50, color: Colors.grey.shade200);
}
