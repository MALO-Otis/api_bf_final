import 'package:flutter/material.dart';
import '../../../../data/models/collecte_models.dart';

class SectionProducteur extends StatelessWidget {
  final ProducteurModel? producteurSelectionne;
  final VoidCallback onSelectProducteur;
  final VoidCallback onAddProducteur;
  final VoidCallback? onChangeProducteur;

  const SectionProducteur({
    Key? key,
    required this.producteurSelectionne,
    required this.onSelectProducteur,
    required this.onAddProducteur,
    this.onChangeProducteur,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: Opacity(
            opacity: value,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.orange[600],
                            size: isSmallScreen ? 18 : 22,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Text(
                          'Producteur',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    if (producteurSelectionne == null)
                      _buildNoProducteurSelected(isSmallScreen)
                    else
                      _buildProducteurSelected(isSmallScreen),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoProducteurSelected(bool isSmallScreen) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onSelectProducteur,
            icon: Icon(
              Icons.search,
              size: isSmallScreen ? 16 : 18,
            ),
            label: Text(
              'Sélectionner un producteur',
              style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 10 : 12,
                horizontal: isSmallScreen ? 12 : 16,
              ),
              side: BorderSide(color: Colors.orange[400]!),
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onAddProducteur,
            icon: Icon(
              Icons.person_add,
              size: isSmallScreen ? 16 : 18,
            ),
            label: Text(
              'Ajouter un nouveau producteur',
              style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 10 : 12,
                horizontal: isSmallScreen ? 12 : 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProducteurSelected(bool isSmallScreen) {
    final producteur = producteurSelectionne!;
    final localisation = producteur.localisation;
    final localisationText = [
      localisation['region'],
      localisation['province'],
      localisation['commune'],
      localisation['village'],
    ].where((s) => s != null && s.isNotEmpty).join(' > ');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producteur.nomPrenom,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 4 : 6),
                    _buildProducteurInfo(
                      Icons.phone,
                      'N° ${producteur.numero}',
                      isSmallScreen,
                    ),
                    _buildProducteurInfo(
                      Icons.location_on,
                      localisationText,
                      isSmallScreen,
                    ),
                    _buildProducteurInfo(
                      Icons.group_work,
                      producteur.appartenance == 'Propre'
                          ? 'Producteur individuel'
                          : 'Coopérative: ${producteur.cooperative}',
                      isSmallScreen,
                    ),
                    _buildProducteurInfo(
                      Icons.hive,
                      '${producteur.totalRuches} ruches (${producteur.nbRuchesTrad} trad. + ${producteur.nbRuchesMod} mod.)',
                      isSmallScreen,
                    ),
                  ],
                ),
              ),
              if (onChangeProducteur != null)
                Column(
                  children: [
                    IconButton(
                      onPressed: onChangeProducteur,
                      icon: Icon(
                        Icons.edit,
                        color: Colors.green[600],
                        size: isSmallScreen ? 18 : 20,
                      ),
                      tooltip: 'Changer de producteur',
                    ),
                    Text(
                      'Changer',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 11,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 10),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green[700],
                  size: isSmallScreen ? 16 : 18,
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Text(
                  'Producteur sélectionné avec succès',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProducteurInfo(IconData icon, String text, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 2 : 3),
      child: Row(
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 14 : 16,
            color: Colors.green[600],
          ),
          SizedBox(width: isSmallScreen ? 4 : 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                color: Colors.green[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
