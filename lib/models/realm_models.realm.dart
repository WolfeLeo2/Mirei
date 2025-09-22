// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realm_models.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class UserProfileRealm extends _UserProfileRealm
    with RealmEntity, RealmObjectBase, RealmObject {
  UserProfileRealm(
    String uid,
    String email,
    String provider,
    bool isEmailVerified,
    DateTime lastUpdated,
    DateTime createdAt, {
    String? displayName,
    String? photoURL,
    String? customAvatarUrl,
  }) {
    RealmObjectBase.set(this, 'uid', uid);
    RealmObjectBase.set(this, 'email', email);
    RealmObjectBase.set(this, 'displayName', displayName);
    RealmObjectBase.set(this, 'photoURL', photoURL);
    RealmObjectBase.set(this, 'customAvatarUrl', customAvatarUrl);
    RealmObjectBase.set(this, 'provider', provider);
    RealmObjectBase.set(this, 'isEmailVerified', isEmailVerified);
    RealmObjectBase.set(this, 'lastUpdated', lastUpdated);
    RealmObjectBase.set(this, 'createdAt', createdAt);
  }

  UserProfileRealm._();

  @override
  String get uid => RealmObjectBase.get<String>(this, 'uid') as String;
  @override
  set uid(String value) => RealmObjectBase.set(this, 'uid', value);

  @override
  String get email => RealmObjectBase.get<String>(this, 'email') as String;
  @override
  set email(String value) => RealmObjectBase.set(this, 'email', value);

  @override
  String? get displayName =>
      RealmObjectBase.get<String>(this, 'displayName') as String?;
  @override
  set displayName(String? value) =>
      RealmObjectBase.set(this, 'displayName', value);

  @override
  String? get photoURL =>
      RealmObjectBase.get<String>(this, 'photoURL') as String?;
  @override
  set photoURL(String? value) => RealmObjectBase.set(this, 'photoURL', value);

  @override
  String? get customAvatarUrl =>
      RealmObjectBase.get<String>(this, 'customAvatarUrl') as String?;
  @override
  set customAvatarUrl(String? value) =>
      RealmObjectBase.set(this, 'customAvatarUrl', value);

  @override
  String get provider =>
      RealmObjectBase.get<String>(this, 'provider') as String;
  @override
  set provider(String value) => RealmObjectBase.set(this, 'provider', value);

  @override
  bool get isEmailVerified =>
      RealmObjectBase.get<bool>(this, 'isEmailVerified') as bool;
  @override
  set isEmailVerified(bool value) =>
      RealmObjectBase.set(this, 'isEmailVerified', value);

  @override
  DateTime get lastUpdated =>
      RealmObjectBase.get<DateTime>(this, 'lastUpdated') as DateTime;
  @override
  set lastUpdated(DateTime value) =>
      RealmObjectBase.set(this, 'lastUpdated', value);

  @override
  DateTime get createdAt =>
      RealmObjectBase.get<DateTime>(this, 'createdAt') as DateTime;
  @override
  set createdAt(DateTime value) =>
      RealmObjectBase.set(this, 'createdAt', value);

  @override
  Stream<RealmObjectChanges<UserProfileRealm>> get changes =>
      RealmObjectBase.getChanges<UserProfileRealm>(this);

  @override
  Stream<RealmObjectChanges<UserProfileRealm>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<UserProfileRealm>(this, keyPaths);

  @override
  UserProfileRealm freeze() =>
      RealmObjectBase.freezeObject<UserProfileRealm>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'uid': uid.toEJson(),
      'email': email.toEJson(),
      'displayName': displayName.toEJson(),
      'photoURL': photoURL.toEJson(),
      'customAvatarUrl': customAvatarUrl.toEJson(),
      'provider': provider.toEJson(),
      'isEmailVerified': isEmailVerified.toEJson(),
      'lastUpdated': lastUpdated.toEJson(),
      'createdAt': createdAt.toEJson(),
    };
  }

  static EJsonValue _toEJson(UserProfileRealm value) => value.toEJson();
  static UserProfileRealm _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'uid': EJsonValue uid,
        'email': EJsonValue email,
        'provider': EJsonValue provider,
        'isEmailVerified': EJsonValue isEmailVerified,
        'lastUpdated': EJsonValue lastUpdated,
        'createdAt': EJsonValue createdAt,
      } =>
        UserProfileRealm(
          fromEJson(uid),
          fromEJson(email),
          fromEJson(provider),
          fromEJson(isEmailVerified),
          fromEJson(lastUpdated),
          fromEJson(createdAt),
          displayName: fromEJson(ejson['displayName']),
          photoURL: fromEJson(ejson['photoURL']),
          customAvatarUrl: fromEJson(ejson['customAvatarUrl']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(UserProfileRealm._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      UserProfileRealm,
      'UserProfileRealm',
      [
        SchemaProperty('uid', RealmPropertyType.string, primaryKey: true),
        SchemaProperty('email', RealmPropertyType.string),
        SchemaProperty('displayName', RealmPropertyType.string, optional: true),
        SchemaProperty('photoURL', RealmPropertyType.string, optional: true),
        SchemaProperty(
          'customAvatarUrl',
          RealmPropertyType.string,
          optional: true,
        ),
        SchemaProperty('provider', RealmPropertyType.string),
        SchemaProperty('isEmailVerified', RealmPropertyType.bool),
        SchemaProperty('lastUpdated', RealmPropertyType.timestamp),
        SchemaProperty('createdAt', RealmPropertyType.timestamp),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class MoodEntryRealm extends _MoodEntryRealm
    with RealmEntity, RealmObjectBase, RealmObject {
  MoodEntryRealm(
    ObjectId id,
    String mood,
    DateTime createdAt, {
    String? note,
    int? intensity,
    String? context,
    String? triggers,
    String? activities,
    String? location,
    String? checkInType,
    int? sequenceNumber,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'mood', mood);
    RealmObjectBase.set(this, 'createdAt', createdAt);
    RealmObjectBase.set(this, 'note', note);
    RealmObjectBase.set(this, 'intensity', intensity);
    RealmObjectBase.set(this, 'context', context);
    RealmObjectBase.set(this, 'triggers', triggers);
    RealmObjectBase.set(this, 'activities', activities);
    RealmObjectBase.set(this, 'location', location);
    RealmObjectBase.set(this, 'checkInType', checkInType);
    RealmObjectBase.set(this, 'sequenceNumber', sequenceNumber);
  }

  MoodEntryRealm._();

  @override
  ObjectId get id => RealmObjectBase.get<ObjectId>(this, 'id') as ObjectId;
  @override
  set id(ObjectId value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get mood => RealmObjectBase.get<String>(this, 'mood') as String;
  @override
  set mood(String value) => RealmObjectBase.set(this, 'mood', value);

  @override
  DateTime get createdAt =>
      RealmObjectBase.get<DateTime>(this, 'createdAt') as DateTime;
  @override
  set createdAt(DateTime value) =>
      RealmObjectBase.set(this, 'createdAt', value);

  @override
  String? get note => RealmObjectBase.get<String>(this, 'note') as String?;
  @override
  set note(String? value) => RealmObjectBase.set(this, 'note', value);

  @override
  int? get intensity => RealmObjectBase.get<int>(this, 'intensity') as int?;
  @override
  set intensity(int? value) => RealmObjectBase.set(this, 'intensity', value);

  @override
  String? get context =>
      RealmObjectBase.get<String>(this, 'context') as String?;
  @override
  set context(String? value) => RealmObjectBase.set(this, 'context', value);

  @override
  String? get triggers =>
      RealmObjectBase.get<String>(this, 'triggers') as String?;
  @override
  set triggers(String? value) => RealmObjectBase.set(this, 'triggers', value);

  @override
  String? get activities =>
      RealmObjectBase.get<String>(this, 'activities') as String?;
  @override
  set activities(String? value) =>
      RealmObjectBase.set(this, 'activities', value);

  @override
  String? get location =>
      RealmObjectBase.get<String>(this, 'location') as String?;
  @override
  set location(String? value) => RealmObjectBase.set(this, 'location', value);

  @override
  String? get checkInType =>
      RealmObjectBase.get<String>(this, 'checkInType') as String?;
  @override
  set checkInType(String? value) =>
      RealmObjectBase.set(this, 'checkInType', value);

  @override
  int? get sequenceNumber =>
      RealmObjectBase.get<int>(this, 'sequenceNumber') as int?;
  @override
  set sequenceNumber(int? value) =>
      RealmObjectBase.set(this, 'sequenceNumber', value);

  @override
  Stream<RealmObjectChanges<MoodEntryRealm>> get changes =>
      RealmObjectBase.getChanges<MoodEntryRealm>(this);

  @override
  Stream<RealmObjectChanges<MoodEntryRealm>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<MoodEntryRealm>(this, keyPaths);

  @override
  MoodEntryRealm freeze() => RealmObjectBase.freezeObject<MoodEntryRealm>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'mood': mood.toEJson(),
      'createdAt': createdAt.toEJson(),
      'note': note.toEJson(),
      'intensity': intensity.toEJson(),
      'context': context.toEJson(),
      'triggers': triggers.toEJson(),
      'activities': activities.toEJson(),
      'location': location.toEJson(),
      'checkInType': checkInType.toEJson(),
      'sequenceNumber': sequenceNumber.toEJson(),
    };
  }

  static EJsonValue _toEJson(MoodEntryRealm value) => value.toEJson();
  static MoodEntryRealm _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'mood': EJsonValue mood,
        'createdAt': EJsonValue createdAt,
      } =>
        MoodEntryRealm(
          fromEJson(id),
          fromEJson(mood),
          fromEJson(createdAt),
          note: fromEJson(ejson['note']),
          intensity: fromEJson(ejson['intensity']),
          context: fromEJson(ejson['context']),
          triggers: fromEJson(ejson['triggers']),
          activities: fromEJson(ejson['activities']),
          location: fromEJson(ejson['location']),
          checkInType: fromEJson(ejson['checkInType']),
          sequenceNumber: fromEJson(ejson['sequenceNumber']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(MoodEntryRealm._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      MoodEntryRealm,
      'MoodEntryRealm',
      [
        SchemaProperty('id', RealmPropertyType.objectid, primaryKey: true),
        SchemaProperty('mood', RealmPropertyType.string),
        SchemaProperty(
          'createdAt',
          RealmPropertyType.timestamp,
          indexType: RealmIndexType.regular,
        ),
        SchemaProperty('note', RealmPropertyType.string, optional: true),
        SchemaProperty('intensity', RealmPropertyType.int, optional: true),
        SchemaProperty('context', RealmPropertyType.string, optional: true),
        SchemaProperty('triggers', RealmPropertyType.string, optional: true),
        SchemaProperty('activities', RealmPropertyType.string, optional: true),
        SchemaProperty('location', RealmPropertyType.string, optional: true),
        SchemaProperty('checkInType', RealmPropertyType.string, optional: true),
        SchemaProperty('sequenceNumber', RealmPropertyType.int, optional: true),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class JournalEntryRealm extends _JournalEntryRealm
    with RealmEntity, RealmObjectBase, RealmObject {
  JournalEntryRealm(
    ObjectId id,
    String title,
    String content,
    DateTime createdAt, {
    String? imagePathsString,
    String? audioRecordingsString,
    String? entryMood,
    int? entryMoodIntensity,
    String? entryMoodContext,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'title', title);
    RealmObjectBase.set(this, 'content', content);
    RealmObjectBase.set(this, 'createdAt', createdAt);
    RealmObjectBase.set(this, 'imagePathsString', imagePathsString);
    RealmObjectBase.set(this, 'audioRecordingsString', audioRecordingsString);
    RealmObjectBase.set(this, 'entryMood', entryMood);
    RealmObjectBase.set(this, 'entryMoodIntensity', entryMoodIntensity);
    RealmObjectBase.set(this, 'entryMoodContext', entryMoodContext);
  }

  JournalEntryRealm._();

  @override
  ObjectId get id => RealmObjectBase.get<ObjectId>(this, 'id') as ObjectId;
  @override
  set id(ObjectId value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get title => RealmObjectBase.get<String>(this, 'title') as String;
  @override
  set title(String value) => RealmObjectBase.set(this, 'title', value);

  @override
  String get content => RealmObjectBase.get<String>(this, 'content') as String;
  @override
  set content(String value) => RealmObjectBase.set(this, 'content', value);

  @override
  DateTime get createdAt =>
      RealmObjectBase.get<DateTime>(this, 'createdAt') as DateTime;
  @override
  set createdAt(DateTime value) =>
      RealmObjectBase.set(this, 'createdAt', value);

  @override
  String? get imagePathsString =>
      RealmObjectBase.get<String>(this, 'imagePathsString') as String?;
  @override
  set imagePathsString(String? value) =>
      RealmObjectBase.set(this, 'imagePathsString', value);

  @override
  String? get audioRecordingsString =>
      RealmObjectBase.get<String>(this, 'audioRecordingsString') as String?;
  @override
  set audioRecordingsString(String? value) =>
      RealmObjectBase.set(this, 'audioRecordingsString', value);

  @override
  String? get entryMood =>
      RealmObjectBase.get<String>(this, 'entryMood') as String?;
  @override
  set entryMood(String? value) => RealmObjectBase.set(this, 'entryMood', value);

  @override
  int? get entryMoodIntensity =>
      RealmObjectBase.get<int>(this, 'entryMoodIntensity') as int?;
  @override
  set entryMoodIntensity(int? value) =>
      RealmObjectBase.set(this, 'entryMoodIntensity', value);

  @override
  String? get entryMoodContext =>
      RealmObjectBase.get<String>(this, 'entryMoodContext') as String?;
  @override
  set entryMoodContext(String? value) =>
      RealmObjectBase.set(this, 'entryMoodContext', value);

  @override
  Stream<RealmObjectChanges<JournalEntryRealm>> get changes =>
      RealmObjectBase.getChanges<JournalEntryRealm>(this);

  @override
  Stream<RealmObjectChanges<JournalEntryRealm>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<JournalEntryRealm>(this, keyPaths);

  @override
  JournalEntryRealm freeze() =>
      RealmObjectBase.freezeObject<JournalEntryRealm>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'title': title.toEJson(),
      'content': content.toEJson(),
      'createdAt': createdAt.toEJson(),
      'imagePathsString': imagePathsString.toEJson(),
      'audioRecordingsString': audioRecordingsString.toEJson(),
      'entryMood': entryMood.toEJson(),
      'entryMoodIntensity': entryMoodIntensity.toEJson(),
      'entryMoodContext': entryMoodContext.toEJson(),
    };
  }

  static EJsonValue _toEJson(JournalEntryRealm value) => value.toEJson();
  static JournalEntryRealm _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'title': EJsonValue title,
        'content': EJsonValue content,
        'createdAt': EJsonValue createdAt,
      } =>
        JournalEntryRealm(
          fromEJson(id),
          fromEJson(title),
          fromEJson(content),
          fromEJson(createdAt),
          imagePathsString: fromEJson(ejson['imagePathsString']),
          audioRecordingsString: fromEJson(ejson['audioRecordingsString']),
          entryMood: fromEJson(ejson['entryMood']),
          entryMoodIntensity: fromEJson(ejson['entryMoodIntensity']),
          entryMoodContext: fromEJson(ejson['entryMoodContext']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(JournalEntryRealm._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      JournalEntryRealm,
      'JournalEntryRealm',
      [
        SchemaProperty('id', RealmPropertyType.objectid, primaryKey: true),
        SchemaProperty('title', RealmPropertyType.string),
        SchemaProperty('content', RealmPropertyType.string),
        SchemaProperty(
          'createdAt',
          RealmPropertyType.timestamp,
          indexType: RealmIndexType.regular,
        ),
        SchemaProperty(
          'imagePathsString',
          RealmPropertyType.string,
          optional: true,
        ),
        SchemaProperty(
          'audioRecordingsString',
          RealmPropertyType.string,
          optional: true,
        ),
        SchemaProperty('entryMood', RealmPropertyType.string, optional: true),
        SchemaProperty(
          'entryMoodIntensity',
          RealmPropertyType.int,
          optional: true,
        ),
        SchemaProperty(
          'entryMoodContext',
          RealmPropertyType.string,
          optional: true,
        ),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
