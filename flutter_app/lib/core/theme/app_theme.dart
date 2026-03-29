import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1E40AF);    // Azul escuro
  static const Color secondary = Color(0xFF3B82F6);  // Azul claro
  static const Color success = Color(0xFF16A34A);    // Verde
  static const Color warning = Color(0xFFD97706);    // Laranja
  static const Color error = Color(0xFFDC2626);      // Vermelho
  static const Color surface = Color(0xFFF8FAFC);    // Cinza muito claro

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );

  // Cores dos estados das encomendas
  static Color statusColor(String status) {
    switch (status) {
      case 'PENDING':       return const Color(0xFF64748B);
      case 'CONFIRMED':     return const Color(0xFF2563EB);
      case 'IN_PRODUCTION': return const Color(0xFFD97706);
      case 'READY':         return const Color(0xFF7C3AED);
      case 'SHIPPED':       return const Color(0xFF0891B2);
      case 'DELIVERED':     return success;
      case 'CANCELLED':     return error;
      default:              return const Color(0xFF64748B);
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'PENDING':       return 'Pendente';
      case 'CONFIRMED':     return 'Confirmada';
      case 'IN_PRODUCTION': return 'Em Produção';
      case 'READY':         return 'Pronta';
      case 'SHIPPED':       return 'Enviada';
      case 'DELIVERED':     return 'Entregue';
      case 'CANCELLED':     return 'Cancelada';
      default:              return status;
    }
  }

  static String roleLabel(String role) {
    switch (role) {
      case 'ADMIN':    return 'Administrador';
      case 'MANAGER':  return 'Gestor';
      case 'OPERATOR': return 'Operador';
      case 'VIEWER':   return 'Visualizador';
      default:         return role;
    }
  }
}
