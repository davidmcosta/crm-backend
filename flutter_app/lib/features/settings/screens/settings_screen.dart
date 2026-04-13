import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _anoCtrl    = TextEditingController();
  final _kmCtrl     = TextEditingController();
  final _mealCtrl   = TextEditingController();
  bool _saving      = false;
  bool _loaded      = false;

  @override
  void dispose() {
    _anoCtrl.dispose();
    _kmCtrl.dispose();
    _mealCtrl.dispose();
    super.dispose();
  }

  void _populate(AppSettings s) {
    if (_loaded) return;
    _anoCtrl.text  = s.anoAtual > 0 ? s.anoAtual.toString() : '';
    _kmCtrl.text   = s.kmRate.toString();
    _mealCtrl.text = s.mealCost.toString();
    _loaded = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final anoText = _anoCtrl.text.trim();
      final ano     = anoText.isEmpty ? 0 : int.tryParse(anoText) ?? 0;
      final km      = double.tryParse(_kmCtrl.text.replaceAll(',', '.'))   ?? 0.36;
      final meal    = double.tryParse(_mealCtrl.text.replaceAll(',', '.')) ?? 12.0;

      await ApiClient().dio.put(ApiEndpoints.settings, data: {
        'anoAtual':  ano,
        'kmRate':    km,
        'mealCost':  meal,
      });

      ref.invalidate(settingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Configurações guardadas'),
              backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro: $e'),
              backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Erro: $e')),
        data:    (settings) {
          _populate(settings);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ── Numeração das encomendas ──────────────────────────────────
              _sectionHeader(
                  Icons.tag_outlined, 'Numeração das encomendas'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ano atual para numeração',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Deixe em branco para usar o ano do sistema. '
                        'As encomendas serão numeradas como 01/AA, 02/AA...',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _anoCtrl,
                        decoration: InputDecoration(
                          labelText: 'Ano (ex: ${DateTime.now().year})',
                          hintText: 'Deixar vazio = ano do sistema',
                          prefixIcon:
                              const Icon(Icons.calendar_today_outlined, size: 18),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.goldFaint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          const Icon(Icons.info_outline,
                              size: 14, color: AppTheme.gold),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ano em uso: ${settings.effectiveYear} '
                              '(próxima encomenda terá o sufixo /${settings.effectiveYear.toString().substring(2)})',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.gold),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Custos de deslocação ──────────────────────────────────────
              _sectionHeader(
                  Icons.directions_car_outlined, 'Custos de deslocação'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estes valores são usados para calcular os custos '
                        'de deslocação nas encomendas.',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _kmCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Custo por km (€/km)',
                              prefixIcon:
                                  Icon(Icons.route_outlined, size: 18),
                              isDense: true,
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _mealCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Custo por refeição (€)',
                              prefixIcon:
                                  Icon(Icons.restaurant_outlined, size: 18),
                              isDense: true,
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar configurações'),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Icon(icon, size: 16, color: AppTheme.gold),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary)),
          const SizedBox(width: 8),
          const Expanded(child: Divider()),
        ]),
      );
}
