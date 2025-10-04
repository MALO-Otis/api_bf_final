import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Widget formulaire de création d'utilisateur basé sur le sign up
class SignupFormWidget extends StatefulWidget {
  final VoidCallback onUserCreated;

  const SignupFormWidget({
    Key? key,
    required this.onUserCreated,
  }) : super(key: key);

  @override
  State<SignupFormWidget> createState() => _SignupFormWidgetState();
}

class _SignupFormWidgetState extends State<SignupFormWidget> {
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
      firstNameController.clear();
      lastNameController.clear();
      emailController.clear();
      phoneController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      selectedSite = null;
      selectedRole = null;
      availableRoles = [];
      showPassword = false;
      showConfirmPassword = false;
      passwordStrength = 0;
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
        return null;
      case 'confirmPassword':
        return value != passwordController.text
            ? 'Les mots de passe ne correspondent pas'
            : null;
      default:
        return null;
    }
  }

  void handleInputChange(String name, String value) {
    setState(() {
      errors[name] = validateField(name, value);
      if (name == 'password') {
        passwordStrength = _calculatePasswordStrength(value);
        // Re-valider la confirmation si elle existe
        if (confirmPasswordController.text.isNotEmpty) {
          errors['confirmPassword'] =
              validateField('confirmPassword', confirmPasswordController.text);
        }
      }
    });
  }

  int _calculatePasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;
    return strength;
  }

  Future<void> signUp() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation des champs obligatoires
    final requiredFields = [
      ('firstName', firstNameController.text.trim()),
      ('lastName', lastNameController.text.trim()),
      ('email', emailController.text.trim()),
      ('phone', phoneController.text.trim()),
      ('password', passwordController.text),
      ('confirmPassword', confirmPasswordController.text),
    ];

    bool hasErrors = false;
    for (final (name, value) in requiredFields) {
      final error = validateField(name, value);
      if (error != null) {
        setState(() => errors[name] = error);
        hasErrors = true;
      }
    }

    if (selectedSite == null || selectedRole == null) {
      setState(
          () => errors['form'] = 'Veuillez sélectionner un site et un rôle');
      hasErrors = true;
    }

    if (hasErrors) return;

    setState(() => isLoading = true);

    try {
      // Créer l'utilisateur avec Firebase Auth
      final userCred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // Envoyer l'email de vérification
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
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => isLoading = false);

      // Affichage du popup de vérification d'email AVANT de vider les champs
      final userEmail = emailController.text.trim();
      _showEmailVerificationDialog(userEmail);

      // Vider tous les champs après affichage du dialog
      _clearAllFields();
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

  void _showEmailVerificationDialog(String userEmail) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.email, color: Colors.green),
            SizedBox(width: 8),
            Text('Email de vérification envoyé'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Un email de vérification a été envoyé à:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                userEmail,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'L\'utilisateur devra vérifier son email avant de pouvoir se connecter.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onUserCreated();
            },
            child: Text(
              'Continuer',
              style: TextStyle(color: Color(0xFF2D0C0D)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titre
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add, color: Color(0xFF2196F3), size: 28),
                SizedBox(width: 12),
                Text(
                  "Création d'un Nouvel Utilisateur",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D0C0D),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              "Créez un nouveau compte utilisateur avec accès immédiat",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF2D0C0D).withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            SizedBox(height: 32),

            // --- Section Informations personnelles ---
            Row(
              children: [
                Icon(Icons.person_outline, color: Color(0xFF2196F3)),
                SizedBox(width: 8),
                Text(
                  "Informations Personnelles",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D0C0D),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (v) => handleInputChange('firstName', v),
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
                          prefixIcon: Icon(Icons.person_outline),
                          errorText: errors['lastName'],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (v) => handleInputChange('lastName', v),
                      ),
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: 16),

            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email *",
                prefixIcon: Icon(Icons.email_outlined),
                errorText: errors['email'],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (v) => handleInputChange('email', v),
            ),

            SizedBox(height: 16),

            TextFormField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: "Téléphone *",
                prefixIcon: Icon(Icons.phone_outlined),
                errorText: errors['phone'],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: "+226 XX XX XX XX",
              ),
              keyboardType: TextInputType.phone,
              onChanged: (v) => handleInputChange('phone', v),
            ),

            SizedBox(height: 24),

            // --- Section Mot de passe ---
            Row(
              children: [
                Icon(Icons.lock_outline, color: Color(0xFF2196F3)),
                SizedBox(width: 8),
                Text(
                  "Mot de Passe",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D0C0D),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            TextFormField(
              controller: passwordController,
              obscureText: !showPassword,
              decoration: InputDecoration(
                labelText: "Mot de passe *",
                prefixIcon: Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => showPassword = !showPassword),
                ),
                errorText: errors['password'],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => handleInputChange('password', v),
            ),

            SizedBox(height: 8),

            // Indicateur de force du mot de passe
            if (passwordController.text.isNotEmpty) ...[
              Row(
                children: [
                  Text("Force: ", style: TextStyle(fontSize: 12)),
                  ...List.generate(5, (index) {
                    return Container(
                      margin: EdgeInsets.only(right: 4),
                      width: 20,
                      height: 4,
                      decoration: BoxDecoration(
                        color: index < passwordStrength
                            ? (passwordStrength <= 2
                                ? Colors.red
                                : passwordStrength <= 3
                                    ? Colors.orange
                                    : Colors.green)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                  SizedBox(width: 8),
                  Text(
                    passwordStrength <= 2
                        ? "Faible"
                        : passwordStrength <= 3
                            ? "Moyen"
                            : "Fort",
                    style: TextStyle(
                      fontSize: 12,
                      color: passwordStrength <= 2
                          ? Colors.red
                          : passwordStrength <= 3
                              ? Colors.orange
                              : Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],

            TextFormField(
              controller: confirmPasswordController,
              obscureText: !showConfirmPassword,
              decoration: InputDecoration(
                labelText: "Confirmer le mot de passe *",
                prefixIcon: Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(showConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () => setState(
                      () => showConfirmPassword = !showConfirmPassword),
                ),
                errorText: errors['confirmPassword'],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => handleInputChange('confirmPassword', v),
            ),

            SizedBox(height: 24),

            // --- Section Affectation ---
            Row(
              children: [
                Icon(Icons.business_outlined, color: Color(0xFF2196F3)),
                SizedBox(width: 8),
                Text(
                  "Affectation",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D0C0D),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: selectedSite,
              decoration: InputDecoration(
                labelText: "Site *",
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: sites.map((site) {
                return DropdownMenuItem(
                  value: site['value'],
                  child: Text(site['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSite = value;
                  selectedRole = null;
                  availableRoles = rolesBySite[value] ?? [];
                });
              },
            ),

            SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: InputDecoration(
                labelText: "Rôle *",
                prefixIcon: Icon(Icons.work_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: availableRoles.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedRole = value),
            ),

            if (errors['form'] != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  errors['form']!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],

            SizedBox(height: 32),

            // Bouton de création
            ElevatedButton(
              onPressed: isLoading ? null : signUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text("Création en cours..."),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add),
                        SizedBox(width: 8),
                        Text(
                          "Créer l'Utilisateur",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
}
