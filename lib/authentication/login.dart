import 'package:apisavana_gestion/screens/dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:apisavana_gestion/authentication/user_session.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;
  bool showPassword = false;
  String? emailError;
  String? passwordError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String? validateEmail(String value) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+');
    if (!emailRegex.hasMatch(value)) return 'Format email invalide';
    return null;
  }

  String? validatePassword(String value) {
    if (value.length < 8) return 'Minimum 8 caractères';
    return null;
  }

  void handleInputChange(String name, String value) {
    setState(() {
      if (name == 'email') {
        emailError = validateEmail(value);
      } else if (name == 'password') {
        passwordError = validatePassword(value);
      }
    });
  }

  void login() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      emailError = validateEmail(emailController.text.trim());
      passwordError = validatePassword(passwordController.text.trim());
    });
    if (emailError != null || passwordError != null) {
      setState(() => isLoading = false);
      return;
    }
    try {
      UserCredential userCred =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // ÉTAPE CRITIQUE: Vérification de l'email avant de continuer
      await userCred.user!.reload(); // Actualise les informations utilisateur
      if (!userCred.user!.emailVerified) {
        setState(() => isLoading = false);
        print(
            '🚫 Tentative de connexion avec email non vérifié: ${userCred.user!.email}');
        _showEmailNotVerifiedDialog(userCred.user!);
        await FirebaseAuth.instance.signOut(); // Déconnecte l'utilisateur
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(userCred.user!.uid)
          .get();
      if (!userDoc.exists) {
        errorMessage = "Compte utilisateur non trouvé dans la base.";
        setState(() => isLoading = false);
        return;
      }
      final userData = userDoc.data()!;

      // Mise à jour du statut de vérification dans Firestore
      await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(userCred.user!.uid)
          .update({'emailVerified': true});

      // Normalisation automatique du champ site et du rôle à la connexion
      String normalizedSite = '';
      if ((userData['site'] ?? '').toString().isNotEmpty) {
        String s = userData['site'];
        normalizedSite = s[0].toUpperCase() + s.substring(1).toLowerCase();
      }
      String normalizedRole = '';
      if ((userData['role'] ?? '').toString().isNotEmpty) {
        String r = userData['role'];
        normalizedRole = r[0].toUpperCase() + r.substring(1);
      }
      // Debug print pour le site et le rôle récupérés de la base et leur version normalisée
      print(
          'USER FROM DB - site: \'${userData['site']}\', role: \'${userData['role']}\'');
      print(
          'USER NORMALIZED - site: \'$normalizedSite\', role: \'$normalizedRole\'');
      // Debug print pour la liste des sites et rôles attendus dans le dashboard
      print('DASHBOARD SITES: [Ouaga, Koudougou, Bobo, Mangodara, Bagre, Pô]');
      print(
          'DASHBOARD ROLES: [Admin, Collecteur, Contrôleur, Controlleur, Filtreur, Conditionneur, Magazinier, Gestionnaire Commercial, Commercial, Caissier, Caissière, Extracteur]');
      Get.put(UserSession(), permanent: true).setUser(
        uid: userCred.user!.uid,
        role: normalizedRole,
        nom: userData['nom'] ?? '',
        email: userData['email'] ?? '',
        site: normalizedSite, // Utilise le site normalisé
        photoUrl: userData['photoUrl'],
      );
      print('SESSION - site: \'$normalizedSite\', role: \'$normalizedRole\'');
      print('✅ Connexion réussie avec email vérifié: ${userCred.user!.email}');
      // Navigation GetX vers le dashboard sans routes nommées
      Get.offAll(() => const DashboardPage());
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? "Erreur lors de la connexion";
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showEmailNotVerifiedDialog(User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Email non vérifié',
                style: TextStyle(
                  color: Color(0xFF2D0C0D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Votre email n\'est pas encore vérifié.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Vous devez vérifier votre email avant de pouvoir accéder à votre compte.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user.email ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue.shade600, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Instructions :',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      '1. Vérifiez votre boîte de réception\n2. Cherchez dans vos spams/courriers indésirables\n3. Cliquez sur le lien de vérification\n4. Revenez vous connecter',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Fermer',
                style: TextStyle(color: Color(0xFF2D0C0D)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  print('🔄 [LOGIN] Tentative de renvoi d\'email...');
                  print('📧 [LOGIN] Email utilisateur: ${user.email}');
                  print('🔐 [LOGIN] UID utilisateur: ${user.uid}');

                  await user.sendEmailVerification();

                  Navigator.of(context).pop();
                  Get.snackbar(
                    'Email renvoyé',
                    'Un nouvel email de vérification a été envoyé à ${user.email}',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.green[100],
                    colorText: Colors.green[900],
                    duration: Duration(seconds: 4),
                  );

                  print('✅ [LOGIN] Email de vérification renvoyé avec succès');
                } catch (e) {
                  print('❌ [LOGIN] Erreur lors du renvoi d\'email: $e');
                  Navigator.of(context).pop();
                  Get.snackbar(
                    'Erreur',
                    'Impossible de renvoyer l\'email: ${e.toString()}',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.red[100],
                    colorText: Colors.red[900],
                    duration: Duration(seconds: 5),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF49101),
              ),
              child: Text(
                'Renvoyer l\'email',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> handleLogin() async {
    setState(() => isLoading = true);
    await Future.delayed(Duration(seconds: 2));
    setState(() => isLoading = false);
    Get.offAllNamed('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF8F0), Color(0xFFF49101), Color(0xFF2D0C0D)],
            stops: [0.1, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 0, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22)),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 18 : 36,
                    vertical: isMobile ? 24 : 36,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo centré agrandi
                      Center(
                        child: Image.asset(
                          "assets/logo/logo.jpeg",
                          height: isMobile ? 120 : 150,
                          width: isMobile ? 120 : 150,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: 24),
                      Center(
                        child: Text(
                          "Connexion à la plateforme",
                          style: TextStyle(
                            color: Color(0xFF2D0C0D).withOpacity(0.8),
                            fontSize: isMobile ? 15 : 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 28),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (isMobile) {
                            // Champs en colonne sur mobile
                            return Column(
                              children: [
                                _emailField(),
                                SizedBox(height: 18),
                                _passwordField(),
                              ],
                            );
                          } else {
                            // Champs côte à côte sur desktop
                            return Row(
                              children: [
                                Expanded(child: _emailField()),
                                SizedBox(width: 18),
                                Expanded(child: _passwordField()),
                              ],
                            );
                          }
                        },
                      ),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            "Mot de passe oublié ?",
                            style: TextStyle(
                              color: Color(0xFF2D0C0D),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 4),
                          child: Text(
                            errorMessage!,
                            style: TextStyle(color: Colors.red, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              isLoading ? null : login, // Correction ici !
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF49101),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Text(
                                  "Se connecter",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailField() {
    return TextFormField(
      controller: emailController,
      decoration: InputDecoration(
        labelText: "Email",
        prefixIcon: Icon(Icons.email_outlined),
        errorText: emailError,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      ),
      keyboardType: TextInputType.emailAddress,
      onChanged: (v) => handleInputChange('email', v),
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: passwordController,
      obscureText: !showPassword,
      decoration: InputDecoration(
        labelText: "Mot de passe",
        prefixIcon: Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => showPassword = !showPassword),
        ),
        errorText: passwordError,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      ),
      onChanged: (v) => handleInputChange('password', v),
    );
  }
}
