import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/vente_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/vente_service.dart';
import '../../../widgets/location_picker.dart';
import '../../../widgets/money_icon_widget.dart';
import '../controllers/espace_commercial_controller.dart';

/// 🛒 MODAL DE FORMULAIRE DE VENTE COMPLET
///
/// Interface complète pour enregistrer une nouvelle vente

class VenteFormModalComplete extends StatefulWidget {
  final Prelevement prelevement;
  final VoidCallback onVenteEnregistree;

  const VenteFormModalComplete({
    super.key,
    required this.prelevement,
    required this.onVenteEnregistree,
  });

  @override
  State<VenteFormModalComplete> createState() => _VenteFormModalCompleteState();
}

class _VenteFormModalCompleteState extends State<VenteFormModalComplete> {
  final VenteService _service = VenteService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _clientNomController = TextEditingController();
  final _clientTelephoneController = TextEditingController();
  final _clientAdresseController = TextEditingController();
  final _clientBoutiqueController = TextEditingController();
  final _montantPayeController = TextEditingController();
  final _observationsController = TextEditingController();

  // État du formulaire
  DateTime _dateVente = DateTime.now();
  ModePaiement _modePaiement = ModePaiement.espece;
  final Map<String, int> _quantitesVendues = {};
  List<Client> _clients = [];
  Client? _clientSelectionne;
  bool _isNouveauClient = true;
  bool _isLoading = false;

  // Nouveaux champs pour client étendu
  TypeClient _typeClient = TypeClient.particulier;
  bool _clientActif = true;
  double? _latitude;
  double? _longitude;
  double? _altitude;
  double? _precision;

  // Données calculées
  double _montantTotal = 0.0;
  double _montantPaye = 0.0;
  double _montantRestant = 0.0;

  @override
  void initState() {
    super.initState();
    _loadClients();
    _initializeQuantites();
  }

