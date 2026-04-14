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
  final double       kmRate;
  final double       mealCost;
  final List<int>    anosVisiveis;

  const AppSettings({
    required this.anoAtual,
    required this.kmRate,
    required this.mealCost,
    this.anosVisiveis = const [],
  });

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        anoAtual:     (j['anoAtual'] as num?)?.toInt() ?? 0,
        kmRate:       _toDouble(j['kmRate'])   ?? 0.36,
        mealCost:     _toDouble(j['mealCost']) ?? 12.0,
        anosVisiveis: (j['anosVisiveis'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList() ?? [],
      );

  /// Effective year for display (0 = sistema)
  int get effectiveYear => anoAtual > 0 ? anoAtual : DateTime.now().year;
}

final settingsProvider = FutureProvider<AppSettings>((ref) async {
  final response = await ApiClient().dio.get(ApiEndpoints.settings);
  return AppSettings.fromJson(response.data as Map<String, dynamic>);
});
