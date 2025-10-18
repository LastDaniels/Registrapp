import 'package:flutter/material.dart';
import '../shared/product_card_placeholder.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final Map<String, _CartLine> cart = {};
  String customer = '';

  // MOCK de productos (Semana 1). Semana 2 lo cambiaremos por DB.
  final products = const [
    ('Arroz con pollo', 4.50, 12.0),
    ('Seco de pollo', 4.50, 12.0),
    ('Jugo de naranja', 1.20, 12.0),
    ('Sopa del día', 2.00, 12.0),
    ('Empanada', 0.80, 12.0),
    ('Gaseosa', 1.00, 12.0),
  ];

  double get subtotal =>
      cart.values.fold(0, (p, e) => p + (e.price * e.qty));
  double get iva =>
      cart.values.fold(0, (p, e) => p + ((e.price * e.ivaPct / 100) * e.qty));
  double get total => subtotal + iva;

  void _inc(String name, double price, double ivaPct) {
    setState(() {
      cart.update(
        name,
        (l) => l.copyWith(qty: l.qty + 1),
        ifAbsent: () => _CartLine(name, price, ivaPct, 1),
      );
    });
  }

  void _dec(String name) {
    setState(() {
      final l = cart[name];
      if (l == null) return;
      final q = l.qty - 1;
      if (q <= 0) {
        cart.remove(name);
      } else {
        cart[name] = l.copyWith(qty: q);
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
            TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Cliente')),
            const SizedBox(height: 8),
            Text('Total: \$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Registrar')),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        customer = ctrl.text.trim();
        // Semana 1: solo limpiamos carrito (mock de “registrado”).
        cart.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta registrada (sin impresión).')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    final left = GridView.count(
      crossAxisCount: isWide ? 3 : 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        for (final p in products)
          ProductCardPlaceholder(
            title: p.$1,
            price: p.$2,
            onAdd: () => _inc(p.$1, p.$2, p.$3),
          ),
      ],
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Detalle', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: cart.length,
            itemBuilder: (_, i) {
              final line = cart.values.elementAt(i);
              final lineTotal = (line.price + line.price * line.ivaPct / 100) * line.qty;
              return ListTile(
                title: Text(line.name),
                subtitle: Text('Item  |  Precio: \$${line.price.toStringAsFixed(2)}  |  IVA ${line.ivaPct.toStringAsFixed(0)}%'),
                trailing: SizedBox(
                  width: 140,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(onPressed: () => _dec(line.name), icon: const Icon(Icons.remove)),
                      Text(line.qty.toString()),
                      IconButton(onPressed: () => _inc(line.name, line.price, line.ivaPct), icon: const Icon(Icons.add)),
                      const SizedBox(width: 8),
                      Text('\$${lineTotal.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
          ),
        ),
        const Divider(),
        _totals(context),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => cart.clear()),
                child: const Text('Vaciar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: cart.isEmpty ? null : _askCustomerAndRegister,
                child: const Text('Registrar (sin imprimir)'),
              ),
            ),
          ],
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: isWide
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
                SizedBox(height: 320, child: right),
              ],
            ),
    );
  }

  Widget _totals(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _kv('Subtotal', subtotal),
        _kv('IVA', iva),
        _kv('Total', total, bold: true),
      ],
    );
  }

  Widget _kv(String k, double v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null),
            Text('\$${v.toStringAsFixed(2)}', style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null),
          ],
        ),
      );
}

class _CartLine {
  final String name;
  final double price;
  final double ivaPct;
  final int qty;
  const _CartLine(this.name, this.price, this.ivaPct, this.qty);
  _CartLine copyWith({int? qty}) => _CartLine(name, price, ivaPct, qty ?? this.qty);
}
