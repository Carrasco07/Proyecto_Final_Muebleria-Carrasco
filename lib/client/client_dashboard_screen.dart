import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'client_product_detail_screen.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<QuerySnapshot>? _categorySubscription;
  StreamSubscription<QuerySnapshot>? _productSubscription;
  
  String _userName = "Cliente";
  String _userUID = "";
  
  final List<Map<String, dynamic>> _defaultCategories = [
    {'id': 'Todas', 'nombre': 'Todas'},
    {'id': 'Oficina', 'nombre': 'Oficina'},
    {'id': 'Recámara', 'nombre': 'Recámara'},
    {'id': 'Comedor', 'nombre': 'Comedor'},
    {'id': 'Sala', 'nombre': 'Sala'},
  ];

  final List<Map<String, dynamic>> _defaultProducts = [
    { 'id': '1', 'nombre': 'Escritorio Roble Nordik', 'precio': 4500.0, 'id_categoria': 'Oficina', 'imagen': 'https://raw.githubusercontent.com/Carrasco07/Imagenes_Flutter/refs/heads/main/Escritorio%20Roble%20Nordik.jpg', 'descripcion': 'Escritorio de línea nórdica con acabado natural.', 'material': 'Roble macizo', 'stock': 12 },
    { 'id': '2', 'nombre': 'Silla Ejecutiva Ergo-Black', 'precio': 3200.0, 'id_categoria': 'Oficina', 'imagen': 'https://raw.githubusercontent.com/Carrasco07/Imagenes_Flutter/refs/heads/main/Silla%20Ejecutiva%20Ergo-Black.jpg', 'descripcion': 'Silla ergonómica con respaldo alto y detalles en negro.', 'material': 'Polipiel premium', 'stock': 12 },
    { 'id': '3', 'nombre': 'Librero Modular Blanco', 'precio': 5800.0, 'id_categoria': 'Oficina', 'imagen': 'https://raw.githubusercontent.com/Carrasco07/Imagenes_Flutter/refs/heads/main/Librero%20Modular%20Blanco.jpg', 'descripcion': 'Librero funcional para organizar tu oficina con estilo.', 'material': 'Melamina blanca', 'stock': 12 },
    { 'id': '4', 'nombre': 'Archivero Industrial Metal', 'precio': 2900.0, 'id_categoria': 'Oficina', 'imagen': 'https://raw.githubusercontent.com/Carrasco07/Imagenes_Flutter/refs/heads/main/Archivero%20Industrial%20Metal.jpg', 'descripcion': 'Archivero resistente de estilo industrial.', 'material': 'Metal', 'stock': 12 },
    { 'id': '5', 'nombre': 'Cama Velvet Gris King', 'precio': 12500.0, 'id_categoria': 'Recámara', 'imagen': 'https://raw.githubusercontent.com/Carrasco07/Imagenes_Flutter/refs/heads/main/Cama%20Velvet%20Gris%20King.jpg', 'descripcion': 'Cama king size con tapizado velvet sofisticado.', 'material': 'Velvet suave', 'stock': 12 },
    { 'id': '6', 'nombre': 'Buró de Nogal Macizo', 'precio': 2100.0, 'id_categoria': 'Recámara', 'imagen': 'https://raw.githubusercontent.com/Carrasco07/Imagenes_Flutter/refs/heads/main/Bur%C3%B3%20de%20Nogal%20Macizo.jpg', 'descripcion': 'Buró elegante con detalles en nogal natural.', 'material': 'Nogal', 'stock': 12 },
    { 'id': '7', 'nombre': 'Cómoda Minimalista 6C', 'precio': 4900.0, 'id_categoria': 'Recámara', 'imagen': 'https://raw.githubusercontent.com/Carrasco07/Imagenes_Flutter/refs/heads/main/C%C3%B3moda%20Minimalista%206C.jpg', 'descripcion': 'Cómoda moderna con acabado minimalista.', 'material': 'Madera lacada', 'stock': 12 },
    { 'id': '8', 'nombre': 'Espejo Hollywood Led', 'precio': 1800.0, 'id_categoria': 'Recámara', 'imagen': 'https://raw.githubusercontent.com/Carrasco07/Imagenes_Flutter/refs/heads/main/Espejo%20Hollywood%20Led.jpg', 'descripcion': 'Espejo con iluminación LED para un estilo glam.', 'material': 'Vidrio y metal', 'stock': 12 },
    { 'id': '9', 'nombre': 'Mesa Comedor Escandinava', 'precio': 7200.0, 'id_categoria': 'Comedor', 'imagen': 'https://raw.githubusercontent.com/Carrasco07/Imagenes_Flutter/refs/heads/main/Mesa%20Comedor%20Escandinava.jpg', 'descripcion': 'Mesa de comedor con aspecto ligero y natural.', 'material': 'Madera clara', 'stock': 12 },
    { 'id': '10', 'nombre': 'Silla Comedor Terciopelo', 'precio': 1400.0, 'id_categoria': 'Comedor', 'imagen': 'https://raw.githubusercontent.com/Carrasco07/Imagenes_Flutter/refs/heads/main/Silla%20Comedor%20Terciopelo.jpg', 'descripcion': 'Silla tapizada para un comedor elegante.', 'material': 'Terciopelo', 'stock': 12 },
    { 'id': '11', 'nombre': 'Trinchador Buffet Madera', 'precio': 8900.0, 'id_categoria': 'Comedor', 'imagen': 'https://raw.githubusercontent.com/Carrasco07/Imagenes_Flutter/refs/heads/main/Trinchador%20Buffet%20Madera.jpg', 'descripcion': 'Buffet de comedor con gran capacidad y diseño cálido.', 'material': 'Madera natural', 'stock': 12 },
    { 'id': '12', 'nombre': 'Set 4 Sillas Negras Matte', 'precio': 5600.0, 'id_categoria': 'Comedor', 'imagen': 'https://raw.githubusercontent.com/Carrasco07/Imagenes_Flutter/refs/heads/main/Set%204%20Sillas%20Negras%20Matte.jpg', 'descripcion': 'Juego de 4 sillas modernas con acabado matte.', 'material': 'Metal y tela', 'stock': 12 },
    { 'id': '13', 'nombre': 'Sofá Modular Cloud', 'precio': 18500.0, 'id_categoria': 'Sala', 'imagen': 'https://raw.githubusercontent.com/Carrasco07/Imagenes_Flutter/refs/heads/main/Sof%C3%A1%20Modular%20Cloud.jpg', 'descripcion': 'Sofá modular con cojines suaves y amplio confort.', 'material': 'Tapizado premium', 'stock': 12 },
    { 'id': '14', 'nombre': 'Mesa Centro Mármol', 'precio': 3400.0, 'id_categoria': 'Sala', 'imagen': 'https://raw.githubusercontent.com/Carrasco07/Imagenes_Flutter/refs/heads/main/Mesa%20Centro%20M%C3%A1rmol.jpg', 'descripcion': 'Mesa de centro con cubierta de mármol elegante.', 'material': 'Mármol y metal', 'stock': 12 },
    { 'id': '15', 'nombre': 'Sillón Relax Cuero', 'precio': 6700.0, 'id_categoria': 'Sala', 'imagen': 'https://raw.githubusercontent.com/Carrasco07/Imagenes_Flutter/refs/heads/main/Sill%C3%B3n%20Relax%20Cuero.jpg', 'descripcion': 'Sillón reclinable con acabado en cuero premium.', 'material': 'Cuero sintético', 'stock': 12 },
    { 'id': '16', 'nombre': 'Mueble TV Flotante', 'precio': 4200.0, 'id_categoria': 'Sala', 'imagen': 'https://raw.githubusercontent.com/Carrasco07/Imagenes_Flutter/refs/heads/main/Mueble%20TV%20Flotante.webp', 'descripcion': 'Mueble TV con diseño flotante y almacenamiento oculto.', 'material': 'Madera laminada', 'stock': 12 },
  ];

  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _displayedProducts = [];
  List<Map<String, dynamic>> _categories = [];
  String _selectedCategoryId = "Todas";
  bool _isLoadingCatalog = true;
  
  // Carrito de Compras: Lista de {'id': String, 'product': Map, 'cantidad': int}
  final List<Map<String, dynamic>> _cart = [];
  
  final Color azulGrisaceo = const Color(0xFF2C3E50);
  final Color doradoPremium = const Color(0xFFD4AF37);
  final Color grisFondo = const Color(0xFFEDEFF2);

  @override
  void initState() {
    super.initState();
    _loadClientData();
  }

  Future<void> _loadClientData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      _userUID = user.uid;
      try {
        final doc = await _db.collection('cliente').doc(user.uid).get();
        String raw = 'Cliente';
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          raw = data['nombre'] ?? 'Cliente';
          if (raw.isNotEmpty) {
            raw = raw.split(' ')[0]; // Usar solo el primer nombre
            raw = raw[0].toUpperCase() + raw.substring(1).toLowerCase();
          }
        }
        setState(() => _userName = raw);
      } catch (e) {
        // Fallback en caso de error
        setState(() => _userName = 'Cliente');
      }
    }
    _setupCatalogListener();
  }

  Future<void> _setupCatalogListener() async {
    setState(() => _isLoadingCatalog = true);
    _categorySubscription?.cancel();
    _productSubscription?.cancel();

    QuerySnapshot? latestCategorySnapshot;
    QuerySnapshot? latestProductSnapshot;

    void updateCatalogIfReady() {
      if (latestCategorySnapshot != null && latestProductSnapshot != null) {
        _updateCatalogFromSnapshots(latestCategorySnapshot!, latestProductSnapshot!);
      }
    }

    _categorySubscription = _db.collection('categoria').snapshots().listen(
      (catSnapshot) {
        latestCategorySnapshot = catSnapshot;
        updateCatalogIfReady();
      },
      onError: (_) => _fallbackDefaultCatalog(),
    );

    _productSubscription = _db.collection('productos').snapshots().listen(
      (prodSnapshot) {
        latestProductSnapshot = prodSnapshot;
        updateCatalogIfReady();
      },
      onError: (_) => _fallbackDefaultCatalog(),
    );

    // Escuchar cambios en inventario para actualizar el catálogo en tiempo real
    _db.collection('inventario').snapshots().listen(
      (invSnapshot) {
        // Cuando el inventario cambia, actualiza el catálogo
        if (latestCategorySnapshot != null && latestProductSnapshot != null) {
          _updateCatalogFromSnapshots(latestCategorySnapshot!, latestProductSnapshot!);
        }
      },
      onError: (_) {},
    );

    try {
      final catSnapshot = await _db.collection('categoria').get();
      final prodSnapshot = await _db.collection('productos').get();
      _updateCatalogFromSnapshots(catSnapshot, prodSnapshot);
    } catch (_) {
      _fallbackDefaultCatalog();
    }
  }

  void _updateCatalogFromSnapshots(QuerySnapshot catSnapshot, QuerySnapshot prodSnapshot) async {
    final List<Map<String, dynamic>> categoriesFromDb = catSnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final rawName = data['nombre']?.toString().trim();
      final displayName = (rawName != null && rawName.isNotEmpty) ? rawName : doc.id;
      return {'docId': doc.id, 'nombre': displayName};
    }).toList();

    final Map<String, String> categoryNameByDocId = {
      for (var category in categoriesFromDb) category['docId'] as String: category['nombre'] as String,
    };

    // Obtener todos los inventarios para mapear stock por producto ID
    final inventarioSnapshot = await _db.collection('inventario').get();
    final Map<String, int> stockByProductId = {};
    
    debugPrint('🔍 DEBUG INVENTARIO - Total docs: ${inventarioSnapshot.docs.length}');
    
    for (var doc in inventarioSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      debugPrint('📦 Inventario doc: ${doc.id}');
      debugPrint('   Data: $data');
      
      // Buscar id_producto en diferentes campos posibles
      String? productoId;
      for (var key in ['id_producto', 'ID Producto', 'Producto ID', 'producto_id']) {
        if (data.containsKey(key)) {
          productoId = data[key]?.toString();
          if (productoId != null && productoId.isNotEmpty) {
            debugPrint('   ✓ Encontrado id_producto con clave "$key": $productoId');
            break;
          }
        }
      }
      
      if (productoId == null || productoId.isEmpty) {
        debugPrint('   ✗ No se encontró id_producto');
        continue;
      }

      // Buscar stock en diferentes campos posibles
      int? parsedStock;
      for (var key in ['Stock Actual', 'stock_actual', 'stock', 'Stock', 'StockActual']) {
        if (data.containsKey(key)) {
          final stockValue = data[key];
          debugPrint('   → Intentando campo "$key": $stockValue (tipo: ${stockValue.runtimeType})');
          if (stockValue != null) {
            parsedStock = stockValue is int 
                ? stockValue 
                : int.tryParse(stockValue.toString());
            if (parsedStock != null && parsedStock > 0) {
              debugPrint('   ✓ Stock encontrado con clave "$key": $parsedStock');
              break;
            }
          }
        }
      }

      if (parsedStock != null && parsedStock > 0) {
        stockByProductId[productoId] = parsedStock;
        debugPrint('   ✅ Mapeado: $productoId → $parsedStock unidades');
      } else {
        debugPrint('   ⚠️ Stock inválido o 0 para producto $productoId');
      }
    }

    debugPrint('📊 RESUMEN STOCK: $stockByProductId\n');

    final loadedProducts = prodSnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final rawCategory = data['id_categoria']?.toString().trim() ?? '';
      String categoryName = rawCategory;
      if (categoryNameByDocId.containsKey(rawCategory)) {
        categoryName = categoryNameByDocId[rawCategory]!;
      } else {
        for (var cat in categoriesFromDb) {
          if (cat['nombre'] == rawCategory) {
            categoryName = cat['nombre'] as String;
            break;
          }
        }
      }
      if (categoryName.isEmpty) categoryName = 'General';

      final rawPrice = data['precio'];
      
      // Obtener stock desde inventario, usar 0 si no existe
      final int realStock = stockByProductId[doc.id] ?? 0;
      debugPrint('📌 Producto ${doc.id}: stock asignado = $realStock');

      return {
        'id': doc.id,
        'nombre': data['nombre'] ?? 'Producto',
        'precio': rawPrice is num ? rawPrice.toDouble() : double.tryParse(rawPrice?.toString() ?? '') ?? 0.0,
        'id_categoria': categoryName,
        'imagen': data['imagen'] ?? '',
        'descripcion': data['descripcion'] ?? '',
        'material': data['material'] ?? '',
        'stock': realStock,
      };
    }).toList();

    final bool showEmptyCatalog = catSnapshot.docs.isEmpty && prodSnapshot.docs.isEmpty;

    final List<Map<String, dynamic>> categories = [];
    if (!showEmptyCatalog) {
      categories.add({'id': 'Todas', 'nombre': 'Todas'});
      for (var cat in categoriesFromDb) {
        final name = cat['nombre'] as String;
        if (!categories.any((c) => c['id'] == name)) {
          categories.add({'id': name, 'nombre': name});
        }
      }
    }

    final List<Map<String, dynamic>> currentProducts = showEmptyCatalog ? [] : loadedProducts;

    if (!mounted) return;
    setState(() {
      _categories = categories;
      _allProducts = currentProducts;
      _displayedProducts = _selectedCategoryId == 'Todas'
          ? currentProducts
          : currentProducts.where((p) => p['id_categoria'] == _selectedCategoryId).toList();
      _isLoadingCatalog = false;
    });
  }

  void _fallbackDefaultCatalog() {
    if (!mounted) return;
    setState(() {
      _categories = [];
      _allProducts = [];
      _displayedProducts = [];
      _selectedCategoryId = 'Todas';
      _isLoadingCatalog = false;
    });
  }

  void _filtrarCategoria(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      if (categoryId == 'Todas') {
        _displayedProducts = _allProducts;
      } else {
        _displayedProducts = _allProducts.where((p) => p['id_categoria'] == categoryId).toList();
      }
    });
  }

  void _agregarAlCarrito(Map<String, dynamic> product) {
    final existingIndex = _cart.indexWhere((item) => item['id'] == product['id']);
    int stockDisponible = product['stock'] ?? 0;
    int cantidadEnCarrito = existingIndex != -1 ? _cart[existingIndex]['cantidad'] : 0;

    if (cantidadEnCarrito >= stockDisponible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No puedes agregar más piezas de este modelo. Stock máximo alcanzado ($stockDisponible)."),
          backgroundColor: Colors.amber.shade700,
        ),
      );
      return;
    }

    setState(() {
      if (existingIndex != -1) {
        _cart[existingIndex]['cantidad']++;
      } else {
        _cart.add({
          'id': product['id'],
          'product': product,
          'cantidad': 1,
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("¡Agregado! ${product['nombre']} se sumó al carrito."),
        backgroundColor: azulGrisaceo,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _modificarCantidad(int index, int delta) {
    int currentQty = _cart[index]['cantidad'];
    int stockDisponible = _cart[index]['product']['stock'] ?? 0;

    if (currentQty + delta > stockDisponible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No contamos con más unidades en este momento ($stockDisponible)."),
          backgroundColor: Colors.amber.shade700,
        ),
      );
      return;
    }

    setState(() {
      if (currentQty + delta <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index]['cantidad'] += delta;
      }
    });
  }

  double _calcularTotal() {
    double sub = 0;
    for (var item in _cart) {
      sub += (item['product']['precio'] ?? 0.0) * item['cantidad'];
    }
    return sub;
  }

  void _abrirCarrito() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final total = _calcularTotal();
          final bool isDark = Theme.of(context).brightness == Brightness.dark;
          
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Cabecera del Carrito
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: azulGrisaceo,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            "Tu Carrito de Compra",
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Cuerpo
                Expanded(
                  child: _cart.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
                              const SizedBox(height: 15),
                              Text(
                                "Tu carrito está completamente vacío.",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _cart.length,
                          separatorBuilder: (c, i) => const Divider(height: 25),
                          itemBuilder: (context, i) {
                            final item = _cart[i];
                            final prod = item['product'];
                            final qty = item['cantidad'];
                            final subtotal = (prod['precio'] ?? 0.0) * qty;
                            
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: azulGrisaceo.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.chair_outlined, color: azulGrisaceo, size: 30),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prod['nombre'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        "${prod['material']} | ${NumberFormat.simpleCurrency().format(prod['precio'] ?? 0)}",
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              _buildQtyBtn(Icons.remove, () {
                                                _modificarCantidad(i, -1);
                                                setModalState(() {});
                                                setState(() {});
                                              }),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                                child: Text(
                                                  "$qty",
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                ),
                                              ),
                                              _buildQtyBtn(Icons.add, () {
                                                _modificarCantidad(i, 1);
                                                setModalState(() {});
                                                setState(() {});
                                              }),
                                            ],
                                          ),
                                          Text(
                                            NumberFormat.simpleCurrency().format(subtotal),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                // Footer con totales e iniciar Checkout
                if (_cart.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF21262D) : Colors.grey.shade50,
                      border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Estimado:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                              NumberFormat.simpleCurrency().format(total),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.teal),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: azulGrisaceo,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _abrirCheckout();
                            },
                            child: const Text(
                              "CONTINUAR A LA CAJA",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14),
      ),
    );
  }

  void _abrirCheckout() {
    String metodoPago = "Tarjeta";
    final cardHolderController = TextEditingController();
    final cardNumberController = TextEditingController();
    final expirationController = TextEditingController();
    final cvvController = TextEditingController();
    bool isProcessingOrder = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setCheckState) {
          final total = _calcularTotal();
          final subtotalCalculado = total / 1.16;
          final ivaCalculado = subtotalCalculado * 0.16;
          final bool isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Cabecera Checkout
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: azulGrisaceo,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.credit_card_rounded, color: Colors.white, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            "Checkout & Caja",
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Formulario
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "1. Resumen de Compra",
                          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14, color: azulGrisaceo),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF21262D) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey.shade300, width: 0.5),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Subtotal (antes de IVA):", style: TextStyle(fontSize: 13)),
                                  Text(NumberFormat.simpleCurrency().format(subtotalCalculado), style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("IVA (16%):", style: TextStyle(fontSize: 13)),
                                  Text(NumberFormat.simpleCurrency().format(ivaCalculado), style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Total a Pagar:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text(
                                    NumberFormat.simpleCurrency().format(total),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          "2. Método de Pago",
                          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14, color: azulGrisaceo),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [Icon(Icons.credit_card, size: 16), SizedBox(width: 5), Text("Tarjeta")],
                                ),
                                selected: metodoPago == "Tarjeta",
                                onSelected: (val) {
                                  if (val) setCheckState(() => metodoPago = "Tarjeta");
                                },
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: ChoiceChip(
                                label: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [Icon(Icons.money_rounded, size: 16), SizedBox(width: 5), Text("Efectivo")],
                                ),
                                selected: metodoPago == "Efectivo",
                                onSelected: (val) {
                                  if (val) setCheckState(() => metodoPago = "Efectivo");
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        if (metodoPago == "Tarjeta") ...[
                          Text(
                            "3. Datos de la Tarjeta",
                            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14, color: azulGrisaceo),
                          ),
                          const SizedBox(height: 15),
                          _buildCheckoutField("Nombre del Titular", Icons.person_outline, cardHolderController, isDark),
                          const SizedBox(height: 15),
                          _buildCheckoutField("Número de Tarjeta", Icons.credit_card_outlined, cardNumberController, isDark, keyboard: TextInputType.number),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCheckoutField("Vencimiento (MM/AA)", Icons.calendar_today_outlined, expirationController, isDark, keyboard: TextInputType.datetime),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _buildCheckoutField("CVV", Icons.lock_outline, cvvController, isDark, isPass: true, keyboard: TextInputType.number),
                              ),
                            ],
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.amber.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.amber),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    "Elegiste pago en efectivo. Podrás realizar tu pago de forma segura al recibir tu mueble en tu domicilio.",
                                    style: TextStyle(color: Colors.amber.shade900, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: isProcessingOrder
                                ? null
                                : () async {
                                    if (metodoPago == "Tarjeta") {
                                      if (cardHolderController.text.trim().isEmpty ||
                                          cardNumberController.text.trim().isEmpty ||
                                          expirationController.text.trim().isEmpty ||
                                          cvvController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("⚠️ Completa todos los campos de tu tarjeta de crédito/débito."),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                        return;
                                      }
                                    }
                                    setCheckState(() => isProcessingOrder = true);
                                    
                                    final result = await _procesarTransaccionCompra(metodoPago);
                                    
                                    if (mounted) {
                                      Navigator.pop(context); // Cierra checkout
                                      if (result != null) {
                                        _mostrarExitoCompra(total, result['pedidoId'] as String, result['orderNumber'] as int, metodoPago);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("⚠️ Hubo un error al procesar tu compra. Intenta de nuevo."),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: isProcessingOrder
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.payment, color: Colors.white),
                                      const SizedBox(width: 10),
                                      Text(
                                        "FINALIZAR COMPRA POR ${NumberFormat.simpleCurrency().format(total)}",
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCheckoutField(String label, IconData icon, TextEditingController controller, bool isDark, {bool isPass = false, TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      keyboardType: keyboard,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: azulGrisaceo),
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF95A5A6), fontSize: 13),
        filled: true,
        fillColor: isDark ? const Color(0xFF21262D) : const Color(0xFFF2F4F4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Future<Map<String, dynamic>?> _procesarTransaccionCompra(String metodoPago) async {
    try {
      final total = _calcularTotal();
      final dateStr = DateTime.now().toString().substring(0, 10);

      debugPrint('\n🛒 INICIANDO COMPRA - Total: \$$total');

      // 1. Agregar a la colección 'pedido'
      final newPedidoDoc = await _db.collection('pedido').add({
        'id_cliente': _userUID,
        'id_empleado': '', // Vacío por ser autoservicio digital
        'fecha_pedido': dateStr,
        'estado': 'Pendiente',
        'total': total,
      });

      debugPrint('✅ Pedido creado: ${newPedidoDoc.id}');

      // 2. Agregar a 'detalle_pedido' y actualizar 'inventario'
      for (var item in _cart) {
        final prod = item['product'];
        final qty = item['cantidad'];
        final subtotal = (prod['precio'] ?? 0.0) * qty;

        debugPrint('\n📦 Procesando producto: ${prod['id']} (${prod['nombre']})');
        debugPrint('   Cantidad: $qty');

        await _db.collection('detalle_pedido').add({
          'id_pedido': newPedidoDoc.id,
          'id_producto': prod['id'],
          'cantidad': qty,
          'precio_unitario': prod['precio'],
          'subtotal': subtotal,
        });

        debugPrint('   ✓ Detalle añadido a detalle_pedido');

        // Actualizar el stock en la tabla de inventario
        try {
          debugPrint('   🔍 Buscando inventario para producto: ${prod['id']}');

          // Buscar inventario por id_producto usando campos esperados,
          // y si no encuentra ningún documento usar un fallback más amplio.
          final initialQuery = await _db
              .collection('inventario')
              .where('id_producto', isEqualTo: prod['id'])
              .get();
          List<QueryDocumentSnapshot> inventarioDocs = initialQuery.docs;

          if (inventarioDocs.isEmpty) {
            debugPrint('   ⚠️ No se encontró con id_producto, buscando por otras variantes...');
            final allInventario = await _db.collection('inventario').get();
            inventarioDocs = allInventario.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              for (var key in ['id_producto', 'ID Producto', 'Producto ID', 'producto_id']) {
                if (data.containsKey(key) && data[key]?.toString() == prod['id'].toString()) {
                  return true;
                }
              }
              return false;
            }).toList();
            if (inventarioDocs.isNotEmpty) {
              debugPrint('   ✓ Fallback encontró inventario con campo alternativo');
            }
          }

          if (inventarioDocs.isNotEmpty) {
            final inventarioDoc = inventarioDocs.first;
            debugPrint('   📄 Documento encontrado: ${inventarioDoc.id}');
            final docData = inventarioDoc.data() as Map<String, dynamic>;
            debugPrint('   Data: $docData');

            // Buscar el campo de stock correcto
            int stockActualAnterior = 0;
            String stockField = '';
            for (var field in ['stock_actual', 'Stock Actual', 'stock', 'Stock', 'StockActual']) {
              if (docData.containsKey(field)) {
                stockActualAnterior = docData[field] is int
                    ? docData[field]
                    : int.tryParse(docData[field].toString()) ?? 0;
                stockField = field;
                break;
              }
            }

            debugPrint('   Stock actual encontrado en campo "$stockField": $stockActualAnterior');
            final nuevoStock = stockActualAnterior - qty;
            debugPrint('   ➖ Nuevo stock: $stockActualAnterior - $qty = $nuevoStock');

            await _db.collection('inventario').doc(inventarioDoc.id).update({
              stockField.isNotEmpty ? stockField : 'stock_actual': nuevoStock,
              'ultima_actualizacion': dateStr,
            });

            debugPrint('   ✅ Stock actualizado en Firestore');

            final int stockMinimo = 5;
            if (nuevoStock <= stockMinimo) {
              await _db.collection('notificaciones').add({
                'titulo': '⚠️ ¡Stock Crítico Detectado!',
                'mensaje': 'El stock de "${prod['nombre']}" bajó a $nuevoStock unidades por venta directa online.',
                'fecha': FieldValue.serverTimestamp(),
                'leido': false,
                'icono': 'warning',
              });
            }
          } else {
            debugPrint('   ⚠️ NO SE ENCONTRÓ INVENTARIO para producto ${prod['id']}');
          }
        } catch (e) {
          debugPrint('   ❌ Error actualizando inventario: $e');
        }
      }

      // 3. Crear 'factura'
      final subtotalFactura = total / 1.16;
      final ivaFactura = subtotalFactura * 0.16;

      final newFacturaDoc = await _db.collection('factura').add({
        'id_pedido': newPedidoDoc.id,
        'fecha_emision': dateStr,
        'subtotal': subtotalFactura,
        'iva': ivaFactura,
        'total': total,
        'rfc_cliente': 'XAXX010101000',
      });

      debugPrint('✅ Factura creada: ${newFacturaDoc.id}');

      // 4. Registrar el 'pago'
      final refTransaccion = 'TRANS-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      await _db.collection('pago').add({
        'id_factura': newFacturaDoc.id,
        'fecha_pago': dateStr,
        'metodo': metodoPago,
        'monto': total,
        'referencia': refTransaccion,
      });

      debugPrint('✅ Pago registrado: $refTransaccion');

      // 5. Notificación ERP
      await _db.collection('notificaciones').add({
        'titulo': '💰 ¡Nueva Venta Registrada!',
        'mensaje': 'El cliente "$_userName" realizó una compra online de Muebles por un total de ${NumberFormat.simpleCurrency().format(total)} MXN.',
        'fecha': FieldValue.serverTimestamp(),
        'leido': false,
        'icono': 'monetization_on',
      });

      // Auditoría
      await _db.collection('auditoria').add({
        'accion': '[$_userName] Compra Directa Online por \$${total.toStringAsFixed(2)} MXN',
        'fecha': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
        'usuario': _userName,
      });

      debugPrint('✅ Notificaciones y auditoría registradas');
      debugPrint('🎉 COMPRA COMPLETADA\n');

      final orderCountSnapshot = await _db.collection('pedido').get();
      final int orderNumber = orderCountSnapshot.size;
      return {'pedidoId': newPedidoDoc.id, 'orderNumber': orderNumber};
    } catch (e) {
      debugPrint('❌ Error procesando compra: $e');
      return null;
    }
  }

  void _mostrarExitoCompra(double total, String pedidoId, int orderNumber, String metodoPago) {
    final cartCopy = _cart.map((item) {
      return {
        'id': item['id'],
        'cantidad': item['cantidad'],
        'product': Map<String, dynamic>.from(item['product']),
      };
    }).toList();

    setState(() => _cart.clear());

    context.push('/client_order_success', extra: {
      'pedidoId': pedidoId,
      'orderNumber': orderNumber,
      'total': total,
      'clientName': _userName,
      'metodoPago': metodoPago,
      'cartItems': cartCopy,
    });
  }

  @override
  void dispose() {
    _categorySubscription?.cancel();
    _productSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0B0C) : grisFondo,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Catálogo Carrasco",
              style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
            ),
            Text(
              "16 productos premium listos para ti",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            )
          ],
        ),
        backgroundColor: azulGrisaceo,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: _abrirCarrito,
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      "${_cart.fold<int>(0, (prev, element) => prev + (element['cantidad'] as int))}",
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Cerrar Sesión",
            onPressed: () async {
              await _auth.signOut();
              if (mounted) context.go('/selection');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_categories.isNotEmpty) _buildCategoriesBar(isDark),
          Expanded(
            child: _isLoadingCatalog
                ? const Center(child: CircularProgressIndicator())
                : _displayedProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chair_outlined, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            const Text("No hay productos disponibles en esta categoría.", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 260,
                          mainAxisExtent: 390,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                        ),
                        itemCount: _displayedProducts.length,
                        itemBuilder: (context, i) {
                          final prod = _displayedProducts[i];
                          return _buildProductCard(prod, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesBar(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      color: isDark ? const Color(0xFF12202E) : const Color(0xFFF7F9FB),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _categories.map((cat) {
            final isSelected = _selectedCategoryId == cat['id'];
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => _filtrarCategoria(cat['id']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? azulGrisaceo
                        : (isDark ? const Color(0xFF1F2F3F) : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? azulGrisaceo : Colors.grey.shade300,
                      width: isSelected ? 0 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: azulGrisaceo.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6))]
                        : [],
                  ),
                  child: Text(
                    cat['nombre'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : azulGrisaceo),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> prod, bool isDark) {
    final hasStock = (prod['stock'] ?? 0) > 0;
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClientProductDetailScreen(
            product: prod,
            onAddToCart: _agregarAlCarrito,
          ),
        ),
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 6,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  color: isDark ? const Color(0xFF1E2C3D) : const Color(0xFFF4F7F9),
                  child: prod['imagen'] != null && prod['imagen'].toString().isNotEmpty
                      ? Image.network(
                          prod['imagen'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.chair_outlined,
                            size: 45,
                            color: isDark ? Colors.amber.shade200 : azulGrisaceo,
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)));
                          },
                        )
                      : Icon(
                          Icons.chair_outlined,
                          size: 45,
                          color: isDark ? Colors.amber.shade200 : azulGrisaceo,
                        ),
                ),
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    prod['id_categoria'] ?? '',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prod['nombre'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    prod['descripcion'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12.2, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            NumberFormat.simpleCurrency(decimalDigits: 0).format(prod['precio'] ?? 0.0),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            prod['material'] ?? '',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: hasStock ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          hasStock ? '${prod['stock']} disp' : 'Agotado',
                          style: TextStyle(
                            color: hasStock ? Colors.green.shade700 : Colors.red.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasStock ? azulGrisaceo : Colors.grey.shade500,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: hasStock ? () => _agregarAlCarrito(prod) : null,
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: const Text('Agregar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}