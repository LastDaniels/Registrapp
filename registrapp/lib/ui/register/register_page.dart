import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/products_provider.dart';
import '../shared/product_card_placeholder.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final Map<int, _CartLine> cart = {}; // key = product.id
  String customer = '';

  // --- helpers de impuestos con IVA incluido ---
  double _baseUnit(double priceWithIva, double ivaPct) {
    final factor = 1 + (ivaPct / 100.0);
    return priceWithIva / factor;
  }

  double _ivaUnit(double priceWithIva, double ivaPct) {
    return priceWithIva - _baseUnit(priceWithIva, ivaPct);
  }

  // subtotal sin IVA (suma de bases)
  double get subtotal {
    double sum = 0;
    for (final line in cart.values) {
      final baseUnit = _baseUnit(line.price, line.ivaPct);
      sum += baseUnit * line.qty;
    }
    return sum;
  }

  // total IVA (suma de solo IVA)
  double get iva {
    double sum = 0;
    for (final line in cart.values) {
      final ivaUnit = _ivaUnit(line.price, line.ivaPct);
      sum += ivaUnit * line.qty;
    }
    return sum;
  }

  // total final cobrado (precio con IVA * qty)
  double get total {
    double sum = 0;
    for (final line in cart.values) {
      sum += line.price * line.qty;
    }
    return sum;
  }

  void _inc({
    required int id,
    required String name,
    required double price,
    required double ivaPct,
  }) {
    setState(() {
      cart.update(
        id,
        (line) => line.copyWith(qty: line.qty + 1),
        ifAbsent: () => _CartLine(
          id: id,
          name: name,
          price: price,
          ivaPct: ivaPct,
          qty: 1,
        ),
      );
    });
  }

  void _dec(int id) {
    setState(() {
      final line = cart[id];
      if (line == null) return;
      final q = line.qty - 1;
      if (q <= 0) {
        cart.remove(id);
      } else {
        cart[id] = line.copyWith(qty: q);
      }
    });
  }

  Future<void> _askCustomerAndRegister() async {
    final ctrl = TextEditingController(text: customer);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() {
        customer = ctrl.text.trim();
        // Semana 2: todavía no guardamos en tabla de ventas.
        cart.clear();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta registrada (sin impresión).')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: productsAsync.when(
        data: (products) {
          // ==== LEFT PANEL: catálogo ====
          final left = GridView.count(
            crossAxisCount: isWide ? 3 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (final p in products)
                ProductCardPlaceholder(
                  title: p.name,
                  price: p.price,
                  onAdd: () => _inc(
                    id: p.id,
                    name: p.name,
                    price: p.price,
                    ivaPct: p.ivaPct,
                  ),
                ),
            ],
          );

          // ==== RIGHT PANEL: carrito ====
          final right = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Detalle', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: cart.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final line = cart.values.elementAt(i);

                    final baseUnitVal = _baseUnit(line.price, line.ivaPct);
                    final ivaUnitVal = _ivaUnit(line.price, line.ivaPct);

                    final lineBase = baseUnitVal * line.qty;
                    final lineIva = ivaUnitVal * line.qty;
                    final lineTotal = line.price * line.qty;

                    return ListTile(
                      title: Text(line.name),
                      subtitle: Text(
                        // ejemplo:
                        // $3.00 (IVA incl.) | IVA 15% | Cant: 2
                        '\$${line.price.toStringAsFixed(2)} (IVA incl.)'
                        '  |  IVA ${line.ivaPct.toStringAsFixed(0)}%'
                        '  |  Cant: ${line.qty}',
                      ),
                      trailing: SizedBox(
                        width: 180,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: () => _dec(line.id),
                                  icon: const Icon(Icons.remove),
                                ),
                                Text(line.qty.toString()),
                                IconButton(
                                  onPressed: () => _inc(
                                    id: line.id,
                                    name: line.name,
                                    price: line.price,
                                    ivaPct: line.ivaPct,
                                  ),
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                            Text(
                              // mostramos total de esta línea
                              '\$${lineTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              // desglose interno
                              'Base: \$${lineBase.toStringAsFixed(2)}\nIVA:  \$${lineIva.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Divider(),
              _totalsSection(),

              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          cart.clear();
                        });
                      },
                      child: const Text('Vaciar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: cart.isEmpty
                          ? null
                          : _askCustomerAndRegister,
                      child: const Text('Registrar (sin imprimir)'),
                    ),
                  ),
                ],
              ),
            ],
          );

          // ==== responsive layout ====
          return isWide
              ? Row(
                  children: [
                    Expanded(flex: 3, child: left),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: right),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: left),
                    const SizedBox(height: 16),
                    SizedBox(height: 360, child: right),
                  ],
                );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error cargando productos: $err'),
        ),
      ),
    );
  }

  Widget _totalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _totalRow('Subtotal (sin IVA)', subtotal),
        _totalRow('IVA', iva),
        _totalRow('Total', total, bold: true),
      ],
    );
  }

  Widget _totalRow(String label, double value, {bool bold = false}) {
    final style = bold
        ? const TextStyle(fontWeight: FontWeight.bold)
        : const TextStyle();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('\$${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}

class _CartLine {
  final int id;
  final String name;
  final double price; // ya incluye IVA
  final double ivaPct;
  final int qty;

  const _CartLine({
    required this.id,
    required this.name,
    required this.price,
    required this.ivaPct,
    required this.qty,
  });

  _CartLine copyWith({int? qty}) {
    return _CartLine(
      id: id,
      name: name,
      price: price,
      ivaPct: ivaPct,
      qty: qty ?? this.qty,
    );
  }
}
