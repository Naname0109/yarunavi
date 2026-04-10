import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import 'task_provider.dart';

/// カテゴリ一覧Provider
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final db = ref.read(databaseServiceProvider);
  return db.getAllCategories();
});

/// カテゴリ操作用Notifier
final categoryActionsProvider = Provider((ref) => CategoryActions(ref));

class CategoryActions {
  final Ref _ref;
  CategoryActions(this._ref);

  Future<void> add(Category category) async {
    final db = _ref.read(databaseServiceProvider);
    await db.addCategory(category);
    _ref.invalidate(categoriesProvider);
  }

  Future<void> update(Category category) async {
    final db = _ref.read(databaseServiceProvider);
    await db.updateCategory(category);
    _ref.invalidate(categoriesProvider);
  }

  Future<void> delete(int id) async {
    final db = _ref.read(databaseServiceProvider);
    await db.deleteCategory(id);
    _ref.invalidate(categoriesProvider);
    _ref.invalidate(tasksProvider);
  }
}
