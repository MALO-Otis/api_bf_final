import 'package:apisavana_gestion/screens/commercialisation/prelevement_form.dart';
import 'package:apisavana_gestion/screens/commercialisation/prelevement_magazinier.dart';
import 'package:apisavana_gestion/screens/commercialisation/vente_form.dart';
import 'package:apisavana_gestion/screens/commercialisation/vente_recu.dart';
import 'package:apisavana_gestion/screens/commercialisation/widgets/rapport.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Ajoute cette ligne
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

// Il te faut ces helpers/extension pour `.firstWhereOrNull` etc.
// Ajoute si tu ne les as pas :
extension IterableExt<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class CommercialisationHomePage extends StatefulWidget {
  const CommercialisationHomePage({super.key});

  @override
  State<CommercialisationHomePage> createState() =>
      _CommercialisationHomePageState();
}

class _CommercialisationHomePageState extends State<CommercialisationHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<Tab> myTabs;

  String? _userRole;

  @override
  void initState() {
    super.initState();
    myTabs = [
      const Tab(icon: Icon(Icons.store), text: "Magazinier"),
      const Tab(icon: Icon(Icons.person), text: "Commercial(e)"),
      const Tab(icon: Icon(Icons.attach_money), text: "Caissier"),
      const Tab(
          icon: Icon(Icons.admin_panel_settings),
          text: "Gestionnaire Commercial"),
    ];
    _tabController = TabController(length: myTabs.length, vsync: this);
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance
        .collection('utilisateurs')
        .doc(user.uid)
        .get();
    final data = userDoc.data() ?? {};
    setState(() {
      _userRole = data['role'];
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: "Retour au Dashboard",
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.offAllNamed('/dashboard'),
        ),
        title: const Text("💰 Commercialisation"),
        backgroundColor: Colors.green[700],
        bottom: TabBar(
          controller: _tabController,
          tabs: myTabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MagazinierPage(onPrelevement: () => _tabController.animateTo(1)),
          CommercialPage(),
          CaissierPage(),
          GestionnaireCommercialPage(),
        ],
      ),
    );
  }
}

class MagazinierPage extends StatefulWidget {
  final VoidCallback? onPrelevement;
  const MagazinierPage({super.key, this.onPrelevement});

  @override
  State<MagazinierPage> createState() => _MagazinierPageState();
}

class _MagazinierPageState extends State<MagazinierPage> {
  String? userNom;
  String? userRole;
  String? typeMag;
  String? localiteMag;
  String? userId;
  // Mets-le ici !
  final ValueNotifier<Map<String, String?>> directPrelevementSelection =
      ValueNotifier({});

  @override
  void initState() {
    super.initState();
    _loadUserInfos();
  }

  Future<void> _loadUserInfos() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(currentUser.uid)
          .get();
      final data = userDoc.data() ?? {};
      setState(() {
        userId = currentUser.uid;
        userNom = data['nom']?.toString();
        userRole = data['role']?.toString();
        final magField = data['magazinier'] as Map<String, dynamic>?;
        typeMag = magField?['type']?.toString();
        localiteMag = magField?['localite']?.toString();
      });
    }
  }

  Future<void> approuverRestitutionAutomatique({
    required String prelevementId,
    required Map<String, dynamic> prelevement,
    required List ventes,
  }) async {
    List emballages = prelevement['emballages'] ?? [];
    List<Map<String, dynamic>> potsRestants = [];
    double quantiteRestanteKg = 0;
    double montantRestant = 0;

    Map<String, int> potsVendus = {};
    for (var emb in emballages) {
      potsVendus[emb['type']] = 0;
    }
    for (var venteDoc in ventes) {
      final vente = venteDoc.data() as Map<String, dynamic>;
      if (vente['emballagesVendus'] != null) {
        for (final emb in vente['emballagesVendus']) {
          potsVendus[emb['type']] =
              (potsVendus[emb['type']] ?? 0) + (emb['nombre'] ?? 0) as int;
        }
      }
    }

    for (var emb in emballages) {
      int potsRest = (emb['nombre'] ?? 0) - (potsVendus[emb['type']] ?? 0);
      if (potsRest > 0) {
        potsRestants.add({
          ...emb,
          'nombre': potsRest,
        });
        quantiteRestanteKg += potsRest * (emb['contenanceKg'] ?? 0.0);
        montantRestant += potsRest * (emb['prixUnitaire'] ?? 0.0);
      }
    }

    await FirebaseFirestore.instance
        .collection('prelevements')
        .doc(prelevementId)
        .update({
      'magazinierApprobationRestitution': true,
      'magazinierApprobateurNom': userNom ?? '',
      'dateApprobationRestitution': FieldValue.serverTimestamp(),
      'emballagesRestitues': potsRestants,
      'quantiteRestituee': quantiteRestanteKg,
      'montantRestitue': montantRestant,
      'restitutionAutomatique': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return FutureBuilder<DocumentSnapshot>(
      future: currentUser != null
          ? FirebaseFirestore.instance
              .collection('utilisateurs')
              .doc(currentUser.uid)
              .get()
          : null,
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!userSnap.hasData || userSnap.data == null) {
          // Pas de données utilisateur
          return Center(child: Text("Utilisateur non trouvé"));
        }

        final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
        final nomUser = userData['nom'] as String?;
        final magField = userData['magazinier'] as Map<String, dynamic>?;
        final typeMag = magField?['type']?.toString()?.toLowerCase().trim();
        final userId = currentUser?.uid;

        // Autorisation stricte par rôle exact
        if (typeMag == 'simple') {
          return magasinierSimpleView(userId!, nomUser ?? "");
        } else if (typeMag == 'principale') {
          return magasinierPrincipalView();
        } else {
          // Tout autre type d'utilisateur : accès refusé
          return Center(
              child: Text(
                  "Accès refusé : vous n'êtes pas un magasinier autorisé."));
        }
      },
    );
  }

  // ----------- MAGASINIER SIMPLE VIEW -----------
  // Helper pour récupérer le nom du mag principal (à adapter selon ta structure user)
  Future<String> getNomMagPrincipal() async {
    // TODO: Ajoute la vraie logique de récupération, ici un exemple statique :
    return "MAGAZINIER PRINCIPAL";
  }

