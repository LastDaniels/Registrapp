import 'package:drift/drift.dart';

class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();

  // fecha/hora de la venta
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  // nombre del cliente (opcional)
  TextColumn get customerName => text().nullable()();

  // totales ya calculados en el momento de vender
  RealColumn get subtotal => real()();     // sin IVA
  RealColumn get iva => real()();          // solo IVA
  RealColumn get total => real()();        // con IVA
}
