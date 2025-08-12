// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mood_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MoodEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoodEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MoodEvent()';
}


}

/// @nodoc
class $MoodEventCopyWith<$Res>  {
$MoodEventCopyWith(MoodEvent _, $Res Function(MoodEvent) __);
}


/// Adds pattern-matching-related methods to [MoodEvent].
extension MoodEventPatterns on MoodEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LoadInitialMood value)?  loadInitialMood,TResult Function( MoodSelected value)?  moodSelected,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LoadInitialMood() when loadInitialMood != null:
return loadInitialMood(_that);case MoodSelected() when moodSelected != null:
return moodSelected(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LoadInitialMood value)  loadInitialMood,required TResult Function( MoodSelected value)  moodSelected,}){
final _that = this;
switch (_that) {
case LoadInitialMood():
return loadInitialMood(_that);case MoodSelected():
return moodSelected(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LoadInitialMood value)?  loadInitialMood,TResult? Function( MoodSelected value)?  moodSelected,}){
final _that = this;
switch (_that) {
case LoadInitialMood() when loadInitialMood != null:
return loadInitialMood(_that);case MoodSelected() when moodSelected != null:
return moodSelected(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadInitialMood,TResult Function( String mood)?  moodSelected,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LoadInitialMood() when loadInitialMood != null:
return loadInitialMood();case MoodSelected() when moodSelected != null:
return moodSelected(_that.mood);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadInitialMood,required TResult Function( String mood)  moodSelected,}) {final _that = this;
switch (_that) {
case LoadInitialMood():
return loadInitialMood();case MoodSelected():
return moodSelected(_that.mood);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadInitialMood,TResult? Function( String mood)?  moodSelected,}) {final _that = this;
switch (_that) {
case LoadInitialMood() when loadInitialMood != null:
return loadInitialMood();case MoodSelected() when moodSelected != null:
return moodSelected(_that.mood);case _:
  return null;

}
}

}

/// @nodoc


class LoadInitialMood implements MoodEvent {
  const LoadInitialMood();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadInitialMood);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MoodEvent.loadInitialMood()';
}


}




/// @nodoc


class MoodSelected implements MoodEvent {
  const MoodSelected(this.mood);
  

 final  String mood;

/// Create a copy of MoodEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MoodSelectedCopyWith<MoodSelected> get copyWith => _$MoodSelectedCopyWithImpl<MoodSelected>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoodSelected&&(identical(other.mood, mood) || other.mood == mood));
}


@override
int get hashCode => Object.hash(runtimeType,mood);

@override
String toString() {
  return 'MoodEvent.moodSelected(mood: $mood)';
}


}

