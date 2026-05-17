import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/dashboard.dart';
import '../screens/interception.dart';
import '../widgets/sidebar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return Scaffold(
          body: Row(
            children: [
              const Sidebar(),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(child: child),
            ],
          ),
        );
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/interception',
          builder: (context, state) => const InterceptionScreen(),
        ),
      ],
    ),
  ],
);
