// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'journal_writing_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$JournalFailure {

 String get message;
/// Create a copy of JournalFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalFailureCopyWith<JournalFailure> get copyWith => _$JournalFailureCopyWithImpl<JournalFailure>(this as JournalFailure, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'JournalFailure(message: $message)';
}


}

/// @nodoc
abstract mixin class $JournalFailureCopyWith<$Res>  {
  factory $JournalFailureCopyWith(JournalFailure value, $Res Function(JournalFailure) _then) = _$JournalFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$JournalFailureCopyWithImpl<$Res>
    implements $JournalFailureCopyWith<$Res> {
  _$JournalFailureCopyWithImpl(this._self, this._then);

  final JournalFailure _self;
  final $Res Function(JournalFailure) _then;

/// Create a copy of JournalFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,}) {
  return _then(_self.copyWith(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [JournalFailure].
extension JournalFailurePatterns on JournalFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _ValidationFailure value)?  validation,TResult Function( _StorageFailure value)?  storage,TResult Function( _NetworkFailure value)?  network,TResult Function( _UnknownFailure value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ValidationFailure() when validation != null:
return validation(_that);case _StorageFailure() when storage != null:
return storage(_that);case _NetworkFailure() when network != null:
return network(_that);case _UnknownFailure() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _ValidationFailure value)  validation,required TResult Function( _StorageFailure value)  storage,required TResult Function( _NetworkFailure value)  network,required TResult Function( _UnknownFailure value)  unknown,}){
final _that = this;
switch (_that) {
case _ValidationFailure():
return validation(_that);case _StorageFailure():
return storage(_that);case _NetworkFailure():
return network(_that);case _UnknownFailure():
return unknown(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _ValidationFailure value)?  validation,TResult? Function( _StorageFailure value)?  storage,TResult? Function( _NetworkFailure value)?  network,TResult? Function( _UnknownFailure value)?  unknown,}){
final _that = this;
switch (_that) {
case _ValidationFailure() when validation != null:
return validation(_that);case _StorageFailure() when storage != null:
return storage(_that);case _NetworkFailure() when network != null:
return network(_that);case _UnknownFailure() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String message)?  validation,TResult Function( String message)?  storage,TResult Function( String message)?  network,TResult Function( String message)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ValidationFailure() when validation != null:
return validation(_that.message);case _StorageFailure() when storage != null:
return storage(_that.message);case _NetworkFailure() when network != null:
return network(_that.message);case _UnknownFailure() when unknown != null:
return unknown(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String message)  validation,required TResult Function( String message)  storage,required TResult Function( String message)  network,required TResult Function( String message)  unknown,}) {final _that = this;
switch (_that) {
case _ValidationFailure():
return validation(_that.message);case _StorageFailure():
return storage(_that.message);case _NetworkFailure():
return network(_that.message);case _UnknownFailure():
return unknown(_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String message)?  validation,TResult? Function( String message)?  storage,TResult? Function( String message)?  network,TResult? Function( String message)?  unknown,}) {final _that = this;
switch (_that) {
case _ValidationFailure() when validation != null:
return validation(_that.message);case _StorageFailure() when storage != null:
return storage(_that.message);case _NetworkFailure() when network != null:
return network(_that.message);case _UnknownFailure() when unknown != null:
return unknown(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _ValidationFailure implements JournalFailure {
  const _ValidationFailure(this.message);
  

@override final  String message;

/// Create a copy of JournalFailure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ValidationFailureCopyWith<_ValidationFailure> get copyWith => __$ValidationFailureCopyWithImpl<_ValidationFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ValidationFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'JournalFailure.validation(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ValidationFailureCopyWith<$Res> implements $JournalFailureCopyWith<$Res> {
  factory _$ValidationFailureCopyWith(_ValidationFailure value, $Res Function(_ValidationFailure) _then) = __$ValidationFailureCopyWithImpl;
@override @useResult
$Res call({
 String message
});




}
/// @nodoc
class __$ValidationFailureCopyWithImpl<$Res>
    implements _$ValidationFailureCopyWith<$Res> {
  __$ValidationFailureCopyWithImpl(this._self, this._then);

  final _ValidationFailure _self;
  final $Res Function(_ValidationFailure) _then;

/// Create a copy of JournalFailure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_ValidationFailure(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _StorageFailure implements JournalFailure {
  const _StorageFailure(this.message);
  

@override final  String message;

/// Create a copy of JournalFailure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StorageFailureCopyWith<_StorageFailure> get copyWith => __$StorageFailureCopyWithImpl<_StorageFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StorageFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'JournalFailure.storage(message: $message)';
}


}

/// @nodoc
abstract mixin class _$StorageFailureCopyWith<$Res> implements $JournalFailureCopyWith<$Res> {
  factory _$StorageFailureCopyWith(_StorageFailure value, $Res Function(_StorageFailure) _then) = __$StorageFailureCopyWithImpl;
@override @useResult
$Res call({
 String message
});




}
/// @nodoc
class __$StorageFailureCopyWithImpl<$Res>
    implements _$StorageFailureCopyWith<$Res> {
  __$StorageFailureCopyWithImpl(this._self, this._then);

  final _StorageFailure _self;
  final $Res Function(_StorageFailure) _then;

/// Create a copy of JournalFailure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_StorageFailure(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _NetworkFailure implements JournalFailure {
  const _NetworkFailure(this.message);
  

@override final  String message;

/// Create a copy of JournalFailure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetworkFailureCopyWith<_NetworkFailure> get copyWith => __$NetworkFailureCopyWithImpl<_NetworkFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'JournalFailure.network(message: $message)';
}


}

/// @nodoc
abstract mixin class _$NetworkFailureCopyWith<$Res> implements $JournalFailureCopyWith<$Res> {
  factory _$NetworkFailureCopyWith(_NetworkFailure value, $Res Function(_NetworkFailure) _then) = __$NetworkFailureCopyWithImpl;
@override @useResult
$Res call({
 String message
});




}
/// @nodoc
class __$NetworkFailureCopyWithImpl<$Res>
    implements _$NetworkFailureCopyWith<$Res> {
  __$NetworkFailureCopyWithImpl(this._self, this._then);

  final _NetworkFailure _self;
  final $Res Function(_NetworkFailure) _then;

/// Create a copy of JournalFailure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_NetworkFailure(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _UnknownFailure implements JournalFailure {
  const _UnknownFailure(this.message);
  

@override final  String message;

/// Create a copy of JournalFailure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnknownFailureCopyWith<_UnknownFailure> get copyWith => __$UnknownFailureCopyWithImpl<_UnknownFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnknownFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'JournalFailure.unknown(message: $message)';
}


}

