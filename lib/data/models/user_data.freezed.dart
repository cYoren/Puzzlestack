// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserData {

@HiveField(0) int get xp;@HiveField(1) int get level;@HiveField(2) int? get superStreak;@HiveField(3) DateTime? get lastSuperStreakDate;@HiveField(4) int? get totalSolved;@HiveField(5) List<String>? get favoriteGameIds;@HiveField(6) bool? get isTrialModeEnabled;@HiveField(7) List<String>? get hiddenGameIds;@HiveField(8) bool? get isKeepScreenAwakeEnabled;
/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserDataCopyWith<UserData> get copyWith => _$UserDataCopyWithImpl<UserData>(this as UserData, _$identity);

  /// Serializes this UserData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UserData;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserData&&(identical(other.xp, _this.xp) || other.xp == _this.xp)&&(identical(other.level, _this.level) || other.level == _this.level)&&(identical(other.superStreak, _this.superStreak) || other.superStreak == _this.superStreak)&&(identical(other.lastSuperStreakDate, _this.lastSuperStreakDate) || other.lastSuperStreakDate == _this.lastSuperStreakDate)&&(identical(other.totalSolved, _this.totalSolved) || other.totalSolved == _this.totalSolved)&&const DeepCollectionEquality().equals(other.favoriteGameIds, _this.favoriteGameIds)&&(identical(other.isTrialModeEnabled, _this.isTrialModeEnabled) || other.isTrialModeEnabled == _this.isTrialModeEnabled)&&const DeepCollectionEquality().equals(other.hiddenGameIds, _this.hiddenGameIds)&&(identical(other.isKeepScreenAwakeEnabled, _this.isKeepScreenAwakeEnabled) || other.isKeepScreenAwakeEnabled == _this.isKeepScreenAwakeEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UserData;
  return Object.hash(runtimeType,_this.xp,_this.level,_this.superStreak,_this.lastSuperStreakDate,_this.totalSolved,const DeepCollectionEquality().hash(_this.favoriteGameIds),_this.isTrialModeEnabled,const DeepCollectionEquality().hash(_this.hiddenGameIds),_this.isKeepScreenAwakeEnabled);
}

@override
String toString() {
  final _this = this as UserData;
  return 'UserData(xp: ${_this.xp}, level: ${_this.level}, superStreak: ${_this.superStreak}, lastSuperStreakDate: ${_this.lastSuperStreakDate}, totalSolved: ${_this.totalSolved}, favoriteGameIds: ${_this.favoriteGameIds}, isTrialModeEnabled: ${_this.isTrialModeEnabled}, hiddenGameIds: ${_this.hiddenGameIds}, isKeepScreenAwakeEnabled: ${_this.isKeepScreenAwakeEnabled})';
}


}

