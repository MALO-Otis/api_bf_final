import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SuppressionStockFormPage extends StatefulWidget {
  final Map<String, dynamic> lotConditionnement;
  final Map<String, int> stockRestantParType;
  final VoidCallback? onSuppression;

  const SuppressionStockFormPage({
    super.key,
    required this.lotConditionnement,
    required this.stockRestantParType,
    this.onSuppression,
  });

  @override
  State<SuppressionStockFormPage> createState() =>
      _SuppressionStockFormPageState();
}

class _SuppressionStockFormPageState extends State<SuppressionStockFormPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _date;
  String? _motif;
  Map<String, TextEditingController> nbPotsController = {};
  Map<String, bool> emballageSelection = {};

  double quantiteTotale = 0;
  List<Map<String, dynamic>> _emballages = [];

  @override
  void initState() {
    super.initState();
    for (final t in widget.stockRestantParType.keys) {
      nbPotsController[t] = TextEditingController();
      emballageSelection[t] = false;
      nbPotsController[t]!.addListener(_recalc);
    }
  }

  void _recalc() {
    double qte = 0;
    _emballages = [];
    widget.stockRestantParType.forEach((type, stockRestant) {
      if (!emballageSelection[type]!) return;
      final n = int.tryParse(nbPotsController[type]?.text ?? '') ?? 0;
      final contenance = _findContenanceKg(type);
      if (n > 0) {
        qte += n * contenance;
        _emballages.add({
          "type": type,
          "nombre": n,
          "contenanceKg": contenance,
        });
      }
    });
    setState(() {
      quantiteTotale = qte;
    });
  }

  double _findContenanceKg(String type) {
    final emb = widget.lotConditionnement['emballages'] as List<dynamic>? ?? [];
    for (final e in emb) {
      if (e['type'] == type) return (e['contenanceKg'] ?? 0.0).toDouble();
    }
    // fallback
    switch (type) {
      case "1.5Kg":
        return 1.5;
      case "1Kg":
        return 1.0;
      case "720g":
        return 0.72;
      case "500g":
        return 0.5;
      case "250g":
        return 0.25;
      case "Pot alvéoles 30g":
        return 0.03;
      case "Stick 20g":
        return 0.02;
      case "7kg":
        return 7.0;
      default:
        return 0.0;
    }
  }

  bool get isValidEmballages {
    for (final type in widget.stockRestantParType.keys) {
      if (emballageSelection[type] == true) {
        final txt = nbPotsController[type]?.text ?? '';
        final n = int.tryParse(txt);
        if (n != null &&
            n > 0 &&
            n <= (widget.stockRestantParType[type] ?? 0)) {
          return true;
        }
      }
    }
    return false;
  }

  bool get isFormValid {
    return _formKey.currentState?.validate() == true &&
        isValidEmballages &&
        _date != null &&
        _motif != null &&
        _motif!.trim().isNotEmpty;
  }

  Future<void> _saveSuppression() async {
    if (!isFormValid) {
      Get.snackbar("Erreur", "Veuillez remplir tous les champs obligatoires.");
      return;
    }
    // Vérification des quantités
    for (final type in widget.stockRestantParType.keys) {
      final n = int.tryParse(nbPotsController[type]?.text ?? '') ?? 0;
      if (n > (widget.stockRestantParType[type] ?? 0)) {
        Get.snackbar("Erreur",
            "Vous ne pouvez pas supprimer plus de ${widget.stockRestantParType[type] ?? 0} pots pour $type.");
        return;
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';

    // Historique suppression (une collection "suppression_stock" par lot)
    final suppressionDoc = await FirebaseFirestore.instance
        .collection('conditionnement')
        .doc(widget.lotConditionnement['id'])
        .collection('suppression_stock')
        .add({
      "dateSuppression": _date,
      "motif": _motif,
      "utilisateurId": userId,
      "utilisateurNom": user?.displayName ?? '',
      "emballagesSupprimes": _emballages,
      "quantiteTotaleSupprimee": quantiteTotale,
      "createdAt": FieldValue.serverTimestamp(),
    });

    // Met à jour le stock restant sur le lot (décrémente les quantités/pots)
    final lotRef = FirebaseFirestore.instance
        .collection('conditionnement')
        .doc(widget.lotConditionnement['id']);

    final lotSnap = await lotRef.get();
    if (lotSnap.exists) {
      final data = lotSnap.data()!;
      final emballages = (data['emballages'] as List<dynamic>?) ?? [];
      for (final emb in _emballages) {
        final idx = emballages.indexWhere((e) => e['type'] == emb['type']);
        if (idx != -1) {
          emballages[idx]['nombre'] =
              (emballages[idx]['nombre'] ?? 0) - (emb['nombre'] ?? 0);
          if (emballages[idx]['nombre'] < 0) emballages[idx]['nombre'] = 0;
        }
      }
      await lotRef.update({'emballages': emballages});
    }

    Get.snackbar("Succès", "Suppression enregistrée !");
    if (widget.onSuppression != null) widget.onSuppression!();
    Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Suppression de stock"),
        backgroundColor: Colors.red[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.red),
                title: Text(
                  _date != null
                      ? "Date : ${_date!.day}/${_date!.month}/${_date!.year}"
                      : "Sélectionner la date de suppression",
                  style: TextStyle(
                      color: _date == null ? Colors.red : Colors.black),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_calendar, color: Colors.red),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
              ),
              if (_date == null)
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, bottom: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("La date est obligatoire.",
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ),
              const Divider(height: 25),
              ListTile(
                leading: const Icon(Icons.info, color: Colors.red),
                title: TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Motif de suppression (obligatoire)",
                  ),
                  onChanged: (v) => setState(() => _motif = v),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Obligatoire" : null,
                ),
              ),
              const Divider(height: 25),
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: const [
                    Icon(Icons.inventory, color: Colors.amber),
                    SizedBox(width: 8),
                    Text("Type d'emballage à supprimer",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ...widget.stockRestantParType.keys.map((type) {
                final selected = emballageSelection[type] ?? false;
                final stockRestant = widget.stockRestantParType[type] ?? 0;
                return Card(
                  color: selected ? Colors.red[50] : Colors.grey[100],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
                    child: Row(
                      children: [
                        Switch(
                          value: selected,
                          activeColor: Colors.red[700],
                          onChanged: (v) {
                            setState(() {
                              emballageSelection[type] = v;
                              if (!v) {
                                nbPotsController[type]?.clear();
                              } else if ((nbPotsController[type]?.text ?? "")
                                  .isEmpty) {
                                nbPotsController[type]?.text = "1";
                              }
                              _recalc();
                            });
                          },
                        ),
                        Icon(Icons.delete, color: Colors.red[400], size: 27),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(type,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 150,
                          child: TextFormField(
                            enabled: selected,
                            controller: nbPotsController[type],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Nb",
                              isDense: true,
                              prefixIcon:
                                  const Icon(Icons.delete_forever, size: 18),
                              suffixText: "/$stockRestant",
                            ),
                            validator: (v) {
                              if (!selected) return null;
                              if (v == null || v.isEmpty) return "!";
                              final n = int.tryParse(v);
                              if (n == null || n <= 0) return "!";
                              if (n > stockRestant) {
                                return "Max: $stockRestant";
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const Divider(height: 30),
              Row(
                children: [
                  Icon(Icons.remove_circle, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Text("Quantité totale supprimée : ",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("${quantiteTotale.toStringAsFixed(2)} kg"),
                ],
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text("Valider la suppression"),
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isFormValid ? Colors.red[700] : Colors.grey,
                    minimumSize: const Size(220, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    )),
                onPressed: isFormValid ? _saveSuppression : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
