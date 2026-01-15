import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/expenses_provider.dart';


class ExpensesPage extends ConsumerStatefulWidget {
  const ExpensesPage({super.key});
  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage> {
  // Categorías de ejemplo. Luego serán configurables.
  final cats = const ['Insumos', 'Transporte', 'Servicios', 'Otros'];
  String? selected;
  final amountCtrl = TextEditingController();

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _addExpense() async {
    final value = double.tryParse(amountCtrl.text);

    if (selected == null || value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una categoría e ingresa un monto válido.'),
        ),
      );
      return;
    }

    final controller = ref.read(expensesControllerProvider);
    await controller.addExpense(category: selected!, amount: value);

    amountCtrl.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gasto agregado a "$selected".')),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final expensesAsync = ref.watch(todayExpensesStreamProvider);
    double totalExpenses = 0;

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

          ],
        ),
      ),
    );



    expensesAsync.whenData((list) {
      totalExpenses = list.fold(0.0, (s, e) => s + e.amount);
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: isWide
          ? Row(children: [Expanded(flex: 3, child: grid), const SizedBox(width: 16), Expanded(flex: 2, child: panel)])
          : Column(children: [Expanded(child: grid), const SizedBox(height: 16), SizedBox(height: 320, child: panel)]),
    );
  }
}
