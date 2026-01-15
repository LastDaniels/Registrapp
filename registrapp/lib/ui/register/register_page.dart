// lib/ui/register/register_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/products_provider.dart';
import '../../providers/sales_provider.dart';
import '../../data/db.dart' show CartItemInput;

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  // carrito: productId -> _CartEntry
  final Map<int, _CartEntry> _cart = {};
  String _lastCustomer = '';

  // helpers de cálculo
  double get subtotal {
    double s = 0;
    _cart.forEach((_, entry) {
      final base = _baseFromPrice(entry.priceWithIva, entry.ivaPct);
      s += base * entry.qty;
    });
    return s;
  }

  double get iva {
    double i = 0;
    _cart.forEach((_, entry) {
      final base = _baseFromPrice(entry.priceWithIva, entry.ivaPct);
      final ivaUnit = entry.priceWithIva - base;
      i += ivaUnit * entry.qty;
    });
    return i;
  }

  double get total {
    double t = 0;
    _cart.forEach((_, entry) {
      t += entry.priceWithIva * entry.qty;
    });
    return t;
  }

  double _baseFromPrice(double priceWithIva, double ivaPct) {
    final factor = 1 + (ivaPct / 100.0);
    return priceWithIva / factor;
  }

  void _addProduct({
    required int id,
    required String name,
    required double priceWithIva,
    required double ivaPct,
  }) {
    setState(() {
      if (_cart.containsKey(id)) {
        _cart[id] = _cart[id]!.copyWith(qty: _cart[id]!.qty + 1);
      } else {
        _cart[id] = _CartEntry(
          productId: id,
          name: name,
          priceWithIva: priceWithIva,
          ivaPct: ivaPct,
          qty: 1,
        );
      }
    });
  }

  void _increaseQty(int productId) {
    final entry = _cart[productId];
    if (entry == null) return;
    setState(() {
      _cart[productId] = entry.copyWith(qty: entry.qty + 1);
    });
  }

  void _decreaseQty(int productId) {
    final entry = _cart[productId];
    if (entry == null) return;
    setState(() {
      if (entry.qty <= 1) {
        _cart.remove(productId);
      } else {
        _cart[productId] = entry.copyWith(qty: entry.qty - 1);
      }
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }

  Future<void> _askCustomerAndRegister() async {
    if (_cart.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos en el pedido.')),
      );
      return;
    }

    final ctrl = TextEditingController(text: _lastCustomer);

    // usar rootNavigator para evitar pantalla negra
    final rootCtx = Navigator.of(context, rootNavigator: true).context;

    final ok = await showDialog<bool>(
      context: rootCtx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirmar pedido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa el nombre del cliente (opcional).'),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: 'Cliente'),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: \$${total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (ok == true) {
      // convertir carrito a lo que espera la DB
      final salesController = ref.read(salesControllerProvider);
      final items = _cart.values.map((entry) {
        return CartItemInput(
          productId: entry.productId,
          productName: entry.name,
          priceWithIva: entry.priceWithIva,
          ivaPct: entry.ivaPct,
          qty: entry.qty,
        );
      }).toList();

      await salesController.registerSale(
        customerName: ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
        items: items,
      );

      setState(() {
        _lastCustomer = ctrl.text.trim();
        _cart.clear();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta registrada.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 720;

    // construimos líneas del carrito para el panel de detalle
    final cartLines = _cart.values
        .map(
          (e) => CartLine(
            id: e.productId,
            name: e.name,
            price: e.priceWithIva,
            ivaPct: e.ivaPct,
            qty: e.qty,
            onIncrease: () => _increaseQty(e.productId),
            onDecrease: () => _decreaseQty(e.productId),
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xfff2f2f6),
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  // panel de productos
                  Expanded(
                    flex: 2,
                    child: productsAsync.when(
                      data: (products) {
                        if (products.isEmpty) {
                          return const Center(
                            child: Text('No hay productos.'),
                          );
                        }
                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.4,
                          ),
                          itemCount: products.length,
                          itemBuilder: (_, index) {
                            final p = products[index];
                            return InkWell(
                              onTap: () => _addProduct(
                                id: p.id,
                                name: p.name,
                                priceWithIva: p.price,
                                ivaPct: p.ivaPct,
                              ),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      Text(
                                          '\$${p.price.toStringAsFixed(2)} (IVA incl.)'),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, st) => Center(
                        child: Text('Error: $err'),
                      ),
                    ),
                  ),
                  // panel de detalle
                  SizedBox(
                    width: 360,
                    child: _DetailPanel(
                      items: cartLines,
                      onClear: _clearCart,
                      onRegister: _askCustomerAndRegister,
                      subtotal: subtotal,
                      iva: iva,
                      total: total,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  // en pantallas angostas, productos arriba
                  Expanded(
                    child: productsAsync.when(
                      data: (products) {
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: products.length,
                          itemBuilder: (_, index) {
                            final p = products[index];
                            return ListTile(
                              title: Text(p.name),
                              subtitle: Text(
                                  '\$${p.price.toStringAsFixed(2)} (IVA incl.)'),
                              onTap: () => _addProduct(
                                id: p.id,
                                name: p.name,
                                priceWithIva: p.price,
                                ivaPct: p.ivaPct,
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, st) => Center(
                        child: Text('Error: $err'),
                      ),
                    ),
                  ),
                  // y detalle abajo
                  SizedBox(
                    height: 300,
                    child: _DetailPanel(
                      items: cartLines,
                      onClear: _clearCart,
                      onRegister: _askCustomerAndRegister,
                      subtotal: subtotal,
                      iva: iva,
                      total: total,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ======================================================
//   Widgets de detalle (parte derecha) SIN overflow
// ======================================================

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({
    required this.items,
    required this.onClear,
    required this.onRegister,
    required this.subtotal,
    required this.iva,
    required this.total,
  });

  final List<CartLine> items;
  final VoidCallback onClear;
  final VoidCallback onRegister;
  final double subtotal;
  final double iva;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // título
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Detalle',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          // lista scrollable
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('Sin productos'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final line = items[index];
                      return _DetailLine(line: line);
                    },
                  ),
          ),
          // totales
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _totalRow('Subtotal (sin IVA)', subtotal),
                _totalRow('IVA', iva),
                const Divider(),
                _totalRow('Total', total, isBold: true),
              ],
            ),
          ),
          // botones fijos abajo
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onClear,
                    child: const Text('Vaciar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onRegister,
                    child: const Text('Registrar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: isBold
              ? const TextStyle(fontWeight: FontWeight.bold)
              : null,
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '\$${line.price.toStringAsFixed(2)} (IVA incl.)  |  IVA ${line.ivaPct.toStringAsFixed(1)}%  | Cant: ${line.qty}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        // controles
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove, size: 18),
              onPressed: line.onDecrease,
            ),
            Text('${line.qty}'),
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              onPressed: line.onIncrease,
            ),
          ],
        ),
      ],
    );
  }
}

// ======================================================
//   Modelos/chismecitos internos de la página
// ======================================================

class _CartEntry {
  final int productId;
  final String name;
  final double priceWithIva;
  final double ivaPct;
  final int qty;

  _CartEntry({
    required this.productId,
    required this.name,
    required this.priceWithIva,
    required this.ivaPct,
    required this.qty,
  });

  _CartEntry copyWith({
    int? productId,
    String? name,
    double? priceWithIva,
    double? ivaPct,
    int? qty,
  }) {
    return _CartEntry(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      priceWithIva: priceWithIva ?? this.priceWithIva,
      ivaPct: ivaPct ?? this.ivaPct,
      qty: qty ?? this.qty,
    );
    }
}

class CartLine {
  final int id;
  final String name;
  final double price;
  final double ivaPct;
  final int qty;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  CartLine({
    required this.id,
    required this.name,
    required this.price,
    required this.ivaPct,
    required this.qty,
    required this.onIncrease,
    required this.onDecrease,
  });
}
