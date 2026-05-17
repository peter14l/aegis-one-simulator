import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Metrics {
  final double iops;
  final double throughputMb;
  final double saturation; // 0.0 to 1.0
  final bool voltageStable;
  final double voltage;
  final double emmcWear;
  final double supercapCharge;
  final String status;
  final int totalIos;
  final double moneySaved;
  final double ssdLifeExtended;
  final String backendVersion;

  const Metrics({
    required this.iops,
    required this.throughputMb,
    required this.saturation,
    required this.voltageStable,
    required this.voltage,
    required this.emmcWear,
    required this.supercapCharge,
    required this.status,
    required this.totalIos,
    required this.moneySaved,
    required this.ssdLifeExtended,
    required this.backendVersion,
  });
}

class DaemonBridge extends ChangeNotifier {
  Metrics _metrics = const Metrics(
    iops: 0,
    throughputMb: 0,
    saturation: 0,
    voltageStable: true,
    voltage: 3.3,
    emmcWear: 0.001,
    supercapCharge: 100,
    status: "DISCONNECTED",
    totalIos: 0,
    moneySaved: 0.0,
    ssdLifeExtended: 0.0,
    backendVersion: "N/A",
  );

  Metrics get metrics => _metrics;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  List<double> iopsHistory = List.filled(60, 0.0, growable: true);
  List<double> throughputHistory = List.filled(60, 0.0, growable: true);

  double? _lastTotalIos;
  DateTime _lastUpdateTime = DateTime.now();

  DaemonBridge() {
    _connect();
  }

  bool _isActuallyConnected = false;

  String lastRawData = "WAITING FOR DATA...";
  int packetsReceived = 0;

