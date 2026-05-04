import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:lottie/lottie.dart'; // Removido por no usarse
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // Importado para formato de moneda

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});
  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final _db = FirebaseFirestore.instance;
  final Color azulGris = const Color(0xFF2C3E50);

  final _nombre = TextEditingController();
  final _categoria = TextEditingController();
  final _precio = TextEditingController();
  final _stock = TextEditingController();
  final _material = TextEditingController();

  Widget _badgeStock(int stock) {
    Color color = Colors.green;
    if (stock <= 5) color = Colors.red;
    else if (stock <= 15) color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text('$stock', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  void _abrirFormulario({String? docId, Map<String, dynamic>? data}) {
    if (data != null) {
      _nombre.text = data['Nombre'] ?? '';
      _categoria.text = data['Categoría'] ?? '';
      _precio.text = data['Precio'].toString();
      _stock.text = data['Stock'].toString();
      _material.text = data['Material'] ?? '';
    } else {
      _nombre.clear(); _categoria.clear(); _precio.clear(); _stock.clear(); _material.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: azulGris,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(docId == null ? "Registrar Nuevo Producto" : "Editar Producto",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _input("Nombre del Mueble", _nombre, Icons.chair),
                    _input("Categoría", _categoria, Icons.category_outlined),
                    Row(children: [
                      Expanded(child: _input("Precio", _precio, Icons.attach_money, true, true)),
                      const SizedBox(width: 10),
                      Expanded(child: _input("Stock", _stock, Icons.inventory_2_outlined, true)),
                    ]),
                    _input("Material principal", _material, Icons.handyman_outlined),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
            onPressed: () {
              final d = {
                "Nombre": _nombre.text,
                "Categoría": _categoria.text,
                // Eliminamos comas de miles antes de parsear para evitar errores con decimales
                "Precio": double.tryParse(_precio.text.replaceAll(',', '')) ?? 0.0,
                "Stock": int.tryParse(_stock.text) ?? 0,
                "Material": _material.text,
              };
              docId == null ? _db.collection('muebles').add(d) : _db.collection('muebles').doc(docId).update(d);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.save),
            label: const Text("Guardar Producto"),
          )
        ],
      ),
    );
  }

  void _confirmarBorrado(String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              color: Colors.red[700],
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Text("Confirmar Eliminación", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Animación de basura nativa en Flutter (sin depender de LottieFiles)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, -10 * (1 - value)), // Efecto de caída
                        child: Opacity(
                          opacity: value,
                          child: const Icon(Icons.delete_sweep, color: Colors.red, size: 70),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text("¿Estás seguro de eliminar este producto?", textAlign: TextAlign.center),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Nombre: ${data['Nombre'] ?? '-'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text("Categoría: ${data['Categoría'] ?? '-'}"),
                        const SizedBox(height: 5),
                        Text("Precio: \$${data['Precio'] ?? '0'}"),
                        const SizedBox(height: 5),
                        Text("Stock: ${data['Stock'] ?? '0'}"),
                        const SizedBox(height: 5),
                        Text("Material: ${data['Material'] ?? '-'}"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () { _db.collection('muebles').doc(docId).delete(); Navigator.pop(context); },
            child: const Text("Confirmar Borrado", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _input(String l, TextEditingController c, IconData i, [bool n = false, bool d = false]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          TextField(
            controller: c, 
            keyboardType: d 
                ? const TextInputType.numberWithOptions(decimal: true) 
                : (n ? TextInputType.number : TextInputType.text),
            decoration: InputDecoration(
              prefixIcon: Icon(i, color: azulGris, size: 18),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(
                  value.contains('\$') ? value : value, // El valor ya vendrá formateado
                  style: TextStyle(color: azulGris, fontSize: 20, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- AYUDANTE PARA TARJETAS EN WRAP ---
  Widget _buildAdaptiveSummaryCard(BuildContext context, BoxConstraints constraints, String title, String value, IconData icon, Color color) {
    // Calculamos el ancho: 
    // - Si hay mucho espacio (> 1000): 3 columnas (aprox 30% cada una)
    // - Si hay espacio medio (700-1000): 2 columnas (aprox 45% cada una)
    // - Si es móvil (< 700): 1 columna (100%)
    double cardWidth;
    if (constraints.maxWidth > 1000) {
      cardWidth = (constraints.maxWidth - 60) / 3;
    } else if (constraints.maxWidth > 700) {
      cardWidth = (constraints.maxWidth - 45) / 2;
    } else {
      cardWidth = constraints.maxWidth - 30;
    }

    return SizedBox(
      width: cardWidth,
      child: _summaryCard(title, value, icon, color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new), 
          color: azulGris, 
          onPressed: () => context.go('/menu')
        ),
        backgroundColor: Colors.white, elevation: 1, centerTitle: true,
        title: Text("Inventario Carrasco", style: GoogleFonts.playfairDisplay(color: azulGris, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder(
        stream: _db.collection('muebles').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          int totalProductos = snapshot.data!.docs.length;
          int alertasStock = 0;
          double valorTotal = 0;

          for (var doc in snapshot.data!.docs) {
            var item = doc.data() as Map<String, dynamic>;
            int stock = (item['Stock'] ?? 0).toInt();
            double precio = (item['Precio'] ?? 0).toDouble();
            if (stock <= 5) alertasStock++;
            valorTotal += (stock * precio);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 700;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- TARJETAS DE RESUMEN RESPONSIVAS (Usando Wrap para evitar aplastamiento) ---
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        spacing: 15,
                        runSpacing: 15,
                        alignment: WrapAlignment.start,
                        children: [
                          _buildAdaptiveSummaryCard(
                            context,
                            constraints,
                            "Total Productos", 
                            "$totalProductos", 
                            Icons.inventory_2, 
                            Colors.blue
                          ),
                          _buildAdaptiveSummaryCard(
                            context,
                            constraints,
                            "Alertas Stock", 
                            "$alertasStock", 
                            Icons.warning_amber_rounded, 
                            Colors.orange
                          ),
                          _buildAdaptiveSummaryCard(
                            context,
                            constraints,
                            "Valor Inventario", 
                            NumberFormat.simpleCurrency(decimalDigits: 2).format(valorTotal), 
                            Icons.monetization_on, 
                            Colors.green
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 25),

                    // --- BARRA DE TÍTULO (Compartida o específica) ---
                    if (isMobile)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                        decoration: BoxDecoration(
                          color: azulGris,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Catálogo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ElevatedButton.icon(
                              onPressed: () => _abrirFormulario(),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text("Añadir", style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600], 
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            )
                          ],
                        ),
                      ),

                    // --- LISTADO DE PRODUCTOS (TABLA O TARJETAS) ---
                    isMobile 
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                          ),
                          child: _buildMobileList(snapshot.data!.docs),
                        )
                      : _buildDesktopTable(snapshot.data!.docs),
                  ],
                ),
              );
            }
          );
        },
      ),
    );
  }

  // --- VISTA PARA TABLET/PC (TABLA) ---
  Widget _buildDesktopTable(List<QueryDocumentSnapshot> docs) {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicWidth( // Esto obliga a que los hijos tengan el mismo ancho
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // El encabezado ahora se estirará hasta el ancho máximo de la tabla
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: azulGris,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Catálogo de Productos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(width: 40), 
                    ElevatedButton.icon(
                      onPressed: () => _abrirFormulario(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Agregar Mueble", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600], 
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      ),
                    )
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: DataTable(
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  columnSpacing: 40,
                  columns: const [
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Categoría')),
                    DataColumn(label: Text('Precio')),
                    DataColumn(label: Text('Stock')),
                    DataColumn(label: Text('Material')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: docs.map<DataRow>((doc) {
                    var item = doc.data() as Map<String, dynamic>;
                    final double precio = (item['Precio'] ?? 0).toDouble();
                    return DataRow(cells: [
                      DataCell(Text(item['Nombre'] ?? '-')),
                      DataCell(Text(item['Categoría'] ?? '-')),
                      DataCell(Text(NumberFormat.simpleCurrency(decimalDigits: 2).format(precio))),
                      DataCell(_badgeStock((item['Stock'] ?? 0).toInt())),
                      DataCell(Text(item['Material'] ?? '-')),
                      DataCell(Row(children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.orange, size: 20), onPressed: () => _abrirFormulario(docId: doc.id, data: item)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _confirmarBorrado(doc.id, item)),
                      ])),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- VISTA PARA CELULAR (TARJETAS) ---
  Widget _buildMobileList(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: Text("No hay productos registrados.")),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      separatorBuilder: (context, index) => Divider(color: Colors.grey[200], height: 1),
      itemBuilder: (context, index) {
        var doc = docs[index];
        var item = doc.data() as Map<String, dynamic>;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          title: Text(item['Nombre'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Text("${item['Categoría'] ?? '-'} • ${item['Material'] ?? '-'}", style: TextStyle(color: Colors.blueGrey[600], fontSize: 13)),
              const SizedBox(height: 5),
              Text(
                NumberFormat.simpleCurrency(decimalDigits: 2).format((item['Precio'] ?? 0).toDouble()), 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _badgeStock((item['Stock'] ?? 0).toInt()),
              const SizedBox(width: 5),
              IconButton(icon: const Icon(Icons.edit, color: Colors.orange, size: 22), onPressed: () => _abrirFormulario(docId: doc.id, data: item)),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 22), onPressed: () => _confirmarBorrado(doc.id, item)),
            ],
          ),
        );
      },
    );
  }
}