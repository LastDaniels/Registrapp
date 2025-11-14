import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/summary_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/db_provider.dart';
import '../../data/db.dart';

class TotalsPage extends ConsumerStatefulWidget {
  const TotalsPage({super.key});

  @override
  ConsumerState<TotalsPage> createState() => _TotalsPageState();
}

class _TotalsPageState extends ConsumerState<TotalsPage> {
  DailySummary? _lastSummary;
  bool _loading = false;

  Future<void> _loadSummary({bool close = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
    });

    final summaryController = ref.read(summaryControllerProvider);
    final db = ref.read(dbProvider);

    // 1. obtener el resumen
    final DailySummary summary = close
        ? await summaryController.closeTodayCash()
        : await summaryController.getTodaySummary();

    // si la página ya no está montada, salimos
    if (!mounted) return;

    // 2. si es cerrar caja, borramos las ventas del día
    if (close) {
      // esto borra sales y sale_items
      await db.clearDailySales();
      ref.invalidate(todaySalesStreamProvider);

    }

    setState(() {
      _lastSummary = summary;
      _loading = false;
    });

    // 3. mostrar diálogo con el resumen
    _showSummaryDialog(summary, closed: close);
  }

  void _showSummaryDialog(DailySummary summary, {required bool closed}) {
    final rootCtx = Navigator.of(context, rootNavigator: true).context;

    showDialog(
      context: rootCtx,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(closed ? 'Caja cerrada' : 'Resumen del día'),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fecha: ${summary.day.toLocal().toString().split(".").first}',
                  style: Theme.of(dialogCtx).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text('Subtotal: \$${summary.subtotal.toStringAsFixed(2)}'),
                Text('IVA:      \$${summary.iva.toStringAsFixed(2)}'),
                Text(
                  'TOTAL:    \$${summary.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Items vendidos:',
                  style: Theme.of(dialogCtx)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 160,
                  child: summary.items.isEmpty
                      ? const Text('No hay ventas registradas.')
                      : ListView.builder(
                          itemCount: summary.items.length,
                          itemBuilder: (_, i) {
                            final it = summary.items[i];
                            return Text(
                                '- ${it.name}  x${it.qty}  \$${it.totalAmount.toStringAsFixed(2)}');
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 700;

    // ventas del día (se resetean solas porque la consulta filtra por fecha)
    final salesAsync = ref.watch(todaySalesStreamProvider);
    // item más vendido en histórico (no se resetea)
    final bestItemAsync = ref.watch(mostSoldItemProvider);

    double kpiSubtotal = 0;
    double kpiIva = 0;
    double kpiTotal = 0;

    salesAsync.whenData((sales) {
      for (final s in sales) {
        kpiSubtotal += s.subtotal;
        kpiIva += s.iva;
        kpiTotal += s.total;
      }
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Datos', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Totales del día (se vacían al cerrar caja) y un KPI histórico.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),

          // Botones de acción
          Row(
            children: [
              FilledButton(
                onPressed:
                    _loading ? null : () => _loadSummary(close: false),
                child: const Text('Resumen del día'),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: _loading ? null : () => _loadSummary(close: true),
                child: const Text('Cerrar caja'),
              ),
              if (_loading) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ]
            ],
          ),

          const SizedBox(height: 20),

          // KPIs diarios SIEMPRE visibles
          salesAsync.when(
            data: (_) {
              if (isWide) {
                return Row(
                  children: [
                    _KpiCard(
                      title: 'Total del día',
                      value: '\$${kpiTotal.toStringAsFixed(2)}',
                      icon: Icons.attach_money,
                    ),
                    const SizedBox(width: 12),
                    _KpiCard(
                      title: 'Subtotal',
                      value: '\$${kpiSubtotal.toStringAsFixed(2)}',
                      icon: Icons.table_rows,
                    ),
                    const SizedBox(width: 12),
                    _KpiCard(
                      title: 'IVA',
                      value: '\$${kpiIva.toStringAsFixed(2)}',
                      icon: Icons.receipt_long,
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _KpiCard(
                      title: 'Total del día',
                      value: '\$${kpiTotal.toStringAsFixed(2)}',
                      icon: Icons.attach_money,
                    ),
                    const SizedBox(height: 12),
                    _KpiCard(
                      title: 'Subtotal',
                      value: '\$${kpiSubtotal.toStringAsFixed(2)}',
                      icon: Icons.table_rows,
                    ),
                    const SizedBox(height: 12),
                    _KpiCard(
                      title: 'IVA',
                      value: '\$${kpiIva.toStringAsFixed(2)}',
                      icon: Icons.receipt_long,
                    ),
                  ],
                );
              }
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error: $err'),
          ),

          const SizedBox(height: 16),

          // KPI histórico: item más vendido
          bestItemAsync.when(
            data: (item) {
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text('Item más vendido'),
                  subtitle: Text(
                    item == null
                        ? 'Aún no hay ventas'
                        : '${item.name} — ${item.qty} uds.',
                  ),
                  trailing: item == null
                      ? null
                      : Text('\$${item.totalAmount.toStringAsFixed(2)}'),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (err, _) =>
                Text('Error cargando histórico: $err'),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.primary.withOpacity(0.1),
                child: Icon(icon, color: color.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    value,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
