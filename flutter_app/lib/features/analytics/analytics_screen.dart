import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_drawer.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final statsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final r = await ApiClient().dio.get(ApiEndpoints.stats);
  return r.data as Map<String, dynamic>;
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Desempenho'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: () => ref.invalidate(statsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Erro: $e')),
        data:    (data) => _AnalyticsBody(data: data),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _AnalyticsBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AnalyticsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final summary      = data['summary']       as Map<String, dynamic>;
    final byMonth      = (data['ordersByMonth'] as List).cast<Map<String, dynamic>>();
    final byStatus     = data['ordersByStatus'] as Map<String, dynamic>;
    final topCustomers = (data['topCustomers']  as List).cast<Map<String, dynamic>>();
    final topProducts  = (data['topProducts']   as List).cast<Map<String, dynamic>>();
    final byWork       = (data['ordersByWork']  as List).cast<Map<String, dynamic>>();

    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [

        // ── KPI tiles (3 × 2) ─────────────────────────────────────────────────
        _sectionLabel(Icons.bar_chart_outlined, 'Resumo'),
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.45,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _KpiTile(
              label: 'Encomendas\neste ano',
              value: '${summary['ordersThisYear']}',
              color: AppTheme.primary,
              icon: Icons.inventory_2_outlined,
            ),
            _KpiTile(
              label: 'Encomendas\neste mês',
              value: '${summary['ordersThisMonth']}',
              color: AppTheme.gold,
              icon: Icons.calendar_today_outlined,
            ),
            _KpiTile(
              label: 'Total de\nencomendas',
              value: '${summary['totalOrders']}',
              color: AppTheme.textMuted,
              icon: Icons.all_inbox_outlined,
            ),
            _KpiTile(
              label: 'Faturação\neste ano',
              value: _compactCurrency(summary['revenueThisYear'] ?? 0),
              color: AppTheme.success,
              icon: Icons.euro_outlined,
            ),
            _KpiTile(
              label: 'Faturação\neste mês',
              value: _compactCurrency(summary['revenueThisMonth'] ?? 0),
              color: const Color(0xFF8A5C2A),
              icon: Icons.trending_up_outlined,
            ),
            _KpiTile(
              label: 'Valor médio\npor enc.',
              value: _compactCurrency(summary['avgOrderValue'] ?? 0),
              color: AppTheme.primary,
              icon: Icons.calculate_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Monthly chart (tabbed) ─────────────────────────────────────────────
        _sectionLabel(Icons.show_chart, 'Evolução mensal (últimos 13 meses)'),
        _MonthlyTabChart(byMonth: byMonth),
        const SizedBox(height: 16),

        // ── Status donut + Work bars (side by side on wide screens) ───────────
        LayoutBuilder(builder: (ctx, constraints) {
          final wide = constraints.maxWidth > 460;
          final statusCard = _card(_StatusDonut(byStatus: byStatus));
          final workCard   = byWork.isNotEmpty
              ? _card(_WorkBars(byWork: byWork))
              : null;

          if (wide && workCard != null) {
            return IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(child: _namedSection(
                    Icons.donut_small_outlined, 'Por estado', statusCard)),
                const SizedBox(width: 8),
                Expanded(child: _namedSection(
                    Icons.build_outlined, 'Tipos de trabalho', workCard)),
              ]),
            );
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionLabel(Icons.donut_small_outlined, 'Por estado'),
            statusCard,
            if (workCard != null) ...[
              const SizedBox(height: 16),
              _sectionLabel(Icons.build_outlined, 'Tipos de trabalho mais frequentes'),
              workCard,
            ],
          ]);
        }),
        const SizedBox(height: 16),

        // ── Top clientes ──────────────────────────────────────────────────────
        if (topCustomers.isNotEmpty) ...[
          _sectionLabel(Icons.people_outline, 'Clientes com mais encomendas'),
          _TopList(items: topCustomers.map((c) => _TopItem(
            label:    c['name'] as String,
            primary:  '${c['count']} enc.',
            secondary: currency.format(c['revenue'] ?? 0),
          )).toList()),
          const SizedBox(height: 16),
        ],

        // ── Top produtos ──────────────────────────────────────────────────────
        if (topProducts.isNotEmpty) ...[
          _sectionLabel(Icons.category_outlined, 'Produtos mais vendidos'),
          _TopList(items: topProducts.map((p) => _TopItem(
            label:    p['name'] as String,
            primary:  '${p['qty']} un.',
            secondary: currency.format(p['revenue'] ?? 0),
          )).toList()),
        ],
      ],
    );
  }

  static String _compactCurrency(num v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M€';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}k€';
    return NumberFormat.currency(locale: 'pt_PT', symbol: '€').format(v);
  }

  static Widget _sectionLabel(IconData icon, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icon, size: 14, color: AppTheme.gold),
      const SizedBox(width: 6),
      Text(title,
        style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: AppTheme.primary, letterSpacing: 0.2)),
      const SizedBox(width: 8),
      const Expanded(child: Divider(height: 1)),
    ]),
  );

  static Widget _card(Widget child) => Card(
    margin: EdgeInsets.zero,
    child: child,
  );

  static Widget _namedSection(IconData icon, String title, Widget content) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel(icon, title),
      content,
    ]);
}

