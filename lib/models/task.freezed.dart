// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Task _$TaskFromJson(Map<String, dynamic> json) {
  return _Task.fromJson(json);
}

/// @nodoc
mixin _$Task {
  int? get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  DateTime get dueDate => throw _privateConstructorUsedError;
  String? get memo => throw _privateConstructorUsedError;
  int? get categoryId => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;
  int get priority => throw _privateConstructorUsedError;
  String? get aiComment => throw _privateConstructorUsedError;
  String? get recurrenceType => throw _privateConstructorUsedError;
  int? get recurrenceValue => throw _privateConstructorUsedError;
  int? get recurrenceParentId => throw _privateConstructorUsedError;
  String? get notifySettings => throw _privateConstructorUsedError;
  String? get calendarEventId => throw _privateConstructorUsedError;
  String? get estimatedTime => throw _privateConstructorUsedError;
  int get importance => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  DateTime? get recommendedStart => throw _privateConstructorUsedError;
  DateTime? get recommendedEnd => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Task to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskCopyWith<Task> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskCopyWith<$Res> {
  factory $TaskCopyWith(Task value, $Res Function(Task) then) =
      _$TaskCopyWithImpl<$Res, Task>;
  @useResult
  $Res call({
    int? id,
    String title,
    DateTime dueDate,
    String? memo,
    int? categoryId,
    bool isCompleted,
    DateTime? completedAt,
    int priority,
    String? aiComment,
    String? recurrenceType,
    int? recurrenceValue,
    int? recurrenceParentId,
    String? notifySettings,
    String? calendarEventId,
    String? estimatedTime,
    int importance,
    int sortOrder,
    DateTime? recommendedStart,
    DateTime? recommendedEnd,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$TaskCopyWithImpl<$Res, $Val extends Task>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? title = null,
    Object? dueDate = null,
    Object? memo = freezed,
    Object? categoryId = freezed,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? priority = null,
    Object? aiComment = freezed,
    Object? recurrenceType = freezed,
    Object? recurrenceValue = freezed,
    Object? recurrenceParentId = freezed,
    Object? notifySettings = freezed,
    Object? calendarEventId = freezed,
    Object? estimatedTime = freezed,
    Object? importance = null,
    Object? sortOrder = null,
    Object? recommendedStart = freezed,
    Object? recommendedEnd = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            dueDate: null == dueDate
                ? _value.dueDate
                : dueDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            memo: freezed == memo
                ? _value.memo
                : memo // ignore: cast_nullable_to_non_nullable
                      as String?,
            categoryId: freezed == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as int?,
            isCompleted: null == isCompleted
                ? _value.isCompleted
                : isCompleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as int,
            aiComment: freezed == aiComment
                ? _value.aiComment
                : aiComment // ignore: cast_nullable_to_non_nullable
                      as String?,
            recurrenceType: freezed == recurrenceType
                ? _value.recurrenceType
                : recurrenceType // ignore: cast_nullable_to_non_nullable
                      as String?,
            recurrenceValue: freezed == recurrenceValue
                ? _value.recurrenceValue
                : recurrenceValue // ignore: cast_nullable_to_non_nullable
                      as int?,
            recurrenceParentId: freezed == recurrenceParentId
                ? _value.recurrenceParentId
                : recurrenceParentId // ignore: cast_nullable_to_non_nullable
                      as int?,
            notifySettings: freezed == notifySettings
                ? _value.notifySettings
                : notifySettings // ignore: cast_nullable_to_non_nullable
                      as String?,
            calendarEventId: freezed == calendarEventId
                ? _value.calendarEventId
                : calendarEventId // ignore: cast_nullable_to_non_nullable
                      as String?,
            estimatedTime: freezed == estimatedTime
                ? _value.estimatedTime
                : estimatedTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            importance: null == importance
                ? _value.importance
                : importance // ignore: cast_nullable_to_non_nullable
                      as int,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
            recommendedStart: freezed == recommendedStart
                ? _value.recommendedStart
                : recommendedStart // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            recommendedEnd: freezed == recommendedEnd
                ? _value.recommendedEnd
                : recommendedEnd // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TaskImplCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$$TaskImplCopyWith(
    _$TaskImpl value,
    $Res Function(_$TaskImpl) then,
  ) = __$$TaskImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    String title,
    DateTime dueDate,
    String? memo,
    int? categoryId,
    bool isCompleted,
    DateTime? completedAt,
    int priority,
    String? aiComment,
    String? recurrenceType,
    int? recurrenceValue,
    int? recurrenceParentId,
    String? notifySettings,
    String? calendarEventId,
    String? estimatedTime,
    int importance,
    int sortOrder,
    DateTime? recommendedStart,
    DateTime? recommendedEnd,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$TaskImplCopyWithImpl<$Res>
    extends _$TaskCopyWithImpl<$Res, _$TaskImpl>
    implements _$$TaskImplCopyWith<$Res> {
  __$$TaskImplCopyWithImpl(_$TaskImpl _value, $Res Function(_$TaskImpl) _then)
    : super(_value, _then);

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? title = null,
    Object? dueDate = null,
    Object? memo = freezed,
    Object? categoryId = freezed,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? priority = null,
    Object? aiComment = freezed,
    Object? recurrenceType = freezed,
    Object? recurrenceValue = freezed,
    Object? recurrenceParentId = freezed,
    Object? notifySettings = freezed,
    Object? calendarEventId = freezed,
    Object? estimatedTime = freezed,
    Object? importance = null,
    Object? sortOrder = null,
    Object? recommendedStart = freezed,
    Object? recommendedEnd = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$TaskImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        dueDate: null == dueDate
            ? _value.dueDate
            : dueDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        memo: freezed == memo
            ? _value.memo
            : memo // ignore: cast_nullable_to_non_nullable
                  as String?,
        categoryId: freezed == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as int?,
        isCompleted: null == isCompleted
            ? _value.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as int,
        aiComment: freezed == aiComment
            ? _value.aiComment
            : aiComment // ignore: cast_nullable_to_non_nullable
                  as String?,
        recurrenceType: freezed == recurrenceType
            ? _value.recurrenceType
            : recurrenceType // ignore: cast_nullable_to_non_nullable
                  as String?,
        recurrenceValue: freezed == recurrenceValue
            ? _value.recurrenceValue
            : recurrenceValue // ignore: cast_nullable_to_non_nullable
                  as int?,
        recurrenceParentId: freezed == recurrenceParentId
            ? _value.recurrenceParentId
            : recurrenceParentId // ignore: cast_nullable_to_non_nullable
                  as int?,
        notifySettings: freezed == notifySettings
            ? _value.notifySettings
            : notifySettings // ignore: cast_nullable_to_non_nullable
                  as String?,
        calendarEventId: freezed == calendarEventId
            ? _value.calendarEventId
            : calendarEventId // ignore: cast_nullable_to_non_nullable
                  as String?,
        estimatedTime: freezed == estimatedTime
            ? _value.estimatedTime
            : estimatedTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        importance: null == importance
            ? _value.importance
            : importance // ignore: cast_nullable_to_non_nullable
                  as int,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        recommendedStart: freezed == recommendedStart
            ? _value.recommendedStart
            : recommendedStart // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        recommendedEnd: freezed == recommendedEnd
            ? _value.recommendedEnd
            : recommendedEnd // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskImpl extends _Task {
  const _$TaskImpl({
    this.id,
    required this.title,
    required this.dueDate,
    this.memo,
    this.categoryId,
    this.isCompleted = false,
    this.completedAt,
    this.priority = 0,
    this.aiComment,
    this.recurrenceType,
    this.recurrenceValue,
    this.recurrenceParentId,
    this.notifySettings,
    this.calendarEventId,
    this.estimatedTime,
    this.importance = 1,
    this.sortOrder = 0,
    this.recommendedStart,
    this.recommendedEnd,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();

  factory _$TaskImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskImplFromJson(json);

  @override
  final int? id;
  @override
  final String title;
  @override
  final DateTime dueDate;
  @override
  final String? memo;
  @override
  final int? categoryId;
  @override
  @JsonKey()
  final bool isCompleted;
  @override
  final DateTime? completedAt;
  @override
  @JsonKey()
  final int priority;
  @override
  final String? aiComment;
  @override
  final String? recurrenceType;
  @override
  final int? recurrenceValue;
  @override
  final int? recurrenceParentId;
  @override
  final String? notifySettings;
  @override
  final String? calendarEventId;
  @override
  final String? estimatedTime;
  @override
  @JsonKey()
  final int importance;
  @override
  @JsonKey()
  final int sortOrder;
  @override
  final DateTime? recommendedStart;
  @override
  final DateTime? recommendedEnd;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Task(id: $id, title: $title, dueDate: $dueDate, memo: $memo, categoryId: $categoryId, isCompleted: $isCompleted, completedAt: $completedAt, priority: $priority, aiComment: $aiComment, recurrenceType: $recurrenceType, recurrenceValue: $recurrenceValue, recurrenceParentId: $recurrenceParentId, notifySettings: $notifySettings, calendarEventId: $calendarEventId, estimatedTime: $estimatedTime, importance: $importance, sortOrder: $sortOrder, recommendedStart: $recommendedStart, recommendedEnd: $recommendedEnd, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.memo, memo) || other.memo == memo) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.aiComment, aiComment) ||
                other.aiComment == aiComment) &&
            (identical(other.recurrenceType, recurrenceType) ||
                other.recurrenceType == recurrenceType) &&
            (identical(other.recurrenceValue, recurrenceValue) ||
                other.recurrenceValue == recurrenceValue) &&
            (identical(other.recurrenceParentId, recurrenceParentId) ||
                other.recurrenceParentId == recurrenceParentId) &&
            (identical(other.notifySettings, notifySettings) ||
                other.notifySettings == notifySettings) &&
            (identical(other.calendarEventId, calendarEventId) ||
                other.calendarEventId == calendarEventId) &&
            (identical(other.estimatedTime, estimatedTime) ||
                other.estimatedTime == estimatedTime) &&
            (identical(other.importance, importance) ||
                other.importance == importance) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.recommendedStart, recommendedStart) ||
                other.recommendedStart == recommendedStart) &&
            (identical(other.recommendedEnd, recommendedEnd) ||
                other.recommendedEnd == recommendedEnd) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    title,
    dueDate,
    memo,
    categoryId,
    isCompleted,
    completedAt,
    priority,
    aiComment,
    recurrenceType,
    recurrenceValue,
    recurrenceParentId,
    notifySettings,
    calendarEventId,
    estimatedTime,
    importance,
    sortOrder,
    recommendedStart,
    recommendedEnd,
    createdAt,
    updatedAt,
  ]);

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskImplCopyWith<_$TaskImpl> get copyWith =>
      __$$TaskImplCopyWithImpl<_$TaskImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskImplToJson(this);
  }
}

