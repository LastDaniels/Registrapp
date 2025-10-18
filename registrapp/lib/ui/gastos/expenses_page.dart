import 'package:flutter/material.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});
  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  // Categorías de ejemplo. Luego serán configurables.
  final cats = const ['Insumos', 'Transporte', 'Servicios', 'Otros'];
  String? selected;
  final amountCtrl = TextEditingController();

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }

  void _addExpense() {
    final ok = double.tryParse(amountCtrl.text);
    if (selected == null || ok == null || ok <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría e ingresa un monto válido.')),
      );
      return;
    }
    // Semana 1: solo feedback. Semana 5 guardamos y sumamos al total del día.
    amountCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gasto agregado a "$selected".')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    final grid = GridView.count(
      crossAxisCount: isWide ? 3 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        for (final c in cats)
          Card(
            color: selected == c ? Theme.of(context).colorScheme.primaryContainer : null,
            child: InkWell(
              onTap: () => setState(() => selected = c),
              child: Center(
                child: Text(c, style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
          ),
      ],
    );

    final panel = Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Gastos', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Categoría seleccionada: ${selected ?? '—'}'),
            const SizedBox(height: 8),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto (\$)', hintText: '0.00'),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _addExpense, child: const Text('Agregar gasto')),
            const Spacer(),
            const Divider(),
            const ListTile(
              title: Text('Total gastos del día'),
              trailing: Text('\$0.00'),
            ),
            const SizedBox(height: 8),
            const Text('• Al final del día se resta de lo generado para la ganancia.'),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: isWide
          ? Row(children: [Expanded(flex: 3, child: grid), const SizedBox(width: 16), Expanded(flex: 2, child: panel)])
          : Column(children: [Expanded(child: grid), const SizedBox(height: 16), SizedBox(height: 320, child: panel)]),
    );
  }
}
