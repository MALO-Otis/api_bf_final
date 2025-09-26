import 'login.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apisavana_gestion/screens/dashboard/dashboard.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers pour chaque champ ---
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // --- Etats UI ---
  bool showPassword = false;
  bool showConfirmPassword = false;
  int passwordStrength = 0;
  bool isLoading = false;

  // --- Validation ---
  Map<String, String?> errors = {};

  // --- Affectation ---
  String? selectedSite;
  String? selectedRole;
  List<String> availableRoles = [];

  // --- Sites et rôles ---
  final List<Map<String, String>> sites = [
    {'value': 'ouagadougou', 'label': 'Ouagadougou'},
    {'value': 'koudougou', 'label': 'Koudougou'},
    {'value': 'bobo', 'label': 'Bobo-Dioulasso'},
    {'value': 'mangodara', 'label': 'Mangodara'},
    {'value': 'bagre', 'label': 'Bagré'},
    {'value': 'po', 'label': 'Pô'},
  ];

  final Map<String, List<String>> rolesBySite = {
    'ouagadougou': [
      'Magazinier',
      'Commercial',
      'Gestionnaire Commercial',
      'Caissier'
    ],
    'koudougou': [
      'Admin',
      'Collecteur',
      'Contrôleur',
      'Extracteur',
      'Filtreur',
      'Conditionneur',
      'Magazinier',
      'Gestionnaire Commercial',
      'Commercial',
      'Caissier'
    ],
    'bobo': [
      'Admin',
      'Collecteur',
      'Contrôleur',
      'Extracteur',
      'Filtreur',
      'Conditionneur',
      'Magazinier',
      'Gestionnaire Commercial',
      'Commercial',
      'Caissier'
    ],
    'mangodara': ['Collecteur', 'Contrôleur'],
    'bagre': ['Collecteur', 'Contrôleur', 'Filtreur', 'Commercial', 'Caissier'],
    'po': [
      'Admin',
      'Collecteur',
      'Contrôleur',
      'Extracteur',
      'Filtreur',
      'Conditionneur',
      'Magazinier',
      'Gestionnaire Commercial',
      'Commercial',
      'Caissier'
    ],
  };

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Méthode pour vider tous les champs ---
  void _clearAllFields() {
    setState(() {
      // Vider tous les controllers
      firstNameController.clear();
      lastNameController.clear();
      emailController.clear();
      phoneController.clear();
      passwordController.clear();
      confirmPasswordController.clear();

      // Réinitialiser les sélections
      selectedSite = null;
      selectedRole = null;
      availableRoles = [];

      // Réinitialiser les états
      showPassword = false;
      showConfirmPassword = false;
      passwordStrength = 0;

      // Vider les erreurs
      errors.clear();
    });
  }

  // --- Validation en temps réel ---
  String? validateField(String name, String value) {
    switch (name) {
      case 'firstName':
      case 'lastName':
        return value.length < 2 ? 'Minimum 2 caractères' : null;
      case 'email':
        final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+');
        return !emailRegex.hasMatch(value) ? 'Format email invalide' : null;
      case 'phone':
        final phoneRegex = RegExp(r'^(\+226|00226)?[0-9]{8}');
        return !phoneRegex.hasMatch(value.replaceAll(' ', ''))
            ? 'Format téléphone invalide'
            : null;
      case 'password':
        if (value.length < 8) return 'Minimum 8 caractères';
        if (!RegExp(r'[a-z]').hasMatch(value)) return 'Au moins 1 minuscule';
        if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Au moins 1 majuscule';
        if (!RegExp(r'[0-9]').hasMatch(value)) return 'Au moins 1 chiffre';
        return null;
      case 'confirmPassword':
        return value != passwordController.text
            ? 'Les mots de passe ne correspondent pas'
            : null;
      case 'site':
        return value.isEmpty ? 'Site obligatoire' : null;
      case 'role':
        return value.isEmpty ? 'Rôle obligatoire' : null;
      default:
        return null;
    }
  }

  void handleInputChange(String name, String value) {
    setState(() {
      switch (name) {
        case 'firstName':
          errors['firstName'] = validateField('firstName', value);
          break;
        case 'lastName':
          errors['lastName'] = validateField('lastName', value);
          break;
        case 'email':
          errors['email'] = validateField('email', value);
          break;
        case 'phone':
          errors['phone'] = validateField('phone', value);
          break;
        case 'password':
          errors['password'] = validateField('password', value);
          passwordStrength = calculatePasswordStrength(value);
          if (confirmPasswordController.text.isNotEmpty) {
            errors['confirmPassword'] = validateField(
                'confirmPassword', confirmPasswordController.text);
          }
          break;
        case 'confirmPassword':
          errors['confirmPassword'] = validateField('confirmPassword', value);
          break;
        case 'site':
          errors['site'] = validateField('site', value);
          selectedSite = value;
          availableRoles = rolesBySite[value] ?? [];
          if (selectedRole != null && !availableRoles.contains(selectedRole)) {
            selectedRole = null;
          }
          break;
        case 'role':
          errors['role'] = validateField('role', value);
          selectedRole = value;
          break;
      }
      // Correction : efface l'erreur globale si le formulaire est valide
      if (isFormValid()) {
        errors['form'] = null;
      }
    });
  }

  int calculatePasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 8) strength += 25;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 25;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 25;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 25;
    return strength;
  }

  Color getPasswordStrengthColor() {
    if (passwordStrength < 50) return Color(0xFFD32F2F); // rouge
    if (passwordStrength < 75) return Color(0xFFF49101); // orange
    return Color(0xFF2D0C0D); // vert foncé (validation)
  }

  String getPasswordStrengthText() {
    if (passwordStrength < 25) return 'Très faible';
    if (passwordStrength < 50) return 'Faible';
    if (passwordStrength < 75) return 'Moyenne';
    return 'Forte';
  }

  bool isFormValid() {
    final hasNoErrors = errors.values.every((e) => e == null || e.isEmpty);
    final hasAllFields = firstNameController.text.trim().isNotEmpty &&
        lastNameController.text.trim().isNotEmpty &&
        emailController.text.trim().isNotEmpty &&
        phoneController.text.trim().isNotEmpty &&
        passwordController.text.trim().isNotEmpty &&
        confirmPasswordController.text.trim().isNotEmpty &&
        selectedSite != null &&
        selectedRole != null;
    return hasNoErrors && hasAllFields && passwordStrength == 100;
  }

  Future<void> handleSubmit() async {
    if (!isFormValid()) {
      setState(() {
        errors['form'] = 'Veuillez corriger les erreurs dans le formulaire';
      });
      return;
    }
    setState(() => isLoading = true);
    try {
      UserCredential userCred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Envoi de l'email de vérification
      await userCred.user!.sendEmailVerification();

      // Normalisation du site et du rôle avant enregistrement
      String normalizedSite = '';
      if ((selectedSite ?? '').isNotEmpty) {
        normalizedSite = selectedSite![0].toUpperCase() +
            selectedSite!.substring(1).toLowerCase();
      }
      String normalizedRole = '';
      if ((selectedRole ?? '').isNotEmpty) {
        normalizedRole =
            selectedRole![0].toUpperCase() + selectedRole!.substring(1);
      }
      await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(userCred.user!.uid)
          .set({
        'uid': userCred.user!.uid,
        'nom': lastNameController.text.trim(),
        'prenom': firstNameController.text.trim(),
        'email': emailController.text.trim(),
        'telephone': phoneController.text.trim(),
        'site': normalizedSite,
        'role': normalizedRole,
        'emailVerified': false, // Ajout du statut de vérification
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => isLoading = false);

      // Vider tous les champs après création réussie
      _clearAllFields();

      // Affichage du popup de vérification d'email
      _showEmailVerificationDialog();
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
        errors['form'] = e.message ?? 'Erreur lors de la création du compte';
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errors['form'] = 'Erreur inattendue: $e';
      });
    }
  }

  void _showEmailVerificationDialog() {
    // Sauvegarder l'email pour le renvoi
    final userEmail = emailController.text.trim();

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
              Icon(Icons.email, color: Color(0xFFF49101)),
              SizedBox(width: 8),
              Text(
                'Vérification Email',
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
                'Compte créé avec succès !',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Un email de vérification a été envoyé à :',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFF49101).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  emailController.text.trim(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF49101),
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
                          'Vérifiez bien votre adresse email !',
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
                      '• Assurez-vous que l\'adresse ci-dessus est correcte\n• Vérifiez vos spams/courriers indésirables\n• Le lien de vérification expire dans 24h',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                '⚠️ Vous devez vérifier votre email avant de pouvoir vous connecter.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Permettre de modifier l'email si il y a une erreur
              },
              child: Text(
                'Modifier l\'email',
                style: TextStyle(color: Colors.orange[700]),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Revenir à la page précédente (gestion des utilisateurs) ou dashboard
                Get.back();
              },
              child: Text(
                'Continuer',
                style: TextStyle(color: Color(0xFF2D0C0D)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  print('🔄 Tentative de renvoi d\'email...');

                  // Vérifier si un utilisateur est connecté
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) {
                    print(
                        '❌ Aucun utilisateur connecté pour renvoyer l\'email');
                    Get.snackbar(
                      'Erreur',
                      'Aucun utilisateur connecté. Veuillez recréer le compte.',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Colors.red[100],
                      colorText: Colors.red[900],
                    );
                    Navigator.of(context).pop();
                    return;
                  }

                  print('📧 Renvoi d\'email à: ${currentUser.email}');
                  await currentUser.sendEmailVerification();

                  Navigator.of(context).pop();
                  Get.snackbar(
                    'Email renvoyé',
                    'Un nouvel email de vérification a été envoyé à ${userEmail}',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.green[100],
                    colorText: Colors.green[900],
                    duration: Duration(seconds: 4),
                  );

                  print('✅ Email de vérification renvoyé avec succès');
                } catch (e) {
                  print('❌ Erreur lors du renvoi d\'email: $e');
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
                'Renvoyer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: Center(
        child: SingleChildScrollView(
          padding:
              EdgeInsets.symmetric(horizontal: isMobile ? 8 : 0, vertical: 24),
          child: Container(
            constraints: BoxConstraints(maxWidth: 650),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(bottom: 18.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFFF49101), Color(0xFFFFC46B)],
                              ),
                            ),
                            child: Center(
                                child:
                                    Text('🍯', style: TextStyle(fontSize: 24))),
                          ),
                          SizedBox(width: 12),
                          Text('ApiSavana',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF49101))),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Administration > Gestion des utilisateurs > Nouveau compte",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Color(0xFFF49101).withOpacity(0.7),
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Titre
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person, color: Color(0xFF2D0C0D)),
                              SizedBox(width: 8),
                              Text(
                                "Création de Compte",
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D0C0D)),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Créez un nouveau compte utilisateur (accès administrateur requis)",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFF2D0C0D).withOpacity(0.7)),
                          ),
                          SizedBox(height: 24),
                          // --- Section Informations personnelles ---
                          Row(
                            children: [
                              Icon(Icons.person_outline,
                                  color: Color(0xFFF49101)),
                              SizedBox(width: 8),
                              Text("Informations Personnelles",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2D0C0D))),
                            ],
                          ),
                          SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 500;
                              return Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  SizedBox(
                                    width: isWide
                                        ? (constraints.maxWidth / 2) - 12
                                        : constraints.maxWidth,
                                    child: TextFormField(
                                      controller: firstNameController,
                                      decoration: InputDecoration(
                                        labelText: "Prénom *",
                                        prefixIcon: Icon(Icons.person_outline),
                                        errorText: errors['firstName'],
                                      ),
                                      onChanged: (v) =>
                                          handleInputChange('firstName', v),
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide
                                        ? (constraints.maxWidth / 2) - 12
                                        : constraints.maxWidth,
                                    child: TextFormField(
                                      controller: lastNameController,
                                      decoration: InputDecoration(
                                        labelText: "Nom *",
                                        prefixIcon: Icon(Icons.person),
                                        errorText: errors['lastName'],
                                      ),
                                      onChanged: (v) =>
                                          handleInputChange('lastName', v),
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide
                                        ? (constraints.maxWidth / 2) - 12
                                        : constraints.maxWidth,
                                    child: TextFormField(
                                      controller: emailController,
                                      decoration: InputDecoration(
                                        labelText: "Email professionnel *",
                                        prefixIcon: Icon(Icons.email_outlined),
                                        errorText: errors['email'],
                                      ),
                                      onChanged: (v) =>
                                          handleInputChange('email', v),
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide
                                        ? (constraints.maxWidth / 2) - 12
                                        : constraints.maxWidth,
                                    child: TextFormField(
                                      controller: phoneController,
                                      decoration: InputDecoration(
                                        labelText: "Téléphone *",
                                        prefixIcon: Icon(Icons.phone),
                                        errorText: errors['phone'],
                                      ),
                                      keyboardType: TextInputType.phone,
                                      onChanged: (v) =>
                                          handleInputChange('phone', v),
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide
                                        ? (constraints.maxWidth / 2) - 12
                                        : constraints.maxWidth,
                                    child: TextFormField(
                                      controller: passwordController,
                                      obscureText: !showPassword,
                                      decoration: InputDecoration(
                                        labelText: "Mot de passe *",
                                        prefixIcon: Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          icon: Icon(showPassword
                                              ? Icons.visibility_off
                                              : Icons.visibility),
                                          onPressed: () => setState(() =>
                                              showPassword = !showPassword),
                                        ),
                                        errorText: errors['password'],
                                      ),
                                      onChanged: (v) =>
                                          handleInputChange('password', v),
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide
                                        ? (constraints.maxWidth / 2) - 12
                                        : constraints.maxWidth,
                                    child: TextFormField(
                                      controller: confirmPasswordController,
                                      obscureText: !showConfirmPassword,
                                      decoration: InputDecoration(
                                        labelText:
                                            "Confirmer le mot de passe *",
                                        prefixIcon: Icon(Icons.lock),
                                        suffixIcon: IconButton(
                                          icon: Icon(showConfirmPassword
                                              ? Icons.visibility_off
                                              : Icons.visibility),
                                          onPressed: () => setState(() =>
                                              showConfirmPassword =
                                                  !showConfirmPassword),
                                        ),
                                        errorText: errors['confirmPassword'],
                                      ),
                                      onChanged: (v) => handleInputChange(
                                          'confirmPassword', v),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          if (passwordController.text.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8.0, bottom: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Force du mot de passe:",
                                          style: TextStyle(fontSize: 12)),
                                      Text(getPasswordStrengthText(),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  getPasswordStrengthColor())),
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  LinearProgressIndicator(
                                    value: passwordStrength / 100,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation(
                                        getPasswordStrengthColor()),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: 24),
                          // --- Section Affectation ---
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  color: Color(0xFFF49101)),
                              SizedBox(width: 8),
                              Text("Affectation",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2D0C0D))),
                            ],
                          ),
                          SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 500;
                              return Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  SizedBox(
                                    width: isWide
                                        ? (constraints.maxWidth / 2) - 12
                                        : constraints.maxWidth,
                                    child: DropdownButtonFormField<String>(
                                      value: selectedSite,
                                      decoration: InputDecoration(
                                        labelText: "Site d'affectation *",
                                        prefixIcon:
                                            Icon(Icons.location_on_outlined),
                                        errorText: errors['site'],
                                      ),
                                      items: sites
                                          .map((site) => DropdownMenuItem(
                                                value: site['value'],
                                                child: Text(site['label']!),
                                              ))
                                          .toList(),
                                      onChanged: (v) =>
                                          handleInputChange('site', v ?? ''),
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide
                                        ? (constraints.maxWidth / 2) - 12
                                        : constraints.maxWidth,
                                    child: DropdownButtonFormField<String>(
                                      value: selectedRole != null &&
                                              availableRoles
                                                  .contains(selectedRole)
                                          ? selectedRole
                                          : null,
                                      decoration: InputDecoration(
                                        labelText: "Rôle *",
                                        prefixIcon: Icon(Icons.shield_outlined),
                                        errorText: errors['role'],
                                      ),
                                      items: availableRoles
                                          .map((role) => DropdownMenuItem(
                                                value: role,
                                                child: Text(
                                                  role,
                                                  style:
                                                      TextStyle(fontSize: 12),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: selectedSite == null
                                          ? null
                                          : (v) => handleInputChange(
                                              'role', v ?? ''),
                                      disabledHint:
                                          Text("Choisir un site d'abord"),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          if (selectedSite != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                "${availableRoles.length} rôle(s) disponible(s) pour " +
                                    (sites.firstWhere((s) =>
                                            s['value'] ==
                                            selectedSite)['label'] ??
                                        ''),
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFFF49101)),
                              ),
                            ),
                          SizedBox(height: 24),
                          // --- Message d'erreur global ---
                          if (errors['form'] != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Text(
                                errors['form']!,
                                style:
                                    TextStyle(color: Colors.red, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          // --- Boutons ---
                          SizedBox(height: 6),
                          ElevatedButton.icon(
                            onPressed: isLoading ? null : handleSubmit,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              backgroundColor: Color(0xFFF49101),
                            ),
                            icon: isLoading
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Icon(Icons.check, color: Colors.white),
                            label: Text(
                              isLoading
                                  ? "Création en cours..."
                                  : "Créer le compte",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                          SizedBox(height: 18),
                          OutlinedButton.icon(
                            onPressed: () {
                              // Si on peut revenir en arrière, on le fait, sinon on va au dashboard
                              if (Get.routing.previous.isNotEmpty) {
                                Get.back();
                              } else {
                                Get.offAll(() => DashboardPage());
                              }
                            },
                            icon: Icon(Icons.arrow_back,
                                color: Color(0xFF2D0C0D)),
                            label: Text("Retour",
                                style: TextStyle(color: Color(0xFF2D0C0D))),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Color(0xFFF49101)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          SizedBox(height: 12),
                          // --- Lien vers la page de login ---
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Get.off(() => LoginPage());
                              },
                              child: Text(
                                "Déjà un compte ? Connectez-vous",
                                style: TextStyle(color: Color(0xFF2D0C0D)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
