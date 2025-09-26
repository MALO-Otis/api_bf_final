// ====================================================================
// FICHIER DE RÉFÉRENCE POUR L'ANCIEN CODE DE COLLECTE
// Contient les définitions nécessaires pour comprendre l'ancien système
// NE PAS UTILISER EN PRODUCTION - RÉFÉRENCE SEULEMENT
// ====================================================================

// Énumérations utilisées dans l'ancien système
import 'package:flutter/material.dart';

enum TypeCollecte { recolte, achat }

enum OrigineAchat { scoops, individuel }

// Classes de données de l'ancien système
class AchatProduitData {
  final String unite;
  final double quantiteAcceptee = 0.0;
  final double quantiteRejetee = 0.0;
  final double prixUnitaire = 0.0;
  final double prixTotal = 0.0;

  AchatProduitData({required this.unite});
}

// Données géographiques simplifiées pour référence
const List<String> regionsBurkinaAncien = [
  'CASCADES',
  'HAUTS-BASSINS',
  'BOUCLE DU MOUHOUN',
  'CENTRE-OUEST',
  'CENTRE-SUD',
  'SUD-OUEST',
];

// Structure des arrondissements de l'ancien système
const Map<String, List<String>> ArrondissementsParCommune = {
  'Ouagadougou': [
    'Baskuy',
    'Bogodogo',
    'Boulmiougou',
    'Nongremassom',
    'Sig-Nonghin'
  ],
  'Bobo-Dioulasso': ['Dô', 'Konsa', 'Secteur 1-30'],
};

// Secteurs par arrondissement (référence)
const Map<String, List<String>> secteursParArrondissement = {
  'Baskuy': ['Secteur 1', 'Secteur 2', 'Secteur 3'],
  'Bogodogo': ['Secteur 4', 'Secteur 5', 'Secteur 6'],
  // ... autres secteurs
};

// Quartiers par secteur (référence)
const Map<String, List<String>> QuartierParSecteur = {
  'Secteur 1': ['Quartier A', 'Quartier B'],
  'Secteur 2': ['Quartier C', 'Quartier D'],
  // ... autres quartiers
};

// Fonctions utilitaires pour validation (référence)
bool validateDropdown(String? value, String fieldName) {
  if (value == null || value.isEmpty) {
    print('Erreur: $fieldName requis');
    return false;
  }
  return true;
}

bool validateDouble(String value, String fieldName) {
  final parsed = double.tryParse(value);
  if (parsed == null || parsed < 0) {
    print('Erreur: $fieldName invalide');
    return false;
  }
  return true;
}

void showFieldError(String title, String message) {
  print('$title: $message');
}

// Widget personnalisé de l'ancien système
class CustomMultiSelectCard extends StatelessWidget {
  final String value;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const CustomMultiSelectCard({
    Key? key,
    required this.value,
    required this.label,
    required this.selected,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Ancien widget - non fonctionnel'),
    );
  }
}

// ====================================================================
// NOTE: Ce fichier est fourni uniquement pour comprendre l'ancien code
// Les classes et fonctions ne sont pas complètement implémentées
// ====================================================================
