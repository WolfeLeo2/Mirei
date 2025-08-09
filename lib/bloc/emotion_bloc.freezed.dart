// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'emotion_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$EmotionEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadInitialMood,
    required TResult Function(String mood) moodSelected,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadInitialMood,
    TResult? Function(String mood)? moodSelected,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadInitialMood,
    TResult Function(String mood)? moodSelected,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadInitialMood value) loadInitialMood,
    required TResult Function(MoodSelected value) moodSelected,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadInitialMood value)? loadInitialMood,
    TResult? Function(MoodSelected value)? moodSelected,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadInitialMood value)? loadInitialMood,
    TResult Function(MoodSelected value)? moodSelected,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EmotionEventCopyWith<$Res> {
  factory $EmotionEventCopyWith(
    EmotionEvent value,
    $Res Function(EmotionEvent) then,
  ) = _$EmotionEventCopyWithImpl<$Res, EmotionEvent>;
}

/// @nodoc
class _$EmotionEventCopyWithImpl<$Res, $Val extends EmotionEvent>
    implements $EmotionEventCopyWith<$Res> {
  _$EmotionEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EmotionEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$LoadInitialMoodImplCopyWith<$Res> {
  factory _$$LoadInitialMoodImplCopyWith(
    _$LoadInitialMoodImpl value,
    $Res Function(_$LoadInitialMoodImpl) then,
  ) = __$$LoadInitialMoodImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadInitialMoodImplCopyWithImpl<$Res>
    extends _$EmotionEventCopyWithImpl<$Res, _$LoadInitialMoodImpl>
    implements _$$LoadInitialMoodImplCopyWith<$Res> {
  __$$LoadInitialMoodImplCopyWithImpl(
    _$LoadInitialMoodImpl _value,
    $Res Function(_$LoadInitialMoodImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EmotionEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadInitialMoodImpl implements LoadInitialMood {
  const _$LoadInitialMoodImpl();

  @override
  String toString() {
    return 'EmotionEvent.loadInitialMood()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadInitialMoodImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadInitialMood,
    required TResult Function(String mood) moodSelected,
  }) {
    return loadInitialMood();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadInitialMood,
    TResult? Function(String mood)? moodSelected,
  }) {
    return loadInitialMood?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadInitialMood,
    TResult Function(String mood)? moodSelected,
    required TResult orElse(),
  }) {
    if (loadInitialMood != null) {
      return loadInitialMood();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadInitialMood value) loadInitialMood,
    required TResult Function(MoodSelected value) moodSelected,
  }) {
    return loadInitialMood(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadInitialMood value)? loadInitialMood,
    TResult? Function(MoodSelected value)? moodSelected,
  }) {
    return loadInitialMood?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadInitialMood value)? loadInitialMood,
    TResult Function(MoodSelected value)? moodSelected,
    required TResult orElse(),
  }) {
    if (loadInitialMood != null) {
      return loadInitialMood(this);
    }
    return orElse();
  }
}

abstract class LoadInitialMood implements EmotionEvent {
  const factory LoadInitialMood() = _$LoadInitialMoodImpl;
}

/// @nodoc
abstract class _$$MoodSelectedImplCopyWith<$Res> {
  factory _$$MoodSelectedImplCopyWith(
    _$MoodSelectedImpl value,
    $Res Function(_$MoodSelectedImpl) then,
  ) = __$$MoodSelectedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String mood});
}

