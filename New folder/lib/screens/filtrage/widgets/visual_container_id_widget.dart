import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../authentication/user_session.dart';
import '../../../services/universal_container_id_service.dart';

/// Widget d'identification de contenant avec affichage visuel du préfixe
/// Le préfixe reste toujours visible et seul le code numérique est modifiable
class VisualContainerIdWidget extends StatefulWidget {
  /// Callback appelé quand les données du contenant changent
  final Function(String fullId, String containerNature, String numeroCode,
      bool isValid) onContainerChanged;

  /// ID initial du contenant (optionnel)
  final String? initialContainerId;

  const VisualContainerIdWidget({
    super.key,
    required this.onContainerChanged,
    this.initialContainerId,
  });

  @override
  State<VisualContainerIdWidget> createState() =>
      _VisualContainerIdWidgetState();
}

class _VisualContainerIdWidgetState extends State<VisualContainerIdWidget> {
  // Controllers pour les champs
  final TextEditingController _numeroCodeController = TextEditingController();
  final FocusNode _numeroCodeFocusNode = FocusNode();

  // Services
  final UniversalContainerIdService _universalService =
      UniversalContainerIdService();
  final UserSession _userSession = Get.find<UserSession>();

  // Variables d'état
  String _fixedPrefix = '';
  String _containerNature = '';
  String _numeroCode = '';
  String _fullId = '';
  bool _isInitialized = false;