/// @nodoc
abstract mixin class $UserDataCopyWith<$Res>  {
  factory $UserDataCopyWith(UserData value, $Res Function(UserData) _then) = _$UserDataCopyWithImpl;
@useResult
$Res call({
@HiveField(0) int xp,@HiveField(1) int level,@HiveField(2) int? superStreak,@HiveField(3) DateTime? lastSuperStreakDate,@HiveField(4) int? totalSolved,@HiveField(5) List<String>? favoriteGameIds,@HiveField(6) bool? isTrialModeEnabled,@HiveField(7) List<String>? hiddenGameIds,@HiveField(8) bool? isKeepScreenAwakeEnabled
});




}
/// @nodoc
class _$UserDataCopyWithImpl<$Res>
    implements $UserDataCopyWith<$Res> {
  _$UserDataCopyWithImpl(this._self, this._then);

  final UserData _self;
  final $Res Function(UserData) _then;

/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? xp = null,Object? level = null,Object? superStreak = freezed,Object? lastSuperStreakDate = freezed,Object? totalSolved = freezed,Object? favoriteGameIds = freezed,Object? isTrialModeEnabled = freezed,Object? hiddenGameIds = freezed,Object? isKeepScreenAwakeEnabled = freezed,}) {
  return _then(UserData(
xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,superStreak: freezed == superStreak ? _self.superStreak : superStreak // ignore: cast_nullable_to_non_nullable
as int?,lastSuperStreakDate: freezed == lastSuperStreakDate ? _self.lastSuperStreakDate : lastSuperStreakDate // ignore: cast_nullable_to_non_nullable
as DateTime?,totalSolved: freezed == totalSolved ? _self.totalSolved : totalSolved // ignore: cast_nullable_to_non_nullable
as int?,favoriteGameIds: freezed == favoriteGameIds ? _self.favoriteGameIds : favoriteGameIds // ignore: cast_nullable_to_non_nullable
as List<String>?,isTrialModeEnabled: freezed == isTrialModeEnabled ? _self.isTrialModeEnabled : isTrialModeEnabled // ignore: cast_nullable_to_non_nullable
as bool?,hiddenGameIds: freezed == hiddenGameIds ? _self.hiddenGameIds : hiddenGameIds // ignore: cast_nullable_to_non_nullable
as List<String>?,isKeepScreenAwakeEnabled: freezed == isKeepScreenAwakeEnabled ? _self.isKeepScreenAwakeEnabled : isKeepScreenAwakeEnabled // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserData].
extension UserDataPatterns on UserData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserData value)  $default,){
final _that = this;
switch (_that) {
case _UserData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserData value)?  $default,){
final _that = this;
switch (_that) {
case _UserData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  int xp, @HiveField(1)  int level, @HiveField(2)  int? superStreak, @HiveField(3)  DateTime? lastSuperStreakDate, @HiveField(4)  int? totalSolved, @HiveField(5)  List<String>? favoriteGameIds, @HiveField(6)  bool? isTrialModeEnabled, @HiveField(7)  List<String>? hiddenGameIds, @HiveField(8)  bool? isKeepScreenAwakeEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserData() when $default != null:
return $default(_that.xp,_that.level,_that.superStreak,_that.lastSuperStreakDate,_that.totalSolved,_that.favoriteGameIds,_that.isTrialModeEnabled,_that.hiddenGameIds,_that.isKeepScreenAwakeEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  int xp, @HiveField(1)  int level, @HiveField(2)  int? superStreak, @HiveField(3)  DateTime? lastSuperStreakDate, @HiveField(4)  int? totalSolved, @HiveField(5)  List<String>? favoriteGameIds, @HiveField(6)  bool? isTrialModeEnabled, @HiveField(7)  List<String>? hiddenGameIds, @HiveField(8)  bool? isKeepScreenAwakeEnabled)  $default,) {final _that = this;
switch (_that) {
case _UserData():
return $default(_that.xp,_that.level,_that.superStreak,_that.lastSuperStreakDate,_that.totalSolved,_that.favoriteGameIds,_that.isTrialModeEnabled,_that.hiddenGameIds,_that.isKeepScreenAwakeEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  int xp, @HiveField(1)  int level, @HiveField(2)  int? superStreak, @HiveField(3)  DateTime? lastSuperStreakDate, @HiveField(4)  int? totalSolved, @HiveField(5)  List<String>? favoriteGameIds, @HiveField(6)  bool? isTrialModeEnabled, @HiveField(7)  List<String>? hiddenGameIds, @HiveField(8)  bool? isKeepScreenAwakeEnabled)?  $default,) {final _that = this;
switch (_that) {
case _UserData() when $default != null:
return $default(_that.xp,_that.level,_that.superStreak,_that.lastSuperStreakDate,_that.totalSolved,_that.favoriteGameIds,_that.isTrialModeEnabled,_that.hiddenGameIds,_that.isKeepScreenAwakeEnabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()
@HiveType(typeId: 0, adapterName: 'UserDataAdapter')
class _UserData extends UserData {
  const _UserData({@HiveField(0) required this.xp, @HiveField(1) required this.level, @HiveField(2) this.superStreak, @HiveField(3) this.lastSuperStreakDate, @HiveField(4) this.totalSolved, @HiveField(5)  List<String>? favoriteGameIds, @HiveField(6) this.isTrialModeEnabled, @HiveField(7)  List<String>? hiddenGameIds, @HiveField(8) this.isKeepScreenAwakeEnabled}): _favoriteGameIds = favoriteGameIds,_hiddenGameIds = hiddenGameIds,super._();
  factory _UserData.fromJson(Map<String, dynamic> json) => _$UserDataFromJson(json);

@override@HiveField(0) final  int xp;
@override@HiveField(1) final  int level;
@override@HiveField(2) final  int? superStreak;
@override@HiveField(3) final  DateTime? lastSuperStreakDate;
@override@HiveField(4) final  int? totalSolved;
 final  List<String>? _favoriteGameIds;
@override@HiveField(5) List<String>? get favoriteGameIds {
  final value = _favoriteGameIds;
  if (value == null) return null;
  if (_favoriteGameIds is EqualUnmodifiableListView) return _favoriteGameIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@HiveField(6) final  bool? isTrialModeEnabled;
 final  List<String>? _hiddenGameIds;
@override@HiveField(7) List<String>? get hiddenGameIds {
  final value = _hiddenGameIds;
  if (value == null) return null;
  if (_hiddenGameIds is EqualUnmodifiableListView) return _hiddenGameIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@HiveField(8) final  bool? isKeepScreenAwakeEnabled;

/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserDataCopyWith<_UserData> get copyWith => __$UserDataCopyWithImpl<_UserData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserDataToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserData&&(identical(other.xp, xp) || other.xp == xp)&&(identical(other.level, level) || other.level == level)&&(identical(other.superStreak, superStreak) || other.superStreak == superStreak)&&(identical(other.lastSuperStreakDate, lastSuperStreakDate) || other.lastSuperStreakDate == lastSuperStreakDate)&&(identical(other.totalSolved, totalSolved) || other.totalSolved == totalSolved)&&const DeepCollectionEquality().equals(other.favoriteGameIds, _favoriteGameIds)&&(identical(other.isTrialModeEnabled, isTrialModeEnabled) || other.isTrialModeEnabled == isTrialModeEnabled)&&const DeepCollectionEquality().equals(other.hiddenGameIds, _hiddenGameIds)&&(identical(other.isKeepScreenAwakeEnabled, isKeepScreenAwakeEnabled) || other.isKeepScreenAwakeEnabled == isKeepScreenAwakeEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,xp,level,superStreak,lastSuperStreakDate,totalSolved,const DeepCollectionEquality().hash(_favoriteGameIds),isTrialModeEnabled,const DeepCollectionEquality().hash(_hiddenGameIds),isKeepScreenAwakeEnabled);
}

@override
String toString() {
    return 'UserData(xp: $xp, level: $level, superStreak: $superStreak, lastSuperStreakDate: $lastSuperStreakDate, totalSolved: $totalSolved, favoriteGameIds: $favoriteGameIds, isTrialModeEnabled: $isTrialModeEnabled, hiddenGameIds: $hiddenGameIds, isKeepScreenAwakeEnabled: $isKeepScreenAwakeEnabled)';
}


}

/// @nodoc
abstract mixin class _$UserDataCopyWith<$Res> implements $UserDataCopyWith<$Res> {
  factory _$UserDataCopyWith(_UserData value, $Res Function(_UserData) _then) = __$UserDataCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) int xp,@HiveField(1) int level,@HiveField(2) int? superStreak,@HiveField(3) DateTime? lastSuperStreakDate,@HiveField(4) int? totalSolved,@HiveField(5) List<String>? favoriteGameIds,@HiveField(6) bool? isTrialModeEnabled,@HiveField(7) List<String>? hiddenGameIds,@HiveField(8) bool? isKeepScreenAwakeEnabled
});




}
/// @nodoc
class __$UserDataCopyWithImpl<$Res>
    implements _$UserDataCopyWith<$Res> {
  __$UserDataCopyWithImpl(this._self, this._then);

  final _UserData _self;
  final $Res Function(_UserData) _then;

/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? xp = null,Object? level = null,Object? superStreak = freezed,Object? lastSuperStreakDate = freezed,Object? totalSolved = freezed,Object? favoriteGameIds = freezed,Object? isTrialModeEnabled = freezed,Object? hiddenGameIds = freezed,Object? isKeepScreenAwakeEnabled = freezed,}) {
  return _then(_UserData(
xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,superStreak: freezed == superStreak ? _self.superStreak : superStreak // ignore: cast_nullable_to_non_nullable
as int?,lastSuperStreakDate: freezed == lastSuperStreakDate ? _self.lastSuperStreakDate : lastSuperStreakDate // ignore: cast_nullable_to_non_nullable
as DateTime?,totalSolved: freezed == totalSolved ? _self.totalSolved : totalSolved // ignore: cast_nullable_to_non_nullable
as int?,favoriteGameIds: freezed == favoriteGameIds ? _self._favoriteGameIds : favoriteGameIds // ignore: cast_nullable_to_non_nullable
as List<String>?,isTrialModeEnabled: freezed == isTrialModeEnabled ? _self.isTrialModeEnabled : isTrialModeEnabled // ignore: cast_nullable_to_non_nullable
as bool?,hiddenGameIds: freezed == hiddenGameIds ? _self._hiddenGameIds : hiddenGameIds // ignore: cast_nullable_to_non_nullable
as List<String>?,isKeepScreenAwakeEnabled: freezed == isKeepScreenAwakeEnabled ? _self.isKeepScreenAwakeEnabled : isKeepScreenAwakeEnabled // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
