import 'package:drift/drift.dart';
import 'sales_table.dart';
import 'product_table.dart';

class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  // FK a la venta
  IntColumn get saleId =>
      integer().references(Sales, #id, onDelete: KeyAction.cascade)();

  // Guardamos el producto que se vendió
  IntColumn get productId =>
      integer().references(Products, #id)();

  // snapshot del nombre del producto (por si luego lo cambias en catálogo)
  TextColumn get productName => text()();

  // precio unitario con IVA incluido en el momento de la venta
  RealColumn get priceWithIva => real()();

  // porcentaje de IVA en el momento de la venta (ej. 15)
  RealColumn get ivaPct => real()();

  // cantidad vendida
  IntColumn get qty => integer()();
}
