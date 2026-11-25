import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';

class DateRangeFilter extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final ValueChanged<DateTime?> onStartChanged;
  final ValueChanged<DateTime?> onEndChanged;
  final VoidCallback? onClear;
  final String label;

  const DateRangeFilter({
    super.key,
    this.initialStart,
    this.initialEnd,
    required this.onStartChanged,
    required this.onEndChanged,
    this.onClear,
    this.label = 'Date Range',
  });

  @override
  State<DateRangeFilter> createState() => _DateRangeFilterState();
}

class _DateRangeFilterState extends State<DateRangeFilter> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStart;
    _endDate = widget.initialEnd;
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
      widget.onStartChanged(picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      widget.onEndChanged(picked);
    }
  }

  void _clear() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    widget.onStartChanged(null);
    widget.onEndChanged(null);
    widget.onClear?.call();
  }

  bool get _hasFilter => _startDate != null || _endDate != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _pickStartDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _startDate != null
                          ? AppTheme.primaryGreen
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: _startDate != null ? AppTheme.primaryGreen : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _startDate != null
                              ? _dateFormat.format(_startDate!)
                              : 'From',
                          style: TextStyle(
                            fontSize: 12,
                            color: _startDate != null
                                ? (isDark ? Colors.white : Colors.black87)
                                : Colors.grey,
                            fontWeight: _startDate != null ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: _pickEndDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _endDate != null
                          ? AppTheme.primaryGreen
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: _endDate != null ? AppTheme.primaryGreen : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _endDate != null
                              ? _dateFormat.format(_endDate!)
                              : 'To',
                          style: TextStyle(
                            fontSize: 12,
                            color: _endDate != null
                                ? (isDark ? Colors.white : Colors.black87)
                                : Colors.grey,
                            fontWeight: _endDate != null ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_hasFilter) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: _clear,
                icon: const Icon(Icons.clear_rounded, size: 20),
                tooltip: 'Clear date range',
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  foregroundColor: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class DateRangeFilterChip extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onClear;
  final String label;

  const DateRangeFilterChip({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onClear,
    this.label = 'Date Range',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM');

    if (startDate == null && endDate == null) return const SizedBox.shrink();

    String chipLabel;
    if (startDate != null && endDate != null) {
      chipLabel = '$label: ${dateFormat.format(startDate!)} - ${dateFormat.format(endDate!)}';
    } else if (startDate != null) {
      chipLabel = '$label: From ${dateFormat.format(startDate!)}';
    } else {
      chipLabel = '$label: Until ${dateFormat.format(endDate!)}';
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(chipLabel, style: const TextStyle(fontSize: 11)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onClear,
        backgroundColor: AppTheme.primaryGreen.withOpacity(0.12),
        labelStyle: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
        deleteIconColor: AppTheme.primaryGreen,
        side: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.3)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}