import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Abre la base local en el dispositivo. En web usa `web/sqlite3.wasm` y
/// `web/drift_worker.js` (OPFS o IndexedDB según el navegador).
QueryExecutor openAppDatabaseConnection() => driftDatabase(
  name: 'asistente',
  web: DriftWebOptions(
    sqlite3Wasm: Uri.parse('sqlite3.wasm'),
    driftWorker: Uri.parse('drift_worker.js'),
  ),
);
