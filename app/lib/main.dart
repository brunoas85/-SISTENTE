import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/format/formatters.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/sync/sync_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(appLocale);
  if (!AppConfig.isConfigured) {
    runApp(const _FaltaConfigApp());
    return;
  }
  // Supabase guarda la sesión en el dispositivo y la recupera sin red.
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );
  runApp(const ProviderScope(child: AsistenteApp()));
}

const _supportedLocales = [Locale('es', 'AR'), Locale('es')];

class AsistenteApp extends ConsumerWidget {
  const AsistenteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mantiene viva la sincronización automática mientras la app corre.
    ref.listen(syncControllerProvider, (_, _) {});
    return MaterialApp.router(
      title: '@sistente',
      debugShowCheckedModeBanner: false,
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      locale: const Locale('es', 'AR'),
      supportedLocales: _supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}

class _FaltaConfigApp extends StatelessWidget {
  const _FaltaConfigApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '@sistente',
    theme: appLightTheme,
    home: const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Falta la configuración de Supabase. Corré la app con '
            '--dart-define-from-file=env/dev.json',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
