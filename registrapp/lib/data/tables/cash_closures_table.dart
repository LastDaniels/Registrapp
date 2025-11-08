import 'package:drift/drift.dart';

class CashClosures extends Table {
  IntColumn get id => integer().autoIncrement()();

  // cuándo se cerró
  DateTimeColumn get closedAt =>
      dateTime().withDefault(currentDateAndTime)();

  // día que se está cerrando (por si cierro el día de ayer)
  DateTimeColumn get dayClosed => dateTime()();

  // totales al momento del cierre
  RealColumn get subtotal => real()();
  RealColumn get iva => real()();
  RealColumn get total => real()();

  // por si luego quieres marcar si se imprimió
  BoolColumn get printed =>
      boolean().withDefault(const Constant(false))();
}
