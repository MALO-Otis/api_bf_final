import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../utils/smart_appbar.dart';
import '../services/conditionnement_db_service.dart';

class RapportsAnalyticsPage extends StatefulWidget {
  const RapportsAnalyticsPage({super.key});

  @override
  State<RapportsAnalyticsPage> createState() => _RapportsAnalyticsPageState();
}

class _RapportsAnalyticsPageState extends State<RapportsAnalyticsPage>
    with TickerProviderStateMixin {
  late ConditionnementDbService _service;
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    try {
      _service = Get.find<ConditionnementDbService>();
    } catch (_) {
      _service = Get.put(ConditionnementDbService());
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await _service.refreshData();
      final stats = await _service.getStatistiques();
      if (mounted) setState(() => _stats = stats);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: SmartAppBar(
        title: '📊 Rapports & Analytics',
        backgroundColor: const Color(0xFF1E88E5),
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 12 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKpis(isMobile),
                  const SizedBox(height: 16),
                  _buildRepartitionParSite(isMobile),
                  const SizedBox(height: 16),
                  _buildTopEmballages(isMobile),
                ],
              ),
            ),
    );
  }

  Widget _buildKpis(bool isMobile) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Row(
          children: [
            _kpi('Lots conditionnés', '${_stats['lotsConditionnes'] ?? 0}',
                Icons.inventory_2, Colors.indigo, isMobile),
            const SizedBox(width: 12),
            _kpi(
                'Quantité totale',
                '${(_stats['quantiteTotaleConditionnee'] ?? 0.0).toStringAsFixed(1)} kg',
                Icons.scale,
                Colors.green,
                isMobile),
            const SizedBox(width: 12),
            _kpi(
                'Valeur totale',
                NumberFormat.currency(
                        locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
                    .format(_stats['valeurTotaleConditionnee'] ?? 0),
                Icons.payments,
                Colors.orange,
                isMobile),
          ],
        ),
      ),
    );
  }

  Widget _kpi(
      String label, String value, IconData icon, Color color, bool isMobile) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: isMobile ? 20 : 24),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 14 : 16,
                color: color,
              )),
          Text(label,
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                color: Colors.grey.shade700,
              )),
        ],
      ),
    );
  }

  Widget _buildRepartitionParSite(bool isMobile) {
    final repSite = (_stats['repartitionParSite'] as Map<String, int>?) ?? {};
    if (repSite.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_city, color: Colors.indigo),
                const SizedBox(width: 8),
                Text('Répartition par site',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 14 : 16)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: repSite.entries
                  .map((e) => Chip(
                        backgroundColor: Colors.indigo.shade50,
                        label: Text('${e.key}  •  ${e.value}'),
                      ))
                  .toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTopEmballages(bool isMobile) {
    final emb = (_stats['emballagesPopulaires'] as Map<String, int>?) ?? {};
    if (emb.isEmpty) return const SizedBox.shrink();

    final entries = emb.entries.toList();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_food_beverage, color: Colors.orange),
                const SizedBox(width: 8),
                Text('Emballages les plus utilisés',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 14 : 16)),
              ],
            ),
            const SizedBox(height: 12),
            ...entries.take(6).map((e) => Row(
                  children: [
                    Expanded(
                        child: Text(e.key,
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text('${e.value}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        )),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
