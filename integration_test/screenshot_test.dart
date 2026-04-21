import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'package:yarunavi/app.dart';
import 'package:yarunavi/models/task.dart';
import 'package:yarunavi/providers/dev_mode_provider.dart';
import 'package:yarunavi/providers/settings_provider.dart';
import 'package:yarunavi/providers/task_provider.dart';
import 'package:yarunavi/services/ai_service.dart';
import 'package:yarunavi/services/database_service.dart';
import 'package:yarunavi/services/notification_service.dart';
import 'package:yarunavi/services/purchase_service.dart';
import 'package:yarunavi/services/calendar_service.dart';
import 'package:yarunavi/services/secure_storage_service.dart';
import 'package:yarunavi/providers/purchase_provider.dart';
import 'package:yarunavi/providers/secure_storage_provider.dart';
import 'package:yarunavi/widgets/ai_sort_button.dart';

/// カレンダー権限ダイアログを抑制するモック
class _NoOpCalendarService extends CalendarService {
  @override
  Future<bool> requestPermission() async => false;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// シミュレータ実画面をキャプチャ
  Future<void> screenshot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(milliseconds: 800));
    await binding.takeScreenshot(name);
    debugPrint('[SCREENSHOT] $name captured');
  }

  testWidgets('App Store screenshots - all in one', (tester) async {
    // レイアウト警告を抑制
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exceptionAsString();
      if (msg.contains('ParentData') || msg.contains('overflowed')) return;
      originalOnError?.call(details);
    };

    // --- 初期化 ---
    SharedPreferences.setMockInitialValues({});
    final db = DatabaseService();
    await db.initialize();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(NotificationService()),
        calendarServiceProvider.overrideWithValue(_NoOpCalendarService()),
        purchaseServiceProvider.overrideWithValue(PurchaseService.instance),
        secureStorageServiceProvider
            .overrideWithValue(SecureStorageService()),
        initialLocaleProvider.overrideWithValue(const Locale('ja')),
        initialThemeModeProvider.overrideWithValue(ThemeMode.light),
        initialDevAiUnlimitedProvider.overrideWithValue(true),
        initialDevPremiumProvider.overrideWithValue(true),
      ],
      child: const YaruNaviApp(),
    ));

    // スプラッシュ → オンボーディング遷移待ち
    await tester.pumpAndSettle(const Duration(seconds: 5));
    debugPrint('[TEST] Post-splash');

    // ===== Screenshot 1: オンボーディング画面2 =====
    final nextBtn = find.text('次へ');
    expect(nextBtn, findsWidgets, reason: 'オンボーディングが表示されていません');
    await tester.tap(nextBtn.first);
    await tester.pumpAndSettle();
    debugPrint('[TEST] On onboarding page 2');

    await screenshot(tester, 'raw_05_onboarding');

    // ===== オンボーディング完了 → ホームへ =====
    // 「スキップ」ボタンをタップ
    final skipBtn = find.text('スキップ');
    expect(skipBtn, findsOneWidget, reason: 'スキップボタンが見つかりません');
    await tester.tap(skipBtn);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    debugPrint('[TEST] Skipped onboarding');

    // コーチマークが表示されたら閉じる
    for (var i = 0; i < 5; i++) {
      if (find.text('次へ').evaluate().isNotEmpty) {
        await tester.tap(find.text('次へ').first);
        await tester.pumpAndSettle();
      } else if (find.text('OK').evaluate().isNotEmpty) {
        await tester.tap(find.text('OK').first);
        await tester.pumpAndSettle();
      } else if (find.text('閉じる').evaluate().isNotEmpty) {
        await tester.tap(find.text('閉じる').first);
        await tester.pumpAndSettle();
      } else {
        break;
      }
    }
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // ホーム画面の確認
    expect(find.text('やること'), findsWidgets,
        reason: 'ホーム画面が表示されていません');
    debugPrint('[TEST] Home screen visible');

    // --- テストデータ投入 ---
    final aiResponse = await _insertScreenshotData(db);
    final ctx0 = tester.element(find.byType(Scaffold).first);
    final container = ProviderScope.containerOf(ctx0);
    container.read(aiSortResponseProvider.notifier).state = aiResponse;
    container.invalidate(tasksProvider);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // ===== Screenshot 2: ホーム画面 =====
    debugPrint('[TEST] === Home ===');
    await screenshot(tester, 'raw_01_home');

    // ===== Screenshot 3: AI整理結果 =====
    debugPrint('[TEST] === AI Result ===');
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .push('/ai-result');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await screenshot(tester, 'raw_02_ai_result');

    // 戻る
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/home');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // ===== Screenshot 4: カレンダー画面 =====
    debugPrint('[TEST] === Calendar ===');
    // 表示されているダイアログを閉じる
    final okBtn = find.text('OK');
    if (okBtn.evaluate().isNotEmpty) {
      await tester.tap(okBtn.first);
      await tester.pumpAndSettle();
    }

    final calTab = find.text('カレンダー');
    expect(calTab, findsWidgets, reason: 'カレンダータブが見つかりません');
    await tester.tap(calTab.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // カレンダー遷移後もダイアログが出る場合
    final okBtn2 = find.text('OK');
    if (okBtn2.evaluate().isNotEmpty) {
      await tester.tap(okBtn2.first);
      await tester.pumpAndSettle();
    }

    await screenshot(tester, 'raw_03_calendar');

    // ===== Screenshot 5: タスクカード展開 (AIコメント) =====
    debugPrint('[TEST] === Task expanded ===');
    final todoTab = find.text('やること');
    await tester.tap(todoTab.first);
    await tester.pumpAndSettle();

    final card = find.textContaining('家賃振込');
    if (card.evaluate().isNotEmpty) {
      await tester.tap(card.first);
      await tester.pump(const Duration(seconds: 1));
    }
    await screenshot(tester, 'raw_04_ai_comment');

    // ===== Screenshot 6: ストア画面 =====
    debugPrint('[TEST] === Store ===');
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .push('/store');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await screenshot(tester, 'raw_iap');

    // クリーンアップ
    FlutterError.onError = originalOnError;
    await db.close();

    debugPrint('[SCREENSHOT] All 6 iPhone screenshots captured!');
  });
}