/// @nodoc
abstract mixin class _$UnknownFailureCopyWith<$Res> implements $JournalFailureCopyWith<$Res> {
  factory _$UnknownFailureCopyWith(_UnknownFailure value, $Res Function(_UnknownFailure) _then) = __$UnknownFailureCopyWithImpl;
@override @useResult
$Res call({
 String message
});




}
/// @nodoc
class __$UnknownFailureCopyWithImpl<$Res>
    implements _$UnknownFailureCopyWith<$Res> {
  __$UnknownFailureCopyWithImpl(this._self, this._then);

  final _UnknownFailure _self;
  final $Res Function(_UnknownFailure) _then;

/// Create a copy of JournalFailure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_UnknownFailure(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$JournalWritingState {

 String get title; String get content; String? get selectedMood; String? get moodContext; List<XFile> get selectedImages;// audioRecordings: List<Map>{ path: String, duration: int(ms), timestamp: int(ms) }
//forced comment
 List<Map<String, dynamic>> get audioRecordings; bool get isRecording; Duration get recordingDuration; List<double> get waveAmplitudes; String? get currentlyPlayingAudio; JournalSaveStatus get saveStatus; JournalFailure? get failure; bool get hasUnsavedChanges;
/// Create a copy of JournalWritingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalWritingStateCopyWith<JournalWritingState> get copyWith => _$JournalWritingStateCopyWithImpl<JournalWritingState>(this as JournalWritingState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalWritingState&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.selectedMood, selectedMood) || other.selectedMood == selectedMood)&&(identical(other.moodContext, moodContext) || other.moodContext == moodContext)&&const DeepCollectionEquality().equals(other.selectedImages, selectedImages)&&const DeepCollectionEquality().equals(other.audioRecordings, audioRecordings)&&(identical(other.isRecording, isRecording) || other.isRecording == isRecording)&&(identical(other.recordingDuration, recordingDuration) || other.recordingDuration == recordingDuration)&&const DeepCollectionEquality().equals(other.waveAmplitudes, waveAmplitudes)&&(identical(other.currentlyPlayingAudio, currentlyPlayingAudio) || other.currentlyPlayingAudio == currentlyPlayingAudio)&&(identical(other.saveStatus, saveStatus) || other.saveStatus == saveStatus)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.hasUnsavedChanges, hasUnsavedChanges) || other.hasUnsavedChanges == hasUnsavedChanges));
}


