import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/patient_call.dart';
import '../services/dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDate = DateTime.now();
  late Future<DashboardStats> _future;

  @override
  void initState() {
    super.initState();
    _future = DashboardService.instance.getStatsForDate(_selectedDate);
  }

  void _reload() {
    setState(() => _future = DashboardService.instance.getStatsForDate(_selectedDate));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            tooltip: 'Choisir la date',
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<DashboardStats>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erreur : ${snapshot.error}'));
            }
            final stats = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Text(
                    DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.grisAnthracite.withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildKpiRow(stats),
                  const SizedBox(height: AppSpacing.lg),
                  _SectionCard(
                    title: 'Appels par service',
                    child: stats.byService.isEmpty
                        ? const _EmptyChart()
                        : _ServiceBarChart(data: stats.byService),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    title: 'Appels par heure de la journée',
                    child: stats.totalCalls == 0
                        ? const _EmptyChart()
                        : _HourBarChart(data: stats.byHour),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    title: 'Activité par agent',
                    child: stats.byAgent.isEmpty
                        ? const _EmptyChart()
                        : _AgentList(data: stats.byAgent),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _NoteCard(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildKpiRow(DashboardStats stats) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'Appels du jour',
            value: '${stats.totalCalls}',
            icon: Icons.campaign_rounded,
            color: AppColors.bleuMedical,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _KpiCard(
            label: 'Service le plus actif',
            value: stats.busiestService != null
                ? '${stats.busiestService!.emoji} ${stats.busiestService!.label}'
                : '—',
            icon: Icons.local_hospital_rounded,
            color: AppColors.vertEmeraude,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: AppSpacing.sm),
            Text(value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grisAnthracite.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.md),
            SizedBox(height: 180, child: child),
          ],
        ),
      ),
    );
  }
}

class _ServiceBarChart extends StatelessWidget {
  final Map<ServiceType, int> data;
  const _ServiceBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: (maxY + 1).toDouble(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(entries[i].key.emoji, style: const TextStyle(fontSize: 16)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < entries.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: entries[i].value.toDouble(),
                color: AppColors.bleuMedical,
                width: 22,
                borderRadius: BorderRadius.circular(6),
              ),
            ]),
        ],
      ),
    );
  }
}

class _HourBarChart extends StatelessWidget {
  final Map<int, int> data;
  const _HourBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = data.values.isEmpty
        ? 1
        : data.values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: (maxY + 1).toDouble(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 3,
              getTitlesWidget: (value, meta) {
                final h = value.toInt();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${h}h', style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var h = 0; h < 24; h++)
            BarChartGroupData(x: h, barRods: [
              BarChartRodData(
                toY: (data[h] ?? 0).toDouble(),
                color: AppColors.vertEmeraude,
                width: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ]),
        ],
      ),
    );
  }
}

class _AgentList extends StatelessWidget {
  final Map<String, int> data;
  const _AgentList({required this.data});

  @override
  Widget build(BuildContext context) {
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ListView.separated(
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final e = sorted[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(e.key, overflow: TextOverflow.ellipsis)),
              Text('${e.value}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Aucune donnée pour cette date.',
          style: TextStyle(color: Colors.grey)),
    );
  }
}

class _NoteCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.grisClair.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: const Text(
        'ℹ️ Le temps d\'attente réel par patient nécessite un horodatage '
        'd\'arrivée (ticket d\'accueil), non encore capturé. Les chiffres '
        'ci-dessus reflètent le volume et la répartition des appels.',
        style: TextStyle(fontSize: 12, color: AppColors.grisAnthracite),
      ),
    );
  }
}
