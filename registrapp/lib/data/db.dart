// lib/data/db.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// tablas
import 'tables/product_table.dart';
import 'tables/sales_table.dart';
import 'tables/sale_items_table.dart';
import 'tables/cash_closures_table.dart';
import 'tables/expenses_table.dart';


part 'db.g.dart';

@DriftDatabase(
  tables: [
    Products,
    Sales,
    SaleItems,
    CashClosures,
    Expenses,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // subimos versión porque agregamos tablas nuevas
  @override
  int get schemaVersion => 4;

  // migración sencilla: si vienes de una versión anterior, crea las nuevas tablas
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll(); // crea todas las tablas
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // versión vieja solo tenía products
            await m.createTable(sales);
            await m.createTable(saleItems);
            await m.createTable(cashClosures);
          }
          if (from < 3) {
            await m.createTable(expenses);
          }
          if (from < 4) {
            await m.addColumn(sales, sales.status);
          }

        },
      );

  // =========================================================
  //                     PRODUCTOS
  // =========================================================

  Future<List<Product>> getAllProducts() {
    return (select(products)
          ..where((tbl) => tbl.active.equals(true))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .get();
  }

  Stream<List<Product>> watchAllProducts() {
    return (select(products)
          ..where((tbl) => tbl.active.equals(true))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .watch();
  }

  Future<int> insertProduct(String name, double price, double ivaPct) {
    return into(products).insert(
      ProductsCompanion.insert(
        name: name,
        price: price,
        ivaPct: Value(ivaPct),
      ),
    );
  }

  Future<bool> updateProduct(Product row) {
    return update(products).replace(row);
  }

  Future<int> softDeleteProduct(int id) {
    return (update(products)..where((tbl) => tbl.id.equals(id))).write(
      const ProductsCompanion(active: Value(false)),
    );
  }

  // =========================================================
  //                      VENTAS
  // =========================================================

  /// Guarda una venta CON sus ítems en una sola transacción.
  /// [items] deben venir con precioConIva, ivaPct y qty.
  Future<int> insertSaleWithItems({
    required String? customerName,
    required List<CartItemInput> items,
  }) async {
    double subtotal = 0;
    double iva = 0;
    double total = 0;

    // calculamos totales aquí para guardarlos fijos
    for (final item in items) {
      final base = _baseFromPrice(item.priceWithIva, item.ivaPct);
      final ivaUnit = item.priceWithIva - base;

      subtotal += base * item.qty;
      iva += ivaUnit * item.qty;
      total += item.priceWithIva * item.qty;
    }

    return transaction(() async {
      // 1) insertamos la venta
      final saleId = await into(sales).insert(
        SalesCompanion.insert(
          customerName: Value(customerName),
          subtotal: subtotal,
          iva: iva,
          total: total,
        ),
      );

      // 2) insertamos los ítems de la venta
      for (final item in items) {
        await into(saleItems).insert(
          SaleItemsCompanion.insert(
            saleId: saleId,
            productId: item.productId,
            productName: item.productName,
            priceWithIva: item.priceWithIva,
            ivaPct: item.ivaPct,
            qty: item.qty,
          ),
        );
      }

      return saleId;
    });
  }

  /// Ventas del día (para la pantalla Pedidos)
  Stream<List<Sale>> watchSalesOfDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    return (select(sales)
          ..where((tbl) =>
              tbl.createdAt.isBiggerOrEqualValue(start) &
              tbl.createdAt.isSmallerThanValue(end))
          ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
        .watch();
  }
  Stream<List<SaleWithItems>> watchSalesOfDayWithItems(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final q = (select(sales)
      ..where((s) =>
          s.createdAt.isBiggerOrEqualValue(start) &
          s.createdAt.isSmallerThanValue(end))
      ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]));

    return q.watch().asyncMap((rows) async {
      final result = <SaleWithItems>[];

      for (final sale in rows) {
        final items = await (select(saleItems)
              ..where((i) => i.saleId.equals(sale.id)))
            .get();

        result.add(
          SaleWithItems(
            sale: sale,
            items: items,
          ),
        );
      }

      return result;
    });
  }
  Future<void> updateSaleStatus(int saleId, String status) {
    return (update(sales)
          ..where((s) => s.id.equals(saleId)))
        .write(
          SalesCompanion(
            status: Value(status),
          ),
        );
  }


  // =========================================================
