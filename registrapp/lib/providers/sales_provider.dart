import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/db.dart';
import 'db_provider.dart';

final salesControllerProvider = Provider<SalesController>((ref) {
  final db = ref.watch(dbProvider);
  return SalesController(db);
});

/// ventas del día actual
final todaySalesStreamProvider =
    StreamProvider.autoDispose<List<Sale>>((ref) {
  final db = ref.watch(dbProvider);
  final now = DateTime.now();
  return db.watchSalesOfDay(now);
});

/// item más vendido
final mostSoldItemProvider =
    FutureProvider.autoDispose<DailySummaryItem?>((ref) async {

  ref.watch(todaySalesStreamProvider);

  final db = ref.watch(dbProvider);
  return db.getMostSoldItemEver();
});

class SalesController {
  SalesController(this._db);
  final AppDatabase _db;

  Future<int> registerSale({
    required String? customerName,
    required List<CartItemInput> items,
  }) {
    return _db.insertSaleWithItems(
      customerName: customerName,
      items: items,
    );
  }
}
