import 'package:get/get.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apisavana_gestion/screens/vente/models/vente_models.dart';
import 'package:apisavana_gestion/screens/caisse/controllers/caisse_controller.dart';
import 'package:apisavana_gestion/screens/vente/controllers/espace_commercial_controller.dart';
// Assuming models & controller are accessible; these tests focus on pure recompute logic expectations.
// NOTE: Adjust imports according to actual project structure if needed.

/// These tests validate KPI formulas of CaisseController with controlled in-memory data.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CaisseController KPI calculations', () {
    late EspaceCommercialController espace;
    late CaisseController caisse;

    setUp(() {
      Get.testMode = true;
      espace = Get.put(EspaceCommercialController());
      caisse = Get.put(CaisseController());
      // Reset data lists
      espace.ventes.clear();
      espace.restitutions.clear();
      espace.pertes.clear();
    });

    tearDown(() {
      Get.delete<CaisseController>();
      Get.delete<EspaceCommercialController>();
    });

    test('Simple paid vente updates CA brut/net and efficiency', () async {
      final vente = Vente(
        id: 'V1',
        prelevementId: 'P1',
        commercialId: 'C1',
        commercialNom: 'Alice',
        clientId: 'CL1',
        clientNom: 'Client',
        clientTelephone: '',
        clientAdresse: '',
        dateVente: DateTime.now(),
        produits: [
          ProduitVendu(
            produitId: 'PR1',
            numeroLot: 'L1',
            typeEmballage: 'Sac 50kg',
            contenanceKg: 50,
            quantiteVendue: 2,
            prixUnitaire: 1000,
            prixVente: 1000,
            montantTotal: 2000,
          ),
        ],
        montantTotal: 2000,
        montantPaye: 2000,
        montantRestant: 0,
        modePaiement: ModePaiement.espece,
        statut: StatutVente.payeeEnTotalite,
        observations: null,
      );
      espace.ventes.add(vente);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(caisse.caBrut.value, 2000);
      expect(caisse.caNet.value, 2000);
      expect(caisse.creditAttente.value, 0);
      expect(caisse.efficacite.value, 100); // 2/(2) *100
    });

    test('Credit vente impacts CA net and credit attente', () async {
      final vente = Vente(
        id: 'V2',
        prelevementId: 'P1',
        commercialId: 'C1',
        commercialNom: 'Alice',
        clientId: 'CL1',
        clientNom: 'Client',
        clientTelephone: '',
        clientAdresse: '',
        dateVente: DateTime.now(),
        produits: [
          ProduitVendu(
            produitId: 'PR1',
            numeroLot: 'L1',
            typeEmballage: 'Sac 50kg',
            contenanceKg: 50,
            quantiteVendue: 1,
            prixUnitaire: 1000,
            prixVente: 1000,
            montantTotal: 1000,
          ),
        ],
        montantTotal: 1000,
        montantPaye: 200,
        montantRestant: 800,
        modePaiement: ModePaiement.espece,
        statut: StatutVente.creditEnAttente,
        observations: null,
      );
      espace.ventes.add(vente);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(caisse.caBrut.value, 1000);
      expect(caisse.caNet.value, 200); // brut - creditAttente (800)
      expect(caisse.creditAttente.value, 800);
    });

    test('Restitution and perte adjust rates and efficiency', () async {
      final vente = Vente(
        id: 'V3',
        prelevementId: 'P1',
        commercialId: 'C1',
        commercialNom: 'Alice',
        clientId: 'CL2',
        clientNom: 'Client2',
        clientTelephone: '',
        clientAdresse: '',
        dateVente: DateTime.now(),
        produits: [
          ProduitVendu(
            produitId: 'PR1',
            numeroLot: 'L1',
            typeEmballage: 'Sac 50kg',
            contenanceKg: 50,
            quantiteVendue: 3,
            prixUnitaire: 1000,
            prixVente: 1000,
            montantTotal: 3000,
          ),
        ],
        montantTotal: 3000,
        montantPaye: 3000,
        montantRestant: 0,
        modePaiement: ModePaiement.espece,
        statut: StatutVente.payeeEnTotalite,
        observations: null,
      );
      espace.ventes.add(vente);

      final rest = Restitution(
        id: 'R1',
        prelevementId: 'P1',
        commercialId: 'C1',
        commercialNom: 'Alice',
        dateRestitution: DateTime.now(),
        produits: [
          ProduitRestitue(
            produitId: 'PR1',
            numeroLot: 'L1',
            typeEmballage: 'Sac 50kg',
            quantiteRestituee: 1,
            valeurUnitaire: 1000,
            etatProduit: 'BON',
          ),
        ],
        valeurTotale: 1000,
        type: TypeRestitution.defaut,
        motif: 'Test restitution',
      );
      espace.restitutions.add(rest);

      final perte = Perte(
        id: 'PER1',
        prelevementId: 'P1',
        commercialId: 'C1',
        commercialNom: 'Alice',
        datePerte: DateTime.now(),
        produits: [
          ProduitPerdu(
            produitId: 'PR1',
            numeroLot: 'L1',
            typeEmballage: 'Sac 50kg',
            quantitePerdue: 1,
            valeurUnitaire: 1000,
            circonstances: 'Test perte',
          ),
        ],
        valeurTotale: 1000,
        type: TypePerte.casse,
        motif: 'Test perte',
        estValidee: false,
      );
      espace.pertes.add(perte);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(caisse.valeurRestitutions.value, 1000);
      expect(caisse.valeurPertes.value, 1000);
      expect(caisse.tauxRestitution.value, closeTo(1000 / 3000 * 100, 0.001));
      expect(caisse.tauxPertes.value, closeTo(1000 / 3000 * 100, 0.001));
      // produits vendus=3 restitués=1 perdus=1 => efficacité = 3/5
      expect(caisse.efficacite.value, closeTo(3 / 5 * 100, 0.001));
    });

    test('Ventilation modes paiement et anomalie crédits', () async {
      // Trois ventes: 2 espèces, 1 mobile, plus crédits élevés
      final now = DateTime.now();
      final ventes = [
        Vente(
          id: 'V4',
          prelevementId: 'P2',
          commercialId: 'C1',
          commercialNom: 'Alice',
          clientId: 'CL3',
          clientNom: 'X',
          clientTelephone: '',
          clientAdresse: '',
          dateVente: now,
          produits: [
            ProduitVendu(
                produitId: 'PRX',
                numeroLot: 'L1',
                typeEmballage: 'Sac 50kg',
                contenanceKg: 50,
                quantiteVendue: 1,
                prixUnitaire: 1000,
                prixVente: 1000,
                montantTotal: 1000)
          ],
          montantTotal: 1000,
          montantPaye: 1000,
          montantRestant: 0,
          modePaiement: ModePaiement.espece,
          statut: StatutVente.payeeEnTotalite,
          observations: null,
        ),
        Vente(
          id: 'V5',
          prelevementId: 'P2',
          commercialId: 'C1',
          commercialNom: 'Alice',
          clientId: 'CL3',
          clientNom: 'X',
          clientTelephone: '',
          clientAdresse: '',
          dateVente: now,
          produits: [
            ProduitVendu(
                produitId: 'PRX',
                numeroLot: 'L1',
                typeEmballage: 'Sac 50kg',
                contenanceKg: 50,
                quantiteVendue: 2,
                prixUnitaire: 1000,
                prixVente: 1000,
                montantTotal: 2000)
          ],
          montantTotal: 2000,
          montantPaye: 0,
          montantRestant: 2000,
          modePaiement: ModePaiement.espece,
          statut: StatutVente.creditEnAttente,
          observations: null,
        ),
        Vente(
          id: 'V6',
          prelevementId: 'P2',
          commercialId: 'C1',
          commercialNom: 'Alice',
          clientId: 'CL4',
          clientNom: 'Y',
          clientTelephone: '',
          clientAdresse: '',
          dateVente: now,
          produits: [
            ProduitVendu(
                produitId: 'PRX',
                numeroLot: 'L1',
                typeEmballage: 'Sac 50kg',
                contenanceKg: 50,
                quantiteVendue: 1,
                prixUnitaire: 5000,
                prixVente: 5000,
                montantTotal: 5000)
          ],
          montantTotal: 5000,
          montantPaye: 5000,
          montantRestant: 0,
          modePaiement: ModePaiement.mobile,
          statut: StatutVente.payeeEnTotalite,
          observations: null,
        ),
      ];
      espace.ventes.addAll(ventes);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(caisse.caBrut.value, 8000); // 1k +2k +5k
      expect(caisse.caEspece.value, 3000);
      expect(caisse.caMobile.value, 5000);
      expect(caisse.caAutres.value, 0);
      expect(caisse.pctEspece.value, closeTo(3000 / 8000 * 100, 0.001));
      expect(caisse.pctMobile.value, closeTo(5000 / 8000 * 100, 0.001));
      // Crédit en attente = 2000
      expect(caisse.creditAttente.value, 2000);
      // CA Net = 8000 - 2000 = 6000
      expect(caisse.caNet.value, 6000);
      // Anomalie crédits si >40%? 2000/8000 = 25% => pas d'anomalie crédit ici
      expect(caisse.anomalies.any((a) => a.contains('Crédits')), false);

      // Ajouter des ventes crédit pour dépasser 40%
      final creditBoost = Vente(
        id: 'V7',
        prelevementId: 'P2',
        commercialId: 'C1',
        commercialNom: 'Alice',
        clientId: 'CL5',
        clientNom: 'Z',
        clientTelephone: '',
        clientAdresse: '',
        dateVente: now,
        produits: [
          ProduitVendu(
              produitId: 'PRX',
              numeroLot: 'L1',
              typeEmballage: 'Sac 50kg',
              contenanceKg: 50,
              quantiteVendue: 5,
              prixUnitaire: 1000,
              prixVente: 1000,
              montantTotal: 5000)
        ],
        montantTotal: 5000,
        montantPaye: 0,
        montantRestant: 5000,
        modePaiement: ModePaiement.espece,
        statut: StatutVente.creditEnAttente,
        observations: null,
      );
      espace.ventes.add(creditBoost);
      await Future.delayed(const Duration(milliseconds: 20));
      // Nouveau CA brut = 13000 ; crédits = 7000 -> ~53.8%
      expect(caisse.anomalies.any((a) => a.contains('Crédits élevés')), true);
    });
  });
}
