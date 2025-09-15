/// 💰 ONGLET VENTE AUX CLIENTS
///
/// Interface complète pour gérer les ventes aux clients :
/// - Liste des clients existants
/// - Ajout de nouveaux clients
/// - Création de ventes
/// - Gestion des paiements
/// - Historique des ventes

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/commercial_models.dart';
import '../services/commercial_service.dart';

class VenteClientsTab extends StatefulWidget {
  final CommercialService commercialService;

  const VenteClientsTab({
    super.key,
    required this.commercialService,
  });

  @override
  State<VenteClientsTab> createState() => _VenteClientsTabState();
}

class _VenteClientsTabState extends State<VenteClientsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final RxList<Client> _clients = <Client>[].obs;
  final RxList<VenteClient> _ventes = <VenteClient>[].obs;
  final RxBool _isLoading = false.obs;
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchTerm = ''.obs;

  @override
  void initState() {
    super.initState();
    _loadClients();
    _loadVentes();
    _searchController.addListener(() {
      _searchTerm.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      _isLoading.value = true;
      // TODO: Charger les vrais clients depuis Firestore
      // Pour l'instant, utiliser des données mockées
      await Future.delayed(const Duration(milliseconds: 500));
      
      _clients.value = [
        Client(
          id: 'client_1',
          nom: 'OUEDRAOGO',
          prenom: 'Marie',
          telephone: '70123456',
          email: 'marie.ouedraogo@email.com',
          adresse: 'Secteur 15, Rue 12.34',
          ville: 'Ouagadougou',
          quartier: 'Tampouy',
          typeClient: 'particulier',
          dateCreation: DateTime.now().subtract(const Duration(days: 30)),
          site: 'Koudougou',
        ),
        Client(
          id: 'client_2',
          nom: 'SAWADOGO',
          prenom: 'Ibrahim',
          telephone: '76987654',
          adresse: 'Zone commerciale',
          ville: 'Koudougou',
          quartier: 'Centre-ville',
          typeClient: 'entreprise',
          dateCreation: DateTime.now().subtract(const Duration(days: 15)),
          site: 'Koudougou',
        ),
      ];
      debugPrint('✅ [VenteClientsTab] ${_clients.length} clients chargés');
    } catch (e) {
      debugPrint('❌ [VenteClientsTab] Erreur chargement clients: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _loadVentes() async {
    try {
      // TODO: Charger les vraies ventes depuis Firestore
      _ventes.value = [];
      debugPrint('✅ [VenteClientsTab] ${_ventes.length} ventes chargées');
    } catch (e) {
      debugPrint('❌ [VenteClientsTab] Erreur chargement ventes: $e');
    }
  }

  void _ouvrirAjoutClient() {
    showDialog(
      context: context,
      builder: (context) => _AjoutClientDialog(
        onClientAjoute: (client) {
          _clients.add(client);
          Get.snackbar(
            '✅ Client ajouté',
            'Le client ${client.nomComplet} a été ajouté avec succès',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            icon: const Icon(Icons.check, color: Colors.white),
          );
        },
      ),
    );
  }

  void _creerVente(Client client) {
    showDialog(
      context: context,
      builder: (context) => _CreerVenteDialog(
        client: client,
        commercialService: widget.commercialService,
        onVenteCree: (vente) {
          _ventes.add(vente);
          Get.snackbar(
            '✅ Vente créée',
            'Vente de ${CommercialUtils.formatPrix(vente.montantTotal)} FCFA créée',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            icon: const Icon(Icons.check, color: Colors.white),
          );
        },
      ),
    );
  }

  List<Client> get _clientsFiltres {
    if (_searchTerm.value.isEmpty) return _clients;
    
    return _clients.where((client) {
      return client.searchableText.contains(_searchTerm.value.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ouvrirAjoutClient,
        icon: const Icon(Icons.person_add),
        label: const Text('Nouveau Client'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.people, size: 32, color: Colors.blue.shade700),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion des Clients',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                Obx(() => Text(
                  '${_clients.length} clients • ${_ventes.length} ventes',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade600,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un client (nom, téléphone, adresse)...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Obx(() {
      if (_isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final clients = _clientsFiltres;
      
      if (clients.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: clients.length,
        itemBuilder: (context, index) {
          final client = clients[index];
          return _buildClientCard(client);
        },
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.people_outline,
              size: 50,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchTerm.value.isNotEmpty
                ? 'Aucun client trouvé'
                : 'Aucun client enregistré',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchTerm.value.isNotEmpty
                ? 'Essayez un autre terme de recherche'
                : 'Commencez par ajouter un client',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          if (_searchTerm.value.isEmpty)
            ElevatedButton.icon(
              onPressed: _ouvrirAjoutClient,
              icon: const Icon(Icons.person_add),
              label: const Text('Ajouter un Client'),
            ),
        ],
      ),
    );
  }

  Widget _buildClientCard(Client client) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _creerVente(client),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      client.nom.substring(0, 1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.nomComplet,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          client.telephone,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: client.typeClient == 'entreprise'
                          ? Colors.orange.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      client.typeClient,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: client.typeClient == 'entreprise'
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${client.adresse}, ${client.ville}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Modifier le client
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Modifier'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _creerVente(client),
                    icon: const Icon(Icons.shopping_cart, size: 16),
                    label: const Text('Créer Vente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 🏪 DIALOG AJOUT CLIENT
// ============================================================================

class _AjoutClientDialog extends StatefulWidget {
  final Function(Client) onClientAjoute;

  const _AjoutClientDialog({
    required this.onClientAjoute,
  });

  @override
  State<_AjoutClientDialog> createState() => __AjoutClientDialogState();
}

class __AjoutClientDialogState extends State<_AjoutClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _adresseController = TextEditingController();
  final _villeController = TextEditingController();
  final _quartierController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _typeClient = 'particulier';
  final RxBool _isLoading = false.obs;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _quartierController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      _isLoading.value = true;

      final client = Client(
        id: 'client_${DateTime.now().millisecondsSinceEpoch}',
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim().isEmpty 
            ? null 
            : _prenomController.text.trim(),
        telephone: _telephoneController.text.trim(),
        email: _emailController.text.trim().isEmpty 
            ? null 
            : _emailController.text.trim(),
        adresse: _adresseController.text.trim(),
        ville: _villeController.text.trim(),
        quartier: _quartierController.text.trim().isEmpty 
            ? null 
            : _quartierController.text.trim(),
        typeClient: _typeClient,
        dateCreation: DateTime.now(),
        site: 'Koudougou', // TODO: Récupérer le site de l'utilisateur
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      // TODO: Sauvegarder dans Firestore
      await Future.delayed(const Duration(milliseconds: 500));

      widget.onClientAjoute(client);
      Get.back();
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde client: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de sauvegarder le client',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Dialog(
      child: Container(
        width: 500,
        height: screenHeight * 0.9,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTypeClientSection(),
                        const SizedBox(height: 24),
                        _buildIdentiteSection(),
                        const SizedBox(height: 24),
                        _buildContactSection(),
                        const SizedBox(height: 24),
                        _buildAdresseSection(),
                        const SizedBox(height: 24),
                        _buildNotesSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.person_add, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          const Text(
            'Nouveau Client',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeClientSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type de client',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Particulier'),
                value: 'particulier',
                groupValue: _typeClient,
                onChanged: (value) {
                  setState(() => _typeClient = value!);
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Entreprise'),
                value: 'entreprise',
                groupValue: _typeClient,
                onChanged: (value) {
                  setState(() => _typeClient = value!);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIdentiteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Identité',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (_typeClient == 'particulier') ...[
              Expanded(
                child: TextFormField(
                  controller: _prenomController,
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: TextFormField(
                controller: _nomController,
                decoration: InputDecoration(
                  labelText: _typeClient == 'entreprise' 
                      ? 'Nom de l\'entreprise *' 
                      : 'Nom *',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ce champ est requis';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _telephoneController,
          decoration: const InputDecoration(
            labelText: 'Téléphone *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le téléphone est requis';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email (optionnel)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildAdresseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Adresse',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _adresseController,
          decoration: const InputDecoration(
            labelText: 'Adresse *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'L\'adresse est requise';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _villeController,
                decoration: const InputDecoration(
                  labelText: 'Ville *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La ville est requise';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _quartierController,
                decoration: const InputDecoration(
                  labelText: 'Quartier (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (optionnel)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 12),
          Obx(() => ElevatedButton(
            onPressed: _isLoading.value ? null : _sauvegarder,
            child: _isLoading.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Sauvegarder'),
          )),
        ],
      ),
    );
  }
}

// ============================================================================
// 🛒 DIALOG CRÉER VENTE
// ============================================================================

class _CreerVenteDialog extends StatefulWidget {
  final Client client;
  final CommercialService commercialService;
  final Function(VenteClient) onVenteCree;

  const _CreerVenteDialog({
    required this.client,
    required this.commercialService,
    required this.onVenteCree,
  });

  @override
  State<_CreerVenteDialog> createState() => __CreerVenteDialogState();
}

class __CreerVenteDialogState extends State<_CreerVenteDialog> {
  final RxList<ProduitVente> _produits = <ProduitVente>[].obs;
  final RxBool _isLoading = false.obs;
  final _notesController = TextEditingController();
  
  String _modePaiement = 'especes';
  
  double get _montantTotal => _produits.fold(0, (sum, p) => sum + p.montantTotal);

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _ajouterProduit() {
    // TODO: Ouvrir un dialog pour sélectionner un produit depuis les lots attribués
    // Pour l'instant, ajouter un produit mocké
    _produits.add(const ProduitVente(
      lotId: 'LOT_KOU_P1K_Lot_272_846',
      typeEmballage: '1Kg',
      numeroLot: 'Lot-272-846',
      quantite: 1,
      prixUnitaire: 3400,
      montantTotal: 3400,
    ));
  }

  Future<void> _creerVente() async {
    if (_produits.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez ajouter au moins un produit',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      _isLoading.value = true;

      final vente = VenteClient(
        id: 'vente_${DateTime.now().millisecondsSinceEpoch}',
        clientId: widget.client.id,
        commercialId: 'commercial_1', // TODO: Récupérer le commercial actuel
        commercialNom: 'YAMEOGO Rose', // TODO: Récupérer le commercial actuel
        produits: _produits.toList(),
        montantTotal: _montantTotal,
        montantPaye: _montantTotal, // Par défaut, considérer comme payé
        montantDu: 0,
        modePaiement: _modePaiement,
        statut: 'paye',
        dateVente: DateTime.now(),
        site: 'Koudougou', // TODO: Récupérer le site de l'utilisateur
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        gestionnaire: 'Gestionnaire', // TODO: Récupérer l'utilisateur actuel
      );

      // TODO: Sauvegarder dans Firestore
      await Future.delayed(const Duration(milliseconds: 500));

      widget.onVenteCree(vente);
      Get.back();
    } catch (e) {
      debugPrint('❌ Erreur création vente: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de créer la vente',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Dialog(
      child: Container(
        width: 600,
        height: screenHeight * 0.8,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildClientInfo(),
                      const SizedBox(height: 24),
                      _buildProduitsSection(),
                      const SizedBox(height: 24),
                      _buildPaiementSection(),
                      const SizedBox(height: 24),
                      _buildNotesSection(),
                    ],
                  ),
                ),
              ),
            ),
            _buildTotal(),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.shopping_cart, color: Colors.green.shade700),
          const SizedBox(width: 12),
          const Text(
            'Nouvelle Vente',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Text(
              widget.client.nom.substring(0, 1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.client.nomComplet,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.client.telephone,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProduitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Produits',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _ajouterProduit,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (_produits.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun produit ajouté',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cliquez sur "Ajouter" pour commencer',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: _produits.asMap().entries.map((entry) {
              final index = entry.key;
              final produit = entry.value;
              
              return Card(
                child: ListTile(
                  title: Text('${produit.typeEmballage} - ${produit.numeroLot}'),
                  subtitle: Text('${produit.quantite} x ${CommercialUtils.formatPrix(produit.prixUnitaire)} FCFA'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${CommercialUtils.formatPrix(produit.montantTotal)} FCFA',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _produits.removeAt(index),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildPaiementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mode de paiement',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _modePaiement,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'especes', child: Text('Espèces')),
            DropdownMenuItem(value: 'mobile_money', child: Text('Mobile Money')),
            DropdownMenuItem(value: 'cheque', child: Text('Chèque')),
            DropdownMenuItem(value: 'virement', child: Text('Virement')),
          ],
          onChanged: (value) {
            setState(() => _modePaiement = value!);
          },
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes sur la vente (optionnel)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTotal() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Total à payer:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Obx(() => Text(
            '${CommercialUtils.formatPrix(_montantTotal)} FCFA',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 12),
          Obx(() => ElevatedButton(
            onPressed: _isLoading.value ? null : _creerVente,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: _isLoading.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Créer la Vente'),
          )),
        ],
      ),
    );
  }
}

