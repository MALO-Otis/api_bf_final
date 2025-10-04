class GeoVillage {
  final String code;
  String nom;

  GeoVillage({required this.code, required this.nom});

  factory GeoVillage.fromMap(Map<String, dynamic> map) {
    return GeoVillage(
      code: (map['code'] ?? '').toString(),
      nom: (map['nom'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'nom': nom,
    };
  }

  GeoVillage copyWith({String? code, String? nom}) {
    return GeoVillage(
      code: code ?? this.code,
      nom: nom ?? this.nom,
    );
  }
}

class GeoCommune {
  final String code;
  String nom;
  final List<GeoVillage> villages;

  GeoCommune({required this.code, required this.nom, List<GeoVillage>? villages})
      : villages = villages ?? <GeoVillage>[];

  factory GeoCommune.fromMap(Map<String, dynamic> map) {
    final rawVillages = (map['villages'] as List?) ?? const [];
    return GeoCommune(
      code: (map['code'] ?? '').toString(),
      nom: (map['nom'] ?? '').toString(),
      villages: rawVillages
          .map((v) => GeoVillage.fromMap(Map<String, dynamic>.from(v)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'nom': nom,
      'villages': villages.map((v) => v.toMap()).toList(),
    };
  }

  GeoCommune copyWith({String? code, String? nom, List<GeoVillage>? villages}) {
    return GeoCommune(
      code: code ?? this.code,
      nom: nom ?? this.nom,
      villages: villages ?? this.villages.map((v) => v.copyWith()).toList(),
    );
  }

  int get villagesCount => villages.length;
}

class GeoProvince {
  final String code;
  String nom;
  final List<GeoCommune> communes;

  GeoProvince({required this.code, required this.nom, List<GeoCommune>? communes})
      : communes = communes ?? <GeoCommune>[];

  factory GeoProvince.fromMap(Map<String, dynamic> map) {
    final rawCommunes = (map['communes'] as List?) ?? const [];
    return GeoProvince(
      code: (map['code'] ?? '').toString(),
      nom: (map['nom'] ?? '').toString(),
      communes: rawCommunes
          .map((c) => GeoCommune.fromMap(Map<String, dynamic>.from(c)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'nom': nom,
      'communes': communes.map((c) => c.toMap()).toList(),
    };
  }

  GeoProvince copyWith({String? code, String? nom, List<GeoCommune>? communes}) {
    return GeoProvince(
      code: code ?? this.code,
      nom: nom ?? this.nom,
      communes: communes ?? this.communes.map((c) => c.copyWith()).toList(),
    );
  }

  int get communesCount => communes.length;
  int get villagesCount =>
      communes.fold<int>(0, (total, c) => total + c.villagesCount);
}

class GeoRegion {
  final String code;
  String nom;
  final List<GeoProvince> provinces;

  GeoRegion({required this.code, required this.nom, List<GeoProvince>? provinces})
      : provinces = provinces ?? <GeoProvince>[];

  factory GeoRegion.fromMap(Map<String, dynamic> map) {
    final rawProvinces = (map['provinces'] as List?) ?? const [];
    return GeoRegion(
      code: (map['code'] ?? '').toString(),
      nom: (map['nom'] ?? '').toString(),
      provinces: rawProvinces
          .map((p) => GeoProvince.fromMap(Map<String, dynamic>.from(p)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'nom': nom,
      'provinces': provinces.map((p) => p.toMap()).toList(),
    };
  }

  GeoRegion copyWith({String? code, String? nom, List<GeoProvince>? provinces}) {
    return GeoRegion(
      code: code ?? this.code,
      nom: nom ?? this.nom,
      provinces: provinces ?? this.provinces.map((p) => p.copyWith()).toList(),
    );
  }

  int get provincesCount => provinces.length;
  int get communesCount =>
    provinces.fold<int>(0, (total, p) => total + p.communesCount);
  int get villagesCount =>
    provinces.fold<int>(0, (total, p) => total + p.villagesCount);
}