// Helper pour récupérer le nom de boutique du client à partir de son id (cache local simple)
  final Map<String, String> _clientNameCache = {};
  Future<String> getClientNomBoutique(String clientId) async {
    if (_clientNameCache.containsKey(clientId))
      return _clientNameCache[clientId]!;
    final snap = await FirebaseFirestore.instance
        .collection('clients')
        .doc(clientId)
        .get();
    final nom = (snap.data() ?? {})['nomBoutique'] ?? clientId;
    _clientNameCache[clientId] = nom;
    return nom;
  }

  Widget magasinierSimpleView(
    String userId,
    String nomUser, {
    VoidCallback? onPrelevement,
  }) {
    final ValueNotifier<Map<String, String?>>
        expandedCommercialSelectorByPrelev = ValueNotifier({});

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('conditionnement').snapshots(),
      builder: (context, lotsSnap) {
        if (!lotsSnap.hasData || lotsSnap.data!.docs.isEmpty) {
          return const Center(child: Text("Aucun lot reçu."));
        }
        final lots = lotsSnap.data!.docs;
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: lots.length,
              separatorBuilder: (c, i) => const SizedBox(height: 18),
              itemBuilder: (context, i) {
                final lot = lots[i].data() as Map<String, dynamic>;
                final lotId = lots[i].id;
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('prelevements')
                      .where('lotConditionnementId', isEqualTo: lotId)
                      .snapshots(),
                  builder: (context, allPrelevSnap) {
                    if (!allPrelevSnap.hasData) return const SizedBox.shrink();
                    final prelevements = allPrelevSnap.data!.docs;

                    // Prélèvements reçus par ce magasinier simple (un par doc !)
                    final prelevementsRecus = prelevements.where((prDoc) {
                      final d = prDoc.data() as Map<String, dynamic>;
                      return d['typePrelevement'] == 'magasinier' &&
                          d['magasinierDestId'] == userId;
                    }).map((prDoc) {
                      final d = prDoc.data() as Map<String, dynamic>;
                      final date = d['datePrelevement'] is Timestamp
                          ? (d['datePrelevement'] as Timestamp).toDate()
                          : null;
                      return {
                        "doc": prDoc,
                        "id": prDoc.id,
                        "date": date,
                        "data": d,
                      };
                    }).toList();

                    if (prelevementsRecus.isEmpty)
                      return const SizedBox.shrink();

                    // Pour chaque prélèvement reçu, une carte indépendante
                    return Column(
                      children: prelevementsRecus.map<Widget>((prelevData) {
                        final prDoc =
                            prelevData['doc'] as QueryDocumentSnapshot;
                        final prId = prelevData['id'] as String;
                        final d = prelevData['data'] as Map<String, dynamic>;
                        final datePr = prelevData['date'] as DateTime?;

                        double quantiteRecu =
                            (d['quantiteTotale'] ?? 0.0).toDouble();
                        Map<String, int> potsRecusParType = {};
                        if (d['emballages'] != null) {
                          for (var emb in d['emballages']) {
                            final t = emb['type'];
                            final n = (emb['nombre'] ?? 0) as int;
                            potsRecusParType[t] =
                                (potsRecusParType[t] ?? 0) + n;
                          }
                        }
                        final prelevRecusDocId = prId;
                        final prelevRecusData = d;

                        // Prélèvements faits à des commerciaux à partir de CE prélèvement
                        final prelevementsCommerciaux =
                            prelevements.where((prDoc2) {
                          final d2 = prDoc2.data() as Map<String, dynamic>;
                          return d2['typePrelevement'] == 'commercial' &&
                              d2['magazinierId'] == userId &&
                              d2['prelevementMagasinierId'] == prId;
                        }).toList();

                        double quantitePrelevee = 0.0;
                        Map<String, int> potsPrelevesParType = {};
                        for (final prDoc2 in prelevementsCommerciaux) {
                          final d2 = prDoc2.data() as Map<String, dynamic>;
                          quantitePrelevee +=
                              (d2['quantiteTotale'] ?? 0.0).toDouble();
                          if (d2['emballages'] != null) {
                            for (var emb in d2['emballages']) {
                              final t = emb['type'];
                              final n = (emb['nombre'] ?? 0) as int;
                              potsPrelevesParType[t] =
                                  (potsPrelevesParType[t] ?? 0) + n;
                            }
                          }
                        }

                        // CUMUL DES RESTES COMMERCIAUX VALIDÉS sur CE prélèvement
                        Map<String, int> totalRestesParType = {};
                        double totalRestesKg = 0.0;
                        for (final prDoc2 in prelevementsCommerciaux) {
                          final d2 = prDoc2.data() as Map<String, dynamic>;
                          if (d2['magazinierApprobationRestitution'] == true &&
                              d2['demandeRestitution'] == true &&
                              d2['restesApresVenteCommercial'] != null) {
                            final restes = Map<String, dynamic>.from(
                                d2['restesApresVenteCommercial']);
                            restes.forEach((k, v) {
                              totalRestesParType[k] =
                                  (totalRestesParType[k] ?? 0) + (v as int);
                            });
                            if (d2['emballages'] != null) {
                              for (var emb in d2['emballages']) {
                                final type = emb['type'];
                                final contenance =
                                    (emb['contenanceKg'] ?? 0.0).toDouble();
                                if (restes.containsKey(type)) {
                                  totalRestesKg +=
                                      (restes[type] ?? 0) * contenance;
                                }
                              }
                            }
                          }
                        }

                        // --- MAJ Firestore des champs restesApresVenteCommerciaux et restantApresVenteCommerciauxKg (doc mag simple) ---
                        bool needsUpdate = false;
                        Map<String, int> dbRestes = Map<String, int>.from(
                            prelevRecusData['restesApresVenteCommerciaux'] ??
                                {});
                        totalRestesParType.forEach((k, v) {
                          final current = dbRestes[k] ?? 0;
                          if (v != current) {
                            dbRestes[k] = v;
                            needsUpdate = true;
                          }
                        });
                        double dbRestesKg = (prelevRecusData[
                                    'restantApresVenteCommerciauxKg'] ??
                                0.0)
                            .toDouble();
                        if ((totalRestesKg - dbRestesKg).abs() > 0.01) {
                          dbRestesKg = totalRestesKg;
                          needsUpdate = true;
                        }
                        if (needsUpdate && prelevRecusDocId.isNotEmpty) {
                          FirebaseFirestore.instance
                              .collection('prelevements')
                              .doc(prelevRecusDocId)
                              .update({
                            'restesApresVenteCommerciaux': dbRestes,
                            'restantApresVenteCommerciauxKg': dbRestesKg,
                          });
                        }
                        final restesApresVentesCommerciaux = dbRestes;
                        final restesKgApresVentesCommerciaux = dbRestesKg;

                        double quantiteRestanteNormal =
                            quantiteRecu - quantitePrelevee;
                        double quantiteRestante = quantiteRestanteNormal +
                            restesKgApresVentesCommerciaux;

                        // Cumul des pots par type (ajoute aussi les restes commerciaux validés)
                        Map<String, int> potsRestantsParType = {};
                        for (final t in potsRecusParType.keys) {
                          final resteNormal = (potsRecusParType[t] ?? 0) -
                              (potsPrelevesParType[t] ?? 0);
                          final resteComm =
                              restesApresVentesCommerciaux[t] ?? 0;
                          potsRestantsParType[t] = resteNormal + resteComm;
                        }
                        for (final t in restesApresVentesCommerciaux.keys) {
                          if (!potsRestantsParType.containsKey(t)) {
                            potsRestantsParType[t] =
                                restesApresVentesCommerciaux[t]!;
                          }
                        }

                        // Sélecteur commercial par prélèvement
                        final commerciauxForPrelev = prelevementsCommerciaux
                            .map((prDoc2) {
                              final d2 = prDoc2.data() as Map<String, dynamic>;
                              final date = d2['datePrelevement'] is Timestamp
                                  ? (d2['datePrelevement'] as Timestamp)
                                      .toDate()
                                  : null;
                              return {
                                "id": prDoc2.id,
                                "commercialId": d2['commercialId'] ?? "",
                                "nom": d2['commercialNom'] ?? "",
                                "date": date,
                                "doc": prDoc2,
                              };
                            })
                            .where(
                                (c) => c['commercialId'].toString().isNotEmpty)
                            .toList();

                        if (!expandedCommercialSelectorByPrelev.value
                            .containsKey(prId)) {
                          expandedCommercialSelectorByPrelev.value = {
                            ...expandedCommercialSelectorByPrelev.value,
                            prId: null,
                          };
                        }

                        // --- Statuts de restitution ---
                        bool restitutionValideePrincipal = prelevRecusData[
                                'magasinierPrincipalApprobationRestitution'] ==
                            true;
                        bool demandeRestitutionEnCours =
                            prelevRecusData['demandeRestitutionMagasinier'] ==
                                true;

                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          elevation: 5,
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // HEADER
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Lot: ${lot['lotOrigine'] ?? lotId}",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18),
                                          ),
                                          Text(
                                            "Prélèvement reçu le : ${datePr != null ? DateFormat('dd/MM/yyyy').format(datePr) : '?'}",
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.scale,
                                                  color: Colors.amber[700],
                                                  size: 18),
                                              const SizedBox(width: 6),
                                              Text("Quantité reçue : ",
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              Text(
                                                  "${quantiteRecu.toStringAsFixed(2)} kg",
                                                  style: const TextStyle(
                                                      fontSize: 15)),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.add_box,
                                                  color: Colors.blue, size: 18),
                                              const SizedBox(width: 6),
                                              Text("Restant : ",
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              Text(
                                                  "${quantiteRestante < 0 ? 0 : quantiteRestante.toStringAsFixed(2)} kg",
                                                  style: const TextStyle(
                                                      fontSize: 15,
                                                      color: Colors.blue)),
                                            ],
                                          ),
                                          if (potsRestantsParType.isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Wrap(
                                                spacing: 12,
                                                children: potsRestantsParType
                                                    .keys
                                                    .map((t) {
                                                  return Chip(
                                                    label: Text(
                                                      "$t: ${potsRestantsParType[t]! < 0 ? 0 : potsRestantsParType[t]} / ${potsRecusParType[t] ?? potsRestantsParType[t]} pots",
                                                      style: const TextStyle(
                                                          fontSize: 13),
                                                    ),
                                                    backgroundColor:
                                                        Colors.amber[50],
                                                    avatar: const Icon(
                                                        Icons.local_mall,
                                                        size: 18,
                                                        color: Colors.amber),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          if (restesApresVentesCommerciaux
                                              .isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 6),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.green[50],
                                                  border: Border.all(
                                                      color:
                                                          Colors.green[100]!),
                                                  borderRadius:
                                                      BorderRadius.circular(9),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 7.0,
                                                      horizontal: 10),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(Icons.undo,
                                                              color: Colors
                                                                  .green[700],
                                                              size: 20),
                                                          const SizedBox(
                                                              width: 7),
                                                          Text(
                                                            "Restes cumulés des commerciaux :",
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                        .green[
                                                                    800]),
                                                          ),
                                                          const SizedBox(
                                                              width: 7),
                                                          Text(
                                                            "${restesKgApresVentesCommerciaux.toStringAsFixed(2)} kg",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .green[900],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                          ),
                                                        ],
                                                      ),
                                                      ...restesApresVentesCommerciaux
                                                          .entries
                                                          .map((e) => Text(
                                                                "${e.key}: ${e.value} pots",
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    color: Colors
                                                                        .green),
                                                              )),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // BOUTON PRELEVER
                                    if (quantiteRestante > 0 &&
                                        !restitutionValideePrincipal)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 10, top: 2),
                                        child: ElevatedButton.icon(
                                          icon: const Icon(
                                              Icons.add_shopping_cart),
                                          label: const Text("Prélever"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                quantiteRestante > 0
                                                    ? Colors.green[700]
                                                    : Colors.grey,
                                            foregroundColor: Colors.white,
                                            elevation: 2,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30)),
                                          ),
                                          onPressed: () async {
                                            final result = await Get.to(
                                                () => PrelevementFormPage(
                                                      lotConditionnement: {
                                                        ...lot,
                                                        "id": lotId,
                                                        "prelevementMagasinierId":
                                                            prId,
                                                        "prelevementMagasinierData":
                                                            d,
                                                      },
                                                    ));
                                            if (result == true &&
                                                onPrelevement != null) {
                                              onPrelevement!();
                                            }
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                                // ---------- SELECTEUR COMMERCIAL PAR PRELEVEMENT ----------
                                if (commerciauxForPrelev.isNotEmpty)
                                  ValueListenableBuilder<Map<String, String?>>(
                                    valueListenable:
                                        expandedCommercialSelectorByPrelev,
                                    builder: (context, selections, _) {
                                      final expandedComId = selections[prId];
                                      return Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 2),
                                            child: Row(
                                              children: [
                                                Icon(Icons.people,
                                                    color: Colors.green,
                                                    size: 19),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child:
                                                      DropdownButtonFormField<
                                                          String>(
                                                    value: expandedComId,
                                                    hint: const Text(
                                                        "Afficher un prélèvement commercial..."),
                                                    items: commerciauxForPrelev
                                                        .map((c) =>
                                                            DropdownMenuItem<
                                                                String>(
                                                              value: c['id']
                                                                  as String,
                                                              child: Text(
                                                                  "${c['nom']} - ${(c['date'] != null) ? DateFormat('dd/MM/yyyy').format(c['date']) : c['id']}"),
                                                            ))
                                                        .toList(),
                                                    onChanged: (val) {
                                                      expandedCommercialSelectorByPrelev
                                                          .value = {
                                                        ...expandedCommercialSelectorByPrelev
                                                            .value,
                                                        prId:
                                                            expandedComId == val
                                                                ? null
                                                                : val,
                                                      };
                                                    },
                                                    isExpanded: true,
                                                    icon: expandedComId != null
                                                        ? Icon(
                                                            Icons.arrow_drop_up)
                                                        : Icon(Icons
                                                            .arrow_drop_down),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (expandedComId != null)
                                            Builder(builder: (context) {
                                              final match = commerciauxForPrelev
                                                  .firstWhere(
                                                (c) => c['id'] == expandedComId,
                                                orElse: () => {},
                                              );
                                              if (match.isNotEmpty) {
                                                return _buildCommercialDetailsSimple(
                                                  context,
                                                  match['doc']
                                                      as QueryDocumentSnapshot,
                                                  isMobile,
                                                  nomMagasinier: nomUser,
                                                  onPrelevement: onPrelevement,
                                                );
                                              }
                                              return const SizedBox();
                                            }),
                                        ],
                                      );
                                    },
                                  ),
                                // --- BOUTON RENDRE COMPTE ---
                                FutureBuilder<String>(
                                  future: getNomMagPrincipal(),
                                  builder: (context, principalSnap) {
                                    bool tousRestitues = false;
                                    if (prelevementsCommerciaux.isNotEmpty) {
                                      tousRestitues = prelevementsCommerciaux
                                          .every((prDoc2) {
                                        final d2 = prDoc2.data()
                                            as Map<String, dynamic>;
                                        return d2['demandeRestitution'] ==
                                                true &&
                                            d2['magazinierApprobationRestitution'] ==
                                                true;
                                      });
                                    }

                                    if (tousRestitues &&
                                        principalSnap.hasData &&
                                        !demandeRestitutionEnCours &&
                                        !restitutionValideePrincipal) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            top: 14.0,
                                            left: 10,
                                            right: 10,
                                            bottom: 4),
                                        child: ElevatedButton.icon(
                                          icon: const Icon(
                                              Icons.assignment_turned_in),
                                          label: Text(
                                              'Rendre compte au "${principalSnap.data!}"'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue[700],
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size(200, 45),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                            ),
                                          ),
                                          onPressed: () async {
                                            final docRef = FirebaseFirestore
                                                .instance
                                                .collection('prelevements')
                                                .doc(prelevRecusDocId);
                                            await docRef.update({
                                              'demandeRestitutionMagasinier':
                                                  true,
                                              'dateDemandeRestitutionMagasinier':
                                                  FieldValue.serverTimestamp(),
                                            });
                                            Get.snackbar("Demande envoyée",
                                                "La demande de restitution a été transmise au magasinier principal.");
                                            if (onPrelevement != null)
                                              onPrelevement!();
                                          },
                                        ),
                                      );
                                    } else if (demandeRestitutionEnCours &&
                                        !restitutionValideePrincipal) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            top: 14,
                                            left: 10,
                                            right: 10,
                                            bottom: 4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 18),
                                          decoration: BoxDecoration(
                                            color: Colors.orange[100],
                                            borderRadius:
                                                BorderRadius.circular(13),
                                          ),
                                          child: const Text(
                                            "En attente de validation du magasinier principal...",
                                            style: TextStyle(
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      );
                                    } else if (restitutionValideePrincipal) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            top: 14,
                                            left: 10,
                                            right: 10,
                                            bottom: 4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 18),
                                          decoration: BoxDecoration(
                                            color: Colors.green[100],
                                            borderRadius:
                                                BorderRadius.circular(13),
                                          ),
                                          child: const Text(
                                            "Restitution validée par le magasinier principal",
                                            style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget magasinierPrincipalView({VoidCallback? onPrelevement}) {
    final ValueNotifier<Map<String, dynamic>> expandedSelectorByLot =
        ValueNotifier({});
    final ValueNotifier<Map<String, String?>> expandedCommercialByMagSimple =
        ValueNotifier({});
    final ValueNotifier<Map<String, String?>>
        expandedSousPrelevementByCommercial = ValueNotifier({});

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('conditionnement').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Aucun produit conditionné."));
        }
        final lots = snapshot.data!.docs;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: lots.length,
              separatorBuilder: (c, i) => const SizedBox(height: 18),
              itemBuilder: (context, i) {
                final lotDoc = lots[i];
                final lot = lotDoc.data() as Map<String, dynamic>;
                final lotId = lotDoc.id;
                final magasinierPrincipalId =
                    FirebaseAuth.instance.currentUser?.uid;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('prelevements')
                      .where('lotConditionnementId', isEqualTo: lotId)
                      .snapshots(),
                  builder: (context, allPrelevSnap) {
                    if (!allPrelevSnap.hasData) return const SizedBox();

                    double quantiteConditionnee =
                        (lot['quantiteConditionnee'] ?? 0.0).toDouble();
                    double quantitePrelevee = 0.0;
                    int nbTotalPots = (lot['nbTotalPots'] ?? 0) as int;
                    double prixTotal = (lot['prixTotal'] ?? 0.0).toDouble();

                    Map<String, int> potsRestantsParType = {};
                    Map<String, int> potsInitials = {};
                    if (lot['emballages'] != null) {
                      for (var emb in lot['emballages']) {
                        potsRestantsParType[emb['type']] = emb['nombre'];
                        potsInitials[emb['type']] = emb['nombre'];
                      }
                    }

                    List<Map<String, dynamic>> magSimplesForLot = [];
                    final prelevementsCommerciauxDirects =
                        allPrelevSnap.data!.docs.where((prDoc) {
                      final pr = prDoc.data() as Map<String, dynamic>;
                      return pr['typePrelevement'] == 'commercial' &&
                          pr['lotConditionnementId'] == lotId &&
                          (pr['magazinierId'] ?? '') == magasinierPrincipalId &&
                          (pr['commercialId'] ?? '').toString().isNotEmpty;
                    }).toList();

                    // Clé unique = magSimpleId|prelevementMagasinierId
                    Map<String, List<QueryDocumentSnapshot>>
                        prelevementsCommerciauxByMagSimple = {};

                    // -------- PATCH: Calcul des restes cumulés sans surplus ---------
                    // 1. Récupère tous les prélèvements mag simples pour ce lot
                    final magsSimplesDocs =
                        allPrelevSnap.data!.docs.where((prDoc) {
                      final d = prDoc.data() as Map<String, dynamic>;
                      return d['typePrelevement'] == 'magasinier' &&
                          d['magasinierDestId'] != null;
                    }).toList();

                    Map<String, int> restesCumulesParType = {};
                    double restesCumulesKg = 0.0;

                    for (final magSimpleDoc in magsSimplesDocs) {
                      final magData =
                          magSimpleDoc.data() as Map<String, dynamic>;
                      final magRestitutionValidee = magData[
                              'magasinierPrincipalApprobationRestitution'] ==
                          true;

                      if (magRestitutionValidee &&
                          magData['restesApresVenteCommerciaux'] != null) {
                        // Cas 1 : restitution validée, on prend UNIQUEMENT le champ firestore (ne pas additionner le calcul dynamique)
                        final restes = Map<String, dynamic>.from(
                            magData['restesApresVenteCommerciaux']);
                        restes.forEach((k, v) {
                          restesCumulesParType[k] =
                              (restesCumulesParType[k] ?? 0) + (v as int);
                        });
                        if (magData['emballages'] != null) {
                          for (var emb in magData['emballages']) {
                            final type = emb['type'];
                            final contenance =
                                (emb['contenanceKg'] ?? 0.0).toDouble();
                            if (restes.containsKey(type)) {
                              restesCumulesKg +=
                                  (restes[type] ?? 0) * contenance;
                            }
                          }
                        }
                      } else {
                        // Cas 2 : restitution NON validée, on fait le calcul dynamique
                        final magSimpleId = magData['magasinierDestId'];
                        final magSimplePrId = magSimpleDoc.id;
                        final sousPrelevCommerciaux =
                            allPrelevSnap.data!.docs.where((prDoc2) {
                          final d2 = prDoc2.data() as Map<String, dynamic>;
                          return d2['typePrelevement'] == 'commercial' &&
                              d2['magazinierId'] == magSimpleId &&
                              d2['prelevementMagasinierId'] == magSimplePrId;
                        }).toList();

                        Map<String, int> totalRestesParType = {};
                        double totalRestesKg = 0.0;
                        for (final prDoc2 in sousPrelevCommerciaux) {
                          final d2 = prDoc2.data() as Map<String, dynamic>;
                          if (d2['magazinierApprobationRestitution'] == true &&
                              d2['demandeRestitution'] == true &&
                              d2['restesApresVenteCommercial'] != null) {
                            final restes = Map<String, dynamic>.from(
                                d2['restesApresVenteCommercial']);
                            restes.forEach((k, v) {
                              totalRestesParType[k] =
                                  (totalRestesParType[k] ?? 0) + (v as int);
                            });
                            if (d2['emballages'] != null) {
                              for (var emb in d2['emballages']) {
                                final type = emb['type'];
                                final contenance =
                                    (emb['contenanceKg'] ?? 0.0).toDouble();
                                if (restes.containsKey(type)) {
                                  totalRestesKg +=
                                      (restes[type] ?? 0) * contenance;
                                }
                              }
                            }
                          }
                        }
                        totalRestesParType.forEach((k, v) {
                          restesCumulesParType[k] =
                              (restesCumulesParType[k] ?? 0) + v;
                        });
                        restesCumulesKg += totalRestesKg;
                      }
                    }

                    // --- Calcul des restes commerciaux DIRECTS du principal (hors mag simples) ---
                    final commerciauxDirects =
                        allPrelevSnap.data!.docs.where((prDoc) {
                      final d = prDoc.data() as Map<String, dynamic>;
                      return d['typePrelevement'] == 'commercial' &&
                          (d['magazinierId'] ?? '') == magasinierPrincipalId &&
                          (d['prelevementMagasinierId'] == null ||
                              d['prelevementMagasinierId'].toString().isEmpty);
                    }).toList();

                    for (final prDoc in commerciauxDirects) {
                      final prData = prDoc.data() as Map<String, dynamic>;
                      if (prData['magazinierApprobationRestitution'] == true &&
                          prData['demandeRestitution'] == true &&
                          prData['restesApresVenteCommercial'] != null) {
                        final restes = Map<String, dynamic>.from(
                            prData['restesApresVenteCommercial']);
                        restes.forEach((k, v) {
                          restesCumulesParType[k] =
                              (restesCumulesParType[k] ?? 0) + (v as int);
                        });
                        if (prData['emballages'] != null) {
                          for (var emb in prData['emballages']) {
                            final type = emb['type'];
                            final contenance =
                                (emb['contenanceKg'] ?? 0.0).toDouble();
                            if (restes.containsKey(type)) {
                              restesCumulesKg +=
                                  (restes[type] ?? 0) * contenance;
                            }
                          }
                        }
                      }
                    }

                    for (final pr in allPrelevSnap.data!.docs) {
                      final prData = pr.data() as Map<String, dynamic>;
                      final isVersMagasinierSimple =
                          (prData['magasinierDestId'] ?? '')
                                  .toString()
                                  .isNotEmpty &&
                              prData['typePrelevement'] == 'magasinier';

                      final isVersCommercialDirect =
                          prData['typePrelevement'] == 'commercial' &&
                              (prData['magazinierId'] ?? '') ==
                                  magasinierPrincipalId;

                      if (isVersMagasinierSimple || isVersCommercialDirect) {
                        quantitePrelevee +=
                            (prData['quantiteTotale'] ?? 0.0).toDouble();
                        prixTotal -=
                            (prData['prixTotalEstime'] ?? 0.0).toDouble();
                        if (prData['emballages'] != null) {
                          for (var emb in prData['emballages']) {
                            final t = emb['type'];
                            potsRestantsParType[t] =
                                (potsRestantsParType[t] ?? 0) -
                                    ((emb['nombre'] ?? 0) as num).toInt();
                          }
                        }
                        nbTotalPots -= (prData['emballages'] as List).fold<int>(
                            0,
                            (prev, emb) =>
                                prev + ((emb['nombre'] ?? 0) as num).toInt());
                      }

                      if (isVersMagasinierSimple) {
                        final date = prData['datePrelevement'] is Timestamp
                            ? (prData['datePrelevement'] as Timestamp).toDate()
                            : null;
                        magSimplesForLot.add({
                          "id": prData['magasinierDestId'] ?? "",
                          "nom": prData['magasinierDestNom'] ?? "",
                          "doc": pr,
                          "date": date,
                          "prId": pr.id,
                        });
                      }

                      // Correction : clé unique = magSimpleId|prelevementMagasinierId
                      if (prData['typePrelevement'] == 'commercial' &&
                          prData['magazinierId'] != null &&
                          prData['prelevementMagasinierId'] != null) {
                        final key =
                            "${prData['magazinierId']}|${prData['prelevementMagasinierId']}";
                        prelevementsCommerciauxByMagSimple.putIfAbsent(
                            key, () => []);
                        prelevementsCommerciauxByMagSimple[key]!.add(pr);
                      }
                    }

                    double quantiteRestanteNormal =
                        quantiteConditionnee - quantitePrelevee;
                    double quantiteRestante =
                        quantiteRestanteNormal + restesCumulesKg;

                    Map<String, int> potsRestantsAvecRestes =
                        Map.from(potsRestantsParType);
                    restesCumulesParType.forEach((k, v) {
                      potsRestantsAvecRestes[k] =
                          (potsRestantsAvecRestes[k] ?? 0) + v;
                    });

                    final commerciauxForLot = <Map<String, String>>{};
                    for (final prDoc in prelevementsCommerciauxDirects) {
                      final pr = prDoc.data() as Map<String, dynamic>;
                      final cid = pr['commercialId']?.toString() ?? '';
                      final nom = pr['commercialNom']?.toString() ?? '';
                      if (cid.isNotEmpty &&
                          commerciauxForLot.every((c) => c['id'] != cid)) {
                        commerciauxForLot.add({"id": cid, "nom": nom});
                      }
                    }

                    if (!expandedSelectorByLot.value.containsKey(lotId)) {
                      expandedSelectorByLot.value = {
                        ...expandedSelectorByLot.value,
                        lotId: null,
                      };
                    }

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      elevation: 5,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // En-tête lot
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.green[50],
                                child: Icon(Icons.inventory_2_rounded,
                                    size: 35, color: Colors.green[800]),
                              ),
                              title: Text(
                                "Lot: ${lot['lotOrigine'] ?? lotId}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.scale,
                                          color: Colors.amber[700], size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Conditionné: ${quantiteConditionnee.toStringAsFixed(2)} kg",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.add_box,
                                          color: Colors.blue, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Restant: ${quantiteRestante < 0 ? 0 : quantiteRestante.toStringAsFixed(2)} kg",
                                        style: const TextStyle(
                                            fontSize: 14, color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.format_list_numbered,
                                          color: Colors.brown, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                          "Nb total de pots: ${nbTotalPots < 0 ? 0 : nbTotalPots}",
                                          style: const TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.attach_money,
                                          color: Colors.green, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Prix total: ${prixTotal < 0 ? 0 : prixTotal.toStringAsFixed(0)} FCFA",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (potsRestantsAvecRestes.isNotEmpty)
                                    ...potsRestantsAvecRestes.entries
                                        .map((e) => Row(
                                              children: [
                                                Icon(Icons.local_mall,
                                                    color: Colors.amber,
                                                    size: 16),
                                                const SizedBox(width: 6),
                                                Text(
                                                  "${e.key}: ${e.value < 0 ? 0 : e.value} pots"
                                                  " (${potsInitials[e.key] ?? 0} init.)",
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                ),
                                              ],
                                            )),
                                  if (restesCumulesParType.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 10, bottom: 8),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          border: Border.all(
                                              color: Colors.green[100]!),
                                          borderRadius:
                                              BorderRadius.circular(9),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12.0, horizontal: 14),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.undo,
                                                      color: Colors.green[700],
                                                      size: 20),
                                                  const SizedBox(width: 7),
                                                  Text(
                                                    "Restes cumulés restitués : ",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.green[800]),
                                                  ),
                                                  const SizedBox(width: 7),
                                                  Text(
                                                    "${restesCumulesKg.toStringAsFixed(2)} kg",
                                                    style: TextStyle(
                                                        color:
                                                            Colors.green[900],
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                ],
                                              ),
                                              ...restesCumulesParType.entries
                                                  .map((e) => Text(
                                                      "${e.key}: ${e.value} pots",
                                                      style: const TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              Colors.green))),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: (quantiteRestante > 0)
                                  ? ElevatedButton.icon(
                                      icon: const Icon(Icons.add_shopping_cart),
                                      label: const Text("Prélever"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: quantiteRestante > 0
                                            ? Colors.green[700]
                                            : Colors.grey,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30)),
                                      ),
                                      onPressed: () async {
                                        final res =
                                            await showModalBottomSheet<String>(
                                          context: context,
                                          builder: (ctx) => SafeArea(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ListTile(
                                                  leading: Icon(Icons.people,
                                                      color: Colors.green),
                                                  title:
                                                      Text("À un commercial"),
                                                  onTap: () => Navigator.pop(
                                                      ctx, 'commercial'),
                                                ),
                                                ListTile(
                                                  leading: Icon(Icons.store,
                                                      color: Colors.brown),
                                                  title:
                                                      Text("À un magasinier"),
                                                  onTap: () => Navigator.pop(
                                                      ctx, 'magasinier'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                        if (res == 'commercial') {
                                          // Ouvre le formulaire de prélèvement vers un commercial
                                          final result =
                                              await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  PrelevementFormPage(
                                                lotConditionnement: {
                                                  ...lot,
                                                  "id": lotId,
                                                  "magazinierId":
                                                      magasinierPrincipalId,
                                                  // PAS de prelevementMagasinierId ici
                                                },
                                              ),
                                            ),
                                          );
                                          if (result == true &&
                                              onPrelevement != null)
                                            onPrelevement!();
                                          (context as Element).markNeedsBuild();
                                        } else if (res == 'magasinier') {
                                          // Ouvre le formulaire de prélèvement vers un magasinier simple
                                          final result =
                                              await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  PrelevementMagasinierFormPage(
                                                lotConditionnement: {
                                                  ...lot,
                                                  "id": lotId,
                                                },
                                              ),
                                            ),
                                          );
                                          if (result == true &&
                                              onPrelevement != null)
                                            onPrelevement!();
                                          (context as Element).markNeedsBuild();
                                        }
                                      },
                                    )
                                  : null,
                            ),
                            // ... tout le reste de l'affichage (sélecteurs, détails mag simples, commerciaux, etc.)
                            ValueListenableBuilder<Map<String, dynamic>>(
                              valueListenable: expandedSelectorByLot,
                              builder: (context, selections, _) {
                                final expanded = selections[lotId];
                                final expandedType =
                                    expanded is Map ? expanded['type'] : null;
                                final expandedId =
                                    expanded is Map ? expanded['id'] : null;

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // -------- Sélecteur magasinier simple --------
                                    if (magSimplesForLot.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2),
                                        child: Row(
                                          children: [
                                            Icon(Icons.store,
                                                color: Colors.brown, size: 19),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: DropdownButtonFormField<
                                                  String>(
                                                value:
                                                    expandedType == 'magasinier'
                                                        ? expandedId as String?
                                                        : null,
                                                hint: const Text(
                                                    "Afficher un prélèvement de magasinier simple..."),
                                                items: magSimplesForLot
                                                    .map((m) =>
                                                        DropdownMenuItem<
                                                            String>(
                                                          value: m['prId']
                                                              as String,
                                                          child: Text(
                                                            "${m['nom'] ?? ''} - ${m['date'] != null ? DateFormat('dd/MM/yyyy').format(m['date']) : m['prId']}",
                                                          ),
                                                        ))
                                                    .toList(),
                                                onChanged: (val) {
                                                  expandedSelectorByLot.value =
                                                      {
                                                    lotId: expandedType ==
                                                                'magasinier' &&
                                                            expandedId == val
                                                        ? null
                                                        : {
                                                            'type':
                                                                'magasinier',
                                                            'id': val
                                                          }
                                                  };
                                                },
                                                isExpanded: true,
                                                icon: expandedType ==
                                                        'magasinier'
                                                    ? Icon(Icons.arrow_drop_up)
                                                    : Icon(
                                                        Icons.arrow_drop_down),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (expandedType == 'magasinier' &&
                                        expandedId != null)
                                      Builder(builder: (context) {
                                        final selectedMagSimple =
                                            magSimplesForLot.firstWhere(
                                                (m) => m['prId'] == expandedId,
                                                orElse: () =>
                                                    <String, dynamic>{});
                                        final selectedPrDoc =
                                            selectedMagSimple['doc']
                                                as QueryDocumentSnapshot?;
                                        if (selectedPrDoc == null) {
                                          return const SizedBox();
                                        }
                                        final magSimpleId =
                                            (selectedPrDoc.data() as Map<String,
                                                dynamic>)['magasinierDestId'];
                                        final prId = selectedPrDoc.id;
                                        final magKey = "$magSimpleId|$prId";
                                        final sousPrelevs =
                                            prelevementsCommerciauxByMagSimple[
                                                    magKey] ??
                                                [];
                                        final commerciauxOfMagSimple =
                                            sousPrelevs
                                                .map((prDoc) => {
                                                      "id": (prDoc.data()
                                                                  as Map<String,
                                                                      dynamic>)[
                                                              'commercialId'] ??
                                                          "",
                                                      "nom": (prDoc.data()
                                                                  as Map<String,
                                                                      dynamic>)[
                                                              'commercialNom'] ??
                                                          "",
                                                      "prId": prDoc.id,
                                                    })
                                                .where((c) => c['id']
                                                    .toString()
                                                    .isNotEmpty)
                                                .toList();
                                        final uniqueCommerciauxIds =
                                            commerciauxOfMagSimple
                                                .map((e) => e['id'])
                                                .toSet()
                                                .toList();
                                        if (!expandedCommercialByMagSimple.value
                                            .containsKey(magKey)) {
                                          expandedCommercialByMagSimple.value =
                                              {
                                            ...expandedCommercialByMagSimple
                                                .value,
                                            magKey: null,
                                          };
                                        }
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            _buildMagasinierSimpleDetails(
                                              context,
                                              selectedPrDoc,
                                              sousPrelevs,
                                              lot,
                                              lotId,
                                              isMobile,
                                            ),
                                            const SizedBox(height: 10),
                                            if (uniqueCommerciauxIds.isNotEmpty)
                                              ValueListenableBuilder<
                                                  Map<String, String?>>(
                                                valueListenable:
                                                    expandedCommercialByMagSimple,
                                                builder: (context,
                                                    comSelections, _) {
                                                  final expandedCommercialId =
                                                      comSelections[magKey];
                                                  return Column(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 2),
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.person,
                                                                color:
                                                                    Colors.blue,
                                                                size: 19),
                                                            const SizedBox(
                                                                width: 4),
                                                            Expanded(
                                                              child:
                                                                  DropdownButtonFormField<
                                                                      String>(
                                                                value:
                                                                    expandedCommercialId,
                                                                hint: const Text(
                                                                    "Afficher un commercial..."),
                                                                items: uniqueCommerciauxIds
                                                                    .map((cid) {
                                                                  final first =
                                                                      commerciauxOfMagSimple.firstWhere((e) =>
                                                                          e['id'] ==
                                                                          cid);
                                                                  return DropdownMenuItem<
                                                                          String>(
                                                                      value: cid
                                                                          as String,
                                                                      child: Text(
                                                                          first['nom'] ??
                                                                              cid));
                                                                }).toList(),
                                                                onChanged:
                                                                    (val) {
                                                                  expandedCommercialByMagSimple
                                                                      .value = {
                                                                    ...expandedCommercialByMagSimple
                                                                        .value,
                                                                    magKey: expandedCommercialId ==
                                                                            val
                                                                        ? null
                                                                        : val,
                                                                  };
                                                                },
                                                                isExpanded:
                                                                    true,
                                                                icon: expandedCommercialId !=
                                                                        null
                                                                    ? Icon(Icons
                                                                        .arrow_drop_up)
                                                                    : Icon(Icons
                                                                        .arrow_drop_down),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (expandedCommercialId !=
                                                          null)
                                                        Builder(
                                                            builder: (context) {
                                                          final sousPrelsCom = sousPrelevs
                                                              .where((prDoc) =>
                                                                  (prDoc.data() as Map<
                                                                          String,
                                                                          dynamic>)[
                                                                      'commercialId'] ==
                                                                  expandedCommercialId)
                                                              .toList();
                                                          if (sousPrelsCom
                                                                  .length >
                                                              1) {
                                                            final sousPrelKey =
                                                                "$magKey-$expandedCommercialId";
                                                            if (!expandedSousPrelevementByCommercial
                                                                .value
                                                                .containsKey(
                                                                    sousPrelKey)) {
                                                              expandedSousPrelevementByCommercial
                                                                  .value = {
                                                                ...expandedSousPrelevementByCommercial
                                                                    .value,
                                                                sousPrelKey:
                                                                    null,
                                                              };
                                                            }
                                                            final expandedSousPrId =
                                                                expandedSousPrelevementByCommercial
                                                                        .value[
                                                                    sousPrelKey];
                                                            return Column(
                                                              children: [
                                                                Padding(
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          2),
                                                                  child: Row(
                                                                    children: [
                                                                      Icon(
                                                                          Icons
                                                                              .history,
                                                                          color: Colors
                                                                              .orange,
                                                                          size:
                                                                              19),
                                                                      const SizedBox(
                                                                          width:
                                                                              4),
                                                                      Expanded(
                                                                        child: DropdownButtonFormField<
                                                                            String>(
                                                                          value:
                                                                              expandedSousPrId,
                                                                          hint:
                                                                              const Text("Sélectionner un sous-prélèvement..."),
                                                                          items:
                                                                              sousPrelsCom.map((subPrDoc) {
                                                                            final subData =
                                                                                subPrDoc.data() as Map<String, dynamic>;
                                                                            final subDate = subData['datePrelevement'] != null
                                                                                ? (subData['datePrelevement'] as Timestamp).toDate()
                                                                                : null;
                                                                            final qte =
                                                                                subData['quantiteTotale'] ?? '?';
                                                                            final dateStr = subDate != null
                                                                                ? DateFormat('dd/MM/yyyy').format(subDate)
                                                                                : subPrDoc.id;
                                                                            return DropdownMenuItem(
                                                                              value: subPrDoc.id,
                                                                              child: Text("$dateStr - $qte kg"),
                                                                            );
                                                                          }).toList(),
                                                                          onChanged:
                                                                              (val) {
                                                                            expandedSousPrelevementByCommercial.value =
                                                                                {
                                                                              ...expandedSousPrelevementByCommercial.value,
                                                                              sousPrelKey: val,
                                                                            };
                                                                          },
                                                                          isExpanded:
                                                                              true,
                                                                          icon: expandedSousPrId != null
                                                                              ? Icon(Icons.arrow_drop_up)
                                                                              : Icon(Icons.arrow_drop_down),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                // PATCH: Place le détail dans un ValueListenableBuilder pour que le rebuild s'effectue instantanément
                                                                ValueListenableBuilder<
                                                                    Map<String,
                                                                        String?>>(
                                                                  valueListenable:
                                                                      expandedSousPrelevementByCommercial,
                                                                  builder: (context,
                                                                      sousSelections,
                                                                      _) {
                                                                    final expandedSousPrId =
                                                                        sousSelections[
                                                                            sousPrelKey];
                                                                    if (expandedSousPrId !=
                                                                        null) {
                                                                      return _buildSousPrelevementCommercialWithVentes(
                                                                        context,
                                                                        sousPrelsCom.firstWhere((prDoc) =>
                                                                            prDoc.id ==
                                                                            expandedSousPrId),
                                                                        isMobile,
                                                                        nomMagasinier:
                                                                            selectedMagSimple['nom'] ??
                                                                                '',
                                                                        onPrelevement:
                                                                            onPrelevement,
                                                                        lot:
                                                                            lot,
                                                                      );
                                                                    }
                                                                    return const SizedBox();
                                                                  },
                                                                )
                                                              ],
                                                            );
                                                          } else if (sousPrelsCom
                                                                  .length ==
                                                              1) {
                                                            // --- VERSION COMPACTE AVEC BOUTONS ---
                                                            return _buildSousPrelevementCommercialWithVentes(
                                                              context,
                                                              sousPrelsCom
                                                                  .first,
                                                              isMobile,
                                                              nomMagasinier:
                                                                  selectedMagSimple[
                                                                          'nom'] ??
                                                                      '',
                                                              onPrelevement:
                                                                  onPrelevement,
                                                              lot: lot,
                                                            );
                                                          }
                                                          return const SizedBox();
                                                        })
                                                    ],
                                                  );
                                                },
                                              ),
                                            const SizedBox(height: 10),
                                          ],
                                        );
                                      }),
                                    // ----------- Sélecteur commercial direct (exclusif) -----------
                                    if (commerciauxForLot.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2),
                                        child: Row(
                                          children: [
                                            Icon(Icons.people,
                                                color: Colors.green, size: 19),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: DropdownButtonFormField<
                                                  String>(
                                                value:
                                                    expandedType == 'commercial'
                                                        ? expandedId as String?
                                                        : null,
                                                hint: const Text(
                                                    "Afficher un prélèvement commercial..."),
                                                items: commerciauxForLot
                                                    .map((c) =>
                                                        DropdownMenuItem<
                                                            String>(
                                                          value:
                                                              c['id'] as String,
                                                          child: Text(c['nom']
                                                              as String),
                                                        ))
                                                    .toList(),
                                                onChanged: (val) {
                                                  expandedSelectorByLot.value =
                                                      {
                                                    lotId: expandedType ==
                                                                'commercial' &&
                                                            expandedId == val
                                                        ? null
                                                        : {
                                                            'type':
                                                                'commercial',
                                                            'id': val
                                                          }
                                                  };
                                                },
                                                isExpanded: true,
                                                icon: expandedType ==
                                                        'commercial'
                                                    ? Icon(Icons.arrow_drop_up)
                                                    : Icon(
                                                        Icons.arrow_drop_down),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (expandedType == 'commercial' &&
                                        expandedId != null &&
                                        prelevementsCommerciauxDirects
                                            .isNotEmpty)
                                      Builder(
                                        builder: (context) {
                                          final selectedPrDocs =
                                              prelevementsCommerciauxDirects
                                                  .where(
                                                    (prDoc) =>
                                                        (prDoc.data() as Map<
                                                                String,
                                                                dynamic>)[
                                                            'commercialId'] ==
                                                        expandedId,
                                                  )
                                                  .toList();

                                          if (selectedPrDocs.length > 1) {
                                            // PATCH: Dropdown unique par commercial/lot
                                            final String dropdownKey =
                                                "direct_${lotId}_$expandedId";
                                            if (!(directPrelevementSelection
                                                .value
                                                .containsKey(dropdownKey))) {
                                              directPrelevementSelection.value =
                                                  {
                                                ...directPrelevementSelection
                                                    .value,
                                                dropdownKey:
                                                    selectedPrDocs.first.id,
                                              };
                                            }
                                            return ValueListenableBuilder<
                                                Map<String, String?>>(
                                              valueListenable:
                                                  directPrelevementSelection,
                                              builder:
                                                  (context, selections, _) {
                                                final selectedPrelevementId =
                                                    selections[dropdownKey]!;
                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    DropdownButton<String>(
                                                      value:
                                                          selectedPrelevementId,
                                                      items: selectedPrDocs
                                                          .map((prDoc) {
                                                        final prData =
                                                            prDoc.data() as Map<
                                                                String,
                                                                dynamic>;
                                                        final date = prData[
                                                                    'datePrelevement'] !=
                                                                null
                                                            ? (prData['datePrelevement']
                                                                    as Timestamp)
                                                                .toDate()
                                                            : null;
                                                        final quantite = prData[
                                                                'quantiteTotale'] ??
                                                            '?';
                                                        return DropdownMenuItem<
                                                            String>(
                                                          value: prDoc.id,
                                                          child: Text(
                                                              "${date != null ? "${date.day}/${date.month}/${date.year}" : prDoc.id} - ${quantite}kg"),
                                                        );
                                                      }).toList(),
                                                      onChanged: (val) {
                                                        if (val != null) {
                                                          directPrelevementSelection
                                                              .value = {
                                                            ...directPrelevementSelection
                                                                .value,
                                                            dropdownKey: val,
                                                          };
                                                        }
                                                      },
                                                      isExpanded: true,
                                                    ),
                                                    _buildCommercialDirectDetailsWithVentes(
                                                      context,
                                                      selectedPrDocs.firstWhere(
                                                          (prDoc) =>
                                                              prDoc.id ==
                                                              selectedPrelevementId),
                                                      lot,
                                                      lotId,
                                                      isMobile,
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          } else if (selectedPrDocs.length ==
                                              1) {
                                            return _buildCommercialDirectDetailsWithVentes(
                                              context,
                                              selectedPrDocs.first,
                                              lot,
                                              lotId,
                                              isMobile,
                                            );
                                          }
                                          return const SizedBox();
                                        },
                                      ),
                                  ],
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // --- Détail ventes pour un commercial/prélèvement donné ---
  Widget _buildDetailVentesCommercial({
    required BuildContext context,
    required String commercialId,
    required String prelevementId,
    required bool isMobile,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ventes')
          .doc(commercialId)
          .collection('ventes_effectuees')
          .where('prelevementId', isEqualTo: prelevementId)
          .snapshots(),
      builder: (context, ventesSnap) {
        if (!ventesSnap.hasData || ventesSnap.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(left: 8, top: 7),
            child: Text("Aucune vente pour ce prélèvement.",
                style: TextStyle(
                    fontStyle: FontStyle.italic, color: Colors.grey[700])),
          );
        }
        final ventes = ventesSnap.data!.docs
            .map((v) => v.data() as Map<String, dynamic>)
            .toList();
        final ventesParType = {
          "Comptant": <Map<String, dynamic>>[],
          "Crédit": <Map<String, dynamic>>[],
          "Recouvrement": <Map<String, dynamic>>[],
        };
        for (final v in ventes) {
          ventesParType[v['typeVente'] ?? 'Comptant']?.add(v);
        }

        Widget buildVenteTile(Map<String, dynamic> v, bool isMobile) {
          final dateVente = v['dateVente'] != null
              ? (v['dateVente'] as Timestamp).toDate()
              : null;
          final clientNomBoutique = v['clientNom'] ?? v['clientId'] ?? '';
          final quantite = (v['quantiteTotale'] ?? 0).toString();
          final montantTotal = v['montantTotal'] ?? v['prixTotal'] ?? 0;
          final montantPaye = v['montantPaye'] ?? 0;
          final montantRestant = v['montantRestant'] ?? 0;
          final typeVente = v['typeVente'] ?? '';
          final embVendus = v['emballagesVendus'] ?? v['emballages'] ?? [];

          Color badgeColor;
          Color textColor;
          switch (typeVente) {
            case "Comptant":
              badgeColor = Colors.green[100]!;
              textColor = Colors.green[800]!;
              break;
            case "Crédit":
              badgeColor = Colors.orange[100]!;
              textColor = Colors.orange[800]!;
              break;
            case "Recouvrement":
              badgeColor = Colors.blue[100]!;
              textColor = Colors.blue[800]!;
              break;
            default:
              badgeColor = Colors.grey[300]!;
              textColor = Colors.black;
          }

          return Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? 320.0 : 390.0,
              minWidth: isMobile ? 200.0 : 290.0,
            ),
            margin: const EdgeInsets.only(bottom: 14, right: 12),
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: badgeColor.withOpacity(0.13)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shopping_cart,
                        size: 18, color: Colors.blue[600]),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        dateVente != null
                            ? "${dateVente.day}/${dateVente.month}/${dateVente.year}"
                            : "?",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (clientNomBoutique != '') ...[
                      const SizedBox(width: 6),
                      Icon(Icons.store, size: 15, color: Colors.purple[200]),
                      Flexible(
                        child: Text(
                          "Client : $clientNomBoutique",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.scale, size: 16, color: Colors.teal),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        "$quantite kg",
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.attach_money, size: 16, color: Colors.orange),
                    Flexible(
                      child: Text(
                        " $montantTotal FCFA",
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 2),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: badgeColor,
                        ),
                        child: Text(
                          typeVente,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        "Payé: $montantPaye FCFA • Reste: $montantRestant FCFA",
                        style: const TextStyle(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ...embVendus.map<Widget>((emb) => Wrap(
                      children: [
                        Text(
                          "- ${emb['type']}: ${emb['nombre']} pots x ${emb['contenanceKg']}kg @ ${emb['prixUnitaire']} FCFA",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )),
              ],
            ),
          );
        }

        if (isMobile) {
          return Padding(
            padding: const EdgeInsets.only(left: 2, right: 2, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Ventes réalisées :",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 15)),
                const SizedBox(height: 6),
                SizedBox(
                  height: 250,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final type in ["Comptant", "Crédit", "Recouvrement"])
                        if (ventesParType[type]?.isNotEmpty ?? false)
                          Container(
                            width: 280,
                            margin: const EdgeInsets.only(right: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  margin: const EdgeInsets.only(bottom: 4),
                                  decoration: BoxDecoration(
                                    color: type == "Comptant"
                                        ? Colors.green[50]
                                        : type == "Crédit"
                                            ? Colors.orange[50]
                                            : Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    type,
                                    style: TextStyle(
                                      color: type == "Comptant"
                                          ? Colors.green[800]
                                          : type == "Crédit"
                                              ? Colors.orange[800]
                                              : Colors.blue[800],
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                ...ventesParType[type]!
                                    .map<Widget>((vente) =>
                                        buildVenteTile(vente, isMobile))
                                    .toList()
                              ],
                            ),
                          )
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(left: 10, right: 8, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Ventes réalisées :",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: 15)),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final type in ["Comptant", "Crédit", "Recouvrement"])
                    if (ventesParType[type]?.isNotEmpty ?? false)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: type == "Comptant"
                                    ? Colors.green[50]
                                    : type == "Crédit"
                                        ? Colors.orange[50]
                                        : Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  color: type == "Comptant"
                                      ? Colors.green[800]
                                      : type == "Crédit"
                                          ? Colors.orange[800]
                                          : Colors.blue[800],
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            ...ventesParType[type]!
                                .map<Widget>(
                                    (vente) => buildVenteTile(vente, isMobile))
                                .toList()
                          ],
                        ),
                      )
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSousPrelevementCommercialWithVentes(
    BuildContext context,
    QueryDocumentSnapshot subPrDoc,
    bool isMobile, {
    String? nomMagasinier,
    VoidCallback? onPrelevement,
    Map<String, dynamic>? lot,
  }) {
    final subData = subPrDoc.data() as Map<String, dynamic>;
    final subDate = subData['datePrelevement'] != null
        ? (subData['datePrelevement'] as Timestamp).toDate()
        : null;
    final bool demandeRestitution = subData['demandeRestitution'] == true;
    final bool approuveParMag =
        subData['magazinierApprobationRestitution'] == true;
    final String commercialNom =
        subData['commercialNom'] ?? subData['commercialId'] ?? '';
    final String prelevementId = subPrDoc.id;
    final String commercialId = subData['commercialId'] ?? '';
    final String nomMag =
        nomMagasinier ?? subData['magazinierApprobateurNom'] ?? '';
    final bool restitutionDemandee = demandeRestitution && !approuveParMag;
    final bool restitutionValidee = approuveParMag;

    // Calcul des restes
    Map<String, int> restesApresVente = {};
    double restesKg = 0.0;
    if (subData['restesApresVenteCommercial'] != null) {
      final m =
          Map<String, dynamic>.from(subData['restesApresVenteCommercial']);
      m.forEach((k, v) => restesApresVente[k] = (v as int));
      if (subData['emballages'] != null) {
        for (var emb in subData['emballages']) {
          if (restesApresVente.containsKey(emb['type'])) {
            restesKg += (restesApresVente[emb['type']] ?? 0) *
                (emb['contenanceKg'] ?? 0.0);
          }
        }
      }
    }

    return Card(
      color: Colors.orange[100],
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.orange[700]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Commercial: $commercialNom",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                if (restitutionValidee)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.green[300],
                        borderRadius: BorderRadius.circular(9)),
                    child: Row(
                      children: [
                        Icon(Icons.verified,
                            size: 16, color: Colors.green[900]),
                        const SizedBox(width: 4),
                        const Text("Restitution validée",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                        if (nomMag.isNotEmpty)
                          Text(" ($nomMag)",
                              style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  color: Colors.green)),
                      ],
                    ),
                  ),
              ],
            ),
            Text(
                "Prélèvement du ${subDate != null ? "${subDate.day}/${subDate.month}/${subDate.year}" : '?'}"),
            Text("Quantité: ${subData['quantiteTotale']} kg"),
            Text("Valeur: ${subData['prixTotalEstime']} FCFA"),
            if (subData['emballages'] != null)
              ...List.generate((subData['emballages'] as List).length, (j) {
                final emb = subData['emballages'][j];
                return Text(
                    "- ${emb['type']}: ${emb['nombre']} pots x ${emb['contenanceKg']}kg @ ${emb['prixUnitaire']} FCFA",
                    style: const TextStyle(fontSize: 13));
              }),
            _buildDetailVentesCommercial(
                context: context,
                commercialId: commercialId,
                prelevementId: prelevementId,
                isMobile: isMobile),
            if (restesApresVente.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.green[200]!)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.undo,
                                color: Colors.green[700], size: 20),
                            const SizedBox(width: 7),
                            Text("Restes réstitués :",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800])),
                            const SizedBox(width: 7),
                            Text("${restesKg.toStringAsFixed(2)} kg",
                                style: TextStyle(
                                    color: Colors.green[900],
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        ...restesApresVente.entries.map((e) => Text(
                            "${e.key}: ${e.value} pots",
                            style: const TextStyle(
                                fontSize: 13, color: Colors.green))),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            if (restitutionDemandee || restitutionValidee)
              Row(
                children: [
                  if (restitutionDemandee) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.orange[200],
                          borderRadius: BorderRadius.circular(10)),
                      child: const Text(
                        "En attente de validation de la restitution...",
                        style: TextStyle(
                            color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.verified),
                      label: Text("Valider la restitution de $commercialNom"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        // 1. Récupère toutes les ventes pour ce commercial/prélèvement
                        final ventesSnap = await FirebaseFirestore.instance
                            .collection('ventes')
                            .doc(commercialId)
                            .collection('ventes_effectuees')
                            .where('prelevementId', isEqualTo: prelevementId)
                            .get();
                        final ventes =
                            ventesSnap.docs.map((v) => v.data()).toList();

                        // 2. Calcul des pots vendus par type
                        Map<String, int> potsVendues = {};
                        for (final v in ventes) {
                          final embVendus =
                              v['emballagesVendus'] ?? v['emballages'] ?? [];
                          for (var emb in embVendus) {
                            final t = emb['type'];
                            final n = (emb['nombre'] ?? 0) as int;
                            potsVendues[t] = (potsVendues[t] ?? 0) + n;
                          }
                        }

                        // 3. Calcul des restes par type
                        Map<String, int> restesParType = {};
                        double restesKg = 0.0;
                        if (subData['emballages'] != null) {
                          for (var emb in subData['emballages']) {
                            final type = emb['type'];
                            final nInit = (emb['nombre'] ?? 0) as int;
                            final vendu = potsVendues[type] ?? 0;
                            final reste = nInit - vendu;
                            restesParType[type] = reste;
                            final contenance =
                                (emb['contenanceKg'] ?? 0.0).toDouble();
                            restesKg += reste * contenance;
                          }
                        }

                        await FirebaseFirestore.instance
                            .collection('prelevements')
                            .doc(subPrDoc.id)
                            .update({
                          'magazinierApprobationRestitution': true,
                          'magazinierApprobateurNom': nomMag,
                          'dateApprobationRestitution':
                              FieldValue.serverTimestamp(),
                          'restesApresVenteCommercial': restesParType,
                          'restantApresVenteCommercialKg': restesKg,
                        });
                        if (onPrelevement != null) onPrelevement();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Restitution du commercial validée avec succès !"),
                            backgroundColor: Colors.green[700],
                          ),
                        );
                        (context as Element).markNeedsBuild();
                      },
                    ),
                  ],
                  if (restitutionValidee)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.green[200],
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        "Restitution validée${nomMag.isNotEmpty ? " ($nomMag)" : ""}",
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(width: 12),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommercialDetailsSimple(
    BuildContext context,
    QueryDocumentSnapshot prDoc,
    bool isMobile, {
    required String nomMagasinier,
    VoidCallback? onPrelevement,
  }) {
    final d = prDoc.data() as Map<String, dynamic>;
    final datePr = d['datePrelevement'] != null
        ? (d['datePrelevement'] as Timestamp).toDate()
        : null;
    final prelevementId = prDoc.id;
    final commercialId = d['commercialId'];
    final demandeRestitution = d['demandeRestitution'] == true;
    final restitutionApprouvee = d['magazinierApprobationRestitution'] == true;

    return Card(
      color: Colors.orange[50],
      margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Infos principales du prélèvement ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_pin,
                              color: Colors.orange, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            "Commercial : ",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Flexible(
                            child: Text(
                              "${d['commercialNom'] ?? d['commercialId'] ?? ''}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Colors.brown, size: 17),
                          const SizedBox(width: 4),
                          Text(
                            "Prélèvement du : ",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            datePr != null
                                ? "${datePr.day}/${datePr.month}/${datePr.year}"
                                : '?',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.scale, color: Colors.teal, size: 18),
                          const SizedBox(width: 4),
                          Text("Quantité : ${d['quantiteTotale']} kg",
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.attach_money,
                              color: Colors.orange, size: 18),
                          const SizedBox(width: 4),
                          Text("Valeur : ${d['prixTotalEstime']} FCFA",
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10.0, top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Détail emballages :",
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.brown)),
                        ...((d['emballages'] ?? []) as List).map((emb) => Text(
                              "- ${emb['type']}: ${emb['nombre']} pots x ${emb['contenanceKg']}kg @ ${emb['prixUnitaire']} FCFA",
                              style: const TextStyle(fontSize: 12),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // --- SOUS SECTION VENTES DU COMMERCIAL (responsive) ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ventes')
                  .doc(commercialId)
                  .collection('ventes_effectuees')
                  .where('prelevementId', isEqualTo: prelevementId)
                  .snapshots(),
              builder: (context, ventesSnap) {
                if (!ventesSnap.hasData || ventesSnap.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 10, bottom: 8),
                    child: Text("Aucune vente enregistrée pour ce prélèvement.",
                        style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[700])),
                  );
                }
                final ventes = ventesSnap.data!.docs
                    .map((v) => v.data() as Map<String, dynamic>)
                    .toList();
                final ventesParType = {
                  "Comptant": <Map<String, dynamic>>[],
                  "Crédit": <Map<String, dynamic>>[],
                  "Recouvrement": <Map<String, dynamic>>[],
                };
                for (final v in ventes) {
                  ventesParType[v['typeVente'] ?? 'Comptant']?.add(v);
                }
                Map<String, int> potsVendues = {};
                for (final v in ventes) {
                  final embVendus =
                      v['emballagesVendus'] ?? v['emballages'] ?? [];
                  for (var emb in embVendus) {
                    final t = emb['type'];
                    final n = (emb['nombre'] ?? 0) as int;
                    potsVendues[t] = (potsVendues[t] ?? 0) + n;
                  }
                }
                Map<String, int> potsPreleves = {};
                if (d['emballages'] != null) {
                  for (var emb in d['emballages']) {
                    final t = emb['type'];
                    final n = (emb['nombre'] ?? 0) as int;
                    potsPreleves[t] = (potsPreleves[t] ?? 0) + n;
                  }
                }
                Map<String, int> potsRestes = {};
                for (final t in potsPreleves.keys) {
                  potsRestes[t] =
                      (potsPreleves[t] ?? 0) - (potsVendues[t] ?? 0);
                }

                Widget buildVenteTile(Map<String, dynamic> v) {
                  final dateVente = v['dateVente'] != null
                      ? (v['dateVente'] as Timestamp).toDate()
                      : null;
                  final clientId = v['clientId'] ?? '';
                  final quantite = (v['quantiteTotale'] ?? 0).toString();
                  final montantTotal = v['montantTotal'] ?? v['prixTotal'] ?? 0;
                  final montantPaye = v['montantPaye'] ?? 0;
                  final montantRestant = v['montantRestant'] ?? 0;
                  final typeVente = v['typeVente'] ?? '';
                  final embVendus =
                      v['emballagesVendus'] ?? v['emballages'] ?? [];
                  return Container(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? 320.0 : 390.0,
                      minWidth: isMobile ? 200.0 : 290.0,
                    ),
                    margin: const EdgeInsets.only(bottom: 14, right: 12),
                    padding:
                        const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.withOpacity(0.13)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shopping_cart,
                                size: 18, color: Colors.blue[600]),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                dateVente != null
                                    ? "${dateVente.day}/${dateVente.month}/${dateVente.year}"
                                    : "?",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (clientId.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.store,
                                  size: 15, color: Colors.purple[200]),
                              Flexible(
                                child: Text(
                                  "Client : $clientId",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.scale, size: 16, color: Colors.teal),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                "$quantite kg",
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.attach_money,
                                size: 16, color: Colors.orange),
                            Flexible(
                              child: Text(
                                " $montantTotal FCFA",
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2, bottom: 2),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: typeVente == "Comptant"
                                      ? Colors.green[100]
                                      : typeVente == "Crédit"
                                          ? Colors.orange[100]
                                          : typeVente == "Recouvrement"
                                              ? Colors.blue[100]
                                              : Colors.grey[300],
                                ),
                                child: Text(
                                  typeVente,
                                  style: TextStyle(
                                    color: typeVente == "Comptant"
                                        ? Colors.green[800]
                                        : typeVente == "Crédit"
                                            ? Colors.orange[800]
                                            : typeVente == "Recouvrement"
                                                ? Colors.blue[800]
                                                : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                "Payé: $montantPaye FCFA • Reste: $montantRestant FCFA",
                                style: const TextStyle(fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        ...embVendus.map<Widget>((emb) => Wrap(
                              children: [
                                Text(
                                  "- ${emb['type']}: ${emb['nombre']} pots x ${emb['contenanceKg']}kg @ ${emb['prixUnitaire']} FCFA",
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black87),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            )),
                      ],
                    ),
                  );
                }

                if (isMobile) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(left: 10, right: 8, bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Ventes réalisées :",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                fontSize: 15)),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 220,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final type in [
                                "Comptant",
                                "Crédit",
                                "Recouvrement"
                              ])
                                if (ventesParType[type]?.isNotEmpty ?? false)
                                  Container(
                                    width: 270,
                                    margin: const EdgeInsets.only(right: 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4, horizontal: 8),
                                          margin:
                                              const EdgeInsets.only(bottom: 4),
                                          decoration: BoxDecoration(
                                            color: type == "Comptant"
                                                ? Colors.green[50]
                                                : type == "Crédit"
                                                    ? Colors.orange[50]
                                                    : Colors.blue[50],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            type,
                                            style: TextStyle(
                                              color: type == "Comptant"
                                                  ? Colors.green[800]
                                                  : type == "Crédit"
                                                      ? Colors.orange[800]
                                                      : Colors.blue[800],
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        ...ventesParType[type]!
                                            .map<Widget>(
                                                (v) => buildVenteTile(v))
                                            .toList()
                                      ],
                                    ),
                                  ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text("Restes :",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
                        ...potsRestes.entries.map((e) => Text(
                              "${e.key}: ${e.value < 0 ? 0 : e.value} pots",
                              style: const TextStyle(fontSize: 13),
                            )),
                      ],
                    ),
                  );
                }
                // Desktop
                return Padding(
                  padding: const EdgeInsets.only(left: 10, right: 8, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Ventes réalisées :",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              fontSize: 15)),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final type in [
                            "Comptant",
                            "Crédit",
                            "Recouvrement"
                          ])
                            if (ventesParType[type]?.isNotEmpty ?? false)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 8),
                                      margin: const EdgeInsets.only(bottom: 4),
                                      decoration: BoxDecoration(
                                        color: type == "Comptant"
                                            ? Colors.green[50]
                                            : type == "Crédit"
                                                ? Colors.orange[50]
                                                : Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        type,
                                        style: TextStyle(
                                          color: type == "Comptant"
                                              ? Colors.green[800]
                                              : type == "Crédit"
                                                  ? Colors.orange[800]
                                                  : Colors.blue[800],
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    ...ventesParType[type]!
                                        .map<Widget>((v) => buildVenteTile(v))
                                        .toList()
                                  ],
                                ),
                              )
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text("Restes :",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red)),
                      ...potsRestes.entries.map((e) => Text(
                            "${e.key}: ${e.value < 0 ? 0 : e.value} pots",
                            style: const TextStyle(fontSize: 13),
                          )),
                    ],
                  ),
                );
              },
            ),
            // --- SECTION RESTITUTION et VALIDATION ---
            Padding(
              padding:
                  const EdgeInsets.only(left: 10, right: 8, bottom: 8, top: 4),
              child: Row(
                children: [
                  if (demandeRestitution && !restitutionApprouvee) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.orange[200],
                          borderRadius: BorderRadius.circular(10)),
                      child: const Text(
                        "En attente de validation de la restitution...",
                        style: TextStyle(
                            color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.verified),
                      label: Text(
                          "Valider la restitution de ${d['commercialNom'] ?? d['commercialId']}"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        // 1. Récupère toutes les ventes pour ce commercial/prélèvement
                        final ventesSnap = await FirebaseFirestore.instance
                            .collection('ventes')
                            .doc(commercialId)
                            .collection('ventes_effectuees')
                            .where('prelevementId', isEqualTo: prelevementId)
                            .get();
                        final ventes =
                            ventesSnap.docs.map((v) => v.data()).toList();

                        // 2. Calcul des pots vendus par type
                        Map<String, int> potsVendues = {};
                        for (final v in ventes) {
                          final embVendus =
                              v['emballagesVendus'] ?? v['emballages'] ?? [];
                          for (var emb in embVendus) {
                            final t = emb['type'];
                            final n = (emb['nombre'] ?? 0) as int;
                            potsVendues[t] = (potsVendues[t] ?? 0) + n;
                          }
                        }

                        // 3. Calcul des restes par type
                        Map<String, int> restesParType = {};
                        double restesKg = 0.0;
                        if (d['emballages'] != null) {
                          for (var emb in d['emballages']) {
                            final type = emb['type'];
                            final nInit = (emb['nombre'] ?? 0) as int;
                            final vendu = potsVendues[type] ?? 0;
                            final reste = nInit - vendu;
                            restesParType[type] = reste;
                            final contenance =
                                (emb['contenanceKg'] ?? 0.0).toDouble();
                            restesKg += reste * contenance;
                          }
                        }

                        await FirebaseFirestore.instance
                            .collection('prelevements')
                            .doc(prDoc.id)
                            .update({
                          'magazinierApprobationRestitution': true,
                          'magazinierApprobateurNom': nomMagasinier,
                          'dateApprobationRestitution':
                              FieldValue.serverTimestamp(),
                          'restesApresVenteCommercial': restesParType,
                          'restantApresVenteCommercialKg': restesKg,
                        });
                        if (onPrelevement != null) onPrelevement();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Restitution du commercial validée avec succès !"),
                            backgroundColor: Colors.green[700],
                          ),
                        );
                      },
                    ),
                  ],
                  if (restitutionApprouvee)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.green[200],
                          borderRadius: BorderRadius.circular(10)),
                      child: const Text(
                        "Restitution validée",
                        style: TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NO MORE: _buildValiderRestitutionCommercialButton

  Widget _buildCommercialDirectDetailsWithVentes(
    BuildContext context,
    QueryDocumentSnapshot prDoc,
    Map<String, dynamic> lot,
    String lotId,
    bool isMobile,
  ) {
    final prData = prDoc.data() as Map<String, dynamic>;
    final datePr = prData['datePrelevement'] != null
        ? (prData['datePrelevement'] as Timestamp).toDate()
        : null;
    final String commercialId = prData['commercialId'] ?? "";
    final String prelevementId = prDoc.id;
    final bool demandeRestitution = prData['demandeRestitution'] == true;
    final bool restitutionValidee =
        prData['magazinierApprobationRestitution'] == true;
    final String nomMagasinier = prData['magazinierApprobateurNom'] ?? "";

    // Cumuls des restes pour affichage "comme magasinier simple"
    Map<String, int> restesCumulCommerciaux = {};
    double restesKgTotal = 0.0;
    if (prData['restesApresVenteCommercial'] != null) {
      final m = Map<String, dynamic>.from(prData['restesApresVenteCommercial']);
      m.forEach((k, v) {
        restesCumulCommerciaux[k] =
            (restesCumulCommerciaux[k] ?? 0) + (v as int);
      });
    }
    if (prData['emballages'] != null) {
      for (var emb in prData['emballages']) {
        if (restesCumulCommerciaux.containsKey(emb['type'])) {
          restesKgTotal += (restesCumulCommerciaux[emb['type']] ?? 0) *
              (emb['contenanceKg'] ?? 0.0);
        }
      }
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('ventes')
          .doc(commercialId)
          .collection('ventes_effectuees')
          .where('prelevementId', isEqualTo: prelevementId)
          .get(),
      builder: (context, ventesSnap) {
        Map<String, int> potsRestantsParType = {};
        Map<String, int> potsInitials = {};
        if (prData['emballages'] != null) {
          for (var emb in prData['emballages']) {
            final t = emb['type'];
            final n = (emb['nombre'] ?? 0) as num;
            potsRestantsParType[t] = n.toInt();
            potsInitials[t] = n.toInt();
          }
        }
        if (ventesSnap.hasData) {
          for (final venteDoc in ventesSnap.data!.docs) {
            final vente = venteDoc.data() as Map<String, dynamic>;
            if (vente['emballagesVendus'] != null) {
              for (var emb in vente['emballagesVendus']) {
                final t = emb['type'];
                final n = (emb['nombre'] ?? 0) as num;
                potsRestantsParType[t] =
                    (potsRestantsParType[t] ?? 0) - n.toInt();
              }
            }
          }
          potsRestantsParType.updateAll((k, v) => v < 0 ? 0 : v);
        }

        return Card(
          color: Colors.green[50],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  leading: Icon(Icons.person, color: Colors.green[700]),
                  title: Text(
                    "Prélèvement commercial direct du ${datePr != null ? "${datePr.day}/${datePr.month}/${datePr.year}" : '?'}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "Commercial: ${prData['commercialNom'] ?? prData['commercialId'] ?? ''}"),
                      Text(
                          "Quantité: ${prData['quantiteTotale'] ?? '?'} kg, Valeur: ${prData['prixTotalEstime'] ?? '?'} FCFA"),
                      if (prData['emballages'] != null)
                        ...List.generate((prData['emballages'] as List).length,
                            (j) {
                          final emb = prData['emballages'][j];
                          return Text(
                            "- ${emb['type']}: ${emb['nombre']} pots x ${emb['contenanceKg']}kg @ ${emb['prixUnitaire']} FCFA",
                            style: const TextStyle(fontSize: 13),
                          );
                        }),
                      if (restesCumulCommerciaux.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 7, bottom: 2),
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(color: Colors.green[200]!)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.undo,
                                          color: Colors.green[700], size: 20),
                                      const SizedBox(width: 7),
                                      Text("Restes cumulés réstitués :",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[800])),
                                      const SizedBox(width: 7),
                                      Text(
                                          "${restesKgTotal.toStringAsFixed(2)} kg",
                                          style: TextStyle(
                                              color: Colors.green[900],
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  ...restesCumulCommerciaux.entries.map((e) =>
                                      Text(
                                          "${e.key}: ${e.value} pots",
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.green))),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 16),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Restes par type (pots non vendus) :",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ...potsRestantsParType.entries.map((e) => Text(
                            "${e.key} : ${e.value < 0 ? 0 : e.value} pots (${potsInitials[e.key] ?? 0} init.)",
                            style: const TextStyle(fontSize: 13),
                          )),
                    ],
                  ),
                ),
                if (demandeRestitution && !restitutionValidee)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.verified),
                      label:
                          const Text("Valider la restitution de ce commercial"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        minimumSize: Size(isMobile ? 130 : 200, 40),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('prelevements')
                            .doc(prelevementId)
                            .update({
                          'magazinierApprobationRestitution': true,
                          'magazinierApprobateurNom': nomMagasinier,
                          'dateApprobationRestitution':
                              FieldValue.serverTimestamp(),
                          'restesApresVenteCommercial': potsRestantsParType,
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Restitution validée !")),
                        );
                        (context as Element).markNeedsBuild();
                      },
                    ),
                  ),
                if (restitutionValidee)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.green[200],
                        borderRadius: BorderRadius.circular(16)),
                    child: Text(
                      "Restitution validée par le magasinier principal${nomMagasinier.isNotEmpty ? " : $nomMagasinier" : ""}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                _buildDetailVentesCommercial(
                  context: context,
                  commercialId: commercialId,
                  prelevementId: prelevementId,
                  isMobile: isMobile,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// --- Détail magasinier simple : résumé (sans les commerciaux enfants) ---
  Widget _buildMagasinierSimpleDetails(
    BuildContext context,
    QueryDocumentSnapshot prDoc,
    List<QueryDocumentSnapshot> sousPrelevs,
    Map<String, dynamic> lot,
    String lotId,
    bool isMobile, {
    Widget Function(bool, bool, String?, Map<String, dynamic>)?
        bottomExtrasBuilder,
  }) {
    final prData = prDoc.data() as Map<String, dynamic>;
    final datePr = prData['datePrelevement'] != null
        ? (prData['datePrelevement'] as Timestamp).toDate()
        : null;

    Map<String, int> restesCumulCommerciaux = {};
    final bool restitutionValideePrincipal =
        prData['magasinierPrincipalApprobationRestitution'] == true;
    final bool demandeRestitutionMagasinier =
        prData['demandeRestitutionMagasinier'] == true;
    final String? nomMagPrincipal = prData['magasinierPrincipalApprobateurNom'];

    // Calcule les restes cumulés
    if (restitutionValideePrincipal &&
        prData['restesApresVenteCommerciaux'] != null) {
      restesCumulCommerciaux =
          Map<String, int>.from(prData['restesApresVenteCommerciaux']);
    } else {
      for (final subPrDoc in sousPrelevs) {
        final subData = subPrDoc.data() as Map<String, dynamic>;
        if (subData['demandeRestitution'] == true &&
            subData['magazinierApprobationRestitution'] == true &&
            subData['restesApresVenteCommercial'] != null) {
          final m =
              Map<String, dynamic>.from(subData['restesApresVenteCommercial']);
          m.forEach((k, v) {
            restesCumulCommerciaux[k] =
                (restesCumulCommerciaux[k] ?? 0) + (v as int);
          });
        }
      }
    }

    double restesKgTotal = 0.0;
    if (prData['emballages'] != null) {
      for (var emb in prData['emballages']) {
        final type = emb['type'];
        final contenance = (emb['contenanceKg'] ?? 0.0).toDouble();
        if (restesCumulCommerciaux.containsKey(type)) {
          restesKgTotal += (restesCumulCommerciaux[type] ?? 0) * contenance;
        }
      }
    }

    // -------- BOUTON VALIDER RESTITUTION MAGASINIER SIMPLE --------
    Widget validationRestitutionWidget = const SizedBox.shrink();
    if (demandeRestitutionMagasinier && !restitutionValideePrincipal) {
      validationRestitutionWidget = Padding(
        padding: const EdgeInsets.only(top: 12, left: 0, right: 0, bottom: 4),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.verified),
          label: const Text('Valider la restitution'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            minimumSize: const Size(180, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('prelevements')
                .doc(prDoc.id)
                .update({
              'magasinierPrincipalApprobationRestitution': true,
              'magasinierPrincipalApprobateurNom':
                  nomMagPrincipal ?? "Magasinier Principal",
              'dateApprobationRestitutionPrincipal':
                  FieldValue.serverTimestamp(),
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Restitution validée avec succès !")),
            );
          },
        ),
      );
    } else if (restitutionValideePrincipal) {
      validationRestitutionWidget = Padding(
        padding: const EdgeInsets.only(top: 12, left: 0, right: 0, bottom: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            "Restitution validée par le magasinier principal${nomMagPrincipal != null && nomMagPrincipal.isNotEmpty ? " : $nomMagPrincipal" : ""}",
            style: const TextStyle(
                color: Colors.green, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else if (demandeRestitutionMagasinier && !restitutionValideePrincipal) {
      validationRestitutionWidget = Padding(
        padding: const EdgeInsets.only(top: 12, left: 0, right: 0, bottom: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Text(
            "En attente de validation du magasinier principal...",
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    // -------- BOUTON TELECHARGER RAPPORT GLOBAL MAG SIMPLE --------
    Widget telechargerRapportWidget = Padding(
      padding: const EdgeInsets.only(top: 8, left: 0, right: 0),
      child: TelechargerRapportBouton(
        prelevement: {...prData, 'id': prDoc.id}, // <-- AJOUTE L'ID !
        lot: {...lot, 'id': lotId}, // <-- AJOUTE 'id' dans le lot !
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: Icon(Icons.shopping_bag, color: Colors.blue[700]),
          title: Text(
            "Prélèvement mag simple du ${datePr != null ? "${datePr.day}/${datePr.month}/${datePr.year}" : '?'}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "Magasinier destinataire: ${prData['magasinierDestNom'] ?? ''}"),
              Text(
                  "Quantité: ${prData['quantiteTotale'] ?? '?'} kg, Valeur: ${prData['prixTotalEstime'] ?? '?'} FCFA"),
              if (prData['emballages'] != null)
                ...List.generate((prData['emballages'] as List).length, (j) {
                  final emb = prData['emballages'][j];
                  return Text(
                    "- ${emb['type']}: ${emb['nombre']} pots x ${emb['contenanceKg']}kg @ ${emb['prixUnitaire']} FCFA",
                    style: const TextStyle(fontSize: 13),
                  );
                }),
              if (restesCumulCommerciaux.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 7, bottom: 2),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: Colors.green[200]!)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.undo,
                                  color: Colors.green[700], size: 20),
                              const SizedBox(width: 7),
                              Text("Restes cumulés réstitués :",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800])),
                              const SizedBox(width: 7),
                              Text("${restesKgTotal.toStringAsFixed(2)} kg",
                                  style: TextStyle(
                                      color: Colors.green[900],
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          ...restesCumulCommerciaux.entries.map((e) => Text(
                              "${e.key}: ${e.value} pots",
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.green))),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        validationRestitutionWidget,
        telechargerRapportWidget,
        if (bottomExtrasBuilder != null) const SizedBox(height: 14),
        if (bottomExtrasBuilder != null)
          bottomExtrasBuilder(
            demandeRestitutionMagasinier,
            restitutionValideePrincipal,
            nomMagPrincipal,
            prData,
          ),
      ],
    );
  }

// ... Tes fonctions _buildMagasinierSimpleDetails, _buildSousPrelevementCommercialWithVentes, etc., restent inchangées ! ...
}

/// COMMERCIAL PAGE

class CommercialPage extends StatefulWidget {
  const CommercialPage({super.key});

  @override
  State<CommercialPage> createState() => _CommercialPageState();
}

class _CommercialPageState extends State<CommercialPage> {
  DateTime? _dateStart;
  DateTime? _dateEnd;
  String? _selectedLot;
  String? _selectedMagasinier;

  // Pour stocker le mapping lotConditionnementId -> lotOrigine (numéro du lot)
  Map<String, String> lotNumMap = {};

  // Pour éviter de multiples fetchs simultanés
  bool lotsFetched = false;

  Future<void> fetchLotNumMap(List<QueryDocumentSnapshot> prelevsRaw) async {
    final ids = prelevsRaw
        .map((doc) =>
            (doc.data() as Map<String, dynamic>)['lotConditionnementId']
                ?.toString() ??
            '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (ids.isEmpty) return;

    Map<String, String> newMap = {};
    for (final id in ids) {
      if (lotNumMap.containsKey(id)) continue;
      final doc = await FirebaseFirestore.instance
          .collection('conditionnement')
          .doc(id)
          .get();
      if (doc.exists) {
        final map = doc.data();
        if (map != null && map['lotOrigine'] != null) {
          newMap[id] = map['lotOrigine'].toString();
        }
      }
    }
    if (mounted) {
      setState(() {
        lotNumMap.addAll(newMap);
        lotsFetched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text("Utilisateur non identifié !"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('prelevements')
          .where('commercialId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Aucun prélèvement attribué."));
        }

        final prelevsRaw = snapshot.data!.docs;

        // On fetch le mapping lotId -> lotOrigine
        if (!lotsFetched) {
          fetchLotNumMap(prelevsRaw);
        }

        // --- Extraction des lots (numéros) et magasiniers pour les filtres ---
        final lotsDisponibles = <String>{};
        final lotsLabels = <String, String>{};
        final magasiniersDisponibles = <String>{};
        for (final doc in prelevsRaw) {
          final pr = doc.data() as Map<String, dynamic>;
          final lotId = pr['lotConditionnementId']?.toString() ?? '';
          final lotNum = lotNumMap[lotId] ?? lotId; // Numéro du lot sinon id
          lotsDisponibles.add(lotNum);
          lotsLabels[lotNum] = lotNum;
          final magazinierNom = pr['magasinierNom']?.toString() ?? '';
          magasiniersDisponibles.add(magazinierNom);
        }

        // --- APPLICATION DES FILTRES ---
        List<QueryDocumentSnapshot> prelevs = prelevsRaw.where((doc) {
          final pr = doc.data() as Map<String, dynamic>;
          final lotId = pr['lotConditionnementId']?.toString() ?? '';
          final lotNum = lotNumMap[lotId] ?? lotId;
          final magazinierNom = pr['magasinierNom']?.toString() ?? '';
          DateTime? date = pr['datePrelevement'] != null
              ? (pr['datePrelevement'] as Timestamp).toDate()
              : null;
          bool matchLot = _selectedLot == null || _selectedLot == lotNum;
          bool matchMag = _selectedMagasinier == null ||
              _selectedMagasinier == magazinierNom;
          bool matchDate = true;
          if (_dateStart != null) {
            matchDate = date != null && !date.isBefore(_dateStart!);
          }
          if (matchDate && _dateEnd != null) {
            matchDate = date != null && !date.isAfter(_dateEnd!);
          }
          return matchLot && matchMag && matchDate;
        }).toList();

        // --- TRI PAR DATE DESC ---
        prelevs.sort((a, b) {
          final aD = (a['datePrelevement'] as Timestamp?)?.toDate();
          final bD = (b['datePrelevement'] as Timestamp?)?.toDate();
          if (aD == null && bD == null) return 0;
          if (bD == null) return -1;
          if (aD == null) return 1;
          return bD.compareTo(aD);
        });

        // --- GROUPEMENT PAR MOIS ---
        Map<String, List<QueryDocumentSnapshot>> groupes = {};
        for (final doc in prelevs) {
          final pr = doc.data() as Map<String, dynamic>;
          DateTime? date = pr['datePrelevement'] != null
              ? (pr['datePrelevement'] as Timestamp).toDate()
              : null;
          final key = date != null
              ? "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}"
              : "Inconnu";
          groupes.putIfAbsent(key, () => []);
          groupes[key]!.add(doc);
        }
        final sortedKeys = groupes.keys.toList()
          ..sort((a, b) => b.compareTo(a)); // mois récent d'abord

        // --- UI DES FILTRES ---
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Wrap(
                runSpacing: 8,
                spacing: 8,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Sélecteur d'intervalle de dates
                  ElevatedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _dateStart == null && _dateEnd == null
                          ? "Filtrer par date"
                          : "${_dateStart != null ? "${_dateStart!.day}/${_dateStart!.month}/${_dateStart!.year}" : "..."} - ${_dateEnd != null ? "${_dateEnd!.day}/${_dateEnd!.month}/${_dateEnd!.year}" : "..."}",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                    ),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(now.year - 3),
                        lastDate: DateTime(now.year + 3),
                        initialDateRange: _dateStart != null && _dateEnd != null
                            ? DateTimeRange(start: _dateStart!, end: _dateEnd!)
                            : null,
                      );
                      if (picked != null) {
                        setState(() {
                          _dateStart = picked.start;
                          _dateEnd = picked.end;
                        });
                      }
                    },
                  ),
                  if (_dateStart != null || _dateEnd != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      tooltip: "Réinitialiser la date",
                      onPressed: () => setState(() {
                        _dateStart = null;
                        _dateEnd = null;
                      }),
                    ),
                  // Sélecteur de lot (numéro)
                  DropdownButton<String>(
                    value: _selectedLot,
                    hint: const Text("Tous les lots"),
                    style: TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.w500),
                    borderRadius: BorderRadius.circular(13),
                    underline: const SizedBox(),
                    icon: const Icon(Icons.local_offer),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text("Tous les lots")),
                      ...lotsDisponibles.map((lotNum) => DropdownMenuItem(
                            value: lotNum,
                            child: Text(lotsLabels[lotNum] ?? lotNum),
                          ))
                    ],
                    onChanged: (v) => setState(() => _selectedLot = v),
                  ),
                  // Sélecteur de magasinier
                  DropdownButton<String>(
                    value: _selectedMagasinier,
                    hint: const Text("Tous les magasiniers"),
                    style: TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.w500),
                    borderRadius: BorderRadius.circular(13),
                    underline: const SizedBox(),
                    icon: const Icon(Icons.store),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text("Tous les magasiniers")),
                      ...magasiniersDisponibles.map((mag) => DropdownMenuItem(
                            value: mag,
                            child: Text(mag),
                          ))
                    ],
                    onChanged: (v) => setState(() => _selectedMagasinier = v),
                  ),
                  if (_selectedLot != null || _selectedMagasinier != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      tooltip: "Réinitialiser les filtres",
                      onPressed: () => setState(() {
                        _selectedLot = null;
                        _selectedMagasinier = null;
                      }),
                    ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 18, top: 4, right: 18, bottom: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Affichés: ${prelevs.length} / ${prelevsRaw.length}",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ),
            const Divider(height: 2),
            Expanded(
              child: prelevs.isEmpty
                  ? const Center(child: Text("Aucun prélèvement trouvé."))
                  : ListView.separated(
                      padding: const EdgeInsets.all(10),
                      itemCount: sortedKeys.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 7),
                      itemBuilder: (context, i) {
                        final key = sortedKeys[i];
                        final mois = key == "Inconnu"
                            ? "Date inconnue"
                            : "${_moisFr(int.parse(key.substring(5, 7)))} ${key.substring(0, 4)}";
                        final items = groupes[key]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 7, horizontal: 2),
                              child: Text(mois,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey)),
                            ),
                            ...List.generate(items.length, (j) {
                              final prelevDoc = items[j];
                              final pr =
                                  prelevDoc.data() as Map<String, dynamic>;
                              final prId = prelevDoc.id;
                              final datePr = pr['datePrelevement'] != null
                                  ? (pr['datePrelevement'] as Timestamp)
                                      .toDate()
                                  : null;
                              final lotId =
                                  pr['lotConditionnementId']?.toString() ?? '';
                              final lotNum = lotNumMap[lotId] ?? lotId;
                              final magazinierNom =
                                  pr['magasinierNom']?.toString() ?? '';

                              return FutureBuilder<DocumentSnapshot>(
                                future: pr['lotConditionnementId'] != null
                                    ? FirebaseFirestore.instance
                                        .collection('conditionnement')
                                        .doc(pr['lotConditionnementId'])
                                        .get()
                                    : Future.value(null),
                                builder: (context, lotSnap) {
                                  String lotLabel = lotNum;
                                  if (lotSnap.hasData &&
                                      lotSnap.data?.data() != null) {
                                    final lotData = lotSnap.data!.data()
                                        as Map<String, dynamic>;
                                    lotLabel =
                                        lotData['lotOrigine'] ?? lotLabel;
                                  }

                                  return StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('ventes')
                                        .doc(userId)
                                        .collection('ventes_effectuees')
                                        .where('prelevementId', isEqualTo: prId)
                                        .snapshots(),
                                    builder: (context, ventesSnap) {
                                      double quantitePrelevee =
                                          (pr['quantiteTotale'] ?? 0.0)
                                              .toDouble();
                                      double montantEstime =
                                          (pr['prixTotalEstime'] ?? 0.0)
                                              .toDouble();
                                      double quantiteVendue = 0.0;
                                      double montantVendu = 0.0;

                                      Map<String, int> potsRestantsParType = {};
                                      Map<String, int> potsInitials = {};

                                      if (pr['emballages'] != null) {
                                        for (var emb in pr['emballages']) {
                                          potsRestantsParType[emb['type']] =
                                              emb['nombre'];
                                          potsInitials[emb['type']] =
                                              emb['nombre'];
                                        }
                                      }

                                      List<QueryDocumentSnapshot> ventesDocs =
                                          ventesSnap.data?.docs.toList() ?? [];
                                      Map<String, List<QueryDocumentSnapshot>>
                                          ventesByType = {
                                        "Comptant": [],
                                        "Crédit": [],
                                        "Recouvrement": [],
                                      };
                                      for (var vd in ventesDocs) {
                                        final v =
                                            vd.data() as Map<String, dynamic>;
                                        if (v['typeVente'] == "Comptant") {
                                          ventesByType["Comptant"]!.add(vd);
                                        } else if (v['typeVente'] == "Crédit") {
                                          ventesByType["Crédit"]!.add(vd);
                                        } else if (v['typeVente'] ==
                                            "Recouvrement") {
                                          ventesByType["Recouvrement"]!.add(vd);
                                        }
                                      }

                                      if (ventesSnap.hasData) {
                                        for (final vDoc
                                            in ventesSnap.data!.docs) {
                                          final vente = vDoc.data()
                                              as Map<String, dynamic>;
                                          quantiteVendue +=
                                              (vente['quantiteTotale'] ?? 0.0)
                                                  .toDouble();
                                          montantVendu +=
                                              (vente['montantTotal'] ?? 0.0)
                                                  .toDouble();
                                          if (vente['emballagesVendus'] !=
                                              null) {
                                            for (var emb
                                                in vente['emballagesVendus']) {
                                              final t = emb['type'];
                                              potsRestantsParType[t] =
                                                  (potsRestantsParType[t] ??
                                                          0) -
                                                      ((emb['nombre'] ?? 0)
                                                              as num)
                                                          .toInt();
                                            }
                                          }
                                        }
                                      }
                                      final quantiteRestante =
                                          quantitePrelevee - quantiteVendue;
                                      final montantRestant =
                                          montantEstime - montantVendu;

                                      final bool demandeTerminee =
                                          pr['demandeRestitution'] == true;
                                      final bool approuveParMag =
                                          pr['magazinierApprobationRestitution'] ==
                                              true;
                                      final String? nomMagApprobateur =
                                          pr['magasinierApprobateurNom'];

                                      return StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('transactions_caissier')
                                            .where('prelevementId',
                                                isEqualTo: prId)
                                            .snapshots(),
                                        builder: (context, txnSnap) {
                                          final transactionCaissierExiste =
                                              txnSnap.hasData &&
                                                  txnSnap.data!.docs.isNotEmpty;

                                          Map<String, bool> ventesValidees = {};
                                          int ventesEnvoyees = 0;
                                          int ventesValideesCount = 0;
                                          for (final vDoc in ventesDocs) {
                                            final v = vDoc.data()
                                                as Map<String, dynamic>;
                                            if ((v['envoyeAuCaissier'] ??
                                                    false) ==
                                                true) {
                                              ventesEnvoyees++;
                                              if (v['transfertValideParCaissier'] ==
                                                  true) {
                                                ventesValideesCount++;
                                                ventesValidees[vDoc.id] = true;
                                              } else {
                                                ventesValidees[vDoc.id] = false;
                                              }
                                            }
                                          }
                                          final toutesVentesValidees =
                                              ventesEnvoyees > 0 &&
                                                  ventesValideesCount ==
                                                      ventesEnvoyees;
                                          final toutesVentesEnvoyees = ventesDocs
                                                  .isNotEmpty &&
                                              ventesDocs.every((v) =>
                                                  ((v.data() as Map<String,
                                                              dynamic>)[
                                                          'envoyeAuCaissier'] ??
                                                      false) ==
                                                  true);

                                          Widget buildValidCaissierWidget() {
                                            if (approuveParMag &&
                                                transactionCaissierExiste) {
                                              if (ventesEnvoyees == 0) {
                                                return const SizedBox.shrink();
                                              }
                                              if (toutesVentesValidees) {
                                                return Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                                  decoration: BoxDecoration(
                                                      color: Colors.green[200],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16)),
                                                  child: const Text(
                                                    "Toutes les ventes validées par le caissier !",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.green),
                                                  ),
                                                );
                                              }
                                              if (ventesValideesCount > 0) {
                                                return Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                                  decoration: BoxDecoration(
                                                      color: Colors.orange[200],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16)),
                                                  child: Text(
                                                    "$ventesValideesCount vente(s) validée(s) sur $ventesEnvoyees !",
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.orange),
                                                  ),
                                                );
                                              }
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 5),
                                                decoration: BoxDecoration(
                                                    color: Colors.orange[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16)),
                                                child: const Text(
                                                    "En attente de validation du caissier !!",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.orange)),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          }

                                          final typeList = ventesByType.entries
                                              .where((e) => e.value.isNotEmpty)
                                              .map((e) => e.key)
                                              .toList();
                                          final ValueNotifier<String>
                                              selectedType =
                                              ValueNotifier<String>(
                                                  typeList.isNotEmpty
                                                      ? typeList.first
                                                      : "");

                                          return Card(
                                            color: Colors.orange[50],
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  ListTile(
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                    leading: Icon(
                                                        Icons.shopping_bag,
                                                        color:
                                                            Colors.blue[700]),
                                                    title: Text(
                                                      "Prélèvement du ${datePr != null ? "${datePr.day}/${datePr.month}/${datePr.year}" : '?'}",
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    subtitle: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text("Lot: $lotLabel"),
                                                        Text(
                                                            "Magasinier: $magazinierNom"),
                                                        Text(
                                                            "Total prélevé: ${pr['quantiteTotale'] ?? '?'} kg"),
                                                        Text(
                                                            "Montant estimé: ${pr['prixTotalEstime'] ?? '?'} FCFA"),
                                                        if (pr['emballages'] !=
                                                            null)
                                                          ...List.generate(
                                                              (pr['emballages']
                                                                      as List)
                                                                  .length, (j) {
                                                            final emb =
                                                                pr['emballages']
                                                                    [j];
                                                            return Text(
                                                              "- ${emb['type']}: ${emb['nombre']} pots x ${emb['contenanceKg']}kg @ ${emb['prixUnitaire']} FCFA",
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          13),
                                                            );
                                                          }),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  buildValidCaissierWidget(),
                                                  if (typeList.length > 1)
                                                    Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 8.0,
                                                          horizontal: 5),
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.filter_alt,
                                                              color: Colors
                                                                  .purple[400]),
                                                          const SizedBox(
                                                              width: 8),
                                                          const Text(
                                                            "Type de vente : ",
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 15),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child:
                                                                ValueListenableBuilder<
                                                                    String>(
                                                              valueListenable:
                                                                  selectedType,
                                                              builder: (context,
                                                                  typeSelected,
                                                                  _) {
                                                                return DropdownButton<
                                                                    String>(
                                                                  value:
                                                                      typeSelected,
                                                                  isExpanded:
                                                                      true,
                                                                  items: typeList
                                                                      .map((t) => DropdownMenuItem<String>(
                                                                            value:
                                                                                t,
                                                                            child:
                                                                                Text(
                                                                              t,
                                                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                                                            ),
                                                                          ))
                                                                      .toList(),
                                                                  onChanged:
                                                                      (val) {
                                                                    if (val !=
                                                                        null) {
                                                                      selectedType
                                                                              .value =
                                                                          val;
                                                                    }
                                                                  },
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ValueListenableBuilder<
                                                      String>(
                                                    valueListenable:
                                                        selectedType,
                                                    builder: (context,
                                                        typeSelected, _) {
                                                      final ventes = ventesByType[
                                                              typeSelected] ??
                                                          [];
                                                      if (ventes.isEmpty) {
                                                        return const Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  18.0),
                                                          child: Text(
                                                            "Aucune vente pour ce type.",
                                                            style: TextStyle(
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                                color: Colors
                                                                    .grey),
                                                          ),
                                                        );
                                                      }
                                                      return Column(
                                                        children:
                                                            ventes.map<Widget>(
                                                          (venteDoc) {
                                                            final vente =
                                                                venteDoc.data()
                                                                    as Map<
                                                                        String,
                                                                        dynamic>;
                                                            final dateV = vente[
                                                                        'dateVente'] !=
                                                                    null
                                                                ? (vente['dateVente']
                                                                        is Timestamp
                                                                    ? (vente['dateVente']
                                                                            as Timestamp)
                                                                        .toDate()
                                                                    : DateTime.tryParse(
                                                                        vente['dateVente']
                                                                            .toString()))
                                                                : null;
                                                            final clientName = vente[
                                                                    'clientNom'] ??
                                                                vente[
                                                                    'clientId'] ??
                                                                '';
                                                            final montant =
                                                                vente['montantTotal'] ??
                                                                    0;
                                                            final montantPaye =
                                                                vente['montantPaye'] ??
                                                                    0;
                                                            final montantRestant =
                                                                vente['montantRestant'] ??
                                                                    0;
                                                            final approuveCaissier =
                                                                vente['transfertValideParCaissier'] ==
                                                                    true;
                                                            final etatCredit =
                                                                vente[
                                                                    'etatCredit'];
                                                            final typeVente =
                                                                vente['typeVente'] ??
                                                                    '';
                                                            final emballages =
                                                                vente['emballagesVendus']
                                                                    as List?;
                                                            final detailsEmballage =
                                                                emballages !=
                                                                        null
                                                                    ? emballages
                                                                        .map((e) =>
                                                                            "- ${e['type']}: ${e['nombre']} pots")
                                                                        .join(
                                                                            "\n")
                                                                    : "";

                                                            Color chipColor =
                                                                Colors.orange;
                                                            String chipLabel =
                                                                "En attente";
                                                            if (approuveCaissier) {
                                                              chipColor =
                                                                  Colors.green;
                                                              chipLabel =
                                                                  "Validée par le caissier";
                                                            } else if ((typeVente ==
                                                                        "Crédit" ||
                                                                    typeVente ==
                                                                        "Recouvrement") &&
                                                                etatCredit ==
                                                                    'partiel') {
                                                              chipColor =
                                                                  Colors.orange;
                                                              chipLabel =
                                                                  "Crédit partiellement remboursé";
                                                            } else if ((typeVente ==
                                                                        "Crédit" ||
                                                                    typeVente ==
                                                                        "Recouvrement") &&
                                                                etatCredit ==
                                                                    'remboursé') {
                                                              chipColor =
                                                                  Colors.green;
                                                              chipLabel =
                                                                  "Crédit remboursé";
                                                            }

                                                            return Card(
                                                              margin:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          7,
                                                                      horizontal:
                                                                          3),
                                                              elevation: 1,
                                                              shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              13)),
                                                              child: Padding(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    vertical: 7,
                                                                    horizontal:
                                                                        12),
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Row(
                                                                      children: [
                                                                        Icon(
                                                                          approuveCaissier
                                                                              ? Icons.verified
                                                                              : Icons.pending_actions,
                                                                          color: approuveCaissier
                                                                              ? Colors.green
                                                                              : Colors.orange,
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                10),
                                                                        Text(
                                                                          "${typeVente.toString().toUpperCase()}",
                                                                          style:
                                                                              TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color: approuveCaissier
                                                                                ? Colors.green[700]
                                                                                : Colors.orange[700],
                                                                            fontSize:
                                                                                15,
                                                                          ),
                                                                        ),
                                                                        const Spacer(),
                                                                        Chip(
                                                                          label: Text(
                                                                              chipLabel,
                                                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                                          backgroundColor:
                                                                              chipColor,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            6),
                                                                    Text(
                                                                        "Vente du ${dateV != null ? "${dateV.day}/${dateV.month}/${dateV.year}" : "?"}",
                                                                        style: const TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.w600)),
                                                                    Text(
                                                                        "Client: $clientName"),
                                                                    Text(
                                                                        "Qté vendue: ${vente['quantiteTotale'] ?? '?'} kg"),
                                                                    Text(
                                                                        "Montant: $montant FCFA"),
                                                                    if (detailsEmballage
                                                                        .isNotEmpty)
                                                                      Padding(
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            top:
                                                                                4.0,
                                                                            bottom:
                                                                                2),
                                                                        child: Text(
                                                                            "Emballages:\n$detailsEmballage"),
                                                                      ),
                                                                    Row(
                                                                      children: [
                                                                        Icon(
                                                                            Icons
                                                                                .check_circle,
                                                                            size:
                                                                                16,
                                                                            color:
                                                                                Colors.green[300]),
                                                                        const SizedBox(
                                                                            width:
                                                                                4),
                                                                        Text(
                                                                            "Payé: "),
                                                                        Text(
                                                                            "$montantPaye FCFA",
                                                                            style:
                                                                                const TextStyle(fontWeight: FontWeight.bold)),
                                                                        const SizedBox(
                                                                            width:
                                                                                20),
                                                                        Icon(
                                                                            Icons
                                                                                .cancel,
                                                                            size:
                                                                                16,
                                                                            color:
                                                                                Colors.red[200]),
                                                                        const SizedBox(
                                                                            width:
                                                                                4),
                                                                        Text(
                                                                            "Restant: "),
                                                                        Text(
                                                                            "$montantRestant FCFA",
                                                                            style:
                                                                                const TextStyle(fontWeight: FontWeight.bold)),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ).toList(),
                                                      );
                                                    },
                                                  ),
                                                  const Divider(height: 30),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 8),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                            "Restant à vendre: ${quantiteRestante < 0 ? 0 : quantiteRestante.toStringAsFixed(2)} kg"),
                                                        Text(
                                                            "Montant restant: ${montantRestant < 0 ? 0 : montantRestant.toStringAsFixed(0)} FCFA"),
                                                        ...potsRestantsParType
                                                            .entries
                                                            .map(
                                                          (e) => Text(
                                                            "${e.key}: ${e.value < 0 ? 0 : e.value} pots restants",
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        13),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 7),
                                                        if (demandeTerminee &&
                                                            !approuveParMag)
                                                          Row(
                                                            children: [
                                                              Container(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        10,
                                                                    vertical:
                                                                        5),
                                                                decoration: BoxDecoration(
                                                                    color: Colors
                                                                            .orange[
                                                                        200],
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            16)),
                                                                child: const Text(
                                                                    "En demande d'approbation",
                                                                    style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold,
                                                                        color: Colors
                                                                            .orange)),
                                                              ),
                                                            ],
                                                          ),
                                                        if (approuveParMag &&
                                                            !transactionCaissierExiste &&
                                                            !toutesVentesEnvoyees)
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 12.0),
                                                            child:
                                                                ElevatedButton
                                                                    .icon(
                                                              icon: const Icon(Icons
                                                                  .account_balance),
                                                              label: const Text(
                                                                  "Virer au caissier"),
                                                              style:
                                                                  ElevatedButton
                                                                      .styleFrom(
                                                                backgroundColor:
                                                                    Colors.blue[
                                                                        700],
                                                                foregroundColor:
                                                                    Colors
                                                                        .white,
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              13),
                                                                ),
                                                              ),
                                                              onPressed:
                                                                  () async {
                                                                final ventesSnap = await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        'ventes')
                                                                    .doc(userId)
                                                                    .collection(
                                                                        'ventes_effectuees')
                                                                    .where(
                                                                        'prelevementId',
                                                                        isEqualTo:
                                                                            prId)
                                                                    .get();
                                                                final venteIds =
                                                                    <String>[];
                                                                for (final doc
                                                                    in ventesSnap
                                                                        .docs) {
                                                                  venteIds.add(
                                                                      doc.id);
                                                                  await doc
                                                                      .reference
                                                                      .update({
                                                                    'envoyeAuCaissier':
                                                                        true,
                                                                    'dateTransfertCaissier':
                                                                        FieldValue
                                                                            .serverTimestamp(),
                                                                    'transfertValideParCaissier':
                                                                        false,
                                                                  });
                                                                }
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        'transactions_caissier')
                                                                    .add({
                                                                  'prelevementId':
                                                                      prId,
                                                                  'commercialId':
                                                                      userId,
                                                                  'magasinierId':
                                                                      pr['magasinierId'],
                                                                  'magasinierNom':
                                                                      pr['magasinierNom'],
                                                                  'lotConditionnementId':
                                                                      pr['lotConditionnementId'],
                                                                  'dateTransfertCaissier':
                                                                      FieldValue
                                                                          .serverTimestamp(),
                                                                  'venteIds':
                                                                      venteIds,
                                                                  'transfertValideParCaissier':
                                                                      false,
                                                                });
                                                                setState(() {});
                                                              },
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (!demandeTerminee)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 12),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .end,
                                                        children: [
                                                          ElevatedButton.icon(
                                                            icon: const Icon(Icons
                                                                .shopping_cart),
                                                            label: const Text(
                                                                "Vendre"),
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor:
                                                                  quantiteRestante >
                                                                          0
                                                                      ? Colors.blue[
                                                                          700]
                                                                      : Colors
                                                                          .grey,
                                                            ),
                                                            onPressed:
                                                                quantiteRestante >
                                                                        0
                                                                    ? () async {
                                                                        final result = await Get.to(() =>
                                                                            VenteFormPage(
                                                                              prelevement: {
                                                                                ...pr,
                                                                                "id": prId,
                                                                                "emballages": pr['emballages'] ?? [],
                                                                              },
                                                                            ));
                                                                        if (result ==
                                                                            true)
                                                                          setState(
                                                                              () {});
                                                                      }
                                                                    : null,
                                                          ),
                                                          const SizedBox(
                                                              width: 16),
                                                          ElevatedButton.icon(
                                                            icon: const Icon(Icons
                                                                .assignment_turned_in),
                                                            label: const Text(
                                                                "Terminer et restituer le reste"),
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor:
                                                                  Colors
                                                                      .red[700],
                                                            ),
                                                            onPressed:
                                                                () async {
                                                              await FirebaseFirestore
                                                                  .instance
                                                                  .collection(
                                                                      'prelevements')
                                                                  .doc(prId)
                                                                  .update({
                                                                'demandeRestitution':
                                                                    true,
                                                                'dateDemandeRestitution':
                                                                    FieldValue
                                                                        .serverTimestamp(),
                                                              });
                                                              setState(() {});
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 9,
                                                        horizontal: 15),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        PopupMenuButton<String>(
                                                          icon: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: const [
                                                              Icon(Icons
                                                                  .download),
                                                              SizedBox(
                                                                  width: 6),
                                                              Text(
                                                                  "Télécharger reçu de ventes"),
                                                            ],
                                                          ),
                                                          itemBuilder:
                                                              (context) => [
                                                            PopupMenuItem(
                                                              value: "all",
                                                              child: const Text(
                                                                  "Tous les reçus de ventes"),
                                                            ),
                                                            PopupMenuItem(
                                                              value: "last",
                                                              child: const Text(
                                                                  "Dernier reçu de vente"),
                                                            ),
                                                          ],
                                                          onSelected: (val) {
                                                            if (val == "all" ||
                                                                val == "last") {
                                                              Navigator.of(
                                                                      context)
                                                                  .push(
                                                                      MaterialPageRoute(
                                                                builder: (ctx) =>
                                                                    VenteReceiptsPage(
                                                                  commercialId:
                                                                      userId,
                                                                  prelevementId:
                                                                      prId,
                                                                  showLastOnly:
                                                                      val ==
                                                                          "last",
                                                                ),
                                                              ));
                                                            }
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              );
                            }),
                          ],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  String _moisFr(int m) {
    switch (m) {
      case 1:
        return "Janvier";
      case 2:
        return "Février";
      case 3:
        return "Mars";
      case 4:
        return "Avril";
      case 5:
        return "Mai";
      case 6:
        return "Juin";
      case 7:
        return "Juillet";
      case 8:
        return "Août";
      case 9:
        return "Septembre";
      case 10:
        return "Octobre";
      case 11:
        return "Novembre";
      case 12:
        return "Décembre";
      default:
        return "Mois $m";
    }
  }
}

