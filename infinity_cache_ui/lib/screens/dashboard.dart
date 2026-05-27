import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../main.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bridge = BridgeProvider.of(context);

    return Scaffold(
      body: ListenableBuilder(
        listenable: bridge,
        builder: (context, _) {
          final metrics = bridge.metrics;
          return AmbientCanvas(
            status: metrics.status,
            child: Row(
              children: [
                // 1. Sleek B2B Left Sidebar
                Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    border: Border(
                      right: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: Column(
                          children: [
                            // Shield Brand Icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.shield_outlined,
                                color: AppTheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Connection status glowing light
                            Tooltip(
                              message: 'Aegis-One Core Connected',
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.success,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.success.withValues(
                                        alpha: 0.6,
                                      ),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Sidebar bottom action trigger
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: IconButton(
                          icon: Icon(
                            Icons.settings_input_component,
                            color: AppTheme.textSecondary,
                            size: 24,
                          ),
                          onPressed: () {
                            bridge.resetHmb();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Main Workspace Split Panel
                Expanded(
                  child: Row(
                    children: [
                      // LEFT WORKSPACE PANEL: Interactive Hardware Twin Visualizer (42% width)
                      Expanded(
                        flex: 42,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AEGIS-ONE DIGITAL TWIN',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Phase 3: Monolithic M.2 2280 Elastic HMB Architecture',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 24),
                              Expanded(
                                child: GlassCard(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: HardwareBoardVisualizer(
                                      status: metrics.status,
                                      isStressed: bridge.isStressed,
                                      ufsWearArray: metrics.ufsWearArray,
                                      hmbPressure: metrics.hmbPressure,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Divider Line
                      Container(
                        width: 1.0,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),

                      // RIGHT WORKSPACE PANEL: Dynamic Tabbed Control Panel (58% width)
                      Expanded(
                        flex: 58,
                        child: DefaultTabController(
                          length: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header bar with Status Indicator & Simulation Toggle
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'TOTAL SSD REPLACEMENT',
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .displayLarge
                                                ?.copyWith(fontSize: 24),
                                          ),
                                          Text(
                                            'MEMORY-PERSISTENCE CONTINUUM ACTIVE • V${metrics.backendVersion}',
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelSmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _StatusChip(status: metrics.status),
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          onPressed: bridge.metrics.hmbMaxPages < 1000
                                              ? bridge.resetHmb
                                              : bridge.simulateHmbPressure,
                                          icon: Icon(
                                            bridge.metrics.hmbMaxPages < 1000
                                                ? Icons.refresh
                                                : Icons.compress,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          label: Text(
                                            bridge.metrics.hmbMaxPages < 1000
                                                ? "RESET HMB"
                                                : "SIMULATE PRESSURE",
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                bridge.metrics.hmbMaxPages < 1000
                                                ? AppTheme.success
                                                : AppTheme.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // B2B TabBar
                                TabBar(
                                  isScrollable: false,
                                  dividerColor: Colors.transparent,
                                  indicatorColor: AppTheme.primary,
                                  labelColor: AppTheme.primary,
                                  labelStyle: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                  unselectedLabelColor: AppTheme.textSecondary,
                                  tabs: const [
                                    Tab(text: "LIVE TELEMETRY"),
                                    Tab(text: "UFS ARRAY HEALTH"),
                                    Tab(text: "1M-WRITE DEMO"),
                                    Tab(text: "THERMAL DYNAMICS"),
                                    Tab(text: "CONSUMER ROI"),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Tab Views
                                Expanded(
                                  child: TabBarView(
                                    physics:
                                        const NeverScrollableScrollPhysics(), 
                                    children: [
                                      // Tab 1: Live Analytics & Graph View
                                      SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _MetricCard(
                                                    title: 'HOST IOPS',
                                                    value: metrics.iops
                                                        .toStringAsFixed(0),
                                                    unit: ' ops/sec',
                                                    color: AppTheme.primary,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: _MetricCard(
                                                    title: 'THROUGHPUT',
                                                    value: metrics.throughputMb
                                                        .toStringAsFixed(1),
                                                    unit: ' MB/s',
                                                    color: AppTheme.accent,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),
                                            GlassCard(
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  20.0,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'BURST PERFORMANCE TRACKER',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleLarge
                                                          ?.copyWith(
                                                            fontSize: 14,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    SizedBox(
                                                      height: 180,
                                                      child: _IopsChart(
                                                        history:
                                                            bridge.iopsHistory,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: _HmbPressureCard(
                                                    pressure: metrics.hmbPressure,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    children: [
                                                      _UfsWearCard(
                                                        wear: metrics
                                                            .ufsWearPercentage,
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      _PseudoSlcCard(
                                                        active: metrics.pseudoSlcActive,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Tab 2: UFS Array Health
                                      SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'PERSISTENCE VAULT: UFS 4.0 ARRAY',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(fontSize: 15),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Real-time heatmap of the 4-channel high-speed UFS persistence layer',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                            ),
                                            const SizedBox(height: 24),
                                            _CellHealthGrid(
                                              wearArray: metrics.ufsWearArray,
                                              averageWear:
                                                  metrics.ufsWearPercentage,
                                            ),
                                            const SizedBox(height: 24),
                                            _VaultStatsCard(
                                              totalCapacity: '2.0 TB',
                                              redundancy: 'Asynchronous RAID-0',
                                              writeEndurance: 'Infinite*',
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Tab 3: 1M-Write Absorption Demo
                                      _WriteAbsorptionDemoTab(bridge: bridge),

                                      // Tab 4: Thermal Dynamics
                                      _ThermalDynamicsTab(bridge: bridge),

                                      // Tab 5: Consumer ROI
                                      _ConsumerRoiTab(bridge: bridge),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TABS & COMPONENTS
// ═══════════════════════════════════════════════════════════

class _ConsumerRoiTab extends StatelessWidget {
  final dynamic bridge;
  const _ConsumerRoiTab({required this.bridge});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONSUMER TOTAL COST OF OWNERSHIP (TCO)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'Comparing Aegis-One against the 2026 standard 2TB NVMe SSD market.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _RoiStatCard(
                  title: 'PURCHASE PRICE',
                  value: '₹10,500',
                  label: '50% below market average',
                  color: AppTheme.success,
                  icon: Icons.shopping_cart_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _RoiStatCard(
                  title: 'EXPECTED LIFESPAN',
                  value: '10+ YEARS',
                  label: 'vs 3 years for QLC SSDs',
                  color: AppTheme.primary,
                  icon: Icons.update,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _TcoRow(
                    label: 'Samsung 990 Pro 2TB',
                    price: '₹21,500',
                    life: '36 Months',
                    isWorst: true,
                  ),
                  const Divider(height: 32),
                  _TcoRow(
                    label: 'Aegis-One 2TB',
                    price: '₹10,500',
                    life: '120+ Months',
                    isBest: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _TotalSavingsBanner(
            savings: '₹32,500',
            duration: 'Over 6 Years',
          ),
        ],
      ),
    );
  }
}

class _WriteAbsorptionDemoTab extends StatelessWidget {
  final dynamic bridge;
  const _WriteAbsorptionDemoTab({required this.bridge});

  @override
  Widget build(BuildContext context) {
    final bool running = bridge.demo1MRunning as bool;
    final int total = bridge.demo1MTotal as int;
    final int consumed = bridge.demo1MConsumed as int;
    final double progress = total > 0 ? consumed / total : 0.0;
    final double nvmeEquivWrites = consumed * 4.2;
    final double ufsActualWrites = consumed * 0.0008;
    final double reductionRatio = nvmeEquivWrites > 0
        ? (nvmeEquivWrites - ufsActualWrites) / nvmeEquivWrites
        : 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.bolt, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 14),
                      Text('1M-WRITE ABSORPTION DEMO', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  LinearProgressIndicator(value: progress, minHeight: 12),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: running ? null : bridge.start1MDemo,
                    child: Text(running ? 'RUNNING...' : 'START 1M-WRITE TEST'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _DemoResultCard(title: 'UFS WRITES', value: ufsActualWrites.toStringAsFixed(0), label: 'Physical Cell Wear', color: AppTheme.success, icon: Icons.memory)),
              const SizedBox(width: 16),
              Expanded(child: _DemoResultCard(title: 'NVMe EQUIVALENT', value: nvmeEquivWrites.toStringAsFixed(0), label: 'Wear on QLC Drive', color: AppTheme.danger, icon: Icons.storage)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThermalDynamicsTab extends StatelessWidget {
  final dynamic bridge;
  const _ThermalDynamicsTab({required this.bridge});

  @override
  Widget build(BuildContext context) {
    final metrics = bridge.metrics;
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _MetricCard(title: 'ASIC TEMP', value: metrics.temperature.toStringAsFixed(1), unit: '°C', color: AppTheme.primary)),
              const SizedBox(width: 16),
              Expanded(child: _MetricCard(title: 'PERFORMANCE', value: (metrics.performanceMultiplier * 100).toStringAsFixed(0), unit: '%', color: AppTheme.success)),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: bridge.startThermalStress, child: const Text('APPLY THERMAL STRESS')),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// LOW-LEVEL UI COMPONENTS
// ═══════════════════════════════════════════════════════════

class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }
}

class AmbientCanvas extends StatefulWidget {
  final String status;
  final Widget child;
  const AmbientCanvas({super.key, required this.status, required this.child});
  @override
  State<AmbientCanvas> createState() => _AmbientCanvasState();
}

class _AmbientCanvasState extends State<AmbientCanvas> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }
  @override
  void dispose() { _pulseController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.5,
              colors: [
                AppTheme.primary.withValues(alpha: 0.05 * _pulseController.value),
                AppTheme.background,
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

class HardwareBoardVisualizer extends StatelessWidget {
  final String status;
  final bool isStressed;
  final List<double> ufsWearArray;
  final double hmbPressure;

  const HardwareBoardVisualizer({
    super.key,
    required this.status,
    required this.isStressed,
    required this.ufsWearArray,
    required this.hmbPressure,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: HardwareBoardPainter(
        status: status,
        isStressed: isStressed,
        ufsWearArray: ufsWearArray,
        hmbPressure: hmbPressure,
      ),
      child: Container(),
    );
  }
}

class HardwareBoardPainter extends CustomPainter {
  final String status;
  final bool isStressed;
  final List<double> ufsWearArray;
  final double hmbPressure;

  HardwareBoardPainter({
    required this.status,
    required this.isStressed,
    required this.ufsWearArray,
    required this.hmbPressure,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = w / 2;

    // Draw Board
    final paintBoard = Paint()..color = const Color(0xFF020617);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(center, h / 2), width: w * 0.8, height: h * 0.8), const Radius.circular(8)), paintBoard);

    // ASIC
    final paintAsic = Paint()..color = const Color(0xFF1E293B);
    canvas.drawRect(Rect.fromCenter(center: Offset(center, h / 2 - 80), width: 50, height: 50), paintAsic);

    // HMB Visual (Simulated as a glow around the ASIC)
    final paintHmb = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.2 + (hmbPressure * 0.5))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(center, h / 2 - 80), 30 + (hmbPressure * 20), paintHmb);

    // UFS Chips (4 channels)
    for (int i = 0; i < 4; i++) {
      final chipX = center - 60 + (i * 40);
      final chipY = h / 2 + 50;
      final paintChip = Paint()..color = Color.lerp(const Color(0xFF0F172A), AppTheme.accent, ufsWearArray[i])!;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(chipX, chipY), width: 30, height: 30), const Radius.circular(2)), paintChip);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CellHealthGrid extends StatelessWidget {
  final List<double> wearArray;
  final double averageWear;
  const _CellHealthGrid({required this.wearArray, required this.averageWear});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('UFS 4.0 ARRAY HEALTH'),
            Text('${(100 - averageWear).toStringAsFixed(1)}% HEALTHY', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
          itemCount: 4,
          itemBuilder: (context, i) => Container(
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4)),
            child: Center(child: Text('${(wearArray[i] * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 10))),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title, value, unit;
  final Color color;
  const _MetricCard({required this.title, required this.value, required this.unit, required this.color});
  @override
  Widget build(BuildContext context) {
    return GlassCard(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 8),
      Row(children: [Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)), Text(unit, style: TextStyle(fontSize: 12, color: color))]),
    ])));
  }
}

class _IopsChart extends StatelessWidget {
  final List<double> history;
  const _IopsChart({required this.history});
  @override
  Widget build(BuildContext context) {
    return LineChart(LineChartData(
      lineBarsData: [LineChartBarData(spots: history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(), isCurved: true, color: AppTheme.primary, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: AppTheme.primary.withValues(alpha: 0.1)))],
      titlesData: const FlTitlesData(show: false),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
    ));
  }
}

class _HmbPressureCard extends StatelessWidget {
  final double pressure;
  const _HmbPressureCard({required this.pressure});
  @override
  Widget build(BuildContext context) {
    return GlassCard(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('HMB PRESSURE'),
      const SizedBox(height: 8),
      LinearProgressIndicator(value: pressure, color: pressure > 0.8 ? AppTheme.danger : AppTheme.primary),
      const SizedBox(height: 4),
      Text('${(pressure * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 10)),
    ])));
  }
}

class _UfsWearCard extends StatelessWidget {
  final double wear;
  const _UfsWearCard({required this.wear});
  @override
  Widget build(BuildContext context) {
    return GlassCard(child: Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const Text('ARRAY WEAR', style: TextStyle(fontSize: 10)),
      Text('${wear.toStringAsFixed(3)}%', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
    ])));
  }
}

class _PseudoSlcCard extends StatelessWidget {
  final bool active;
  const _PseudoSlcCard({required this.active});
  @override
  Widget build(BuildContext context) {
    return GlassCard(child: Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const Text('PSEUDO-SLC', style: TextStyle(fontSize: 10)),
      Text(active ? 'ACTIVE' : 'IDLE', style: TextStyle(color: active ? AppTheme.success : AppTheme.textSecondary, fontWeight: FontWeight.bold)),
    ])));
  }
}

class _ThermalChart extends StatelessWidget {
  final List<double> aegisHistory, nvmeHistory;
  const _ThermalChart({required this.aegisHistory, required this.nvmeHistory});
  @override
  Widget build(BuildContext context) {
    return LineChart(LineChartData(
      lineBarsData: [
        LineChartBarData(spots: aegisHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(), isCurved: true, color: AppTheme.primary, dotData: const FlDotData(show: false)),
        LineChartBarData(spots: nvmeHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(), isCurved: true, color: AppTheme.danger, dotData: const FlDotData(show: false)),
      ],
      titlesData: const FlTitlesData(show: false),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
    ));
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2))),
      child: Text(status, style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _VaultStatsCard extends StatelessWidget {
  final String totalCapacity, redundancy, writeEndurance;
  const _VaultStatsCard({required this.totalCapacity, required this.redundancy, required this.writeEndurance});
  @override
  Widget build(BuildContext context) {
    return GlassCard(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      _StatRow(label: 'Usable Capacity', value: totalCapacity),
      const Divider(),
      _StatRow(label: 'Endurance', value: writeEndurance),
    ])));
  }
}

class _StatRow extends StatelessWidget {
  final String label, value;
  const _StatRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 12)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]);
  }
}

class _RoiStatCard extends StatelessWidget {
  final String title, value, label;
  final Color color;
  final IconData icon;
  const _RoiStatCard({required this.title, required this.value, required this.label, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) {
    return GlassCard(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: color, size: 16), const SizedBox(width: 8), Text(title, style: TextStyle(color: color, fontSize: 10))]),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
    ])));
  }
}

class _TcoRow extends StatelessWidget {
  final String label, price, life;
  final bool isBest, isWorst;
  const _TcoRow({required this.label, required this.price, required this.life, this.isBest = false, this.isWorst = false});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isBest ? AppTheme.success : (isWorst ? AppTheme.danger : Colors.white))), Text('Lifespan: $life', style: const TextStyle(fontSize: 10))]),
      Text(price, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isBest ? AppTheme.success : Colors.white)),
    ]);
  }
}

class _TotalSavingsBanner extends StatelessWidget {
  final String savings, duration;
  const _TotalSavingsBanner({required this.savings, required this.duration});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.success.withValues(alpha: 0.2))),
      child: Column(children: [
        const Text('TOTAL PROJECTED SAVINGS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.success)),
        Text(savings, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.success)),
        Text(duration, style: const TextStyle(fontSize: 12, color: AppTheme.success)),
      ]),
    );
  }
}

class _DemoResultCard extends StatelessWidget {
  final String title, value, label;
  final Color color;
  final IconData icon;
  const _DemoResultCard({required this.title, required this.value, required this.label, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) {
    return GlassCard(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: color, size: 14), const SizedBox(width: 4), Text(title, style: TextStyle(color: color, fontSize: 10))]),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(fontSize: 10)),
    ])));
  }
}

class _ThermalSpecRow extends StatelessWidget {
  final String label, value;
  const _ThermalSpecRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 10)), Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]));
  }
}
