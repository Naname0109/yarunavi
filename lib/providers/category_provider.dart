import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import 'task_provider.dart';

/// カテゴリ一覧Provider
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final db = ref.read(databaseServiceProvider);
  return db.getAllCategories();
});