/// @nodoc
abstract mixin class $MoodSelectedCopyWith<$Res> implements $MoodEventCopyWith<$Res> {
  factory $MoodSelectedCopyWith(MoodSelected value, $Res Function(MoodSelected) _then) = _$MoodSelectedCopyWithImpl;
@useResult
$Res call({
 String mood
});




}
/// @nodoc
class _$MoodSelectedCopyWithImpl<$Res>
    implements $MoodSelectedCopyWith<$Res> {
  _$MoodSelectedCopyWithImpl(this._self, this._then);

  final MoodSelected _self;
  final $Res Function(MoodSelected) _then;

/// Create a copy of MoodEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mood = null,}) {
  return _then(MoodSelected(
null == mood ? _self.mood : mood // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$MoodState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoodState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MoodState()';
}


}

/// @nodoc
class $MoodStateCopyWith<$Res>  {
$MoodStateCopyWith(MoodState _, $Res Function(MoodState) __);
}


/// Adds pattern-matching-related methods to [MoodState].
extension MoodStatePatterns on MoodState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MoodInitial value)?  initial,TResult Function( MoodLoadInProgress value)?  loadInProgress,TResult Function( MoodLoadSuccess value)?  loadSuccess,TResult Function( MoodLoadFailure value)?  loadFailure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MoodInitial() when initial != null:
return initial(_that);case MoodLoadInProgress() when loadInProgress != null:
return loadInProgress(_that);case MoodLoadSuccess() when loadSuccess != null:
return loadSuccess(_that);case MoodLoadFailure() when loadFailure != null:
return loadFailure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MoodInitial value)  initial,required TResult Function( MoodLoadInProgress value)  loadInProgress,required TResult Function( MoodLoadSuccess value)  loadSuccess,required TResult Function( MoodLoadFailure value)  loadFailure,}){
final _that = this;
switch (_that) {
case MoodInitial():
return initial(_that);case MoodLoadInProgress():
return loadInProgress(_that);case MoodLoadSuccess():
return loadSuccess(_that);case MoodLoadFailure():
return loadFailure(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MoodInitial value)?  initial,TResult? Function( MoodLoadInProgress value)?  loadInProgress,TResult? Function( MoodLoadSuccess value)?  loadSuccess,TResult? Function( MoodLoadFailure value)?  loadFailure,}){
final _that = this;
switch (_that) {
case MoodInitial() when initial != null:
return initial(_that);case MoodLoadInProgress() when loadInProgress != null:
return loadInProgress(_that);case MoodLoadSuccess() when loadSuccess != null:
return loadSuccess(_that);case MoodLoadFailure() when loadFailure != null:
return loadFailure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loadInProgress,TResult Function( List<String> allMoods,  String selectedMood)?  loadSuccess,TResult Function( String error)?  loadFailure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MoodInitial() when initial != null:
return initial();case MoodLoadInProgress() when loadInProgress != null:
return loadInProgress();case MoodLoadSuccess() when loadSuccess != null:
return loadSuccess(_that.allMoods,_that.selectedMood);case MoodLoadFailure() when loadFailure != null:
return loadFailure(_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loadInProgress,required TResult Function( List<String> allMoods,  String selectedMood)  loadSuccess,required TResult Function( String error)  loadFailure,}) {final _that = this;
switch (_that) {
case MoodInitial():
return initial();case MoodLoadInProgress():
return loadInProgress();case MoodLoadSuccess():
return loadSuccess(_that.allMoods,_that.selectedMood);case MoodLoadFailure():
return loadFailure(_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loadInProgress,TResult? Function( List<String> allMoods,  String selectedMood)?  loadSuccess,TResult? Function( String error)?  loadFailure,}) {final _that = this;
switch (_that) {
case MoodInitial() when initial != null:
return initial();case MoodLoadInProgress() when loadInProgress != null:
return loadInProgress();case MoodLoadSuccess() when loadSuccess != null:
return loadSuccess(_that.allMoods,_that.selectedMood);case MoodLoadFailure() when loadFailure != null:
return loadFailure(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class MoodInitial implements MoodState {
  const MoodInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoodInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MoodState.initial()';
}


}




/// @nodoc


class MoodLoadInProgress implements MoodState {
  const MoodLoadInProgress();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoodLoadInProgress);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MoodState.loadInProgress()';
}


}




/// @nodoc


class MoodLoadSuccess implements MoodState {
  const MoodLoadSuccess({required final  List<String> allMoods, required this.selectedMood}): _allMoods = allMoods;
  

 final  List<String> _allMoods;
 List<String> get allMoods {
  if (_allMoods is EqualUnmodifiableListView) return _allMoods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allMoods);
}

 final  String selectedMood;

/// Create a copy of MoodState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MoodLoadSuccessCopyWith<MoodLoadSuccess> get copyWith => _$MoodLoadSuccessCopyWithImpl<MoodLoadSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoodLoadSuccess&&const DeepCollectionEquality().equals(other._allMoods, _allMoods)&&(identical(other.selectedMood, selectedMood) || other.selectedMood == selectedMood));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_allMoods),selectedMood);

@override
String toString() {
  return 'MoodState.loadSuccess(allMoods: $allMoods, selectedMood: $selectedMood)';
}


}

/// @nodoc
abstract mixin class $MoodLoadSuccessCopyWith<$Res> implements $MoodStateCopyWith<$Res> {
  factory $MoodLoadSuccessCopyWith(MoodLoadSuccess value, $Res Function(MoodLoadSuccess) _then) = _$MoodLoadSuccessCopyWithImpl;
@useResult
$Res call({
 List<String> allMoods, String selectedMood
});




}
/// @nodoc
class _$MoodLoadSuccessCopyWithImpl<$Res>
    implements $MoodLoadSuccessCopyWith<$Res> {
  _$MoodLoadSuccessCopyWithImpl(this._self, this._then);

  final MoodLoadSuccess _self;
  final $Res Function(MoodLoadSuccess) _then;

/// Create a copy of MoodState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? allMoods = null,Object? selectedMood = null,}) {
  return _then(MoodLoadSuccess(
allMoods: null == allMoods ? _self._allMoods : allMoods // ignore: cast_nullable_to_non_nullable
as List<String>,selectedMood: null == selectedMood ? _self.selectedMood : selectedMood // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MoodLoadFailure implements MoodState {
  const MoodLoadFailure(this.error);
  

 final  String error;

/// Create a copy of MoodState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MoodLoadFailureCopyWith<MoodLoadFailure> get copyWith => _$MoodLoadFailureCopyWithImpl<MoodLoadFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoodLoadFailure&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,error);

@override
String toString() {
  return 'MoodState.loadFailure(error: $error)';
}


}

/// @nodoc
abstract mixin class $MoodLoadFailureCopyWith<$Res> implements $MoodStateCopyWith<$Res> {
  factory $MoodLoadFailureCopyWith(MoodLoadFailure value, $Res Function(MoodLoadFailure) _then) = _$MoodLoadFailureCopyWithImpl;
@useResult
$Res call({
 String error
});




}
/// @nodoc
class _$MoodLoadFailureCopyWithImpl<$Res>
    implements $MoodLoadFailureCopyWith<$Res> {
  _$MoodLoadFailureCopyWithImpl(this._self, this._then);

  final MoodLoadFailure _self;
  final $Res Function(MoodLoadFailure) _then;

/// Create a copy of MoodState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(MoodLoadFailure(
null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
