import 'package:flutter/material.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Semana 1: mock. Semana 3 conectaremos con DB.
    final items = List.generate(8, (i) => ('Venta #${101 + i}', 'Cliente: —', '12:${i}0', 0.0));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pedidos del día', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width >= 900 ? 3 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                for (final e in items)
                  Card(
                    child: ListTile(
                      title: Text(e.$1),
                      subtitle: Text('${e.$2}\nTotal: \$${e.$4.toStringAsFixed(2)}'),
                      isThreeLine: true,
                      trailing: Text(e.$3),
                    ),
                  )
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text('• Aquí agregaremos edición y reimpresión en Semanas 4 y 6.'),
        ],
      ),
    );
  }
}