// ── KPI tile ──────────────────────────────────────────────────────────────────

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  final IconData icon;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(label,
                  style: const TextStyle(
                    fontSize: 10, color: AppTheme.textMuted, height: 1.3),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 12, color: color),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.bottomLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Monthly tabbed chart ──────────────────────────────────────────────────────

class _MonthlyTabChart extends StatefulWidget {
  final List<Map<String, dynamic>> byMonth;
  const _MonthlyTabChart({required this.byMonth});

  @override
  State<_MonthlyTabChart> createState() => _MonthlyTabChartState();
}

class _MonthlyTabChartState extends State<_MonthlyTabChart>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Column(children: [
      // Tab bar
      Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: TabBar(
          controller: _tab,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.gold,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'Encomendas'),
            Tab(text: 'Faturação'),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 12, 8),
        child: SizedBox(
          height: 180,
          child: _tab.index == 0
              ? _OrdersBarChart(byMonth: widget.byMonth)
              : _RevenueLineChart(byMonth: widget.byMonth),
        ),
      ),
    ]),
  );
}

// ── Bar chart (orders) ────────────────────────────────────────────────────────

class _OrdersBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> byMonth;
  const _OrdersBarChart({required this.byMonth});

  @override
  Widget build(BuildContext context) {
    if (byMonth.isEmpty) return const SizedBox.shrink();
    final maxY = byMonth
        .map((m) => (m['count'] as int).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: (maxY + 1).ceilToDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${byMonth[group.x]['label']}\n${rod.toY.toInt()} enc.',
              const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: maxY > 6 ? null : 1,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= byMonth.length) return const SizedBox.shrink();
                if (i % 2 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(byMonth[i]['label'] as String,
                    style: const TextStyle(fontSize: 8, color: AppTheme.textMuted)),
                );
              },
            ),
          ),
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppTheme.border.withOpacity(0.4), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(byMonth.length, (i) => BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: (byMonth[i]['count'] as int).toDouble(),
              color: AppTheme.primary,
              width: 12,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            ),
          ],
        )),
      ),
    );
  }
}

// ── Line chart (revenue) ──────────────────────────────────────────────────────

class _RevenueLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> byMonth;
  const _RevenueLineChart({required this.byMonth});

  @override
  Widget build(BuildContext context) {
    final spots = byMonth.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), (e.value['revenue'] as num).toDouble()))
        .toList();
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final compact = NumberFormat.compactCurrency(locale: 'pt_PT', symbol: '€');

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY > 0 ? maxY * 1.2 : 100,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (ts) => ts.map((s) => LineTooltipItem(
              '${byMonth[s.x.toInt()]['label']}\n${NumberFormat.currency(locale: 'pt_PT', symbol: '€').format(s.y)}',
              const TextStyle(color: Colors.white, fontSize: 11),
            )).toList(),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (v, _) => Text(compact.format(v),
                style: const TextStyle(fontSize: 8, color: AppTheme.textMuted)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= byMonth.length) return const SizedBox.shrink();
                if (i % 2 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(byMonth[i]['label'] as String,
                    style: const TextStyle(fontSize: 8, color: AppTheme.textMuted)),
                );
              },
            ),
          ),
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppTheme.border.withOpacity(0.4), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.gold,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.gold.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status donut ──────────────────────────────────────────────────────────────