@override
int get hashCode => Object.hash(runtimeType,title,content,selectedMood,moodContext,const DeepCollectionEquality().hash(selectedImages),const DeepCollectionEquality().hash(audioRecordings),isRecording,recordingDuration,const DeepCollectionEquality().hash(waveAmplitudes),currentlyPlayingAudio,saveStatus,failure,hasUnsavedChanges);

@override
String toString() {
  return 'JournalWritingState(title: $title, content: $content, selectedMood: $selectedMood, moodContext: $moodContext, selectedImages: $selectedImages, audioRecordings: $audioRecordings, isRecording: $isRecording, recordingDuration: $recordingDuration, waveAmplitudes: $waveAmplitudes, currentlyPlayingAudio: $currentlyPlayingAudio, saveStatus: $saveStatus, failure: $failure, hasUnsavedChanges: $hasUnsavedChanges)';
}


}

/// @nodoc
abstract mixin class $JournalWritingStateCopyWith<$Res>  {
  factory $JournalWritingStateCopyWith(JournalWritingState value, $Res Function(JournalWritingState) _then) = _$JournalWritingStateCopyWithImpl;
@useResult
$Res call({
 String title, String content, String? selectedMood, String? moodContext, List<XFile> selectedImages, List<Map<String, dynamic>> audioRecordings, bool isRecording, Duration recordingDuration, List<double> waveAmplitudes, String? currentlyPlayingAudio, JournalSaveStatus saveStatus, JournalFailure? failure, bool hasUnsavedChanges
});


$JournalFailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$JournalWritingStateCopyWithImpl<$Res>
    implements $JournalWritingStateCopyWith<$Res> {
  _$JournalWritingStateCopyWithImpl(this._self, this._then);

  final JournalWritingState _self;
  final $Res Function(JournalWritingState) _then;

/// Create a copy of JournalWritingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? content = null,Object? selectedMood = freezed,Object? moodContext = freezed,Object? selectedImages = null,Object? audioRecordings = null,Object? isRecording = null,Object? recordingDuration = null,Object? waveAmplitudes = null,Object? currentlyPlayingAudio = freezed,Object? saveStatus = null,Object? failure = freezed,Object? hasUnsavedChanges = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,selectedMood: freezed == selectedMood ? _self.selectedMood : selectedMood // ignore: cast_nullable_to_non_nullable
as String?,moodContext: freezed == moodContext ? _self.moodContext : moodContext // ignore: cast_nullable_to_non_nullable
as String?,selectedImages: null == selectedImages ? _self.selectedImages : selectedImages // ignore: cast_nullable_to_non_nullable
as List<XFile>,audioRecordings: null == audioRecordings ? _self.audioRecordings : audioRecordings // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,isRecording: null == isRecording ? _self.isRecording : isRecording // ignore: cast_nullable_to_non_nullable
as bool,recordingDuration: null == recordingDuration ? _self.recordingDuration : recordingDuration // ignore: cast_nullable_to_non_nullable
as Duration,waveAmplitudes: null == waveAmplitudes ? _self.waveAmplitudes : waveAmplitudes // ignore: cast_nullable_to_non_nullable
as List<double>,currentlyPlayingAudio: freezed == currentlyPlayingAudio ? _self.currentlyPlayingAudio : currentlyPlayingAudio // ignore: cast_nullable_to_non_nullable
as String?,saveStatus: null == saveStatus ? _self.saveStatus : saveStatus // ignore: cast_nullable_to_non_nullable
as JournalSaveStatus,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as JournalFailure?,hasUnsavedChanges: null == hasUnsavedChanges ? _self.hasUnsavedChanges : hasUnsavedChanges // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of JournalWritingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JournalFailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $JournalFailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}


/// Adds pattern-matching-related methods to [JournalWritingState].
extension JournalWritingStatePatterns on JournalWritingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JournalWritingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JournalWritingState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JournalWritingState value)  $default,){
final _that = this;
switch (_that) {
case _JournalWritingState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JournalWritingState value)?  $default,){
final _that = this;
switch (_that) {
case _JournalWritingState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String content,  String? selectedMood,  String? moodContext,  List<XFile> selectedImages,  List<Map<String, dynamic>> audioRecordings,  bool isRecording,  Duration recordingDuration,  List<double> waveAmplitudes,  String? currentlyPlayingAudio,  JournalSaveStatus saveStatus,  JournalFailure? failure,  bool hasUnsavedChanges)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JournalWritingState() when $default != null:
return $default(_that.title,_that.content,_that.selectedMood,_that.moodContext,_that.selectedImages,_that.audioRecordings,_that.isRecording,_that.recordingDuration,_that.waveAmplitudes,_that.currentlyPlayingAudio,_that.saveStatus,_that.failure,_that.hasUnsavedChanges);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String content,  String? selectedMood,  String? moodContext,  List<XFile> selectedImages,  List<Map<String, dynamic>> audioRecordings,  bool isRecording,  Duration recordingDuration,  List<double> waveAmplitudes,  String? currentlyPlayingAudio,  JournalSaveStatus saveStatus,  JournalFailure? failure,  bool hasUnsavedChanges)  $default,) {final _that = this;
switch (_that) {
case _JournalWritingState():
return $default(_that.title,_that.content,_that.selectedMood,_that.moodContext,_that.selectedImages,_that.audioRecordings,_that.isRecording,_that.recordingDuration,_that.waveAmplitudes,_that.currentlyPlayingAudio,_that.saveStatus,_that.failure,_that.hasUnsavedChanges);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String content,  String? selectedMood,  String? moodContext,  List<XFile> selectedImages,  List<Map<String, dynamic>> audioRecordings,  bool isRecording,  Duration recordingDuration,  List<double> waveAmplitudes,  String? currentlyPlayingAudio,  JournalSaveStatus saveStatus,  JournalFailure? failure,  bool hasUnsavedChanges)?  $default,) {final _that = this;
switch (_that) {
case _JournalWritingState() when $default != null:
return $default(_that.title,_that.content,_that.selectedMood,_that.moodContext,_that.selectedImages,_that.audioRecordings,_that.isRecording,_that.recordingDuration,_that.waveAmplitudes,_that.currentlyPlayingAudio,_that.saveStatus,_that.failure,_that.hasUnsavedChanges);case _:
  return null;

}
}

}

