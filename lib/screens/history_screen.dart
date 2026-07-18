import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/patient_call.dart';
import '../services/history_service.dart';
import '../services/local_db.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime? _selectedDate = DateTime.now();
  ServiceType? _selectedService;
  final _searchCtrl = TextEditingController();

  late Future<List<PatientCall>> _future;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _loadPendingCount();
  }

  Future<List<PatientCall>> _load() {
    return HistoryService.instance.getHistory(
      date: _selectedDate,
      service: _selectedService,
      searchQuery: _searchCtrl.text,
    );
  }

  Future<void> _loadPendingCount() async {
    final count = await LocalDb.instance.countPending();
    if (mounted) setState(() => _pendingCount = count);
  }

  void _reload() {
    setState(() => _future = _load());
    _loadPendingCount();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
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
      appBar: AppBar(title: const Text('Historique des appels')),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilters(),
            if (_pendingCount > 0) _buildPendingBanner(),
            Expanded(
              child: FutureBuilder<List<PatientCall>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Erreur : ${snapshot.error}'));
                  }
                  final calls = snapshot.data ?? [];
                  if (calls.isEmpty) {
                    return const Center(
                      child: Text('Aucun appel pour ces filtres.'),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: calls.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) => _HistoryTile(call: calls[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingBanner() {
    return Container(
      width: double.infinity,
      color: AppColors.attention.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 18, color: AppColors.attention),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$_pendingCount appel(s) enregistré(s) hors-ligne, '
              'pas encore visible(s) ici — en attente de synchronisation.',
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _reload(),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un patient…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded),
                      onPressed: _reload,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(AppSpacing.radius),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.blanc,
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                    border: Border.all(color: AppColors.grisClair),
                  ),
                  child: const Icon(Icons.calendar_month_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_selectedDate != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(DateFormat('EEEE d MMMM yyyy', 'fr_FR')
                    .format(_selectedDate!)),
                onDeleted: () {
                  setState(() => _selectedDate = null);
                  _reload();
                },
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _ServiceChip(
                  label: 'Tous les services',
                  selected: _selectedService == null,
                  onTap: () {
                    setState(() => _selectedService = null);
                    _reload();
                  },
                ),
                ...ServiceType.values.map((s) => _ServiceChip(
                      label: '${s.emoji} ${s.label}',
                      selected: _selectedService == s,
                      onTap: () {
                        setState(() => _selectedService = s);
                        _reload();
                      },
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ServiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: AppColors.bleuMedical,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.grisAnthracite,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final PatientCall call;
  const _HistoryTile({required this.call});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(call.calledAt.toLocal());
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.bleuMedical.withValues(alpha: 0.1),
          child: Text(call.service.emoji, style: const TextStyle(fontSize: 18)),
        ),
        title: Text(call.patientName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${call.serviceDisplayLabel}'
            '${call.salle != null ? ' · ${call.salle}' : ''}'
            ' · par ${call.calledBy}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(time, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            _StatusPill(status: call.status),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final CallStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (status) {
      case CallStatus.enAttente:
        color = AppColors.attention;
        label = 'En attente';
        break;
      case CallStatus.appele:
        color = AppColors.vertEmeraude;
        label = 'Appelé';
        break;
      case CallStatus.termine:
        color = AppColors.grisAnthracite;
        label = 'Terminé';
        break;
      case CallStatus.annule:
        color = AppColors.erreur;
        label = 'Annulé';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}
