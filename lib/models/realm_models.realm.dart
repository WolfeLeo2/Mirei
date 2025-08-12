// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realm_models.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class MoodEntryRealm extends _MoodEntryRealm
    with RealmEntity, RealmObjectBase, RealmObject {
  MoodEntryRealm(ObjectId id, String mood, DateTime createdAt, {String? note}) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'mood', mood);
    RealmObjectBase.set(this, 'createdAt', createdAt);
    RealmObjectBase.set(this, 'note', note);
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
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'title', title);
    RealmObjectBase.set(this, 'content', content);
    RealmObjectBase.set(this, 'createdAt', createdAt);
    RealmObjectBase.set(this, 'imagePathsString', imagePathsString);
    RealmObjectBase.set(this, 'audioRecordingsString', audioRecordingsString);
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
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class AudioCacheEntry extends _AudioCacheEntry
    with RealmEntity, RealmObjectBase, RealmObject {
  AudioCacheEntry(
    String url,
    String localPath,
    DateTime cachedAt,
    DateTime lastAccessed,
    int sizeBytes,
    int accessCount,
    bool isComplete, {
    String? mimeType,
  }) {
    RealmObjectBase.set(this, 'url', url);
    RealmObjectBase.set(this, 'localPath', localPath);
    RealmObjectBase.set(this, 'cachedAt', cachedAt);
    RealmObjectBase.set(this, 'lastAccessed', lastAccessed);
    RealmObjectBase.set(this, 'sizeBytes', sizeBytes);
    RealmObjectBase.set(this, 'mimeType', mimeType);
    RealmObjectBase.set(this, 'accessCount', accessCount);
    RealmObjectBase.set(this, 'isComplete', isComplete);
  }

  AudioCacheEntry._();

  @override
  String get url => RealmObjectBase.get<String>(this, 'url') as String;
  @override
  set url(String value) => RealmObjectBase.set(this, 'url', value);

  @override
  String get localPath =>
      RealmObjectBase.get<String>(this, 'localPath') as String;
  @override
  set localPath(String value) => RealmObjectBase.set(this, 'localPath', value);

  @override
  DateTime get cachedAt =>
      RealmObjectBase.get<DateTime>(this, 'cachedAt') as DateTime;
  @override
  set cachedAt(DateTime value) => RealmObjectBase.set(this, 'cachedAt', value);

  @override
  DateTime get lastAccessed =>
      RealmObjectBase.get<DateTime>(this, 'lastAccessed') as DateTime;
  @override
  set lastAccessed(DateTime value) =>
      RealmObjectBase.set(this, 'lastAccessed', value);

  @override
  int get sizeBytes => RealmObjectBase.get<int>(this, 'sizeBytes') as int;
  @override
  set sizeBytes(int value) => RealmObjectBase.set(this, 'sizeBytes', value);

  @override
  String? get mimeType =>
      RealmObjectBase.get<String>(this, 'mimeType') as String?;
  @override
  set mimeType(String? value) => RealmObjectBase.set(this, 'mimeType', value);

  @override
  int get accessCount => RealmObjectBase.get<int>(this, 'accessCount') as int;
  @override
  set accessCount(int value) => RealmObjectBase.set(this, 'accessCount', value);

  @override
  bool get isComplete => RealmObjectBase.get<bool>(this, 'isComplete') as bool;
  @override
  set isComplete(bool value) => RealmObjectBase.set(this, 'isComplete', value);

  @override
  Stream<RealmObjectChanges<AudioCacheEntry>> get changes =>
      RealmObjectBase.getChanges<AudioCacheEntry>(this);

  @override
  Stream<RealmObjectChanges<AudioCacheEntry>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<AudioCacheEntry>(this, keyPaths);

  @override
  AudioCacheEntry freeze() =>
      RealmObjectBase.freezeObject<AudioCacheEntry>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'url': url.toEJson(),
      'localPath': localPath.toEJson(),
      'cachedAt': cachedAt.toEJson(),
      'lastAccessed': lastAccessed.toEJson(),
      'sizeBytes': sizeBytes.toEJson(),
      'mimeType': mimeType.toEJson(),
      'accessCount': accessCount.toEJson(),
      'isComplete': isComplete.toEJson(),
    };
  }

  static EJsonValue _toEJson(AudioCacheEntry value) => value.toEJson();
  static AudioCacheEntry _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'url': EJsonValue url,
        'localPath': EJsonValue localPath,
        'cachedAt': EJsonValue cachedAt,
        'lastAccessed': EJsonValue lastAccessed,
        'sizeBytes': EJsonValue sizeBytes,
        'accessCount': EJsonValue accessCount,
        'isComplete': EJsonValue isComplete,
      } =>
        AudioCacheEntry(
          fromEJson(url),
          fromEJson(localPath),
          fromEJson(cachedAt),
          fromEJson(lastAccessed),
          fromEJson(sizeBytes),
          fromEJson(accessCount),
          fromEJson(isComplete),
          mimeType: fromEJson(ejson['mimeType']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(AudioCacheEntry._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      AudioCacheEntry,
      'AudioCacheEntry',
      [
        SchemaProperty('url', RealmPropertyType.string, primaryKey: true),
        SchemaProperty('localPath', RealmPropertyType.string),
        SchemaProperty('cachedAt', RealmPropertyType.timestamp),
        SchemaProperty(
          'lastAccessed',
          RealmPropertyType.timestamp,
          indexType: RealmIndexType.regular,
        ),
        SchemaProperty('sizeBytes', RealmPropertyType.int),
        SchemaProperty('mimeType', RealmPropertyType.string, optional: true),
        SchemaProperty('accessCount', RealmPropertyType.int),
        SchemaProperty('isComplete', RealmPropertyType.bool),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class PlaylistCacheEntry extends _PlaylistCacheEntry
    with RealmEntity, RealmObjectBase, RealmObject {
  PlaylistCacheEntry(
    ObjectId id,
    String playlistId,
    String songUrl,
    int priority,
    DateTime createdAt,
    DateTime expiresAt,
    bool isPreloaded,
  ) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'playlistId', playlistId);
    RealmObjectBase.set(this, 'songUrl', songUrl);
    RealmObjectBase.set(this, 'priority', priority);
    RealmObjectBase.set(this, 'createdAt', createdAt);
    RealmObjectBase.set(this, 'expiresAt', expiresAt);
    RealmObjectBase.set(this, 'isPreloaded', isPreloaded);
  }

  PlaylistCacheEntry._();

  @override
  ObjectId get id => RealmObjectBase.get<ObjectId>(this, 'id') as ObjectId;
  @override
  set id(ObjectId value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get playlistId =>
      RealmObjectBase.get<String>(this, 'playlistId') as String;
  @override
  set playlistId(String value) =>
      RealmObjectBase.set(this, 'playlistId', value);

  @override
  String get songUrl => RealmObjectBase.get<String>(this, 'songUrl') as String;
  @override
  set songUrl(String value) => RealmObjectBase.set(this, 'songUrl', value);

  @override
  int get priority => RealmObjectBase.get<int>(this, 'priority') as int;
  @override
  set priority(int value) => RealmObjectBase.set(this, 'priority', value);

  @override
  DateTime get createdAt =>
      RealmObjectBase.get<DateTime>(this, 'createdAt') as DateTime;
  @override
  set createdAt(DateTime value) =>
      RealmObjectBase.set(this, 'createdAt', value);

  @override
  DateTime get expiresAt =>
      RealmObjectBase.get<DateTime>(this, 'expiresAt') as DateTime;
  @override
  set expiresAt(DateTime value) =>
      RealmObjectBase.set(this, 'expiresAt', value);

  @override
  bool get isPreloaded =>
      RealmObjectBase.get<bool>(this, 'isPreloaded') as bool;
  @override
  set isPreloaded(bool value) =>
      RealmObjectBase.set(this, 'isPreloaded', value);

  @override
  Stream<RealmObjectChanges<PlaylistCacheEntry>> get changes =>
      RealmObjectBase.getChanges<PlaylistCacheEntry>(this);

  @override
  Stream<RealmObjectChanges<PlaylistCacheEntry>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<PlaylistCacheEntry>(this, keyPaths);

  @override
  PlaylistCacheEntry freeze() =>
      RealmObjectBase.freezeObject<PlaylistCacheEntry>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'playlistId': playlistId.toEJson(),
      'songUrl': songUrl.toEJson(),
      'priority': priority.toEJson(),
      'createdAt': createdAt.toEJson(),
      'expiresAt': expiresAt.toEJson(),
      'isPreloaded': isPreloaded.toEJson(),
    };
  }

  static EJsonValue _toEJson(PlaylistCacheEntry value) => value.toEJson();
  static PlaylistCacheEntry _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'playlistId': EJsonValue playlistId,
        'songUrl': EJsonValue songUrl,
        'priority': EJsonValue priority,
        'createdAt': EJsonValue createdAt,
        'expiresAt': EJsonValue expiresAt,
        'isPreloaded': EJsonValue isPreloaded,
      } =>
        PlaylistCacheEntry(
          fromEJson(id),
          fromEJson(playlistId),
          fromEJson(songUrl),
          fromEJson(priority),
          fromEJson(createdAt),
          fromEJson(expiresAt),
          fromEJson(isPreloaded),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(PlaylistCacheEntry._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      PlaylistCacheEntry,
      'PlaylistCacheEntry',
      [
        SchemaProperty('id', RealmPropertyType.objectid, primaryKey: true),
        SchemaProperty(
          'playlistId',
          RealmPropertyType.string,
          indexType: RealmIndexType.regular,
        ),
        SchemaProperty('songUrl', RealmPropertyType.string),
        SchemaProperty('priority', RealmPropertyType.int),
        SchemaProperty('createdAt', RealmPropertyType.timestamp),
        SchemaProperty(
          'expiresAt',
          RealmPropertyType.timestamp,
          indexType: RealmIndexType.regular,
        ),
        SchemaProperty('isPreloaded', RealmPropertyType.bool),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class PlaylistData extends _PlaylistData
    with RealmEntity, RealmObjectBase, RealmObject {
  PlaylistData(
    String playlistUrl,
    String jsonData,
    DateTime cachedAt,
    DateTime expiresAt,
    int trackCount, {
    String? title,
  }) {
    RealmObjectBase.set(this, 'playlistUrl', playlistUrl);
    RealmObjectBase.set(this, 'jsonData', jsonData);
    RealmObjectBase.set(this, 'cachedAt', cachedAt);
    RealmObjectBase.set(this, 'expiresAt', expiresAt);
    RealmObjectBase.set(this, 'trackCount', trackCount);
    RealmObjectBase.set(this, 'title', title);
  }

  PlaylistData._();

  @override
  String get playlistUrl =>
      RealmObjectBase.get<String>(this, 'playlistUrl') as String;
  @override
  set playlistUrl(String value) =>
      RealmObjectBase.set(this, 'playlistUrl', value);

  @override
  String get jsonData =>
      RealmObjectBase.get<String>(this, 'jsonData') as String;
  @override
  set jsonData(String value) => RealmObjectBase.set(this, 'jsonData', value);

  @override
  DateTime get cachedAt =>
      RealmObjectBase.get<DateTime>(this, 'cachedAt') as DateTime;
  @override
  set cachedAt(DateTime value) => RealmObjectBase.set(this, 'cachedAt', value);

  @override
  DateTime get expiresAt =>
      RealmObjectBase.get<DateTime>(this, 'expiresAt') as DateTime;
  @override
  set expiresAt(DateTime value) =>
      RealmObjectBase.set(this, 'expiresAt', value);

  @override
  int get trackCount => RealmObjectBase.get<int>(this, 'trackCount') as int;
  @override
  set trackCount(int value) => RealmObjectBase.set(this, 'trackCount', value);

  @override
  String? get title => RealmObjectBase.get<String>(this, 'title') as String?;
  @override
  set title(String? value) => RealmObjectBase.set(this, 'title', value);

  @override
  Stream<RealmObjectChanges<PlaylistData>> get changes =>
      RealmObjectBase.getChanges<PlaylistData>(this);

  @override
  Stream<RealmObjectChanges<PlaylistData>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<PlaylistData>(this, keyPaths);

  @override
  PlaylistData freeze() => RealmObjectBase.freezeObject<PlaylistData>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'playlistUrl': playlistUrl.toEJson(),
      'jsonData': jsonData.toEJson(),
      'cachedAt': cachedAt.toEJson(),
      'expiresAt': expiresAt.toEJson(),
      'trackCount': trackCount.toEJson(),
      'title': title.toEJson(),
    };
  }

  static EJsonValue _toEJson(PlaylistData value) => value.toEJson();
  static PlaylistData _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'playlistUrl': EJsonValue playlistUrl,
        'jsonData': EJsonValue jsonData,
        'cachedAt': EJsonValue cachedAt,
        'expiresAt': EJsonValue expiresAt,
        'trackCount': EJsonValue trackCount,
      } =>
        PlaylistData(
          fromEJson(playlistUrl),
          fromEJson(jsonData),
          fromEJson(cachedAt),
          fromEJson(expiresAt),
          fromEJson(trackCount),
          title: fromEJson(ejson['title']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(PlaylistData._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      PlaylistData,
      'PlaylistData',
      [
        SchemaProperty(
          'playlistUrl',
          RealmPropertyType.string,
          primaryKey: true,
        ),
        SchemaProperty('jsonData', RealmPropertyType.string),
        SchemaProperty('cachedAt', RealmPropertyType.timestamp),
        SchemaProperty(
          'expiresAt',
          RealmPropertyType.timestamp,
          indexType: RealmIndexType.regular,
        ),
        SchemaProperty('trackCount', RealmPropertyType.int),
        SchemaProperty('title', RealmPropertyType.string, optional: true),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class HttpCacheEntry extends _HttpCacheEntry
    with RealmEntity, RealmObjectBase, RealmObject {
  HttpCacheEntry(
    String key,
    String responseBody,
    DateTime cachedAt,
    DateTime expiresAt,
    int statusCode, {
    String? contentType,
  }) {
    RealmObjectBase.set(this, 'key', key);
    RealmObjectBase.set(this, 'responseBody', responseBody);
    RealmObjectBase.set(this, 'cachedAt', cachedAt);
    RealmObjectBase.set(this, 'expiresAt', expiresAt);
    RealmObjectBase.set(this, 'statusCode', statusCode);
    RealmObjectBase.set(this, 'contentType', contentType);
  }

  HttpCacheEntry._();

  @override
  String get key => RealmObjectBase.get<String>(this, 'key') as String;
  @override
  set key(String value) => RealmObjectBase.set(this, 'key', value);

  @override
  String get responseBody =>
      RealmObjectBase.get<String>(this, 'responseBody') as String;
  @override
  set responseBody(String value) =>
      RealmObjectBase.set(this, 'responseBody', value);

  @override
  DateTime get cachedAt =>
      RealmObjectBase.get<DateTime>(this, 'cachedAt') as DateTime;
  @override
  set cachedAt(DateTime value) => RealmObjectBase.set(this, 'cachedAt', value);

  @override
  DateTime get expiresAt =>
      RealmObjectBase.get<DateTime>(this, 'expiresAt') as DateTime;
  @override
  set expiresAt(DateTime value) =>
      RealmObjectBase.set(this, 'expiresAt', value);

  @override
  int get statusCode => RealmObjectBase.get<int>(this, 'statusCode') as int;
  @override
  set statusCode(int value) => RealmObjectBase.set(this, 'statusCode', value);

  @override
  String? get contentType =>
      RealmObjectBase.get<String>(this, 'contentType') as String?;
  @override
  set contentType(String? value) =>
      RealmObjectBase.set(this, 'contentType', value);

  @override
  Stream<RealmObjectChanges<HttpCacheEntry>> get changes =>
      RealmObjectBase.getChanges<HttpCacheEntry>(this);

  @override
  Stream<RealmObjectChanges<HttpCacheEntry>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<HttpCacheEntry>(this, keyPaths);

  @override
  HttpCacheEntry freeze() => RealmObjectBase.freezeObject<HttpCacheEntry>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'key': key.toEJson(),
      'responseBody': responseBody.toEJson(),
      'cachedAt': cachedAt.toEJson(),
      'expiresAt': expiresAt.toEJson(),
      'statusCode': statusCode.toEJson(),
      'contentType': contentType.toEJson(),
    };
  }

  static EJsonValue _toEJson(HttpCacheEntry value) => value.toEJson();
  static HttpCacheEntry _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'key': EJsonValue key,
        'responseBody': EJsonValue responseBody,
        'cachedAt': EJsonValue cachedAt,
        'expiresAt': EJsonValue expiresAt,
        'statusCode': EJsonValue statusCode,
      } =>
        HttpCacheEntry(
          fromEJson(key),
          fromEJson(responseBody),
          fromEJson(cachedAt),
          fromEJson(expiresAt),
          fromEJson(statusCode),
          contentType: fromEJson(ejson['contentType']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(HttpCacheEntry._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      HttpCacheEntry,
      'HttpCacheEntry',
      [
        SchemaProperty('key', RealmPropertyType.string, primaryKey: true),
        SchemaProperty('responseBody', RealmPropertyType.string),
        SchemaProperty('cachedAt', RealmPropertyType.timestamp),
        SchemaProperty(
          'expiresAt',
          RealmPropertyType.timestamp,
          indexType: RealmIndexType.regular,
        ),
        SchemaProperty('statusCode', RealmPropertyType.int),
        SchemaProperty('contentType', RealmPropertyType.string, optional: true),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
