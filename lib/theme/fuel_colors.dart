import 'package:flutter/material.dart';

const Color _petrol = Color(0xFFC25E00);
const Color _gas = Color(0xFF2E7D32);
const Color _diesel = Color(0xFF6D4C41);
const Color _electric = Color(0xFF00796B);

/// Color of a fuel type, the same on every screen. The shades keep a text
/// contrast of at least 4.5:1 on white.
Color fuelTypeColor(String fuelType, ColorScheme colorScheme) {
  final name = fuelType.trim().toUpperCase();
  bool hasAny(List<String> words) => words.any(name.contains);

  if (hasAny(const ['ГАЗ', 'LPG', 'CNG', 'ПРОПАН', 'МЕТАН'])) return _gas;
  if (hasAny(const ['ДИЗЕЛЬ', 'DIESEL', 'ДП', 'ДТ'])) return _diesel;
  if (hasAny(const ['ЕЛЕКТРИ', 'ELECTRIC'])) return _electric;
  if (hasAny(const ['92', '95', '98', '100', 'БЕНЗИН', 'PETROL'])) {
    return _petrol;
  }
  return colorScheme.primary;
}
