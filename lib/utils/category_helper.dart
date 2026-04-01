import '../l10n/generated/app_localizations.dart';

/// デフォルトカテゴリのi18nキーからローカライズ名に変換する。
/// ユーザー作成カテゴリはそのまま返す。
String getCategoryDisplayName(String name, AppLocalizations l10n) {
  switch (name) {
    case 'categoryPayment':
      return l10n.categoryPayment;
    case 'categoryPaperwork':
      return l10n.categoryPaperwork;
    case 'categoryShopping':
      return l10n.categoryShopping;
    case 'categoryHousehold':
      return l10n.categoryHousehold;
    case 'categoryWork':
      return l10n.categoryWork;
    case 'categoryOther':
      return l10n.categoryOther;
    default:
      return name;
  }
}
