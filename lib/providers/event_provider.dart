import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event.dart';
import 'task_provider.dart' show databaseServiceProvider;

/// #2: カレンダー予定 (タスクとは独立) の Riverpod Provider。
class EventsNotifier extends AsyncNotifier<List<Event>> {
  @override
  Future<List<Event>> build() async {
    final db = ref.read(databaseServiceProvider);
    return db.getAllEvents();
  }

  Future<void> add(Event event) async {
    final db = ref.read(databaseServiceProvider);
    await db.insertEvent(event);
    ref.invalidateSelf();
  }

  Future<void> updateEvent(Event event) async {
    final db = ref.read(databaseServiceProvider);
    await db.updateEvent(event);
    ref.invalidateSelf();
  }

  Future<void> delete(int id) async {
    final db = ref.read(databaseServiceProvider);
    await db.deleteEvent(id);
    ref.invalidateSelf();
  }
}

final eventsProvider =
    AsyncNotifierProvider<EventsNotifier, List<Event>>(EventsNotifier.new);