//                      GASTOS
// =========================================================

  Future<int> insertExpense({
    required String category,
    required double amount,
  }) {
    return into(expenses).insert(
      ExpensesCompanion.insert(
        category: category,
        amount: amount,
      ),
    );
  }

  Stream<List<Expense>> watchExpensesOfDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    return (select(expenses)
      ..where((tbl) =>
      tbl.createdAt.isBiggerOrEqualValue(start) &
      tbl.createdAt.isSmallerThanValue(end))
      ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]))
        .watch();
  }

  Future<double> getExpensesTotalOfDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final row = await customSelect(
      '''
    SELECT COALESCE(SUM(amount), 0) AS total
    FROM expenses
    WHERE created_at >= ? AND created_at < ?
    ''',
      variables: [Variable<DateTime>(start), Variable<DateTime>(end)],
      readsFrom: {expenses},
    ).getSingle();

    return (row.data['total'] as num).toDouble();
  }

  Future<void> clearDailyExpenses() async {
    await delete(expenses).go();
  }


  // =========================================================
  //                  RESÚMENES Y CIERRE DE CAJA
  // =========================================================

  /// Devuelve el resumen del día (ventas + items) sin cerrar la caja.
  Future<DailySummary> getDailySummary(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    // 1) totales por venta
    final salesRows = await (select(sales)
          ..where((tbl) =>
              tbl.createdAt.isBiggerOrEqualValue(start) &
              tbl.createdAt.isSmallerThanValue(end)))
        .get();

    double subtotal = 0;
    double iva = 0;
    double total = 0;
    for (final s in salesRows) {
      subtotal += s.subtotal;
      iva += s.iva;
      total += s.total;
    }

    // 2) detalle por producto para el ticket largo
    final itemsRows = await customSelect(
      '''
      SELECT product_name AS name,
             SUM(qty) AS total_qty,
             SUM(price_with_iva * qty) AS total_amount
      FROM sale_items
      WHERE sale_id IN (
        SELECT id FROM sales
        WHERE created_at >= ? AND created_at < ?
      )
      GROUP BY product_name
      ORDER BY total_qty DESC
      ''',
      variables: [
        Variable<DateTime>(start),
        Variable<DateTime>(end),
      ],
      readsFrom: {saleItems, sales},
    ).get();

    final details = itemsRows
        .map(
          (row) => DailySummaryItem(
            name: row.data['name'] as String,
            qty: row.data['total_qty'] as int,
            totalAmount:
                (row.data['total_amount'] as num).toDouble(),
          ),
        )
        .toList();

    return DailySummary(
      day: start,
      subtotal: subtotal,
      iva: iva,
      total: total,
      items: details,
    );
  }

    /// Devuelve el item más vendido en toda la historia, según cantidad.
  /// Si no hay datos, devuelve null.
  Future<DailySummaryItem?> getMostSoldItemEver() async {
    final rows = await customSelect(
      '''
      SELECT product_name AS name,
             SUM(qty) AS total_qty,
             SUM(price_with_iva * qty) AS total_amount
      FROM sale_items
      GROUP BY product_name
      ORDER BY total_qty DESC
      LIMIT 1
      ''',
      readsFrom: {saleItems},
    ).get();

    if (rows.isEmpty) return null;

    final row = rows.first;
    return DailySummaryItem(
      name: row.data['name'] as String,
      qty: row.data['total_qty'] as int,
      totalAmount: (row.data['total_amount'] as num).toDouble(),
    );
  }
  Future<DailySummaryItem?> getMostSoldItemOfDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final rows = await customSelect(
      '''
      SELECT product_name AS name,
            SUM(qty) AS total_qty,
            SUM(price_with_iva * qty) AS total_amount
      FROM sale_items
      WHERE sale_id IN (
        SELECT id FROM sales
        WHERE created_at >= ? AND created_at < ?
      )
      GROUP BY product_name
      ORDER BY total_qty DESC
      LIMIT 1
      ''',
      variables: [
        Variable<DateTime>(start),
        Variable<DateTime>(end),
      ],
      readsFrom: {saleItems, sales},
    ).get();

    if (rows.isEmpty) return null;

    final row = rows.first;
    return DailySummaryItem(
      name: row.data['name'] as String,
      qty: row.data['total_qty'] as int,
      totalAmount: (row.data['total_amount'] as num).toDouble(),
    );
  }

  Future<void> clearDailySales() async {
  await transaction(() async {
    await delete(saleItems).go(); // borra los detalles de los pedidos
    await delete(sales).go(); // borra las ventas principales
    });
  }
  Future<void> deleteSaleById(int saleId) async {
    await transaction(() async {
      await (delete(saleItems)..where((i) => i.saleId.equals(saleId))).go();
      await (delete(sales)..where((s) => s.id.equals(saleId))).go();
    });
  }


  /// Cierra la caja de un día: guarda el cierre y devuelve el mismo resumen.
  Future<DailySummary> closeCash(DateTime day) async {
    final summary = await getDailySummary(day);

    await into(cashClosures).insert(
      CashClosuresCompanion.insert(
        dayClosed: summary.day,
        subtotal: summary.subtotal,
        iva: summary.iva,
        total: summary.total,
      ),
    );

    return summary;
  }

  // =========================================================
  //                    HELPERS PRIVADOS
  // =========================================================

  // cuando el precio ya viene con IVA incluido
  double _baseFromPrice(double priceWithIva, double ivaPct) {
    final factor = 1 + (ivaPct / 100.0);
    return priceWithIva / factor;
  }
}

// =========================================================
//                 MODELOS AUXILIARES
// =========================================================

/// Lo que recibe la DB desde la UI cuando guardamos una venta
class CartItemInput {
  final int productId;
  final String productName;
  final double priceWithIva;
  final double ivaPct;
  final int qty;

  CartItemInput({
    required this.productId,
    required this.productName,
    required this.priceWithIva,
    required this.ivaPct,
    required this.qty,
  });
}

/// Resumen del día (para imprimir o mostrar en pantalla)
class DailySummary {
  final DateTime day;
  final double subtotal;
  final double iva;
  final double total;
  final List<DailySummaryItem> items;

  DailySummary({
    required this.day,
    required this.subtotal,
    required this.iva,
    required this.total,
    required this.items,
  });
}

class DailySummaryItem {
  final String name;
  final int qty;
  final double totalAmount;

  DailySummaryItem({
    required this.name,
    required this.qty,
    required this.totalAmount,
  });
}
class SaleWithItems {
  final Sale sale;
  final List<SaleItem> items;

  SaleWithItems({
    required this.sale,
    required this.items,
  });
}


// =========================================================
//                 CONEXIÓN A LA BD FÍSICA
// =========================================================

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'pos_offline.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