/// @nodoc
class __$$MoodSelectedImplCopyWithImpl<$Res>
    extends _$EmotionEventCopyWithImpl<$Res, _$MoodSelectedImpl>
    implements _$$MoodSelectedImplCopyWith<$Res> {
  __$$MoodSelectedImplCopyWithImpl(
    _$MoodSelectedImpl _value,
    $Res Function(_$MoodSelectedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EmotionEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? mood = null}) {
    return _then(
      _$MoodSelectedImpl(
        null == mood
            ? _value.mood
            : mood // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$MoodSelectedImpl implements MoodSelected {
  const _$MoodSelectedImpl(this.mood);

  @override
  final String mood;

  @override
  String toString() {
    return 'EmotionEvent.moodSelected(mood: $mood)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MoodSelectedImpl &&
            (identical(other.mood, mood) || other.mood == mood));
  }

  @override
  int get hashCode => Object.hash(runtimeType, mood);

  /// Create a copy of EmotionEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MoodSelectedImplCopyWith<_$MoodSelectedImpl> get copyWith =>
      __$$MoodSelectedImplCopyWithImpl<_$MoodSelectedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadInitialMood,
    required TResult Function(String mood) moodSelected,
  }) {
    return moodSelected(mood);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadInitialMood,
    TResult? Function(String mood)? moodSelected,
  }) {
    return moodSelected?.call(mood);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadInitialMood,
    TResult Function(String mood)? moodSelected,
    required TResult orElse(),
  }) {
    if (moodSelected != null) {
      return moodSelected(mood);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadInitialMood value) loadInitialMood,
    required TResult Function(MoodSelected value) moodSelected,
  }) {
    return moodSelected(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadInitialMood value)? loadInitialMood,
    TResult? Function(MoodSelected value)? moodSelected,
  }) {
    return moodSelected?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadInitialMood value)? loadInitialMood,
    TResult Function(MoodSelected value)? moodSelected,
    required TResult orElse(),
  }) {
    if (moodSelected != null) {
      return moodSelected(this);
    }
    return orElse();
  }
}

abstract class MoodSelected implements EmotionEvent {
  const factory MoodSelected(final String mood) = _$MoodSelectedImpl;

  String get mood;

  /// Create a copy of EmotionEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MoodSelectedImplCopyWith<_$MoodSelectedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$EmotionState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loadInProgress,
    required TResult Function(List<String> allEmotions, String selectedMood)
    loadSuccess,
    required TResult Function(String error) loadFailure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loadInProgress,
    TResult? Function(List<String> allEmotions, String selectedMood)?
    loadSuccess,
    TResult? Function(String error)? loadFailure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loadInProgress,
    TResult Function(List<String> allEmotions, String selectedMood)?
    loadSuccess,
    TResult Function(String error)? loadFailure,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EmotionInitial value) initial,
    required TResult Function(EmotionLoadInProgress value) loadInProgress,
    required TResult Function(EmotionLoadSuccess value) loadSuccess,
    required TResult Function(EmotionLoadFailure value) loadFailure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EmotionInitial value)? initial,
    TResult? Function(EmotionLoadInProgress value)? loadInProgress,
    TResult? Function(EmotionLoadSuccess value)? loadSuccess,
    TResult? Function(EmotionLoadFailure value)? loadFailure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EmotionInitial value)? initial,
    TResult Function(EmotionLoadInProgress value)? loadInProgress,
    TResult Function(EmotionLoadSuccess value)? loadSuccess,
    TResult Function(EmotionLoadFailure value)? loadFailure,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EmotionStateCopyWith<$Res> {
  factory $EmotionStateCopyWith(
    EmotionState value,
    $Res Function(EmotionState) then,
  ) = _$EmotionStateCopyWithImpl<$Res, EmotionState>;
}