abstract class _Task extends Task {
  const factory _Task({
    final int? id,
    required final String title,
    required final DateTime dueDate,
    final String? memo,
    final int? categoryId,
    final bool isCompleted,
    final DateTime? completedAt,
    final int priority,
    final String? aiComment,
    final String? recurrenceType,
    final int? recurrenceValue,
    final int? recurrenceParentId,
    final String? notifySettings,
    final String? calendarEventId,
    final String? estimatedTime,
    final int importance,
    final int sortOrder,
    final DateTime? recommendedStart,
    final DateTime? recommendedEnd,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$TaskImpl;
  const _Task._() : super._();

  factory _Task.fromJson(Map<String, dynamic> json) = _$TaskImpl.fromJson;

  @override
  int? get id;
  @override
  String get title;
  @override
  DateTime get dueDate;
  @override
  String? get memo;
  @override
  int? get categoryId;
  @override
  bool get isCompleted;
  @override
  DateTime? get completedAt;
  @override
  int get priority;
  @override
  String? get aiComment;
  @override
  String? get recurrenceType;
  @override
  int? get recurrenceValue;
  @override
  int? get recurrenceParentId;
  @override
  String? get notifySettings;
  @override
  String? get calendarEventId;
  @override
  String? get estimatedTime;
  @override
  int get importance;
  @override
  int get sortOrder;
  @override
  DateTime? get recommendedStart;
  @override
  DateTime? get recommendedEnd;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskImplCopyWith<_$TaskImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
