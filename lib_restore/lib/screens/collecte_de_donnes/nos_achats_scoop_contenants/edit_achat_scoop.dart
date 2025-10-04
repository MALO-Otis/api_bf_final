import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/services/collecte_protection_service.dart';

class EditAchatScoopPage extends StatefulWidget {
  final String
      documentPath; // ex: Sites/{site}/nos_achats_scoop_contenants/{id}

  const EditAchatScoopPage({
    Key? key,
    required this.documentPath,
  }) : super(key: key);

  @override
  State<EditAchatScoopPage> createState() => _EditAchatScoopPageState();
}

class _EditAchatScoopPageState extends State<EditAchatScoopPage> {
  bool _loading = true;
  bool _saving = false;

  late DocumentReference<Map<String, dynamic>> _docRef;
  late String _site;

  // Données de la collecte
  Map<String, dynamic> _collecteData = {};
  List<Map<String, dynamic>> _contenants = [];

  // Contrôleurs
  final TextEditingController _observationsCtrl = TextEditingController();
  final TextEditingController _periodeCtrl = TextEditingController();

  // Variables de formulaire
  DateTime _dateAchat = DateTime.now();
  String _scoopId = '';
  String _scoopNom = '';
  String _collecteurId = '';
  String _collecteurNom = '';
  String _statut = 'collecte_terminee';

  // Options
  final List<String> _typesContenant = ['Bidon', 'Fût', 'Seau', 'Pot'];
  final List<String> _typesMiel = ['Liquide', 'Brute', 'Cire'];
  final List<String> _statutOptions = [
    'en_cours',
    'collecte_terminee',
    'valide',
    'rejete'
  ];

  @override
  void initState() {
    super.initState();
    _docRef = FirebaseFirestore.instance.doc(widget.documentPath);
    final parts = widget.documentPath.split('/');
    _site = parts.length >= 4 ? parts[1] : 'DefaultSite';
    _loadCollecte();
  }