/// @nodoc
class _$EmotionStateCopyWithImpl<$Res, $Val extends EmotionState>
    implements $EmotionStateCopyWith<$Res> {
  _$EmotionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EmotionState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$EmotionInitialImplCopyWith<$Res> {
  factory _$$EmotionInitialImplCopyWith(
    _$EmotionInitialImpl value,
    $Res Function(_$EmotionInitialImpl) then,
  ) = __$$EmotionInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$EmotionInitialImplCopyWithImpl<$Res>
    extends _$EmotionStateCopyWithImpl<$Res, _$EmotionInitialImpl>
    implements _$$EmotionInitialImplCopyWith<$Res> {
  __$$EmotionInitialImplCopyWithImpl(
    _$EmotionInitialImpl _value,
    $Res Function(_$EmotionInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EmotionState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$EmotionInitialImpl implements EmotionInitial {
  const _$EmotionInitialImpl();

  @override
  String toString() {
    return 'EmotionState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$EmotionInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loadInProgress,
    required TResult Function(List<String> allEmotions, String selectedMood)
    loadSuccess,
    required TResult Function(String error) loadFailure,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loadInProgress,
    TResult? Function(List<String> allEmotions, String selectedMood)?
    loadSuccess,
    TResult? Function(String error)? loadFailure,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loadInProgress,
    TResult Function(List<String> allEmotions, String selectedMood)?
    loadSuccess,
    TResult Function(String error)? loadFailure,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EmotionInitial value) initial,
    required TResult Function(EmotionLoadInProgress value) loadInProgress,
    required TResult Function(EmotionLoadSuccess value) loadSuccess,
    required TResult Function(EmotionLoadFailure value) loadFailure,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EmotionInitial value)? initial,
    TResult? Function(EmotionLoadInProgress value)? loadInProgress,
    TResult? Function(EmotionLoadSuccess value)? loadSuccess,
    TResult? Function(EmotionLoadFailure value)? loadFailure,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EmotionInitial value)? initial,
    TResult Function(EmotionLoadInProgress value)? loadInProgress,
    TResult Function(EmotionLoadSuccess value)? loadSuccess,
    TResult Function(EmotionLoadFailure value)? loadFailure,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class EmotionInitial implements EmotionState {
  const factory EmotionInitial() = _$EmotionInitialImpl;
}

/// @nodoc
abstract class _$$EmotionLoadInProgressImplCopyWith<$Res> {
  factory _$$EmotionLoadInProgressImplCopyWith(
    _$EmotionLoadInProgressImpl value,
    $Res Function(_$EmotionLoadInProgressImpl) then,
  ) = __$$EmotionLoadInProgressImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$EmotionLoadInProgressImplCopyWithImpl<$Res>
    extends _$EmotionStateCopyWithImpl<$Res, _$EmotionLoadInProgressImpl>
    implements _$$EmotionLoadInProgressImplCopyWith<$Res> {
  __$$EmotionLoadInProgressImplCopyWithImpl(
    _$EmotionLoadInProgressImpl _value,
    $Res Function(_$EmotionLoadInProgressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EmotionState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$EmotionLoadInProgressImpl implements EmotionLoadInProgress {
  const _$EmotionLoadInProgressImpl();

  @override
  String toString() {
    return 'EmotionState.loadInProgress()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EmotionLoadInProgressImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loadInProgress,
    required TResult Function(List<String> allEmotions, String selectedMood)
    loadSuccess,
    required TResult Function(String error) loadFailure,
  }) {
    return loadInProgress();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loadInProgress,
    TResult? Function(List<String> allEmotions, String selectedMood)?
    loadSuccess,
    TResult? Function(String error)? loadFailure,
  }) {
    return loadInProgress?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loadInProgress,
    TResult Function(List<String> allEmotions, String selectedMood)?
    loadSuccess,
    TResult Function(String error)? loadFailure,
    required TResult orElse(),
  }) {
    if (loadInProgress != null) {
      return loadInProgress();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EmotionInitial value) initial,
    required TResult Function(EmotionLoadInProgress value) loadInProgress,
    required TResult Function(EmotionLoadSuccess value) loadSuccess,
    required TResult Function(EmotionLoadFailure value) loadFailure,
  }) {
    return loadInProgress(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EmotionInitial value)? initial,
    TResult? Function(EmotionLoadInProgress value)? loadInProgress,
    TResult? Function(EmotionLoadSuccess value)? loadSuccess,
    TResult? Function(EmotionLoadFailure value)? loadFailure,
  }) {
    return loadInProgress?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EmotionInitial value)? initial,
    TResult Function(EmotionLoadInProgress value)? loadInProgress,
    TResult Function(EmotionLoadSuccess value)? loadSuccess,
    TResult Function(EmotionLoadFailure value)? loadFailure,
    required TResult orElse(),
  }) {
    if (loadInProgress != null) {
      return loadInProgress(this);
    }
    return orElse();
  }
}

abstract class EmotionLoadInProgress implements EmotionState {
  const factory EmotionLoadInProgress() = _$EmotionLoadInProgressImpl;
}

/// @nodoc
abstract class _$$EmotionLoadSuccessImplCopyWith<$Res> {
  factory _$$EmotionLoadSuccessImplCopyWith(
    _$EmotionLoadSuccessImpl value,
    $Res Function(_$EmotionLoadSuccessImpl) then,
  ) = __$$EmotionLoadSuccessImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<String> allEmotions, String selectedMood});
}

