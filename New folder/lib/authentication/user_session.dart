import 'package:get/get.dart';

class UserSession extends GetxController {
  String? uid;
  String? role;
  String? nom;
  String? email;
  String? photoUrl;
  String? site; // Ajout du champ site

  void setUser({
    required String uid,
    required String role,
    required String nom,
    required String email,
    required String site, // Ajout du paramètre site
    String? photoUrl,
  }) {
    this.uid = uid;
    this.role = role;
    this.nom = nom;
    this.email = email;
    this.site = site;
    this.photoUrl = photoUrl;
  }
}
