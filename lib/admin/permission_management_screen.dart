import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PermissionManagementScreen extends StatefulWidget {
  const PermissionManagementScreen({super.key});

  @override
  State<PermissionManagementScreen> createState() => _PermissionManagementScreenState();
}

class _PermissionManagementScreenState extends State<PermissionManagementScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Color azulProfundo = const Color(0xFF2C3E50);
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSaving = false;
  String _searchQuery = '';
  String _selectedEmployeeId = '';
  String _selectedEmployeeName = '';
  Map<String, bool> _draftPermissions = {};

  @override
  void initState() {
    super.initState();
  }

  final List<Map<String, dynamic>> _permissionOptions = [
    {'key': 'clientes', 'label': 'Clientes', 'icon': Icons.people_rounded},
    {'key': 'pedidos', 'label': 'Pedidos', 'icon': Icons.assignment_rounded},
    {'key': 'detalle_pedido', 'label': 'Detalle Pedido', 'icon': Icons.list_alt_rounded},
    {'key': 'empleados', 'label': 'Empleados', 'icon': Icons.badge_rounded},
    {'key': 'productos', 'label': 'Productos', 'icon': Icons.chair_rounded},
    {'key': 'categorias', 'label': 'Categorías', 'icon': Icons.category_rounded},
    {'key': 'proveedores', 'label': 'Proveedores', 'icon': Icons.local_shipping_rounded},
    {'key': 'inventario', 'label': 'Inventario', 'icon': Icons.inventory_2_rounded},
    {'key': 'almacenes', 'label': 'Almacenes', 'icon': Icons.warehouse_rounded},
    {'key': 'facturas', 'label': 'Facturas', 'icon': Icons.description_rounded},
    {'key': 'pagos', 'label': 'Pagos', 'icon': Icons.payments_rounded},
  ];

  Map<String, bool> _defaultPermissions() {
    return Map.fromEntries(_permissionOptions.map((item) => MapEntry(item['key'] as String, false)));
  }

  Map<String, bool> _normalizePermissions(Map<String, dynamic>? raw) {
    final defaultMap = _defaultPermissions();
    if (raw == null) return defaultMap;
    for (var entry in raw.entries) {
      defaultMap[entry.key] = entry.value == true;
    }
    return defaultMap;
  }

  int _activePermissionCount(Map<String, dynamic>? permisos) {
    if (permisos == null) return 0;
    return permisos.entries.where((entry) => entry.value == true).length;
  }

  List<Map<String, dynamic>> _activePermissionItems(Map<String, dynamic>? permisos) {
    if (permisos == null) return [];
    return _permissionOptions.where((item) => permisos[item['key']] == true).toList();
  }

  Future<void> _showPermissionEditor(String employeeId, String employeeName, Map<String, dynamic>? rawPermisos) async {
    setState(() {
      _selectedEmployeeId = employeeId;
      _selectedEmployeeName = employeeName;
      _draftPermissions = _normalizePermissions(rawPermisos);
    });

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.72,
              minChildSize: 0.5,
              maxChildSize: 0.92,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 64,
                            height: 6,
                            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Editar permisos de $_selectedEmployeeName",
                          style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, color: azulProfundo),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Activa o desactiva las secciones visibles en el menú lateral para este empleado.",
                          style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        ..._permissionOptions.map((option) {
                          final key = option['key'] as String;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: SwitchListTile(
                              value: _draftPermissions[key] ?? false,
                              onChanged: (value) {
                                modalSetState(() {
                                  _draftPermissions[key] = value;
                                });
                              },
                              activeColor: azulProfundo,
                              activeTrackColor: azulProfundo.withOpacity(0.45),
                              inactiveTrackColor: Colors.grey[300],
                              inactiveThumbColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              title: Text(option['label'] as String, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                              secondary: CircleAvatar(
                                radius: 20,
                                backgroundColor: azulProfundo.withOpacity(0.12),
                                child: Icon(option['icon'] as IconData, color: azulProfundo, size: 20),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              tileColor: Colors.white,
                            ),
                          );
                        }),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: azulProfundo,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _isSaving ? null : _savePermissions,
                          icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_alt_rounded),
                          label: Text(_isSaving ? 'Guardando...' : 'Guardar cambios', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _savePermissions() async {
    if (_selectedEmployeeId.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await _db.collection('empleado').doc(_selectedEmployeeId).set({
        'permisos': _draftPermissions,
      }, SetOptions(merge: true));
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permisos actualizados para $_selectedEmployeeName.')), 
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudieron guardar los permisos. Intenta de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _isCurrentUserSuperAdmin() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email?.toLowerCase() == 'omar_admin@gmail.com';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = _isCurrentUserSuperAdmin();

    if (!isSuperAdmin) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: azulProfundo,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text('Control de Accesos', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        backgroundColor: const Color(0xFFF4F7F6),
        body: Center(
          child: Text(
            'Acceso restringido. Solo el Superdesarrollador puede administrar permisos.',
            style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: azulProfundo,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Control de Accesos', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      backgroundColor: const Color(0xFFF4F7F6),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('empleado').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar empleados: ${snapshot.error}',
                style: GoogleFonts.inter(color: Colors.red[700], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final empleados = snapshot.data!.docs.where((doc) {
            final cargo = (doc.data() as Map<String, dynamic>)['cargo']?.toString().toLowerCase().trim();
            return cargo == 'administrador' || cargo == 'admin';
          }).toList()
            ..sort((a, b) {
              final aName = (a.data() as Map<String, dynamic>)['nombre']?.toString() ?? '';
              final bName = (b.data() as Map<String, dynamic>)['nombre']?.toString() ?? '';
              return aName.compareTo(bName);
            });
          if (empleados.isEmpty) {
            return Center(
              child: Text(
                'No se encontraron empleados con rol Administrador. Revisa que el campo cargo exista y esté escrito como Administrador.',
                style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          final filteredEmpleados = empleados.where((empleado) {
            final data = empleado.data() as Map<String, dynamic>;
            final nombre = data['nombre']?.toString().toLowerCase() ?? '';
            final correo = data['correo']?.toString().toLowerCase() ?? '';
            final query = _searchQuery.toLowerCase();
            return nombre.contains(query) || correo.contains(query);
          }).toList();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 2,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Superdesarrollador: ${isSuperAdmin ? 'Activo' : 'No autorizado'}', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 15, color: azulProfundo)),
                        const SizedBox(height: 8),
                        Text('Selecciona un administrador para asignar o retirar permisos de las secciones del menú lateral.', style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 14)),
                        const SizedBox(height: 18),
                        TextField(
                          key: const Key('permission_search_field'),
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          textInputAction: TextInputAction.search,
                          enableSuggestions: false,
                          autocorrect: false,
                          keyboardType: TextInputType.text,
                          onChanged: (value) {
                            if (_searchQuery != value) {
                              setState(() => _searchQuery = value);
                            }
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            hintText: 'Buscar por nombre o correo...',
                            hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                            filled: true,
                            fillColor: const Color(0xFFF7F8FB),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            Chip(
                              backgroundColor: azulProfundo.withOpacity(0.08),
                              label: Text('${empleados.length} administradores', style: GoogleFonts.inter(color: azulProfundo, fontWeight: FontWeight.w600)),
                            ),
                            Chip(
                              backgroundColor: isSuperAdmin ? Colors.green.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
                              label: Text(isSuperAdmin ? 'Superadmin: permisos completos' : 'Solo administradores visibles', style: GoogleFonts.inter(color: isSuperAdmin ? Colors.green[800] : Colors.orange[800], fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (filteredEmpleados.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text('No se encontró ningún administrador con esa búsqueda.', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 15)),
                    ),
                  )
                else ...[
                  Text('${filteredEmpleados.length} administradores encontrados', style: GoogleFonts.montserrat(color: Colors.grey[800], fontSize: 13)),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredEmpleados.length,
                      itemBuilder: (context, index) {
                        final empleado = filteredEmpleados[index];
                        final data = empleado.data() as Map<String, dynamic>;
                        final nombre = data['nombre']?.toString() ?? 'Empleado sin nombre';
                        final correo = data['correo']?.toString() ?? 'correo@desconocido.com';
                        final permisos = data['permisos'] as Map<String, dynamic>?;

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _showPermissionEditor(empleado.id, nombre, permisos),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: azulProfundo.withOpacity(0.12),
                                    child: Text(
                                      nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                                      style: TextStyle(color: azulProfundo, fontWeight: FontWeight.bold, fontSize: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(child: Text(nombre, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 16))),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.16),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text('ADMIN', style: GoogleFonts.inter(color: Colors.green[800], fontWeight: FontWeight.w600, fontSize: 11)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(correo, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13)),
                                        const SizedBox(height: 14),
                                        if (_activePermissionCount(permisos) > 0) ...[
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: _activePermissionItems(permisos)
                                                .take(4)
                                                .map((item) => Chip(
                                                      backgroundColor: azulProfundo.withOpacity(0.1),
                                                      label: Text(item['label'] as String, style: TextStyle(color: azulProfundo, fontSize: 12, fontWeight: FontWeight.w600)),
                                                    ))
                                                .toList(),
                                          ),
                                          const SizedBox(height: 10),
                                          Text('${_activePermissionCount(permisos)} permisos activos', style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 12)),
                                        ] else ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: Text('Sin permisos asignados', style: GoogleFonts.inter(color: Colors.orange[800], fontSize: 12)),
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(color: azulProfundo.withOpacity(0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.chevron_right_rounded, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
