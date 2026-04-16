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
    final summary     = data['summary']      as Map<String, dynamic>;
    final byMonth     = (data['ordersByMonth'] as List).cast<Map<String, dynamic>>();
    final byStatus    = data['ordersByStatus'] as Map<String, dynamic>;
    final topCustomers= (data['topCustomers']  as List).cast<Map<String, dynamic>>();
    final topProducts = (data['topProducts']   as List).cast<Map<String, dynamic>>();
    final byWork      = (data['ordersByWork']  as List).cast<Map<String, dynamic>>();

    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        // ── Cards de resumo ───────────────────────────────────────────────────
        _SectionHeader(Icons.bar_chart_outlined, 'Resumo geral'),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.0,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _SummaryCard('Encomendas (ano)', '${summary['ordersThisYear']}',
                Icons.inventory_2_outlined, AppTheme.primary),
            _SummaryCard('Encomendas (mês)', '${summary['ordersThisMonth']}',
                Icons.calendar_today_outlined, AppTheme.gold),
            _SummaryCard('Faturação (ano)', currency.format(summary['revenueThisYear'] ?? 0),
                Icons.euro_outlined, AppTheme.success),
            _SummaryCard('Faturação (mês)', currency.format(summary['revenueThisMonth'] ?? 0),
                Icons.trending_up_outlined, const Color(0xFF8A5C2A)),
            _SummaryCard('Valor médio', currency.format(summary['avgOrderValue'] ?? 0),
                Icons.calculate_outlined, AppTheme.primary),
            _SummaryCard('Total encomendas', '${summary['totalOrders']}',
                Icons.all_inbox_outlined, AppTheme.textMuted),
          ],
        ),
        const SizedBox(height: 24),

        // ── Encomendas por mês ────────────────────────────────────────────────
        _SectionHeader(Icons.show_chart, 'Encomendas por mês (últimos 13 meses)'),
        _MonthlyOrdersChart(byMonth: byMonth),
        const SizedBox(height: 24),

        // ── Faturação por mês ─────────────────────────────────────────────────
        _SectionHeader(Icons.euro_outlined, 'Faturação por mês (encomendas pagas)'),
        _MonthlyRevenueChart(byMonth: byMonth),
        const SizedBox(height: 24),

        // ── Encomendas por estado ─────────────────────────────────────────────
        _SectionHeader(Icons.donut_small_outlined, 'Encomendas por estado'),
        _StatusPieChart(byStatus: byStatus),
        const SizedBox(height: 24),

        // ── Tipo de trabalho ──────────────────────────────────────────────────
        if (byWork.isNotEmpty) ...[
          _SectionHeader(Icons.build_outlined, 'Tipos de trabalho mais frequentes'),
          _WorkBarChart(byWork: byWork),
          const SizedBox(height: 24),
        ],

        // ── Top clientes ──────────────────────────────────────────────────────
        if (topCustomers.isNotEmpty) ...[
          _SectionHeader(Icons.people_outline, 'Clientes com mais encomendas'),
          _TopListCard(
            items: topCustomers.map((c) => _TopItem(
              label:    c['name'] as String,
              value:    '${c['count']} enc.',
              subValue: currency.format(c['revenue'] ?? 0),
            )).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // ── Top produtos ──────────────────────────────────────────────────────
        if (topProducts.isNotEmpty) ...[
          _SectionHeader(Icons.category_outlined, 'Produtos mais vendidos'),
          _TopListCard(
            items: topProducts.map((p) => _TopItem(
              label:    p['name'] as String,
              value:    '${p['qty']} un.',
              subValue: currency.format(p['revenue'] ?? 0),
            )).toList(),
          ),
          const SizedBox(height: 24),
        ],

        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(label,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ]),
    ),
  );
}

// ── Monthly orders bar chart ──────────────────────────────────────────────────

class _MonthlyOrdersChart extends StatelessWidget {
  final List<Map<String, dynamic>> byMonth;
  const _MonthlyOrdersChart({required this.byMonth});

  @override
  Widget build(BuildContext context) {
    if (byMonth.isEmpty) return const SizedBox.shrink();
    final maxY = byMonth.map((m) => (m['count'] as int).toDouble()).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: (maxY + 2).ceilToDouble(),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                    '${byMonth[group.x]['label']}\n${rod.toY.toInt()} enc.',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= byMonth.length) return const SizedBox.shrink();
                      // Show every other label to avoid clutter
                      if (i % 2 != 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          byMonth[i]['label'] as String,
                          style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                        ),
                      );
                    },
                  ),
                ),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                drawHorizontalLine: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppTheme.border.withOpacity(0.5),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(byMonth.length, (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: (byMonth[i]['count'] as int).toDouble(),
                    color: AppTheme.primary,
                    width: 14,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              )),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Monthly revenue line chart ────────────────────────────────────────────────

