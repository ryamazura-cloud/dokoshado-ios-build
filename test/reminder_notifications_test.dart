import 'package:dokoshado/reminder_notifications.dart';
import 'package:dokoshado/reminders.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class _ReminderStore implements ReminderStore {
  ReminderSettings settings = const ReminderSettings();

  @override
  Future<ReminderSettings> load() async => settings;

  @override
  Future<void> save(ReminderSettings value) async => settings = value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const notifications = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const timezone = MethodChannel('flutter_timezone');
  final calls = <MethodCall>[];
  var permission = true;

  setUp(() {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls.clear();
    permission = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notifications, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'initialize':
              return true;
            case 'requestNotificationsPermission':
            case 'areNotificationsEnabled':
              return permission;
            default:
              return null;
          }
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          timezone,
          (_) async => {'identifier': 'Asia/Tokyo'},
        );
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(notifications, null);
    messenger.setMockMethodCallHandler(timezone, null);
  });

  test(
    'preview requests permission and posts without changing daily settings',
    () async {
      final store = _ReminderStore();
      final manager = ReminderManager(
        store: store,
        backend: LocalReminderBackend(),
      );
      await manager.preview();
      expect(calls.map((call) => call.method), [
        'initialize',
        'requestNotificationsPermission',
        'areNotificationsEnabled',
        'show',
      ]);
      final initialization = calls.first.arguments as Map;
      expect(initialization['defaultIcon'], 'ic_stat_dokoshado');
      final posted = calls.last.arguments as Map;
      expect(posted['id'], LocalReminderBackend.previewId);
      expect(posted['title'], 'どこシャド｜テスト通知');
      expect((posted['platformSpecifics'] as Map)['icon'], 'ic_stat_dokoshado');
      expect(store.settings.enabled, false);
    },
  );

  test(
    'daily schedule retains local time, restores, and can be disabled',
    () async {
      final store = _ReminderStore();
      final manager = ReminderManager(
        store: store,
        backend: LocalReminderBackend(),
      );
      await manager.save(
        const ReminderSettings(enabled: true, hour: 20, minute: 17),
      );
      final scheduled =
          calls.singleWhere((call) => call.method == 'zonedSchedule').arguments
              as Map;
      expect(scheduled['id'], LocalReminderBackend.dailyId);
      expect(scheduled['timeZoneName'], 'Asia/Tokyo');
      expect(scheduled['scheduledDateTime'], contains('T20:17:00'));
      expect(store.settings.timeLabel, '20:17');
      expect(store.settings.enabled, true);
      calls.clear();
      await manager.restore();
      expect(calls.map((call) => call.method), [
        'areNotificationsEnabled',
        'zonedSchedule',
      ]);
      calls.clear();
      await manager.save(
        const ReminderSettings(enabled: false, hour: 20, minute: 17),
      );
      expect(calls.map((call) => call.method), ['cancel', 'cancel']);
      expect(store.settings.enabled, false);
    },
  );

  test('denied permission never posts or saves an enabled reminder', () async {
    permission = false;
    final store = _ReminderStore();
    final manager = ReminderManager(
      store: store,
      backend: LocalReminderBackend(),
    );
    await expectLater(
      manager.preview(),
      throwsA(isA<ReminderPermissionDenied>()),
    );
    await expectLater(
      manager.save(const ReminderSettings(enabled: true)),
      throwsA(isA<ReminderPermissionDenied>()),
    );
    expect(
      calls.where(
        (call) => call.method == 'show' || call.method == 'zonedSchedule',
      ),
      isEmpty,
    );
    expect(store.settings.enabled, false);
  });

  test(
    'next reminder follows the selected local clock and moves to the next day',
    () {
      tzdata.initializeTimeZones();
      final japan = tz.getLocation('Asia/Tokyo');
      final now = tz.TZDateTime(japan, 2026, 11, 17, 20, 17);
      expect(
        nextReminder(now, 20, 17),
        tz.TZDateTime(japan, 2026, 11, 18, 20, 17),
      );
      expect(nextReminder(now, 21, 0), tz.TZDateTime(japan, 2026, 11, 17, 21));
    },
  );
}
