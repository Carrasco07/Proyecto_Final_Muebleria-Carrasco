import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ClientProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic>) onAddToCart;

  const ClientProductDetailScreen({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<ClientProductDetailScreen> createState() => _ClientProductDetailScreenState();
}

class _ClientProductDetailScreenState extends State<ClientProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  int _quantity = 1;

  // Rating simulado entre 4.2 y 5.0 basado en el nombre del producto
  double get _rating {
    final seed = widget.product['nombre'].hashCode.abs() % 10;
    return 4.0 + (seed / 25.0);
  }

  final Color azulGrisaceo = const Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildStars(double rating) {
    int fullStars = rating.floor();
    bool hasHalf = (rating - fullStars) >= 0.5;
    return Row(
      children: [
        ...List.generate(5, (i) {
          if (i < fullStars) return const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 22);
          if (i == fullStars && hasHalf) return const Icon(Icons.star_half_rounded, color: Color(0xFFFFC107), size: 22);
          return const Icon(Icons.star_outline_rounded, color: Color(0xFFFFC107), size: 22);
        }),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF555555)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final prod = widget.product;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasStock = (prod['stock'] as int) > 0;
    final String formatPrice = NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(prod['precio']);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0B0C) : const Color(0xFFF7F8FA),
      body: CustomScrollView(
        slivers: [
          // App Bar con imagen hero
          SliverAppBar(
            expandedHeight: 480,
            pinned: true,
            backgroundColor: azulGrisaceo,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isDark ? const Color(0xFF1A2634) : const Color(0xFFE8ECF0),
                      isDark ? const Color(0xFF0F1923) : const Color(0xFFF0F3F5),
                    ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background pattern
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.03,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
                          itemBuilder: (_, __) => const Icon(Icons.chair_outlined, color: Colors.black),
                          itemCount: 30,
                        ),
                      ),
                    ),
                    // Icono del producto grande
                    Container(
                      width: 320,
                      height: 300,
                      decoration: BoxDecoration(
                        color: azulGrisaceo.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: prod['imagen'] != null && prod['imagen'].toString().isNotEmpty
                          ? Image.network(
                              prod['imagen'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.chair_outlined,
                                size: 100,
                                color: isDark ? Colors.amber.shade200 : azulGrisaceo,
                              ),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                            )
                          : Icon(
                              Icons.chair_outlined,
                              size: 100,
                              color: isDark ? Colors.amber.shade200 : azulGrisaceo,
                            ),
                    ),
                    // Badge de stock
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: hasStock ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          hasStock ? '${prod['stock']} disponibles' : 'Agotado',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Contenido deslizante
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0A0B0C) : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Nombre del producto
                        Text(
                          prod['nombre'],
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Estrellas
                        _buildStars(_rating),
                        const SizedBox(height: 10),

                        // Categoría
                        if ((prod['id_categoria'] ?? '').toString().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: azulGrisaceo.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              prod['id_categoria'],
                              style: TextStyle(
                                color: azulGrisaceo,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Precio
                        Text(
                          formatPrice,
                          style: GoogleFonts.montserrat(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Divider
                        Divider(color: Colors.grey.shade200, height: 1),
                        const SizedBox(height: 20),

                        // Material Badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: azulGrisaceo.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.architecture, size: 16, color: azulGrisaceo),
                                  const SizedBox(width: 6),
                                  Text(
                                    prod['material'],
                                    style: TextStyle(
                                      color: azulGrisaceo,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Descripción
                        Text(
                          'Descripción',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          prod['descripcion'],
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : const Color(0xFF4A5568),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Selector de cantidad
                        if (hasStock) ...[
                          Text(
                            'Cantidad',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildQtyControl(Icons.remove, () {
                                if (_quantity > 1) setState(() => _quantity--);
                              }),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ),
                              _buildQtyControl(Icons.add, () {
                                if (_quantity < (prod['stock'] as int)) setState(() => _quantity++);
                              }),
                              const SizedBox(width: 15),
                              Text(
                                'de ${prod['stock']} disponibles',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],

                        // Precio total calculado
                        if (hasStock)
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF161B22) : const Color(0xFFF7F8FA),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total por $_quantity pieza(s):', style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(
                                  NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                                      .format(prod['precio'] * _quantity),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 100), // space for bottom button
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // Botón flotante de agregar al carrito
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: hasStock ? azulGrisaceo : Colors.grey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: hasStock
                ? () {
                    // Agregar la cantidad seleccionada
                    for (int i = 0; i < _quantity; i++) {
                      widget.onAddToCart(widget.product);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🛋️ $_quantity x ${prod['nombre']} agregado al carrito'),
                        backgroundColor: azulGrisaceo,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    Navigator.pop(context);
                  }
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_shopping_cart, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  hasStock ? 'AGREGAR AL CARRITO' : 'PRODUCTO AGOTADO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQtyControl(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}
