import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/models/collecte_models.dart';

class ModalSelectionProducteurReactive extends StatefulWidget {
  final String nomSite;
  final ProducteurModel? producteurSelectionne;

  const ModalSelectionProducteurReactive({
    Key? key,
    required this.nomSite,
    this.producteurSelectionne,
  }) : super(key: key);

  @override
  State<ModalSelectionProducteurReactive> createState() =>
      _ModalSelectionProducteurReactiveState();
}

class _ModalSelectionProducteurReactiveState
    extends State<ModalSelectionProducteurReactive> {
  late TextEditingController _rechercheController;
  String _queryRecherche = '';

  @override
  void initState() {
    super.initState();
    _rechercheController = TextEditingController();
    print(
        "🚀 ModalSelectionProducteurReactive - Initialisation ULTRA-RÉACTIVE");
    print(
        "🔒 GARANTIE: StreamBuilder pour mise à jour temps réel depuis listes_prod");
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  void _filtrerProducteurs(String query) {
    setState(() {
      _queryRecherche = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      ),
      child: Container(
        width: isSmallScreen ? double.infinity : 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.orange[600],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isSmallScreen ? 12 : 16),
                  topRight: Radius.circular(isSmallScreen ? 12 : 16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Colors.white,
                    size: isSmallScreen ? 20 : 24,
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Expanded(
                    child: Text(
                      'Sélectionner un producteur (Temps réel)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 6 : 8,
                      vertical: isSmallScreen ? 2 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sync,
                          color: Colors.white,
                          size: isSmallScreen ? 12 : 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 10 : 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Barre de recherche
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: TextField(
                controller: _rechercheController,
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom ou numéro...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                    vertical: isSmallScreen ? 8 : 10,
                  ),
                ),
                onChanged: _filtrerProducteurs,
              ),
            ),

            // Liste des producteurs avec StreamBuilder ULTRA-RÉACTIF
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Sites')
                    .doc(widget.nomSite)
                    .collection('listes_prod')
                    .orderBy('nomPrenom')
                    .snapshots(),
                builder: (context, snapshot) {
                  print(
                      "🚀 StreamBuilder - État connexion: ${snapshot.connectionState}");

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    print("🔴 StreamBuilder - Erreur: ${snapshot.error}");
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 48),
                          SizedBox(height: 16),
                          Text(
                            'Erreur de chargement',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    print("🔴 StreamBuilder - Aucune donnée trouvée");
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'Aucun producteur trouvé',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Ajoutez des producteurs pour commencer',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }

                  // Conversion et filtrage des producteurs
                  final producteurs = snapshot.data!.docs
                      .map((doc) {
                        try {
                          return ProducteurModel.fromFirestore(doc);
                        } catch (e) {
                          print(
                              "🔴 Erreur conversion producteur ${doc.id}: $e");
                          return null;
                        }
                      })
                      .where((producteur) => producteur != null)
                      .cast<ProducteurModel>()
                      .toList();

                  print(
                      "🚀 StreamBuilder - ${producteurs.length} producteurs chargés en temps réel");

                  // Filtrage selon la recherche
                  final producteursAffiches = _queryRecherche.isEmpty
                      ? producteurs
                      : producteurs
                          .where((producteur) =>
                              producteur.nomPrenom
                                  .toLowerCase()
                                  .contains(_queryRecherche) ||
                              producteur.numero
                                  .toLowerCase()
                                  .contains(_queryRecherche) ||
                              producteur.localisation['village']
                                      ?.toLowerCase()
                                      .contains(_queryRecherche) ==
                                  true)
                          .toList();

                  print(
                      "🔍 StreamBuilder - ${producteursAffiches.length} producteurs après filtrage");

                  if (producteursAffiches.isEmpty &&
                      _queryRecherche.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'Aucun résultat pour "${_rechercheController.text}"',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Essayez avec un autre terme de recherche',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16),
                    itemCount: producteursAffiches.length,
                    itemBuilder: (context, index) {
                      final producteur = producteursAffiches[index];
                      final estSelectionne =
                          widget.producteurSelectionne?.id == producteur.id;

                      return Card(
                        elevation: estSelectionne ? 4 : 1,
                        margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: estSelectionne
                              ? BorderSide(color: Colors.orange[600]!, width: 2)
                              : BorderSide.none,
                        ),
                        child: ListTile(
                          contentPadding:
                              EdgeInsets.all(isSmallScreen ? 8 : 12),
                          leading: CircleAvatar(
                            backgroundColor: estSelectionne
                                ? Colors.orange[600]
                                : Colors.grey[300],
                            child: Text(
                              producteur.nomPrenom.isNotEmpty
                                  ? producteur.nomPrenom[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: estSelectionne
                                    ? Colors.white
                                    : Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            producteur.nomPrenom,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : 15,
                              color: estSelectionne ? Colors.orange[600] : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.badge,
                                    size: isSmallScreen ? 14 : 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'N° ${producteur.numero}',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: isSmallScreen ? 14 : 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      producteur.localisation['village'] ??
                                          'Village non spécifié',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (producteur.nombreCollectes > 0) ...[
                                SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.inventory,
                                      size: isSmallScreen ? 14 : 16,
                                      color: Colors.green[600],
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '${producteur.nombreCollectes} collecte(s)',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 13,
                                        color: Colors.green[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          trailing: estSelectionne
                              ? Icon(
                                  Icons.check_circle,
                                  color: Colors.orange[600],
                                  size: isSmallScreen ? 20 : 24,
                                )
                              : Icon(
                                  Icons.arrow_forward_ios,
                                  size: isSmallScreen ? 16 : 18,
                                  color: Colors.grey[400],
                                ),
                          onTap: () {
                            print(
                                "✅ Producteur sélectionné (temps réel): ${producteur.nomPrenom}");
                            print(
                                "🔒 CONFIRMATION: Données lues depuis listes_prod en temps réel");
                            Navigator.of(context).pop(producteur);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Pied de page
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(isSmallScreen ? 12 : 16),
                  bottomRight: Radius.circular(isSmallScreen ? 12 : 16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: isSmallScreen ? 16 : 18,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Données mises à jour en temps réel depuis listes_prod',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
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
}
