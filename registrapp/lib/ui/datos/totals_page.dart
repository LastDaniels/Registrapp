import 'package:flutter/material.dart';

class TotalsPage extends StatelessWidget {
  const TotalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Semana 1: valores de ejemplo. Semana 5 usaremos consulta real.
    const totalDia = 0.00;
    const cantPedidos = 0;
    final topItems = const ['—'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Datos (KPIs)', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _KpiCard(title: '\$ Acumulado del día', value: '\$0.00'),
              _KpiCard(title: 'Cantidad de pedidos', value: '0'),
              _KpiCard(title: 'Ítems más vendidos', value: '—'),
            ],
          ),
          const Spacer(),
          const Text('• Luego conectaremos estos KPIs a la DB y al “recibo largo”.'),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.title, required this.value});
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Card(
        child: ListTile(
          title: Text(title),
          trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        ),
      ),
    );
  }
}