/// @nodoc
class __$$EmotionLoadSuccessImplCopyWithImpl<$Res>
    extends _$EmotionStateCopyWithImpl<$Res, _$EmotionLoadSuccessImpl>
    implements _$$EmotionLoadSuccessImplCopyWith<$Res> {
  __$$EmotionLoadSuccessImplCopyWithImpl(
    _$EmotionLoadSuccessImpl _value,
    $Res Function(_$EmotionLoadSuccessImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EmotionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? allEmotions = null, Object? selectedMood = null}) {
    return _then(
      _$EmotionLoadSuccessImpl(
        allEmotions: null == allEmotions
            ? _value._allEmotions
            : allEmotions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        selectedMood: null == selectedMood
            ? _value.selectedMood
            : selectedMood // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$EmotionLoadSuccessImpl implements EmotionLoadSuccess {
  const _$EmotionLoadSuccessImpl({
    required final List<String> allEmotions,
    required this.selectedMood,
  }) : _allEmotions = allEmotions;

  final List<String> _allEmotions;
  @override
  List<String> get allEmotions {
    if (_allEmotions is EqualUnmodifiableListView) return _allEmotions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allEmotions);
  }

  @override
  final String selectedMood;

  @override
  String toString() {
    return 'EmotionState.loadSuccess(allEmotions: $allEmotions, selectedMood: $selectedMood)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EmotionLoadSuccessImpl &&
            const DeepCollectionEquality().equals(
              other._allEmotions,
              _allEmotions,
            ) &&
            (identical(other.selectedMood, selectedMood) ||
                other.selectedMood == selectedMood));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_allEmotions),
    selectedMood,
  );

  /// Create a copy of EmotionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EmotionLoadSuccessImplCopyWith<_$EmotionLoadSuccessImpl> get copyWith =>
      __$$EmotionLoadSuccessImplCopyWithImpl<_$EmotionLoadSuccessImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loadInProgress,
    required TResult Function(List<String> allEmotions, String selectedMood)
    loadSuccess,
    required TResult Function(String error) loadFailure,
  }) {
    return loadSuccess(allEmotions, selectedMood);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loadInProgress,
    TResult? Function(List<String> allEmotions, String selectedMood)?
    loadSuccess,
    TResult? Function(String error)? loadFailure,
  }) {
    return loadSuccess?.call(allEmotions, selectedMood);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loadInProgress,
    TResult Function(List<String> allEmotions, String selectedMood)?
    loadSuccess,
    TResult Function(String error)? loadFailure,
    required TResult orElse(),
  }) {
    if (loadSuccess != null) {
      return loadSuccess(allEmotions, selectedMood);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EmotionInitial value) initial,
    required TResult Function(EmotionLoadInProgress value) loadInProgress,
    required TResult Function(EmotionLoadSuccess value) loadSuccess,
    required TResult Function(EmotionLoadFailure value) loadFailure,
  }) {
    return loadSuccess(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EmotionInitial value)? initial,
    TResult? Function(EmotionLoadInProgress value)? loadInProgress,
    TResult? Function(EmotionLoadSuccess value)? loadSuccess,
    TResult? Function(EmotionLoadFailure value)? loadFailure,
  }) {
    return loadSuccess?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EmotionInitial value)? initial,
    TResult Function(EmotionLoadInProgress value)? loadInProgress,
    TResult Function(EmotionLoadSuccess value)? loadSuccess,
    TResult Function(EmotionLoadFailure value)? loadFailure,
    required TResult orElse(),
  }) {
    if (loadSuccess != null) {
      return loadSuccess(this);
    }
    return orElse();
  }
}

