import 'package:asistente/core/auth/auth_providers.dart';
import 'package:asistente/data/local/app_database.dart';
import 'package:asistente/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Dependencias falsas de la app para widget tests (sin red ni Supabase).
class TestDeps {
  TestDeps({String? userId = fakeUserId, DateTime? now})
    : auth = FakeAuthRepository(userId: userId),
      db = newTestDatabase(),
      photos = InMemoryPhotoStore(),
      capture = FakePhotoCapture(fakeJpeg()),
      remote = FakeFichadasRemote()..online = false,
      bancoRemote = FakeBancoRemote()..online = false,
      cursosRemote = FakeCursosRemote()..online = false,
      picker = FakeAttachmentPicker(),
      now = now ?? DateTime(2026, 9, 24, 8, 2);

  final FakeAuthRepository auth;
  final AppDatabase db;
  final InMemoryPhotoStore photos;
  final FakePhotoCapture capture;
  final FakeFichadasRemote remote;
  final FakeBancoRemote bancoRemote;
  final FakeCursosRemote cursosRemote;
  final FakeAttachmentPicker picker;
  DateTime now;

  List<Override> get overrides => [
    authRepositoryProvider.overrideWithValue(auth),
    appDatabaseProvider.overrideWithValue(db),
    photoStoreProvider.overrideWithValue(photos),
    photoCaptureProvider.overrideWithValue(capture),
    photoCompressorProvider.overrideWithValue((bytes) async => bytes),
    fichadasRemoteProvider.overrideWithValue(remote),
    bancoRemoteProvider.overrideWithValue(bancoRemote),
    cursosRemoteProvider.overrideWithValue(cursosRemote),
    attachmentPickerProvider.overrideWithValue(picker),
    connectivityOnlineProvider.overrideWith((ref) => Stream.value(false)),
    syncRetryIntervalProvider.overrideWithValue(null),
    clockProvider.overrideWithValue(() => now),
  ];
}

/// Pantalla de celular (390 x 844 dp).
void usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Widget testMaterialApp(Widget home) => MaterialApp(
  locale: const Locale('es', 'AR'),
  supportedLocales: const [Locale('es', 'AR')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: home,
);

/// Cierra la base al final del test, después de desmontar la UI.
Future<void> disposeTestApp(WidgetTester tester, TestDeps deps) async {
  await tester.pumpWidget(const SizedBox());
  // drift limpia las consultas con timers: hay que bombear el reloj falso
  // antes y durante el cierre para que no quede colgado.
  await tester.pump(const Duration(seconds: 1));
  final closing = deps.db.close();
  await tester.pump(const Duration(seconds: 1));
  await closing;
}
