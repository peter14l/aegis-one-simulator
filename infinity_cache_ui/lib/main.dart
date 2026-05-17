import 'package:flutter/material.dart';
import '../core/router.dart';
import '../core/theme.dart';
import '../services/daemon_bridge.dart';

void main() {
  runApp(const InfinityCacheApp());
}

class InfinityCacheApp extends StatefulWidget {
  const InfinityCacheApp({super.key});

  @override
  State<InfinityCacheApp> createState() => _InfinityCacheAppState();
}

class _InfinityCacheAppState extends State<InfinityCacheApp> {
  late final DaemonBridge _daemonBridge;

  @override
  void initState() {
    super.initState();
    _daemonBridge = DaemonBridge();
  }

  @override
  void dispose() {
    _daemonBridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BridgeProvider(
      bridge: _daemonBridge,
      child: MaterialApp.router(
        title: 'Infinity-Cache Manager',
        theme: AppTheme.darkTheme,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class BridgeProvider extends InheritedWidget {
  final DaemonBridge bridge;

  const BridgeProvider({
    super.key,
    required this.bridge,
    required super.child,
  });

  static DaemonBridge of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<BridgeProvider>();
    assert(provider != null, 'No BridgeProvider found in context');
    return provider!.bridge;
  }

  @override
  bool updateShouldNotify(BridgeProvider oldWidget) {
    return bridge != oldWidget.bridge;
  }
}
