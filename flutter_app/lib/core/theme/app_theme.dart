import 'package:flutter/material.dart';

class AppTheme {
  // ── Paleta principal ──────────────────────────────────────────────────────────
  static const Color primary    = Color(0xFF292624); // castanho escuro
  static const Color gold       = Color(0xFFAFA363); // dourado quente
  static const Color goldLight  = Color(0xFFC8B87A); // dourado claro
  static const Color goldFaint  = Color(0xFFEDE5CE); // dourado muito suave
  static const Color surface    = Color(0xFFF5F0E8); // creme quente (fundo)
  static const Color cardColor  = Color(0xFFFDFBF7); // branco quente (cards)
  static const Color textMuted  = Color(0xFF6B6355); // cinza quente
  static const Color border     = Color(0xFFDED0AA); // borda quente
  static const Color success    = Color(0xFF5A7A3A); // verde suave
  static const Color warning    = Color(0xFFB87A30); // âmbar
  static const Color error      = Color(0xFF963030); // vermelho suave

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: gold,
      brightness: Brightness.light,
    ).copyWith(
      primary:          primary,
      onPrimary:        Colors.white,
      secondary:        gold,
      onSecondary:      primary,
      secondaryContainer: goldFaint,
      onSecondaryContainer: primary,
      surface:          cardColor,
      onSurface:        const Color(0xFF1A1714),
      background:       surface,
      onBackground:     const Color(0xFF1A1714),
      error:            error,
      onError:          Colors.white,
      outline:          border,
    ),
    scaffoldBackgroundColor: surface,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
    ),

    // Cards
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      color: cardColor,
    ),

    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: gold, width: 2),
      ),
      labelStyle: const TextStyle(color: textMuted),
      prefixIconColor: textMuted,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // ElevatedButton — dourado com texto escuro
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: primary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        textStyle: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),

    // OutlinedButton
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ),

    // TextButton
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: gold,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    // Chips / FilterChip
    chipTheme: ChipThemeData(
      selectedColor: gold.withOpacity(0.25),
      checkmarkColor: primary,
      side: const BorderSide(color: border),
      labelStyle: const TextStyle(fontSize: 13, color: textMuted),
      secondaryLabelStyle: const TextStyle(
          fontSize: 13, color: primary, fontWeight: FontWeight.w600),
      backgroundColor: cardColor,
      secondarySelectedColor: gold.withOpacity(0.25),
    ),

    // Drawer
    drawerTheme: const DrawerThemeData(
      backgroundColor: cardColor,
    ),

    // Floating Action Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: gold,
      foregroundColor: primary,
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: border,
      thickness: 1,
    ),
  );

  // ── Cores dos estados ─────────────────────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status) {
      case 'PENDING':       return const Color(0xFF8A7A60);
      case 'CONFIRMED':     return gold;
      case 'IN_PRODUCTION': return warning;
      case 'READY':         return success;
      case 'DELIVERED':     return const Color(0xFF3D6440);
      case 'PAID':          return const Color(0xFF1565C0); // azul escuro — dinheiro
      case 'CANCELLED':     return error;
      default:              return textMuted;
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'PENDING':       return 'Pendente';
      case 'CONFIRMED':     return 'Confirmada';
      case 'IN_PRODUCTION': return 'Em Processo';
      case 'READY':         return 'Concluída';
      case 'DELIVERED':     return 'Entregue';
      case 'PAID':          return 'Pago';
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
