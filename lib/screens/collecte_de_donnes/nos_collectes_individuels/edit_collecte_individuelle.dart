import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/collecte_models.dart';
import '../../../data/services/stats_achats_individuels_service.dart';

class EditCollecteIndividuellePage extends StatefulWidget {
  final String documentPath; // ex: Sites/{site}/nos_achats_individuels/{id}
  const EditCollecteIndividuellePage({super.key, required this.documentPath});

  @override
  State<EditCollecteIndividuellePage> createState() =>
      _EditCollecteIndividuellePageState();
}

class _EditCollecteIndividuellePageState
    extends State<EditCollecteIndividuellePage> {
  bool _loading = true;
  bool _saving = false;

  late DocumentReference<Map<String, dynamic>> _docRef;
  late String _site;

  String _id = '';
  DateTime _dateAchat = DateTime.now();
  String _periodeCollecte = '';
  final TextEditingController _observationsCtrl = TextEditingController();
  List<ContenantModel> _contenants = [];

  // Snapshot initial pour calculer les deltas
  double _oldPoids = 0;
  double _oldMontant = 0;
  int _oldBidons = 0;
  int _oldPots = 0;
  String _originalMonthKey = '';

  @override
  void initState() {
    super.initState();
    _docRef = FirebaseFirestore.instance.doc(widget.documentPath);
    final parts = widget.documentPath.split('/');
    // ['Sites', site, 'nos_achats_individuels', id]
    _site = parts.length >= 4 ? parts[1] : 'DefaultSite';
    _load();
  }

  Future<void> _load() async {
    try {
      final snap = await _docRef.get();
      final data = snap.data() ?? {};
      _id = snap.id;
      final ts = (data['date_achat'] as Timestamp?) ??
          data['created_at'] as Timestamp?;
      _dateAchat = ts?.toDate() ?? DateTime.now();
      _originalMonthKey =
          '${_dateAchat.year.toString().padLeft(4, '0')}-${_dateAchat.month.toString().padLeft(2, '0')}';
      _periodeCollecte = data['periode_collecte']?.toString() ?? '';
      _observationsCtrl.text = data['observations']?.toString() ?? '';

      final rawConts = (data['contenants'] as List<dynamic>? ?? const []);
      _contenants = rawConts
          .map(
              (m) => ContenantModel.fromFirestore(Map<String, dynamic>.from(m)))
          .toList();

      // Old counters
      _oldPoids = (data['poids_total'] ?? 0).toDouble();
      _oldMontant = (data['montant_total'] ?? 0).toDouble();
      for (final c in _contenants) {
        if (c.typeContenant == 'Bidon') _oldBidons++;
        if (c.typeContenant == 'Pot') _oldPots++;
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Chargement: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _observationsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateAchat,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _dateAchat = picked);
  }

  void _addContenant() {
    setState(() {
      final contenantId =
          'C${(_contenants.length + 1).toString().padLeft(3, '0')}_individuel';
      _contenants.add(ContenantModel(
        id: contenantId, // 🆕 ID avec suffixe individuel
        typeRuche: '',
        typeMiel: 'Liquide',
        typeContenant: 'Bidon',
        quantite: 0,
        prixUnitaire: 0,
        predominanceFlorale: '',
      ));
    });
  }

  void _removeContenant(int i) {
    setState(() => _contenants.removeAt(i));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // Recalcul totaux
      double poidsTotal = 0;
      double montantTotal = 0;
      int bidons = 0;
      int pots = 0;
      final mielTypes = <String>{};

      for (final c in _contenants) {
        poidsTotal += c.quantite;
        montantTotal += c.montantTotal;
        if (c.typeContenant == 'Bidon') bidons++;
        if (c.typeContenant == 'Pot') pots++;
        if (c.typeMiel.isNotEmpty) mielTypes.add(c.typeMiel);
      }

      final monthKey =
          '${_dateAchat.year.toString().padLeft(4, '0')}-${_dateAchat.month.toString().padLeft(2, '0')}';

      // Mise à jour du document
      await _docRef.update({
        'date_achat': Timestamp.fromDate(_dateAchat),
        'periode_collecte': _periodeCollecte,
        'observations': _observationsCtrl.text.trim(),
        'contenants': _contenants.map((c) => c.toFirestore()).toList(),
        'poids_total': poidsTotal,
        'montant_total': montantTotal,
        'nombre_contenants': _contenants.length,
        'updated_at': Timestamp.now(),
      });

      // Appliquer delta sur site_infos
      final newMonthKey = monthKey;
      if (_originalMonthKey.isNotEmpty && _originalMonthKey != newMonthKey) {
        // retirer des compteurs de l'ancien mois
        await StatsAchatsIndividuelsService.applySiteInfosDelta(
          site: _site,
          monthKey: _originalMonthKey,
          poidsDelta: -_oldPoids,
          montantDelta: -_oldMontant,
          deltaBidon: -_oldBidons,
          deltaPot: -_oldPots,
        );
        // ajouter au nouveau mois
        await StatsAchatsIndividuelsService.applySiteInfosDelta(
          site: _site,
          monthKey: newMonthKey,
          poidsDelta: poidsTotal,
          montantDelta: montantTotal,
          deltaBidon: bidons,
          deltaPot: pots,
          mielTypesToUnion: mielTypes.toList(),
        );
      } else {
        await StatsAchatsIndividuelsService.applySiteInfosDelta(
          site: _site,
          monthKey: newMonthKey,
          poidsDelta: poidsTotal - _oldPoids,
          montantDelta: montantTotal - _oldMontant,
          deltaBidon: bidons - _oldBidons,
          deltaPot: pots - _oldPots,
          mielTypesToUnion: mielTypes.toList(),
        );
      }

      // Recalcul complet des stats avancées
      await StatsAchatsIndividuelsService.regenerateAdvancedStats(_site);

      Get.snackbar('Succès', 'Collecte mise à jour avec succès',
          backgroundColor: Colors.green, colorText: Colors.white);
      Navigator.of(context).pop();
    } catch (e) {
      Get.snackbar('Erreur', e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modifier collecte individuelle')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isSmall = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange[600],
        title: const Text('Modifier collecte individuelle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saving ? null : _save,
            tooltip: 'Enregistrer',
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _addContenant,
        backgroundColor: Colors.orange[600],
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un contenant'),
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date d\'achat'),
                subtitle: Text(
                    '${_dateAchat.day.toString().padLeft(2, '0')}/${_dateAchat.month.toString().padLeft(2, '0')}/${_dateAchat.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Période de collecte (JJ/MM/AAAA)',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: _periodeCollecte),
                onChanged: (v) => _periodeCollecte = v.trim(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _observationsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observations',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              Text('Contenants',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),

              ..._contenants.asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: c.typeContenant.isEmpty
                                    ? 'Bidon'
                                    : c.typeContenant,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Bidon', child: Text('Bidon')),
                                  DropdownMenuItem(
                                      value: 'Pot', child: Text('Pot')),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _contenants[i] =
                                      c.copyWith(typeContenant: v));
                                },
                                decoration: const InputDecoration(
                                    labelText: 'Type de contenant'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value:
                                    c.typeMiel.isEmpty ? 'Liquide' : c.typeMiel,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Liquide', child: Text('Liquide')),
                                  DropdownMenuItem(
                                      value: 'Brute', child: Text('Brute')),
                                  DropdownMenuItem(
                                      value: 'Cire', child: Text('Cire')),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() =>
                                      _contenants[i] = c.copyWith(typeMiel: v));
                                },
                                decoration: const InputDecoration(
                                    labelText: 'Type de miel'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: c.quantite.toString(),
                                decoration: const InputDecoration(
                                    labelText: 'Quantité (kg)'),
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  final q = double.tryParse(v) ?? 0;
                                  setState(() =>
                                      _contenants[i] = c.copyWith(quantite: q));
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: c.prixUnitaire.toString(),
                                decoration: const InputDecoration(
                                    labelText: 'Prix unitaire (FCFA/kg)'),
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  final pu = double.tryParse(v) ?? 0;
                                  setState(() => _contenants[i] =
                                      c.copyWith(prixUnitaire: pu));
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _removeContenant(i),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Supprimer',
                                style: TextStyle(color: Colors.red)),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
