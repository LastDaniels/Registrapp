import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sales_provider.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(todaySalesStreamProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pedidos del día',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Expanded(
            child: salesAsync.when(
              data: (sales) {
                if (sales.isEmpty) {
                  return const Center(
                    child: Text('Aún no hay ventas hoy.'),
                  );
                }
                return ListView.separated(
                  itemCount: sales.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final sale = sales[i];
                    return ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: Text(
                        'Venta #${sale.id}  -  \$${sale.total.toStringAsFixed(2)}',
                      ),
                      subtitle: Text(
                        (sale.customerName ?? 'Sin nombre') +
                            ' • ' +
                            sale.createdAt.toLocal().toString(),
                      ),
                      // aquí más adelante: onTap => ver detalle / reimprimir
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
