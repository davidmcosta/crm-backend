import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ── Ícone da igreja (CustomPaint) ─────────────────────────────────────────────

class CasaDasCampasIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CasaDasCampasIcon({
    super.key,
    this.size = 48,
    this.color = AppTheme.gold,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _ChurchPainter(color),
      );
}

class _ChurchPainter extends CustomPainter {
  final Color color;
  _ChurchPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // saveLayer allows BlendMode.clear para recortar a porta
    canvas.saveLayer(Offset.zero & size, Paint());

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // ── Corpo principal + telhado ─────────────────────────────────────────────
    final church = Path()
      ..moveTo(w * .12, h)         // base esquerda
      ..lineTo(w * .12, h * .50)   // parede esquerda cima
      ..lineTo(w * .02, h * .50)   // beirado esquerdo
      ..lineTo(w * .50, h * .18)   // pico do telhado
      ..lineTo(w * .98, h * .50)   // beirado direito
      ..lineTo(w * .88, h * .50)   // parede direita cima
      ..lineTo(w * .88, h)         // base direita
      ..close();
    canvas.drawPath(church, fill);

    // ── Torre / campanário ────────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(w * .41, h * .06, w * .18, h * .14),
      fill,
    );

    // ── Cruz no topo ──────────────────────────────────────────────────────────
    // haste vertical
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .455, 0, w * .09, h * .10),
        Radius.circular(w * .02),
      ),
      fill,
    );
    // travessão horizontal
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .36, h * .025, w * .28, h * .045),
        Radius.circular(w * .02),
      ),
      fill,
    );

    // ── Porta arqueada (recorte) ──────────────────────────────────────────────
    final door = Path()
      ..moveTo(w * .375, h)
      ..lineTo(w * .375, h * .72)
      ..arcToPoint(
        Offset(w * .625, h * .72),
        radius: Radius.circular(w * .125),
        clockwise: false,
      )
      ..lineTo(w * .625, h)
      ..close();

    canvas.drawPath(
      door,
      Paint()
        ..color = Colors.black
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.fill,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChurchPainter old) => old.color != color;
}

// ── Logo completo (ícone + texto) ─────────────────────────────────────────────

class CasaDasCampasLogo extends StatelessWidget {
  /// [light] = texto branco sobre fundo escuro  [dark] = texto escuro sobre fundo claro
  final bool light;
  final double iconSize;
  final bool showTagline;

  const CasaDasCampasLogo({
    super.key,
    this.light = true,
    this.iconSize = 52,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = light ? Colors.white : AppTheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ícone com fundo circular subtil
        Container(
          padding: EdgeInsets.all(iconSize * .26),
          decoration: BoxDecoration(
            color: AppTheme.gold.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: CasaDasCampasIcon(size: iconSize, color: AppTheme.gold),
        ),
        SizedBox(height: iconSize * .22),

        // Nome da empresa
        Text(
          'CASA DAS CAMPAS',
          style: TextStyle(
            color: textColor,
            fontSize: iconSize * .42,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
          ),
        ),

        if (showTagline) ...[
          SizedBox(height: iconSize * .08),
          Text(
            'Sistema de Gestão de Encomendas',
            style: TextStyle(
              color: light
                  ? Colors.white.withOpacity(0.60)
                  : AppTheme.textMuted,
              fontSize: iconSize * .24,
              letterSpacing: .4,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Versão horizontal (ícone + texto lado a lado) ─────────────────────────────

class CasaDasCampasLogoHorizontal extends StatelessWidget {
  final bool light;
  final double iconSize;

  const CasaDasCampasLogoHorizontal({
    super.key,
    this.light = true,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = light ? Colors.white : AppTheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CasaDasCampasIcon(size: iconSize, color: AppTheme.gold),
        SizedBox(width: iconSize * .35),
        Text(
          'CASA DAS CAMPAS',
          style: TextStyle(
            color: textColor,
            fontSize: iconSize * .52,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