  // Variables de validation
  bool _isValidContainer = false;
  bool _isSearching = false;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _initializeWithInitialValue();
    _numeroCodeController.addListener(_onNumeroCodeChanged);
  }

  @override
  void dispose() {
    _numeroCodeController.dispose();
    _numeroCodeFocusNode.dispose();
    super.dispose();
  }

  void _initializeWithInitialValue() {
    if (widget.initialContainerId != null &&
        widget.initialContainerId!.isNotEmpty) {
      _extractPrefixAndNumber(widget.initialContainerId!);
      _isInitialized = true;
    }
  }

  /// Extrait le préfixe fixe et le numéro depuis un ID complet
  void _extractPrefixAndNumber(String fullId) {
    final match = RegExp(r'^(.+_)(\d{4})$').firstMatch(fullId.toUpperCase());

    if (match != null) {
      setState(() {
        _fixedPrefix =
            match.group(1)!; // Ex: "REC_NONA_HIPPOLYTEYAMEOGO_20250902_"
        _numeroCode = match.group(2)!; // Ex: "0002"
        _fullId = fullId.toUpperCase();
        _containerNature = _extractContainerNature(_fixedPrefix);

        // Mettre à jour le controller sans déclencher le listener
        _numeroCodeController.removeListener(_onNumeroCodeChanged);
        _numeroCodeController.text = _numeroCode;
        _numeroCodeController.addListener(_onNumeroCodeChanged);
      });

      // Notifier le parent après la construction complète
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onContainerChanged(
            _fullId, _containerNature, _numeroCode, _isValidContainer);
      });
    }
  }

  /// Appelé quand le numéro code change
  void _onNumeroCodeChanged() {
    final newCode = _numeroCodeController.text;

    // Valider que c'est bien numérique et max 4 chiffres
    if (newCode.isNotEmpty && (!RegExp(r'^\d{1,4}$').hasMatch(newCode))) {
      // Revenir à l'ancienne valeur
      _numeroCodeController.removeListener(_onNumeroCodeChanged);
      _numeroCodeController.text = _numeroCode;
      _numeroCodeController.selection =
          TextSelection.collapsed(offset: _numeroCode.length);
      _numeroCodeController.addListener(_onNumeroCodeChanged);
      return;
    }

    // Mettre à jour l'état et réinitialiser la validation précédente
    setState(() {
      _numeroCode = newCode.padLeft(4, '0');
      _fullId = _fixedPrefix + _numeroCode;
      _isValidContainer = false;
      _validationMessage = null;
    });

    // Notifier le parent seulement si on a un code complet
    if (newCode.length == 4) {
      // Différer l'appel pour éviter setState pendant build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onContainerChanged(
            _fullId, _containerNature, _numeroCode, _isValidContainer);
      });
    }
  }

  /// Extrait la nature du contenant depuis le préfixe
  String _extractContainerNature(String prefix) {
    if (prefix.startsWith('REC_')) {
      return 'Récolte - Produit brut collecté';
    } else if (prefix.startsWith('SCO_')) {
      return 'SCOOP - Achat groupé';
    } else if (prefix.startsWith('IND_')) {
      return 'Individuel - Achat direct producteur';
    } else if (prefix.startsWith('MIE_')) {
      return 'Miellerie - Transformation/conditionnement';
    }
    return 'Type non identifié';
  }

  /// Recherche le contenant via le service universel pour valider son existence
  Future<void> _searchContainer() async {
    if (_fullId.isEmpty) {
      setState(() {
        _validationMessage = 'Veuillez d\'abord saisir un identifiant complet';
        _isValidContainer = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _validationMessage = null;
    });

    try {
      final result = await _universalService.verifyContainerMatch(
        controlId: _fullId,
        site: _userSession.site ?? '',
      );

      setState(() {
        _isValidContainer = result.found;
        _isSearching = false;
        if (result.found) {
          final collectionName =
              result.collecteInfo?.collectionType ?? 'collection inconnue';
          _validationMessage = '✅ Contenant trouvé dans $collectionName';
        } else {
          _validationMessage = '❌ Contenant non trouvé dans la base de données';
        }
      });

      // Notifier le parent avec le statut de validation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onContainerChanged(
            _fullId, _containerNature, _numeroCode, _isValidContainer);
      });
    } catch (error) {
      setState(() {
        _isSearching = false;
        _isValidContainer = false;
        _validationMessage = '⚠️ Erreur lors de la recherche: $error';
      });
    }
  }

  /// Interface permettant de saisir l'ID complet pour l'initialisation
  Widget _buildInitializationInterface() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Identification du contenant',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Saisissez l\'ID complet du contenant',
            hintText: 'Ex: REC_NONA_HIPPOLYTEYAMEOGO_20250902_0002',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: Icon(Icons.qr_code_scanner),
            helperText:
                'Une fois saisi, seul le code numérique sera modifiable',
          ),
          onFieldSubmitted: (value) {
            if (value.isNotEmpty) {
              _extractPrefixAndNumber(value);
              setState(() {
                _isInitialized = true;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Saisissez d\'abord l\'ID complet. Ensuite, vous pourrez modifier uniquement le code numérique à la fin.',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Interface de modification avec préfixe visible et code modifiable
  Widget _buildEditingInterface() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Identification du contenant',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),

        // Affichage visuel de l'ID avec parties distinctes
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Identifiant complet:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  // Partie fixe (non modifiable)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Text(
                      _fixedPrefix,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Partie modifiable (code numérique)
                  Container(
                    width: 60,
                    height: 32,
                    child: TextFormField(
                      controller: _numeroCodeController,
                      focusNode: _numeroCodeFocusNode,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        _PaddedNumberFormatter(),
                      ],
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.blue.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide:
                              BorderSide(color: Colors.blue.shade600, width: 2),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Bouton de recherche pour valider l'existence du contenant
        ElevatedButton.icon(
          onPressed: _isSearching ? null : _searchContainer,
          icon: _isSearching
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(Icons.search, size: 18),
          label:
              Text(_isSearching ? 'Recherche...' : 'Rechercher le contenant'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isValidContainer
                ? Colors.green.shade600
                : (_validationMessage != null && !_isValidContainer
                    ? Colors.red.shade600
                    : Colors.blue.shade600),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),

        // Affichage du message de validation
        if (_validationMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  _isValidContainer ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isValidContainer
                    ? Colors.green.shade300
                    : Colors.red.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isValidContainer ? Icons.check_circle : Icons.error,
                  color: _isValidContainer
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _validationMessage!,
                    style: TextStyle(
                      color: _isValidContainer
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Affichage du numéro code (verrouillé, mais synchronisé)
        TextFormField(
          controller: TextEditingController(text: _numeroCode),
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Numéro code *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: Icon(Icons.pin, color: Colors.green.shade600),
            filled: true,
            fillColor: Colors.green.shade50,
          ),
        ),

        const SizedBox(height: 8),

        // Message d'aide
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  color: Colors.amber.shade600, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Modifiez le code à 4 chiffres dans la zone bleue ci-dessus. Les autres champs se mettront à jour automatiquement.',
                  style: TextStyle(
                    color: Colors.amber.shade700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isInitialized
            ? _buildEditingInterface()
            : _buildInitializationInterface(),
      ),
    );
  }
}

/// Formatter qui s'assure que le numéro est toujours sur 4 chiffres avec des zéros de tête
class _PaddedNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Garder seulement les chiffres
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length > 4) {
      return oldValue;
    }

    return TextEditingValue(
      text: digitsOnly,
      selection: TextSelection.collapsed(offset: digitsOnly.length),
    );
  }
}