class _StatusDonut extends StatefulWidget {
  final Map<String, dynamic> byStatus;
  const _StatusDonut({required this.byStatus});

  @override
  State<_StatusDonut> createState() => _StatusDonutState();
}

class _StatusDonutState extends State<_StatusDonut> {
  int _touched = -1;

  static const _labels = {
    'PENDING':       'Pendente',
    'CONFIRMED':     'Confirmada',
    'IN_PRODUCTION': 'Em produção',
    'READY':         'Pronta',
    'DELIVERED':     'Entregue',
    'PAID':          'Paga',
    'CANCELLED':     'Cancelada',
  };

  static const _colors = [
    Color(0xFFE67E22),
    Color(0xFF3498DB),
    Color(0xFF9B59B6),
    Color(0xFF2ECC71),
    Color(0xFF1ABC9C),
    Color(0xFF27AE60),
    Color(0xFF95A5A6),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = widget.byStatus.entries
        .where((e) => (e.value as int) > 0).toList();
    final total = entries.fold<int>(0, (s, e) => s + (e.value as int));

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(
          width: 100, height: 100,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (ev, res) => setState(() {
                  _touched = (ev is FlTapUpEvent && res?.touchedSection != null)
                      ? res!.touchedSection!.touchedSectionIndex : -1;
                }),
              ),
              sectionsSpace: 2,
              centerSpaceRadius: 26,
              sections: List.generate(entries.length, (i) {
                final count     = entries[i].value as int;
                final pct       = total > 0 ? count / total * 100 : 0.0;
                final isTouched = i == _touched;
                return PieChartSectionData(
                  value:  count.toDouble(),
                  color:  _colors[i % _colors.length],
                  radius: isTouched ? 34 : 28,
                  title:  isTouched ? '${pct.toStringAsFixed(0)}%' : '',
                  titleStyle: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(entries.length, (i) {
              final e     = entries[i];
              final count = e.value as int;
              final pct   = total > 0 ? count / total * 100 : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Container(
                    width: 8, height: 8,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      color: _colors[i % _colors.length],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Text(_labels[e.key] ?? e.key,
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                  ),
                  Text('$count',
                    style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 3),
                  Text('${pct.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 10, color: AppTheme.textMuted)),
                ]),
              );
            }),
          ),
        ),
      ]),
    );
  }
}

// ── Work bars ─────────────────────────────────────────────────────────────────

class _WorkBars extends StatelessWidget {
  final List<Map<String, dynamic>> byWork;
  const _WorkBars({required this.byWork});

  @override
  Widget build(BuildContext context) {
    final maxX = byWork
        .map((w) => (w['count'] as int).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(byWork.length, (i) {
          final w     = byWork[i];
          final count = w['count'] as int;
          final pct   = maxX > 0 ? count / maxX : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              SizedBox(
                width: 90,
                child: Text(w['name'] as String,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 10,
                    backgroundColor: AppTheme.border.withOpacity(0.25),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primary.withOpacity(0.65)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('$count',
                style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold,
                  color: AppTheme.primary)),
            ]),
          );
        }),
      ),
    );
  }
}

// ── Top list ──────────────────────────────────────────────────────────────────

class _TopItem {
  final String label;
  final String primary;
  final String secondary;
  const _TopItem({required this.label, required this.primary, required this.secondary});
}

class _TopList extends StatelessWidget {
  final List<_TopItem> items;
  const _TopList({required this.items});

  static const _medalColors = [
    Color(0xFFFFD700), // gold
    Color(0xFFC0C0C0), // silver
    Color(0xFFCD7F32), // bronze
  ];

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Column(
      children: List.generate(items.length, (i) {
        final item   = items[i];
        final rankColor = i < 3 ? _medalColors[i] : AppTheme.textMuted;
        return Column(children: [
          if (i > 0)
            const Divider(height: 1, indent: 12, endIndent: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Container(
                width: 22, height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rankColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${i + 1}',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold,
                    color: rankColor)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(item.label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.primary,
                    style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold,
                      color: AppTheme.primary)),
                  Text(item.secondary,
                    style: const TextStyle(
                      fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ]),
          ),
        ]);
      }),
    ),
  );
}
