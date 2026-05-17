import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    return Container(
      width: 250,
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                const Icon(Icons.memory, color: AppTheme.primary, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'INFINITY\nCACHE',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      height: 1.1,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _NavItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            isSelected: location == '/',
            onTap: () => context.go('/'),
          ),
          _NavItem(
            icon: Icons.folder_special_outlined,
            label: 'Interception',
            isSelected: location == '/interception',
            onTap: () => context.go('/interception'),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppTheme.primary, blurRadius: 4, spreadRadius: 2),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('DAEMON ACTIVE', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isSelected ? AppTheme.primary : Colors.transparent,
              width: 4,
            ),
          ),
          color: isSelected ? AppTheme.primary.withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
