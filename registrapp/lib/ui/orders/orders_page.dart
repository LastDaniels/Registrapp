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
          Text(
            'Pedidos de hoy (${DateTime.now().toLocal().toString().split(" ").first})',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: salesAsync.when(
              data: (sales) {
                if (sales.isEmpty) {
                  return const Center(
                    child: Text('No hay pedidos hoy.'),
                  );
                }

                return ListView.separated(
                  itemCount: sales.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final sale = sales[index];

                    final displayNumber = index + 1;

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(displayNumber.toString()),
                      ),
                      title: Text(
                        'Pedido #$displayNumber  -  \$${sale.total.toStringAsFixed(2)}',
                      ),
                      subtitle: Text(
                        (sale.customerName ?? 'Sin nombre') +
                            ' • ' +
                            sale.createdAt
                                .toLocal()
                                .toString()
                                .split('.')
                                .first,
                      ),
                      // aquí más adelante poner ver detalle / reimprimir
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
