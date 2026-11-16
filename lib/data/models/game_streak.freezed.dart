// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_streak.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GameStreak {

@HiveField(0) String get gameId;@HiveField(1) int get currentStreak;@HiveField(2) DateTime get lastSolvedDate;@HiveField(3) bool get solvedToday;
/// Create a copy of GameStreak
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameStreakCopyWith<GameStreak> get copyWith => _$GameStreakCopyWithImpl<GameStreak>(this as GameStreak, _$identity);

  /// Serializes this GameStreak to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GameStreak;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameStreak&&(identical(other.gameId, _this.gameId) || other.gameId == _this.gameId)&&(identical(other.currentStreak, _this.currentStreak) || other.currentStreak == _this.currentStreak)&&(identical(other.lastSolvedDate, _this.lastSolvedDate) || other.lastSolvedDate == _this.lastSolvedDate)&&(identical(other.solvedToday, _this.solvedToday) || other.solvedToday == _this.solvedToday));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GameStreak;
  return Object.hash(runtimeType,_this.gameId,_this.currentStreak,_this.lastSolvedDate,_this.solvedToday);
}

@override
String toString() {
  final _this = this as GameStreak;
  return 'GameStreak(gameId: ${_this.gameId}, currentStreak: ${_this.currentStreak}, lastSolvedDate: ${_this.lastSolvedDate}, solvedToday: ${_this.solvedToday})';
}


}

/// @nodoc
abstract mixin class $GameStreakCopyWith<$Res>  {
  factory $GameStreakCopyWith(GameStreak value, $Res Function(GameStreak) _then) = _$GameStreakCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String gameId,@HiveField(1) int currentStreak,@HiveField(2) DateTime lastSolvedDate,@HiveField(3) bool solvedToday
});




}
/// @nodoc
class _$GameStreakCopyWithImpl<$Res>
    implements $GameStreakCopyWith<$Res> {
  _$GameStreakCopyWithImpl(this._self, this._then);

  final GameStreak _self;
  final $Res Function(GameStreak) _then;

/// Create a copy of GameStreak
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gameId = null,Object? currentStreak = null,Object? lastSolvedDate = null,Object? solvedToday = null,}) {
  return _then(GameStreak(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,currentStreak: null == currentStreak ? _self.currentStreak : currentStreak // ignore: cast_nullable_to_non_nullable
as int,lastSolvedDate: null == lastSolvedDate ? _self.lastSolvedDate : lastSolvedDate // ignore: cast_nullable_to_non_nullable
as DateTime,solvedToday: null == solvedToday ? _self.solvedToday : solvedToday // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GameStreak].
extension GameStreakPatterns on GameStreak {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameStreak value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameStreak() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameStreak value)  $default,){
final _that = this;
switch (_that) {
case _GameStreak():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameStreak value)?  $default,){
final _that = this;
switch (_that) {
case _GameStreak() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String gameId, @HiveField(1)  int currentStreak, @HiveField(2)  DateTime lastSolvedDate, @HiveField(3)  bool solvedToday)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameStreak() when $default != null:
return $default(_that.gameId,_that.currentStreak,_that.lastSolvedDate,_that.solvedToday);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String gameId, @HiveField(1)  int currentStreak, @HiveField(2)  DateTime lastSolvedDate, @HiveField(3)  bool solvedToday)  $default,) {final _that = this;
switch (_that) {
case _GameStreak():
return $default(_that.gameId,_that.currentStreak,_that.lastSolvedDate,_that.solvedToday);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String gameId, @HiveField(1)  int currentStreak, @HiveField(2)  DateTime lastSolvedDate, @HiveField(3)  bool solvedToday)?  $default,) {final _that = this;
switch (_that) {
case _GameStreak() when $default != null:
return $default(_that.gameId,_that.currentStreak,_that.lastSolvedDate,_that.solvedToday);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()
@HiveType(typeId: 1, adapterName: 'GameStreakAdapter')
class _GameStreak extends GameStreak {
  const _GameStreak({@HiveField(0) required this.gameId, @HiveField(1) required this.currentStreak, @HiveField(2) required this.lastSolvedDate, @HiveField(3) required this.solvedToday}): super._();
  factory _GameStreak.fromJson(Map<String, dynamic> json) => _$GameStreakFromJson(json);

@override@HiveField(0) final  String gameId;
@override@HiveField(1) final  int currentStreak;
@override@HiveField(2) final  DateTime lastSolvedDate;
@override@HiveField(3) final  bool solvedToday;

/// Create a copy of GameStreak
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameStreakCopyWith<_GameStreak> get copyWith => __$GameStreakCopyWithImpl<_GameStreak>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameStreakToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameStreak&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.currentStreak, currentStreak) || other.currentStreak == currentStreak)&&(identical(other.lastSolvedDate, lastSolvedDate) || other.lastSolvedDate == lastSolvedDate)&&(identical(other.solvedToday, solvedToday) || other.solvedToday == solvedToday));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,gameId,currentStreak,lastSolvedDate,solvedToday);
}

@override
String toString() {
    return 'GameStreak(gameId: $gameId, currentStreak: $currentStreak, lastSolvedDate: $lastSolvedDate, solvedToday: $solvedToday)';
}


}

/// @nodoc
abstract mixin class _$GameStreakCopyWith<$Res> implements $GameStreakCopyWith<$Res> {
  factory _$GameStreakCopyWith(_GameStreak value, $Res Function(_GameStreak) _then) = __$GameStreakCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String gameId,@HiveField(1) int currentStreak,@HiveField(2) DateTime lastSolvedDate,@HiveField(3) bool solvedToday
});




}
/// @nodoc
class __$GameStreakCopyWithImpl<$Res>
    implements _$GameStreakCopyWith<$Res> {
  __$GameStreakCopyWithImpl(this._self, this._then);

  final _GameStreak _self;
  final $Res Function(_GameStreak) _then;

/// Create a copy of GameStreak
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gameId = null,Object? currentStreak = null,Object? lastSolvedDate = null,Object? solvedToday = null,}) {
  return _then(_GameStreak(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,currentStreak: null == currentStreak ? _self.currentStreak : currentStreak // ignore: cast_nullable_to_non_nullable
as int,lastSolvedDate: null == lastSolvedDate ? _self.lastSolvedDate : lastSolvedDate // ignore: cast_nullable_to_non_nullable
as DateTime,solvedToday: null == solvedToday ? _self.solvedToday : solvedToday // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
