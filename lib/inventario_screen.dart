import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});
  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final _db = FirebaseFirestore.instance;

  // Controladores para los 5 campos
  final _nombre = TextEditingController();
  final _material = TextEditingController();
  final _precio = TextEditingController();
  final _stock = TextEditingController();
  final _categoria = TextEditingController();

  void _abrirFormulario([String? docId, Map<String, dynamic>? data]) {
    if (data != null) {
      _nombre.text = data['Nombre'];
      _material.text = data['Material'];
      _precio.text = data['Precio'].toString();
      _stock.text = data['Stock'].toString();
      _categoria.text = data['Categoría'];
    } else {
      _nombre.clear(); _material.clear(); _precio.clear(); _stock.clear(); _categoria.clear();
    }

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nombre, decoration: const InputDecoration(labelText: "Nombre")),
            TextField(controller: _material, decoration: const InputDecoration(labelText: "Material")),
            TextField(controller: _precio, decoration: const InputDecoration(labelText: "Precio"), keyboardType: TextInputType.number),
            TextField(controller: _stock, decoration: const InputDecoration(labelText: "Stock"), keyboardType: TextInputType.number),
            TextField(controller: _categoria, decoration: const InputDecoration(labelText: "Categoría")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Map<String, dynamic> datos = {
                  "Nombre": _nombre.text, "Material": _material.text,
                  "Precio": double.parse(_precio.text), "Stock": int.parse(_stock.text),
                  "Categoría": _categoria.text,
                };
                if (docId == null) {
                  _db.collection('muebles').add(datos);
                } else {
                  _db.collection('muebles').doc(docId).update(datos);
                }
                Navigator.pop(context);
              },
              child: Text(docId == null ? "AGREGAR" : "ACTUALIZAR")
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inventario Carrasco")),
      floatingActionButton: FloatingActionButton(onPressed: () => _abrirFormulario(), child: const Icon(Icons.add)),
      body: StreamBuilder(
        stream: _db.collection('muebles').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return ListTile(
                title: Text(doc['Nombre']),
                subtitle: Text("${doc['Categoría']} - \$${doc['Precio']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _abrirFormulario(doc.id, doc.data())),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _db.collection('muebles').doc(doc.id).delete()),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}