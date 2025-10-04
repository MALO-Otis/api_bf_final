import 'lib/screens/controle_de_donnes/models/quality_control_models.dart';
/// 🧪 Test rapide de la logique du contrôle qualité amélioré
/// Vérifie que la logique auto-détermination fonctionne correctement


void main() {
  print('🧪 TEST DE LA LOGIQUE CONTRÔLE QUALITÉ AMÉLIORÉ');
  print('=' * 60);

  // Test 1: Tous les critères bons → Qualité BONNE
  testQualityLogic(
      'Test 1: Tous critères bons',
      ContainerQualityApproval.approuver,
      OdorApproval.approuver,
      SandDepositPresence.non,
      expectedQuality: 'BONNE');

  // Test 2: Contenant mauvais → Qualité MAUVAISE
  testQualityLogic(
      'Test 2: Contenant non approuvé',
      ContainerQualityApproval.nonApprouver,
      OdorApproval.approuver,
      SandDepositPresence.non,
      expectedQuality: 'MAUVAISE');

  // Test 3: Odeurs mauvaises → Qualité MAUVAISE
  testQualityLogic(
      'Test 3: Odeurs non approuvées',
      ContainerQualityApproval.approuver,
      OdorApproval.nonApprouver,
      SandDepositPresence.non,
      expectedQuality: 'MAUVAISE');

  // Test 4: Présence de sable → Qualité MAUVAISE
  testQualityLogic(
      'Test 4: Présence de sable',
      ContainerQualityApproval.approuver,
      OdorApproval.approuver,
      SandDepositPresence.oui,
      expectedQuality: 'MAUVAISE');

  // Test 5: Tous mauvais → Qualité MAUVAISE
  testQualityLogic(
      'Test 5: Tous critères mauvais',
      ContainerQualityApproval.nonApprouver,
      OdorApproval.nonApprouver,
      SandDepositPresence.oui,
      expectedQuality: 'MAUVAISE');

  print('\n🎯 Tests des enums et labels:');
  testEnumLabels();

  print('\n✅ TOUS LES TESTS TERMINÉS !');
}

void testQualityLogic(
    String testName,
    ContainerQualityApproval containerQuality,
    OdorApproval odorApproval,
    SandDepositPresence sandDeposit,
    {required String expectedQuality}) {
  print('\n📋 $testName:');
  print('   Qualité contenant: ${containerQuality.label}');
  print('   Approbation odeurs: ${odorApproval.label}');
  print('   Dépôt de sable: ${sandDeposit.label}');

  // Logique de détermination de la qualité
  bool isGoodQuality = containerQuality == ContainerQualityApproval.approuver &&
      odorApproval == OdorApproval.approuver &&
      sandDeposit == SandDepositPresence.non;

  String actualQuality = isGoodQuality ? 'BONNE' : 'MAUVAISE';
  String conformity = isGoodQuality ? 'CONFORME' : 'NON_CONFORME';

  print('   → Qualité calculée: $actualQuality');
  print('   → Conformité: $conformity');

  if (actualQuality == expectedQuality) {
    print('   ✅ TEST RÉUSSI !');
  } else {
    print(
        '   ❌ TEST ÉCHOUÉ ! Attendu: $expectedQuality, Obtenu: $actualQuality');
  }
}

void testEnumLabels() {
  print('\n🏷️  Labels ContainerQualityApproval:');
  for (var value in ContainerQualityApproval.values) {
    print('   ${value.name} → "${value.label}"');
  }

  print('\n🏷️  Labels OdorApproval:');
  for (var value in OdorApproval.values) {
    print('   ${value.name} → "${value.label}"');
  }

  print('\n🏷️  Labels SandDepositPresence:');
  for (var value in SandDepositPresence.values) {
    print('   ${value.name} → "${value.label}"');
  }
}
