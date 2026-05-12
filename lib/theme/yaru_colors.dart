import 'package:flutter/material.dart';

/// YaruNavi デザイントークン: カラー
///
/// ライト = v1 Electric Blue / ダーク = v2 Midnight Neon の両パレットを保持。
/// テーマ依存の選択は [YaruTheme] (ThemeExtension) 側で行う。
class YaruColors {
  YaruColors._();

  // ============ v1 Light: Ink scale ============
  static const inkLight950 = Color(0xFF050C20);
  static const inkLight900 = Color(0xFF0B1736);
  static const inkLight800 = Color(0xFF182547);
  static const inkLight700 = Color(0xFF2A3A66);
  static const inkLight600 = Color(0xFF44558A);
  static const inkLight500 = Color(0xFF5F6F95);
  static const inkLight400 = Color(0xFF8693B4);
  static const inkLight300 = Color(0xFFB6C0D6);
  static const inkLight200 = Color(0xFFD9DFEB);
  static const inkLight100 = Color(0xFFECEFF6);

  // ============ v1 Light: Surfaces ============
  static const lineLight = Color(0xFFE5E9F2);
  static const lineLightSoft = Color(0xFFEEF1F7);
  static const bgLight = Color(0xFFF4F6FB);
  static const bgLightCool = Color(0xFFEDF0F8);
  static const paperLight = Color(0xFFFFFFFF);

  // ============ v1 Primary: Electric Blue ============
  static const primary = Color(0xFF2453FF);
  static const primaryDeep = Color(0xFF1738C4);
  static const primaryDark = Color(0xFF0A1F7A);
  static const primaryBright = Color(0xFF4F7BFF);
  static const primarySoft = Color(0xFFEEF2FF);
  static const primaryTint = Color(0xFFDDE5FF);
  static const primaryMid = Color(0xFFB7C7FF);

  // AI / Sparkle accent (v1)
  static const sparkle = Color(0xFF7C5CFF);
  static const sparkleSoft = Color(0xFFEFEBFF);

  // ============ v2 Dark: Backgrounds ============
  static const bgDark0 = Color(0xFF050610);
  static const bgDark1 = Color(0xFF0B0E1F);
  static const bgDark2 = Color(0xFF131734);

  // ============ v2 Dark: Ink scale ============
  static const inkDark1 = Color(0xFFF2F4FF);
  static const inkDark2 = Color(0xFFB6BDDB);
  static const inkDark3 = Color(0xFF8088B0);
  static const inkDark4 = Color(0xFF545B82);

  // ============ v2 Neon accents ============
  static const cyan = Color(0xFF4DF5FF);
  static const indigo = Color(0xFF5B7BFF);
  static const magenta = Color(0xFFFF4DDB);
  static const amber = Color(0xFFFFB84D);
  static const lime = Color(0xFFB6FF4D);

  // Dark strokes (alpha-overlaid white)
  static const lineDark = Color(0x14FFFFFF); // 8%
  static const lineDarkStrong = Color(0x29FFFFFF); // 16%

  // ============ 優先度セマンティクス (共有) ============
  // Light (v1) hue
  static const urgent = Color(0xFFFF3B30);
  static const urgentDeep = Color(0xFFC71F16);
  static const urgentSoft = Color(0xFFFFEDEC);
  static const soon = Color(0xFFFF8A00);
  static const soonDeep = Color(0xFFC45F00);
  static const soonSoft = Color(0xFFFFF2E2);
  static const done = Color(0xFF10B981);
  static const doneSoft = Color(0xFFE6FAF3);
  static const flame = Color(0xFFFF6B35);

  // Dark (v2) neon counterparts
  static const urgentNeon = Color(0xFFFF5577);
  static const soonNeon = Color(0xFFFFB84D); // = amber
  static const laterNeon = Color(0xFF4DF5FF); // = cyan
  static const calmNeon = Color(0xFF8088B0); // = inkDark3

  // ============ Premium gold ============
  static const goldLight = Color(0xFFFFE56A);
  static const goldDeep = Color(0xFFFFB050);

  // ============ Tone helper for TaskCard ============
  /// 優先度に基づいたトーン色（テキスト/バー用、ライト/ダーク自動切替）
  ///
  /// priority: 1=urgent, 2=warning, 3=normal, 4=relaxed
  /// 0の場合は dueDate からの自動判定。
  static Color getPriorityColor(int priority, DateTime dueDate,
      {bool isDark = false}) {
    if (priority > 0) {
      return switch (priority) {
        1 => isDark ? urgentNeon : urgent,
        2 => isDark ? soonNeon : soonDeep,
        3 => isDark ? laterNeon : primary,
        4 => isDark ? calmNeon : inkLight500,
        _ => isDark ? laterNeon : primary,
      };
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = due.difference(today).inDays;
    if (diff <= 0) return isDark ? urgentNeon : urgent;
    if (diff <= 3) return isDark ? soonNeon : soonDeep;
    if (diff < 7) return isDark ? laterNeon : primary;
    return isDark ? calmNeon : inkLight500;
  }
}
