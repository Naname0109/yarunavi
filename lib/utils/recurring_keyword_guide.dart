import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/generated/app_localizations.dart';

/// 「振込」「家賃」「引き落とし」などの月次キーワードが
/// 含まれるタスクが新規入力されたら、定期タスク化を促すガイドを表示する。
class RecurringKeywordGuide {
  RecurringKeywordGuide._();

  /// SharedPreferencesに既表示キーワードを保存するキー
  static const _shownKeywordsKey = 'recurring_guide_shown_keywords';

  /// マッチするキーワード（部分一致で判定）
  /// 「支払」「保険」のような単漢字は誤検知が多いので、
  /// 送り仮名や複合語を含む形だけ採用する。
  static const List<String> keywords = [
    // 支払い・引き落とし系
    '振込', '振り込み', 'ふりこみ',
    '引き落とし', '引落', 'ひきおとし',
    '支払い', 'しはらい',
    '家賃', 'やちん',
    '給料日', '給与', 'きゅうりょう',
    '光熱費', '電気代', 'ガス代', '水道代',
    '携帯代', 'スマホ代', '通信費',
    '保険料', '保険金',
    '住宅ローン', 'カードローン', 'ローン返済',
    '月謝', '会費',
    'サブスク',
  ];

  /// タスク名から最初にマッチするキーワードを返す（なければnull）
  static String? matchKeyword(String title) {
    for (final kw in keywords) {
      if (title.contains(kw)) return kw;
    }
    return null;
  }

  /// 表示済みキーワードを取得
  static Future<Set<String>> getShownKeywords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_shownKeywordsKey);
    if (raw == null) return <String>{};
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  /// 表示済みキーワードを記録
  static Future<void> markShown(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    final shown = await getShownKeywords();
    shown.add(keyword);
    await prefs.setString(_shownKeywordsKey, jsonEncode(shown.toList()));
  }

  /// ガイドを表示するべきか判定 (タスク名、定期設定なし、未表示)
  ///
  /// 既に定期タスク (recurrenceType != null) ならスキップ。
  static Future<String?> shouldShow({
    required String title,
    required String? recurrenceType,
  }) async {
    if (recurrenceType != null) return null;
    final keyword = matchKeyword(title);
    if (keyword == null) return null;
    final shown = await getShownKeywords();
    if (shown.contains(keyword)) return null;
    return keyword;
  }

  /// ガイドのボトムシートを表示。ユーザーが「定期タスクに設定する」を
  /// 選んだら true を返す。閉じた/「今回だけ」なら false。
  /// どちらの場合も表示済みフラグを記録する。
  static Future<bool> show({
    required BuildContext context,
    required String keyword,
    required String taskTitle,
    required AppLocalizations l10n,
  }) async {
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _RecurringGuideSheet(
        taskTitle: taskTitle,
        l10n: l10n,
      ),
    );
    // 結果に関わらず、同じキーワードでは2度と表示しない
    await markShown(keyword);
    return accepted == true;
  }
}

class _RecurringGuideSheet extends StatelessWidget {
  const _RecurringGuideSheet({
    required this.taskTitle,
    required this.l10n,
  });

  final String taskTitle;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 22, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.recurringGuideTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.recurringGuideMessage(taskTitle),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.recurringGuideDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l10n.recurringGuideAccept),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.recurringGuideDecline),
            ),
          ],
        ),
      ),
    );
  }
}
