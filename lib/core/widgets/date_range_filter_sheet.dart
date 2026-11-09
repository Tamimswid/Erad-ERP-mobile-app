import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

import '../constants/app_constants.dart';

/// Tarih aralığı sheet'inin sonucu. `range == null` ise kullanıcı filtreyi
/// temizledi; `show` null dönerse sheet sonuç vermeden kapatıldı.
class AppDateRangeResult {
  final DateTimeRange? range;

  const AppDateRangeResult(this.range);

  bool get isCleared => range == null;
}

/// Uygulama genelinde kullanılan tarih aralığı alt sayfası.
/// İki sekme (başlangıç/bitiş), shadcn date picker ve altta uygula butonu.
class AppDateRangeSheet {
  AppDateRangeSheet._();

  static Future<AppDateRangeResult?> show(
    BuildContext context, {
    DateTimeRange? initialRange,
    String title = 'تصفية حسب التاريخ',
  }) {
    return showModalBottomSheet<AppDateRangeResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusLg),
        ),
      ),
      builder: (_) => _DateRangeSheet(initialRange: initialRange, title: title),
    );
  }
}

class _DateRangeSheet extends StatefulWidget {
  final DateTimeRange? initialRange;
  final String title;

  const _DateRangeSheet({required this.initialRange, required this.title});

  @override
  State<_DateRangeSheet> createState() => _DateRangeSheetState();
}

class _DateRangeSheetState extends State<_DateRangeSheet> {
  int _tabIndex = 0;
  DateTime? _start;
  DateTime? _end;

  bool get _canApply => _start != null && _end != null;

  @override
  void initState() {
    super.initState();
    final range = widget.initialRange;
    if (range == null) return;
    _start = _dateOnly(range.start);
    _end = _dateOnly(range.end);
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String _format(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _apply() {
    final start = _start;
    final end = _end;
    if (start == null || end == null) return;

    final range = start.isAfter(end)
        ? DateTimeRange(start: end, end: start)
        : DateTimeRange(start: start, end: end);
    Navigator.pop(context, AppDateRangeResult(range));
  }

  void _clear() {
    Navigator.pop(context, const AppDateRangeResult(null));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = sc.Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: scheme.foreground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'اختر تاريخ البداية وتاريخ النهاية',
              style: TextStyle(fontSize: 13, color: scheme.mutedForeground),
            ),
            const SizedBox(height: 16),
            sc.Tabs(
              index: _tabIndex,
              onChanged: (index) => setState(() => _tabIndex = index),
              expand: true,
              children: const [
                sc.TabItem(child: Text('تاريخ البداية')),
                sc.TabItem(child: Text('تاريخ النهاية')),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedSize(
              duration: const Duration(milliseconds: 150),
              alignment: Alignment.topCenter,
              child: _buildPicker(),
            ),
            if (_start != null && _end != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: scheme.muted,
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusMd,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      sc.LucideIcons.calendarRange,
                      size: 16,
                      color: scheme.mutedForeground,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'من ${_format(_start!)} إلى ${_format(_end!)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: scheme.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                sc.Button(
                  alignment: Alignment.center,
                  style: const sc.ButtonStyle.outline(),
                  onPressed: _clear,
                  child: const Text('مسح'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: sc.Button(
                    alignment: Alignment.center,
                    style: const sc.ButtonStyle.primary(),
                    onPressed: _canApply ? _apply : null,
                    child: const Text('تطبيق'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPicker() {
    final isStart = _tabIndex == 0;
    final value = isStart ? _start : _end;
    final label = isStart ? 'تاريخ البداية' : 'تاريخ النهاية';

    return Column(
      key: ValueKey(_tabIndex),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: sc.Theme.of(context).colorScheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 8),
        sc.DatePicker(
          value: value,
          mode: sc.PromptMode.dialog,
          dialogTitle: Text(label),
          initialView: sc.CalendarView.fromDateTime(value ?? DateTime.now()),
          placeholder: Text(label),
          onChanged: (picked) {
            if (picked == null) return;
            setState(() {
              if (isStart) {
                _start = _dateOnly(picked);
              } else {
                _end = _dateOnly(picked);
              }
            });
          },
        ),
      ],
    );
  }
}

/// Tarih filtresini açan ortak tetikleyici.
/// [compact] true iken app bar için ikon, değilse aralık etiketli çip.
class AppDateRangeFilterButton extends StatelessWidget {
  final DateTimeRange? range;
  final VoidCallback onPressed;
  final String? fallbackLabel;
  final bool compact;

  const AppDateRangeFilterButton({
    super.key,
    required this.range,
    required this.onPressed,
    this.fallbackLabel,
    this.compact = false,
  });

  static String formatRange(DateTimeRange range) {
    String format(DateTime date) {
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    return '${format(range.start)} - ${format(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = sc.Theme.of(context).colorScheme;
    final isActive = range != null;
    final label = isActive
        ? formatRange(range!)
        : (fallbackLabel ?? 'كل الفترات');

    if (compact) {
      return Semantics(
        button: true,
        label: isActive ? 'تصفية حسب التاريخ، $label' : 'تصفية حسب التاريخ',
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? scheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Icon(
                    sc.LucideIcons.calendarDays,
                    size: 20,
                    color: isActive ? scheme.primary : scheme.foreground,
                  ),
                ),
                if (isActive)
                  Positioned(
                    right: 10,
                    top: 9,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? scheme.primary.withValues(alpha: 0.1)
              : scheme.muted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive
                ? scheme.primary.withValues(alpha: 0.3)
                : scheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sc.LucideIcons.calendarDays,
              size: 16,
              color: isActive ? scheme.primary : scheme.mutedForeground,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? scheme.primary : scheme.foreground,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              sc.LucideIcons.chevronDown,
              size: 14,
              color: isActive ? scheme.primary : scheme.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}
