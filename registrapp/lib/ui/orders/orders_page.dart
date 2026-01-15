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
                    final sw = sales[index];
                    final sale = sw.sale;
                    final items = sw.items;
                    final isDelivered = sale.status == 'delivered';
                    final displayNumber = index + 1;
                    Future<void> confirmDelete() async {
                      final rootCtx = Navigator.of(context, rootNavigator: true).context;

                      final ok = await showDialog<bool>(
                        context: rootCtx,
                        builder: (dialogCtx) => AlertDialog(
                          title: const Text('Eliminar pedido'),
                          content: const Text('¿Seguro que deseas eliminar este pedido? Esta acción no se puede deshacer.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogCtx, false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(dialogCtx, true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );

                      if (ok == true) {
                        final ctrl = ref.read(salesControllerProvider);
                        await ctrl.deleteSale(saleId: sale.id);

                        ref.invalidate(todaySalesStreamProvider);
                        ref.invalidate(mostSoldItemProvider);
                      }
                    }

                    return ExpansionTile(
                      leading: CircleAvatar(
                        child: Text(displayNumber.toString()),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Pedido #$displayNumber  -  \$${sale.total.toStringAsFixed(2)}',
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDelivered ? Colors.green[100] : Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isDelivered ? 'Entregado' : 'Pendiente',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDelivered ? Colors.green[800] : Colors.orange[800],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: confirmDelete,
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Eliminar pedido',
                          ),
                        ],
                      ),


                      subtitle: Text(
                        '${sale.customerName ?? 'Sin nombre'} • '
                        '${sale.createdAt.toLocal().toString().split(".").first}',
                      ),
                      children: [
                        for (final it in items)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text('${it.qty} × ${it.productName}'),
                                ),
                                Text('\$${(it.priceWithIva * it.qty).toStringAsFixed(2)}'),

                              ],
                            ),
                          ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Total: \$${sale.total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Marcar como entregado'),
                              Checkbox(
                                value: isDelivered,
                                onChanged: (v) {
                                  final ctrl = ref.read(salesControllerProvider);
                                  ctrl.setDelivered(
                                    saleId: sale.id,
                                    delivered: v ?? false,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                      ],
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
