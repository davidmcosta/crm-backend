import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

// Prisma Decimal fields come back as strings — handle both
double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

class AppSettings {
  final int          anoAtual;
  final int          numeroInicial;
  final double       kmRate;
  final double       mealCost;
  final double       desgasteKm;
  final double       precoCombustivel; // €/litro
  final double       consumoViatura;   // l/100km
  final String       moradaOrigem;
  final List<int>    anosVisiveis;

  const AppSettings({
    required this.anoAtual,
    this.numeroInicial     = 1,
    required this.kmRate,
    required this.mealCost,
    this.desgasteKm        = 0,
    this.precoCombustivel  = 0,
    this.consumoViatura    = 0,
    this.moradaOrigem      = '',
    this.anosVisiveis      = const [],
  });

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        anoAtual:         (j['anoAtual']      as num?)?.toInt() ?? 0,
        numeroInicial:    (j['numeroInicial'] as num?)?.toInt() ?? 1,
        kmRate:           _toDouble(j['kmRate'])            ?? 0.36,
        mealCost:         _toDouble(j['mealCost'])          ?? 12.0,
        desgasteKm:       _toDouble(j['desgasteKm'])        ?? 0.0,
        precoCombustivel: _toDouble(j['precoCombustivel'])  ?? 0.0,
        consumoViatura:   _toDouble(j['consumoViatura'])    ?? 0.0,
        moradaOrigem:     j['moradaOrigem']  as String? ?? '',
        anosVisiveis:     (j['anosVisiveis'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList() ?? [],
      );

  /// Custo de combustível por km (calculado)
  double get combustivelKm => consumoViatura > 0 && precoCombustivel > 0
      ? consumoViatura / 100 * precoCombustivel
      : 0;

  /// Taxa total por km (IRS + desgaste + combustível)
  double get taxaTotalKm => kmRate + desgasteKm + combustivelKm;

  /// Effective year for display (0 = sistema)
  int get effectiveYear => anoAtual > 0 ? anoAtual : DateTime.now().year;
}

final settingsProvider = FutureProvider.autoDispose<AppSettings>((ref) async {
  final response = await ApiClient().dio.get(ApiEndpoints.settings);
  return AppSettings.fromJson(response.data as Map<String, dynamic>);
});