/// @nodoc


class _JournalWritingState extends JournalWritingState {
  const _JournalWritingState({this.title = '', this.content = '', this.selectedMood, this.moodContext, final  List<XFile> selectedImages = const <XFile>[], final  List<Map<String, dynamic>> audioRecordings = const <Map<String, dynamic>>[], this.isRecording = false, this.recordingDuration = Duration.zero, final  List<double> waveAmplitudes = const <double>[], this.currentlyPlayingAudio, this.saveStatus = JournalSaveStatus.idle, this.failure, this.hasUnsavedChanges = false}): _selectedImages = selectedImages,_audioRecordings = audioRecordings,_waveAmplitudes = waveAmplitudes,super._();
  

@override@JsonKey() final  String title;
@override@JsonKey() final  String content;
@override final  String? selectedMood;
@override final  String? moodContext;
 final  List<XFile> _selectedImages;
@override@JsonKey() List<XFile> get selectedImages {
  if (_selectedImages is EqualUnmodifiableListView) return _selectedImages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedImages);
}

// audioRecordings: List<Map>{ path: String, duration: int(ms), timestamp: int(ms) }
//forced comment
 final  List<Map<String, dynamic>> _audioRecordings;
// audioRecordings: List<Map>{ path: String, duration: int(ms), timestamp: int(ms) }
//forced comment
@override@JsonKey() List<Map<String, dynamic>> get audioRecordings {
  if (_audioRecordings is EqualUnmodifiableListView) return _audioRecordings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_audioRecordings);
}

@override@JsonKey() final  bool isRecording;
@override@JsonKey() final  Duration recordingDuration;
 final  List<double> _waveAmplitudes;
@override@JsonKey() List<double> get waveAmplitudes {
  if (_waveAmplitudes is EqualUnmodifiableListView) return _waveAmplitudes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_waveAmplitudes);
}

@override final  String? currentlyPlayingAudio;
@override@JsonKey() final  JournalSaveStatus saveStatus;
@override final  JournalFailure? failure;
@override@JsonKey() final  bool hasUnsavedChanges;

