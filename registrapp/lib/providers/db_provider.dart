import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/db.dart';

// Provider global para tener una sola instancia de la BD en toda la app
final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() {
    db.close();
  });
  return db;
});