  @override
  void dispose() {
    _observationsCtrl.dispose();
    _periodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCollecte() async {
    try {
      setState(() => _loading = true);

      final doc = await _docRef.get();
      if (!doc.exists) {
        Get.snackbar('Erreur', 'Collecte non trouvée');
        Navigator.of(context).pop();
        return;
      }

      _collecteData = doc.data() ?? {};

      // Charger les données selon la vraie structure
      _dateAchat = (_collecteData['date_achat'] as Timestamp?)?.toDate() ??
          (_collecteData['created_at'] as Timestamp?)?.toDate() ??
          DateTime.now();

      _scoopId = _collecteData['scoop_id']?.toString() ?? '';
      _scoopNom = _collecteData['scoop_nom']?.toString() ?? '';
      _collecteurId = _collecteData['collecteur_id']?.toString() ?? '';
      _collecteurNom = _collecteData['collecteur_nom']?.toString() ?? '';
      _statut = _collecteData['statut']?.toString() ?? 'collecte_terminee';

      _observationsCtrl.text = _collecteData['observations']?.toString() ?? '';
      _periodeCtrl.text = _collecteData['periode_collecte']?.toString() ?? '';

      // Charger les contenants avec la vraie structure
      final contenantsData =
          _collecteData['contenants'] as List<dynamic>? ?? [];
      _contenants =
          contenantsData.map((c) => Map<String, dynamic>.from(c)).toList();

      print(
          '🔄 EDIT SCOOP: Collecte chargée avec ${_contenants.length} contenants');
    } catch (e) {
      print('❌ EDIT SCOOP: Erreur chargement: $e');
      Get.snackbar('Erreur', 'Erreur lors du chargement: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveCollecte() async {
    try {
      setState(() => _saving = true);

      // Vérifier la protection avant de sauvegarder
      final protectionStatus =
          await CollecteProtectionService.checkCollecteModifiable(
              _collecteData);
      if (!protectionStatus.isModifiable) {
        Get.snackbar(
          'Modification impossible',
          protectionStatus.userMessage,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Calculer les totaux
      double poidsTotal = 0;
      double montantTotal = 0;

      for (var contenant in _contenants) {
        final poids = (contenant['poids'] ?? 0).toDouble();
        final prix = (contenant['prix'] ?? 0).toDouble();
        poidsTotal += poids;
        montantTotal += prix;
      }

      // Préparer les données à sauvegarder
      final updateData = {
        'date_achat': Timestamp.fromDate(_dateAchat),
        'scoop_id': _scoopId,
        'scoop_nom': _scoopNom,
        'collecteur_id': _collecteurId,
        'collecteur_nom': _collecteurNom,
        'statut': _statut,
        'observations': _observationsCtrl.text.trim(),
        'periode_collecte': _periodeCtrl.text.trim(),
        'contenants': _contenants,
        'poids_total': poidsTotal,
        'montant_total': montantTotal,
        'nombre_contenants': _contenants.length,
        'site': _site,
        'derniereMiseAJour': Timestamp.now(),
      };

      await _docRef.update(updateData);

      print('✅ EDIT SCOOP: Collecte sauvegardée avec succès');

      Get.snackbar(
        'Succès',
        'Collecte SCOOP mise à jour avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Navigator.of(context).pop();
    } catch (e) {
      print('❌ EDIT SCOOP: Erreur sauvegarde: $e');
      Get.snackbar(
        'Erreur',
        'Erreur lors de la sauvegarde: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  void _addContenant() {
    setState(() {
      final index = _contenants.length + 1;
      final newId =
          'SCO_${_scoopNom.replaceAll(' ', '').toUpperCase()}_${_collecteurNom.replaceAll(' ', '').toUpperCase()}_${DateFormat('yyyyMMdd').format(_dateAchat)}_${index.toString().padLeft(4, '0')}';

      _contenants.add({
        'id': newId,
        'typeContenant': 'Bidon',
        'typeMiel': 'Liquide',
        'poids': 0.0,
        'prix': 0.0,
        'notes': null,
        'couleurCire': null,
        'typeCire': null,
      });
    });
  }

  void _removeContenant(int index) {
    final contenant = _contenants[index];

    // Vérifier si le contenant a été traité
    final controlInfo = contenant['controlInfo'] as Map<String, dynamic>?;
    if (controlInfo != null && controlInfo['isControlled'] == true) {
      Get.snackbar(
        'Suppression impossible',
        'Ce contenant a été contrôlé et ne peut pas être supprimé',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _contenants.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Modification Achat SCOOP'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modification Achat SCOOP'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveCollecte,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations générales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations Générales',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 16),

                    // Date d'achat
                    ListTile(
                      leading:
                          const Icon(Icons.calendar_today, color: Colors.blue),
                      title: const Text('Date d\'achat'),
                      subtitle:
                          Text(DateFormat('dd/MM/yyyy').format(_dateAchat)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dateAchat,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _dateAchat = picked);
                        }
                      },
                    ),

                    const Divider(),

                    // SCOOP
                    TextFormField(
                      initialValue: _scoopNom,
                      decoration: const InputDecoration(
                        labelText: 'Nom SCOOP',
                        prefixIcon: Icon(Icons.group),
                      ),
                      onChanged: (value) => setState(() => _scoopNom = value),
                    ),

                    const SizedBox(height: 16),

                    // Collecteur
                    TextFormField(
                      initialValue: _collecteurNom,
                      decoration: const InputDecoration(
                        labelText: 'Nom Collecteur',
                        prefixIcon: Icon(Icons.person),
                      ),
                      onChanged: (value) =>
                          setState(() => _collecteurNom = value),
                    ),

                    const SizedBox(height: 16),

                    // Statut
                    DropdownButtonFormField<String>(
                      value: _statut,
                      decoration: const InputDecoration(
                        labelText: 'Statut',
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: _statutOptions
                          .map((statut) => DropdownMenuItem(
                                value: statut,
                                child: Text(_getStatutLabel(statut)),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _statut = value ?? _statut),
                    ),

                    const SizedBox(height: 16),

                    // Période de collecte
                    TextFormField(
                      controller: _periodeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Période de collecte',
                        prefixIcon: Icon(Icons.schedule),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Observations
                    TextFormField(
                      controller: _observationsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Observations',
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Section contenants
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Contenants (${_contenants.length})',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _addContenant,
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Liste des contenants
                    ..._contenants.asMap().entries.map((entry) {
                      final index = entry.key;
                      final contenant = entry.value;
                      return _buildContenantCard(index, contenant);
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Bouton sauvegarder
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveCollecte,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Sauvegarde...' : 'Sauvegarder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenantCard(int index, Map<String, dynamic> contenant) {
    final controlInfo = contenant['controlInfo'] as Map<String, dynamic>?;
    final isControlled =
        controlInfo != null && controlInfo['isControlled'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isControlled ? Colors.orange.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du contenant
            Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  color: isControlled ? Colors.orange : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Contenant ${index + 1} - ${contenant['id'] ?? 'ID non défini'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (isControlled) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Contrôlé',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeContenant(index),
                ),
              ],
            ),

            if (isControlled) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ℹ️ Contenant contrôlé par ${controlInfo['controllerName'] ?? 'Contrôleur'}',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Statut: ${controlInfo['conformityStatus'] ?? 'Non spécifié'}',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Champs du contenant
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: contenant['typeContenant']?.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Type contenant',
                      border: OutlineInputBorder(),
                    ),
                    items: _typesContenant
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: isControlled
                        ? null
                        : (value) {
                            setState(() {
                              _contenants[index]['typeContenant'] = value;
                            });
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: contenant['typeMiel']?.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Type miel',
                      border: OutlineInputBorder(),
                    ),
                    items: _typesMiel
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: isControlled
                        ? null
                        : (value) {
                            setState(() {
                              _contenants[index]['typeMiel'] = value;
                            });
                          },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: contenant['poids']?.toString() ?? '0',
                    decoration: const InputDecoration(
                      labelText: 'Poids (kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    readOnly: isControlled,
                    onChanged: (value) {
                      final poids = double.tryParse(value) ?? 0;
                      setState(() {
                        _contenants[index]['poids'] = poids;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: contenant['prix']?.toString() ?? '0',
                    decoration: const InputDecoration(
                      labelText: 'Prix (FCFA)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    readOnly: isControlled,
                    onChanged: (value) {
                      final prix = double.tryParse(value) ?? 0;
                      setState(() {
                        _contenants[index]['prix'] = prix;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextFormField(
              initialValue: contenant['notes']?.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              readOnly: isControlled,
              onChanged: (value) {
                setState(() {
                  _contenants[index]['notes'] = value.isEmpty ? null : value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'en_cours':
        return 'En cours';
      case 'collecte_terminee':
        return 'Collecte terminée';
      case 'valide':
        return 'Validé';
      case 'rejete':
        return 'Rejeté';
      default:
        return statut;
    }
  }
}
