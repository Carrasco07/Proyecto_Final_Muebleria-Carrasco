import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:csv/csv.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
class GestionModuloScreen extends StatefulWidget {
  final String modulo;
  const GestionModuloScreen({super.key, required this.modulo});

  @override
  State<GestionModuloScreen> createState() => _GestionModuloScreenState();
}

class _GestionModuloScreenState extends State<GestionModuloScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Color azulProfundo = const Color(0xFF2C3E50);
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _tableScrollController = ScrollController();
  late Stream<QuerySnapshot> _stream;
  String _filtroBusqueda = "";
  bool _isAdmin = false;
  String _userName = "Usuario";

  @override
  void initState() {
    super.initState();
    _stream = _db.collection(widget.modulo).limit(20).snapshots();
    _checkRoleAndUser();
  }

  @override
  void dispose() {
    _tableScrollController.dispose();
    _searchController.dispose();
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _checkRoleAndUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        var snap = await _db.collection('empleados').doc(user.uid).get();
        if (snap.exists && snap.data()?['nombre'] != null) {
          String raw = snap.data()?['nombre'] ?? 'Usuario';
          if (raw.isNotEmpty) raw = raw[0].toUpperCase() + raw.substring(1).toLowerCase();
          setState(() {
            _userName = raw;
            _isAdmin = snap.data()?['cargo'] == 'Administrador';
          });
          return;
        }
      } catch (e) {
        // Fallback
      }

      try {
        var snap2 = await _db.collection('empleado').where('correo', isEqualTo: user.email).get();
        if (snap2.docs.isNotEmpty) {
          var data = snap2.docs.first.data();
          String raw = data['nombre'] ?? 'Empleado';
          if (raw.isNotEmpty) raw = raw[0].toUpperCase() + raw.substring(1).toLowerCase();
          setState(() {
            _isAdmin = data['cargo'] == 'Administrador';
            _userName = raw;
          });
          return;
        }
      } catch (e) {
        // Fallback
      }

      if (user.email != null && user.email!.isNotEmpty) {
        String rawName = user.email!.split('@')[0].split('_')[0];
        if (rawName.isNotEmpty) {
          rawName = rawName[0].toUpperCase() + rawName.substring(1).toLowerCase();
        }
        setState(() {
          _userName = rawName;
          _isAdmin = true;
        });
      }
    }
  }

  Future<void> _registrarAuditoria(String accion) async {
    await _db.collection('auditoria').add({
      'accion': '[$_userName] $accion en ${widget.modulo.toUpperCase()}',
      'fecha': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      'usuario': _userName,
    });
  }

  Map<String, dynamic> _getModuloConfig() {
    switch (widget.modulo) {
      case 'cliente': return {'titulo': 'Clientes', 'icon': Icons.people, 'fields': [{'name': 'nombre', 'label': 'Nombre', 'icon': Icons.person}, {'name': 'telefono', 'label': 'Teléfono', 'icon': Icons.phone}, {'name': 'correo', 'label': 'Correo', 'icon': Icons.email}, {'name': 'direccion', 'label': 'Dirección', 'icon': Icons.home}, {'name': 'fecha_registro', 'label': 'Fecha Registro', 'icon': Icons.calendar_today, 'type': 'date'}]};
      case 'empleado': return {'titulo': 'Empleados', 'icon': Icons.badge, 'fields': [{'name': 'nombre', 'label': 'Nombre', 'icon': Icons.person}, {'name': 'cargo', 'label': 'Cargo', 'icon': Icons.work}, {'name': 'telefono', 'label': 'Teléfono', 'icon': Icons.phone}, {'name': 'correo', 'label': 'Correo', 'icon': Icons.email}, {'name': 'fecha_contrato', 'label': 'Fecha Contrato', 'icon': Icons.calendar_month, 'type': 'date'}]};
      case 'categoria': return {'titulo': 'Categorías', 'icon': Icons.category, 'fields': [{'name': 'nombre', 'label': 'Nombre Categoría', 'icon': Icons.label}, {'name': 'descripcion', 'label': 'Descripción', 'icon': Icons.description}]};
      case 'proveedor': return {'titulo': 'Proveedores', 'icon': Icons.local_shipping, 'fields': [{'name': 'nombre', 'label': 'Nombre Empresa', 'icon': Icons.business}, {'name': 'contacto', 'label': 'Contacto', 'icon': Icons.person}, {'name': 'telefono', 'label': 'Teléfono', 'icon': Icons.phone}, {'name': 'pais', 'label': 'País', 'icon': Icons.public}]};
      case 'productos': return {'titulo': 'Productos', 'icon': Icons.chair, 'fields': [{'name': 'id_categoria', 'label': 'Categoría', 'icon': Icons.category, 'relation': 'categoria'}, {'name': 'id_proveedor', 'label': 'Proveedor', 'icon': Icons.local_shipping, 'relation': 'proveedor'}, {'name': 'nombre', 'label': 'Nombre Producto', 'icon': Icons.edit}, {'name': 'descripcion', 'label': 'Descripción', 'icon': Icons.description}, {'name': 'precio', 'label': 'Precio', 'icon': Icons.attach_money, 'type': 'decimal'}, {'name': 'material', 'label': 'Material', 'icon': Icons.architecture}, {'name': 'imagen', 'label': 'URL Imagen', 'icon': Icons.image}]};
      case 'pedido': return {'titulo': 'Pedidos', 'icon': Icons.assignment, 'fields': [{'name': 'id_cliente', 'label': 'Cliente', 'icon': Icons.person, 'relation': 'cliente'}, {'name': 'id_empleado', 'label': 'Vendedor', 'icon': Icons.badge, 'relation': 'empleado', 'filter': {'field': 'cargo', 'value': 'Vendedor'}}, {'name': 'fecha_pedido', 'label': 'Fecha Pedido', 'icon': Icons.calendar_today, 'type': 'date'}, {'name': 'estado', 'label': 'Estado', 'icon': Icons.sync, 'options': ['Pendiente', 'En Camino', 'Entregado', 'Rechazado']}, {'name': 'total', 'label': 'Total', 'icon': Icons.attach_money, 'type': 'decimal'}]};
      case 'detalle_pedido': return {'titulo': 'Detalles de Pedido', 'icon': Icons.list_alt, 'fields': [{'name': 'id_pedido', 'label': 'Pedido', 'icon': Icons.receipt, 'relation': 'pedido'}, {'name': 'id_producto', 'label': 'Producto', 'icon': Icons.chair, 'relation': 'productos'}, {'name': 'cantidad', 'label': 'Cantidad', 'icon': Icons.add_shopping_cart, 'type': 'number'}, {'name': 'precio_unitario', 'label': 'Precio Unitario', 'icon': Icons.attach_money, 'type': 'decimal'}, {'name': 'subtotal', 'label': 'Subtotal', 'icon': Icons.money, 'type': 'decimal'}]};
      case 'factura': return {'titulo': 'Facturas', 'icon': Icons.description, 'fields': [{'name': 'id_pedido', 'label': 'Pedido', 'icon': Icons.receipt, 'relation': 'pedido'}, {'name': 'fecha_emision', 'label': 'Fecha Emisión', 'icon': Icons.calendar_month, 'type': 'date'}, {'name': 'subtotal', 'label': 'Subtotal', 'icon': Icons.money, 'type': 'decimal'}, {'name': 'iva', 'label': 'IVA', 'icon': Icons.percent, 'type': 'decimal'}, {'name': 'total', 'label': 'Total', 'icon': Icons.attach_money, 'type': 'decimal'}, {'name': 'rfc_cliente', 'label': 'RFC Cliente', 'icon': Icons.assignment_ind}]};
      case 'pago': return {'titulo': 'Pagos', 'icon': Icons.payments, 'fields': [{'name': 'id_factura', 'label': 'Factura', 'icon': Icons.description, 'relation': 'factura'}, {'name': 'fecha_pago', 'label': 'Fecha Pago', 'icon': Icons.calendar_today, 'type': 'date'}, {'name': 'metodo', 'label': 'Método', 'icon': Icons.payment}, {'name': 'monto', 'label': 'Monto', 'icon': Icons.attach_money, 'type': 'decimal'}, {'name': 'referencia', 'label': 'Referencia', 'icon': Icons.confirmation_number}]};
      case 'almacen': return {'titulo': 'Almacenes', 'icon': Icons.warehouse, 'fields': [{'name': 'nombre', 'label': 'Nombre Almacén', 'icon': Icons.badge}, {'name': 'ubicacion', 'label': 'Ubicación', 'icon': Icons.location_on}, {'name': 'responsable', 'label': 'Responsable', 'icon': Icons.person}]};
      case 'inventario': return {'titulo': 'Inventario', 'icon': Icons.storage, 'fields': [{'name': 'id_producto', 'label': 'Producto', 'icon': Icons.chair, 'relation': 'productos'}, {'name': 'id_almacen', 'label': 'Almacén', 'icon': Icons.warehouse, 'relation': 'almacen'}, {'name': 'stock_actual', 'label': 'Stock Actual', 'icon': Icons.inventory, 'type': 'number'}, {'name': 'stock_minimo', 'label': 'Stock Mínimo', 'icon': Icons.warning, 'type': 'number'}, {'name': 'ultima_actualizacion', 'label': 'Última Actualización', 'icon': Icons.update, 'type': 'date'}]};
      default: return {'titulo': 'Módulo', 'fields': []};
    }
  }

  @override
  Widget build(BuildContext context) {
    var config = _getModuloConfig();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(config['titulo'], style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: azulProfundo,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return _buildShimmerLoading();
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Column(
              children: [
                _buildAuditBanner(isDark),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: const BorderRadius.vertical(top: Radius.circular(40))),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSearchAndActionRow(docs, config, isDark),
                          const SizedBox(height: 30),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.inbox, size: 100, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text("No hay datos en este módulo", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 8),
                                const Text("Presiona Nuevo para crear el primer registro.", style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          var filteredDocs = docs;
          if (_filtroBusqueda.isNotEmpty) {
            filteredDocs = docs.where((doc) => doc.data().toString().toLowerCase().contains(_filtroBusqueda.toLowerCase())).toList();
          }
          return Column(children: [_buildAuditBanner(isDark), Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: const BorderRadius.vertical(top: Radius.circular(40))), child: SingleChildScrollView(padding: const EdgeInsets.all(30), child: Column(children: [_buildSearchAndActionRow(filteredDocs, config, isDark), const SizedBox(height: 30), _buildModernTable(filteredDocs, config, isDark)]))))]);
        },
      ),
    );
  }

  Widget _buildAuditBanner(bool isDark) => Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20), color: Colors.green.withOpacity(0.1), child: Row(children: [const Icon(Icons.security_rounded, color: Colors.green, size: 16), const SizedBox(width: 10), Text("AUDITORÍA ACTIVA: Registrando como $_userName", style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold))]));

  Widget _buildSearchAndActionRow(List<QueryDocumentSnapshot> docs, Map<String, dynamic> config, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _filtroBusqueda = v),
            decoration: const InputDecoration(icon: Icon(Icons.search), hintText: "Buscar...", border: InputBorder.none),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(width: 140, child: _exportBtn(Icons.table_chart, Colors.green, "Excel CSV", () => _exportToCSV(docs, config))),
              SizedBox(width: 140, child: _exportBtn(Icons.picture_as_pdf, Colors.red, "Reporte PDF", () => _exportToPDF(docs, config))),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulProfundo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  minimumSize: const Size(130, 44),
                ),
                onPressed: () => _abrirFormulario(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Nuevo"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _exportBtn(IconData i, Color c, String l, VoidCallback t) => InkWell(onTap: t, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withOpacity(0.3))), child: Row(children: [Icon(i, color: c, size: 18), const SizedBox(width: 5), Text(l, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12))])));

  Future<void> _exportToCSV(List<QueryDocumentSnapshot> docs, Map<String, dynamic> config) async {
    List<List<dynamic>> rows = [];
    rows.add(config['fields'].map((f) => f['label']).toList());
    for (var doc in docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      rows.add(config['fields'].map((f) => data[f['name']]?.toString() ?? '-').toList());
    }
    String csvString = csv.encode(rows);
    final bytes = utf8.encode(csvString);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement..href = url..style.display = 'none'..download = 'reporte_${widget.modulo}.csv';
    html.document.body!.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    _registrarAuditoria("Generó Reporte CSV Excel");
  }

  Future<void> _exportToPDF(List<QueryDocumentSnapshot> docs, Map<String, dynamic> config) async {
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final pdf = pw.Document(theme: pw.ThemeData.withFont(base: font, bold: fontBold));
    pdf.addPage(pw.MultiPage(build: (context) => [pw.Header(level: 0, child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("MUEBLERÍA CARRASCO - Reporte de ${config['titulo']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now()))])), pw.Table.fromTextArray(context: context, data: [config['fields'].map((f) => f['label']).toList(), ...docs.map((doc) => config['fields'].map((f) => (doc.data() as Map<String, dynamic>)[f['name']]?.toString() ?? '-').toList())])]));
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
    _registrarAuditoria("Generó Reporte PDF");
  }

  Widget _buildModernTable(List<QueryDocumentSnapshot> docs, Map<String, dynamic> config, bool isDark) {
    List<dynamic> fields = config['fields'];
    return Scrollbar(
      controller: _tableScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _tableScrollController,
        child: DataTable(
          columns: [
            const DataColumn(label: Text("ID")),
            ...fields.map((f) => DataColumn(label: Text(f['label']))).toList(),
            const DataColumn(label: Text("Acciones")),
          ],
          rows: docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return DataRow(cells: [
              DataCell(
                Tooltip(
                  message: "ID Completo: ${doc.id}",
                  child: Text(
                    doc.id.substring(0, 4),
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              ...fields.map((f) => DataCell(_buildCell(f, data))).toList(),
              DataCell(
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _abrirFormulario(doc: doc)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmarBorrado(doc, data)),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCell(Map<String, dynamic> f, Map<String, dynamic> data) {
    dynamic v = data[f['name']];
    String val = v?.toString() ?? '-';
    if (f.containsKey('relation') && val != '-') {
      return RelationCell(relation: f['relation'], docId: val);
    }
    if (f['name'] == 'estado' && widget.modulo == 'pedido') {
      Color bg = Colors.grey.withOpacity(0.2);
      Color text = Colors.grey;
      if (val == 'Pendiente') { bg = Colors.orange.withOpacity(0.15); text = Colors.orange; }
      else if (val == 'En Camino') { bg = Colors.blue.withOpacity(0.15); text = Colors.blue; }
      else if (val == 'Entregado') { bg = Colors.green.withOpacity(0.15); text = Colors.green; }
      else if (val == 'Rechazado') { bg = Colors.red.withOpacity(0.15); text = Colors.red; }
      return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: text.withOpacity(0.3))), child: Text(val, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 11)));
    }
    if (f['name'] == 'stock_actual' && widget.modulo == 'inventario') {
      int current = int.tryParse(val) ?? 0;
      int min = int.tryParse(data['stock_minimo']?.toString() ?? '5') ?? 5;
      Color bg = Colors.green.withOpacity(0.15);
      Color text = Colors.green;
      if (current <= min) { bg = Colors.red.withOpacity(0.15); text = Colors.red; }
      else if (current <= min + 3) { bg = Colors.amber.withOpacity(0.15); text = Colors.amber; }
      return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: text.withOpacity(0.3))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inventory_2_rounded, size: 12, color: text), const SizedBox(width: 5), Text(val, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 11))]));
    }
    if (f['type'] == 'decimal' || f['name'] == 'total' || f['name'] == 'precio' || f['name'] == 'precio_unitario' || f['name'] == 'subtotal') {
      return Text(NumberFormat.simpleCurrency().format(double.tryParse(val) ?? 0.0), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal));
    }
    return Text(val);
  }

  Future<void> _confirmarBorrado(QueryDocumentSnapshot doc, Map<String, dynamic> data) async {
    String identificador = data['nombre'] ?? data['cliente'] ?? data['total']?.toString() ?? doc.id.substring(0, 5);
    var config = _getModuloConfig();
    List<Widget> dataFields = [];
    for(var f in config['fields']) {
       String val = data[f['name']]?.toString() ?? '-';
       dataFields.add(Padding(padding: const EdgeInsets.only(bottom: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(f['icon'] ?? Icons.info, size: 16, color: azulProfundo.withOpacity(0.5)), const SizedBox(width: 10), Expanded(child: Text("${f['label']}: $val", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)))])));
    }
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
    bool hasDependencies = false;
    String dependencyMsg = "";
    if (widget.modulo == 'cliente') {
      var snap = await _db.collection('pedido').where('id_cliente', isEqualTo: doc.id).get();
      if (snap.docs.isNotEmpty) { hasDependencies = true; dependencyMsg = "Tiene ${snap.docs.length} pedidos activos."; }
    } else if (widget.modulo == 'productos') {
      var snap2 = await _db.collection('detalle_pedido').where('id_producto', isEqualTo: doc.id).get();
      if (snap2.docs.isNotEmpty) { hasDependencies = true; dependencyMsg = "Está registrado en pedidos históricos del sistema."; }
    } else if (widget.modulo == 'almacen') {
      var snap = await _db.collection('inventario').where('id_almacen', isEqualTo: doc.id).get();
      if (snap.docs.isNotEmpty) { hasDependencies = true; dependencyMsg = "Tiene productos en inventario."; }
    }
    if (mounted) Navigator.pop(context);

    if (hasDependencies) {
      return showDialog(context: context, builder: (c) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), title: Row(children: [const Icon(Icons.error, color: Colors.red), const SizedBox(width: 10), const Text("No se puede borrar")]), content: Text("No puedes eliminar este registro porque:\n\n$dependencyMsg\n\nDebes eliminar sus dependencias primero.", style: const TextStyle(fontWeight: FontWeight.bold)), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("ENTENDIDO", style: TextStyle(color: Colors.grey)))]));
    }
    return showDialog(context: context, builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 28)), const SizedBox(width: 15), Text("Eliminar Registro", style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 22))]),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("¿Estás completamente seguro de eliminar este registro? Esta acción borrará permanentemente los siguientes datos:", style: TextStyle(fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.withOpacity(0.2))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Tooltip(message: "Full ID: ${doc.id}", child: Text("ID: ${doc.id.substring(0, 8)}", style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
              const Divider(height: 20),
              ...dataFields
            ])),
          ]
        )
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("CANCELAR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))), ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () async {
        _registrarAuditoria("Eliminó Registro: $identificador (${doc.id})");
        
        if (widget.modulo == 'productos') {
          // Borrar en cascada registros del inventario asociados a este producto
          try {
            var invSnap = await _db.collection('inventario').where('id_producto', isEqualTo: doc.id).get();
            for (var d in invSnap.docs) {
              await _db.collection('inventario').doc(d.id).delete();
            }
          } catch(e) {}
        }

        if (widget.modulo == 'empleado' || widget.modulo == 'proveedor' || widget.modulo == 'productos') {
          await _db.collection('notificaciones').add({
            'titulo': '⚠️ Alerta de Seguridad',
            'mensaje': 'El usuario "$_userName" eliminó el registro "$identificador" del módulo de ${config['titulo'] ?? widget.modulo.toUpperCase()}.',
            'fecha': FieldValue.serverTimestamp(),
            'leido': false,
            'icono': 'security'
          });
        } else {
          await _db.collection('notificaciones').add({
            'titulo': '🗑️ Registro Eliminado',
            'mensaje': 'El usuario "$_userName" eliminó el registro "$identificador" del módulo de ${config['titulo'] ?? widget.modulo.toUpperCase()}.',
            'fecha': FieldValue.serverTimestamp(),
            'leido': false,
            'icono': 'delete'
          });
        }
        
        await _db.collection(widget.modulo).doc(doc.id).delete();
        Navigator.pop(c);
      }, icon: const Icon(Icons.delete, size: 18), label: const Text("ELIMINAR", style: TextStyle(fontWeight: FontWeight.bold)))]
    ));
  }

    Future<void> _abrirFormulario({QueryDocumentSnapshot? doc}) async {
    var config = _getModuloConfig();
    Map<String, List<Map<String, dynamic>>> dropdownData = {};
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
    try {
      for (var f in config['fields']) {
        _controllers[f['name']] = TextEditingController(text: doc != null ? (doc.data() as Map<String, dynamic>)[f['name']]?.toString() ?? '' : '');
        if (f.containsKey('relation')) {
          var snap = await _db.collection(f['relation']).get();
          dropdownData[f['name']] = snap.docs.map((d) => {'id': d.id, 'label': (d.data() as Map<String, dynamic>)['nombre'] ?? d.id}).toList();
        }
      }
    } finally {
      if (mounted) Navigator.pop(context);
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) {
          final rows = config['fields'].map<TableRow>((f) {
            Widget fieldWidget;
            if (f.containsKey('options')) {
              fieldWidget = DropdownButtonFormField<String>(
                value: _controllers[f['name']]!.text.isEmpty ? null : _controllers[f['name']]!.text,
                items: (f['options'] as List<String>).map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                onChanged: (v) {
                  _controllers[f['name']]!.text = v ?? '';
                  setDialogState(() {});
                },
                decoration: InputDecoration(labelText: f['label'], prefixIcon: Icon(f['icon'] ?? Icons.list), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
              );
            } else if (f.containsKey('relation')) {
              var items = dropdownData[f['name']] ?? [];
              var currentValue = _controllers[f['name']]!.text;
              bool valueExists = items.any((it) => it['id'] == currentValue);
              String? selectedId = valueExists ? currentValue : null;
              fieldWidget = DropdownButtonFormField<String>(
                value: selectedId,
                items: items.map((it) => DropdownMenuItem(value: it['id'] as String, child: Text(it['label']))).toList(),
                onChanged: (v) {
                  _controllers[f['name']]!.text = v ?? '';
                  setDialogState(() {});
                },
                decoration: InputDecoration(labelText: f['label'], prefixIcon: Icon(f['icon'] ?? Icons.link), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), helperText: !valueExists && currentValue.isNotEmpty ? "Referencia no encontrada" : null),
              );
            } else if (f['type'] == 'date') {
              fieldWidget = TextField(
                controller: _controllers[f['name']],
                readOnly: true,
                decoration: InputDecoration(labelText: f['label'], prefixIcon: const Icon(Icons.calendar_month), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101));
                  if (pickedDate != null) {
                    _controllers[f['name']]!.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                    setDialogState(() {});
                  }
                },
              );
            } else {
              fieldWidget = TextField(
                controller: _controllers[f['name']],
                decoration: InputDecoration(labelText: f['label'], prefixIcon: Icon(f['icon'] ?? Icons.edit), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
              );
            }
            return TableRow(children: [
              Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(f['label'], style: const TextStyle(fontWeight: FontWeight.bold))),
              Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: fieldWidget),
            ]);
          }).toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text(doc == null ? "Nuevo Registro" : "Modificar Datos", style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 22)),
            content: SizedBox(
              width: 550,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(18), color: Theme.of(context).cardColor),
                      padding: const EdgeInsets.all(16),
                      child: Table(
                        columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: rows,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulProfundo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Map<String, dynamic> data = {};
                  for (var f in config['fields']) {
                    var v = _controllers[f['name']]!.text;
                    if (f['type'] == 'number') {
                      data[f['name']] = int.tryParse(v) ?? 0;
                    } else if (f['type'] == 'decimal') {
                      data[f['name']] = double.tryParse(v) ?? 0.0;
                    } else {
                      data[f['name']] = v;
                    }
                  }

                  if (doc == null) {
                    await _db.collection(widget.modulo).add(data);
                    _registrarAuditoria("Creó Nuevo Registro");
                  } else {
                    await _db.collection(widget.modulo).doc(doc.id).update(data);
                    _registrarAuditoria("Editó Registro ${doc.id}");
                  }

                  if (mounted) Navigator.pop(context);
                },
                child: const Text("GUARDAR", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
Widget _buildShimmerLoading() => Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Column(children: List.generate(5, (i) => Container(height: 70, margin: const EdgeInsets.all(10), color: Colors.white))));
}

