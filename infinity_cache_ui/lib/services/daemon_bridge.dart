import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Metrics {
  final double iops;
  final double throughputMb;
  final double hmbPressure; // 0.0 to 1.0
  final double hmbPressurePercentage;
  final double ufsWearPercentage;
  final List<double> ufsWearArray; // Wear for 4 channels
  final String status;
  final int totalIos;
  final double moneySaved;
  final double ssdLifeExtended;
  final String backendVersion;
  final double temperature; 
  final double performanceMultiplier; 
  final bool pseudoSlcActive;
  final int hmbMaxPages;
  final int lostDirtyPagesCount;
  final bool hostPlpEnabled;

  const Metrics({
    required this.iops,
    required this.throughputMb,
    required this.hmbPressure,
    required this.hmbPressurePercentage,
    required this.ufsWearPercentage,
    required this.ufsWearArray,
    required this.status,
    required this.totalIos,
    required this.moneySaved,
    required this.ssdLifeExtended,
    required this.backendVersion,
    required this.temperature,
    required this.performanceMultiplier,
    required this.pseudoSlcActive,
    required this.hmbMaxPages,
    required this.lostDirtyPagesCount,
    required this.hostPlpEnabled,
  });
}

class DaemonBridge extends ChangeNotifier {
  Metrics _metrics = Metrics(
    iops: 0,
    throughputMb: 0,
    hmbPressure: 0,
    hmbPressurePercentage: 0,
    ufsWearPercentage: 0.1,
    ufsWearArray: List.filled(4, 0.001),
    status: "DISCONNECTED",
    totalIos: 0,
    moneySaved: 0.0,
    ssdLifeExtended: 0.0,
    backendVersion: "AEGIS-V3.0",
    temperature: 25.0,
    performanceMultiplier: 1.0,
    pseudoSlcActive: false,
    hmbMaxPages: 4096,
    lostDirtyPagesCount: 0,
    hostPlpEnabled: true,
  );

  Metrics get metrics => _metrics;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  List<double> iopsHistory = List.filled(60, 0.0, growable: true);
  List<double> throughputHistory = List.filled(60, 0.0, growable: true);
  List<double> aegisTempHistory = List.filled(60, 25.0, growable: true);
  List<double> nvmeTempHistory = List.filled(60, 25.0, growable: true);
  double _simulatedNvmeTemp = 25.0;

  // 1M-write demo tracking
  int demo1MTotal = 0;
  int demo1MConsumed = 0;
  bool get demo1MRunning => demo1MTotal > 0 && demo1MConsumed < demo1MTotal;

  bool _hmbPressureSimulated = false;

  final List<_IoSample> _ioSamples = [];

  DaemonBridge() {
    _connect();
  }

  bool _isActuallyConnected = false;

  String lastRawData = "WAITING FOR DATA...";
  int packetsReceived = 0;