abstract class EmotionLoadSuccess implements EmotionState {
  const factory EmotionLoadSuccess({
    required final List<String> allEmotions,
    required final String selectedMood,
  }) = _$EmotionLoadSuccessImpl;

  List<String> get allEmotions;
  String get selectedMood;

  /// Create a copy of EmotionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EmotionLoadSuccessImplCopyWith<_$EmotionLoadSuccessImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$EmotionLoadFailureImplCopyWith<$Res> {
  factory _$$EmotionLoadFailureImplCopyWith(
    _$EmotionLoadFailureImpl value,
    $Res Function(_$EmotionLoadFailureImpl) then,
  ) = __$$EmotionLoadFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String error});
}

/// @nodoc
class __$$EmotionLoadFailureImplCopyWithImpl<$Res>
    extends _$EmotionStateCopyWithImpl<$Res, _$EmotionLoadFailureImpl>
    implements _$$EmotionLoadFailureImplCopyWith<$Res> {
  __$$EmotionLoadFailureImplCopyWithImpl(
    _$EmotionLoadFailureImpl _value,
    $Res Function(_$EmotionLoadFailureImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EmotionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? error = null}) {
    return _then(
      _$EmotionLoadFailureImpl(
        null == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$EmotionLoadFailureImpl implements EmotionLoadFailure {
  const _$EmotionLoadFailureImpl(this.error);

  @override
  final String error;

  @override
  String toString() {
    return 'EmotionState.loadFailure(error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EmotionLoadFailureImpl &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, error);

  /// Create a copy of EmotionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EmotionLoadFailureImplCopyWith<_$EmotionLoadFailureImpl> get copyWith =>
      __$$EmotionLoadFailureImplCopyWithImpl<_$EmotionLoadFailureImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loadInProgress,
    required TResult Function(List<String> allEmotions, String selectedMood)
    loadSuccess,
    required TResult Function(String error) loadFailure,
  }) {
    return loadFailure(error);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loadInProgress,
    TResult? Function(List<String> allEmotions, String selectedMood)?
    loadSuccess,
    TResult? Function(String error)? loadFailure,
  }) {
    return loadFailure?.call(error);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loadInProgress,
    TResult Function(List<String> allEmotions, String selectedMood)?
    loadSuccess,
    TResult Function(String error)? loadFailure,
    required TResult orElse(),
  }) {
    if (loadFailure != null) {
      return loadFailure(error);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EmotionInitial value) initial,
    required TResult Function(EmotionLoadInProgress value) loadInProgress,
    required TResult Function(EmotionLoadSuccess value) loadSuccess,
    required TResult Function(EmotionLoadFailure value) loadFailure,
  }) {
    return loadFailure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EmotionInitial value)? initial,
    TResult? Function(EmotionLoadInProgress value)? loadInProgress,
    TResult? Function(EmotionLoadSuccess value)? loadSuccess,
    TResult? Function(EmotionLoadFailure value)? loadFailure,
  }) {
    return loadFailure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EmotionInitial value)? initial,
    TResult Function(EmotionLoadInProgress value)? loadInProgress,
    TResult Function(EmotionLoadSuccess value)? loadSuccess,
    TResult Function(EmotionLoadFailure value)? loadFailure,
    required TResult orElse(),
  }) {
    if (loadFailure != null) {
      return loadFailure(this);
    }
    return orElse();
  }
}

abstract class EmotionLoadFailure implements EmotionState {
  const factory EmotionLoadFailure(final String error) =
      _$EmotionLoadFailureImpl;

  String get error;

  /// Create a copy of EmotionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EmotionLoadFailureImplCopyWith<_$EmotionLoadFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