class RelationCell extends StatefulWidget {
  final String relation;
  final String docId;

  const RelationCell({
    super.key,
    required this.relation,
    required this.docId,
  });

  @override
  State<RelationCell> createState() => _RelationCellState();
}

class _RelationCellState extends State<RelationCell> {
  static final Map<String, Map<String, dynamic>> _cache = {};
  bool _loading = false;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant RelationCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.relation != widget.relation || oldWidget.docId != widget.docId) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (widget.docId.isEmpty || widget.docId == '-') {
      if (mounted) {
        setState(() {
          _data = null;
          _error = null;
        });
      }
      return;
    }

    final cacheKey = '${widget.relation}/${widget.docId}';
    if (_cache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _data = _cache[cacheKey];
          _loading = false;
          _error = null;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      Map<String, dynamic>? foundData;
      final primaryDoc = await FirebaseFirestore.instance
          .collection(widget.relation)
          .doc(widget.docId)
          .get();

      if (primaryDoc.exists && primaryDoc.data() != null) {
        foundData = primaryDoc.data();
      } else {
        final normalizedId = widget.docId.trim();
        if (normalizedId.isNotEmpty) {
          final backupQuery = await FirebaseFirestore.instance
              .collection(widget.relation)
              .where('nombre', isEqualTo: normalizedId)
              .limit(1)
              .get();

          if (backupQuery.docs.isNotEmpty && backupQuery.docs.first.data() != null) {
            foundData = backupQuery.docs.first.data() as Map<String, dynamic>?;
          } else if (widget.relation == 'productos') {
            final searchQuery = await FirebaseFirestore.instance
                .collection(widget.relation)
                .where('nombre_producto', isEqualTo: normalizedId)
                .limit(1)
                .get();
            if (searchQuery.docs.isNotEmpty && searchQuery.docs.first.data() != null) {
              foundData = searchQuery.docs.first.data() as Map<String, dynamic>?;
            }
          }
        }
      }

      if (foundData != null) {
        _cache[cacheKey] = foundData;
        if (mounted) {
          setState(() {
            _data = foundData;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'No encontrado';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.docId.isEmpty || widget.docId == '-') {
      return const Text('-');
    }

    if (_loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          widget.docId.length > 6 ? '${widget.docId.substring(0, 6)}...' : widget.docId,
          style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
        ),
      );
    }

    if (_error != null) {
      return Tooltip(
        message: 'Relación no encontrada o inválida. (${_error})',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.redAccent.shade700),
                const SizedBox(width: 4),
                Text(
                  widget.docId.length > 6 ? '${widget.docId.substring(0, 6)}...' : widget.docId,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = _data;
    if (data == null) {
      return Text(widget.docId);
    }

    // Determine descriptive display name
    String displayName = data['nombre'] ?? data['nombre_producto'] ?? data['nombre_almacen'] ?? '';
    if (displayName.isEmpty) {
      displayName = data['contacto'] ?? data['responsable'] ?? '';
    }
    if (displayName.isEmpty && widget.relation == 'pedido') {
      displayName = 'Pedido #${widget.docId.substring(0, 5)}';
    }
    if (displayName.isEmpty && widget.relation == 'factura') {
      displayName = 'Factura #${widget.docId.substring(0, 5)}';
    }
    if (displayName.isEmpty) {
      displayName = widget.docId.length > 8 ? widget.docId.substring(0, 8) : widget.docId;
    }

    // Build the tooltip text beautifully
    final tooltipLines = <String>[];
    if (displayName.isNotEmpty && displayName != widget.docId) {
      tooltipLines.add('Nombre: $displayName');
    }
    tooltipLines.add('ID Completo: ${widget.docId}');
    data.forEach((key, val) {
      if (val != null && val.toString().isNotEmpty) {
        if (key.startsWith('id_') || key == 'id' || key == 'nombre' || key == 'nombre_producto' || key == 'nombre_almacen' || key == 'contacto' || key == 'responsable' || key == 'imagen') return;
        String label = key[0].toUpperCase() + key.substring(1).replaceAll('_', ' ');
        tooltipLines.add('$label: $val');
      }
    });

    final displayText = displayName.isNotEmpty ? displayName : (widget.docId.length > 8 ? '${widget.docId.substring(0, 8)}...' : widget.docId);
    final displayId = widget.docId.length > 8 ? '${widget.docId.substring(0, 8)}...' : widget.docId;

    return Tooltip(
      richMessage: TextSpan(
        children: [
          TextSpan(
            text: '${widget.relation.toUpperCase()} DETALLES\n',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent, fontSize: 13),
          ),
          ...tooltipLines.map((line) {
            if (line.startsWith('ID Completo:')) {
              return TextSpan(text: '\n$line', style: const TextStyle(color: Colors.white70, fontSize: 11));
            }
            final parts = line.split(':');
            if (parts.length >= 2) {
              final label = parts[0];
              final value = parts.sublist(1).join(':');
              return TextSpan(
                children: [
                  TextSpan(text: '\n$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  TextSpan(text: value, style: TextStyle(color: Colors.white.withOpacity(0.9))),
                ],
              );
            }
            return TextSpan(text: '\n$line', style: const TextStyle(color: Colors.white));
          }),
        ],
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      preferBelow: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForRelation(widget.relation),
              size: 14,
              color: Colors.blue[700],
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                displayText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            if (displayText != displayId) ...[
              const SizedBox(width: 6),
              Text(
                '($displayId)',
                style: TextStyle(color: Colors.blue[600], fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconForRelation(String rel) {
    switch (rel) {
      case 'cliente': return Icons.person;
      case 'empleado': return Icons.badge;
      case 'categoria': return Icons.category;
      case 'proveedor': return Icons.local_shipping;
      case 'productos': return Icons.chair;
      case 'pedido': return Icons.assignment;
      case 'factura': return Icons.description;
      case 'almacen': return Icons.warehouse;
      default: return Icons.link;
    }
  }
}

