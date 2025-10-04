import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service d'envoi d'emails pour les confirmations utilisateur
class EmailService extends GetxService {
  // Configuration EmailJS (service gratuit pour envoyer des emails depuis Flutter)
  static const String _serviceId = 'your_emailjs_service_id';
  static const String _templateId = 'your_emailjs_template_id';
  static const String _publicKey = 'your_emailjs_public_key';
  static const String _privateKey = 'your_emailjs_private_key';

  /// Envoyer un email de confirmation d'inscription
  Future<bool> sendWelcomeEmail({
    required String userEmail,
    required String userName,
    required String userRole,
    required String userSite,
    required String temporaryPassword,
  }) async {
    try {
      final Map<String, dynamic> templateParams = {
        'to_email': userEmail,
        'to_name': userName,
        'user_role': userRole,
        'user_site': userSite,
        'login_url': 'https://votre-app.com/login', // Remplacez par votre URL
        'temp_password': temporaryPassword,
        'company_name': 'ApiSavana Gestion',
        'support_email': 'support@apisavana.com',
      };

      // Utilisation d'EmailJS pour envoyer l'email
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'accessToken': _privateKey,
          'template_params': templateParams,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Email de bienvenue envoyé avec succès à $userEmail');
        return true;
      } else {
        print('❌ Erreur lors de l\'envoi de l\'email: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Exception lors de l\'envoi de l\'email: $e');
      return false;
    }
  }

