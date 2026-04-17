import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../../../shared/widgets/app_drawer.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _anoCtrl            = TextEditingController();
  final _numeroInicialCtrl  = TextEditingController();
  final _kmCtrl             = TextEditingController();
  final _mealCtrl           = TextEditingController();
  final _moradaOrigemCtrl   = TextEditingController();
  bool _saving              = false;
  bool _loaded              = false;
  List<int> _anosVisiveis   = [];

  @override
  void dispose() {
    _anoCtrl.dispose();
    _numeroInicialCtrl.dispose();
    _kmCtrl.dispose();
    _mealCtrl.dispose();
    _moradaOrigemCtrl.dispose();
    super.dispose();
  }

  void _populate(AppSettings s) {
    if (_loaded) return;
    _anoCtrl.text            = s.anoAtual > 0 ? s.anoAtual.toString() : '';
    _numeroInicialCtrl.text  = s.numeroInicial > 1 ? s.numeroInicial.toString() : '';
    _kmCtrl.text             = s.kmRate.toString();
    _mealCtrl.text           = s.mealCost.toString();
    _moradaOrigemCtrl.text   = s.moradaOrigem;
    _anosVisiveis            = List<int>.from(s.anosVisiveis);
    _loaded = true;
  }

  List<int> _yearOptions() {
    final current = DateTime.now().year;
    return List.generate(5, (i) => current - 3 + i);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final anoText     = _anoCtrl.text.trim();
      final numIniText  = _numeroInicialCtrl.text.trim();
      final ano         = anoText.isEmpty    ? 0 : int.tryParse(anoText)    ?? 0;
      final numInicial  = numIniText.isEmpty ? 1 : int.tryParse(numIniText) ?? 1;
      final km          = double.tryParse(_kmCtrl.text.replaceAll(',', '.'))   ?? 0.36;
      final meal        = double.tryParse(_mealCtrl.text.replaceAll(',', '.')) ?? 12.0;

      await ApiClient().dio.put(ApiEndpoints.settings, data: {
        'anoAtual':      ano,
        'numeroInicial': numInicial,
        'kmRate':        km,
        'mealCost':      meal,
        'moradaOrigem':  _moradaOrigemCtrl.text.trim(),
        'anosVisiveis':  _anosVisiveis,
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
            content: Text(friendlyError(e)),
            backgroundColor: AppTheme.error,
          ),
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
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Configurações')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => _buildErrorView(
          friendlyError(e),
          () => ref.invalidate(settingsProvider),
        ),
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
                      const SizedBox(height: 12),
                      const Text(
                        'Número inicial',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Número a partir do qual começa a contagem quando não '
                        'existem encomendas no ano em uso. Deixe em branco para começar em 1.',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _numeroInicialCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Número inicial (ex: 50)',
                          hintText: 'Deixar vazio = começa em 1',
                          prefixIcon: Icon(Icons.pin_outlined, size: 18),
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

              // ── Anos visíveis na listagem ─────────────────────────────────
              _sectionHeader(
                  Icons.calendar_view_month_outlined, 'Anos visíveis'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filtra a listagem de encomendas pelos anos selecionados. '
                        'Se nenhum ano estiver selecionado, mostram-se todos.',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _yearOptions().map((year) {
                          final selected = _anosVisiveis.contains(year);
                          return FilterChip(
                            label: Text('$year'),
                            selected: selected,
                            onSelected: (_) => setState(() {
                              if (selected) {
                                _anosVisiveis.remove(year);
                              } else {
                                _anosVisiveis.add(year);
                                _anosVisiveis.sort();
                              }
                            }),
                          );
                        }).toList(),
                      ),
                      if (_anosVisiveis.isNotEmpty) ...[
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
                                'A mostrar encomendas de: ${_anosVisiveis.join(', ')}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppTheme.gold),
                              ),
                            ),
                          ]),
                        ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Todos os anos visíveis (sem filtro)',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.success),
                          ),
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
                              prefixIcon: Icon(Icons.route_outlined, size: 18),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _mealCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Custo por refeição (€)',
                              prefixIcon: Icon(Icons.restaurant_outlined, size: 18),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Via Verde ─────────────────────────────────────────────────
              _sectionHeader(Icons.toll_outlined, 'Via Verde'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Morada de origem para o cálculo automático de km e portagens. '
                        'Usa o endereço da empresa ou local de partida habitual.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _moradaOrigemCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Morada de origem',
                          hintText: 'ex: Rua Exemplo 10, Braga',
                          prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                          isDense: true,
                        ),
                      ),
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

Widget _buildErrorView(String message, VoidCallback onRetry) => Center(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off_rounded, size: 56,
            color: AppTheme.textMuted.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tentar novamente'),
          onPressed: onRetry,
        ),
      ],
    ),
  ),
);