/// テストデータ（AI整理済み）投入
Future<AiSortResponse> _insertScreenshotData(DatabaseService db) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final createdAt = now.subtract(const Duration(days: 3));

  final tasksData = [
    (t: '家賃振込', d: 1, c: 1, i: 2, p: 1,
        m: '銀行振込またはネットバンキング', e: '30min',
        ja: '明日が期限です。今日中にネットバンキングで振込を済ませましょう。残高確認も忘れずに。',
        en: 'Due tomorrow. Complete the transfer via online banking today.',
        r: null as String?),
    (t: '企画書作成', d: 2, c: 5, i: 2, p: 1,
        m: '来週の会議用。テンプレートあり', e: 'half_day',
        ja: '来週の会議に間に合わせるために、今日から着手しましょう。',
        en: 'Start today to make the meeting deadline.',
        r: null as String?),
    (t: 'クレジットカード支払い', d: 3, c: 1, i: 2, p: 2,
        m: '引き落とし口座の残高確認', e: '5min',
        ja: '3日後が期限。引き落とし口座の残高を今日中に確認しておくと安心です。',
        en: 'Due in 3 days. Check your account balance today.',
        r: null as String?),
    (t: '日用品買い出し', d: 5, c: 3, i: 1, p: 2,
        m: '洗剤、ティッシュ、シャンプー', e: '1hour',
        ja: '週末の買い物リストを事前にまとめておくとスムーズです。',
        en: 'Prepare your shopping list in advance.',
        r: today.add(const Duration(days: 4)).toIso8601String().substring(0, 10)),
    (t: '週報提出', d: 0, c: 5, i: 1, p: 1,
        m: '毎週提出', e: '30min',
        ja: '今日が提出日です。午前中に済ませて午後の業務に集中しましょう。',
        en: 'Due today. Complete it in the morning.',
        r: null as String?),
    (t: '大掃除', d: 7, c: 4, i: 1, p: 3,
        m: 'キッチン、浴室、リビング', e: 'half_day',
        ja: '週末にまとめて取り組むのがおすすめ。エリアごとに分けると負担が減ります。',
        en: 'Tackle it on the weekend.',
        r: today.add(const Duration(days: 6)).toIso8601String().substring(0, 10)),
    (t: '免許更新', d: 10, c: 2, i: 2, p: 2,
        m: '平日のみ対応可。写真持参', e: 'half_day',
        ja: '平日のみなので、早めにスケジュールを確保しましょう。',
        en: 'Weekdays only — secure a slot early.',
        r: today.add(const Duration(days: 8)).toIso8601String().substring(0, 10)),
    (t: '歯医者予約', d: 8, c: 6, i: 1, p: 3,
        m: '電話予約。平日午前希望', e: '5min',
        ja: '電話1本で完了します。午前中の空き時間にサッと済ませましょう。',
        en: 'Just a quick phone call.',
        r: today.add(const Duration(days: 2)).toIso8601String().substring(0, 10)),
    (t: 'プレゼント選び', d: 14, c: 3, i: 1, p: 3,
        m: '友人の誕生日プレゼント。予算5000円', e: '1hour',
        ja: '2週間あるので余裕がありますが、配送を考えると1週間前には注文を。',
        en: 'Order 1 week ahead considering delivery.',
        r: today.add(const Duration(days: 7)).toIso8601String().substring(0, 10)),
    (t: '確定申告の書類準備', d: 20, c: 2, i: 1, p: 3,
        m: '領収書整理、医療費控除の計算', e: '1day',
        ja: '書類が多いので週末ごとに少しずつ進めるのがおすすめです。',
        en: 'Lots of documents — tackle a bit each weekend.',
        r: today.add(const Duration(days: 13)).toIso8601String().substring(0, 10)),
    (t: 'ジムに行く', d: 4, c: 6, i: 0, p: 4,
        m: null as String?, e: '1hour',
        ja: '体を動かしてリフレッシュしましょう。',
        en: 'Get moving and refresh.',
        r: today.add(const Duration(days: 4)).toIso8601String().substring(0, 10)),
    (t: 'エアコンフィルター掃除', d: 30, c: 4, i: 0, p: 4,
        m: null as String?, e: '30min',
        ja: '期限に余裕があります。他のタスクが落ち着いた時に。',
        en: 'Plenty of time.',
        r: today.add(const Duration(days: 25)).toIso8601String().substring(0, 10)),
  ];

  final aiResults = <AiSortResult>[];
  for (var i = 0; i < tasksData.length; i++) {
    final x = tasksData[i];
    final id = await db.insertTask(Task(
      title: x.t,
      dueDate: today.add(Duration(days: x.d)),
      categoryId: x.c,
      importance: x.i,
      priority: x.p,
      memo: x.m,
      estimatedTime: x.e,
      aiComment: x.ja,
      sortOrder: i,
      recommendedDate: x.r != null ? DateTime.parse(x.r!) : null,
      notifySettings: '["ai_auto"]',
      createdAt: createdAt,
      updatedAt: createdAt,
    ));
    aiResults.add(AiSortResult(
      taskId: id, priority: x.p,
      commentJa: x.ja, commentEn: x.en,
      recommendedDate: x.r,
    ));
  }

  return AiSortResponse(
    summaryJa:
        '合計12件のタスクを分析しました。直近3日以内に期限のタスクが3件あります。'
        '家賃振込と週報提出は今日中に対応が必要です。企画書作成も早めの着手をおすすめします。',
    summaryEn:
        'Analyzed 12 tasks. 3 due within 3 days. '
        'Rent payment and weekly report need attention today.',
    tasks: aiResults,
    questionsJa: [
      '企画書のテンプレートはすでに手元にありますか？',
      '免許更新はお近くの更新センターで行いますか？',
    ],
    questionsEn: [
      'Do you already have the proposal template?',
      'Will you renew your license at a nearby center?',
    ],
  );
}
