import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Light Theme
  static const primaryLight = Color(0xFF2563EB);
  static const secondaryLight = Color(0xFFF59E0B);
  static const backgroundLight = Color(0xFFF8FAFC);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const textPrimaryLight = Color(0xDE000000); // rgba(0,0,0,0.87)
  static const textSecondaryLight = Color(0x99000000); // rgba(0,0,0,0.60)

  // Dark Theme
  static const primaryDark = Color(0xFF60A5FA);
  static const secondaryDark = Color(0xFFFBBF24);
  static const backgroundDark = Color(0xFF121212);
  static const surfaceDark = Color(0xFF1E1E1E);
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xB3FFFFFF); // rgba(255,255,255,0.70)

  // Priority Colors
  static const priorityUrgent = Color(0xFFDC2626);
  static const priorityWarning = Color(0xFFF97316);
  static const priorityNormal = Color(0xFF2563EB);
  static const priorityRelaxed = Color(0xFF9CA3AF);
  // ダークテーマ用: コントラスト比 4.5:1以上を確保
  static const priorityNormalDark = Color(0xFF93C5FD);
  static const priorityRelaxedDark = Color(0xFFD1D5DB);

  /// 優先度に基づく色を返す
  /// priority > 0: AI設定値（1=緊急, 2=要注意, 3=通常, 4=余裕）
  /// priority == 0: 期限日ベースで自動判定
  static Color getPriorityColor(int priority, DateTime dueDate) {
    if (priority > 0) {
      switch (priority) {
        case 1:
          return priorityUrgent;
        case 2:
          return priorityWarning;
        case 3:
          return priorityNormal;
        case 4:
          return priorityRelaxed;
        default:
          return priorityNormal;
      }
    }

    // 期限日ベースの自動判定
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = due.difference(today).inDays;

    if (diff <= 0) return priorityUrgent;
    if (diff <= 3) return priorityWarning;
    if (diff < 7) return priorityNormal;
    return priorityRelaxed;
  }
}
