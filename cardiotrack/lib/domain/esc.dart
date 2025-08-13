import 'package:flutter/material.dart';

enum EscCategory { normal, highNormal, hypertension }

class EscClassification {
  static EscCategory classify({required int systolic, required int diastolic}) {
    if (systolic >= 140 || diastolic >= 90) {
      return EscCategory.hypertension;
    }
    if ((systolic >= 130 && systolic <= 139) || (diastolic >= 85 && diastolic <= 89)) {
      return EscCategory.highNormal;
    }
    return EscCategory.normal;
  }

  static String label(EscCategory c) {
    switch (c) {
      case EscCategory.normal:
        return 'Normal';
      case EscCategory.highNormal:
        return 'Normal élevé';
      case EscCategory.hypertension:
        return 'Hypertension';
    }
  }

  static Color color(EscCategory c) {
    switch (c) {
      case EscCategory.normal:
        return const Color(0xFF10B981); // green
      case EscCategory.highNormal:
        return const Color(0xFFF59E0B); // amber
      case EscCategory.hypertension:
        return const Color(0xFFEF4444); // red
    }
  }
}