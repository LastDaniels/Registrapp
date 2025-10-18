import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Shell extends StatelessWidget {
  const Shell({super.key, required this.child});
  final Widget child;

  static final _destinations = [
    _NavItem('/caja',    Icons.point_of_sale,  'Caja'),
    _NavItem('/pedidos', Icons.list_alt,       'Pedidos'),
    _NavItem('/datos',   Icons.summarize,      'Datos'),
    _NavItem('/gastos',  Icons.payments,       'Gastos'),
  ];

  @override
  Widget build(BuildContext context) {
    // go_router v16: obtener ubicación actual así
    final loc = GoRouterState.of(context).uri.toString();

    final index = _destinations.indexWhere((d) => loc.startsWith(d.path));
    final selected = index < 0 ? 0 : index;

    final isWide = MediaQuery.of(context).size.width >= 900;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selected,
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.only(top: 12),
                child: FlutterLogo(size: 42),
              ),
              destinations: _destinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        label: Text(d.label),
                      ))
                  .toList(),
              onDestinationSelected: (i) => context.go(_destinations[i].path),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: SafeArea(child: child)),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => context.go(_destinations[i].path),
        destinations: _destinations
            .map((d) => NavigationDestination(icon: Icon(d.icon), label: d.label))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final String label;
  const _NavItem(this.path, this.icon, this.label);
}
