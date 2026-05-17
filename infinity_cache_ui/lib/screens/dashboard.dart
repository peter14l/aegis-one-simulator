import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme.dart';
import '../main.dart';
import '../services/daemon_bridge.dart';

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
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SYSTEM TELEMETRY', style: Theme.of(context).textTheme.displayLarge),
                          Text('BACKEND: ${metrics.backendVersion}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary, letterSpacing: 1.1)),
                        ],
                      ),
                      Row(
                        children: [
                          _StatusChip(status: metrics.status),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: bridge.toggleStressTest,
                            icon: Icon(
                              bridge.isStressed ? Icons.stop : Icons.speed,
                              color: Colors.white,
                            ),
                            label: Text(bridge.isStressed ? "STOP STRESS" : "START STRESS"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: bridge.isStressed ? AppTheme.accent : AppTheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: metrics.status == "PANIC_FLUSH" 
                              ? bridge.resetPower 
                              : bridge.simulatePowerFailure,
                            icon: Icon(
                              metrics.status == "PANIC_FLUSH" ? Icons.refresh : Icons.power_off,
                              color: Colors.white,
                            ),
                            label: Text(metrics.status == "PANIC_FLUSH" ? "RESET POWER" : "SIMULATE POWER LOSS"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: metrics.status == "PANIC_FLUSH" ? AppTheme.success : AppTheme.danger,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          title: 'IOPS',
                          value: metrics.iops.toStringAsFixed(0),
                          unit: ' ops/sec',
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _MetricCard(
                          title: 'THROUGHPUT',
                          value: metrics.throughputMb.toStringAsFixed(1),
                          unit: ' MB/s',
                          color: AppTheme.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _ROICard(
                          title: 'ESTIMATED SAVINGS',
                          value: '\$${metrics.moneySaved.toStringAsFixed(2)}',
                          subtitle: 'Saved in NAND replacement costs',
                          icon: Icons.account_balance_wallet_outlined,
                          color: AppTheme.success,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _ROICard(
                          title: 'SSD LIFE EXTENSION',
                          value: '${metrics.ssdLifeExtended.toStringAsFixed(1)} Mo',
                          subtitle: 'Projected life added to primary drive',
                          icon: Icons.favorite_border_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('REAL-TIME IOPS', style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 250,
                                  child: _IopsChart(history: bridge.iopsHistory),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _SaturationCard(saturation: metrics.saturation),
                            const SizedBox(height: 24),
                            _SupercapCard(charge: metrics.supercapCharge),
                            const SizedBox(height: 24),
                            _VoltageCard(voltage: metrics.voltage),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _DebugPanel(bridge: bridge),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DebugPanel extends StatelessWidget {
  final DaemonBridge bridge;
  const _DebugPanel({required this.bridge});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.textSecondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('WS DEBUG CONSOLE', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
              Text('PACKETS: ${bridge.packetsReceived}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'LAST RAW PAYLOAD:',
            style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 9),
          ),
          const SizedBox(height: 4),
          SelectableText(
            bridge.lastRawData,
            style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}


class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case "NORMAL_OPERATION":
        color = AppTheme.success;
        break;
      case "PANIC_FLUSH":
        color = AppTheme.danger;
        break;
      default:
        color = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(color: color, fontSize: 32),
                ),
                Text(unit, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IopsChart extends StatelessWidget {
  final List<double> history;

  const _IopsChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final maxVal = history.reduce((a, b) => a > b ? a : b);
    // Stabilize Y-axis: Use a fixed step of 500, minimum 1000
    final stableMaxY = ((maxVal / 500).ceil() * 500.0 + 500).clamp(1000.0, 1000000.0);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: stableMaxY / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: AppTheme.textSecondary.withOpacity(0.05), strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == meta.max || value == meta.min) return const SizedBox.shrink();
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (history.length - 1).toDouble(),
        minY: 0,
        maxY: stableMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: history.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value);
            }).toList(),
            isCurved: false, // Disable curves to reduce visual jitter during shifts
            color: AppTheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 150), // Smooth transition instead of snap
      curve: Curves.linear,
    );
  }
}

class _SaturationCard extends StatelessWidget {
  final double saturation;

  const _SaturationCard({required this.saturation});

  @override
  Widget build(BuildContext context) {
    final color = saturation > 0.9 ? AppTheme.danger : (saturation > 0.7 ? AppTheme.accent : AppTheme.primary);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text('LPDDR4 CACHE FILL', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            SizedBox(
              height: 100,
              width: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 8,
                    color: AppTheme.textSecondary.withOpacity(0.1),
                  ),
                  CircularProgressIndicator(
                    value: saturation,
                    strokeWidth: 8,
                    color: color,
                    backgroundColor: Colors.transparent,
                  ),
                  Center(
                    child: Text(
                      '${(saturation * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupercapCard extends StatelessWidget {
  final double charge;

  const _SupercapCard({required this.charge});

  @override
  Widget build(BuildContext context) {
    final color = charge < 30 ? AppTheme.danger : (charge < 80 ? AppTheme.accent : AppTheme.success);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SUPERCAPACITOR CHARGE', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: charge / 100.0,
              color: color,
              backgroundColor: AppTheme.textSecondary.withOpacity(0.1),
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${charge.toStringAsFixed(1)}%',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoltageCard extends StatelessWidget {
  final double voltage;

  const _VoltageCard({required this.voltage});

  @override
  Widget build(BuildContext context) {
    final stable = voltage >= 2.9;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VIN VOLTAGE', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  '${voltage.toStringAsFixed(2)}V',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: stable ? AppTheme.success : AppTheme.danger,
                  ),
                ),
              ],
            ),
            Icon(
              stable ? Icons.bolt : Icons.warning_amber_rounded,
              color: stable ? AppTheme.success : AppTheme.danger,
              size: 40,
            ),
          ],
        ),
      ),
    );
  }
}

class _ROICard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ROICard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text(value, style: Theme.of(context).textTheme.displayLarge?.copyWith(color: color, fontSize: 32)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

