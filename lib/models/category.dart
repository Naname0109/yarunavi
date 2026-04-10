import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
class Category with _$Category {
  const Category._();

  const factory Category({
    int? id,
    required String name,
    required String icon,
    @Default(0) int sortOrder,
    @Default(false) bool isDefault,
    required DateTime createdAt,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);

  /// sqflite用: Map → Category
  static Category fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as int?,
        name: map['name'] as String,
        icon: map['icon'] as String,
        sortOrder: map['sort_order'] as int? ?? 0,
        isDefault: (map['is_default'] as int? ?? 0) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  /// sqflite用: Category → Map
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'icon': icon,
        'sort_order': sortOrder,
        'is_default': isDefault ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };
}