/// CAISSIER PAGE
class CaissierPage extends StatefulWidget {
  const CaissierPage({super.key});

  @override
  State<CaissierPage> createState() => _CaissierPageState();
}

class _CaissierPageState extends State<CaissierPage> {
  String? expandedCommercialId;
  DateTime? _dateStart;
  DateTime? _dateEnd;
  String? _selectedLot;
  String? _selectedCommercial;

  Map<String, String> lotNumMap = {}; // lotConditionnementId -> lotOrigine
  Map<String, String> commercialNomMap = {}; // commercialId -> nom affiché
  bool lotsFetched = false;

  Future<Map<String, dynamic>?> fetchCommercialInfo(String commercialId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('utilisateurs')
        .doc(commercialId)
        .get();
    return userDoc.data() as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>?> fetchClientInfo(String clientId) async {
    if (clientId.isEmpty) return null;
    final clientDoc = await FirebaseFirestore.instance
        .collection('clients')
        .doc(clientId)
        .get();
    return clientDoc.data() as Map<String, dynamic>?;
  }

  Future<List<QueryDocumentSnapshot>> fetchVentesForTransaction(
      String commercialId, List venteIds) async {
    if (venteIds.isEmpty) return [];
    List<QueryDocumentSnapshot> result = [];
    for (int i = 0; i < venteIds.length; i += 10) {
      final chunk = venteIds.sublist(
          i, i + 10 > venteIds.length ? venteIds.length : i + 10);
      final ventesSnap = await FirebaseFirestore.instance
          .collection('ventes')
          .doc(commercialId)
          .collection('ventes_effectuees')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      result.addAll(ventesSnap.docs);
    }
    return result;
  }

  void callPhoneNumber(String phone, BuildContext context) async {
    final Uri url = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'appeler ce numéro.')),
      );
    }
  }

  Future<void> showCreditPaymentDialog({
    required BuildContext context,
    required QueryDocumentSnapshot venteDoc,
    required int montantRestant,
    required int montantPaye,
    required int montantTotal,
    required String typeVente,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    int montantSaisi = 0;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
              "Solder le ${typeVente == "Crédit" ? "crédit" : "recouvrement"}"),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Montant versé",
                suffixText: "FCFA",
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return "Saisir un montant";
                }
                final intVal = int.tryParse(val.trim());
                if (intVal == null || intVal <= 0) {
                  return "Montant invalide";
                }
                if (intVal > montantRestant) {
                  return "Montant trop élevé";
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                montantSaisi = int.parse(controller.text.trim());
                final nouveauMontantPaye = montantPaye + montantSaisi;
                final nouveauMontantRestant = montantTotal - nouveauMontantPaye;
                final updates = <String, dynamic>{
                  'montantPaye': nouveauMontantPaye,
                  'montantRestant':
                      nouveauMontantRestant > 0 ? nouveauMontantRestant : 0,
                  'etatCredit':
                      nouveauMontantRestant <= 0 ? 'remboursé' : 'partiel',
                };
                if (nouveauMontantRestant <= 0) {
                  updates['creditRembourseParCaissier'] = true;
                  updates['dateCreditRembourseParCaissier'] =
                      FieldValue.serverTimestamp();
                }
                await venteDoc.reference.update(updates);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(nouveauMontantRestant <= 0
                      ? "Le crédit a été totalement remboursé !"
                      : "Paiement crédit enregistré."),
                ));
                setState(() {});
              },
              child: const Text("Valider paiement"),
            ),
          ],
        );
      },
    );
  }

  bool isCreditFullyPaid(Map<String, dynamic> vente) {
    if (vente['typeVente'] == "Crédit" ||
        vente['typeVente'] == "Recouvrement") {
      return (vente['montantRestant'] ?? 0) <= 0;
    }
    return true;
  }

  Future<void> fetchLotNumAndCommercialNames(
      List<QueryDocumentSnapshot> transferts) async {
    final lotIds = <String>{};
    final vendeurIds = <String>{};
    for (final doc in transferts) {
      final t = doc.data() as Map<String, dynamic>;
      if (t['lotConditionnementId'] != null) {
        lotIds.add(t['lotConditionnementId']);
      }
      if (t['commercialId'] != null) {
        vendeurIds.add(t['commercialId']);
      }
    }
    // Fetch lots
    Map<String, String> lotMap = {};
    for (final id in lotIds) {
      if (lotNumMap.containsKey(id)) continue;
      final doc = await FirebaseFirestore.instance
          .collection('conditionnement')
          .doc(id)
          .get();
      if (doc.exists) {
        final map = doc.data();
        if (map != null && map['lotOrigine'] != null) {
          lotMap[id] = map['lotOrigine'].toString();
        }
      }
    }
    // Fetch vendeur noms
    Map<String, String> vendMap = {};
    for (final vid in vendeurIds) {
      if (commercialNomMap.containsKey(vid)) continue;
      final doc = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(vid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          vendMap[vid] = data['magasinier']?['nom'] ?? data['nom'] ?? vid;
        }
      }
    }
    if (mounted) {
      setState(() {
        lotNumMap.addAll(lotMap);
        commercialNomMap.addAll(vendMap);
        lotsFetched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions_caissier')
          .orderBy('dateTransfertCaissier', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Aucune vente à valider."));
        }

        final transfertsAll = snapshot.data!.docs;

        if (!lotsFetched) {
          fetchLotNumAndCommercialNames(transfertsAll);
        }

        // Filtres dynamiques
        final lotsSet = <String>{};
        final lotsLabels = <String, String>{};
        final vendeurSet = <String>{};
        for (final doc in transfertsAll) {
          final t = doc.data() as Map<String, dynamic>;
          final lotId = t['lotConditionnementId'] ?? '';
          final lotNum = lotNumMap[lotId] ?? lotId;
          lotsSet.add(lotNum);
          lotsLabels[lotNum] = lotNum;
          final vendeurId = t['commercialId'] ?? '';
          final vendeurNom = commercialNomMap[vendeurId] ?? vendeurId;
          vendeurSet.add(vendeurNom);
        }

        // Application des filtres
        List<QueryDocumentSnapshot> transfertsFiltres =
            transfertsAll.where((doc) {
          final t = doc.data() as Map<String, dynamic>;
          final lotId = t['lotConditionnementId'] ?? '';
          final lotNum = lotNumMap[lotId] ?? lotId;
          final vendeurId = t['commercialId'] ?? '';
          final vendeurNom = commercialNomMap[vendeurId] ?? vendeurId;
          final dateTrans = t['dateTransfertCaissier'] != null
              ? (t['dateTransfertCaissier'] is Timestamp
                  ? (t['dateTransfertCaissier'] as Timestamp).toDate()
                  : DateTime.tryParse(t['dateTransfertCaissier'].toString()))
              : null;
          bool matchLot = _selectedLot == null || _selectedLot == lotNum;
          bool matchCommercial =
              _selectedCommercial == null || _selectedCommercial == vendeurNom;
          bool matchDate = true;
          if (_dateStart != null) {
            matchDate = dateTrans != null && !dateTrans.isBefore(_dateStart!);
          }
          if (matchDate && _dateEnd != null) {
            matchDate = dateTrans != null && !dateTrans.isAfter(_dateEnd!);
          }
          return matchLot && matchCommercial && matchDate;
        }).toList();

        // Regroupement par commercialId
        Map<String, List<QueryDocumentSnapshot>> transfertsParCommercial = {};
        for (final doc in transfertsFiltres) {
          final t = doc.data() as Map<String, dynamic>;
          final vendeur = t['commercialId'] ?? 'Inconnu';
          transfertsParCommercial.putIfAbsent(vendeur, () => []).add(doc);
        }

        // UI filtres
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Wrap(
                runSpacing: 8,
                spacing: 8,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _dateStart == null && _dateEnd == null
                          ? "Filtrer par date"
                          : "${_dateStart != null ? "${_dateStart!.day}/${_dateStart!.month}/${_dateStart!.year}" : "..."} - ${_dateEnd != null ? "${_dateEnd!.day}/${_dateEnd!.month}/${_dateEnd!.year}" : "..."}",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                    ),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(now.year - 3),
                        lastDate: DateTime(now.year + 3),
                        initialDateRange: _dateStart != null && _dateEnd != null
                            ? DateTimeRange(start: _dateStart!, end: _dateEnd!)
                            : null,
                      );
                      if (picked != null) {
                        setState(() {
                          _dateStart = picked.start;
                          _dateEnd = picked.end;
                        });
                      }
                    },
                  ),
                  if (_dateStart != null || _dateEnd != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      tooltip: "Réinitialiser la date",
                      onPressed: () => setState(() {
                        _dateStart = null;
                        _dateEnd = null;
                      }),
                    ),
                  DropdownButton<String>(
                    value: _selectedLot,
                    hint: const Text("Tous les lots"),
                    style: TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.w500),
                    borderRadius: BorderRadius.circular(13),
                    underline: const SizedBox(),
                    icon: const Icon(Icons.local_offer),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text("Tous les lots")),
                      ...lotsSet.map((lotNum) => DropdownMenuItem(
                            value: lotNum,
                            child: Text(lotsLabels[lotNum] ?? lotNum),
                          ))
                    ],
                    onChanged: (v) => setState(() => _selectedLot = v),
                  ),
                  DropdownButton<String>(
                    value: _selectedCommercial,
                    hint: const Text("Tous les commerciaux"),
                    style: TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.w500),
                    borderRadius: BorderRadius.circular(13),
                    underline: const SizedBox(),
                    icon: const Icon(Icons.person),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text("Tous les commerciaux")),
                      ...vendeurSet.map((vendeurNom) => DropdownMenuItem(
                            value: vendeurNom,
                            child: Text(vendeurNom),
                          ))
                    ],
                    onChanged: (v) => setState(() => _selectedCommercial = v),
                  ),
                  if (_selectedLot != null || _selectedCommercial != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      tooltip: "Réinitialiser les filtres",
                      onPressed: () => setState(() {
                        _selectedLot = null;
                        _selectedCommercial = null;
                      }),
                    ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 18, top: 4, right: 18, bottom: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Affichés: ${transfertsFiltres.length} / ${transfertsAll.length}",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ),
            const Divider(height: 2),
            Expanded(
              child: transfertsParCommercial.isEmpty
                  ? const Center(child: Text("Aucune vente trouvée."))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: transfertsParCommercial.entries.map((entry) {
                        final vendeurId = entry.key;
                        final transferts = entry.value;
                        final vendeurNom =
                            commercialNomMap[vendeurId] ?? vendeurId;
                        return FutureBuilder<Map<String, dynamic>?>(
                          future: fetchCommercialInfo(vendeurId),
                          builder: (context, userSnap) {
                            final userData = userSnap.data;
                            final isExpanded =
                                expandedCommercialId == vendeurId;
                            return Card(
                              elevation: 5,
                              margin: const EdgeInsets.only(bottom: 25),
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: ExpansionTile(
                                key: ValueKey(vendeurId),
                                initiallyExpanded: isExpanded,
                                onExpansionChanged: (expanded) {
                                  setState(() {
                                    expandedCommercialId =
                                        expanded ? vendeurId : null;
                                  });
                                },
                                tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                childrenPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                title: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.blue[50],
                                      child: Icon(Icons.person,
                                          color: Colors.blue[900], size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Commercial: ${userData?['magasinier']?['nom'] ?? userData?['nom'] ?? vendeurNom}",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18),
                                          ),
                                          if (userData != null)
                                            Row(
                                              children: [
                                                Icon(Icons.email,
                                                    size: 15,
                                                    color: Colors.grey[700]),
                                                const SizedBox(width: 3),
                                                Flexible(
                                                  child: Text(
                                                    "${userData['email'] ?? ''}",
                                                    style: const TextStyle(
                                                        fontSize: 14),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          if (userData != null)
                                            Row(
                                              children: [
                                                Icon(Icons.location_on,
                                                    size: 15,
                                                    color: Colors.grey[700]),
                                                const SizedBox(width: 3),
                                                Flexible(
                                                  child: Text(
                                                    "${userData['magasinier']?['localite'] ?? ''}",
                                                    style: const TextStyle(
                                                        fontSize: 14),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                children: transferts.map((transfertDoc) {
                                  final t = transfertDoc.data()
                                      as Map<String, dynamic>;
                                  final venteIds = (t['venteIds'] as List?)
                                          ?.cast<String>() ??
                                      [];
                                  final prelevementId =
                                      t['prelevementId'] ?? '';
                                  final dateTrans =
                                      t['dateTransfertCaissier'] != null
                                          ? (t['dateTransfertCaissier']
                                                  is Timestamp
                                              ? (t['dateTransfertCaissier']
                                                      as Timestamp)
                                                  .toDate()
                                              : DateTime.tryParse(
                                                  t['dateTransfertCaissier']
                                                      .toString()))
                                          : null;
                                  final lotId = t['lotConditionnementId'] ?? '';
                                  final lotNum = lotNumMap[lotId] ?? lotId;
                                  return FutureBuilder<
                                      List<QueryDocumentSnapshot>>(
                                    future: fetchVentesForTransaction(
                                        vendeurId, venteIds),
                                    builder: (context, ventesSnap) {
                                      if (!ventesSnap.hasData) {
                                        return const Padding(
                                          padding: EdgeInsets.all(15),
                                          child: Center(
                                              child:
                                                  CircularProgressIndicator()),
                                        );
                                      }
                                      final ventesDocs = ventesSnap.data ?? [];
                                      if (ventesDocs.isEmpty) {
                                        return const Padding(
                                          padding: EdgeInsets.all(15),
                                          child: Text(
                                              "Aucune vente pour ce transfert."),
                                        );
                                      }
                                      Map<String, List<QueryDocumentSnapshot>>
                                          ventesParType = {};
                                      for (final v in ventesDocs) {
                                        final type = (v.data() as Map<String,
                                                dynamic>)['typeVente'] ??
                                            'Comptant';
                                        ventesParType
                                            .putIfAbsent(type, () => [])
                                            .add(v);
                                      }
                                      final typeList =
                                          ventesParType.keys.toList();
                                      final ValueNotifier<String>
                                          selectedTypeVente =
                                          ValueNotifier<String>(typeList.first);
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 6.0),
                                            child: Text(
                                              "Transfert du ${dateTrans != null ? "${dateTrans.day}/${dateTrans.month}/${dateTrans.year}" : '?'} | Lot: $lotNum | Prélèvement: $prelevementId",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15),
                                            ),
                                          ),
                                          if (typeList.length > 1)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 4,
                                                  right: 4,
                                                  bottom: 12,
                                                  top: 0),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.filter_alt,
                                                      color:
                                                          Colors.purple[400]),
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    "Type de vente : ",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child:
                                                        ValueListenableBuilder<
                                                            String>(
                                                      valueListenable:
                                                          selectedTypeVente,
                                                      builder: (context,
                                                          typeSelected, _) {
                                                        return DropdownButton<
                                                            String>(
                                                          value: typeSelected,
                                                          isExpanded: true,
                                                          items: typeList
                                                              .map((t) =>
                                                                  DropdownMenuItem<
                                                                      String>(
                                                                    value: t,
                                                                    child: Text(
                                                                      t,
                                                                      style: const TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.w500),
                                                                    ),
                                                                  ))
                                                              .toList(),
                                                          onChanged: (val) {
                                                            if (val != null)
                                                              selectedTypeVente
                                                                  .value = val;
                                                          },
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ValueListenableBuilder<String>(
                                            valueListenable: selectedTypeVente,
                                            builder:
                                                (context, typeSelected, _) {
                                              final docs =
                                                  ventesParType[typeSelected] ??
                                                      [];
                                              if (docs.isEmpty) {
                                                return const Padding(
                                                  padding: EdgeInsets.all(18.0),
                                                  child: Text(
                                                    "Aucune vente pour ce type.",
                                                    style: TextStyle(
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        color: Colors.grey),
                                                  ),
                                                );
                                              }
                                              return Column(
                                                children: docs.map((venteDoc) {
                                                  final vente = venteDoc.data()
                                                      as Map<String, dynamic>;
                                                  final clientId =
                                                      vente['clientId'] ?? '';
                                                  final dateV = vente[
                                                              'dateVente'] !=
                                                          null
                                                      ? (vente['dateVente']
                                                              is Timestamp
                                                          ? (vente['dateVente']
                                                                  as Timestamp)
                                                              .toDate()
                                                          : DateTime.tryParse(
                                                              vente['dateVente']
                                                                  .toString()))
                                                      : null;
                                                  final montant =
                                                      vente['montantTotal'] ??
                                                          0;
                                                  final montantPaye =
                                                      vente['montantPaye'] ?? 0;
                                                  final montantRestant =
                                                      vente['montantRestant'] ??
                                                          0;
                                                  final typeVente =
                                                      vente['typeVente'] ?? '';
                                                  final approuve = vente[
                                                          'transfertValideParCaissier'] ==
                                                      true;
                                                  final emballages =
                                                      vente['emballagesVendus']
                                                          as List?;
                                                  final detailsEmballage =
                                                      emballages != null
                                                          ? emballages
                                                              .map((e) =>
                                                                  "- ${e['type']}: ${e['nombre']} pots")
                                                              .join("\n")
                                                          : "";
                                                  return FutureBuilder<
                                                      Map<String, dynamic>?>(
                                                    future: fetchClientInfo(
                                                        clientId),
                                                    builder:
                                                        (context, clientSnap) {
                                                      final clientData =
                                                          clientSnap.data;
                                                      final boutique = clientData?[
                                                              'nomBoutique'] ??
                                                          vente[
                                                              'nomBoutique'] ??
                                                          '';
                                                      final clientName =
                                                          clientData?[
                                                                  'nomGerant'] ??
                                                              vente[
                                                                  'clientNom'] ??
                                                              vente[
                                                                  'clientId'] ??
                                                              '';
                                                      final clientTel =
                                                          clientData?[
                                                                  'telephone1'] ??
                                                              vente[
                                                                  'clientTel'] ??
                                                              '';
                                                      return Card(
                                                        margin: const EdgeInsets
                                                            .symmetric(
                                                            vertical: 9,
                                                            horizontal: 5),
                                                        elevation: 2,
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        13)),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 8,
                                                                  horizontal:
                                                                      10),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                    approuve
                                                                        ? Icons
                                                                            .verified
                                                                        : Icons
                                                                            .pending_actions,
                                                                    color: approuve
                                                                        ? Colors.green[
                                                                            700]
                                                                        : Colors
                                                                            .orange[700],
                                                                  ),
                                                                  const SizedBox(
                                                                      width:
                                                                          10),
                                                                  Text(
                                                                    "${typeVente.toString().toUpperCase()}",
                                                                    style:
                                                                        TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: approuve
                                                                          ? Colors.green[
                                                                              700]
                                                                          : Colors
                                                                              .orange[700],
                                                                      fontSize:
                                                                          15,
                                                                    ),
                                                                  ),
                                                                  const Spacer(),
                                                                  if (approuve)
                                                                    Chip(
                                                                      label: Text(
                                                                          vente['etatCredit'] == 'remboursé'
                                                                              ? "Crédit remboursé"
                                                                              : vente['etatCredit'] == 'partiel' && (typeVente == "Crédit" || typeVente == "Recouvrement")
                                                                                  ? "Partiellement remboursé"
                                                                                  : "Validé",
                                                                          style: const TextStyle(color: Colors.white)),
                                                                      backgroundColor: vente['etatCredit'] ==
                                                                              'remboursé'
                                                                          ? Colors
                                                                              .green
                                                                          : vente['etatCredit'] == 'partiel'
                                                                              ? Colors.orange
                                                                              : Colors.green[700],
                                                                    ),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                  height: 8),
                                                              Wrap(
                                                                spacing: 16,
                                                                runSpacing: 6,
                                                                children: [
                                                                  Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      Icon(
                                                                          Icons
                                                                              .storefront,
                                                                          color: Colors.blue[
                                                                              800],
                                                                          size:
                                                                              18),
                                                                      const SizedBox(
                                                                          width:
                                                                              3),
                                                                      Text(
                                                                        "Boutique: ",
                                                                        style: const TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.w500),
                                                                      ),
                                                                      Text(
                                                                        boutique.isNotEmpty
                                                                            ? boutique
                                                                            : "-",
                                                                        style: const TextStyle(
                                                                            fontStyle:
                                                                                FontStyle.italic),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      Icon(
                                                                          Icons
                                                                              .person_outline,
                                                                          color: Colors.teal[
                                                                              800],
                                                                          size:
                                                                              18),
                                                                      const SizedBox(
                                                                          width:
                                                                              3),
                                                                      const Text(
                                                                          "Client: "),
                                                                      Text(
                                                                        clientName,
                                                                        style: const TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.w500),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  if (clientTel
                                                                      .toString()
                                                                      .isNotEmpty)
                                                                    Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        Icon(
                                                                            Icons
                                                                                .phone,
                                                                            color:
                                                                                Colors.green[800],
                                                                            size: 18),
                                                                        const SizedBox(
                                                                            width:
                                                                                3),
                                                                        InkWell(
                                                                          onTap: () => callPhoneNumber(
                                                                              clientTel,
                                                                              context),
                                                                          child:
                                                                              Text(
                                                                            clientTel,
                                                                            style:
                                                                                const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                  height: 7),
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                      Icons
                                                                          .date_range,
                                                                      size: 16,
                                                                      color: Colors
                                                                          .grey),
                                                                  const SizedBox(
                                                                      width: 4),
                                                                  Text(
                                                                      "Date: ${dateV != null ? "${dateV.day}/${dateV.month}/${dateV.year}" : "?"}"),
                                                                ],
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                      Icons
                                                                          .price_change,
                                                                      size: 16,
                                                                      color: Colors
                                                                              .orange[
                                                                          300]),
                                                                  const SizedBox(
                                                                      width: 4),
                                                                  Text(
                                                                      "Montant total: "),
                                                                  Text(
                                                                      "$montant FCFA",
                                                                      style: const TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold)),
                                                                ],
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                      Icons
                                                                          .check_circle,
                                                                      size: 16,
                                                                      color: Colors
                                                                              .green[
                                                                          300]),
                                                                  const SizedBox(
                                                                      width: 4),
                                                                  Text(
                                                                      "Montant payé: "),
                                                                  Text(
                                                                      "$montantPaye FCFA",
                                                                      style: const TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold)),
                                                                ],
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                      Icons
                                                                          .cancel,
                                                                      size: 16,
                                                                      color: Colors
                                                                              .red[
                                                                          200]),
                                                                  const SizedBox(
                                                                      width: 4),
                                                                  Text(
                                                                      "Montant restant: "),
                                                                  Text(
                                                                      "$montantRestant FCFA",
                                                                      style: const TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold)),
                                                                ],
                                                              ),
                                                              if (detailsEmballage
                                                                  .isNotEmpty)
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              4.0,
                                                                          bottom:
                                                                              2),
                                                                  child: Row(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Icon(
                                                                          Icons
                                                                              .local_mall,
                                                                          size:
                                                                              17,
                                                                          color:
                                                                              Colors.amber[800]),
                                                                      const SizedBox(
                                                                          width:
                                                                              4),
                                                                      Flexible(
                                                                          child:
                                                                              Text("Emballages:\n$detailsEmballage")),
                                                                    ],
                                                                  ),
                                                                ),
                                                              if (vente[
                                                                      'note'] !=
                                                                  null)
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              2.0),
                                                                  child: Row(
                                                                    children: [
                                                                      Icon(
                                                                          Icons
                                                                              .note,
                                                                          size:
                                                                              15,
                                                                          color:
                                                                              Colors.grey[700]),
                                                                      const SizedBox(
                                                                          width:
                                                                              3),
                                                                      Flexible(
                                                                          child:
                                                                              Text("Note: ${vente['note']}")),
                                                                    ],
                                                                  ),
                                                                ),
                                                              if (vente[
                                                                      'nomMagasinier'] !=
                                                                  null)
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              2.0),
                                                                  child: Row(
                                                                    children: [
                                                                      Icon(
                                                                          Icons
                                                                              .store,
                                                                          size:
                                                                              15,
                                                                          color:
                                                                              Colors.brown[700]),
                                                                      const SizedBox(
                                                                          width:
                                                                              3),
                                                                      Flexible(
                                                                          child:
                                                                              Text("Magasinier: ${vente['nomMagasinier']}")),
                                                                    ],
                                                                  ),
                                                                ),
                                                              if (vente[
                                                                      'dateTransfertCaissier'] !=
                                                                  null)
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              2.0),
                                                                  child: Row(
                                                                    children: [
                                                                      Icon(
                                                                          Icons
                                                                              .compare_arrows,
                                                                          size:
                                                                              15,
                                                                          color:
                                                                              Colors.blueGrey),
                                                                      const SizedBox(
                                                                          width:
                                                                              3),
                                                                      Flexible(
                                                                        child:
                                                                            Text(
                                                                          "Transféré au caissier le: ${vente['dateTransfertCaissier'] is Timestamp ? (vente['dateTransfertCaissier'] as Timestamp).toDate().toString() : vente['dateTransfertCaissier'].toString()}",
                                                                          style: const TextStyle(
                                                                              fontSize: 12,
                                                                              color: Colors.blueGrey),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              const SizedBox(
                                                                  height: 10),
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .end,
                                                                children: [
                                                                  if ((typeVente ==
                                                                              "Crédit" ||
                                                                          typeVente ==
                                                                              "Recouvrement") &&
                                                                      montantRestant >
                                                                          0)
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              6),
                                                                      child: ElevatedButton
                                                                          .icon(
                                                                        icon: const Icon(
                                                                            Icons.attach_money),
                                                                        label: Text(typeVente ==
                                                                                "Crédit"
                                                                            ? "Solder le crédit"
                                                                            : "Solder le recouvrement"),
                                                                        style: ElevatedButton
                                                                            .styleFrom(
                                                                          backgroundColor:
                                                                              Colors.orange[700],
                                                                          foregroundColor:
                                                                              Colors.white,
                                                                          shape:
                                                                              RoundedRectangleBorder(
                                                                            borderRadius:
                                                                                BorderRadius.circular(10),
                                                                          ),
                                                                          elevation:
                                                                              0,
                                                                        ),
                                                                        onPressed:
                                                                            () =>
                                                                                showCreditPaymentDialog(
                                                                          context:
                                                                              context,
                                                                          venteDoc:
                                                                              venteDoc,
                                                                          montantRestant:
                                                                              montantRestant,
                                                                          montantPaye:
                                                                              montantPaye,
                                                                          montantTotal:
                                                                              montant,
                                                                          typeVente:
                                                                              typeVente,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  if (!approuve &&
                                                                      ((typeVente ==
                                                                              "Comptant") ||
                                                                          ((typeVente == "Crédit" || typeVente == "Recouvrement") &&
                                                                              isCreditFullyPaid(
                                                                                  vente))))
                                                                    ElevatedButton
                                                                        .icon(
                                                                      icon: const Icon(
                                                                          Icons
                                                                              .verified),
                                                                      style: ElevatedButton
                                                                          .styleFrom(
                                                                        backgroundColor:
                                                                            Colors.blue[700],
                                                                        foregroundColor:
                                                                            Colors.white,
                                                                        shape:
                                                                            RoundedRectangleBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(10),
                                                                        ),
                                                                        elevation:
                                                                            0,
                                                                      ),
                                                                      label: const Text(
                                                                          "Valider cette vente"),
                                                                      onPressed:
                                                                          () async {
                                                                        await venteDoc
                                                                            .reference
                                                                            .update({
                                                                          'transfertValideParCaissier':
                                                                              true
                                                                        });
                                                                        setState(
                                                                            () {});
                                                                      },
                                                                    ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                }).toList(),
                                              );
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class GestionnaireCommercialPage extends StatefulWidget {
  const GestionnaireCommercialPage({super.key});
  @override
  State<GestionnaireCommercialPage> createState() =>
      _GestionnaireCommercialPageState();
}

class _GestionnaireCommercialPageState
    extends State<GestionnaireCommercialPage> {
  String selectedSection = "Ventes";
  String? selectedClient;
  String? selectedCommercial;
  String? selectedTypeProduit;
  String? selectedLocalite;
  DateTimeRange? selectedPeriode;
  String? selectedCollecteType;
  String? selectedStockLocalite;
  String? selectedStockMagasin;

  Map<String, String> clientsMap = {};
  Map<String, String> commerciauxMap = {};

  List<Map<String, dynamic>> _latestVentesFiltered = [];
  List<Map<String, dynamic>> _latestCollectesFiltered = [];
  List<Map<String, dynamic>> _latestStockFiltered = [];

  Future<List<String>> fetchClients() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('clients').get();
      clientsMap = {
        for (var d in snap.docs)
          d.id: d.data()['nomBoutique'] ?? d.data()['nomGerant'] ?? d.id
      };
      return clientsMap.values.toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> fetchCommerciaux() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .where('role', isEqualTo: 'Commercial')
          .get();
      commerciauxMap = {};
      for (var d in snap.docs) {
        final nom = d.data()['nom'] ?? d.id;
        commerciauxMap[d.id] = nom;
        final uid = d.data()['uid'];
        if (uid != null && uid != d.id) {
          commerciauxMap[uid] = nom;
        }
      }
      return commerciauxMap.values.toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> fetchTypesProduit() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('conditionnement').get();
      final types = <String>{};
      for (var doc in snap.docs) {
        final emballages = (doc.data()['emballages'] as List?) ?? [];
        for (final emb in emballages) {
          types.add(emb['type'] ?? '');
        }
      }
      return types.where((e) => e.isNotEmpty).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> fetchLocalites() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('utilisateurs').get();
      final localites = <String>{};
      for (var doc in snap.docs) {
        final loc = doc.data()['localite'];
        if (loc != null && loc.toString().isNotEmpty) localites.add(loc);
      }
      return localites.toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> fetchMagasins() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('magasins').get();
      return snap.docs
          .map((e) => e.data()['nom'] ?? e.id)
          .cast<String>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  Widget periodePicker() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.date_range),
      label: Text(selectedPeriode == null
          ? "Période d'opération"
          : "${DateFormat('dd/MM/yyyy').format(selectedPeriode!.start)} - "
              "${DateFormat('dd/MM/yyyy').format(selectedPeriode!.end)}"),
      onPressed: () async {
        try {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 2)),
            initialDateRange: selectedPeriode,
          );
          if (picked != null) setState(() => selectedPeriode = picked);
        } catch (_) {}
      },
    );
  }

  Future<void> exportPDF(
      List<Map<String, dynamic>>? data, String section) async {
    try {
      List<Map<String, dynamic>> exportData = data ?? [];
      if ((section == "Ventes" || section == "Crédits") &&
          _latestVentesFiltered.isNotEmpty) {
        exportData = _latestVentesFiltered;
      }
      if (section == "Recouvrements" && _latestCollectesFiltered.isNotEmpty) {
        exportData = _latestCollectesFiltered;
      }
      if (section == "Stock" && _latestStockFiltered.isNotEmpty) {
        exportData = _latestStockFiltered;
      }
      if (exportData.isEmpty) {
        final pdf = pw.Document();
        pdf.addPage(pw.Page(
          build: (context) => pw.Center(child: pw.Text('Aucune donnée')),
        ));
        await Printing.layoutPdf(onLayout: (format) async => pdf.save());
        return;
      }

      List<String> columns;
      List<List<String>> rows;

      if (section == "Ventes" || section == "Crédits") {
        columns = [
          "Date",
          "Client",
          "Commercial",
          "Type vente",
          "Montant total",
          "Etat"
        ];
        rows = exportData.map((v) {
          final dateV = v['dateVente'] is Timestamp
              ? DateFormat('dd/MM/yyyy')
                  .format((v['dateVente'] as Timestamp).toDate())
              : "";
          String? commId = v['commercialId']?.toString();
          String? commNom = v['commercialNom']?.toString();
          String displayComm = commerciauxMap[commId] ?? commNom ?? "";
          String displayClient =
              clientsMap[v['clientId']] ?? v['clientNom'] ?? "";
          String etat = v['etatCredit']?.toString() ?? "";
          return [
            dateV,
            displayClient,
            displayComm,
            v['typeVente']?.toString() ?? "",
            "${v['montantTotal'] ?? ""}",
            etat
          ].map((e) => e.toString()).toList();
        }).toList();
      } else if (section == "Recouvrements") {
        columns = [
          "Date",
          "Type",
          "Client",
          "Montant crédit",
          "Montant remboursé",
          "Montant restant",
          "Etat"
        ];
        rows = exportData.map((l) {
          final dateC = l['dateVente'] is Timestamp
              ? DateFormat('dd/MM/yyyy')
                  .format((l['dateVente'] as Timestamp).toDate())
              : "";
          String displayClient =
              clientsMap[l['clientId']] ?? l['clientNom'] ?? "";
          String etat = l['etatCredit']?.toString() ?? "";
          return [
            dateC.toString(),
            (l['typeVente'] ?? "").toString(),
            displayClient.toString(),
            "${l['montantTotal'] ?? ""}",
            "${l['montantPaye'] ?? ""}",
            "${l['montantRestant'] ?? ""}",
            etat
          ];
        }).toList();
      } else if (section == "Stock") {
        columns = [
          "Date",
          "Lot origine",
          "Florale",
          "Nb total pots",
          "Qté conditionnée",
          "Qté reçue",
          "Qté restante",
        ];
        rows = exportData.map((lot) {
          final dateC = lot['date'] is Timestamp
              ? DateFormat('dd/MM/yyyy')
                  .format((lot['date'] as Timestamp).toDate())
              : "";
          return [
            dateC,
            "${lot['lotOrigine'] ?? ""}",
            "${lot['predominanceFlorale'] ?? ""}",
            "${lot['nbTotalPots'] ?? ""}",
            "${lot['quantiteConditionnee'] ?? ""}",
            "${lot['quantiteRecue'] ?? ""}",
            "${lot['quantiteRestante'] ?? ""}",
          ];
        }).toList();
      } else {
        columns = [];
        rows = [];
      }

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Export $section",
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 22),
              ),
              pw.SizedBox(height: 14),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: columns
                        .map((h) => pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(h,
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold)),
                            ))
                        .toList(),
                  ),
                  ...rows.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                          color: index.isEven
                              ? PdfColors.white
                              : PdfColors.grey100),
                      children: row
                          .map((cell) => pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(cell),
                              ))
                          .toList(),
                    );
                  }),
                ],
              )
            ],
          ),
        ),
      );
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur export PDF: $e")),
        );
      }
    }
  }

  void showDetailsDialog(BuildContext context, Map<String, dynamic> data,
      {String? title}) {
    String formatValue(dynamic value, {String? key}) {
      if (key != null && key.toLowerCase().contains('client')) {
        return clientsMap[value] ?? value?.toString() ?? '';
      }
      if (key != null && key.toLowerCase().contains('commercial')) {
        return commerciauxMap[value] ?? value?.toString() ?? '';
      }
      if (value is Timestamp) {
        return DateFormat('dd/MM/yyyy HH:mm').format(value.toDate());
      }
      if (value is DateTime) {
        return DateFormat('dd/MM/yyyy HH:mm').format(value);
      }
      if (value is Map) {
        return value.entries
            .map((e) => "${e.key}: ${formatValue(e.value, key: e.key)}")
            .join(", ");
      }
      if (value is List) {
        if (value.isEmpty) return "(vide)";
        if (value[0] is Map) {
          return value
              .map((item) => value.length > 1
                  ? "\n- ${formatValue(item)}"
                  : formatValue(item))
              .join("");
        }
        return value.join(", ");
      }
      return value?.toString() ?? "";
    }

    List<Widget> buildDetails(Map<String, dynamic> details) {
      final infos = <TableRow>[];
      final autres = <TableRow>[];
      final listes = <Widget>[];

      details.forEach((key, value) {
        final labelStyle = TextStyle(
            fontWeight: FontWeight.w600, color: Colors.deepPurple[700]);
        if (key.toLowerCase().contains('nom') ||
            key.toLowerCase().contains('type') ||
            key.toLowerCase().contains('produit') ||
            key.toLowerCase().contains('client') ||
            key.toLowerCase().contains('commercial')) {
          infos.add(TableRow(children: [
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(key, style: labelStyle)),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(formatValue(value, key: key))),
          ]));
        } else if (value is List && value.isNotEmpty && value[0] is Map) {
          listes.add(Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 2),
            child: Text("$key :",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          ));
          for (var i = 0; i < value.length; i++) {
            final map = value[i] as Map;
            listes.add(
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.deepPurple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepPurple.shade100),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: FlexColumnWidth(),
                    },
                    children: map.entries
                        .map<TableRow>((entry) => TableRow(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Text("${entry.key}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500)),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                      formatValue(entry.value, key: entry.key)),
                                ),
                              ],
                            ))
                        .toList(),
                  ),
                ),
              ),
            );
          }
        } else {
          autres.add(TableRow(children: [
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(key, style: labelStyle)),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(formatValue(value, key: key))),
          ]));
        }
      });

      return [
        if (infos.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text("Informations principales",
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple)),
          ),
          Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth()
            },
            children: infos,
          ),
        ],
        if (autres.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text("Autres champs",
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800])),
          ),
          Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth()
            },
            children: autres,
          ),
        ],
        if (listes.isNotEmpty) ...listes,
        const SizedBox(height: 10),
      ];
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.info, color: Colors.deepPurple[300]),
            const SizedBox(width: 8),
            Text(title ?? "Détails",
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: buildDetails(data),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fermer")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        fetchClients(),
        fetchCommerciaux(),
        fetchTypesProduit(),
        fetchLocalites(),
        fetchMagasins(),
      ]),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final clients = snap.data![0] as List<String>;
        final commerciaux = snap.data![1] as List<String>;
        final produits = snap.data![2] as List<String>;
        final localites = snap.data![3] as List<String>;
        final magasins = snap.data![4] as List<String>;

        List<Widget> filterWidgets = [];
        if (selectedSection == "Ventes" || selectedSection == "Crédits") {
          filterWidgets.addAll([
            SizedBox(
              width: 220,
              child: DropdownButton<String?>(
                value: selectedClient,
                hint: const Text("Filtrer par client"),
                isExpanded: true,
                items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text("Tous les clients"))
                    ] +
                    clients
                        .map((c) =>
                            DropdownMenuItem<String?>(value: c, child: Text(c)))
                        .toList(),
                onChanged: (v) => setState(() => selectedClient = v),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButton<String?>(
                value: selectedCommercial,
                hint: const Text("Filtrer par commercial"),
                isExpanded: true,
                items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text("Tous les commerciaux"))
                    ] +
                    commerciaux
                        .map((c) =>
                            DropdownMenuItem<String?>(value: c, child: Text(c)))
                        .toList(),
                onChanged: (v) => setState(() => selectedCommercial = v),
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButton<String?>(
                value: selectedTypeProduit,
                hint: const Text("Filtrer par type de produit"),
                isExpanded: true,
                items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text("Tous les types"))
                    ] +
                    produits
                        .map((t) =>
                            DropdownMenuItem<String?>(value: t, child: Text(t)))
                        .toList(),
                onChanged: (v) => setState(() => selectedTypeProduit = v),
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButton<String?>(
                value: selectedLocalite,
                hint: const Text("Filtrer par localité"),
                isExpanded: true,
                items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text("Toutes les localités"))
                    ] +
                    localites
                        .map((l) =>
                            DropdownMenuItem<String?>(value: l, child: Text(l)))
                        .toList(),
                onChanged: (v) => setState(() => selectedLocalite = v),
              ),
            ),
            periodePicker(),
          ]);
        }
        if (selectedSection == "Recouvrements") {
          filterWidgets.addAll([
            SizedBox(
              width: 220,
              child: DropdownButton<String?>(
                value: selectedClient,
                hint: const Text("Filtrer par client"),
                isExpanded: true,
                items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text("Tous les clients"))
                    ] +
                    clients
                        .map((c) =>
                            DropdownMenuItem<String?>(value: c, child: Text(c)))
                        .toList(),
                onChanged: (v) => setState(() => selectedClient = v),
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButton<String?>(
                value: selectedLocalite,
                hint: const Text("Filtrer par localité"),
                isExpanded: true,
                items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text("Toutes les localités"))
                    ] +
                    localites
                        .map((l) =>
                            DropdownMenuItem<String?>(value: l, child: Text(l)))
                        .toList(),
                onChanged: (v) => setState(() => selectedLocalite = v),
              ),
            ),
            periodePicker(),
          ]);
        }
        if (selectedSection == "Stock") {
          filterWidgets.addAll([
            SizedBox(
              width: 220,
              child: DropdownButton<String?>(
                value: selectedStockLocalite,
                hint: const Text("Filtrer par localité"),
                isExpanded: true,
                items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text("Toutes les localités"))
                    ] +
                    localites
                        .map((l) =>
                            DropdownMenuItem<String?>(value: l, child: Text(l)))
                        .toList(),
                onChanged: (v) => setState(() => selectedStockLocalite = v),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButton<String?>(
                value: selectedStockMagasin,
                hint: const Text("Filtrer par magasin"),
                isExpanded: true,
                items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text("Tous les magasins"))
                    ] +
                    magasins
                        .map((m) =>
                            DropdownMenuItem<String?>(value: m, child: Text(m)))
                        .toList(),
                onChanged: (v) => setState(() => selectedStockMagasin = v),
              ),
            ),
          ]);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tableau de bord Gestionnaire Commercial",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text("Ventes"),
                      selected: selectedSection == "Ventes",
                      onSelected: (_) =>
                          setState(() => selectedSection = "Ventes"),
                    ),
                    ChoiceChip(
                      label: const Text("Crédits en cours"),
                      selected: selectedSection == "Crédits",
                      onSelected: (_) =>
                          setState(() => selectedSection = "Crédits"),
                    ),
                    ChoiceChip(
                      label: const Text("Recouvrements"),
                      selected: selectedSection == "Recouvrements",
                      onSelected: (_) =>
                          setState(() => selectedSection = "Recouvrements"),
                    ),
                    ChoiceChip(
                      label: const Text("Stock"),
                      selected: selectedSection == "Stock",
                      onSelected: (_) =>
                          setState(() => selectedSection = "Stock"),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: filterWidgets,
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (selectedSection == "Ventes" ||
                        selectedSection == "Crédits") {
                      await exportPDF(_latestVentesFiltered, selectedSection);
                    } else if (selectedSection == "Stock") {
                      await exportPDF(_latestStockFiltered, selectedSection);
                    } else if (selectedSection == "Recouvrements") {
                      await exportPDF(
                          _latestCollectesFiltered, selectedSection);
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Exporter PDF"),
                ),
                const SizedBox(height: 16),
                if (selectedSection == "Ventes")
                  buildVentesTable(context, showOnlyCredits: false),
                if (selectedSection == "Crédits")
                  buildVentesTable(context, showOnlyCredits: true),
                if (selectedSection == "Recouvrements")
                  buildRecouvrementsTable(context),
                if (selectedSection == "Stock") buildStockTable(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildVentesTable(BuildContext context,
      {required bool showOnlyCredits}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('ventes_effectuees')
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError)
          return Center(child: Text('Erreur Firestore: ${snap.error}'));
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final ventes = snap.data!.docs
            .map((e) => e.data() as Map<String, dynamic>)
            .toList();
        List<Map<String, dynamic>> filtered = ventes;
        if (showOnlyCredits) {
          filtered = filtered
              .where((v) => (v['typeVente'] == "Crédit" ||
                  v['typeVente'] == "Recouvrement"))
              .toList();
        }
        if (selectedClient != null) {
          filtered = filtered
              .where((v) =>
                  (clientsMap[v['clientId']] ?? v['clientNom'] ?? "") ==
                  selectedClient)
              .toList();
        }
        if (selectedCommercial != null) {
          filtered = filtered.where((v) {
            String? commId = v['commercialId']?.toString();
            String? commNom = v['commercialNom']?.toString();
            return (commerciauxMap[commId] ?? commNom ?? "") ==
                selectedCommercial;
          }).toList();
        }
        if (selectedTypeProduit != null) {
          filtered = filtered.where((v) {
            final emb = (v['emballagesVendus'] ?? []) as List;
            return emb.any((e) => e['type'] == selectedTypeProduit);
          }).toList();
        }
        if (selectedLocalite != null) {
          filtered =
              filtered.where((v) => v['localite'] == selectedLocalite).toList();
        }
        if (selectedPeriode != null) {
          filtered = filtered.where((v) {
            final d = v['dateVente'];
            if (d is Timestamp) {
              final dt = d.toDate();
              return dt.isAfter(selectedPeriode!.start
                      .subtract(const Duration(days: 1))) &&
                  dt.isBefore(
                      selectedPeriode!.end.add(const Duration(days: 1)));
            }
            return true;
          }).toList();
        }
        _latestVentesFiltered = filtered;

        return Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Date")),
                DataColumn(label: Text("Client")),
                DataColumn(label: Text("Commercial")),
                DataColumn(label: Text("Type vente")),
                DataColumn(label: Text("Montant total")),
                DataColumn(label: Text("Etat")),
                DataColumn(label: Text("Voir détails")),
              ],
              rows: filtered.map((v) {
                final dateV = v['dateVente'] is Timestamp
                    ? (v['dateVente'] as Timestamp).toDate()
                    : null;
                String? commId = v['commercialId']?.toString();
                String? commNom = v['commercialNom']?.toString();
                String displayComm = commerciauxMap[commId] ?? commNom ?? "";
                String displayClient =
                    clientsMap[v['clientId']] ?? v['clientNom'] ?? "";
                String etat = v['etatCredit']?.toString() ?? "";
                return DataRow(
                  cells: [
                    DataCell(Text(dateV != null
                        ? DateFormat('dd/MM/yyyy').format(dateV)
                        : "")),
                    DataCell(Text(displayClient)),
                    DataCell(Text(displayComm)),
                    DataCell(Text(v['typeVente'] ?? "")),
                    DataCell(Text("${v['montantTotal'] ?? ""}")),
                    DataCell(Text(etat)),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.info_outline,
                            color: Colors.deepPurple),
                        onPressed: () => showDetailsDialog(context, v,
                            title: "Détails de la vente"),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget buildRecouvrementsTable(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('ventes_effectuees')
          .where('typeVente', whereIn: ['Crédit', 'Recouvrement'])
          .where('etatCredit', isEqualTo: 'remboursé')
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError)
          return Center(child: Text('Erreur Firestore: ${snap.error}'));
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final credits = snap.data!.docs
            .map((e) => e.data() as Map<String, dynamic>)
            .toList();
        List<Map<String, dynamic>> filtered = credits;
        if (selectedClient != null) {
          filtered = filtered
              .where((v) =>
                  (clientsMap[v['clientId']] ?? v['clientNom'] ?? "") ==
                  selectedClient)
              .toList();
        }
        if (selectedLocalite != null) {
          filtered =
              filtered.where((v) => v['localite'] == selectedLocalite).toList();
        }
        if (selectedPeriode != null) {
          filtered = filtered.where((v) {
            final d = v['dateVente'];
            if (d is Timestamp) {
              final dt = d.toDate();
              return dt.isAfter(selectedPeriode!.start
                      .subtract(const Duration(days: 1))) &&
                  dt.isBefore(
                      selectedPeriode!.end.add(const Duration(days: 1)));
            }
            return true;
          }).toList();
        }
        _latestCollectesFiltered = filtered;

        return Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Date")),
                DataColumn(label: Text("Type")),
                DataColumn(label: Text("Client")),
                DataColumn(label: Text("Montant crédit")),
                DataColumn(label: Text("Montant remboursé")),
                DataColumn(label: Text("Montant restant")),
                DataColumn(label: Text("Etat")),
                DataColumn(label: Text("Voir détails")),
              ],
              rows: filtered.map((v) {
                final dateV = v['dateVente'] is Timestamp
                    ? (v['dateVente'] as Timestamp).toDate()
                    : null;
                String displayClient =
                    clientsMap[v['clientId']] ?? v['clientNom'] ?? "";
                String etat = v['etatCredit']?.toString() ?? "";
                return DataRow(
                  cells: [
                    DataCell(Text(dateV != null
                        ? DateFormat('dd/MM/yyyy').format(dateV)
                        : "")),
                    DataCell(Text(v['typeVente'] ?? "")),
                    DataCell(Text(displayClient)),
                    DataCell(Text("${v['montantTotal'] ?? ""}")),
                    DataCell(Text("${v['montantPaye'] ?? ""}")),
                    DataCell(Text("${v['montantRestant'] ?? ""}")),
                    DataCell(Text(etat)),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.info_outline,
                            color: Colors.deepPurple),
                        onPressed: () => showDetailsDialog(context, v,
                            title: "Détail du recouvrement"),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget buildStockTable(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('conditionnement').snapshots(),
      builder: (context, snap) {
        if (snap.hasError)
          return Center(child: Text('Erreur Firestore: ${snap.error}'));
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final lots = snap.data!.docs
            .map((e) => e.data() as Map<String, dynamic>)
            .toList();
        List<Map<String, dynamic>> filtered = lots;
        if (selectedStockLocalite != null) {
          filtered = filtered
              .where((l) => (l['localite'] ?? "") == selectedStockLocalite)
              .toList();
        }
        if (selectedStockMagasin != null) {
          filtered = filtered
              .where((l) => (l['magasin'] ?? "") == selectedStockMagasin)
              .toList();
        }
        _latestStockFiltered = filtered;

        return Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Date")),
                DataColumn(label: Text("Lot origine")),
                DataColumn(label: Text("Florale")),
                DataColumn(label: Text("Nb total pots")),
                DataColumn(label: Text("Qté conditionnée")),
                DataColumn(label: Text("Qté reçue")),
                DataColumn(label: Text("Qté restante")),
                DataColumn(label: Text("Voir détails")),
              ],
              rows: filtered.map((lot) {
                final dateC = lot['date'] is Timestamp
                    ? (lot['date'] as Timestamp).toDate()
                    : null;
                return DataRow(
                  cells: [
                    DataCell(Text(dateC != null
                        ? DateFormat('dd/MM/yyyy').format(dateC)
                        : "")),
                    DataCell(Text("${lot['lotOrigine'] ?? ""}")),
                    DataCell(Text("${lot['predominanceFlorale'] ?? ""}")),
                    DataCell(Text("${lot['nbTotalPots'] ?? ""}")),
                    DataCell(Text("${lot['quantiteConditionnee'] ?? ""}")),
                    DataCell(Text("${lot['quantiteRecue'] ?? ""}")),
                    DataCell(Text("${lot['quantiteRestante'] ?? ""}")),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.info_outline,
                            color: Colors.deepPurple),
                        onPressed: () => showDetailsDialog(context, lot,
                            title: "Détail du lot conditionné"),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