/// Create a copy of JournalWritingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JournalWritingStateCopyWith<_JournalWritingState> get copyWith => __$JournalWritingStateCopyWithImpl<_JournalWritingState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JournalWritingState&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.selectedMood, selectedMood) || other.selectedMood == selectedMood)&&(identical(other.moodContext, moodContext) || other.moodContext == moodContext)&&const DeepCollectionEquality().equals(other._selectedImages, _selectedImages)&&const DeepCollectionEquality().equals(other._audioRecordings, _audioRecordings)&&(identical(other.isRecording, isRecording) || other.isRecording == isRecording)&&(identical(other.recordingDuration, recordingDuration) || other.recordingDuration == recordingDuration)&&const DeepCollectionEquality().equals(other._waveAmplitudes, _waveAmplitudes)&&(identical(other.currentlyPlayingAudio, currentlyPlayingAudio) || other.currentlyPlayingAudio == currentlyPlayingAudio)&&(identical(other.saveStatus, saveStatus) || other.saveStatus == saveStatus)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.hasUnsavedChanges, hasUnsavedChanges) || other.hasUnsavedChanges == hasUnsavedChanges));
}


@override
int get hashCode => Object.hash(runtimeType,title,content,selectedMood,moodContext,const DeepCollectionEquality().hash(_selectedImages),const DeepCollectionEquality().hash(_audioRecordings),isRecording,recordingDuration,const DeepCollectionEquality().hash(_waveAmplitudes),currentlyPlayingAudio,saveStatus,failure,hasUnsavedChanges);

@override
String toString() {
  return 'JournalWritingState(title: $title, content: $content, selectedMood: $selectedMood, moodContext: $moodContext, selectedImages: $selectedImages, audioRecordings: $audioRecordings, isRecording: $isRecording, recordingDuration: $recordingDuration, waveAmplitudes: $waveAmplitudes, currentlyPlayingAudio: $currentlyPlayingAudio, saveStatus: $saveStatus, failure: $failure, hasUnsavedChanges: $hasUnsavedChanges)';
}


}

/// @nodoc
abstract mixin class _$JournalWritingStateCopyWith<$Res> implements $JournalWritingStateCopyWith<$Res> {
  factory _$JournalWritingStateCopyWith(_JournalWritingState value, $Res Function(_JournalWritingState) _then) = __$JournalWritingStateCopyWithImpl;
@override @useResult
$Res call({
 String title, String content, String? selectedMood, String? moodContext, List<XFile> selectedImages, List<Map<String, dynamic>> audioRecordings, bool isRecording, Duration recordingDuration, List<double> waveAmplitudes, String? currentlyPlayingAudio, JournalSaveStatus saveStatus, JournalFailure? failure, bool hasUnsavedChanges
});


@override $JournalFailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$JournalWritingStateCopyWithImpl<$Res>
    implements _$JournalWritingStateCopyWith<$Res> {
  __$JournalWritingStateCopyWithImpl(this._self, this._then);

  final _JournalWritingState _self;
  final $Res Function(_JournalWritingState) _then;

/// Create a copy of JournalWritingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? content = null,Object? selectedMood = freezed,Object? moodContext = freezed,Object? selectedImages = null,Object? audioRecordings = null,Object? isRecording = null,Object? recordingDuration = null,Object? waveAmplitudes = null,Object? currentlyPlayingAudio = freezed,Object? saveStatus = null,Object? failure = freezed,Object? hasUnsavedChanges = null,}) {
  return _then(_JournalWritingState(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,selectedMood: freezed == selectedMood ? _self.selectedMood : selectedMood // ignore: cast_nullable_to_non_nullable
as String?,moodContext: freezed == moodContext ? _self.moodContext : moodContext // ignore: cast_nullable_to_non_nullable
as String?,selectedImages: null == selectedImages ? _self._selectedImages : selectedImages // ignore: cast_nullable_to_non_nullable
as List<XFile>,audioRecordings: null == audioRecordings ? _self._audioRecordings : audioRecordings // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,isRecording: null == isRecording ? _self.isRecording : isRecording // ignore: cast_nullable_to_non_nullable
as bool,recordingDuration: null == recordingDuration ? _self.recordingDuration : recordingDuration // ignore: cast_nullable_to_non_nullable
as Duration,waveAmplitudes: null == waveAmplitudes ? _self._waveAmplitudes : waveAmplitudes // ignore: cast_nullable_to_non_nullable
as List<double>,currentlyPlayingAudio: freezed == currentlyPlayingAudio ? _self.currentlyPlayingAudio : currentlyPlayingAudio // ignore: cast_nullable_to_non_nullable
as String?,saveStatus: null == saveStatus ? _self.saveStatus : saveStatus // ignore: cast_nullable_to_non_nullable
as JournalSaveStatus,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as JournalFailure?,hasUnsavedChanges: null == hasUnsavedChanges ? _self.hasUnsavedChanges : hasUnsavedChanges // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of JournalWritingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JournalFailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $JournalFailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