  /// Envoyer un email de réinitialisation de mot de passe
  Future<bool> sendPasswordResetEmail({
    required String userEmail,
    required String userName,
    required String resetLink,
  }) async {
    try {
      final Map<String, dynamic> templateParams = {
        'to_email': userEmail,
        'to_name': userName,
        'reset_link': resetLink,
        'company_name': 'ApiSavana Gestion',
        'support_email': 'support@apisavana.com',
      };

      // Template différent pour la réinitialisation
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': _serviceId,
          'template_id': 'password_reset_template', // Template spécifique
          'user_id': _publicKey,
          'accessToken': _privateKey,
          'template_params': templateParams,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Exception lors de l\'envoi de l\'email de réinitialisation: $e');
      return false;
    }
  }

  /// Envoyer un email confirmant le changement de mot de passe
  Future<bool> sendPasswordChangedEmail({
    required String userEmail,
    required String userName,
    required String newPassword,
  }) async {
    try {
      final Map<String, dynamic> templateParams = {
        'to_email': userEmail,
        'to_name': userName,
        'new_password': newPassword,
        'company_name': 'ApiSavana Gestion',
        'support_email': 'support@apisavana.com',
      };

      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': _serviceId,
          'template_id': 'password_changed_template',
          'user_id': _publicKey,
          'accessToken': _privateKey,
          'template_params': templateParams,
        }),
      );

      if (response.statusCode == 200) {
        print(
            '✅ Email de changement de mot de passe envoyé avec succès à $userEmail');
        return true;
      } else {
        print(
            "❌ Erreur lors de l'envoi de l'email de changement de mot de passe: ${response.statusCode}");
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print(
          "❌ Exception lors de l'envoi de l'email de changement de mot de passe: $e");
      return false;
    }
  }

  /// Version locale/logging de l'email de confirmation de changement de mot de passe
  Future<bool> sendPasswordChangedEmailLocal({
    required String userEmail,
    required String userName,
    required String newPassword,
  }) async {
    try {
      if (kDebugMode) {
        print('🔐 CONFIRMATION CHANGEMENT MOT DE PASSE');
        print('========================================');
        print('À: $userEmail');
        print('Utilisateur: $userName');
        print('Nouveau mot de passe: $newPassword');
        print('========================================');
        return true;
      }

      return await sendPasswordChangedEmail(
        userEmail: userEmail,
        userName: userName,
        newPassword: newPassword,
      );
    } catch (e) {
      print(
          "❌ Erreur lors de la simulation d'envoi de l'email de changement de mot de passe: $e");
      return false;
    }
  }

  /// Générer le contenu HTML de l'email de bienvenue
  // ignore: unused_element
  String _generateWelcomeEmailHTML({
    required String userName,
    required String userEmail,
    required String userRole,
    required String userSite,
    required String temporaryPassword,
    required String loginUrl,
  }) {
    return '''
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bienvenue sur ApiSavana Gestion</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #F49101 0%, #FF6B35 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .info-box { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #F49101; }
        .credentials { background: #e8f4fd; padding: 15px; border-radius: 5px; margin: 15px 0; }
        .button { display: inline-block; background: #F49101; color: white; padding: 12px 25px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
        .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
        .warning { background: #fff3cd; border: 1px solid #ffeaa7; color: #856404; padding: 15px; border-radius: 5px; margin: 15px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🍯 Bienvenue sur ApiSavana Gestion</h1>
        <p>Votre compte a été créé avec succès !</p>
    </div>
    
    <div class="content">
        <h2>Bonjour $userName,</h2>
        
        <p>Nous sommes ravis de vous accueillir dans l'équipe ApiSavana ! Votre compte utilisateur a été créé avec succès.</p>
        
        <div class="info-box">
            <h3>📋 Informations de votre compte :</h3>
            <ul>
                <li><strong>Nom :</strong> $userName</li>
                <li><strong>Email :</strong> $userEmail</li>
                <li><strong>Rôle :</strong> $userRole</li>
                <li><strong>Site :</strong> $userSite</li>
            </ul>
        </div>
        
        <div class="credentials">
            <h3>🔐 Vos identifiants de connexion :</h3>
            <p><strong>Email :</strong> $userEmail</p>
            <p><strong>Mot de passe temporaire :</strong> <code>$temporaryPassword</code></p>
        </div>
        
        <div class="warning">
            <strong>⚠️ Important :</strong> Pour des raisons de sécurité, nous vous recommandons fortement de changer votre mot de passe lors de votre première connexion.
        </div>
        
        <div style="text-align: center;">
            <a href="$loginUrl" class="button">🚀 Se connecter maintenant</a>
        </div>
        
        <div class="info-box">
            <h3>📚 Prochaines étapes :</h3>
            <ol>
                <li>Cliquez sur le bouton ci-dessus pour accéder à la plateforme</li>
                <li>Connectez-vous avec vos identifiants</li>
                <li>Changez votre mot de passe temporaire</li>
                <li>Explorez les fonctionnalités selon votre rôle</li>
                <li>Contactez le support si vous avez des questions</li>
            </ol>
        </div>
        
        <p>Si vous rencontrez des difficultés, n'hésitez pas à nous contacter à l'adresse : <a href="mailto:support@apisavana.com">support@apisavana.com</a></p>
        
        <p>Bonne utilisation de la plateforme !</p>
        
        <p><strong>L'équipe ApiSavana Gestion</strong></p>
    </div>
    
    <div class="footer">
        <p>© 2025 ApiSavana Gestion - Système de gestion des collectes de miel</p>
        <p>Cet email a été envoyé automatiquement, merci de ne pas y répondre.</p>
    </div>
</body>
</html>
    ''';
  }

  /// Méthode alternative utilisant un service SMTP local (pour développement)
  Future<bool> sendWelcomeEmailLocal({
    required String userEmail,
    required String userName,
    required String userRole,
    required String userSite,
    required String temporaryPassword,
  }) async {
    try {
      // Simuler l'envoi d'email en développement
      if (kDebugMode) {
        print('🎉 EMAIL DE BIENVENUE SIMULÉ 🎉');
        print('====================================');
        print('À: $userEmail');
        print('Nom: $userName');
        print('Rôle: $userRole');
        print('Site: $userSite');
        print('Mot de passe temporaire: $temporaryPassword');
        print('====================================');
        print('✅ Email envoyé avec succès !');

        // Afficher une notification à l'utilisateur administrateur
        Get.snackbar(
          '📧 Email envoyé',
          'Email de bienvenue envoyé à $userName ($userEmail)',
          backgroundColor: const Color(0xFF4CAF50),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.TOP,
        );

        return true;
      }

      // En production, utiliser un vrai service d'email
      return await sendWelcomeEmail(
        userEmail: userEmail,
        userName: userName,
        userRole: userRole,
        userSite: userSite,
        temporaryPassword: temporaryPassword,
      );
    } catch (e) {
      print('❌ Erreur lors de l\'envoi de l\'email local: $e');
      return false;
    }
  }

  /// Envoyer un email de vérification personnalisé
  Future<bool> sendCustomVerificationEmail({
    required String userEmail,
    required String userName,
  }) async {
    try {
      // Générer un lien de vérification (en pratique, vous devriez générer un token unique)
      final verificationLink =
          'https://votre-app.com/verify-email?email=${Uri.encodeComponent(userEmail)}';

      final Map<String, dynamic> templateParams = {
        'to_email': userEmail,
        'to_name': userName,
        'verification_link': verificationLink,
        'company_name': 'ApiSavana Gestion',
        'support_email': 'support@apisavana.com',
      };

      // Template spécifique pour la vérification d'email
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': _serviceId,
          'template_id': 'email_verification_template', // Template spécifique
          'user_id': _publicKey,
          'accessToken': _privateKey,
          'template_params': templateParams,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Email de vérification personnalisé envoyé avec succès');
        return true;
      } else {
        print(
            '❌ Erreur lors de l\'envoi de l\'email de vérification: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Exception lors de l\'envoi de l\'email de vérification: $e');
      return false;
    }
  }

  /// Version locale pour le développement de l'email de vérification
  Future<bool> sendCustomVerificationEmailLocal({
    required String userEmail,
    required String userName,
  }) async {
    try {
      if (kDebugMode) {
        print('📧 EMAIL DE VÉRIFICATION PERSONNALISÉ 📧');
        print('==========================================');
        print('À: $userEmail');
        print('Nom: $userName');
        print(
            'Lien de vérification: https://votre-app.com/verify-email?email=${Uri.encodeComponent(userEmail)}');
        print('==========================================');
        print('✅ Email de vérification envoyé !');

        Get.snackbar(
          '📧 Email envoyé',
          'Email de vérification renvoyé à $userName',
          backgroundColor: const Color(0xFF2196F3),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.TOP,
        );

        return true;
      }

      return await sendCustomVerificationEmail(
        userEmail: userEmail,
        userName: userName,
      );
    } catch (e) {
      print('❌ Erreur lors de l\'envoi local de l\'email de vérification: $e');
      return false;
    }
  }

  /// Générer le HTML pour l'email de vérification personnalisé
  // ignore: unused_element
  String _generateVerificationEmailHTML({
    required String userName,
    required String userEmail,
    required String verificationLink,
  }) {
    return '''
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Vérifiez votre adresse email - ApiSavana</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background-color: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #F49101 0%, #FF6B35 100%); color: white; padding: 30px; text-align: center; }
        .header h1 { margin: 0; font-size: 28px; }
        .content { padding: 40px 30px; }
        .verification-box { background-color: #FFF8F0; border: 2px solid #F49101; border-radius: 8px; padding: 20px; margin: 20px 0; text-align: center; }
        .verify-button { display: inline-block; background: linear-gradient(135deg, #F49101 0%, #FF6B35 100%); color: white; text-decoration: none; padding: 15px 30px; border-radius: 8px; font-weight: bold; font-size: 16px; margin: 20px 0; }
        .verify-button:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(244, 145, 1, 0.3); }
        .footer { background-color: #f8f9fa; padding: 20px; text-align: center; color: #666; font-size: 12px; }
        .warning { background-color: #FFF3CD; border: 1px solid #FFEAA7; border-radius: 6px; padding: 15px; margin: 20px 0; color: #856404; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🍯 Vérification d'Email</h1>
            <p>ApiSavana Gestion</p>
        </div>
        
        <div class="content">
            <h2>Bonjour $userName,</h2>
            
            <p>Nous avons besoin de vérifier votre adresse email pour activer votre accès à la plateforme ApiSavana Gestion.</p>
            
            <div class="verification-box">
                <h3>📧 Vérifiez votre email</h3>
                <p>Cliquez sur le bouton ci-dessous pour confirmer votre adresse email :</p>
                <p><strong>$userEmail</strong></p>
                
                <a href="$verificationLink" class="verify-button">
                    ✅ Vérifier mon email
                </a>
            </div>
            
            <div class="warning">
                <strong>⚠️ Important :</strong>
                <ul style="margin: 10px 0; padding-left: 20px;">
                    <li>Ce lien est valide pendant 24 heures</li>
                    <li>Après vérification, vous pourrez accéder à toutes les fonctionnalités</li>
                    <li>Si vous n'avez pas demandé cette vérification, ignorez cet email</li>
                </ul>
            </div>
            
            <p>Si le bouton ne fonctionne pas, copiez et collez ce lien dans votre navigateur :</p>
            <p style="word-break: break-all; background-color: #f8f9fa; padding: 10px; border-radius: 4px; font-family: monospace; font-size: 12px;">
                $verificationLink
            </p>
            
            <p>Besoin d'aide ? Contactez notre support à <a href="mailto:support@apisavana.com">support@apisavana.com</a></p>
            
            <p><strong>L'équipe ApiSavana Gestion</strong></p>
        </div>
        
        <div class="footer">
            <p>© 2025 ApiSavana Gestion - Système de gestion des collectes de miel</p>
            <p>Cet email a été envoyé automatiquement, merci de ne pas y répondre.</p>
        </div>
    </div>
</body>
</html>
    ''';
  }

  /// Envoyer (ou simuler) une notification simple à un utilisateur.
  Future<bool> sendUserNotificationEmail({
    required String userEmail,
    required String userName,
    required String subject,
    required String message,
  }) async {
    try {
      if (kDebugMode) {
        print('📨 NOTIFICATION UTILISATEUR');
        print('==============================');
        print('À: $userEmail');
        print('Utilisateur: $userName');
        print('Sujet: $subject');
        print('Message: $message');
        print('==============================');
        return true;
      }

      final Map<String, dynamic> templateParams = {
        'to_email': userEmail,
        'to_name': userName,
        'subject': subject,
        'message': message,
        'company_name': 'ApiSavana Gestion',
        'support_email': 'support@apisavana.com',
      };

      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': _serviceId,
          'template_id': 'user_notification_template',
          'user_id': _publicKey,
          'accessToken': _privateKey,
          'template_params': templateParams,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      }

      if (kDebugMode) {
        print('❌ Échec envoi notification email: ${response.statusCode}');
        print('Body: ${response.body}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Exception notification email: $e');
      }
      return false;
    }
  }
}
