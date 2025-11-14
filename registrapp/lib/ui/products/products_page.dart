import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/products_provider.dart';
import '../../data/db.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  static const _iva = 'Precio (IVA incl.)';
  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());

    if (name.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos inválidos')),
      );
      return;
    }

    final controller = ref.read(productsControllerProvider);
    await controller.addProduct(
      name: name,
      price: price,
    );

    _nameCtrl.clear();
    _priceCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);

    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;
    final isTight = width < 500; // pantalla tipo celular más angosta

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Productos',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Los precios deben ingresarse con IVA incluido (15%).',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),

          // --- Formulario para agregar producto nuevo ---
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: isTight
                  // Layout VERTICAL para pantallas angostas
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del producto',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _priceCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration: const InputDecoration(
                            labelText: _iva,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _addProduct,
                          child: const Text('Agregar'),
                        ),
                      ],
                    )
                  // Layout HORIZONTAL para pantallas más anchas
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del producto',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _priceCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: const InputDecoration(
                              labelText: _iva,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _addProduct,
                          child: const Text('Agregar'),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // --- Grilla de productos ---
          Expanded(
            child: productsAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Text('No hay productos aún.'),
                  );
                }

                // En tablet grande mostramos 3 por fila.
                // En cel/tablet chica mostramos 2 por fila.
                final crossAxisCount = isWide ? 3 : 2;

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    // hacemos las tarjetas un poco más altas en cel
                    childAspectRatio: isWide ? 1.4 : 0.95,
                  ),
                  itemCount: list.length,
                  itemBuilder: (_, index) {
                    final p = list[index];
                    return _ProductCard(
                      product: p,
                      compact: isTight, // <- para botones apilados
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({
    required this.product,
    required this.compact,
  });

  final Product product;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> handleDelete() async {
      // usamos el rootNavigator para asegurar que el diálogo se monte
      // por encima de toda la app, no dentro de una subruta
      final confirmed = await showDialog<bool>(
        context: Navigator.of(context, rootNavigator: true).context,
        builder: (dialogCtx) {
          return AlertDialog(
            title: const Text('Eliminar producto'),
            content: Text(
              '¿Seguro que quieres eliminar "${product.name}"?',
            ),
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
          );
        },
      );

      // si el widget ya no está montado (por ejemplo, navegué rápido),
      // no intentes hacer nada más
      if (!context.mounted) return;

      if (confirmed == true) {
        final controller = ref.read(productsControllerProvider);
        await controller.deleteProduct(product.id);
      }
    }

    Future<void> handleEdit() async {
      await _showEditDialog(
        // igual nos aseguramos rootNavigator para el modal de edición
        Navigator.of(context, rootNavigator: true).context,
        ref,
        product,
      );

      if (!context.mounted) return;
    }

    final editButton = OutlinedButton.icon(
      icon: const Icon(Icons.edit, size: 18),
      label: const Text('Editar'),
      onPressed: handleEdit,
    );

    final deleteButton = IconButton(
      icon: const Icon(Icons.delete, color: Colors.red),
      onPressed: handleDelete,
    );

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final infoSection = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Precio (IVA incl.):',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );

            final actionsSection = compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: editButton,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: deleteButton,
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: editButton),
                      deleteButton,
                    ],
                  );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoSection,
                const Spacer(),
                actionsSection,
              ],
            );
          },
        ),
      ),
    );
  }
}


Future<void> _showEditDialog(
    BuildContext parentContext, WidgetRef ref, Product product) async {
  final nameCtrl = TextEditingController(text: product.name);
  final priceCtrl =
      TextEditingController(text: product.price.toStringAsFixed(2));

  final saved = await showDialog<bool>(
    context: Navigator.of(parentContext, rootNavigator: true).context,
    builder: (dialogCtx) {
      return AlertDialog(
        title: const Text('Editar producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Precio (IVA incl.)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );

  // Si el usuario ya se fue de la pantalla, no sigas
  if (!(parentContext.mounted)) return;

  if (saved == true) {
    final newName = nameCtrl.text.trim();
    final newPrice = double.tryParse(priceCtrl.text.trim());

    if (newName.isEmpty || newPrice == null) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(content: Text('Datos inválidos')),
      );
      return;
    }

    final controller = ref.read(productsControllerProvider);
    await controller.updateProduct(
      product.copyWith(
        name: newName,
        price: newPrice,
        // ivaPct se fuerza a 15% dentro del controller
      ),
    );
  }
}
