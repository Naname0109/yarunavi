import 'package:flutter/material.dart';

import 'yaru_colors.dart';
import 'yaru_theme.dart';

/// アプリ全体のテーマ。
///
/// ライト = v1 Electric Blue、ダーク = v2 Midnight Neon。
/// 各画面/ウィジェットからは `Theme.of(context).extension<YaruTheme>()!`
/// (または `context.yaru`) でデザイントークンを引く。
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final yaru = isDark ? YaruTheme.dark : YaruTheme.light;

    // ColorScheme: 主要色をブランドにピン留め。fromSeed の自然な階調を活かしつつ
    // primary/onPrimary/surface 等を上書きする。
    final base = ColorScheme.fromSeed(
      seedColor: yaru.accent,
      brightness: brightness,
    );
    final scheme = base.copyWith(
      primary: yaru.accent,
      onPrimary: isDark ? YaruColors.bgDark0 : Colors.white,
      secondary: yaru.sparkle,
      onSecondary: Colors.white,
      surface: yaru.paper,
      onSurface: yaru.inkPrimary,
      surfaceContainerHighest: yaru.paperEmph,
      onSurfaceVariant: yaru.inkSecondary,
      outline: yaru.line,
      outlineVariant: yaru.lineStrong,
      error: yaru.urgent,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: yaru.scaffoldBg,
      extensions: <ThemeExtension<dynamic>>[yaru],

      appBarTheme: AppBarTheme(
        backgroundColor: yaru.scaffoldBg,
        foregroundColor: yaru.inkPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: yaru.inkPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),

      cardTheme: CardThemeData(
        color: yaru.paper,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: yaru.line, width: 1),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: yaru.accent,
        foregroundColor: isDark ? YaruColors.bgDark0 : Colors.white,
        elevation: 0,
        shape: const CircleBorder(),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: yaru.paper,
        selectedColor: yaru.accent.withValues(alpha: 0.12),
        labelStyle: TextStyle(color: yaru.inkSecondary),
        side: BorderSide(color: yaru.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: yaru.line,
        space: 1,
        thickness: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: yaru.paper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: yaru.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: yaru.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: yaru.accent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: yaru.accent,
          foregroundColor: isDark ? YaruColors.bgDark0 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          minimumSize: const Size(0, 48),
          textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: yaru.accent,
          side: BorderSide(color: yaru.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          minimumSize: const Size(0, 48),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: yaru.accent,
          textStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: yaru.paper,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        modalBackgroundColor: yaru.paper,
        modalElevation: 0,
      ),

      iconTheme: IconThemeData(color: yaru.inkSecondary),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: yaru.accent,
      ),
    );
  }
}
