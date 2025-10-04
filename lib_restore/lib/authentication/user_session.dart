import 'package:get/get.dart';

class UserSession extends GetxController {
  String? uid;
  List<String> roles = <String>[];
  String? nom;
  String? email;
  String? photoUrl;
  String? site; // Ajout du champ site

  String? get role => roles.isNotEmpty ? roles.first : null;

  void setUser({
    required String uid,
    required List<String> roles,
    required String nom,
    required String email,
    required String site, // Ajout du paramètre site
    String? photoUrl,
  }) {
    this.uid = uid;
    this.roles = List<String>.unmodifiable(roles);
    this.nom = nom;
    this.email = email;
    this.site = site;
    this.photoUrl = photoUrl;
  }
}
