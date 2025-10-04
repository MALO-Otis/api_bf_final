import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/collecte_models.dart';
import '../models/quality_control_models.dart';
import '../services/quality_control_service.dart';
import '../../../authentication/user_session.dart';
import '../../../services/universal_container_id_service.dart';
import '../../filtrage/widgets/visual_container_id_widget.dart';
// Formulaire de contrôle qualité du miel

class QualityControlForm extends StatefulWidget {
  final BaseCollecte collecteItem;
  final String containerCode;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final QualityControlData? existingData;

  const QualityControlForm({
    super.key,
    required this.collecteItem,
    required this.containerCode,
    required this.onSave,
    required this.onCancel,
    this.existingData,
  });

  @override
  State<QualityControlForm> createState() => _QualityControlFormState();
}

class _QualityControlFormState extends State<QualityControlForm> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers pour les champs de texte
  late final TextEditingController _producerController;
  late final TextEditingController _villageController;
  late final TextEditingController _hiveTypeController;
  late final TextEditingController _containerTypeController;
  late final TextEditingController _containerNumberController;
  late final TextEditingController _totalWeightController;
  late final TextEditingController _containerWeightController;
  late final TextEditingController _honeyWeightController;
  late final TextEditingController _qualityController;
  late final TextEditingController _waterContentController;
  late final TextEditingController _floralPredominanceController;
  late final TextEditingController _nonConformityCauseController;
  late final TextEditingController _observationsController;
  late final TextEditingController _controllerNameController;

  // Variables d'état
  DateTime _receptionDate = DateTime.now();
  DateTime? _collectionStartDate;
  DateTime? _collectionEndDate;
  HoneyNature _honeyNature = HoneyNature.brut;
  ContainerType? _selectedContainerType;
  ConformityStatus _conformityStatus = ConformityStatus.conforme;

  // 🆕 Nouvelles variables d'état pour le contrôle qualité avancé
  ContainerQualityApproval _containerQualityApproval =
      ContainerQualityApproval.approuver;
  OdorApproval _odorApproval = OdorApproval.approuver;
  SandDepositPresence _sandDepositPresence = SandDepositPresence.non;
  String _trackingCode = '';
  String _collectionPeriod = '';
  String _autoHiveType = '';
  String _autoHoneyNature = '';

  // Nouveau système d'ID universel
  String _validatedContainerId = '';
  List<ContainerMatchResult> _possibleMatches = [];

  // Variables pour le widget avancé
  String _containerNature = '';
  String _numeroCode = '';
  bool _isContainerValid = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadExistingData();

    // Auto-remplir les champs obligatoires si c'est un nouveau formulaire
    if (widget.existingData == null) {
      _autoFillFloralPredominance();
      _autoFillMandatoryFields(); // 🆕 Auto-remplit type ruche, période, nature
      _autoFillControllerName(); // 🆕 Auto-remplit nom contrôleur

      // Générer le code de suivi initial
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _trackingCode = _generateTrackingCode();
        });
      });
    }
  }

  void _initializeControllers() {
    _producerController = TextEditingController();
    _villageController = TextEditingController();
    _hiveTypeController = TextEditingController();
    _containerTypeController = TextEditingController();
    _containerNumberController = TextEditingController();
    _totalWeightController = TextEditingController();
    _containerWeightController = TextEditingController();
    _honeyWeightController = TextEditingController();
    _qualityController = TextEditingController();
    _waterContentController = TextEditingController();
    _floralPredominanceController = TextEditingController();
    _nonConformityCauseController = TextEditingController();
    _observationsController = TextEditingController();
    _controllerNameController = TextEditingController();
  }

  void _loadExistingData() {
    if (widget.existingData != null) {
      final data = widget.existingData!;
      _producerController.text = data.producer;
      _villageController.text = data.apiaryVillage;
      _hiveTypeController.text = data.hiveType;
      _containerTypeController.text = data.containerType;
      _containerNumberController.text = data.containerNumber;
      _totalWeightController.text = data.totalWeight.toString();
      _containerWeightController.text = data.containerWeight?.toString() ?? '';
      _honeyWeightController.text = data.honeyWeight.toString();
      _qualityController.text = data.quality;
      _waterContentController.text = data.waterContent?.toString() ?? '';
      _floralPredominanceController.text = data.floralPredominance;
      _nonConformityCauseController.text = data.nonConformityCause ?? '';
      _observationsController.text = data.observations ?? '';
      _controllerNameController.text = data.controllerName ?? '';

      _receptionDate = data.receptionDate;
      _collectionStartDate = data.collectionStartDate;
      _collectionEndDate = data.collectionEndDate;
      _honeyNature = data.honeyNature;
      _conformityStatus = data.conformityStatus;

      // Initialiser le type de contenant sélectionné
      try {
        _selectedContainerType = ContainerType.values.firstWhere(
          (type) => type.label == data.containerType,
        );
      } catch (e) {
        _selectedContainerType = null;
      }
    } else {
      // Pré-remplir avec les données de la collecte
      _producerController.text = widget.collecteItem.technicien ?? '';
      _villageController.text = widget.collecteItem.site;
      _containerNumberController.text = widget.containerCode;
    }
  }

  /// Calcule automatiquement le poids du miel
  void _calculateHoneyWeight() {
    final totalWeightText = _totalWeightController.text;
    final containerWeightText = _containerWeightController.text;

    if (totalWeightText.isNotEmpty && containerWeightText.isNotEmpty) {
      try {
        final totalWeight = double.parse(totalWeightText);
        final containerWeight = double.parse(containerWeightText);
        final honeyWeight = totalWeight - containerWeight;

        if (honeyWeight >= 0) {
          _honeyWeightController.text = honeyWeight.toStringAsFixed(2);
        } else {
          _honeyWeightController.text = '';
          _showSnackBar(
              'Erreur: Le poids du contenant ne peut pas être supérieur au poids total',
              true);
        }
      } catch (e) {
        _honeyWeightController.text = '';
      }
    } else {
      _honeyWeightController.text = '';
    }
  }

  /// 🔧 Détermine automatiquement la qualité selon la nouvelle logique (appelée quand teneur eau change)
  void _determineQualityFromWaterContent() {
    // Appeler directement la nouvelle logique qui prend en compte tous les critères
    _autoUpdateConformityAndQuality();
  }

  /// Auto-remplissage de la prédominance florale selon les données récupérées
  void _autoFillFloralPredominance() {
    // Récupérer les données du collecte item
    final collecteItem = widget.collecteItem;

    // Auto-remplir selon le type de collecte
    if (collecteItem is Individuel) {
      // Pour les collectes individuelles, utiliser le site
      _autoFillFromRegionalData(collecteItem.site);
    } else {
      // Pour les autres types, utiliser la propriété site générique
      _autoFillFromRegionalData(collecteItem.site);
    }
  }

  /// Auto-remplissage selon la région/site
  void _autoFillFromRegionalData(String? site) {
    if (site == null || site.isEmpty) return;

    // Mapping basique selon les sites (peut être étendu avec une base de données)
    final Map<String, String> regionalFloralData = {
      'Koudougou': 'Karité, Baobab',
      'Bobo Dioulasso': 'Acacia, Néré',
      'Ouagadougou': 'Eucalyptus, Manguier',
      'Bingo': 'Karité, Acacia',
      'Soaw': 'Néré, Baobab',
      'Dalo': 'Acacia, Tamarinier',
      'Dassa': 'Karité, Eucalyptus',
      'Léo': 'Baobab, Karité',
      'PÔ': 'Acacia, Néré',
      'Bagré': 'Eucalyptus, Manguier',
      'Dereguan': 'Karité, Baobab',
      'Sifarasso': 'Acacia, Karité',
      'Mahon': 'Néré, Acacia',
      'Mangodara': 'Karité, Tamarinier',
      'Niantono': 'Baobab, Karité',
      'Nalere': 'Acacia, Eucalyptus',
      'Tourni': 'Karité, Néré',
      'Bougoula': 'Baobab, Acacia',
      'Bouroum Bouroum': 'Karité, Manguier',
    };

    // Mapping des types de ruches selon les sites
    final Map<String, String> regionalHiveData = {
      'Koudougou': 'Ruche kenyane',
      'Bobo Dioulasso': 'Ruche traditionnelle',
      'Ouagadougou': 'Ruche moderne',
      'Bingo': 'Ruche kenyane',
      'Soaw': 'Ruche traditionnelle',
      'Dalo': 'Ruche kenyane',
      'Dassa': 'Ruche moderne',
      'Léo': 'Ruche traditionnelle',
      'PÔ': 'Ruche kenyane',
      'Bagré': 'Ruche moderne',
      'Dereguan': 'Ruche traditionnelle',
      'Sifarasso': 'Ruche kenyane',
      'Mahon': 'Ruche traditionnelle',
      'Mangodara': 'Ruche kenyane',
      'Niantono': 'Ruche traditionnelle',
      'Nalere': 'Ruche moderne',
      'Tourni': 'Ruche kenyane',
      'Bougoula': 'Ruche traditionnelle',
      'Bouroum Bouroum': 'Ruche kenyane',
    };

    // Auto-remplir la prédominance florale
    final floralSuggestion = regionalFloralData[site];
    if (floralSuggestion != null &&
        _floralPredominanceController.text.isEmpty) {
      _floralPredominanceController.text = floralSuggestion;
    }

    // Auto-remplir le type de ruche
    final hiveSuggestion = regionalHiveData[site];
    if (hiveSuggestion != null && _hiveTypeController.text.isEmpty) {
      _hiveTypeController.text = hiveSuggestion;
    }
  }

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 🆕 Auto-remplit les champs obligatoires depuis les données de collecte réelles
  void _autoFillMandatoryFields() {
    final collecteItem = widget.collecteItem;

    // 🔧 Auto-remplir le type de ruche depuis les contenants de la collecte
    if (collecteItem is Individuel && collecteItem.contenants.isNotEmpty) {
      // Récupérer le type de ruche du premier contenant (ou faire une agrégation si plusieurs)
      final typeRuche = collecteItem
          .contenants.first.typeMiel; // ou autre propriété appropriée
      _autoHiveType = 'Ruche ${typeRuche}';
      _hiveTypeController.text = _autoHiveType;
    } else if (collecteItem is Scoop && collecteItem.contenants.isNotEmpty) {
      // Pour les SCOOP, récupérer le type depuis les contenants
      final typeRuche = collecteItem.contenants.first.typeMiel;
      _autoHiveType = 'Ruche SCOOP ${typeRuche}';
      _hiveTypeController.text = _autoHiveType;
    } else if (collecteItem is Recolte && collecteItem.contenants.isNotEmpty) {
      // Pour les récoltes, récupérer le type de ruche réel
      final typeRuche = collecteItem.contenants.first.hiveType;
      _autoHiveType = typeRuche;
      _hiveTypeController.text = _autoHiveType;
    } else {
      _autoHiveType = 'Type non défini';
      _hiveTypeController.text = _autoHiveType;
    }

    // 🔧 Auto-remplir la date de collecte précise (renommé)
    _collectionPeriod = DateFormat('dd/MM/yyyy').format(collecteItem.date);

    // 🔧 Auto-remplir la nature du miel selon les données réelles de collecte
    _honeyNature = _determineHoneyNature(collecteItem);
    _autoHoneyNature = QualityControlUtils.getHoneyNatureLabel(_honeyNature);

    // 🔧 Auto-remplir le type de contenant depuis la collecte d'origine
    _autoFillContainerType(collecteItem);
  }

  /// 🆕 Auto-remplit le type de contenant depuis les données de collecte
  void _autoFillContainerType(BaseCollecte collecteItem) {
    String containerType = '';

    if (collecteItem is Individuel && collecteItem.contenants.isNotEmpty) {
      containerType = collecteItem.contenants.first.typeContenant;
    } else if (collecteItem is Scoop && collecteItem.contenants.isNotEmpty) {
      containerType = collecteItem.contenants.first.typeContenant;
    } else if (collecteItem is Recolte && collecteItem.contenants.isNotEmpty) {
      containerType = collecteItem.contenants.first.containerType;
    }

    if (containerType.isNotEmpty) {
      _containerTypeController.text = containerType;
      // Également mettre à jour le type sélectionné si nécessaire
      try {
        _selectedContainerType = ContainerType.values.firstWhere(
          (type) => type.label == containerType,
        );
      } catch (e) {
        // Si le type n'est pas trouvé dans l'enum, garder le texte libre
      }
    }
  }

  /// 🆕 Détermine automatiquement la nature du miel
  HoneyNature _determineHoneyNature(BaseCollecte collecteItem) {
    // Logique pour déterminer la nature selon les données
    if (widget.containerCode.toLowerCase().contains('cire')) {
      return HoneyNature.cire;
    } else if (widget.containerCode.toLowerCase().contains('filtre')) {
      return HoneyNature.prefilitre;
    } else {
      return HoneyNature.brut;
    }
  }

  /// 🆕 Auto-détermine la conformité et qualité selon les critères
  /// 🆕 Auto-détermination de la qualité et conformité selon les nouveaux critères
  void _autoUpdateConformityAndQuality() {
    bool isContainerApproved =
        _containerQualityApproval == ContainerQualityApproval.approuver;
    bool isOdorApproved = _odorApproval == OdorApproval.approuver;
    bool noSandDeposit = _sandDepositPresence == SandDepositPresence.non;

    if (isContainerApproved && isOdorApproved && noSandDeposit) {
      // 🔧 Tous les critères sont bons → vérifier la teneur en eau
      final waterContentText = _waterContentController.text;

      if (waterContentText.isNotEmpty) {
        try {
          final waterContent = double.parse(waterContentText);

          setState(() {
            if (waterContent < 20) {
              _qualityController.text = 'Très Bonne';
              _conformityStatus = ConformityStatus.conforme;
              _nonConformityCauseController.text = '';
            } else if (waterContent <= 21) {
              _qualityController.text = 'Bonne';
              _conformityStatus = ConformityStatus.conforme;
              _nonConformityCauseController.text = '';
            } else {
              _qualityController.text = 'Mauvaise';
              _conformityStatus = ConformityStatus.nonConforme;
              _nonConformityCauseController.text =
                  'Teneur en eau trop élevée (>21%)';
            }
          });
        } catch (e) {
          // Si la teneur en eau n'est pas parsable, marquer comme bonne par défaut
          setState(() {
            _qualityController.text = 'Bonne';
            _conformityStatus = ConformityStatus.conforme;
            _nonConformityCauseController.text = '';
          });
        }
      } else {
        // Si pas de teneur en eau saisie, marquer comme bonne par défaut
        setState(() {
          _qualityController.text = 'Bonne';
          _conformityStatus = ConformityStatus.conforme;
          _nonConformityCauseController.text = '';
        });
      }
    } else {
      // 🔧 Au moins un critère n'est pas bon → Non conforme
      setState(() {
        _conformityStatus = ConformityStatus.nonConforme;
        _qualityController.text = 'Mauvaise';

        // Construire la cause de non-conformité
        List<String> causes = [];
        if (!isContainerApproved)
          causes.add('Qualité du contenant non approuvée');
        if (!isOdorApproved) causes.add('Odeurs non approuvées');
        if (!noSandDeposit) causes.add('Présence de dépôt de sable');

        _nonConformityCauseController.text = causes.join(', ');
      });
    }
  }

  /// 🆕 Génère le code de suivi avec le nouveau format
  String _generateTrackingCode() {
    final now = DateTime.now();
    final collecteItem = widget.collecteItem;

    // 🔧 Nouveau format: [Recolte]__[Du(date precise de collecte)]__[De-VALENTIN-ZOUNGRANA]__[A-(code localité)]__[Site de (nom site)]__[Controle-(date controle)]__[Controler-Par-(nom controleur)]__[Code-Contenant-00001]

    // 1. Type de collecte
    String typeCollecte = '';
    if (collecteItem is Recolte) {
      typeCollecte = 'Recolte';
    } else if (collecteItem is Scoop) {
      typeCollecte = 'Scoop';
    } else if (collecteItem is Individuel) {
      typeCollecte = 'Individuel';
    } else {
      typeCollecte = 'Collecte';
    }

    // 2. Date précise de collecte
    String datePreciseCollecte =
        DateFormat('dd-MM-yyyy').format(collecteItem.date);

    // 3. Nom du producteur/technicien (De-XXX-XXX)
    String nomProducteur = '';
    if (collecteItem is Individuel) {
      nomProducteur = collecteItem.nomProducteur
          .toUpperCase()
          .replaceAll(' ', '-')
          .replaceAll(RegExp(r'[^A-Z\-]'), '');
    } else if (collecteItem.technicien != null) {
      nomProducteur = collecteItem.technicien!
          .toUpperCase()
          .replaceAll(' ', '-')
          .replaceAll(RegExp(r'[^A-Z\-]'), '');
    } else {
      nomProducteur = 'TECHNICIEN';
    }

    // 4. Code de localité (A-04-03-01-VillageName)
    String codeLocalite = _buildLocationCode(collecteItem);

    // 5. Site de récolte
    String siteRecolte = collecteItem.site.toUpperCase().replaceAll(' ', '-');

    // 6. Date de contrôle
    String dateControle = DateFormat('dd-MM-yyyy').format(now);

    // 7. Nom du contrôleur
    String nomControleur = '';
    try {
      final userSession = Get.find<UserSession>();
      if (userSession.nom != null && userSession.nom!.isNotEmpty) {
        nomControleur = userSession.nom!
            .toUpperCase()
            .replaceAll(' ', '-')
            .replaceAll(RegExp(r'[^A-Z\-]'), '');
      } else {
        nomControleur = 'CONTROLEUR';
      }
    } catch (e) {
      nomControleur = 'CONTROLEUR';
    }

    // 8. Code contenant (extraire le numéro du containerCode)
    String codeContenant = _extractContainerNumber(widget.containerCode);

    // Construire le code final
    return '[$typeCollecte]__[Du-$datePreciseCollecte]__[De-$nomProducteur]__[A-$codeLocalite]__[Site-de-$siteRecolte]__[Controle-$dateControle]__[Controler-Par-$nomControleur]__[Code-Contenant-$codeContenant]';
  }

  /// 🆕 Construit le code de localité selon les données géographiques
  String _buildLocationCode(BaseCollecte collecteItem) {
    String codeRegion = '04'; // Valeur par défaut
    String codeProvince = '03'; // Valeur par défaut
    String codeCommune = '01'; // Valeur par défaut
    String nomVillage = 'VILLAGE';

    // Récupérer les données géographiques selon le type de collecte
    if (collecteItem is Recolte) {
      // Pour les récoltes, utiliser les données géographiques spécifiques
      if (collecteItem.village != null && collecteItem.village!.isNotEmpty) {
        nomVillage = collecteItem.village!.toUpperCase().replaceAll(' ', '-');
      }
      // TODO: Mapper region/province/commune vers des codes numériques
      // Pour l'instant utiliser des valeurs par défaut
    } else if (collecteItem is Scoop) {
      if (collecteItem.village != null && collecteItem.village!.isNotEmpty) {
        nomVillage = collecteItem.village!.toUpperCase().replaceAll(' ', '-');
      }
    } else if (collecteItem is Individuel) {
      if (collecteItem.village != null && collecteItem.village!.isNotEmpty) {
        nomVillage = collecteItem.village!.toUpperCase().replaceAll(' ', '-');
      }
    }

    // Si on a accès aux champs du formulaire, les utiliser
    if (_villageController.text.isNotEmpty) {
      nomVillage = _villageController.text.toUpperCase().replaceAll(' ', '-');
    }

    return '$codeRegion-$codeProvince-$codeCommune-$nomVillage';
  }

  /// 🆕 Extrait le numéro du code contenant
  String _extractContainerNumber(String containerCode) {
    // Extraire les derniers chiffres ou formater en 00001
    final regex = RegExp(r'(\d+)$');
    final match = regex.firstMatch(containerCode);

    if (match != null) {
      final number = int.tryParse(match.group(1)!) ?? 1;
      return number.toString().padLeft(5, '0');
    } else {
      // Si pas de numéro trouvé, utiliser 00001
      return '00001';
    }
  }

  /// 🔧 Auto-remplit le nom du contrôleur avec les vraies données utilisateur
  void _autoFillControllerName() {
    try {
      // Récupérer la session utilisateur depuis GetX
      final userSession = Get.find<UserSession>();

      String controllerInfo = '';

      // Construire le nom avec rôle
      if (userSession.nom != null && userSession.nom!.isNotEmpty) {
        controllerInfo = userSession.nom!;

        // Ajouter le rôle principal si disponible
        if (userSession.roles.isNotEmpty) {
          final primaryRole = userSession.roles.first;
          controllerInfo += ' -- $primaryRole';
        }
      } else {
        // Fallback si pas de nom
        controllerInfo =
            'Contrôleur -- ${userSession.roles.isNotEmpty ? userSession.roles.first : 'Non défini'}';
      }

      _controllerNameController.text = controllerInfo;
    } catch (e) {
      print('Erreur lors de la récupération des données utilisateur: $e');
      // Fallback en cas d'erreur
      _controllerNameController.text = 'Contrôleur -- Non identifié';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _producerController.dispose();
    _villageController.dispose();
    _hiveTypeController.dispose();
    _containerTypeController.dispose();
    _containerNumberController.dispose();
    _totalWeightController.dispose();
    _containerWeightController.dispose();
    _honeyWeightController.dispose();
    _qualityController.dispose();
    _waterContentController.dispose();
    _floralPredominanceController.dispose();
    _nonConformityCauseController.dispose();
    _observationsController.dispose();
    _controllerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isVerySmall = screenSize.width < 360;

    return Container(
      height: screenSize.height * 0.95,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Poignée et header
          _buildHeader(context, theme, isMobile, isVerySmall),

          // Corps du formulaire
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormFields(context, theme, isMobile, isVerySmall),
                  ],
                ),
              ),
            ),
          ),

          // Footer avec actions
          _buildFooter(context, theme, isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, ThemeData theme, bool isMobile, bool isVerySmall) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Poignée pour indiquer qu'on peut glisser
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fact_check,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: isMobile ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contrôle Qualité',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 18 : 22,
                      ),
                    ),
                    Text(
                      'Contenant ${widget.containerCode}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: isMobile ? 13 : 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(
      BuildContext context, ThemeData theme, bool isMobile, bool isVerySmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1: Informations générales
        _buildSection(
          context,
          'Informations générales',
          Icons.info_outline,
          [
            _buildDateField(
              'Date de réception',
              _receptionDate,
              (date) => setState(() => _receptionDate = date),
              isMobile,
            ),
            const SizedBox(height: 16),
            if (isMobile && isVerySmall) ...[
              _buildTextField(
                'Producteur ou groupement',
                _producerController,
                'Nom du producteur',
                isMobile,
                isRequired: true,
                isReadOnly:
                    true, // 🔒 Verrouillé - auto-rempli depuis les données de collecte
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Village apicole',
                _villageController,
                'Nom du village',
                isMobile,
                isRequired: true,
                isReadOnly:
                    true, // 🔒 Verrouillé - auto-rempli depuis les données de collecte
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Producteur ou groupement',
                      _producerController,
                      'Nom du producteur',
                      isMobile,
                      isRequired: true,
                      isReadOnly:
                          true, // 🔒 Verrouillé - auto-rempli depuis les données de collecte
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      'Village apicole',
                      _villageController,
                      'Nom du village',
                      isMobile,
                      isRequired: true,
                      isReadOnly:
                          true, // 🔒 Verrouillé - auto-rempli depuis les données de collecte
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _buildTextField(
              'Type de ruche (auto-rempli)',
              _hiveTypeController,
              'Ex: Langstroth, Kenyane...',
              isMobile,
              isRequired: true,
              isReadOnly: true, // 🆕 Champ non modifiable
            ),
          ],
          isMobile,
        ),

        const SizedBox(height: 24),

        // Section 1.5: Identification VISUELLE du contenant (AMÉLIORÉ)
        VisualContainerIdWidget(
          onContainerChanged:
              (containerId, containerNature, numeroCode, isValid) {
            setState(() {
              _validatedContainerId = containerId;
              _containerNature = containerNature;
              _numeroCode = numeroCode;
              _isContainerValid = isValid;

              // Auto-remplir seulement le numéro code (synchronisé)
              _containerNumberController.text = numeroCode;

              // Le champ "Contenant du miel" reste libre à la saisie utilisateur
            });
          },
          initialContainerId:
              widget.containerCode.isNotEmpty ? widget.containerCode : null,
        ),

        const SizedBox(height: 24),

        // Section 2: Date de collecte précise
        _buildSection(
          context,
          'Date de collecte précise',
          Icons.date_range,
          [
            // 🆕 Champ Date de collecte précise auto-rempli
            TextField(
              controller: TextEditingController(text: _collectionPeriod),
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Date de collecte précise (auto-remplie)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 16),
            if (isMobile && isVerySmall) ...[
              _buildDateField(
                'Du',
                _collectionStartDate,
                (date) => setState(() => _collectionStartDate = date),
                isMobile,
                isOptional: true,
              ),
              const SizedBox(height: 16),
              _buildDateField(
                'Au',
                _collectionEndDate,
                (date) => setState(() => _collectionEndDate = date),
                isMobile,
                isOptional: true,
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      'Du',
                      _collectionStartDate,
                      (date) => setState(() => _collectionStartDate = date),
                      isMobile,
                      isOptional: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                      'Au',
                      _collectionEndDate,
                      (date) => setState(() => _collectionEndDate = date),
                      isMobile,
                      isOptional: true,
                    ),
                  ),
                ],
              ),
            ],
          ],
          isMobile,
        ),

        const SizedBox(height: 24),

        // Section 3: Nature et contenant
        _buildSection(
          context,
          'Nature et contenant',
          Icons.inventory_2,
          [
            // 🆕 Nature du miel auto-remplie (non modifiable)
            TextField(
              controller: TextEditingController(text: _autoHoneyNature),
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Nature du miel (auto-remplie)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 16),
            // ⚠️ MISE À JOUR: Champs synchronisés automatiquement avec l'ID ci-dessus
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.orange.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seul le champ "Numéro (code)" est automatiquement synchronisé avec '
                      'l\'identifiant du contenant. Le champ "Contenant du miel" est libre à votre saisie.',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Affichage informatif des valeurs extraites (utilise les variables)
            if (_containerNature.isNotEmpty || _numeroCode.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  'Valeurs extraites: ${_containerNature.isNotEmpty ? "Nature: $_containerNature" : ""}'
                  '${_numeroCode.isNotEmpty ? " | Code: $_numeroCode" : ""}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (isMobile && isVerySmall) ...[
              _buildContainerTypeSelector(theme, isMobile),
              const SizedBox(height: 16),
              _buildTextField(
                'Numéro (code) *',
                _containerNumberController,
                'Code du contenant (synchronisé)',
                isMobile,
                isRequired: true,
                isReadOnly: true, // 🔒 Verrouillé - synchronisé avec l'ID
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildContainerTypeSelector(theme, isMobile),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      'Numéro (code) *',
                      _containerNumberController,
                      'Code du contenant (synchronisé)',
                      isMobile,
                      isRequired: true,
                      isReadOnly: true, // 🔒 Verrouillé - synchronisé avec l'ID
                    ),
                  ),
                ],
              ),
            ],
          ],
          isMobile,
        ),

        const SizedBox(height: 24),

        // Section 4: Poids et mesures
        _buildSection(
          context,
          'Poids et mesures',
          Icons.scale,
          [
            if (isMobile && isVerySmall) ...[
              _buildNumberField(
                'Poids de l\'ensemble (miel + contenant)',
                _totalWeightController,
                'kg',
                isMobile,
                isRequired: true,
                onChanged: (value) => _calculateHoneyWeight(),
              ),
              const SizedBox(height: 16),
              _buildNumberField(
                'Poids du contenant',
                _containerWeightController,
                'kg',
                isMobile,
                isRequired: true,
                onChanged: (value) => _calculateHoneyWeight(),
              ),
              const SizedBox(height: 16),
              _buildNumberField(
                'Poids du miel (calculé automatiquement)',
                _honeyWeightController,
                'kg',
                isMobile,
                isRequired: true,
                isReadOnly: true,
              ),
              const SizedBox(height: 16),
              _buildNumberField(
                'Teneur en eau',
                _waterContentController,
                '%',
                isMobile,
                isRequired: true,
                onChanged: (value) => _determineQualityFromWaterContent(),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      'Poids de l\'ensemble',
                      _totalWeightController,
                      'kg',
                      isMobile,
                      isRequired: true,
                      onChanged: (value) => _calculateHoneyWeight(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildNumberField(
                      'Poids du contenant',
                      _containerWeightController,
                      'kg',
                      isMobile,
                      isRequired: true,
                      onChanged: (value) => _calculateHoneyWeight(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildNumberField(
                      'Poids du miel (auto)',
                      _honeyWeightController,
                      'kg',
                      isMobile,
                      isRequired: true,
                      isReadOnly: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildNumberField(
                'Teneur en eau',
                _waterContentController,
                '%',
                isMobile,
                isRequired: true,
                onChanged: (value) => _determineQualityFromWaterContent(),
              ),
            ],
          ],
          isMobile,
        ),

        const SizedBox(height: 24),

        // Section 5: Qualité et conformité
        _buildSection(
          context,
          'Qualité et conformité',
          Icons.verified,
          [
            // 🆕 Qualité du contenant (radio)
            _buildApprovalRadio(
              'Qualité du contenant',
              _containerQualityApproval,
              (value) => setState(() {
                _containerQualityApproval = value;
                _autoUpdateConformityAndQuality();
              }),
              ContainerQualityApproval.values,
              isMobile,
            ),
            const SizedBox(height: 16),

            // 🆕 Approbation des odeurs (radio)
            _buildApprovalRadio(
              'Approbation des Odeurs',
              _odorApproval,
              (value) => setState(() {
                _odorApproval = value;
                _autoUpdateConformityAndQuality();
              }),
              OdorApproval.values,
              isMobile,
            ),
            const SizedBox(height: 16),

            // 🆕 Présence de dépôt de sable (Oui/Non)
            _buildYesNoRadio(
              'Présence de Dépôt de Sable',
              _sandDepositPresence,
              (value) => setState(() {
                _sandDepositPresence = value;
                _autoUpdateConformityAndQuality();
              }),
              isMobile,
            ),
            const SizedBox(height: 16),

            // Qualité déterminée automatiquement
            _buildTextField(
              'Qualité du miel (déterminée automatiquement)',
              _qualityController,
              'Calculée automatiquement selon les critères',
              isMobile,
              isRequired: true,
              isReadOnly: true,
            ),
            const SizedBox(height: 16),

            // 🆕 Prédominance florale auto-remplie (non modifiable)
            TextField(
              controller: _floralPredominanceController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Prédominance florale (auto-remplie)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 16),

            // Conformité déterminée automatiquement
            _buildConformitySelector(theme, isMobile),
            const SizedBox(height: 16),

            if (_conformityStatus == ConformityStatus.nonConforme) ...[
              _buildTextField(
                'Cause de la non-conformité',
                _nonConformityCauseController,
                'Précisez la cause',
                isMobile,
                isRequired: true,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
            ],
          ],
          isMobile,
        ),

        const SizedBox(height: 24),

        // Section 6: Observations et suivi
        _buildSection(
          context,
          'Observations et suivi',
          Icons.notes,
          [
            // 🆕 Code de suivi (auto-généré)
            TextField(
              controller: TextEditingController(text: _trackingCode),
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Code de suivi (auto-généré)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 16),

            _buildTextField(
              'Observations / Actions',
              _observationsController,
              'Notes additionnelles...',
              isMobile,
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // 🆕 Nom du contrôleur auto-rempli (non modifiable)
            TextField(
              controller: _controllerNameController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Nom du contrôleur (auto-rempli)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ],
          isMobile,
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
    bool isMobile,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: isMobile ? 18 : 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint,
    bool isMobile, {
    bool isRequired = false,
    bool isOptional = false,
    int maxLines = 1,
    bool isReadOnly = false, // 🆕 Nouveau paramètre pour verrouiller les champs
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: isMobile ? 12 : 14,
                ),
            children: [
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              if (isOptional)
                TextSpan(
                  text: ' (optionnel)',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: isMobile ? 10 : 12,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: isReadOnly, // 🆕 Mode lecture seule
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: isReadOnly
                ? Colors.grey[600]
                : null, // 🆕 Couleur grisée si verrouillé
          ),
          decoration: InputDecoration(
            hintText: isReadOnly
                ? 'Champ auto-rempli (verrouillé)'
                : hint, // 🆕 Hint adapté
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 16,
            ),
            isDense: isMobile,
            filled: isReadOnly, // 🆕 Fond coloré si verrouillé
            fillColor:
                isReadOnly ? Colors.grey[100] : null, // 🆕 Couleur de fond
            prefixIcon: isReadOnly
                ? Icon(Icons.lock_outline, size: 16, color: Colors.grey[600])
                : null, // 🆕 Icône cadenas
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ce champ est requis';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildNumberField(
    String label,
    TextEditingController controller,
    String unit,
    bool isMobile, {
    bool isRequired = false,
    bool isOptional = false,
    bool isReadOnly = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: isMobile ? 12 : 14,
                ),
            children: [
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              if (isOptional)
                TextSpan(
                  text: ' (optionnel)',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: isMobile ? 10 : 12,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: isReadOnly,
          keyboardType: isReadOnly
              ? null
              : const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: isReadOnly ? Colors.grey[600] : null,
          ),
          inputFormatters: isReadOnly
              ? null
              : [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
          onChanged: onChanged,
          decoration: InputDecoration(
            suffixText: unit,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 16,
            ),
            isDense: isMobile,
            filled: isReadOnly,
            fillColor: isReadOnly ? Colors.grey[100] : null,
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ce champ est requis';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Valeur numérique invalide';
                  }
                  return null;
                }
              : (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      double.tryParse(value) == null) {
                    return 'Valeur numérique invalide';
                  }
                  return null;
                },
        ),
      ],
    );
  }

  /// 🆕 Widget pour les champs radio Approuver/Non Approuver
  Widget _buildApprovalRadio(
    String label,
    dynamic currentValue,
    ValueChanged<dynamic> onChanged,
    List<dynamic> options,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: isMobile ? 12 : 14,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: options.map((option) {
            return Expanded(
              child: RadioListTile<dynamic>(
                title: Text(
                  option.label,
                  style: TextStyle(fontSize: isMobile ? 12 : 14),
                ),
                value: option,
                groupValue: currentValue,
                onChanged: (value) {
                  onChanged(value!);
                  _autoUpdateConformityAndQuality(); // 🆕 Auto-mise à jour
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 🆕 Widget pour les champs Oui/Non
  Widget _buildYesNoRadio(
    String label,
    SandDepositPresence currentValue,
    ValueChanged<SandDepositPresence> onChanged,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: isMobile ? 12 : 14,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: SandDepositPresence.values.map((option) {
            return Expanded(
              child: RadioListTile<SandDepositPresence>(
                title: Text(
                  option.label,
                  style: TextStyle(fontSize: isMobile ? 12 : 14),
                ),
                value: option,
                groupValue: currentValue,
                onChanged: (value) {
                  onChanged(value!);
                  _autoUpdateConformityAndQuality(); // 🆕 Auto-mise à jour
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? value,
    ValueChanged<DateTime> onChanged,
    bool isMobile, {
    bool isOptional = false,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: isMobile ? 12 : 14,
            ),
            children: [
              if (isOptional)
                TextSpan(
                  text: ' (optionnel)',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: isMobile ? 10 : 12,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              onChanged(date);
            }
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 16,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null
                        ? Formatters.formatDate(value)
                        : 'Sélectionner une date',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: value != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: isMobile ? 16 : 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContainerTypeSelector(ThemeData theme, bool isMobile) {
    final availableTypes =
        QualityControlUtils.getAvailableContainerTypes(_honeyNature);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de contenant *',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: isMobile ? 12 : 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ContainerType>(
          value: _selectedContainerType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            hintText: 'Sélectionner un type',
          ),
          items: availableTypes.map((type) {
            return DropdownMenuItem<ContainerType>(
              value: type,
              child: Text(
                type.label,
                style: TextStyle(fontSize: isMobile ? 13 : 14),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedContainerType = value;
              _containerTypeController.text = value?.label ?? '';
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Veuillez sélectionner un type de contenant';
            }
            return null;
          },
        ),
        if (_honeyNature == HoneyNature.cire)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Pour la cire, seul le sac est disponible',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConformitySelector(ThemeData theme, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conformité *',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: isMobile ? 12 : 14,
          ),
        ),
        const SizedBox(height: 8),
        ...ConformityStatus.values.map((status) {
          final color = QualityControlUtils.getConformityStatusColor(status);
          final icon = QualityControlUtils.getConformityStatusIcon(status);

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: RadioListTile<ConformityStatus>(
              title: Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 8),
                  Text(
                    QualityControlUtils.getConformityStatusLabel(status),
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              value: status,
              groupValue: _conformityStatus,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _conformityStatus = value);
                }
              },
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onCancel,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 12 : 16,
                ),
              ),
              child: Text(
                'Annuler',
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _saveForm,
              icon: const Icon(Icons.save),
              label: Text(
                'Enregistrer le contrôle',
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 12 : 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      // Validation de l'ID de contenant
      if (_validatedContainerId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Veuillez identifier un contenant valide avant de sauvegarder'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 🆕 Validation obligatoire de l'existence du contenant
      if (!_isContainerValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Le contenant doit être recherché et validé avant l\'enregistrement. '
                    'Cliquez sur "Rechercher le contenant" pour vérifier son existence.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 6),
          ),
        );
        return;
      }

      // ✅ Si on vient d'un autre widget qui fournit des correspondances possibles,
      // vérifier qu'au moins une correspondance est trouvée. Sinon, si la validation
      // visuelle a déjà confirmé le contenant, ne pas bloquer sur une liste vide.
      if (_possibleMatches.isNotEmpty &&
          !_possibleMatches.any((m) => m.found)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Le contenant identifié n\'a pas été trouvé dans les collectes'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_possibleMatches.length > 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Plusieurs contenants correspondent. Veuillez en sélectionner un spécifiquement.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Validation supplémentaire
      if (_conformityStatus == ConformityStatus.nonConforme &&
          _nonConformityCauseController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez préciser la cause de non-conformité'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Créer l'objet de données avec l'ID validé
        final qualityData = QualityControlData(
          containerCode: _validatedContainerId, // 🆕 Utiliser l'ID validé
          receptionDate: _receptionDate,
          producer: _producerController.text.trim(),
          apiaryVillage: _villageController.text.trim(),
          hiveType: _hiveTypeController.text.trim(),
          collectionStartDate: _collectionStartDate,
          collectionEndDate: _collectionEndDate,
          honeyNature: _honeyNature,
          containerType: _selectedContainerType?.label ??
              _containerTypeController.text.trim(),
          containerNumber: _containerNumberController.text.trim(),
          totalWeight: double.parse(_totalWeightController.text),
          containerWeight: _containerWeightController.text.isNotEmpty
              ? double.parse(_containerWeightController.text)
              : null,
          honeyWeight: double.parse(_honeyWeightController.text),
          quality: _qualityController.text.trim(),
          waterContent: _waterContentController.text.isNotEmpty
              ? double.parse(_waterContentController.text)
              : null,
          floralPredominance: _floralPredominanceController.text.trim(),
          conformityStatus: _conformityStatus,
          nonConformityCause: _conformityStatus == ConformityStatus.nonConforme
              ? _nonConformityCauseController.text.trim()
              : null,
          observations: _observationsController.text.trim().isNotEmpty
              ? _observationsController.text.trim()
              : null,
          createdAt: DateTime.now(),
          controllerName: _controllerNameController.text.trim(),
          // 🆕 Nouveaux champs pour l'amélioration du contrôle qualité
          containerQualityApproval: _containerQualityApproval,
          odorApproval: _odorApproval,
          sandDepositPresence: _sandDepositPresence,
          trackingCode: _trackingCode,
        );

        // Sauvegarder avec le service en incluant l'ID de la collecte
        final success = await QualityControlService().saveQualityControl(
          qualityData,
          collecteId: widget.collecteItem.id,
        );

        // Fermer le dialog de chargement
        if (mounted) Navigator.of(context).pop();

        if (success) {
          // Feedback utilisateur de succès
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      QualityControlUtils.getConformityStatusIcon(
                          _conformityStatus),
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Contrôle enregistré avec succès!'),
                          Text(
                            'Statut: ${QualityControlUtils.getConformityStatusLabel(_conformityStatus)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: QualityControlUtils.getConformityStatusColor(
                    _conformityStatus),
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Voir',
                  textColor: Colors.white,
                  onPressed: () {
                    // Optionnel: afficher les détails du contrôle
                  },
                ),
              ),
            );
          }

          widget.onSave();
        } else {
          // Feedback utilisateur d'erreur
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Erreur lors de la sauvegarde'),
                  ],
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // Fermer le dialog de chargement
        if (mounted) Navigator.of(context).pop();

        // Afficher l'erreur
        if (mounted) {
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
  }
}
