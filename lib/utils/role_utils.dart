import 'dart:collection';

List<String> extractNormalizedRoles(dynamic roleField) {
  if (roleField == null) {
    return <String>[];
  }

  List<String> rawRoles;
  if (roleField is String) {
    rawRoles = [roleField];
  } else if (roleField is Iterable) {
    rawRoles = roleField.whereType<String>().toList();
  } else {
    return <String>[];
  }

  final seen = HashSet<String>();
  final roles = <String>[];
  for (final raw in rawRoles) {
    final normalized = _normalizeRoleLabel(raw);
    if (normalized.isEmpty) {
      continue;
    }
    if (seen.add(normalized)) {
      roles.add(normalized);
    }
  }
  return roles;
}

String? primaryRoleFrom(dynamic roleField) {
  final roles = extractNormalizedRoles(roleField);
  if (roles.isEmpty) {
    return null;
  }
  return roles.first;
}

String _normalizeRoleLabel(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  if (trimmed.length == 1) {
    return trimmed.toUpperCase();
  }
  final first = trimmed[0].toUpperCase();
  final rest = trimmed.substring(1);
  return '$first$rest';
}