class _MonthlyRevenueChart extends StatelessWidget {
  final List<Map<String, dynamic>> byMonth;
  const _MonthlyRevenueChart({required this.byMonth});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.compactCurrency(locale: 'pt_PT', symbol: '€');
    final spots = byMonth.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), (e.value['revenue'] as num).toDouble())
    ).toList();

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY > 0 ? maxY * 1.2 : 100,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                    '${byMonth[s.x.toInt()]['label']}\n${NumberFormat.currency(locale: 'pt_PT', symbol: '€').format(s.y)}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  )).toList(),
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    getTitlesWidget: (v, _) => Text(
                      currency.format(v),
                      style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= byMonth.length) return const SizedBox.shrink();
                      if (i % 2 != 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          byMonth[i]['label'] as String,
                          style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                        ),
                      );
                    },
                  ),
                ),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppTheme.border.withOpacity(0.5),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppTheme.gold,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.gold.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Status donut chart ────────────────────────────────────────────────────────

class _StatusPieChart extends StatefulWidget {
  final Map<String, dynamic> byStatus;
  const _StatusPieChart({required this.byStatus});

  @override
  State<_StatusPieChart> createState() => _StatusPieChartState();
}

class _StatusPieChartState extends State<_StatusPieChart> {
  int _touched = -1;

  static const _labels = {
    'PENDING':      'Pendente',
    'CONFIRMED':    'Confirmada',
    'IN_PRODUCTION':'Em produção',
    'READY':        'Pronta',
    'DELIVERED':    'Entregue',
    'PAID':         'Paga',
    'CANCELLED':    'Cancelada',
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
        .where((e) => (e.value as int) > 0)
        .toList();
    final total = entries.fold<int>(0, (s, e) => s + (e.value as int));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 160, height: 160,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (ev, res) => setState(() {
                      _touched = (ev is FlTapUpEvent && res?.touchedSection != null)
                          ? res!.touchedSection!.touchedSectionIndex
                          : -1;
                    }),
                  ),
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  sections: List.generate(entries.length, (i) {
                    final e     = entries[i];
                    final count = e.value as int;
                    final pct   = total > 0 ? count / total * 100 : 0.0;
                    final isTouched = i == _touched;
                    return PieChartSectionData(
                      value:  count.toDouble(),
                      color:  _colors[i % _colors.length],
                      radius: isTouched ? 52 : 44,
                      title:  isTouched ? '${pct.toStringAsFixed(1)}%' : '',
                      titleStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(entries.length, (i) {
                  final e     = entries[i];
                  final count = e.value as int;
                  final pct   = total > 0 ? count / total * 100 : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      Container(
                        width: 10, height: 10,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: _colors[i % _colors.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _labels[e.key] ?? e.key,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('$count', style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text('(${pct.toStringAsFixed(0)}%)',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ]),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Work type bar chart ───────────────────────────────────────────────────────

class _WorkBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> byWork;
  const _WorkBarChart({required this.byWork});

  @override
  Widget build(BuildContext context) {
    final maxX = byWork.map((w) => (w['count'] as int).toDouble()).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: List.generate(byWork.length, (i) {
            final w     = byWork[i];
            final count = w['count'] as int;
            final pct   = maxX > 0 ? count / maxX : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    w['name'] as String,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 12,
                      backgroundColor: AppTheme.border.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primary.withOpacity(0.7)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$count',
                  style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold,
                    color: AppTheme.primary)),
              ]),
            );
          }),
        ),
      ),
    );
  }
}

// ── Top list card ─────────────────────────────────────────────────────────────

class _TopItem {
  final String label;
  final String value;
  final String subValue;
  const _TopItem({required this.label, required this.value, required this.subValue});
}

class _TopListCard extends StatelessWidget {
  final List<_TopItem> items;
  const _TopListCard({required this.items});

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: List.generate(items.length, (i) {
        final item = items[i];
        return Column(
          children: [
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.gold.withOpacity(0.15),
                child: Text('${i + 1}',
                  style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold,
                    color: AppTheme.gold)),
              ),
              title: Text(item.label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item.value,
                    style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold,
                      color: AppTheme.primary)),
                  Text(item.subValue,
                    style: const TextStyle(
                      fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
          ],
        );
      }),
    ),
  );
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader(this.icon, this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, size: 16, color: AppTheme.gold),
      const SizedBox(width: 8),
      Text(title,
        style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
      const SizedBox(width: 8),
      const Expanded(child: Divider()),
    ]),
  );
}
