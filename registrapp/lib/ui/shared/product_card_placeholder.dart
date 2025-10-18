import 'package:flutter/material.dart';

class ProductCardPlaceholder extends StatelessWidget {
  const ProductCardPlaceholder({
    super.key,
    required this.title,
    required this.price,
    required this.onAdd,
  });

  final String title;
  final double price;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAdd,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$${price.toStringAsFixed(2)}'),
                  FilledButton(onPressed: onAdd, child: const Text('+')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}