  void _connect() {
    _isActuallyConnected = false;
    debugPrint("DaemonBridge: Attempting connection to ws://localhost:3030...");
    _startMockTelemetry(); 
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:3030'));
      _subscription = _channel!.stream.listen(
        (data) {
          packetsReceived++;
          lastRawData = data.toString();
          if (!_isActuallyConnected) {
            debugPrint("DaemonBridge: CONNECTION ESTABLISHED. Switching to LIVE mode.");
            _isActuallyConnected = true;
          }
          _handleData(data);
        },
        onDone: () {
          debugPrint("DaemonBridge: WS Connection closed.");
          _isActuallyConnected = false;
          _metrics = _metrics.copyWith(status: "WS_CLOSED");
          notifyListeners();
          Future.delayed(const Duration(seconds: 2), _connect);
        },
        onError: (e) {
          debugPrint("DaemonBridge: WS Error: $e");
          _isActuallyConnected = false;
          _metrics = _metrics.copyWith(status: "WS_ERROR");
          notifyListeners();
          Future.delayed(const Duration(seconds: 2), _connect);
        },
      );
    } catch (e) {
      debugPrint("DaemonBridge: Exception during connect: $e");
      _isActuallyConnected = false;
      Future.delayed(const Duration(seconds: 2), _connect);
    }
  }

  Timer? _mockTimer;
  void _startMockTelemetry() {
    _mockTimer?.cancel();
    _mockTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_isActuallyConnected) return;

      final random = DateTime.now().millisecondsSinceEpoch;
      
      final double mockIops = _isStressed 
          ? 18000 + (random % 4000).toDouble() 
          : 50 + (random % 150).toDouble();
      
      final double mockThroughput = (mockIops * 4096) / (1024 * 1024);
      
      final double addedMoney = (mockIops / 1000000);
      final double addedLife = (mockIops / 10000000);

      _metrics = Metrics(
        iops: mockIops,
        throughputMb: mockThroughput,
        saturation: _isStressed ? 0.82 + (random % 50) / 1000.0 : 0.12 + (random % 50) / 1000.0,
        voltageStable: true,
        voltage: 3.29 + (random % 2) / 100.0,
        emmcWear: 0.002,
        supercapCharge: 99.9,
        status: "MOCK_DEMO_MODE",
        totalIos: _metrics.totalIos + (mockIops / 2).toInt(),
        moneySaved: _metrics.moneySaved + addedMoney,
        ssdLifeExtended: _metrics.ssdLifeExtended + addedLife,
        backendVersion: "UI-EMULATOR",
      );

      final newIops = List<double>.from(iopsHistory);
      newIops.removeAt(0);
      newIops.add(mockIops);
      iopsHistory = newIops;

      final newTp = List<double>.from(throughputHistory);
      newTp.removeAt(0);
      newTp.add(mockThroughput);
      throughputHistory = newTp;
      
      notifyListeners();
    });
  }


  void _handleData(String data) {
    try {
      String cleanData = data.trim();
      if (!cleanData.startsWith('{') && cleanData.contains('{')) {
        // Attempt to recover if it starts with garbage like "[CORE]" or "[DAEMON]"
        cleanData = cleanData.substring(cleanData.indexOf('{'));
      }
      
      final Map<String, dynamic> json = jsonDecode(cleanData);
      
      debugPrint("Flutter received: $cleanData");
      
      final double totalIos = (json['total_ios'] as num).toDouble();
      final DateTime now = DateTime.now();
      
      double currentIops = 0;
      debugPrint("IOPS calc: total=$totalIos, last=$_lastTotalIos");
      if (_lastTotalIos != null) {
        final double elapsedSec = now.difference(_lastUpdateTime).inMilliseconds / 1000.0;
        debugPrint("IOPS calc: elapsed=${elapsedSec}s");
        if (elapsedSec > 0) {
          final double deltaIos = totalIos - _lastTotalIos!;
          debugPrint("IOPS calc: delta=$deltaIos");
          if (deltaIos >= 0) {
            currentIops = deltaIos / elapsedSec;
            debugPrint("IOPS calc: RESULT=$currentIops");
          }
        }
      }
      
      _lastTotalIos = totalIos;
      _lastUpdateTime = now;

      final double currentThroughput = (currentIops * 4096) / (1024 * 1024);
      final double saturation = (json['active_pages'] as num) / (json['max_pages'] as num);
      final double voltage = (json['voltage'] as num).toDouble();

      final double gbWritten = (totalIos * 4096) / (1024 * 1024 * 1024);
      final double moneySaved = gbWritten * 0.05; 
      final double ssdLifeExtended = gbWritten / 10.0;

      _metrics = Metrics(
        iops: currentIops,
        throughputMb: currentThroughput,
        saturation: saturation,
        voltageStable: voltage >= 2.9,
        voltage: voltage,
        emmcWear: (json['emmc_wear_percentage'] as num).toDouble(),
        supercapCharge: (json['supercap_charge'] as num).toDouble(),
        status: json['status'],
        totalIos: totalIos.toInt(),
        moneySaved: moneySaved,
        ssdLifeExtended: ssdLifeExtended,
        backendVersion: json['version'] ?? "V1-LEGACY",
      );

      final List<double> newIopsHistory = List.from(iopsHistory);
      newIopsHistory.removeAt(0);
      newIopsHistory.add(currentIops);
      iopsHistory = newIopsHistory;
      
      final List<double> newTpHistory = List.from(throughputHistory);
      newTpHistory.removeAt(0);
      newTpHistory.add(currentThroughput);
      throughputHistory = newTpHistory;

      notifyListeners();
    } catch (e) {
      debugPrint("DaemonBridge: Error parsing live data: $e");
      notifyListeners(); // ENSURE UI UPDATES even on error to show debug state
    }
  }

  bool _isStressed = false;
  bool get isStressed => _isStressed;

  void toggleStressTest() {
    _isStressed = !_isStressed;
    debugPrint("DaemonBridge: toggleStressTest() -> $_isStressed");
    
    if (_isActuallyConnected) {
      if (_isStressed) {
        _channel?.sink.add("START_STRESS_TEST");
      } else {
        _channel?.sink.add("STOP_STRESS_TEST");
      }
    }
    notifyListeners();
  }

  void simulatePowerFailure() {
    debugPrint("DaemonBridge: simulatePowerFailure() clicked.");
    _channel?.sink.add("SIMULATE_POWER_LOSS");
  }

  void resetPower() {
    debugPrint("DaemonBridge: resetPower() clicked.");
    _channel?.sink.add("RESET_POWER");
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}

extension MetricsExtension on Metrics {
  Metrics copyWith({String? status}) {
    return Metrics(
      iops: iops,
      throughputMb: throughputMb,
      saturation: saturation,
      voltageStable: voltageStable,
      voltage: voltage,
      emmcWear: emmcWear,
      supercapCharge: supercapCharge,
      status: status ?? this.status,
      totalIos: totalIos,
      moneySaved: moneySaved,
      ssdLifeExtended: ssdLifeExtended,
      backendVersion: backendVersion,
    );
  }
}
