import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/commercial_models.dart';
import '../widgets/gestion_commerciaux_tab.dart';
import '../../../authentication/user_session.dart';
import '../controllers/espace_commercial_controller.dart';
import '../../caisse/services/transaction_commerciale_service.dart';
import 'package:apisavana_gestion/screens/commercialisation/new_client_quick_form.dart';
// import '../models/vente_models.dart'; // non utilisé directement ici

class EspaceCommercialPage extends StatelessWidget {
  const EspaceCommercialPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EspaceCommercialController());
    final session = Get.find<UserSession>();
    final isAdmin = controller.isAdminRole;

    return DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            title: Text(isAdmin
                ? 'Espace Commercial (Admin)'
                : 'Mon Espace Commercial'),
            actions: [
              if (isAdmin)
                Obx(() => DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.selectedSite.value.isEmpty
                            ? null
                            : controller.selectedSite.value,
                        hint: const Text('Site'),
                        onChanged: (v) {
                          controller.selectedSite.value = v ?? '';
                          controller.loadAll(forceRefresh: true);
                        },
                        items: (controller.isAdminRole
                                ? controller.availableSites
                                : <String>[controller.effectiveSite])
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                      ),
                    )),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => controller.loadAll(forceRefresh: true),
                tooltip: 'Rafraîchir',
              )
            ],
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Attributions'),
                Tab(text: 'Ventes'),
                Tab(text: 'Restitutions'),
                Tab(text: 'Pertes'),
                Tab(text: 'Clients'),
              ],
            ),
          ),
          body: Obx(() => controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(controller, session, isAdmin)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              // site context
              final site = controller.effectiveSite;
              final result = await Get.to(() => NewClientQuickFormPage(
                    site: site,
                    currentUserId: session.uid ?? 'inconnu',
                  ));
              if (result == true) {
                // Pas besoin de tout recharger lourdement; on pourrait plus tard gérer un cache clients
                Get.snackbar('Client', 'Nouveau client enregistré');
              }
            },
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Client'),
          ),
        ));
  }

  Widget _buildContent(
      EspaceCommercialController c, UserSession session, bool isAdmin) {
    // Role guard: allow roles Admin, Magazinier, Gestionnaire Commercial, Commercial
    final role = session.role ?? '';
    final allowed = [
      'Admin',
      'Magazinier',
      'Gestionnaire Commercial',
      'Commercial'
    ];
    if (!allowed.contains(role)) {
      return LayoutBuilder(builder: (context, _) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 64, color: Colors.orangeAccent),
                const SizedBox(height: 16),
                Text('Accès restreint',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Votre rôle actuel (${role.isEmpty ? 'Inconnu' : role}) ne permet pas d\'accéder à l\'espace commercial.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      });
    }
    return TabBarView(
      children: [
        _buildAttributions(c),
        _buildVentes(c),
        _buildRestitutions(c),
        _buildPertes(c),
        _buildClients(c),
      ],
    );
  }

  Widget _buildAttributions(EspaceCommercialController c) {
    final items = c.filteredAttributions;
    return _buildScrollableList(
      emptyLabel: 'Aucune attribution',
      c: c,
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        final a = items[index];
        final consomme = c.attributionConsomme[a.id] ?? 0;
        final restant =
            c.attributionRestant[a.id] ?? (a.quantiteAttribuee - consomme);
        final progression =
            c.attributionProgression[a.id]?.toStringAsFixed(1) ?? '0';
        return ListTile(
          leading: const Icon(Icons.assignment_turned_in_outlined),
          title: Text('Lot ${a.numeroLot} • ${a.typeEmballage}'),
          subtitle: Text(
              '${a.quantiteAttribuee} attribuées • $consomme consommées • $restant restantes\n${a.commercialNom} • ${a.siteOrigine} • ${a.dateAttribution.toString().split(' ').first}'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${progression}%'),
              const SizedBox(height: 4),
              SizedBox(
                width: 60,
                child: LinearProgressIndicator(
                  value: (c.attributionProgression[a.id] ?? 0) / 100,
                  backgroundColor: Colors.grey.shade300,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVentes(EspaceCommercialController c) {
    final items = c.filteredVentes;
    return _buildScrollableList(
      emptyLabel: 'Aucune vente',
      c: c,
      itemCount: items.length,
      itemBuilder: (_, i) {
        final v = items[i];
        final vendeur = c.displayNameForEmail(v.commercialId);

        // Calculer les quantités pour l'attribution liée à cette vente
        AttributionPartielle? attribution;
        try {
          attribution =
              c.attributions.firstWhere((a) => a.id == v.prelevementId);
        } catch (e) {
          attribution = null;
        }

        String quantiteInfo = '';
        if (attribution != null) {
          final restant = c.attributionRestant[attribution.id] ??
              (attribution.quantiteAttribuee -
                  (c.attributionConsomme[attribution.id] ?? 0));
          final consomme = c.attributionConsomme[attribution.id] ?? 0;
          quantiteInfo =
              '\nAttribution: ${attribution.quantiteAttribuee} → $restant restantes (${consomme} vendues)';
        }

        return ListTile(
          leading: const Icon(Icons.point_of_sale),
          title: Text(v.clientNom),
          subtitle: Text(
              '${v.produits.length} produits • ${v.montantTotal.toStringAsFixed(0)} FCFA\nVendeur: $vendeur$quantiteInfo'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(v.dateVente.toString().split(' ').first),
              if (v.montantRestant > 0)
                Text('Reste: ${v.montantRestant.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(fontSize: 10, color: Colors.orange)),
              const SizedBox(height: 6),
              if (c.getValidationExpiry(v.id) != null)
                CountdownBox(
                    expiry: c.getValidationExpiry(v.id)!,
                    onCancel: () async {
                      // call undo on legacy validation
                      await TransactionCommercialeService.instance
                          .annulerLegacyValidation(
                              site: c.effectiveSite,
                              elementType: 'vente',
                              elementId: v.id);
                      // refresh controller lists
                      c.loadAll();
                    }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRestitutions(EspaceCommercialController c) {
    final items = c.filteredRestitutions;
    return _buildScrollableList(
      emptyLabel: 'Aucune restitution',
      c: c,
      itemCount: items.length,
      itemBuilder: (_, i) {
        final r = items[i];
        final commercial = c.displayNameForEmail(r.commercialId);
        return ListTile(
          leading: const Icon(Icons.undo),
          title: Text(r.motif),
          subtitle: Text(
              '${r.produits.length} produits • ${r.valeurTotale.toStringAsFixed(0)} FCFA\nCommercial: $commercial'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(r.dateRestitution.toString().split(' ').first),
              if (c.getValidationExpiry(r.id) != null)
                CountdownBox(
                    expiry: c.getValidationExpiry(r.id)!,
                    onCancel: () async {
                      await TransactionCommercialeService.instance
                          .annulerLegacyValidation(
                              site: c.effectiveSite,
                              elementType: 'restitution',
                              elementId: r.id);
                      c.loadAll();
                    }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPertes(EspaceCommercialController c) {
    final items = c.filteredPertes;
    return _buildScrollableList(
      emptyLabel: 'Aucune perte',
      c: c,
      itemCount: items.length,
      itemBuilder: (_, i) {
        final p = items[i];
        final commercial = c.displayNameForEmail(p.commercialId);
        final validateur = p.validateurId != null
            ? c.displayNameForEmail(p.validateurId)
            : null;
        return ListTile(
          leading: Icon(p.estValidee ? Icons.verified : Icons.warning_amber),
          title: Text(p.motif),
          subtitle: Text(
              '${p.produits.length} produits • ${p.valeurTotale.toStringAsFixed(0)} FCFA\nCommercial: $commercial${validateur != null ? '\nValidé par: $validateur' : ''}'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(p.datePerte.toString().split(' ').first),
              if (c.getValidationExpiry(p.id) != null)
                CountdownBox(
                    expiry: c.getValidationExpiry(p.id)!,
                    onCancel: () async {
                      await TransactionCommercialeService.instance
                          .annulerLegacyValidation(
                              site: c.effectiveSite,
                              elementType: 'perte',
                              elementId: p.id);
                      c.loadAll();
                    }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClients(EspaceCommercialController c) {
    final items = c.filteredClients;
    return _buildScrollableList(
      emptyLabel: 'Aucun client',
      c: c,
      itemCount: items.length,
      itemBuilder: (_, i) {
        final cl = items[i];
        final commercials = cl.commercials
            .map((e) => c.displayNameForEmail(e))
            .where((e) => e.isNotEmpty)
            .toList();
        return ListTile(
          leading: const Icon(Icons.storefront),
          title: Text(cl.nomBoutique ?? cl.nom),
          subtitle: Text([
            if (cl.telephone != null) cl.telephone!,
            if (commercials.isNotEmpty) 'Commerciaux: ${commercials.join(', ')}'
          ].join('\n')),
          trailing: cl.dateCreation != null
              ? Text(cl.dateCreation!.toString().split(' ').first)
              : null,
        );
      },
    );
  }

  Widget _buildScrollableList({
    required String emptyLabel,
    required EspaceCommercialController c,
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    if (itemCount == 0) {
      return Center(child: Text(emptyLabel));
    }
    // 1 extra for the dynamic stats header
    return ListView.builder(
      itemCount: itemCount + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildScrollingHeader(c);
        return itemBuilder(context, index - 1);
      },
    );
  }

  Widget _buildScrollingHeader(EspaceCommercialController c) {
    final styleLabel = const TextStyle(fontSize: 11, color: Colors.grey);
    final styleValue = const TextStyle(
        fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        border: const Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Rafraîchir maintenant',
            onPressed: () => c.loadAll(forceRefresh: true),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _animatedMiniStat(
                      label: 'Attributions',
                      value: c.attributions.length.toDouble(),
                      styleLabel: styleLabel,
                      styleValue: styleValue,
                      onLongPress: () =>
                          _showDiagnostics(context: Get.context!, c: c)),
                  _animatedMiniStat(
                      label: 'Attribuées',
                      value: c.totalQuantiteAttribuee.toDouble(),
                      styleLabel: styleLabel,
                      styleValue: styleValue,
                      onLongPress: () =>
                          _showDiagnostics(context: Get.context!, c: c)),
                  _animatedMiniStat(
                      label: 'Consommées',
                      value: c.totalQuantiteConsommee.toDouble(),
                      styleLabel: styleLabel,
                      styleValue: styleValue,
                      onLongPress: () =>
                          _showDiagnostics(context: Get.context!, c: c)),
                  _animatedMiniStat(
                      label: 'Restantes',
                      value: c.totalQuantiteRestante.toDouble(),
                      styleLabel: styleLabel,
                      styleValue: styleValue,
                      onLongPress: () =>
                          _showDiagnostics(context: Get.context!, c: c)),
                  _animatedMiniStat(
                      label: 'Taux %',
                      value: c.tauxConsommationGlobal,
                      styleLabel: styleLabel,
                      styleValue: styleValue,
                      onLongPress: () =>
                          _showDiagnostics(context: Get.context!, c: c)),
                  _animatedMiniStat(
                      label: 'Ventes',
                      value: c.ventes.length.toDouble(),
                      styleLabel: styleLabel,
                      styleValue: styleValue,
                      onLongPress: () =>
                          _showDiagnostics(context: Get.context!, c: c)),
                  _animatedMiniStat(
                      label: 'Restitutions',
                      value: c.restitutions.length.toDouble(),
                      styleLabel: styleLabel,
                      styleValue: styleValue,
                      onLongPress: () =>
                          _showDiagnostics(context: Get.context!, c: c)),
                  _animatedMiniStat(
                      label: 'Pertes',
                      value: c.pertes.length.toDouble(),
                      styleLabel: styleLabel,
                      styleValue: styleValue,
                      onLongPress: () =>
                          _showDiagnostics(context: Get.context!, c: c)),
                  _animatedMiniStat(
                      label: 'Attributions',
                      value: c.attributionLotsCount.toDouble(),
                      styleLabel: styleLabel,
                      styleValue: styleValue,
                      onLongPress: () =>
                          _showDiagnostics(context: Get.context!, c: c)),
                  _animatedMiniStat(
                      label: 'Fetch ventes',
                      value: c.ventesFetchCount.toDouble(),
                      styleLabel: styleLabel,
                      styleValue: styleValue,
                      onLongPress: () =>
                          _showDiagnostics(context: Get.context!, c: c)),
                  _animatedMiniStat(
                      label: 'Fetch prélèv.',
                      value: c.prelevementsFetchCount.toDouble(),
                      styleLabel: styleLabel,
                      styleValue: styleValue,
                      onLongPress: () =>
                          _showDiagnostics(context: Get.context!, c: c)),
                  _animatedMiniStat(
                      label: 'Clients',
                      value: c.clientsCount.toDouble(),
                      styleLabel: styleLabel,
                      styleValue: styleValue,
                      onLongPress: () =>
                          _showDiagnostics(context: Get.context!, c: c)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // (Ancien _miniStat supprimé, remplacé par _animatedMiniStat)

  Widget _animatedMiniStat({
    required String label,
    required double value,
    required TextStyle styleLabel,
    required TextStyle styleValue,
    required VoidCallback onLongPress,
  }) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: styleLabel),
            const SizedBox(height: 2),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, val, _) => Text(
                val.round().toString(),
                style: styleValue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDiagnostics(
      {required BuildContext context, required EspaceCommercialController c}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Diagnostics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _diagLine('Attributions', c.attributions.length),
            _diagLine('Quantité attribuée', c.totalQuantiteAttribuee),
            _diagLine('Quantité consommée', c.totalQuantiteConsommee),
            _diagLine('Quantité restante', c.totalQuantiteRestante),
            _diagLine('Ventes', c.ventes.length),
            _diagLine('Restitutions', c.restitutions.length),
            _diagLine('Pertes', c.pertes.length),
            _diagLine('Clients', c.clientsCount),
            _diagLine('Attributions (lots)', c.attributionLotsCount),
            const Divider(),
            _diagLine('Fetch ventes (Firestore)', c.ventesFetchCount),
            _diagLine('Fetch prélèv. (Firestore)', c.prelevementsFetchCount),
            _diagLine('Fetch pertes (Firestore)', c.pertesFetchCount),
            _diagLine(
                'Fetch restitutions (Firestore)', c.restitutionsFetchCount),
            const SizedBox(height: 8),
            Text('Age dernier load: ${c.ageSinceLastLoad.inSeconds}s'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              c.loadAll(forceRefresh: true);
            },
            child: const Text('Rafraîchir'),
          ),
        ],
      ),
    );
  }

  Widget _diagLine(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          Text(value.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
