import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class MichiAiService {
  static final MichiAiService _instance = MichiAiService._internal();
  factory MichiAiService() => _instance;
  MichiAiService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Puedes pegar tu API Key de Gemini aquí para pruebas directas en vivo.
  // Si está vacía, el sistema entrará automáticamente en modo "Offline Simulación".
  String geminiApiKey = ""; 

  /// Genera una respuesta inteligente de Michi Carpintero, ya sea usando Gemini o la Simulación Inteligente.
  Future<String> obtenerRespuesta(String mensajeUsuario) async {
    // 1. Procesar si el mensaje es una acción ejecutable en la base de datos
    String? respuestaAccion = await _procesarAccionesFirestore(mensajeUsuario);
    if (respuestaAccion != null) {
      return respuestaAccion;
    }

    // 2. Obtener contexto en tiempo real del ERP desde Firestore para enriquecer la IA
    String contextoERP = await _obtenerContextoERP();

    // 3. Si hay API Key configurada, intentar usar Gemini AI en vivo
    if (geminiApiKey.isNotEmpty) {
      try {
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: geminiApiKey,
          generationConfig: GenerationConfig(
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
          ),
          systemInstruction: Content.system('''
Eres "Michi Carpintero" 🐈‍⬛🪵🪚, el asistente oficial de "Mueblería Carrasco" y copiloto de Omar.

Personalidad:
- Eres muy amable, entusiasta y respetuoso, pero directo y al grano.
- Saluda con cariño ("¡Miau, Omar!", "¡Ronroneo de éxito, jefe!").
- Usa maullidos/ronroneos y emojis (🪵, 🪚, 🪑, 🐾, 🧰, 🛠️) de forma concisa.
- Da respuestas cortas, directas y útiles. No te extiendas con rodeos innecesarios.

Aquí tienes el contexto actual en vivo de la base de datos de Mueblería Carrasco:
$contextoERP
'''),
        );

        final content = [Content.text(mensajeUsuario)];
        final response = await model.generateContent(content);
        if (response.text != null && response.text!.isNotEmpty) {
          return response.text!;
        }
      } catch (e) {
        // Fallback
      }
    }

    // 4. Modo Simulación Inteligente (Offline / Fallback)
    return _obtenerSimulacionMichi(mensajeUsuario, contextoERP);
  }

  /// Intenta procesar comandos de escritura y ejecutarlos directamente en Firestore.
  Future<String?> _procesarAccionesFirestore(String mensaje) async {
    final msg = mensaje.toLowerCase().trim();

    // Expresión Regular para crear clientes: "crea cliente Carlos con correo carlos@gmail.com"
    final regCliente = RegExp(
      r'(crea|crear|registra|registrar|agrega|agregar)\s+(?:al\s+)?cliente\s+([^@]+?)\s+con\s+correo\s+([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})',
      caseSensitive: false
    );

    // Expresión Regular para crear categorías: "crea la categoría Mesas de Centro"
    final regCategoria = RegExp(
      r'(crea|crear|agrega|agregar|registra|registrar)\s+(?:la\s+)?categor[ií]a\s+(?:llamada\s+)?(.+)',
      caseSensitive: false
    );

    // Expresión Regular para crear productos: "crea producto Silla de Pino con precio 1200 y stock 15"
    final regProducto = RegExp(
      r'(crea|crear|registra|registrar|agrega|agregar)\s+(?:el\s+)?producto\s+([^0-9]+?)\s+con\s+precio\s+([0-9.]+)\s+y\s+stock\s+(\d+)',
      caseSensitive: false
    );

    try {
      // 1. Caso: Crear Cliente
      if (regCliente.hasMatch(msg)) {
        final match = regCliente.firstMatch(mensaje);
        if (match != null) {
          String nombre = match.group(2)!.trim();
          String correo = match.group(3)!.trim();
          
          if (nombre.toLowerCase().startsWith('llamado ')) {
            nombre = nombre.substring(8).trim();
          }
          if (nombre.isNotEmpty) {
            nombre = nombre[0].toUpperCase() + nombre.substring(1);
          }

          String nuevoId = DateTime.now().millisecondsSinceEpoch.toString().substring(6);

          await _db.collection('cliente').add({
            'id': nuevoId,
            'nombre': nombre,
            'correo': correo,
            'telefono': '555-0199',
            'direccion': 'Registrado por Michi AI 🐈‍⬛',
          });

          await _db.collection('notificaciones').add({
            'titulo': 'Cliente por Michi AI',
            'mensaje': '$nombre ($correo) fue registrado por el asistente.',
            'icono': 'person_add',
            'fecha': DateTime.now().toString().substring(0, 19),
            'leido': false,
            'usuario': 'Michi AI',
          });

          return '¡Miau, jefe Omar! 🐾 *saca su martillo de oro* He registrado al cliente **$nombre** ($correo) con éxito en Firestore. ¡Ronroneo de éxito! 📋✨';
        }
      }

      // 2. Caso: Crear Producto
      if (regProducto.hasMatch(msg)) {
        final match = regProducto.firstMatch(mensaje);
        if (match != null) {
          String nombre = match.group(2)!.trim();
          double precio = double.tryParse(match.group(3)!) ?? 0.0;
          int stock = int.tryParse(match.group(4)!) ?? 0;

          if (nombre.toLowerCase().startsWith('llamado ')) {
            nombre = nombre.substring(8).trim();
          }
          if (nombre.isNotEmpty) {
            nombre = nombre[0].toUpperCase() + nombre.substring(1);
          }

          // Consultar dinámicamente el primer ID de categoría y proveedor
          String idCategoria = "";
          try {
            var catSnap = await _db.collection('categoria').get();
            if (catSnap.docs.isNotEmpty) {
              idCategoria = catSnap.docs.first.id;
            }
          } catch (e) {}

          String idProveedor = "";
          try {
            var provSnap = await _db.collection('proveedor').get();
            if (provSnap.docs.isNotEmpty) {
              idProveedor = provSnap.docs.first.id;
            }
          } catch (e) {}

          // 1. Crear el producto real en la colección 'productos'
          var nuevoProdDoc = await _db.collection('productos').add({
            'nombre': nombre,
            'precio': precio,
            'descripcion': 'Producto diseñado y pulido por Michi AI 🐾',
            'material': 'Madera de Cedro',
            'id_categoria': idCategoria,
            'id_proveedor': idProveedor,
          });

          // Consultar dinámicamente el primer ID de almacén
          String idAlmacen = "";
          try {
            var almSnap = await _db.collection('almacen').get();
            if (almSnap.docs.isNotEmpty) {
              idAlmacen = almSnap.docs.first.id;
            }
          } catch (e) {}

          // 2. Vincular el producto en la colección 'inventario' para registrar el stock
          await _db.collection('inventario').add({
            'id_producto': nuevoProdDoc.id,
            'id_almacen': idAlmacen,
            'stock_actual': stock,
            'stock_minimo': 5,
            'ultima_actualizacion': DateTime.now().toString().substring(0, 10),
          });

          await _db.collection('notificaciones').add({
            'titulo': 'Producto por Michi AI',
            'mensaje': 'Fabricado y registrado: $nombre (Stock: $stock, Precio: \$$precio).',
            'icono': 'shopping_bag',
            'fecha': DateTime.now().toString().substring(0, 19),
            'leido': false,
            'usuario': 'Michi AI',
          });

          return '¡Miau, jefe Omar! 🐾 *toma su cepillo de carpintería y pule una pieza* ¡Listo! He fabricado y registrado el producto **$nombre** con un precio de **\$$precio MXN** y **$stock unidades** en inventario. ¡Calidad premium asegurada! 🪑🪚';
        }
      }

      // 3. Caso: Crear Categoría
      if (regCategoria.hasMatch(msg)) {
        final match = regCategoria.firstMatch(mensaje);
        if (match != null) {
          String nombre = match.group(2)!.trim();
          
          if (nombre.isNotEmpty) {
            nombre = nombre[0].toUpperCase() + nombre.substring(1);
          }

          String nuevoId = DateTime.now().millisecondsSinceEpoch.toString().substring(6);

          await _db.collection('categoria').add({
            'id': nuevoId,
            'nombre': nombre,
            'descripcion': 'Categoría creada por Michi Carpintero 🐾',
          });

          await _db.collection('notificaciones').add({
            'titulo': 'Categoría por Michi AI',
            'mensaje': 'Creada la categoría "$nombre" mediante el chat.',
            'icono': 'create',
            'fecha': DateTime.now().toString().substring(0, 19),
            'leido': false,
            'usuario': 'Michi AI',
          });

          return '¡Miau, jefe Omar! 🐾 *lija un bloque de madera* ¡Listo! He creado la categoría **"$nombre"** en tu catálogo de Firestore. ¡Quedó firme como roble! 🛠️🪵';
        }
      }
    } catch (e) {
      return '¡Miau, jefe! Intenté registrarlo pero se me resbaló el serrucho: $e. ¿Revisamos la conexión? 🐾⚠️';
    }

    return null; // No es comando de acción, continuar con el flujo normal
  }

  /// Consulta en tiempo real colecciones de Firestore para armar un contexto de negocios.
  Future<String> _obtenerContextoERP() async {
    try {
      // Consultamos stock crítico
      var inventarioSnap = await _db.collection('inventario').get();
      int totalCriticos = 0;
      List<String> alertasStock = [];
      
      for (var doc in inventarioSnap.docs) {
        int actual = doc.data()['stock_actual'] ?? 0;
        int minimo = doc.data()['stock_minimo'] ?? 0;
        if (actual <= minimo) {
          totalCriticos++;
          alertasStock.add("ID Producto: ${doc.data()['id_producto'] ?? doc.id} (Stock: $actual, Mínimo: $minimo)");
        }
      }

      // Consultamos ventas/pedidos
      var pedidosSnap = await _db.collection('pedido').get();
      int totalPedidos = pedidosSnap.docs.length;
      double ingresosTotales = 0.0;
      for (var doc in pedidosSnap.docs) {
        ingresosTotales += double.tryParse(doc.data()['total']?.toString() ?? '0') ?? 0.0;
      }

      // Clientes totales
      var clientesSnap = await _db.collection('cliente').get();
      int totalClientes = clientesSnap.docs.length;

      return '''
- Colección Clientes: Hay $totalClientes clientes registrados.
- Colección Pedidos: Se han realizado $totalPedidos pedidos en total, sumando ingresos brutos por \$${ingresosTotales.toStringAsFixed(2)} MXN.
- Colección Inventario: Hay actualmente $totalCriticos productos con stock crítico (bajo el mínimo recomendado).
Alertas activas de stock bajo: ${alertasStock.take(3).join(", ")}.
''';
    } catch (e) {
      return "No se pudo conectar a la base de datos de Firestore en este momento, pero sabemos que la carpintería está activa y con aroma a pino fresco.";
    }
  }

  /// Diccionario inteligente de simulación con personalidad tierna, directa y concisa.
  String _obtenerSimulacionMichi(String mensaje, String contexto) {
    String msg = mensaje.toLowerCase();

    // Extraer datos del contexto para respuestas inteligentes simuladas
    int criticos = 0;
    if (contexto.contains('stock crítico')) {
      var match = RegExp(r'Hay actualmente (\d+) productos').firstMatch(contexto);
      if (match != null) {
        criticos = int.tryParse(match.group(1) ?? '0') ?? 0;
      }
    }

    if (msg.contains('hola') || msg.contains('buenos días') || msg.contains('buenas tardes') || msg.contains('miau')) {
      return '¡Miau, jefe Omar! 🐾 *se estira* Qué alegría saludarte. ¿En qué módulo o madera trabajaremos hoy? ¡Tengo mis herramientas listas! 🪚🪵';
    }

    if (msg.contains('inventario') || msg.contains('stock') || msg.contains('crítico') || msg.contains('bajo') || msg.contains('producto')) {
      if (criticos > 0) {
        return '¡Alerta, Omar! ⚠️ Detecté **$criticos productos en stock crítico** (bajo el mínimo). Deberíamos producir más. 🪵 ¿Quieres que revisemos la lista? 🐾';
      } else {
        return '¡Excelente, jefe Omar! 🐾 ¡El inventario está perfecto! Ningún mueble está en stock crítico. ¡Todo listo para pulir! 🪑✨';
      }
    }

    if (msg.contains('ventas') || msg.contains('pedido') || msg.contains('ingresos') || msg.contains('ganado') || msg.contains('dinero')) {
      String totalVentas = "0.00";
      var match = RegExp(r'sumando ingresos brutos por \$([0-9.]+)').firstMatch(contexto);
      if (match != null) {
        totalVentas = match.group(1) ?? "0.00";
      }
      return '¡Miau! 🐾 Las ventas totales de Mueblería Carrasco suman **\$$totalVentas MXN**. ¡Un número muy firme y bien pulido! ¡Sigue así, jefe Omar! 🌲💰';
    }

    if (msg.contains('clientes') || msg.contains('cliente')) {
      String totalClientes = "0";
      var match = RegExp(r'Hay (\d+) clientes registrados').firstMatch(contexto);
      if (match != null) {
        totalClientes = match.group(1) ?? "0";
      }
      return '¡Miau! Tenemos **$totalClientes clientes consentidos** registrados. 🐾🤝 ¡Cada uno ama nuestro aroma a madera fresca tanto como yo! 🐈‍⬛📦';
    }

    if (msg.contains('ayuda') || msg.contains('como se usa') || msg.contains('ayudame')) {
      return '¡Miau! Con gusto, Omar. Aquí puedes:\n1. 🪑 Gestionar las 11 colecciones del ERP.\n2. 📊 Ver reportes e inventarios en vivo.\n3. 🔔 Recibir alertas automáticas de stock.\n4. 📋 **¡Pedirme crear clientes o categorías directamente por chat!** (ej: *"crea la categoría Mesas de Cedro"*).\n¿En qué te apoyo hoy? 🐾';
    }

    if (msg.contains('creador') || msg.contains('quien te creo') || msg.contains('creo') || msg.contains('alex')) {
      return '¡Prrr! Fui diseñado con mucho cariño por el programador Alex en colaboración con mi jefe Omar. ¡El mejor equipo de desarrollo! 🐈‍⬛💻🔨';
    }

    // Default response
    return '¡Miau, jefe Omar! 🐾 Como tu copiloto, opino que suena excelente. *ronronea* ¿Te gustaría que busque datos específicos de pedidos, inventario o cliente, o que cree un registro por ti? ¡Tú dime! 📏✨';
  }
}
