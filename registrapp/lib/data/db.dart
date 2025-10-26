import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/product_table.dart';

// parte generada por drift
part 'db.g.dart';

// AppDatabase será BD local
@DriftDatabase(
  tables: [Products],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // versión del esquema. 
  @override
  int get schemaVersion => 1;

  // ------------- QUERIES PRODUCTOS -------------
  Future<List<Product>> getAllProducts() {
    return (select(products)
          ..where((tbl) => tbl.active.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  Stream<List<Product>> watchAllProducts() {
    return (select(products)
          ..where((tbl) => tbl.active.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  Future<int> insertProduct(String name, double price, double ivaPct) {
    return into(products).insert(ProductsCompanion.insert(
      name: name,
      price: price,
      ivaPct: Value(ivaPct),
    ));
  }

  Future<bool> updateProduct(Product row) {
    return update(products).replace(row);
  }

  Future<int> softDeleteProduct(int id) {
    return (update(products)
          ..where((tbl) => tbl.id.equals(id)))
        .write(const ProductsCompanion(active: Value(false)));
  }
}

// Abre conexión a la BD física en el dispositivo
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'pos_offline.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
