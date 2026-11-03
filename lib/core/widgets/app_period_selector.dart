import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class AppPeriodOption<T> {
  final T value;
  final String label;

  const AppPeriodOption({required this.value, required this.label});
}

/// Compact segmented control for switching between periods, tabs or views.
class AppPeriodSelector<T> extends StatelessWidget {
  final List<AppPeriodOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool expanded;

  const AppPeriodSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = sc.Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: scheme.muted,
        borderRadius: theme.borderRadiusMd,
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: options.map((option) {
          final isSelected = option.value == selected;
          final tile = sc.Clickable(
            onPressed: () => onChanged(option.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: expanded ? 9 : 5,
              ),
              decoration: BoxDecoration(
                color: isSelected ? scheme.primary : Colors.transparent,
                borderRadius: theme.borderRadiusSm,
              ),
              child: Text(
                option.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: expanded ? 13 : 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? scheme.primaryForeground
                      : scheme.mutedForeground,
                ),
              ),
            ),
          );
          return expanded ? Expanded(child: tile) : tile;
        }).toList(),
      ),
    );
  }
}
