import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class AppSettings {
  final int    anoAtual;
  final double kmRate;
  final double mealCost;

  const AppSettings({
    required this.anoAtual,
    required this.kmRate,
    required this.mealCost,
  });

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        anoAtual: (j['anoAtual'] as num?)?.toInt()    ?? 0,
        kmRate:   (j['kmRate']   as num?)?.toDouble() ?? 0.36,
        mealCost: (j['mealCost'] as num?)?.toDouble() ?? 12.0,
      );

  /// Effective year for display (0 = sistema)
  int get effectiveYear => anoAtual > 0 ? anoAtual : DateTime.now().year;
}

final settingsProvider = FutureProvider<AppSettings>((ref) async {
  final response = await ApiClient().dio.get(ApiEndpoints.settings);
  return AppSettings.fromJson(response.data as Map<String, dynamic>);
});
