import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/filtrage_models.dart';
import '../services/filtrage_service.dart';
import '../../controle_de_donnes/models/quality_control_models.dart';

/// Modal pour afficher les détails d'un produit de filtrage
class FiltrageProductDetailsModal extends StatelessWidget {
  final FiltrageProduct product;

  const FiltrageProductDetailsModal({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.deepOrange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Détails du produit',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Code contenant', product.codeContenant),
            _buildDetailRow('Producteur', product.producteur),
            _buildDetailRow('Village', product.village),
            _buildDetailRow(
                'Type de collecte', _getTypeLabel(product.typeCollecte)),
            _buildDetailRow('Nature', product.nature.label),
            _buildDetailRow('Type de contenant', product.typeContenant),
            _buildDetailRow('Poids', '${product.poids.toStringAsFixed(1)} kg'),
            _buildDetailRow('Teneur en eau',
                '${(product.teneurEau ?? 0).toStringAsFixed(1)}%'),
            _buildDetailRow('Qualité', product.qualite),
            _buildDetailRow('Date de réception',
                DateFormat('dd/MM/yyyy HH:mm').format(product.dateReception)),
            _buildDetailRow('Collecteur', product.collecteur),
            _buildDetailRow('Site d\'origine', product.siteOrigine),
            _buildDetailRow('Statut',
                '${product.statutFiltrage.emoji} ${product.statutFiltrage.label}'),
            if (product.observations != null)
              _buildDetailRow('Observations', product.observations!),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'recoltes':
        return 'Récolte';
      case 'scoop':
        return 'SCOOP';
      case 'individuel':
        return 'Individuel';
      case 'miellerie':
        return 'Miellerie';
      default:
        return type;
    }
  }
}

/// Modal pour démarrer un processus de filtrage
class FiltrageProcessModal extends StatefulWidget {
  final FiltrageProduct product;
  final Function(FiltrageResult) onComplete;

  const FiltrageProcessModal({
    super.key,
    required this.product,
    required this.onComplete,
  });

  @override
  State<FiltrageProcessModal> createState() => _FiltrageProcessModalState();
}

class _FiltrageProcessModalState extends State<FiltrageProcessModal> {
  final _formKey = GlobalKey<FormState>();
  final _service = FiltrageService();

  final _agentController = TextEditingController();
  final _observationsDebutController = TextEditingController();
  final _poidsFinalController = TextEditingController();
  final _observationsFinController = TextEditingController();

  bool _isProcessing = false;
  bool _isStarted = false;

