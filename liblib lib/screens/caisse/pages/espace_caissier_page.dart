import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/caisse_cloture.dart';
import '../../../utils/smart_appbar.dart';
import '../../vente/models/vente_models.dart';
import '../controllers/caisse_controller.dart';
import '../../vente/services/vente_service.dart';
import '../../../authentication/user_session.dart';
import '../../vente/controllers/espace_commercial_controller.dart';

/// 🏦 Espace Caissier (Version 1 - MVP)
class EspaceCaissierPage extends StatefulWidget {
  const EspaceCaissierPage({super.key});

  @override
  State<EspaceCaissierPage> createState() => _EspaceCaissierPageState();
}

class _EspaceCaissierPageState extends State<EspaceCaissierPage> {
  late CaisseController caisseCtrl;
  late EspaceCommercialController espaceCtrl;

  @override
  void initState() {
    super.initState();
    // Tentative de récupération du controller commercial déjà existant
    // (normalement initialisé en entrant dans l'espace commercial)
    // Si absent (accès direct via sidebar CAISSE), on l'initialise ici.
    try {
      espaceCtrl = Get.find<EspaceCommercialController>();
    } catch (_) {
      espaceCtrl = Get.put(EspaceCommercialController(), permanent: true);
    }
    if (Get.isRegistered<CaisseController>()) {
      caisseCtrl = Get.find<CaisseController>();
    } else {
      caisseCtrl = Get.put(CaisseController(), permanent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: SmartAppBar(
        title: '🏦 Espace Caissier',
        backgroundColor: const Color(0xFF0EA5E9),
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Exporter CSV',
            onPressed: _exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Changer période',
            onPressed: _pickPeriode,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => caisseCtrl..setPeriode(caisseCtrl.periode.value),
          )
        ],
      ),
      // IMPORTANT: éviter un Obx global couvrant toute la page -> on fragmente
      body: _buildContent(isMobile),
    );
  }

  Future<void> _pickPeriode() async {
    final now = DateTime.now();
    final initial = caisseCtrl.periode.value;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initial,
    );
    if (range != null) {
      caisseCtrl.setPeriode(DateTimeRange(
          start: range.start,
          end: range.end
              .add(const Duration(hours: 23, minutes: 59, seconds: 59))));
    }
  }

  Widget _buildContent(bool isMobile) {
    return LayoutBuilder(builder: (c, cons) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header réactif (période)
            Obx(() => _buildHeader(isMobile)),
            const SizedBox(height: 24),
            Obx(() => _maybeLoadingBanner()),
            Obx(() => espaceCtrl.isLoading.value
                ? const SizedBox(height: 12)
                : const SizedBox.shrink()),
            // Grille KPI réactive
            Obx(() => _buildKpiGrid(isMobile)),
            const SizedBox(height: 32),
            // Timeline réactive
            Obx(() => _buildTimeline(isMobile)),
            const SizedBox(height: 32),
            // Carte reconciliation
            Obx(() => _buildReconciliationCard(isMobile)),
            const SizedBox(height: 32),
            // Clôtures à valider
            Obx(() => _buildCloturesSection(isMobile)),
            const SizedBox(height: 32),
            // Tables réactives
            Obx(() => _buildTables(isMobile)),
            const SizedBox(height: 32),
            // Anomalies réactives
            Obx(() => _buildAnomalies()),
            const SizedBox(height: 40),
            _buildFooterNote()
          ],
        ),
      );
    });
  }

  final Map<String, TextEditingController> _cashControllers = {};

  Widget _buildCloturesSection(bool isMobile) {
    final cls = espaceCtrl.clotures
        .where((c) => c.statut == ClotureStatut.en_attente)
        .toList();
    if (cls.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.flag_circle, color: Color(0xFF0EA5E9)),
              SizedBox(width: 8),
              Text('Clôtures à valider',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ...cls.map((c) => _buildClotureCard(c, isMobile)),
        ],
      ),
    );
  }

  Widget _buildClotureCard(CaisseCloture c, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${c.commercialNom} — ${c.prelevementId}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.black87)),
              Text(DateFormat('dd/MM HH:mm').format(c.dateCreation),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _chip('Ventes', _fmt(c.totalVentes), Colors.green.shade600),
              _chip('Payés', _fmt(c.totalPayes), Colors.teal.shade600),
              _chip('Crédits', _fmt(c.totalCredits), Colors.orange.shade700),
              _chip('Restitutions', _fmt(c.totalRestitutions),
                  Colors.blueGrey.shade600),
              _chip('Pertes', _fmt(c.totalPertes), Colors.red.shade700),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.verified),
              label: const Text('Valider la clôture'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _validerCloture(c),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Future<void> _validerCloture(CaisseCloture c) async {
    final site = espaceCtrl.effectiveSite;
    final user = Get.find<UserSession>();
    try {
      await VenteService().validerCloture(
        site: site,
        clotureId: c.id,
        validatorId: user.email ?? 'unknown',
      );
      Get.snackbar(
          'Clôture validée', 'La clôture de ${c.commercialNom} a été validée.');
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de valider: $e');
    }
  }

  Widget _buildReconciliationCard(bool isMobile) {
    final lignes = caisseCtrl.reconciliationLines;
    if (lignes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ],
        ),
        child: Row(children: const [
          Icon(Icons.receipt_long, color: Colors.blueGrey),
          SizedBox(width: 12),
          Text('Aucune donnée de reconciliation sur la période'),
        ]),
      );
    }

    double totalTheo = 0, totalRecu = 0, totalEcart = 0;
    for (final l in lignes) {
      totalTheo += l.cashTheorique;
      totalRecu += l.cashRecu;
      totalEcart += l.ecart;
    }

    Widget headerRow() => Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF0369A1),
          ),
          child: Row(children: const [
            Expanded(
                flex: 2,
                child: Text('Commercial',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold))),
            Expanded(
                child: Text('CA Brut',
                    style: TextStyle(color: Colors.white, fontSize: 12))),
            Expanded(
                child: Text('Crédits',
                    style: TextStyle(color: Colors.white, fontSize: 12))),
            Expanded(
                child: Text('Théorique',
                    style: TextStyle(color: Colors.white, fontSize: 12))),
            Expanded(
                child: Text('Reçu',
                    style: TextStyle(color: Colors.white, fontSize: 12))),
            Expanded(
                child: Text('Écart',
                    style: TextStyle(color: Colors.white, fontSize: 12))),
            SizedBox(width: 40),
          ]),
        );

    Widget lineRow(CaisseReconciliationLine l) {
      final ctrl = _cashControllers.putIfAbsent(
          l.commercialId,
          () => TextEditingController(
              text: l.cashRecu == 0 ? '' : l.cashRecu.toStringAsFixed(0)));
      final ecartColor = l.ecart.abs() < 1
          ? Colors.green
          : (l.ecart > 0 ? Colors.orange : Colors.red);
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [
          Expanded(
              flex: 2,
              child: Text(l.commercialNom,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(
              child:
                  Text(_fmt(l.caBrut), style: const TextStyle(fontSize: 12))),
          Expanded(
              child:
                  Text(_fmt(l.credit), style: const TextStyle(fontSize: 12))),
          Expanded(
              child: Text(_fmt(l.cashTheorique),
                  style: const TextStyle(fontSize: 12))),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Reçu',
                  border: OutlineInputBorder()),
              onSubmitted: (v) {
                final parsed = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                caisseCtrl.setCashRecu(l.commercialId, parsed);
              },
            ),
          ),
          Expanded(
              child: Text(
            l.ecart.toStringAsFixed(0),
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: ecartColor),
          )),
          IconButton(
            tooltip: 'Valider ligne',
            icon: const Icon(Icons.check_circle, color: Colors.teal),
            onPressed: () {
              final parsed =
                  double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0;
              caisseCtrl.setCashRecu(l.commercialId, parsed);
            },
          )
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 10,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.receipt_long, color: Color(0xFF0369A1)),
          SizedBox(width: 12),
          Text('Reconciliation Encaissements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        headerRow(),
        ...lignes.map(lineRow),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.grey.shade100,
          ),
          child: Row(children: [
            const Expanded(
                flex: 2,
                child: Text('TOTAL',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(
                child: Text(_fmt(totalTheo + (totalRecu - totalRecu)),
                    style: const TextStyle(fontSize: 12))),
            const Expanded(child: SizedBox()),
            Expanded(
                child: Text(_fmt(totalTheo),
                    style: const TextStyle(fontSize: 12))),
            Expanded(
                child: Text(_fmt(totalRecu),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600))),
            Expanded(
                child: Text(totalEcart.toStringAsFixed(0),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: totalEcart.abs() < 1
                            ? Colors.green
                            : (totalEcart > 0 ? Colors.orange : Colors.red)))),
            const SizedBox(width: 40),
          ]),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _exportBonCaisse,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0369A1),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
            icon: const Icon(Icons.download),
            label: const Text('Générer Bon de Caisse'),
          ),
        )
      ]),
    );
  }

  Future<void> _exportBonCaisse() async {
    // Construction simple CSV à partir des lignes
    final buf = StringBuffer();
    buf.writeln(
        'Commercial;CABrut;Credit;CreditRembourse;CashTheo;CashRecu;Ecart');
    for (final l in caisseCtrl.reconciliationLines) {
      buf.writeln(
          '${l.commercialNom};${l.caBrut.toStringAsFixed(0)};${l.credit.toStringAsFixed(0)};${l.creditRembourse.toStringAsFixed(0)};${l.cashTheorique.toStringAsFixed(0)};${l.cashRecu.toStringAsFixed(0)};${l.ecart.toStringAsFixed(0)}');
    }
    final totalEcart =
        caisseCtrl.reconciliationLines.fold<double>(0, (s, l) => s + l.ecart);
    buf.writeln('TOTAL;;;;; ;${totalEcart.toStringAsFixed(0)}');
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bon de caisse copié dans le presse-papiers')));
    }
  }

  Widget _maybeLoadingBanner() {
    final loading = espaceCtrl.isLoading.value;
    if (!loading) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withOpacity(.2)),
      ),
      child: Row(children: [
        const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2.4)),
        const SizedBox(width: 12),
        const Text('Chargement des données commerciales...',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final p = caisseCtrl.periode.value;
    final fmt = DateFormat('dd/MM/yyyy');
    final s = fmt.format(p.start);
    final e = fmt.format(p.end);
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF0EA5E9).withOpacity(.28),
                blurRadius: 18,
                offset: const Offset(0, 8))
          ]),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(.2),
              borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.account_balance_wallet,
              color: Colors.white, size: 34),
        ),
        const SizedBox(width: 20),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Synthèse Caisse',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Période: $s → $e',
              style: TextStyle(
                  color: Colors.white.withOpacity(.9),
                  fontSize: isMobile ? 12 : 14)),
        ])),
        if (!isMobile) _buildCommercialFilter()
      ]),
    );
  }

  Widget _buildCommercialFilter() {
    final allCommercials =
        espaceCtrl.ventes.map((v) => v.commercialId).toSet().toList();
    allCommercials.sort();
    return Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius: BorderRadius.circular(20)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: const Color(0xFF0369A1),
              value: caisseCtrl.commercialFiltre.value.isEmpty
                  ? null
                  : caisseCtrl.commercialFiltre.value,
              hint: const Text('Tous', style: TextStyle(color: Colors.white)),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: [
                const DropdownMenuItem(
                    value: '',
                    child: Text('Tous', style: TextStyle(color: Colors.white))),
                ...allCommercials.map((c) => DropdownMenuItem(
                    value: c,
                    child:
                        Text(c, style: const TextStyle(color: Colors.white))))
              ],
              onChanged: (v) => caisseCtrl.setCommercial(v ?? ''),
            ),
          ),
        ));
  }

  Widget _buildKpiGrid(bool isMobile) {
    final items = [
      _kpiCard('CA Brut', caisseCtrl.caBrut.value, Colors.indigo,
          icon: Icons.trending_up),
      _kpiCard('CA Net', caisseCtrl.caNet.value, Colors.blue,
          icon: Icons.payments),
      _kpiCard('Crédits', caisseCtrl.creditAttente.value, Colors.orange,
          icon: Icons.credit_card),
      _kpiCard('Crédits Remb.', caisseCtrl.creditRembourse.value, Colors.teal,
          icon: Icons.switch_account),
      _kpiCard(
          'Restitutions', caisseCtrl.valeurRestitutions.value, Colors.purple,
          icon: Icons.undo),
      _kpiCard('Pertes', caisseCtrl.valeurPertes.value, Colors.red,
          icon: Icons.warning),
      _kpiCard('% Restitution', caisseCtrl.tauxRestitution.value,
          Colors.purpleAccent,
          isPercent: true, icon: Icons.pie_chart),
      _kpiCard('% Pertes', caisseCtrl.tauxPertes.value, Colors.deepOrange,
          isPercent: true, icon: Icons.percent),
      _kpiCard('Cash Théorique', caisseCtrl.cashTheorique.value, Colors.green,
          icon: Icons.account_balance_wallet),
      _kpiCard('Efficacité', caisseCtrl.efficacite.value, Colors.cyan,
          isPercent: true, icon: Icons.speed),
      _kpiCard('CA Espèce', caisseCtrl.caEspece.value, Colors.brown,
          icon: Icons.payments_outlined),
      _kpiCard('CA Mobile', caisseCtrl.caMobile.value, Colors.lightBlue,
          icon: Icons.smartphone),
      _kpiCard('CA Autres', caisseCtrl.caAutres.value, Colors.grey,
          icon: Icons.layers),
      _kpiCard('% Espèce', caisseCtrl.pctEspece.value, Colors.brown.shade300,
          isPercent: true, icon: Icons.donut_small),
      _kpiCard('% Mobile', caisseCtrl.pctMobile.value, Colors.lightBlueAccent,
          isPercent: true, icon: Icons.donut_small),
      _kpiCard('% Autres', caisseCtrl.pctAutres.value, Colors.grey.shade600,
          isPercent: true, icon: Icons.donut_small),
    ];
    final crossAxis = isMobile ? 2 : 5;
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxis,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: isMobile ? 1.05 : 1.3,
      ),
      itemBuilder: (_, i) => items[i],
    );
  }

  Widget _kpiCard(String label, double value, Color color,
      {bool isPercent = false, IconData icon = Icons.data_usage}) {
    final display = isPercent ? '${value.toStringAsFixed(1)}%' : _fmt(value);
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ],
          border: Border.all(color: color.withOpacity(.15))),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(.12),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 22)),
        const Spacer(),
        Text(display,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ]),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  Widget _buildTimeline(bool isMobile) {
    final points = caisseCtrl.timeline;
    if (points.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5))
            ]),
        child: Row(children: [
          const Icon(Icons.timeline, color: Colors.blueGrey),
          const SizedBox(width: 12),
          const Text('Aucune vente sur la période',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
      );
    }

    final max =
        points.map((e) => e.valeur).fold<double>(0, (m, v) => v > m ? v : m);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(.12),
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.timeline, color: Colors.blue)),
          const SizedBox(width: 12),
          const Text('Evolution CA',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 18),
        SizedBox(
          height: 140,
          child: CustomPaint(
            painter: _SparklinePainter(points.map((p) => p.valeur).toList(),
                color: Colors.blue, max: max),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: points
                  .map((p) => Expanded(
                      child: Center(
                          child: Text(p.label,
                              style: const TextStyle(fontSize: 10)))))
                  .toList(),
            ),
          ),
        )
      ]),
    );
  }

  Widget _buildTables(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Ventes'),
        _tableVentes(isMobile),
        const SizedBox(height: 28),
        _sectionTitle('Crédits en attente'),
        _tableCredits(isMobile),
        const SizedBox(height: 28),
        _sectionTitle('Restitutions'),
        _tableRestitutions(isMobile),
        const SizedBox(height: 28),
        _sectionTitle('Pertes'),
        _tablePertes(isMobile),
        const SizedBox(height: 28),
        _sectionTitle('Top Produits'),
        _tableTopProduits(isMobile),
      ],
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(t,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800)),
    );
  }

  Widget _tableVentes(bool isMobile) {
    final ventes = caisseCtrl.ventesFiltrees;
    if (ventes.isEmpty) return _emptyCard('Aucune vente');
    return _wrapCard(
      child: Column(
          children: ventes.take(15).map((v) {
        final produits =
            v.produits.fold<int>(0, (s, p) => s + p.quantiteVendue);
        return ListTile(
          dense: isMobile,
          leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(.15),
              child: const Icon(Icons.point_of_sale,
                  color: Colors.blue, size: 18)),
          title: Text(v.clientNom.isEmpty ? 'Client Libre' : v.clientNom,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
              '${produits}p • ${DateFormat('dd/MM HH:mm').format(v.dateVente)}'),
          trailing: Text(_money(v.montantTotal),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          onTap: () {},
        );
      }).toList()),
    );
  }

  Widget _tableCredits(bool isMobile) {
    final ventes = caisseCtrl.ventesFiltrees
        .where((v) => v.statut == StatutVente.creditEnAttente)
        .toList();
    if (ventes.isEmpty) return _emptyCard('Aucun crédit en attente');
    return _wrapCard(
      child: Column(
          children: ventes.take(15).map((v) {
        return ListTile(
          dense: isMobile,
          leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(.15),
              child: const Icon(Icons.credit_card,
                  color: Colors.orange, size: 18)),
          title: Text(v.clientNom.isEmpty ? 'Client Libre' : v.clientNom,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(DateFormat('dd/MM HH:mm').format(v.dateVente)),
          trailing: Text(_money(v.montantTotal),
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
        );
      }).toList()),
    );
  }

  Widget _tableRestitutions(bool isMobile) {
    final restits = caisseCtrl.restitutionsFiltrees;
    if (restits.isEmpty) return _emptyCard('Aucune restitution');
    return _wrapCard(
      child: Column(
          children: restits.take(15).map((r) {
        final produits =
            r.produits.fold<int>(0, (s, p) => s + p.quantiteRestituee);
        return ListTile(
          dense: isMobile,
          leading: CircleAvatar(
              backgroundColor: Colors.purple.withOpacity(.15),
              child: const Icon(Icons.undo, color: Colors.purple, size: 18)),
          title: Text('${r.commercialNom}'),
          subtitle: Text(
              '${produits}p • ${DateFormat('dd/MM HH:mm').format(r.dateRestitution)}'),
          trailing: Text(_money(r.valeurTotale),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      }).toList()),
    );
  }

  Widget _tablePertes(bool isMobile) {
    final pertes = caisseCtrl.pertesFiltrees;
    if (pertes.isEmpty) return _emptyCard('Aucune perte');
    return _wrapCard(
      child: Column(
          children: pertes.take(15).map((p) {
        final produits =
            p.produits.fold<int>(0, (s, x) => s + x.quantitePerdue);
        return ListTile(
          dense: isMobile,
          leading: CircleAvatar(
              backgroundColor: Colors.red.withOpacity(.15),
              child: const Icon(Icons.warning, color: Colors.red, size: 18)),
          title: Text(p.commercialNom),
          subtitle: Text(
              '${produits}p • ${DateFormat('dd/MM HH:mm').format(p.datePerte)}'),
          trailing: Text(_money(p.valeurTotale),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.redAccent)),
        );
      }).toList()),
    );
  }

  Widget _tableTopProduits(bool isMobile) {
    final top = caisseCtrl.topProduits;
    if (top.isEmpty) return _emptyCard('Aucun produit');
    return _wrapCard(
        child: Column(
            children: top.map((e) {
      return ListTile(
        dense: isMobile,
        leading: CircleAvatar(
            backgroundColor: Colors.teal.withOpacity(.15),
            child: const Icon(Icons.inventory_2, color: Colors.teal, size: 18)),
        title: Text(e.key),
        subtitle: Text('${e.value.quantite} vendus'),
        trailing: Text(_money(e.value.montant),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      );
    }).toList()));
  }

  Widget _wrapCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ]),
      padding: const EdgeInsets.all(8),
      child: child,
    );
  }

  Widget _emptyCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ]),
      child: Row(children: [
        const Icon(Icons.info_outline, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
            child: Text(msg, style: TextStyle(color: Colors.grey.shade600)))
      ]),
    );
  }

  Widget _buildAnomalies() {
    final list = caisseCtrl.anomalies;
    if (list.isEmpty) return Container();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(.15),
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.warning_amber, color: Colors.amber)),
          const SizedBox(width: 12),
          const Text('Anomalies Détectées',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
        ]),
        const SizedBox(height: 12),
        ...list.map((a) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              const Icon(Icons.circle, size: 8, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(child: Text(a, style: const TextStyle(fontSize: 13)))
            ])))
      ]),
    );
  }

  Widget _buildFooterNote() {
    return Center(
        child: Text('© ${DateTime.now().year} Synthèse Caisse - Version MVP',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)));
  }

  String _money(double v) {
    final f = NumberFormat.currency(
        symbol: 'FCFA ', decimalDigits: 0, locale: 'fr_FR');
    return f.format(v);
  }

  void _exportCsv() {
    final csv = caisseCtrl.exportCsv();
    // Utilisation de Clipboard pour copie rapide
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Export CSV copié dans le presse-papiers'),
        duration: Duration(seconds: 2)));
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double max;
  _SparklinePainter(this.values, {required this.color, required this.max});
  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || max <= 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final stepX = size.width / (values.length - 1);
    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height - (values[i] / max) * size.height;
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    // Remplissage léger
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
              colors: [color.withOpacity(.22), color.withOpacity(0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter)
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values || old.color != color || old.max != max;
}
