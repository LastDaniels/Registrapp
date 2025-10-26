import 'package:drift/drift.dart';

// Esta clase define cómo luce la tabla en SQLite
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();           // nombre del producto
  RealColumn get price => real()();          // precio base
  RealColumn get ivaPct => real().withDefault(const Constant(15.0))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}
