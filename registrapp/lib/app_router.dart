import 'package:go_router/go_router.dart';
import 'ui/shared/shell.dart';
import 'ui/register/register_page.dart';
import 'ui/orders/orders_page.dart';
import 'ui/datos/totals_page.dart';
import 'ui/gastos/expenses_page.dart';
import 'ui/products/products_page.dart';

final router = GoRouter(
  initialLocation: '/caja',
  routes: [
    ShellRoute(
      builder: (context, state, child) => Shell(child: child),
      routes: [
        GoRoute(
          path: '/caja',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/pedidos',
          builder: (context, state) => const OrdersPage(),
        ),
        GoRoute(
          path: '/datos',
          builder: (context, state) => const TotalsPage(),
        ),
        GoRoute(
          path: '/gastos',
          builder: (context, state) => const ExpensesPage(),
        ),
        GoRoute(
          path: '/productos',
          builder: (context, state) => const ProductsPage(),
        ),
      ],
    ),
  ],
);
