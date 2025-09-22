import 'package:flutter_test/flutter_test.dart';
import 'package:mirei/models/realm_models.dart';

void main() {
  group('AudioRecordingData', () {
    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final timestamp = DateTime(2023, 12, 25, 15, 30, 45, 123);
        final audioData = AudioRecordingData(
          path: '/storage/audio/test_recording.m4a',
          duration: const Duration(minutes: 2, seconds: 30, milliseconds: 500),
          timestamp: timestamp,
        );

        final json = audioData.toJson();

        expect(json, isA<String>());
        expect(json, contains('"/storage/audio/test_recording.m4a"'));
        expect(json, contains('"duration":150500')); // 2m30.5s in milliseconds
        expect(
          json,
          contains('"timestamp":${timestamp.millisecondsSinceEpoch}'),
        );
      });

      test('should deserialize from JSON correctly', () {
        final originalTimestamp = DateTime(2023, 12, 25, 15, 30, 45);
        final jsonString =
            '''
        {
          "path": "/storage/audio/test_recording.wav",
          "duration": 75000,
          "timestamp": ${originalTimestamp.millisecondsSinceEpoch}
        }
        ''';

        final audioData = AudioRecordingData.fromJson(jsonString);

        expect(audioData.path, equals('/storage/audio/test_recording.wav'));
        expect(audioData.duration, equals(const Duration(milliseconds: 75000)));
        expect(audioData.timestamp, equals(originalTimestamp));
      });

      test('should handle round-trip serialization correctly', () {
        // Use a timestamp with millisecond precision only (since JSON loses microseconds)
        final original = AudioRecordingData(
          path: '/storage/voice/my_note.aac',
          duration: const Duration(hours: 1, minutes: 15, seconds: 30),
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            DateTime.now().millisecondsSinceEpoch,
          ),
        );

        final json = original.toJson();
        final deserialized = AudioRecordingData.fromJson(json);

        expect(deserialized.path, equals(original.path));
        expect(deserialized.duration, equals(original.duration));
        expect(deserialized.timestamp, equals(original.timestamp));
      });
    });

    group('Error Handling', () {
      test('should handle empty JSON gracefully', () {
        final audioData = AudioRecordingData.fromJson('');

        expect(audioData.path, equals(''));
        expect(audioData.duration, equals(Duration.zero));
        expect(audioData.timestamp, isA<DateTime>());
      });

      test('should handle null JSON gracefully', () {
        final audioData = AudioRecordingData.fromJson('null');

        expect(audioData.path, equals(''));
        expect(audioData.duration, equals(Duration.zero));
        expect(audioData.timestamp, isA<DateTime>());
      });

      test('should handle malformed JSON gracefully', () {
        final audioData = AudioRecordingData.fromJson('{"invalid": json}');

        expect(audioData.path, equals(''));
        expect(audioData.duration, equals(Duration.zero));
        expect(audioData.timestamp, isA<DateTime>());
      });

      test('should handle missing fields gracefully', () {
        const jsonString =
            '{"path": "/test.mp3"}'; // Missing duration and timestamp

        final audioData = AudioRecordingData.fromJson(jsonString);

        expect(audioData.path, equals('/test.mp3'));
        expect(audioData.duration, equals(Duration.zero));
        expect(audioData.timestamp, isA<DateTime>());
      });

      test('should handle null values in JSON fields', () {
        const jsonString = '''
        {
          "path": null,
          "duration": null,
          "timestamp": null
        }
        ''';

        final audioData = AudioRecordingData.fromJson(jsonString);

        expect(audioData.path, equals(''));
        expect(audioData.duration, equals(Duration.zero));
        expect(audioData.timestamp, isA<DateTime>());
      });

      test('should handle zero timestamp gracefully', () {
        const jsonString = '''
        {
          "path": "/storage/test.wav",
          "duration": 5000,
          "timestamp": 0
        }
        ''';

        final audioData = AudioRecordingData.fromJson(jsonString);

        expect(audioData.path, equals('/storage/test.wav'));
        expect(audioData.duration, equals(const Duration(milliseconds: 5000)));
        expect(audioData.timestamp, isA<DateTime>());
        // Should be current time since timestamp was 0
        expect(
          audioData.timestamp.isBefore(
            DateTime.now().add(const Duration(seconds: 1)),
          ),
          isTrue,
        );
      });

      test('should handle negative duration gracefully', () {
        const jsonString = '''
        {
          "path": "/storage/test.mp3",
          "duration": -5000,
          "timestamp": 1703520645000
        }
        ''';

        final audioData = AudioRecordingData.fromJson(jsonString);

        expect(audioData.path, equals('/storage/test.mp3'));
        expect(audioData.duration, equals(const Duration(milliseconds: -5000)));
        expect(audioData.timestamp.year, equals(2023)); // Valid timestamp
      });
    });

    group('Edge Cases', () {
      test('should handle very long file paths', () {
        final longPath =
            '/storage/audio/' + 'very_long_filename_' * 20 + '.m4a';
        final audioData = AudioRecordingData(
          path: longPath,
          duration: const Duration(seconds: 30),
          timestamp: DateTime.now(),
        );

        final json = audioData.toJson();
        final deserialized = AudioRecordingData.fromJson(json);

        expect(deserialized.path, equals(longPath));
      });

      test('should handle special characters in file paths', () {
        const specialPath =
            '/storage/audio/Recording #1 (test) [final] & more.m4a';
        final audioData = AudioRecordingData(
          path: specialPath,
          duration: const Duration(minutes: 5),
          timestamp: DateTime.now(),
        );

        final json = audioData.toJson();
        final deserialized = AudioRecordingData.fromJson(json);

        expect(deserialized.path, equals(specialPath));
      });

      test('should handle zero duration', () {
        final audioData = AudioRecordingData(
          path: '/storage/empty.wav',
          duration: Duration.zero,
          timestamp: DateTime.now(),
        );

        final json = audioData.toJson();
        final deserialized = AudioRecordingData.fromJson(json);

        expect(deserialized.duration, equals(Duration.zero));
      });

      test('should handle very long duration', () {
        const longDuration = Duration(
          hours: 24,
          minutes: 30,
        ); // Very long recording
        final audioData = AudioRecordingData(
          path: '/storage/long_recording.mp3',
          duration: longDuration,
          timestamp: DateTime.now(),
        );

        final json = audioData.toJson();
        final deserialized = AudioRecordingData.fromJson(json);

        expect(deserialized.duration, equals(longDuration));
      });

      test('should handle future timestamps', () {
        // Use millisecond precision to avoid precision loss in JSON serialization
        final futureTimeMs = DateTime.now()
            .add(const Duration(days: 365))
            .millisecondsSinceEpoch;
        final futureTime = DateTime.fromMillisecondsSinceEpoch(futureTimeMs);
        final audioData = AudioRecordingData(
          path: '/storage/future.wav',
          duration: const Duration(seconds: 10),
          timestamp: futureTime,
        );

        final json = audioData.toJson();
        final deserialized = AudioRecordingData.fromJson(json);

        expect(deserialized.timestamp, equals(futureTime));
      });

      test('should handle very old timestamps', () {
        final oldTime = DateTime(1970, 1, 1); // Unix epoch
        final audioData = AudioRecordingData(
          path: '/storage/old.wav',
          duration: const Duration(seconds: 10),
          timestamp: oldTime,
        );

        final json = audioData.toJson();
        final deserialized = AudioRecordingData.fromJson(json);

        expect(deserialized.timestamp, equals(oldTime));
      });
    });

    group('Data Validation', () {
      test('should maintain data integrity across serialization', () {
        final testCases = [
          AudioRecordingData(
            path: '/storage/test1.m4a',
            duration: const Duration(milliseconds: 1),
            timestamp: DateTime(2023, 1, 1),
          ),
          AudioRecordingData(
            path: '/storage/test2.wav',
            duration: const Duration(hours: 23, minutes: 59, seconds: 59),
            timestamp: DateTime(2025, 12, 31, 23, 59, 59),
          ),
          AudioRecordingData(
            path: '',
            duration: Duration.zero,
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              DateTime.now().millisecondsSinceEpoch,
            ),
          ),
        ];

        for (final original in testCases) {
          final json = original.toJson();
          final deserialized = AudioRecordingData.fromJson(json);

          expect(
            deserialized.path,
            equals(original.path),
            reason: 'Path mismatch for ${original.path}',
          );
          expect(
            deserialized.duration,
            equals(original.duration),
            reason: 'Duration mismatch for ${original.path}',
          );
          expect(
            deserialized.timestamp,
            equals(original.timestamp),
            reason: 'Timestamp mismatch for ${original.path}',
          );
        }
      });
    });
  });
}
