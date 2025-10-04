# Documentation Espace Caissier

## Objectif
Fournir au caissier une vision consolidée et temps réel des performances financières quotidiennes ou sur une période sélectionnée, tout en détectant précocement des anomalies opérationnelles (trop de crédits, pertes élevées, restitutions massives, annulations répétées).

## Sources de données
Toutes les données proviennent en flux réactif de `EspaceCommercialController` :
- `ventes` (liste des ventes)
- `restitutions` (produits retournés)
- `pertes` (produits perdus / cassés / avariés)

Le `CaisseController` n'effectue aucune requête Firestore supplémentaire. Il filtre et agrège localement.

## Filtres
- Période (`DateTimeRange`) : bornes inclusives (>= start && <= end)
- Commercial (optionnel) : si vide => tous, sinon filtre sur `commercialId`.

## Définitions des KPIs
| KPI | Définition | Formule |
|-----|------------|---------|
| CA Brut | Somme des `montantTotal` des ventes non annulées | Σ ventes (statut != annulée) montantTotal |
| Crédits en Attente | Somme des ventes au statut `creditEnAttente` | Σ ventes (statut = creditEnAttente) montantTotal |
| Crédits Remboursés | Somme des ventes au statut `creditRembourse` | Σ ventes (statut = creditRembourse) montantTotal |
| CA Net | CA Brut - Crédits en Attente | CA Brut - CréditsAttente |
| Valeur Restitutions | Somme `valeurTotale` des restitutions | Σ restitutions valeurTotale |
| Valeur Pertes | Somme `valeurTotale` des pertes | Σ pertes valeurTotale |
| Taux Restitution | Pourcentage de restitution par rapport au CA Brut | (Valeur Restitutions / CA Brut) * 100 |
| Taux Pertes | Pourcentage de pertes par rapport au CA Brut | (Valeur Pertes / CA Brut) * 100 |
| Cash Théorique | Montant d'argent qui devrait être encaissé (exclut crédits en attente) | CA Net |
| Efficacité Produits | Part des produits vendus vs (vendus + restitués + perdus) | (Produits Vendus / (Vend + Rest + Perdus)) * 100 |
| CA Espèce | Montant total des ventes réglées en espèces | Σ ventes (mode=espece) montantTotal |
| CA Mobile | Montant total des ventes réglées via mobile money | Σ ventes (mode=mobile) montantTotal |
| CA Autres | Montant total ventes autres moyens (carte/virement/chèque/crédit) | Σ ventes (modes divers) montantTotal |
| % Espèce | Part du CA Brut en espèces | (CA Espèce / CA Brut) * 100 |
| % Mobile | Part du CA Brut en mobile money | (CA Mobile / CA Brut) * 100 |
| % Autres | Part du CA Brut autres moyens | (CA Autres / CA Brut) * 100 |

Notes :
- Une vente annulée n'entre dans aucun calcul (ni CA Brut, ni produits vendus).
- Les restitutions et pertes n'altèrent pas le CA Brut (base de facturation) mais influencent les taux et l'efficacité.

## Timeline CA
Agrégation des montants des ventes par :
- Heure (format `HH`) si la période est une seule journée.
- Jour (format `dd/MM`) sinon.
Ordonnée : somme des `montantTotal` (ventes non annulées). Résultat: liste ordonnée par label croissant.

## Top Produits (Top 5)
Agrégation par `typeEmballage` :
- Quantité vendue cumulée
- Montant total cumulé
Tri descendant sur le montant, prise des 5 premiers.

## Anomalies Détectées
Règles (évaluées après calcul des KPIs) :
1. Ventes annulées >= 3 => "Beaucoup de ventes annulées (X)"
2. Crédits en attente > 40% du CA Brut => "Crédits élevés (>40% CA)"
3. Taux de pertes > 5% => "Taux de pertes anormal (>5%)"
4. Taux de restitution > 30% => "Taux de restitution élevé (>30%)"
5. Ventilation extrême: si CA Brut > 100 000 et un mode >90% => "Dépendance forte à l'espèce" ou "... au mobile money"

Ces règles sont extensibles (ajouter une fonction dédiée si nécessaire).

## Flux de Recalcul (`_recompute`)
1. Filtrage des listes selon période + commercial.
2. Calcul CA, crédits, produits vendus.
3. Calcul restitutions & pertes (valeurs + quantités).
4. Dérivation CA Net, Cash Théorique, Taux*, Efficacité.
5. Génération Top Produits.
6. Construction Timeline.
7. Détection Anomalies.

Chaque modification d'un flux ou d'un filtre déclenche `everAll` -> `_recompute()`.

## Exemple Numérique Simple
- Ventes (non annulées): 3 ventes de 1000 FCFA => CA Brut = 3000
- Crédits en attente: 1 vente (statut creditEnAttente) de 1000 => Crédits en attente = 1000
- CA Net = 3000 - 1000 = 2000
- Restitutions: 500 FCFA => Taux Restitution = 500 / 3000 * 100 = 16.67%
- Pertes: 300 FCFA => Taux Pertes = 300 / 3000 * 100 = 10%
- Produits : vendus 30, restitués 5, perdus 3 => Efficacité = 30 / 38 * 100 = 78.95%
- Cash Théorique = CA Net = 2000

## Checklist Validation Manuelle
1. Créer plusieurs ventes (payées & crédit) => vérifier CA Brut, Crédits, CA Net.
2. Ajouter restitutions => observer mise à jour taux restitution.
3. Ajouter pertes => observer mise à jour taux pertes.
4. Annuler >=3 ventes => apparition alerte correspondante.
5. Simuler crédits >40% CA => alerte crédit.
6. Vérifier timeline change jour vs heure selon période.
7. Filtrer par commercial => KPIs recalculés uniquement sur son périmètre.

## Stratégie d'Ajustement Futur
- Introduire Cash Réel + Ecart => nécessite table d'encaissements physiques.
- Ajouter export PDF / CSV des KPIs + timeline.
- Historisation journalière (snapshot fin de journée) pour analyses rétrospectives.

## Limitations Actuelles
- Pas de persistance des clôtures de caisse.
- Ventilation enregistrée mais pas d'analyse historique (pas de moyenne glissante). 
- Efficacité simple (un poids/quantité plus élaboré possible si multi-unités).

## Export CSV
Un bouton "Exporter CSV" copie dans le presse-papiers un flux structuré :
```
Section;Cle;Valeur
KPIs;CaBrut;12345.00
Timeline;12;3400.00
TopProduit;Sac 50kg;89000.00
Anomalies;Alerte;Crédits élevés (>40% CA)
```
Options futures : sauvegarde fichier, export PDF, envoi email automatique.

## Extension Proposée (Backlog)
- Segmentation clients (taux de crédit par type client).
- Heatmap horaire des ventes.
- Seuils dynamiques d'anomalies adaptatifs (basés sur moyenne glissante historique).

---
Dernière mise à jour: 2025-09-15
