// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Event _$EventFromJson(Map<String, dynamic> json) {
  return _Event.fromJson(json);
}

/// @nodoc
mixin _$Event {
  int? get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String? get startTime => throw _privateConstructorUsedError; // "HH:mm" 形式
  String? get endTime => throw _privateConstructorUsedError; // "HH:mm" 形式
  bool get isAllDay => throw _privateConstructorUsedError;
  String? get memo => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  String? get externalId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Event to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Event
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EventCopyWith<Event> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EventCopyWith<$Res> {
  factory $EventCopyWith(Event value, $Res Function(Event) then) =
      _$EventCopyWithImpl<$Res, Event>;
  @useResult
  $Res call({
    int? id,
    String title,
    DateTime date,
    String? startTime,
    String? endTime,
    bool isAllDay,
    String? memo,
    String source,
    String? externalId,
    DateTime createdAt,
  });
}

/// @nodoc
class _$EventCopyWithImpl<$Res, $Val extends Event>
    implements $EventCopyWith<$Res> {
  _$EventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Event
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? title = null,
    Object? date = null,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? isAllDay = null,
    Object? memo = freezed,
    Object? source = null,
    Object? externalId = freezed,
    Object? createdAt = null,
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
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            startTime: freezed == startTime
                ? _value.startTime
                : startTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            endTime: freezed == endTime
                ? _value.endTime
                : endTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            isAllDay: null == isAllDay
                ? _value.isAllDay
                : isAllDay // ignore: cast_nullable_to_non_nullable
                      as bool,
            memo: freezed == memo
                ? _value.memo
                : memo // ignore: cast_nullable_to_non_nullable
                      as String?,
            source: null == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String,
            externalId: freezed == externalId
                ? _value.externalId
                : externalId // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EventImplCopyWith<$Res> implements $EventCopyWith<$Res> {
  factory _$$EventImplCopyWith(
    _$EventImpl value,
    $Res Function(_$EventImpl) then,
  ) = __$$EventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    String title,
    DateTime date,
    String? startTime,
    String? endTime,
    bool isAllDay,
    String? memo,
    String source,
    String? externalId,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$EventImplCopyWithImpl<$Res>
    extends _$EventCopyWithImpl<$Res, _$EventImpl>
    implements _$$EventImplCopyWith<$Res> {
  __$$EventImplCopyWithImpl(
    _$EventImpl _value,
    $Res Function(_$EventImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Event
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? title = null,
    Object? date = null,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? isAllDay = null,
    Object? memo = freezed,
    Object? source = null,
    Object? externalId = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$EventImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        startTime: freezed == startTime
            ? _value.startTime
            : startTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        endTime: freezed == endTime
            ? _value.endTime
            : endTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        isAllDay: null == isAllDay
            ? _value.isAllDay
            : isAllDay // ignore: cast_nullable_to_non_nullable
                  as bool,
        memo: freezed == memo
            ? _value.memo
            : memo // ignore: cast_nullable_to_non_nullable
                  as String?,
        source: null == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String,
        externalId: freezed == externalId
            ? _value.externalId
            : externalId // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EventImpl extends _Event {
  const _$EventImpl({
    this.id,
    required this.title,
    required this.date,
    this.startTime,
    this.endTime,
    this.isAllDay = true,
    this.memo,
    this.source = 'manual',
    this.externalId,
    required this.createdAt,
  }) : super._();

  factory _$EventImpl.fromJson(Map<String, dynamic> json) =>
      _$$EventImplFromJson(json);

  @override
  final int? id;
  @override
  final String title;
  @override
  final DateTime date;
  @override
  final String? startTime;
  // "HH:mm" 形式
  @override
  final String? endTime;
  // "HH:mm" 形式
  @override
  @JsonKey()
  final bool isAllDay;
  @override
  final String? memo;
  @override
  @JsonKey()
  final String source;
  @override
  final String? externalId;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Event(id: $id, title: $title, date: $date, startTime: $startTime, endTime: $endTime, isAllDay: $isAllDay, memo: $memo, source: $source, externalId: $externalId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.isAllDay, isAllDay) ||
                other.isAllDay == isAllDay) &&
            (identical(other.memo, memo) || other.memo == memo) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.externalId, externalId) ||
                other.externalId == externalId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    date,
    startTime,
    endTime,
    isAllDay,
    memo,
    source,
    externalId,
    createdAt,
  );

  /// Create a copy of Event
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EventImplCopyWith<_$EventImpl> get copyWith =>
      __$$EventImplCopyWithImpl<_$EventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EventImplToJson(this);
  }
}

abstract class _Event extends Event {
  const factory _Event({
    final int? id,
    required final String title,
    required final DateTime date,
    final String? startTime,
    final String? endTime,
    final bool isAllDay,
    final String? memo,
    final String source,
    final String? externalId,
    required final DateTime createdAt,
  }) = _$EventImpl;
  const _Event._() : super._();

  factory _Event.fromJson(Map<String, dynamic> json) = _$EventImpl.fromJson;

  @override
  int? get id;
  @override
  String get title;
  @override
  DateTime get date;
  @override
  String? get startTime; // "HH:mm" 形式
  @override
  String? get endTime; // "HH:mm" 形式
  @override
  bool get isAllDay;
  @override
  String? get memo;
  @override
  String get source;
  @override
  String? get externalId;
  @override
  DateTime get createdAt;

  /// Create a copy of Event
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EventImplCopyWith<_$EventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
