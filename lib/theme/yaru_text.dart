import 'package:flutter/material.dart';

/// YaruNavi デザイントークン: TextStyle
///
/// iOSはHiragino Sans、AndroidはNoto Sans CJK（システム既定）にフォールバック。
/// `fontFamily`は指定せずシステム最適化に任せ、weight/size/letter-spacing に注力。
/// 数値部分は [FontFeature.tabularFigures] を必ず付与。
class YaruText {
  YaruText._();

  static const _tabular = <FontFeature>[FontFeature.tabularFigures()];

  // ============ Display ============

  /// 日付・大見出し（例: ホームの "5月11日"）
  static const displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.05,
    letterSpacing: -0.6,
    fontFeatures: _tabular,
  );

  static const display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.3,
  );

  // ============ Title ============

  static const titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.3,
  );

  static const title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    height: 1.3,
  );

  // ============ Card / Section ============

  static const cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );

  static const sectionLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    height: 1.3,
    letterSpacing: 0.4,
  );

  // ============ Body ============

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.55,
  );

  static const bodyStrong = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.55,
  );

  // ============ Meta / Label ============

  static const label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const meta = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  /// 大文字キャプション ("TODAY" "NOW" 等)
  static const cap = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: 1.32, // 0.12em
  );

  // ============ 数字 (tabular figures) ============

  static const num16 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    height: 1.0,
    fontFeatures: _tabular,
  );

  static const num20 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.0,
    fontFeatures: _tabular,
  );

  static const num28 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.0,
    fontFeatures: _tabular,
    letterSpacing: -0.3,
  );

  static const num36 = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.0,
    fontFeatures: _tabular,
    letterSpacing: -0.7,
  );

  static const num56 = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w800,
    height: 0.95,
    fontFeatures: _tabular,
    letterSpacing: -2.2,
  );

  static const num64 = TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.w800,
    height: 1.0,
    fontFeatures: _tabular,
    letterSpacing: -2.6,
  );

  static const num72 = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.w800,
    height: 1.0,
    fontFeatures: _tabular,
    letterSpacing: -2.9,
  );
}