  @override
  void initState() {
    super.initState();
    _poidsFinalController.text = widget.product.poids.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _agentController.dispose();
    _observationsDebutController.dispose();
    _poidsFinalController.dispose();
    _observationsFinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.filter_alt,
                    color: Colors.deepOrange,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isStarted
                          ? 'Finaliser le filtrage'
                          : 'Démarrer le filtrage',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Produit: ${widget.product.codeContenant}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Poids initial: ${widget.product.poids.toStringAsFixed(1)} kg',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              if (!_isStarted) ...[
                TextFormField(
                  controller: _agentController,
                  decoration: InputDecoration(
                    labelText: 'Agent de filtrage *',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir le nom de l\'agent';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _observationsDebutController,
                  decoration: InputDecoration(
                    labelText: 'Observations (optionnel)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
              ] else ...[
                TextFormField(
                  controller: _poidsFinalController,
                  decoration: InputDecoration(
                    labelText: 'Poids final (kg) *',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.scale),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir le poids final';
                    }
                    final poids = double.tryParse(value);
                    if (poids == null || poids <= 0) {
                      return 'Veuillez saisir un poids valide';
                    }
                    if (poids > widget.product.poids) {
                      return 'Le poids final ne peut pas être supérieur au poids initial';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _observationsFinController,
                  decoration: InputDecoration(
                    labelText: 'Observations finales (optionnel)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
              ],
              const SizedBox(height: 24),
              if (_isProcessing)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed:
                          _isStarted ? _finaliserFiltrage : _demarrerFiltrage,
                      icon: Icon(_isStarted ? Icons.check : Icons.play_arrow),
                      label: Text(_isStarted ? 'Finaliser' : 'Démarrer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
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

  Future<void> _demarrerFiltrage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      await _service.demarrerFiltrage(
        product: widget.product,
        agentFiltrage: _agentController.text.trim(),
        observations: _observationsDebutController.text.trim().isEmpty
            ? null
            : _observationsDebutController.text.trim(),
      );

      setState(() {
        _isStarted = true;
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Filtrage démarré avec succès'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Erreur: $e')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _finaliserFiltrage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final result = await _service.terminerFiltrage(
        productId: widget.product.id,
        poidsFinal: double.parse(_poidsFinalController.text),
        observations: _observationsFinController.text.trim().isEmpty
            ? null
            : _observationsFinController.text.trim(),
      );

      Navigator.of(context).pop();
      widget.onComplete(result);
    } catch (e) {
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Erreur: $e')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Modal pour attribuer un produit à un agent
class FiltrageAssignmentModal extends StatefulWidget {
  final FiltrageProduct product;
  final Function(String) onAssign;

  const FiltrageAssignmentModal({
    super.key,
    required this.product,
    required this.onAssign,
  });

  @override
  State<FiltrageAssignmentModal> createState() =>
      _FiltrageAssignmentModalState();
}

class _FiltrageAssignmentModalState extends State<FiltrageAssignmentModal> {
  final _formKey = GlobalKey<FormState>();
  final _service = FiltrageService();

  final _agentController = TextEditingController();
  final _observationsController = TextEditingController();

  List<String> _agents = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  @override
  void dispose() {
    _agentController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _loadAgents() async {
    try {
      final agents = await _service.getAgentsFiltrage();
      setState(() {
        _agents = agents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_add,
                    color: Colors.blue,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Attribuer le produit',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Produit: ${widget.product.codeContenant}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Producteur: ${widget.product.producteur}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                DropdownButtonFormField<String>(
                  value: _agentController.text.isEmpty
                      ? null
                      : _agentController.text,
                  decoration: InputDecoration(
                    labelText: 'Agent de filtrage *',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  items: _agents.map((agent) {
                    return DropdownMenuItem(
                      value: agent,
                      child: Text(agent),
                    );
                  }).toList(),
                  onChanged: (value) {
                    _agentController.text = value ?? '';
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez sélectionner un agent';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _observationsController,
                  decoration: InputDecoration(
                    labelText: 'Instructions/Observations (optionnel)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
              ],
              const SizedBox(height: 24),
              if (_isProcessing)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _attribuer,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Attribuer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
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

  Future<void> _attribuer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      await _service.attribuerProduit(
        productId: widget.product.id,
        agentFiltrage: _agentController.text.trim(),
        observations: _observationsController.text.trim().isEmpty
            ? null
            : _observationsController.text.trim(),
      );

      Navigator.of(context).pop();
      widget.onAssign(_agentController.text.trim());
    } catch (e) {
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Erreur: $e')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Modal pour les filtres avancés
class FiltrageFiltersModal extends StatefulWidget {
  final FiltrageFilters filters;
  final Function(FiltrageFilters) onApply;
  final List<FiltrageProduct> allProducts;

  const FiltrageFiltersModal({
    super.key,
    required this.filters,
    required this.onApply,
    required this.allProducts,
  });

  @override
  State<FiltrageFiltersModal> createState() => _FiltrageFiltersModalState();
}

class _FiltrageFiltersModalState extends State<FiltrageFiltersModal> {
  late FiltrageFilters _currentFilters;

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.filters;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Colors.deepOrange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Filtres avancés',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // TODO: Implémenter les filtres
            Text('Filtres à implémenter...'),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onApply(_currentFilters);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Appliquer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal pour les statistiques
class FiltrageStatsModal extends StatelessWidget {
  final List<FiltrageProduct> products;
  final List<FiltrageProduct> allProducts;

  const FiltrageStatsModal({
    super.key,
    required this.products,
    required this.allProducts,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Colors.deepOrange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Statistiques de filtrage',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildStatCard(
                'Total produits', '${products.length}', Icons.inventory),
            _buildStatCard(
                'Produits urgents',
                '${products.where((p) => p.isUrgent).length}',
                Icons.priority_high),
            _buildStatCard(
                'Poids total',
                '${products.fold(0.0, (sum, p) => sum + p.poids).toStringAsFixed(1)} kg',
                Icons.scale),
            _buildStatCard(
                'En attente',
                '${products.where((p) => p.statutFiltrage == StatutFiltrage.en_attente).length}',
                Icons.hourglass_empty),
            _buildStatCard(
                'En cours',
                '${products.where((p) => p.statutFiltrage == StatutFiltrage.en_cours).length}',
                Icons.hourglass_top),
            _buildStatCard(
                'Terminés',
                '${products.where((p) => p.statutFiltrage == StatutFiltrage.termine).length}',
                Icons.check_circle),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepOrange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
        ],
      ),
    );
  }
}
