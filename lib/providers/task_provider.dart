import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../services/calendar_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/review_service.dart';
import 'gamification_provider.dart';
import 'purchase_provider.dart';

/// DatabaseServiceのProvider（main.dartでoverrideされる）
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('databaseServiceProvider must be overridden');
});

/// NotificationServiceのProvider（main.dartでoverrideされる）
final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('notificationServiceProvider must be overridden');
});

/// CalendarServiceのProvider（main.dartでoverrideされる）
final calendarServiceProvider = Provider<CalendarService>((ref) {
  throw UnimplementedError('calendarServiceProvider must be overridden');
});

/// ReviewServiceのProvider（main.dartでoverrideされる）
final reviewServiceProvider = Provider<ReviewService>((ref) {
  throw UnimplementedError('reviewServiceProvider must be overridden');
});

/// 現在のフィルター状態
final filterProvider = StateProvider<String>((ref) => 'all');

/// タスク一覧Provider (現在のフィルター適用済み)
final tasksProvider =
    AsyncNotifierProvider<TasksNotifier, List<Task>>(TasksNotifier.new);

/// v2 用: 完了済みも含む全タスクProvider。
/// v2 ホーム/カレンダー/実績で、未完了セクション+完了済みセクションの両方を
/// 一つのデータソースから組み立てるために使う。
/// tasksProvider への変更 (invalidate) で連動再取得する。
final allTasksProvider = FutureProvider<List<Task>>((ref) async {
  ref.watch(tasksProvider); // 変更検知
  final db = ref.read(databaseServiceProvider);
  return db.getAllTasks();
});

/// 完了済みタスクの件数（祝福画面の表示判定用）
final completedTaskCountProvider = FutureProvider<int>((ref) async {
  ref.watch(tasksProvider); // tasksProvider更新時に再取得
  final db = ref.read(databaseServiceProvider);
  return db.getCompletedTaskCount();
});

/// 全未完了タスクが期限切れかどうか（バナー表示判定用）
final allTasksOverdueProvider = FutureProvider<bool>((ref) async {
  ref.watch(tasksProvider); // tasksProvider更新時に再取得
  final db = ref.read(databaseServiceProvider);
  return db.areAllTasksOverdue();
});

class TasksNotifier extends AsyncNotifier<List<Task>> {
  DatabaseService get _db => ref.read(databaseServiceProvider);
  NotificationService get _notify => ref.read(notificationServiceProvider);
  CalendarService get _calendar => ref.read(calendarServiceProvider);
  bool get _isPremium => ref.read(isPremiumProvider);

  @override
  Future<List<Task>> build() async {
    final filter = ref.watch(filterProvider);
    return _db.getTasksByFilter(filter);
  }

  /// タスクを追加。戻り値はカレンダー操作の結果（null=カレンダー操作なし）
  Future<CalendarResult?> addTask(
    Task task, {
    bool addToCalendar = false,
  }) async {
    final id = await _db.insertTask(task);
    var savedTask = task.copyWith(id: id);
    CalendarResult? calResult;

    if (addToCalendar && _isPremium) {
      final (result, eventId) = await _calendar.addTaskToCalendar(savedTask);
      calResult = result;
      if (eventId != null) {
        savedTask = savedTask.copyWith(calendarEventId: eventId);
        await _db.updateTask(savedTask);
      }
    }

    await _notify.scheduleTaskNotifications(savedTask, isPremium: _isPremium);
    await _notify.resetAllExpiredFlag();
    // ストリーク維持 (XPは付与しない)
    await ref.read(userStatsProvider.notifier).touchActivity();
    ref.invalidateSelf();
    return calResult;
  }