  void _connect() {
    _isActuallyConnected = false;
    debugPrint("DaemonBridge: Attempting connection to ws://127.0.0.1:3030...");
    _startMockTelemetry();
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://127.0.0.1:3030'));
      _subscription = _channel!.stream.listen(
        (data) {
          packetsReceived++;
          lastRawData = data.toString();
          if (!_isActuallyConnected) {
            debugPrint(
              "DaemonBridge: CONNECTION ESTABLISHED. Switching to LIVE mode.",
            );
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

      double mockIops = _isStressed
          ? 25000 + (random % 5000).toDouble()
          : 120 + (random % 300).toDouble();
      double mockThroughput = (mockIops * 4096) / (1024 * 1024);
      
      double mockPressure = _hmbPressureSimulated ? 0.92 : (_isStressed ? 0.45 : 0.08);

      final double addedMoney = (mockIops / 1000000);
      final double addedLife = (mockIops / 10000000);

      _metrics = Metrics(
        iops: mockIops,
        throughputMb: mockThroughput,
        hmbPressure: mockPressure,
        hmbPressurePercentage: mockPressure * 100.0,
        ufsWearPercentage: 0.15,
        ufsWearArray: List.filled(4, 0.002),
        status: "MOCK_DEMO_MODE",
        totalIos: _metrics.totalIos + (mockIops / 2).toInt(),
        moneySaved: _metrics.moneySaved + addedMoney,
        ssdLifeExtended: _metrics.ssdLifeExtended + addedLife,
        backendVersion: "AEGIS-V3-MOCK",
        temperature: 25.0 + (_isStressed ? 18.0 : 4.0) + (random % 5) / 10.0,
        performanceMultiplier: 1.0,
        pseudoSlcActive: mockPressure > 0.85,
        hmbMaxPages: _hmbPressureSimulated ? 512 : 4096,
        lostDirtyPagesCount: _metrics.lostDirtyPagesCount,
        hostPlpEnabled: _metrics.hostPlpEnabled,
      );

      // Update thermal history
      _simulatedNvmeTemp = _isStressed
          ? (_simulatedNvmeTemp + 0.6).clamp(25.0, 95.0)
          : (_simulatedNvmeTemp - 0.1).clamp(25.0, 95.0);
      
      final newATemp = List<double>.from(aegisTempHistory);
      newATemp.removeAt(0);
      newATemp.add(_metrics.temperature);
      aegisTempHistory = newATemp;
      final newNTemp = List<double>.from(nvmeTempHistory);
      newNTemp.removeAt(0);
      newNTemp.add(_simulatedNvmeTemp);
      nvmeTempHistory = newNTemp;

      if (demo1MRunning) {
        demo1MConsumed = (demo1MConsumed + (mockIops / 2).toInt()).clamp(0, demo1MTotal);
      }

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
      final Map<String, dynamic> json = jsonDecode(data.trim());

      final double totalIos = (json['total_ios'] as num).toDouble();
      final DateTime now = DateTime.now();

      _ioSamples.add(_IoSample(now, totalIos));
      _ioSamples.retainWhere((s) => now.difference(s.time).inMilliseconds < 1000);

      double currentIops = 0;
      if (_ioSamples.length > 1) {
        final firstSample = _ioSamples.first;
        final lastSample = _ioSamples.last;
        final elapsedSec = lastSample.time.difference(firstSample.time).inMilliseconds / 1000.0;
        if (elapsedSec > 0.1) {
          currentIops = (lastSample.totalIos - firstSample.totalIos) / elapsedSec;
        }
      }

      final double currentThroughput = (currentIops * 4096) / (1024 * 1024);
      final double pressurePct = (json['hmb_pressure_percentage'] as num).toDouble();
      final List<dynamic> wearArrayRaw = json['chip_wear_array'] as List<dynamic>;
      final List<double> ufsWears = wearArrayRaw.map((e) => (e as num).toDouble()).toList();

      final double gbWritten = (totalIos * 4096) / (1024 * 1024 * 1024);
      final double moneySaved = gbWritten * 0.12; // Adjusted for new pricing gap
      final double ssdLifeExtended = gbWritten / 5.0;

      _metrics = Metrics(
        iops: currentIops,
        throughputMb: currentThroughput,
        hmbPressure: pressurePct / 100.0,
        hmbPressurePercentage: pressurePct,
        ufsWearPercentage: (json['ufs_wear_percentage'] as num).toDouble(),
        ufsWearArray: ufsWears,
        status: json['status'],
        totalIos: totalIos.toInt(),
        moneySaved: moneySaved,
        ssdLifeExtended: ssdLifeExtended,
        backendVersion: json['version'] ?? "V3-ALPHA",
        temperature: (json['temperature'] as num).toDouble(),
        performanceMultiplier: (json['performance_multiplier'] as num).toDouble(),
        pseudoSlcActive: json['pseudo_slc_active'] as bool,
        hmbMaxPages: (json['hmb_max_pages'] as num).toInt(),
        lostDirtyPagesCount: (json['lost_dirty_pages_count'] as num?)?.toInt() ?? 0,
        hostPlpEnabled: json['host_plp_enabled'] as bool? ?? true,
      );

      _simulatedNvmeTemp = (_simulatedNvmeTemp + (currentIops > 30000 ? 0.4 : -0.05)).clamp(25.0, 98.0);

      final newATemp = List<double>.from(aegisTempHistory);
      newATemp.removeAt(0);
      newATemp.add(_metrics.temperature);
      aegisTempHistory = newATemp;

      final newNTemp = List<double>.from(nvmeTempHistory);
      newNTemp.removeAt(0);
      newNTemp.add(_simulatedNvmeTemp);
      nvmeTempHistory = newNTemp;

      if (demo1MRunning) {
        demo1MConsumed = (demo1MConsumed + (currentIops * 0.3).toInt()).clamp(0, demo1MTotal);
      }

      final newIopsHistory = List<double>.from(iopsHistory);
      newIopsHistory.removeAt(0);
      newIopsHistory.add(currentIops);
      iopsHistory = newIopsHistory;

      final newTpHistory = List<double>.from(throughputHistory);
      newTpHistory.removeAt(0);
      newTpHistory.add(currentThroughput);
      throughputHistory = newTpHistory;

      notifyListeners();
    } catch (e) {
      debugPrint("DaemonBridge: Error parsing live data: $e");
    }
  }

  bool _isStressed = false;
  bool get isStressed => _isStressed;

  void toggleStressTest() {
    _isStressed = !_isStressed;
    if (_isActuallyConnected) {
      _channel?.sink.add(_isStressed ? "START_STRESS_TEST" : "STOP_STRESS_TEST");
    }
    notifyListeners();
  }

  void simulateHmbPressure() {
    if (_isActuallyConnected) {
      _channel?.sink.add("SIMULATE_HMB_PRESSURE");
    } else {
      _hmbPressureSimulated = true;
      notifyListeners();
    }
  }

  void resetHmb() {
    if (_isActuallyConnected) {
      _channel?.sink.add("RESET_HMB");
    } else {
      _hmbPressureSimulated = false;
      notifyListeners();
    }
  }

  void startThermalStress() {
    if (_isActuallyConnected) _channel?.sink.add("START_THERMAL_STRESS");
    notifyListeners();
  }

  void stopThermalStress() {
    if (_isActuallyConnected) _channel?.sink.add("STOP_THERMAL_STRESS");
    notifyListeners();
  }

  void start1MDemo() {
    demo1MTotal = 1000000;
    demo1MConsumed = 0;
    if (_isActuallyConnected) {
      _channel?.sink.add("START_1M_DEMO");
    } else {
      _isStressed = true;
    }
    notifyListeners();
  }

  void triggerSuddenPowerLoss() {
    if (_isActuallyConnected) {
      _channel?.sink.add("TRIGGER_SUDDEN_POWER_LOSS");
    } else {
      // Mock mode increments lost count for display simulation if PLP is disabled
      if (!_metrics.hostPlpEnabled) {
        _metrics = _metrics.copyWith(
          lostDirtyPagesCount: _metrics.lostDirtyPagesCount + 45,
        );
      }
    }
    notifyListeners();
  }

  void toggleHostPlp() {
    if (_isActuallyConnected) {
      _channel?.sink.add("TOGGLE_HOST_PLP");
    } else {
      _metrics = _metrics.copyWith(hostPlpEnabled: !_metrics.hostPlpEnabled);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}

extension MetricsExtension on Metrics {
  Metrics copyWith({String? status, int? lostDirtyPagesCount, bool? hostPlpEnabled}) {
    return Metrics(
      iops: iops,
      throughputMb: throughputMb,
      hmbPressure: hmbPressure,
      hmbPressurePercentage: hmbPressurePercentage,
      ufsWearPercentage: ufsWearPercentage,
      ufsWearArray: ufsWearArray,
      status: status ?? this.status,
      totalIos: totalIos,
      moneySaved: moneySaved,
      ssdLifeExtended: ssdLifeExtended,
      backendVersion: backendVersion,
      temperature: temperature,
      performanceMultiplier: performanceMultiplier,
      pseudoSlcActive: pseudoSlcActive,
      hmbMaxPages: hmbMaxPages,
      lostDirtyPagesCount: lostDirtyPagesCount ?? this.lostDirtyPagesCount,
      hostPlpEnabled: hostPlpEnabled ?? this.hostPlpEnabled,
    );
  }
}

class _IoSample {
  final DateTime time;
  final double totalIos;
  _IoSample(this.time, this.totalIos);
}
