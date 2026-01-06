import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/db.dart';
import 'db_provider.dart';

final expensesControllerProvider = Provider<ExpensesController>((ref) {
  final db = ref.watch(dbProvider);
  return ExpensesController(db);
});

final todayExpensesStreamProvider =
StreamProvider.autoDispose<List<Expense>>((ref) {
  final db = ref.watch(dbProvider);
  return db.watchExpensesOfDay(DateTime.now());
});

class ExpensesController {
  ExpensesController(this._db);
  final AppDatabase _db;

  Future<int> addExpense({
    required String category,
    required double amount,
  }) {
    return _db.insertExpense(category: category, amount: amount);
  }
}
