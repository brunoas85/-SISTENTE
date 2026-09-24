import '../local/app_database.dart';
import 'photo_store.dart';

PhotoStore createPhotoStore(AppDatabase db) => DbPhotoStore(db);
