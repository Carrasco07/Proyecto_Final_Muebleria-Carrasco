import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'splash_screen.dart';
import 'admin/login_screen.dart';
import 'admin/menu_screen.dart';
import 'admin/gestion_modulo_screen.dart';
import 'admin/dashboard_screen.dart';
import 'admin/permission_management_screen.dart';
import 'selection_screen.dart';
import 'client/client_login_screen.dart';
import 'client/client_dashboard_screen.dart';
import 'client/client_product_detail_screen.dart';
import 'client/client_account_screen.dart';
import 'client/client_order_success_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('es_MX', null);
  Intl.defaultLocale = 'es_MX';

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PantallaSplash(),
    ),
    GoRoute(
      path: '/selection',
      builder: (context, state) => const SelectionScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/client_login',
      builder: (context, state) => const ClientLoginScreen(),
    ),
    GoRoute(
      path: '/client_dashboard',
      builder: (context, state) => const ClientDashboardScreen(),
    ),
    GoRoute(
      path: '/product_detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ClientProductDetailScreen(
          product: extra,
          onAddToCart: (_) {},
        );
      },
    ),
    GoRoute(
      path: '/client_account',
      builder: (context, state) => const ClientAccountScreen(),
    ),
    GoRoute(
      path: '/client_order_success',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ClientOrderSuccessScreen(
          pedidoId: extra['pedidoId'] ?? '',
          orderNumber: extra['orderNumber'] ?? 0,
          total: extra['total'] ?? 0.0,
          clientName: extra['clientName'] ?? 'Cliente',
          metodoPago: extra['metodoPago'] ?? 'Tarjeta',
          cartItems: List<Map<String,dynamic>>.from(extra['cartItems'] ?? []),
        );
      },
    ),
    GoRoute(
      path: '/menu',
      builder: (context, state) => const MenuScreen(),
    ),
    GoRoute(
      path: '/gestion/permisos',
      builder: (context, state) => const PermissionManagementScreen(),
    ),
    GoRoute(
      path: '/gestion/:modulo',
      builder: (context, state) {
        final modulo = state.pathParameters['modulo'] ?? 'productos';
        if (modulo == 'dashboard') return const DashboardScreen();
        return GestionModuloScreen(modulo: modulo);
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Mueblería Carrasco',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF2C3E50),
        scaffoldBackgroundColor: const Color(0xFFEDEFF2),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 5,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF3498DB),
        scaffoldBackgroundColor: const Color(0xFF0A0B0C),
        cardTheme: const CardThemeData(
          color: Color(0xFF161B22),
          elevation: 5,
        ),
      ),
      routerConfig: _router,
    );
  }
}