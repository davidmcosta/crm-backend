import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ── Ícone (só o símbolo da igreja) ───────────────────────────────────────────

class CasaDasCampasIcon extends StatelessWidget {
  final double size;
  /// Quando [tint] é true aplica cor dourada via ColorFilter (para fundos escuros).
  /// Quando false usa a imagem tal como está.
  final bool tint;

  const CasaDasCampasIcon({
    super.key,
    this.size = 48,
    this.tint = false,
  });

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      'assets/images/logo_icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (!tint) return img;

    return ColorFiltered(
      colorFilter: const ColorFilter.mode(AppTheme.gold, BlendMode.srcIn),
      child: img,
    );
  }
}

// ── Logo horizontal (ícone + "CASA DAS CAMPAS") ───────────────────────────────

class CasaDasCampasLogoHorizontal extends StatelessWidget {
  final double iconSize;
  /// [light] = sobre fundo escuro (imagem original, texto branco)
  /// [dark]  = sobre fundo claro  (ícone tintado a dourado, texto escuro)
  final bool light;

  const CasaDasCampasLogoHorizontal({
    super.key,
    this.iconSize = 28,
    this.light = true,
  });

  @override
  Widget build(BuildContext context) {
    // O logo_horizontal.png já tem ícone + texto brancos sobre fundo transparente,
    // por isso usamo-lo diretamente em fundos escuros.
    // Em fundos claros usamos ícone + texto separados com cores adaptadas.
    if (light) {
      return Image.asset(
        'assets/images/logo_horizontal.png',
        height: iconSize,
        fit: BoxFit.contain,
      );
    }

    // Versão escura: ícone dourado + texto castanho escuro
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CasaDasCampasIcon(size: iconSize, tint: true),
        SizedBox(width: iconSize * .4),
        Text(
          'CASA DAS CAMPAS',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: iconSize * .55,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ── Logo vertical (ícone centrado + texto) ────────────────────────────────────

class CasaDasCampasLogo extends StatelessWidget {
  final double iconSize;
  final bool light;
  final bool showTagline;

  const CasaDasCampasLogo({
    super.key,
    this.iconSize = 56,
    this.light = true,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = light ? Colors.white : AppTheme.primary;
    final subtitleColor =
        light ? Colors.white.withOpacity(0.60) : AppTheme.textMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ícone com fundo circular subtil
        Container(
          padding: EdgeInsets.all(iconSize * .22),
          decoration: BoxDecoration(
            color: AppTheme.gold.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: CasaDasCampasIcon(size: iconSize, tint: false),
        ),
        SizedBox(height: iconSize * .22),

        // Nome
        Text(
          'CASA DAS CAMPAS',
          style: TextStyle(
            color: textColor,
            fontSize: iconSize * .40,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
          ),
        ),

        if (showTagline) ...[
          SizedBox(height: iconSize * .08),
          Text(
            'Sistema de Gestão de Encomendas',
            style: TextStyle(
              color: subtitleColor,
              fontSize: iconSize * .22,
              letterSpacing: .4,
            ),
          ),
        ],
      ],
    );
  }
}
