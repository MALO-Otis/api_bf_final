import 'package:get/get.dart';
import '../models/metier_models.dart';
import '../../../authentication/user_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MetierSaveResult {
  final bool success;
  final String message;
  final dynamic error;

  const MetierSaveResult({
    required this.success,
    required this.message,
    this.error,
  });
}

class MetierSettingsService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserSession _userSession = Get.find<UserSession>();

  CollectionReference get _collection => _firestore.collection('metiers');
  DocumentReference get _predominenceDoc =>
      _collection.doc('predominence_florale');
  DocumentReference get _pricingDoc => _collection.doc('prix_produits');

  final RxList<FloralPredominence> _predominences = <FloralPredominence>[].obs;
  final RxMap<String, double> _monoPackagingPrices = <String, double>{}.obs;
  final RxMap<String, double> _milleFleursPackagingPrices =
      <String, double>{}.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _hasUnsavedChanges = false.obs;
  final RxnString _errorMessage = RxnString();

  List<FloralPredominence> get predominences => _predominences;
  Map<String, double> get monoPackagingPrices =>
      Map<String, double>.unmodifiable(_monoPackagingPrices);
  Map<String, double> get milleFleursPackagingPrices =>
      Map<String, double>.unmodifiable(_milleFleursPackagingPrices);
  bool get isLoading => _isLoading.value;
  bool get hasUnsavedChanges => _hasUnsavedChanges.value;
  String? get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    loadMetierSettings();
  }

  Future<void> loadMetierSettings() async {
    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      final results = await Future.wait([
        _predominenceDoc.get(),
        _pricingDoc.get(),
      ]);

      final predominenceSnap = results[0];
      final pricingSnap = results[1];

      final Map<String, dynamic> predominenceData =
          (predominenceSnap.data() as Map<String, dynamic>?) ?? {};
      final List<dynamic> rawEntries = predominenceData['entries'] ?? [];

      final Map<String, dynamic> pricingData =
          (pricingSnap.data() as Map<String, dynamic>?) ?? {};
      final Map<String, dynamic> monoRaw =
          _asStringDynamicMap(pricingData['mono']) ?? const <String, dynamic>{};
      final Map<String, dynamic> multiRaw =
          _asStringDynamicMap(pricingData['mille_fleurs']) ??
              _asStringDynamicMap(pricingData['multi']) ??
              const <String, dynamic>{};

      final List<FloralPredominence> loaded = rawEntries.map((dynamic entry) {
        final Map<String, dynamic> entryMap =
            Map<String, dynamic>.from(entry as Map);

        return FloralPredominence.fromFirestore(
          metadata: entryMap,
        );
      }).toList();

      if (loaded.isEmpty) {
        _predominences.assignAll(_defaultPredominences());
      } else {
        _predominences.assignAll(loaded);
      }

      _monoPackagingPrices.assignAll(_buildPricingMap(monoRaw));
      _milleFleursPackagingPrices.assignAll(_buildPricingMap(multiRaw));

      _hasUnsavedChanges.value = false;
    } catch (e) {
      _errorMessage.value = 'Erreur lors du chargement: $e';
      _predominences.assignAll(_defaultPredominences());
      _monoPackagingPrices.assignAll(
        _buildPricingMap(const <String, dynamic>{}),
      );
      _milleFleursPackagingPrices.assignAll(
        _buildPricingMap(const <String, dynamic>{}),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  List<FloralPredominence> _defaultPredominences() {
    return const [
      FloralPredominence(
        id: 'acacia',
        name: 'Acacia',
      ),
      FloralPredominence(
        id: 'karite',
        name: 'Karité',
      ),
      FloralPredominence(
        id: 'nere',
        name: 'Néré',
      ),
    ];
  }

  void addPredominence({
    required String name,
  }) {
    if (name.trim().isEmpty) {
      return;
    }

    final normalizedName = name.trim();
    final id = _buildPredominenceId(normalizedName);

    final newEntry = FloralPredominence(
      id: id,
      name: normalizedName,
    );

    _predominences.add(newEntry);
    _hasUnsavedChanges.value = true;
  }

  void updatePredominenceName(String id, String name) {
    final index = _predominences.indexWhere((element) => element.id == id);
    if (index == -1) return;

    final updated = _predominences[index]
        .copyWith(name: name.trim().isEmpty ? 'Sans nom' : name.trim());
    _predominences[index] = updated;
    _hasUnsavedChanges.value = true;
  }

  void updateMonoPackagingPrice(String size, double price) {
    _updatePackagingPrice(_monoPackagingPrices, size, price);
  }

  void updateMilleFleursPackagingPrice(String size, double price) {
    _updatePackagingPrice(_milleFleursPackagingPrices, size, price);
  }

  void removePredominence(String id) {
    _predominences.removeWhere((element) => element.id == id);
    _hasUnsavedChanges.value = true;
  }

  Future<MetierSaveResult> saveMetierSettings() async {
    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      final metadata =
          _predominences.map((pred) => pred.toMetadataMap()).toList();
      await Future.wait([
        _predominenceDoc.set({
          'entries': metadata,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _userSession.email ?? 'system',
        }),
        _pricingDoc.set({
          'mono': Map<String, double>.from(_monoPackagingPrices),
          'mille_fleurs': Map<String, double>.from(_milleFleursPackagingPrices),
          'packagingOrder': kHoneyPackagingOrder,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _userSession.email ?? 'system',
        }),
      ]);

      _hasUnsavedChanges.value = false;
      return const MetierSaveResult(
        success: true,
        message: 'Configuration métier sauvegardée',
      );
    } catch (e) {
      _errorMessage.value = 'Erreur lors de la sauvegarde: $e';
      return MetierSaveResult(
        success: false,
        message: 'Impossible de sauvegarder la configuration métier',
        error: e,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Map<String, dynamic>? _asStringDynamicMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, dynamic v) => MapEntry(key.toString(), v));
    }
    return null;
  }

  Map<String, double> _buildPricingMap(Map<String, dynamic> raw) {
    final Map<String, double> result = {
      for (final size in kHoneyPackagingOrder) size: 0.0,
    };

    for (final entry in raw.entries) {
      final key = entry.key;
      if (!kHoneyPackagingOrder.contains(key)) continue;
      result[key] = _parsePrice(entry.value);
    }

    return result;
  }

  String _buildPredominenceId(String name) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (base.isEmpty) {
      return 'flore_$timestamp';
    }

    final exists = _predominences.any((element) => element.id == base);
    if (!exists) {
      return base;
    }
    return '${base}_$timestamp';
  }

  void _updatePackagingPrice(
    RxMap<String, double> target,
    String size,
    double price,
  ) {
    if (!kHoneyPackagingOrder.contains(size)) return;

    target[size] = price < 0 ? 0 : double.parse(price.toStringAsFixed(2));
    _hasUnsavedChanges.value = true;
  }

  double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value.toString().replaceAll(',', '.'));
    return parsed ?? 0.0;
  }
}
