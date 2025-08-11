import 'package:flutter/material.dart';
import '../../../../data/models/collecte_models.dart';

class ModalSelectionProducteur extends StatefulWidget {
  final List<ProducteurModel> producteurs;
  final ProducteurModel? producteurSelectionne;

  const ModalSelectionProducteur({
    Key? key,
    required this.producteurs,
    this.producteurSelectionne,
  }) : super(key: key);

  @override
  State<ModalSelectionProducteur> createState() =>
      _ModalSelectionProducteurState();
}

class _ModalSelectionProducteurState extends State<ModalSelectionProducteur> {
  late TextEditingController _rechercheController;
  List<ProducteurModel> _producteursAffiches = [];

  @override
  void initState() {
    super.initState();
    _rechercheController = TextEditingController();
    _producteursAffiches = widget.producteurs;
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  void _filtrerProducteurs(String query) {
    setState(() {
      if (query.isEmpty) {
        _producteursAffiches = widget.producteurs;
      } else {
        _producteursAffiches = widget.producteurs
            .where((producteur) =>
                producteur.nomPrenom
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                producteur.numero.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
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
                      'Sélectionner un producteur',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: TextField(
                controller: _rechercheController,
                onChanged: _filtrerProducteurs,
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom ou numéro...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: isSmallScreen ? 12 : 16,
                  ),
                  hintStyle: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                ),
                style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
              ),
            ),

            // Liste des producteurs
            Expanded(
              child: _producteursAffiches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: isSmallScreen ? 48 : 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          Text(
                            'Aucun producteur trouvé',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16),
                      itemCount: _producteursAffiches.length,
                      itemBuilder: (context, index) {
                        final producteur = _producteursAffiches[index];
                        final estSelectionne =
                            widget.producteurSelectionne?.id == producteur.id;

                        return Card(
                          margin:
                              EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
                          elevation: estSelectionne ? 3 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(isSmallScreen ? 8 : 10),
                            side: BorderSide(
                              color: estSelectionne
                                  ? Colors.orange[300]!
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                              decoration: BoxDecoration(
                                color: estSelectionne
                                    ? Colors.orange[100]
                                    : Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                color: estSelectionne
                                    ? Colors.orange[600]
                                    : Colors.grey[600],
                                size: isSmallScreen ? 18 : 20,
                              ),
                            ),
                            title: Text(
                              producteur.nomPrenom,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 15,
                                fontWeight: estSelectionne
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color:
                                    estSelectionne ? Colors.orange[800] : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'N° ${producteur.numero}',
                                  style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 13),
                                ),
                                SizedBox(height: isSmallScreen ? 2 : 4),
                                Row(
                                  children: [
                                    Icon(Icons.hive,
                                        size: isSmallScreen ? 12 : 14,
                                        color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Text(
                                      '${producteur.totalRuches} ruches',
                                      style: TextStyle(
                                          fontSize: isSmallScreen ? 11 : 12),
                                    ),
                                    SizedBox(width: isSmallScreen ? 8 : 12),
                                    Icon(Icons.assessment,
                                        size: isSmallScreen ? 12 : 14,
                                        color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Text(
                                      '${producteur.nombreCollectes} collectes',
                                      style: TextStyle(
                                          fontSize: isSmallScreen ? 11 : 12),
                                    ),
                                  ],
                                ),
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
                            onTap: () => Navigator.of(context).pop(producteur),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 12 : 16,
                              vertical: isSmallScreen ? 4 : 8,
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Boutons d'action
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Annuler',
                        style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 12 : 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(isSmallScreen ? 8 : 10),
                        ),
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
