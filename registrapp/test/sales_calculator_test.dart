import 'package:flutter_test/flutter_test.dart';
import 'package:registrapp/core/sales_calculator.dart';

void main() {
  group('SalesCalculator - Business Logic Tests', () {
    test('Subtotal is calculated correctly', () {
      final result = SalesCalculator.subtotal([10.0, 5.0, 5.0]);
      expect(result, 20.0);
    });

    test('IVA (15%) is calculated correctly', () {
      final result = SalesCalculator.iva(100.0);
      expect(result, 15.0);
    });

    test('Total equals subtotal plus IVA', () {
      final result = SalesCalculator.total(100.0);
      expect(result, 115.0);
    });

    test('validatePrice rejects zero or negative values', () {
      expect(SalesCalculator.validatePrice(0), isNotNull);
      expect(SalesCalculator.validatePrice(-10), isNotNull);
    });

    test('validatePrice accepts positive values', () {
      expect(SalesCalculator.validatePrice(1.0), isNull);
    });
  });
}
