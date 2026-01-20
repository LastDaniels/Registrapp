/// Pure business logic for sales calculations.
/// This file is intentionally independent from UI, DB, and providers
/// to allow easy and reliable unit testing.
class SalesCalculator {
  /// IVA rate used in the system (15%)
  static const double ivaRate = 0.15;

  /// Calculates the subtotal from a list of item totals (price * quantity).
  static double subtotal(List<double> itemTotals) {
    return itemTotals.fold(0.0, (sum, value) => sum + value);
  }

  /// Calculates IVA amount from a given subtotal.
  static double iva(double subtotal) {
    return subtotal * ivaRate;
  }

  /// Calculates total amount including IVA.
  static double total(double subtotal) {
    return subtotal + iva(subtotal);
  }

  /// Validates a product price.
  /// Returns an error message if invalid, otherwise null.
  static String? validatePrice(double price) {
    if (price <= 0) {
      return 'Price must be greater than zero';
    }
    return null;
  }
}
