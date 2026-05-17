import 'package:flutter/material.dart';
import '../core/theme.dart';

class TrackedPath {
  final String path;
  final int writesAvoided;
  final String category;
  final bool active;

  TrackedPath({
    required this.path,
    required this.writesAvoided,
    required this.category,
    this.active = true,
  });
}

class InterceptionScreen extends StatefulWidget {
  const InterceptionScreen({super.key});

  @override
  State<InterceptionScreen> createState() => _InterceptionScreenState();
}

class _InterceptionScreenState extends State<InterceptionScreen> {
  // Mock data for the UI layout
  final List<TrackedPath> _paths = [
    TrackedPath(path: 'C:\\Projects\\infinity_cache_sim\\target\\', writesAvoided: 8452091, category: 'Rust/Cargo'),
    TrackedPath(path: 'C:\\Projects\\infinity_cache_ui\\build\\', writesAvoided: 120534, category: 'Flutter/Dart'),
    TrackedPath(path: 'C:\\Users\\peter\\AppData\\Local\\Temp\\Adobe\\', writesAvoided: 45091223, category: 'Video Editor'),
    TrackedPath(path: 'C:\\Projects\\web_app\\node_modules\\', writesAvoided: 33405, category: 'Node.js', active: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ACTIVE INTERCEPTIONS', style: Theme.of(context).textTheme.displayLarge),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, color: AppTheme.background),
                label: const Text('ADD PATH', style: TextStyle(color: AppTheme.background, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Card(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _paths.length,
                separatorBuilder: (context, index) => Divider(color: AppTheme.textSecondary.withOpacity(0.1)),
                itemBuilder: (context, index) {
                  final path = _paths[index];
                  return _PathTile(path: path);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PathTile extends StatelessWidget {
  final TrackedPath path;

  const _PathTile({required this.path});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: path.active ? AppTheme.primary.withOpacity(0.1) : AppTheme.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.folder_open,
              color: path.active ? AppTheme.primary : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  path.path,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: path.active ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        border: Border.all(color: AppTheme.textSecondary.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        path.category,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      path.active ? 'Status: Hooked & Syncing' : 'Status: Paused',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'NAND WRITES AVOIDED',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                _formatNumber(path.writesAvoided),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: path.active ? AppTheme.accent : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Switch(
            value: path.active,
            onChanged: (val) {},
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