  @override
  void dispose() {
    _clientNomController.dispose();
    _clientTelephoneController.dispose();
    _clientAdresseController.dispose();
    _clientBoutiqueController.dispose();
    _montantPayeController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      final clients = await _service.getClients();
      setState(() => _clients = clients);
    } catch (e) {
      debugPrint('Erreur chargement clients: $e');
    }
  }

  void _initializeQuantites() {
    // Initialiser toutes les quantités à 0
    for (final produit in widget.prelevement.produits) {
      _quantitesVendues[produit.produitId] = 0;
    }
  }

  void _updateQuantite(String produitId, int nouvelleQuantite) {
    setState(() {
      _quantitesVendues[produitId] = nouvelleQuantite;
      _calculerMontants();
    });
  }

  void _calculerMontants() {
    double total = 0.0;

    for (final produit in widget.prelevement.produits) {
      final quantite = _quantitesVendues[produit.produitId] ?? 0;
      total += quantite * produit.prixUnitaire;
    }

    _montantTotal = total;
    _montantPaye = double.tryParse(_montantPayeController.text) ?? 0.0;
    _montantRestant = _montantTotal - _montantPaye;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isMobile ? double.infinity : 900,
        height: isMobile ? MediaQuery.of(context).size.height * 0.95 : 700,
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          children: [
            _buildHeader(isMobile),
            const SizedBox(height: 20),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDateSection(isMobile),
                      const SizedBox(height: 20),
                      _buildClientSection(isMobile),
                      const SizedBox(height: 20),
                      _buildProduitsSection(isMobile),
                      const SizedBox(height: 20),
                      _buildPaiementSection(isMobile),
                      const SizedBox(height: 20),
                      _buildObservationsSection(isMobile),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildFooter(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.point_of_sale,
            color: Colors.green,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouvelle Vente',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                'Prélèvement ${widget.prelevement.id.split('_').last}',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.close),
          color: Colors.grey.shade600,
        ),
      ],
    );
  }

  Widget _buildDateSection(bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📅 Date de Vente',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd/MM/yyyy à HH:mm').format(_dateVente),
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSection(bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '👤 Informations Client',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),

            // Toggle nouveau/existant
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Nouveau client'),
                    value: true,
                    groupValue: _isNouveauClient,
                    onChanged: (value) =>
                        setState(() => _isNouveauClient = value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Client existant'),
                    value: false,
                    groupValue: _isNouveauClient,
                    onChanged: (value) =>
                        setState(() => _isNouveauClient = value!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_isNouveauClient) ...[
              // Nouveau client - Nom et téléphone
              TextFormField(
                controller: _clientNomController,
                decoration: InputDecoration(
                  labelText: 'Nom du client *',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom du client est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _clientTelephoneController,
                      decoration: InputDecoration(
                        labelText: 'Téléphone',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _clientBoutiqueController,
                      decoration: InputDecoration(
                        labelText: 'Nom boutique',
                        prefixIcon: const Icon(Icons.storefront),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Adresse traditionnelle
              TextFormField(
                controller: _clientAdresseController,
                decoration: InputDecoration(
                  labelText: 'Adresse',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Type de client
              DropdownButtonFormField<TypeClient>(
                value: _typeClient,
                decoration: InputDecoration(
                  labelText: 'Type de client',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: TypeClient.values.map((type) {
                  return DropdownMenuItem<TypeClient>(
                    value: type,
                    child: Text(_getTypeClientLabel(type)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _typeClient = value!),
              ),
              const SizedBox(height: 16),
              // Switch Actif
              SwitchListTile(
                title: const Text('Client actif'),
                subtitle: const Text('Le client peut effectuer des achats'),
                value: _clientActif,
                onChanged: (value) => setState(() => _clientActif = value),
                secondary: const Icon(Icons.toggle_on),
              ),
              const SizedBox(height: 16),
              // Localisation GPS
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.map, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text('Localisation GPS',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _openLocationPicker,
                            icon:
                                const Icon(Icons.location_searching, size: 16),
                            label: const Text('Choisir'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_latitude != null && _longitude != null) ...[
                        Text('Latitude: ${_latitude!.toStringAsFixed(6)}'),
                        Text('Longitude: ${_longitude!.toStringAsFixed(6)}'),
                        if (_altitude != null)
                          Text('Altitude: ${_altitude!.toStringAsFixed(1)} m'),
                        if (_precision != null)
                          Text(
                              'Précision: ±${_precision!.toStringAsFixed(1)} m'),
                      ] else
                        const Text('Aucune localisation sélectionnée',
                            style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Client existant
              DropdownButtonFormField<Client?>(
                value: _clientSelectionne,
                decoration: InputDecoration(
                  labelText: 'Sélectionner un client *',
                  prefixIcon: const Icon(Icons.people),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  const DropdownMenuItem<Client?>(
                    value: null,
                    child: Text('-- Sélectionner --'),
                  ),
                  ..._clients.map((client) => DropdownMenuItem<Client?>(
                        value: client,
                        child: Text(
                            '${client.nom} - ${client.telephone ?? 'Pas de tél.'}'),
                      )),
                ],
                onChanged: (client) {
                  setState(() {
                    _clientSelectionne = client;
                    if (client != null) {
                      _clientNomController.text = client.nom;
                      _clientTelephoneController.text = client.telephone ?? '';
                      _clientAdresseController.text = client.adresse ?? '';
                    }
                  });
                },
                validator: (value) {
                  if (!_isNouveauClient && value == null) {
                    return 'Veuillez sélectionner un client';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProduitsSection(bool isMobile) {
    final produitsAvecVente = widget.prelevement.produits
        .where((p) => _quantitesVendues[p.produitId]! > 0)
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Row(
              children: [
                Text(
                  '📦 Sélection des Produits',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                if (produitsAvecVente.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${produitsAvecVente.length} sélectionné${produitsAvecVente.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              itemCount: widget.prelevement.produits.length,
              itemBuilder: (context, index) {
                final produit = widget.prelevement.produits[index];
                return _buildProduitVenteItem(produit, isMobile);
              },
            ),
          ),
          if (produitsAvecVente.isNotEmpty) ...[
            const Divider(height: 1),
            _buildRecapVente(produitsAvecVente, isMobile),
          ],
        ],
      ),
    );
  }

  Widget _buildProduitVenteItem(ProduitPreleve produit, bool isMobile) {
    final quantiteVendue = _quantitesVendues[produit.produitId] ?? 0;
    final isSelected = quantiteVendue > 0;
    final emoji = VenteUtils.getEmojiiForTypeEmballage(produit.typeEmballage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color:
            isSelected ? Colors.green.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.green : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Emoji et infos produit
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produit.numeroLot,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${produit.typeEmballage} - ${produit.contenanceKg}kg',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Disponible et prix
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${produit.quantitePreleve} prélevé${produit.quantitePreleve > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: isMobile ? 10 : 12,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                VenteUtils.formatPrix(produit.prixUnitaire),
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Sélecteur de quantité
          SizedBox(
            width: 120,
            child: Row(
              children: [
                IconButton(
                  onPressed: quantiteVendue > 0
                      ? () =>
                          _updateQuantite(produit.produitId, quantiteVendue - 1)
                      : null,
                  icon: const Icon(Icons.remove),
                  iconSize: 16,
                  style: IconButton.styleFrom(
                    backgroundColor: quantiteVendue > 0
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.shade200,
                    minimumSize: const Size(32, 32),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: quantiteVendue.toString(),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(fontSize: isMobile ? 12 : 14),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final quantite = int.tryParse(value) ?? 0;
                      if (quantite <= produit.quantitePreleve) {
                        _updateQuantite(produit.produitId, quantite);
                      }
                    },
                  ),
                ),
                IconButton(
                  onPressed: quantiteVendue < produit.quantitePreleve
                      ? () =>
                          _updateQuantite(produit.produitId, quantiteVendue + 1)
                      : null,
                  icon: const Icon(Icons.add),
                  iconSize: 16,
                  style: IconButton.styleFrom(
                    backgroundColor: quantiteVendue < produit.quantitePreleve
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.shade200,
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecapVente(List<ProduitPreleve> produitsVendus, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      color: Colors.green.withOpacity(0.05),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Récapitulatif: ${produitsVendus.length} produit${produitsVendus.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              Text(
                VenteUtils.formatPrix(_montantTotal),
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Total quantité: ${produitsVendus.fold(0, (sum, p) => sum + (_quantitesVendues[p.produitId] ?? 0))}',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaiementSection(bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💳 Informations de Paiement',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),

            // Mode de paiement
            DropdownButtonFormField<ModePaiement>(
              value: _modePaiement,
              decoration: InputDecoration(
                labelText: 'Mode de paiement *',
                prefixIcon: const Icon(Icons.payment),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: ModePaiement.values
                  .map((mode) => DropdownMenuItem<ModePaiement>(
                        value: mode,
                        child: Text(_getModePaiementLabel(mode)),
                      ))
                  .toList(),
              onChanged: (mode) => setState(() => _modePaiement = mode!),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _montantPayeController,
                    decoration: InputDecoration(
                      labelText: 'Montant payé *',
                      prefixIcon: const SimpleMoneyIcon(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixText: 'FCFA',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) => _calculerMontants(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le montant payé est requis';
                      }
                      final montant = double.tryParse(value);
                      if (montant == null || montant < 0) {
                        return 'Montant invalide';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _montantRestant > 0
                          ? Colors.orange.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _montantRestant > 0
                            ? Colors.orange.shade200
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Montant restant',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          VenteUtils.formatPrix(_montantRestant),
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: _montantRestant > 0
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Récap total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Montant total de la vente',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    VenteUtils.formatPrix(_montantTotal),
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
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

  Widget _buildObservationsSection(bool isMobile) {
    return TextFormField(
      controller: _observationsController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Observations (optionnel)',
        prefixIcon: const Icon(Icons.note),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hintText: 'Commentaires sur la vente...',
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    final produitsVendus = widget.prelevement.produits
        .where((p) => _quantitesVendues[p.produitId]! > 0)
        .toList();

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Get.back(),
            child: const Text('Annuler'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed:
                _isLoading || produitsVendus.isEmpty || _montantTotal <= 0
                    ? null
                    : _enregistrerVente,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Enregistrer Vente (${VenteUtils.formatPrix(_montantTotal)})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateVente,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dateVente),
      );

      if (time != null) {
        setState(() {
          _dateVente = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  String _getModePaiementLabel(ModePaiement mode) {
    switch (mode) {
      case ModePaiement.espece:
        return '💵 Espèces';
      case ModePaiement.carte:
        return '💳 Carte bancaire';
      case ModePaiement.virement:
        return '🏦 Virement';
      case ModePaiement.cheque:
        return '📝 Chèque';
      case ModePaiement.mobile:
        return '📱 Paiement mobile';
      case ModePaiement.credit:
        return '📋 Crédit';
    }
  }

  String _getTypeClientLabel(TypeClient type) {
    switch (type) {
      case TypeClient.particulier:
        return '👤 Particulier';
      case TypeClient.professionnel:
        return '🏢 Professionnel';
      case TypeClient.revendeur:
        return '🏪 Revendeur';
      case TypeClient.grossiste:
        return '🏭 Grossiste';
    }
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: _latitude,
          initialLng: _longitude,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _altitude = result.altitude;
        _precision = result.accuracy;
      });
    }
  }

  Future<void> _enregistrerVente() async {
    if (!_formKey.currentState!.validate()) return;

    final produitsVendus = widget.prelevement.produits
        .where((p) => _quantitesVendues[p.produitId]! > 0)
        .toList();

    if (produitsVendus.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner au moins un produit',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_montantTotal <= 0) {
      Get.snackbar(
        'Erreur',
        'Le montant total doit être supérieur à 0',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Créer/récupérer le client
      String clientId;
      String clientNom;
      String? clientTelephone;
      String? clientAdresse;

      if (_isNouveauClient) {
        clientId = 'CLIENT_${DateTime.now().millisecondsSinceEpoch}';
        clientNom = _clientNomController.text.trim();
        clientTelephone = _clientTelephoneController.text.trim().isNotEmpty
            ? _clientTelephoneController.text.trim()
            : null;
        clientAdresse = _clientAdresseController.text.trim().isNotEmpty
            ? _clientAdresseController.text.trim()
            : null;

        // Créer le nouveau client étendu
        final nouveauClient = Client(
          id: clientId,
          nom: clientNom,
          telephone: clientTelephone,
          email: null,
          adresse: clientAdresse,
          ville: null,
          nomBoutique: _clientBoutiqueController.text.trim().isNotEmpty
              ? _clientBoutiqueController.text.trim()
              : null,
          site: null, // sera injecté par le service
          type: _typeClient,
          dateCreation: DateTime.now(),
          totalAchats: _montantTotal,
          nombreAchats: 1,
          estActif: _clientActif,
          latitude: _latitude,
          longitude: _longitude,
          altitude: _altitude,
          precision: _precision,
        );

        await _service.creerClient(nouveauClient);
      } else {
        clientId = _clientSelectionne!.id;
        clientNom = _clientSelectionne!.nom;
        clientTelephone = _clientSelectionne!.telephone;
        clientAdresse = _clientSelectionne!.adresse;
      }

      // Préparer les produits vendus
      final List<ProduitVendu> produitsVenteFinal =
          produitsVendus.map((produit) {
        final quantite = _quantitesVendues[produit.produitId]!;
        return ProduitVendu(
          produitId: produit.produitId,
          numeroLot: produit.numeroLot,
          typeEmballage: produit.typeEmballage,
          contenanceKg: produit.contenanceKg,
          quantiteVendue: quantite,
          prixUnitaire: produit.prixUnitaire,
          prixVente: produit.prixUnitaire, // Prix de vente = prix unitaire
          montantTotal: quantite * produit.prixUnitaire,
        );
      }).toList();

      // Créer la vente
      final vente = Vente(
        id: 'VENTE_${DateTime.now().millisecondsSinceEpoch}',
        prelevementId: widget.prelevement.id,
        commercialId: widget.prelevement.commercialId,
        commercialNom: widget.prelevement.commercialNom,
        clientId: clientId,
        clientNom: clientNom,
        clientTelephone: clientTelephone,
        clientAdresse: clientAdresse,
        dateVente: _dateVente,
        produits: produitsVenteFinal,
        montantTotal: _montantTotal,
        montantPaye: _montantPaye,
        montantRestant: _montantRestant,
        modePaiement: _modePaiement,
        // Nouveau mapping des statuts : crédit vs payé directement
        statut: _montantRestant > 0
            ? StatutVente.creditEnAttente
            : StatutVente.payeeEnTotalite,
        observations: _observationsController.text.trim().isNotEmpty
            ? _observationsController.text.trim()
            : null,
      );

      // Enregistrer la vente
      final success = await _service.enregistrerVente(vente);

      if (success) {
        // Génération et affichage du reçu immédiatement
        try {
          final service = VenteService();
          final recu = service.generateReceipt(vente);
          await Clipboard.setData(ClipboardData(text: recu));
          // Afficher un dialog léger avec le reçu et options
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Reçu de Vente'),
                content: SizedBox(
                  width: 420,
                  child: SingleChildScrollView(
                    child: SelectableText(recu,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12)),
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Fermer')),
                  TextButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: recu));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Reçu copié dans le presse-papiers')),
                          );
                        }
                      },
                      child: const Text('Copier')),
                ],
              ),
            );
          }
        } catch (e) {
          debugPrint('Erreur génération reçu: $e');
        }
        // Fallback / Optimistic update : ajouter immédiatement la vente à la liste réactive
        // si le listener temps réel Firestore n'a pas encore propagé l'événement.
        try {
          if (Get.isRegistered<EspaceCommercialController>()) {
            final espaceCtrl = Get.find<EspaceCommercialController>();
            final already = espaceCtrl.ventes.any((v) => v.id == vente.id);
            if (!already) {
              // Insertion en tête pour visibilité instantanée
              espaceCtrl.ventes.insert(0, vente);
              espaceCtrl.ventes.refresh();
              // DEBUG: log optimistic insertion
              // ignore: avoid_print
              print(
                  '[OPTIMISTIC_VENTE] Insertion immédiate vente ${vente.id} montant=${vente.montantTotal}');
              // Note: la réconciliation des prélèvements sera recalculée automatiquement
              // par le listener temps réel quand il arrivera. Ici on évite d'appeler loadAll() (trop lourd).
            }
          }
        } catch (_) {
          // Ignore discrètement : fallback purement UX, le listener reprendra derrière
        }
        Get.back();
        Get.snackbar(
          'Succès',
          'Vente enregistrée avec succès pour ${vente.montantTotal.toStringAsFixed(0)} FCFA',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        widget.onVenteEnregistree();
      } else {
        Get.snackbar(
          'Erreur',
          'Impossible d\'enregistrer la vente. Veuillez réessayer.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
