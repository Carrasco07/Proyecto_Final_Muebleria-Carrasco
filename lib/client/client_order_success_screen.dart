import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ClientOrderSuccessScreen extends StatefulWidget {
  final String pedidoId;
  final int orderNumber;
  final double total;
  final String clientName;
  final String metodoPago;
  final List<Map<String, dynamic>> cartItems;

  const ClientOrderSuccessScreen({
    super.key,
    required this.pedidoId,
    required this.orderNumber,
    required this.total,
    required this.clientName,
    required this.metodoPago,
    required this.cartItems,
  });

  @override
  State<ClientOrderSuccessScreen> createState() => _ClientOrderSuccessScreenState();
}

class _ClientOrderSuccessScreenState extends State<ClientOrderSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _fadeController;
  late AnimationController _orderNumController;

  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;
  late Animation<double> _fadeIn;
  late Animation<double> _orderNumAnim;

  bool _pdfGenerating = false;

  final Color azulGrisaceo = const Color(0xFF2C3E50);

  String get _shortOrderId {
    final paddedNumber = widget.orderNumber.toString().padLeft(5, '0');
    return '#PED-$paddedNumber';
  }

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _orderNumController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
    _checkOpacity = CurvedAnimation(parent: _checkController, curve: Curves.easeIn);
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _orderNumAnim = CurvedAnimation(parent: _orderNumController, curve: Curves.easeOut);

    // Secuencia de animaciones
    _checkController.forward().then((_) {
      _fadeController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _orderNumController.forward();
        });
      });
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _fadeController.dispose();
    _orderNumController.dispose();
    super.dispose();
  }

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final dateStr = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es').format(DateTime.now());
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final subtotal = widget.total / 1.16;
    final iva = subtotal * 0.16;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Mueblería Carrasco',
                      style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      widget.clientName,
                      style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      'RFC: CARR850312ABC',
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                    ),
                    pw.Text(
                      'Tel: (555) 123-4567',
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 15),

              // Datos del pedido
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Pedido:', style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 13)),
                  pw.Text(
                    _shortOrderId,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Fecha:', style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 13)),
                  pw.Text(
                    dateStr,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Text(
                'ARTÍCULOS',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                  color: PdfColors.grey700,
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.grey300),

              // Artículos del carrito
              ...widget.cartItems.map((item) {
                final prod = item['product'] as Map<String, dynamic>;
                final qty = item['cantidad'] as int;
                final lineTotal = prod['precio'] * qty;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${qty}x ${prod['nombre']}',
                        style: const pw.TextStyle(color: PdfColors.teal, fontSize: 13),
                      ),
                      pw.Text(
                        currencyFormat.format(lineTotal),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),

              // Subtotales
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 13)),
                  pw.Text(currencyFormat.format(subtotal), style: const pw.TextStyle(fontSize: 13)),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('IVA (16%):', style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 13)),
                  pw.Text(currencyFormat.format(iva), style: const pw.TextStyle(fontSize: 13)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                  ),
                  pw.Text(
                    currencyFormat.format(widget.total),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Método de pago:', style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 12)),
                  pw.Text(
                    widget.metodoPago == 'Tarjeta' ? 'Tarjeta de Crédito/Débito' : 'Efectivo contra entrega',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),

              pw.SizedBox(height: 40),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      '¡Gracias por su compra!',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal700,
                        fontSize: 13,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'www.muebleria-carrasco.com',
                      style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _downloadPdf() async {
    setState(() => _pdfGenerating = true);
    try {
      final pdfBytes = await _generatePdf();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'recibo_carrasco_$_shortOrderId.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ No se pudo generar el PDF. Inténtalo de nuevo.'),
            backgroundColor: Colors.redAccent.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateStr = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es').format(DateTime.now());

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0B0C) : const Color(0xFFF7F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Animación del check verde
              ScaleTransition(
                scale: _checkScale,
                child: FadeTransition(
                  opacity: _checkOpacity,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 55),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Título animado
              FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  children: [
                    Text(
                      '¡Pago Exitoso, ${widget.clientName}!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tu pedido ha sido procesado exitosamente',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Card animada del número de pedido
              FadeTransition(
                opacity: _fadeIn,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161B22) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'NÚMERO DE PEDIDO',
                        style: GoogleFonts.montserrat(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Número con animación contador
                      AnimatedBuilder(
                        animation: _orderNumController,
                        builder: (context, child) {
                          if (_orderNumController.value < 0.8) {
                            // Números aleatorios mientras anima
                            final rnd = (_orderNumController.value * 99999).toInt();
                            return Text(
                              '#${rnd.toString().padLeft(5, '0')}',
                              style: GoogleFonts.montserrat(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade400,
                              ),
                            );
                          } else {
                            // Número real del pedido al finalizar
                            return Text(
                              _shortOrderId,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                              ),
                            );
                          }
                        },
                      ),
                      if (_orderNumController.value < 1.0)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Generando número de pedido...',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Recibo / Factura visual
              FadeTransition(
                opacity: _fadeIn,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161B22) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        // Encabezado Factura
                        Text(
                          'Mueblería Carrasco',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.clientName,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        Text(
                          'RFC: CARR850312ABC',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                        Text(
                          'Tel: (555) 123-4567',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),

                        const SizedBox(height: 16),
                        Divider(color: Colors.grey.shade200),
                        const SizedBox(height: 12),

                        _buildReceiptRow('Pedido:', _shortOrderId, isDark, isBold: true),
                        const SizedBox(height: 6),
                        _buildReceiptRow('Fecha:', dateStr, isDark),

                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'ARTÍCULOS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                              fontSize: 11,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Lista de artículos
                        ...widget.cartItems.map((item) {
                          final prod = item['product'] as Map<String, dynamic>;
                          final qty = item['cantidad'] as int;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${qty}x ${prod['nombre']}',
                                    style: const TextStyle(
                                      color: Colors.teal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Text(
                                  NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                                      .format(prod['precio'] * qty),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 10),
                        Divider(color: Colors.grey.shade200),
                        const SizedBox(height: 8),

                        _buildReceiptRow(
                          'Subtotal:',
                          currencyFormat.format(widget.total / 1.16),
                          isDark,
                        ),
                        const SizedBox(height: 5),
                        _buildReceiptRow(
                          'IVA (16%):',
                          currencyFormat.format(widget.total / 1.16 * 0.16),
                          isDark,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              currencyFormat.format(widget.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildReceiptRow(
                          'Método de pago:',
                          widget.metodoPago == 'Tarjeta' ? 'Tarjeta de Crédito' : 'Efectivo',
                          isDark,
                          isBold: true,
                        ),

                        const SizedBox(height: 20),
                        Text(
                          '¡Gracias por su compra!',
                          style: GoogleFonts.lora(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'www.muebleria-carrasco.com',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Mensaje
              FadeTransition(
                opacity: _fadeIn,
                child: Text(
                  'Recibirás un correo de confirmación con los detalles de tu\npedido y el seguimiento de envío.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Botón Descargar PDF
              FadeTransition(
                opacity: _fadeIn,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azulGrisaceo,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: _pdfGenerating ? null : _downloadPdf,
                    child: _pdfGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.download_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'DESCARGAR RECIBO PDF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Botón Volver al Inicio
              FadeTransition(
                opacity: _fadeIn,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      context.go('/client_dashboard');
                    },
                    child: const Text(
                      'VOLVER AL INICIO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Cerrar sesión
              FadeTransition(
                opacity: _fadeIn,
                child: TextButton(
                  onPressed: () => context.go('/selection'),
                  child: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, bool isDark, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}
