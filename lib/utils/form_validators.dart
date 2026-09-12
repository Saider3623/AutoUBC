String? validateRequiredText(
  String? value, {
  required String message,
}) {
  return value == null || value.trim().isEmpty ? message : null;
}

String? validateWholeNumber(
  String? value, {
  required String requiredMessage,
  required String invalidMessage,
  required String nonNegativeMessage,
}) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return requiredMessage;

  final parsed = int.tryParse(trimmed);
  if (parsed == null) return invalidMessage;
  if (parsed < 0) return nonNegativeMessage;
  return null;
}

String normalizeDecimalInput(String value) {
  return value.replaceAll(',', '.');
}

String? validateNonNegativeDecimal(
  String? value, {
  required String requiredMessage,
  required String invalidMessage,
  required String nonNegativeMessage,
}) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return requiredMessage;

  final parsed = double.tryParse(normalizeDecimalInput(trimmed));
  if (parsed == null || !parsed.isFinite) return invalidMessage;
  if (parsed < 0) return nonNegativeMessage;
  return null;
}
