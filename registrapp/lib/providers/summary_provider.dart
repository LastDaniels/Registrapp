import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/db.dart';
import 'db_provider.dart';

final summaryControllerProvider = Provider<SummaryController>((ref) {
  final db = ref.watch(dbProvider);
  return SummaryController(db);
});

class SummaryController {
  SummaryController(this._db);
  final AppDatabase _db;

  Future<DailySummary> getTodaySummary() {
    return _db.getDailySummary(DateTime.now());
  }

  Future<DailySummary> closeTodayCash() {
    return _db.closeCash(DateTime.now());
  }
}
