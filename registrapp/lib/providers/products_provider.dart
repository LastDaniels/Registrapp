import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/db.dart';
import 'db_provider.dart';

// Stream reactivo de productos activos para mostrar en UI y en Caja
final productsStreamProvider =
    StreamProvider.autoDispose<List<Product>>((ref) {
  final db = ref.watch(dbProvider);
  return db.watchAllProducts();
});

// Controlador para acciones CRUD sobre productos
final productsControllerProvider = Provider<ProductsController>((ref) {
  final db = ref.watch(dbProvider);
  return ProductsController(db);
});

class ProductsController {
  ProductsController(this._db);
  final AppDatabase _db;

  static const double _ivaFijo = 15.0;

  Future<void> addProduct({
    required String name,
    required double price,
  }) async {
    await _db.insertProduct(
      name,
      price,
      _ivaFijo,
    );
  }

  Future<void> updateProduct(Product p) async {
    await _db.updateProduct(
      p.copyWith(
        ivaPct: _ivaFijo,
      ),
    );
  }

  Future<void> deleteProduct(int id) async {
    await _db.softDeleteProduct(id);
  }
}