  /// タスクを更新。戻り値はカレンダー操作の結果（null=カレンダー操作なし）
  Future<CalendarResult?> updateTask(
    Task task, {
    bool addToCalendar = false,
  }) async {
    var updated = task;
    CalendarResult? calResult;

    if (_isPremium) {
      if (addToCalendar) {
        if (task.calendarEventId != null) {
          calResult =
              await _calendar.updateCalendarEvent(task, task.calendarEventId!);
        } else {
          final (result, eventId) = await _calendar.addTaskToCalendar(task);
          calResult = result;
          if (eventId != null) {
            updated = task.copyWith(calendarEventId: eventId);
          }
        }
      } else if (task.calendarEventId != null) {
        calResult =
            await _calendar.deleteCalendarEvent(task.calendarEventId!);
        // calendarEventId を null にリセット
        updated = Task(
          id: task.id,
          title: task.title,
          dueDate: task.dueDate,
          memo: task.memo,
          categoryId: task.categoryId,
          isCompleted: task.isCompleted,
          completedAt: task.completedAt,
          priority: task.priority,
          aiComment: task.aiComment,
          recurrenceType: task.recurrenceType,
          recurrenceValue: task.recurrenceValue,
          recurrenceParentId: task.recurrenceParentId,
          notifySettings: task.notifySettings,
          estimatedTime: task.estimatedTime,
          importance: task.importance,
          createdAt: task.createdAt,
          updatedAt: task.updatedAt,
        );
      }
    }

    await _db.updateTask(updated);
    if (updated.id != null) {
      await _notify.cancelTaskNotifications(updated.id!);
      await _notify.scheduleTaskNotifications(updated, isPremium: _isPremium);
    }
    // 期限更新時に全期限切れ通知フラグをリセット
    await _notify.resetAllExpiredFlag();
    ref.invalidateSelf();
    return calResult;
  }

  Future<void> deleteTask(int id) async {
    final task = await _db.getTaskById(id);
    if (task?.calendarEventId != null) {
      await _calendar.deleteCalendarEvent(task!.calendarEventId!);
    }

    await _notify.cancelTaskNotifications(id);
    await _db.deleteTask(id);
    ref.invalidateSelf();
  }

  Future<void> toggleComplete(Task task) async {
    final justCompleting = !task.isCompleted;
    final now = DateTime.now();
    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? now : null,
      updatedAt: now,
    );
    await _db.updateTask(updated);

    if (task.id != null) {
      if (updated.isCompleted) {
        await _notify.cancelTaskNotifications(task.id!);
      } else {
        await _notify.scheduleTaskNotifications(updated, isPremium: _isPremium);
      }
    }

    if (justCompleting) {
      final remaining = await _db.getActiveTodayTasksBroad();
      final allDone = remaining.isEmpty;
      await ref
          .read(userStatsProvider.notifier)
          .recordTaskCompletion(isAllTodayDone: allDone);
    }

    ref.invalidateSelf();
  }

  /// 完了済みタスクを未完了に戻す。 XP は減算せず、 通知だけ再スケジュール。
  /// 「未完了に戻す」ボタン専用 (toggle ではない)。
  Future<void> uncompleteTask(Task task) async {
    if (!task.isCompleted) return;
    final now = DateTime.now();
    final updated = task.copyWith(
      isCompleted: false,
      completedAt: null,
      updatedAt: now,
    );
    await _db.updateTask(updated);
    if (task.id != null) {
      await _notify.scheduleTaskNotifications(updated, isPremium: _isPremium);
    }
    ref.invalidateSelf();
  }

  /// 完了済みタスクをすべて物理削除 (履歴の一括削除)。 削除件数を返す。
  Future<int> deleteAllCompletedHistory() async {
    final completed =
        (await _db.getAllTasks()).where((t) => t.isCompleted).toList();
    for (final t in completed) {
      if (t.id != null) {
        await _notify.cancelTaskNotifications(t.id!);
      }
    }
    final count = await _db.deleteAllCompletedTasks();
    ref.invalidateSelf();
    return count;
  }

  /// タスクを完了する。定期タスクなら次回タスクを自動生成して返す。
  Future<Task?> completeTask(Task task) async {
    if (task.recurrenceType != null) {
      if (task.isCompleted) return null;

      final newTask = await _db.completeRecurringTask(task);

      if (task.id != null) {
        await _notify.cancelTaskNotifications(task.id!);
      }

      // 旧タスクのカレンダーイベント削除 + 新タスクにイベント作成
      if (task.calendarEventId != null && _isPremium) {
        await _calendar.deleteCalendarEvent(task.calendarEventId!);
        final (_, eventId) = await _calendar.addTaskToCalendar(newTask);
        if (eventId != null) {
          final withEvent = newTask.copyWith(calendarEventId: eventId);
          await _db.updateTask(withEvent);
        }
      }

      await _notify.scheduleTaskNotifications(newTask, isPremium: _isPremium);

      // ゲーミフィケーション統合: 完了XP+ストリーク+バッジ
      final remaining = await _db.getActiveTodayTasksBroad();
      final allDone = remaining.isEmpty;
      await ref
          .read(userStatsProvider.notifier)
          .recordTaskCompletion(isAllTodayDone: allDone);

      ref.invalidateSelf();
      return newTask;
    } else {
      await toggleComplete(task);
      return null;
    }
  }
}
