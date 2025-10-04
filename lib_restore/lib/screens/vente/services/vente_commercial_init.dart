import 'vente_service.dart';
import 'package:get/get.dart';
import 'commercial_service.dart';
/// Initialisation unifiée des modules Vente + Commercial pour éviter les doubles chargements.

class VenteCommercialInitializer {
  VenteCommercialInitializer._();

  static Future<void> initialize({bool forceRefresh = false}) async {
    final commercial = Get.put(CommercialService());
    final vente = VenteService();

    // Charger en parallèle : lots + stats commerciales + produits conditionnés (cache TTL côté vente)
    await Future.wait([
      commercial.getLotsAvecCache(forceRefresh: forceRefresh),
      commercial.calculerStatistiques(forceRefresh: forceRefresh),
      vente.getProduitsConditionnesTotalement(forceRefresh: forceRefresh),
    ]);
  }
}
