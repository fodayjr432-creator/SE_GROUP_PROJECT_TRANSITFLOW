import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../controllers/union_controller.dart';
import '../models/rider.dart';
import '../models/station_zone.dart';
import '../widgets/status_pill.dart';
import 'rider_profile_screen.dart';

/// Screen: Rider List & Search Screen
/// Searchable and filterable list of all registered union riders.
/// Connects to UnionController.filteredRiders, setRiderSearchQuery(),
/// setZoneFilter(), and setInspectionFilter().
class RiderListScreen extends StatefulWidget {
  const RiderListScreen({super.key});

  @override
  State<RiderListScreen> createState() => _RiderListScreenState();
}

class _RiderListScreenState extends State<RiderListScreen> {
  String _searchQuery = '';
  String _zoneFilter = 'ALL';
  String _inspectionFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final union = context.watch<UnionController>();
    final zones = union.stations;
    final filteredRiders = union.filteredRiders;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Rider Directory'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_outlined),
            tooltip: 'Filters',
            onPressed: () => _showFilterDialog(context, union, zones),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
                union.setRiderSearchQuery(val.trim());
              },
              decoration: InputDecoration(
                hintText: 'Search by name, rider code, licence, or plate...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        tooltip: 'Clear search',
                        onPressed: () {
                          setState(() => _searchQuery = '');
                          union.setRiderSearchQuery('');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('Zone: ALL', 'ALL', _zoneFilter, () {
                    setState(() => _zoneFilter = 'ALL');
                    union.setZoneFilter('ALL');
                  }),
                  const SizedBox(width: 8),
                  _chip('Zone: LMJ-01', 'LMJ-01', _zoneFilter, () {
                    setState(() => _zoneFilter = 'LMJ-01');
                    union.setZoneFilter('LMJ-01');
                  }),
                  const SizedBox(width: 8),
                  _chip('Zone: WEL-02', 'WEL-02', _zoneFilter, () {
                    setState(() => _zoneFilter = 'WEL-02');
                    union.setZoneFilter('WEL-02');
                  }),
                  const SizedBox(width: 8),
                  _chip('Zone: KSY-03', 'KSY-03', _zoneFilter, () {
                    setState(() => _zoneFilter = 'KSY-03');
                    union.setZoneFilter('KSY-03');
                  }),
                  const SizedBox(width: 8),
                  _chip('Zone: ABD-04', 'ABD-04', _zoneFilter, () {
                    setState(() => _zoneFilter = 'ABD-04');
                    union.setZoneFilter('ABD-04');
                  }),
                  const SizedBox(width: 8),
                  _chip('Zone: CCX-05', 'CCX-05', _zoneFilter, () {
                    setState(() => _zoneFilter = 'CCX-05');
                    union.setZoneFilter('CCX-05');
                  }),
                  const SizedBox(width: 8),
                  _chip('Zone: CTR-06', 'CTR-06', _zoneFilter, () {
                    setState(() => _zoneFilter = 'CTR-06');
                    union.setZoneFilter('CTR-06');
                  }),
                  const SizedBox(width: 8),
                  _chip('Inspection: ALL', 'ALL', _inspectionFilter, () {
                    setState(() => _inspectionFilter = 'ALL');
                    union.setInspectionFilter('ALL');
                  }),
                  const SizedBox(width: 8),
                  _chip('PASSED', 'PASSED', _inspectionFilter, () {
                    setState(() => _inspectionFilter = 'PASSED');
                    union.setInspectionFilter('PASSED');
                  }),
                  const SizedBox(width: 8),
                  _chip('PENDING', 'PENDING', _inspectionFilter, () {
                    setState(() => _inspectionFilter = 'PENDING');
                    union.setInspectionFilter('PENDING');
                  }),
                  const SizedBox(width: 8),
                  _chip('FLAGGED', 'FLAGGED', _inspectionFilter, () {
                    setState(() => _inspectionFilter = 'FLAGGED');
                    union.setInspectionFilter('FLAGGED');
                  }),
                ],
              ),
            ),
          ),
          Expanded(
            child: filteredRiders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 64,
                          color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No riders match "$_searchQuery"'
                              : 'No registered riders found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredRiders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final rider = filteredRiders[index];
                      return _buildRiderCard(context, rider, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, String current, VoidCallback onTap) {
    final isSelected = current == value;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
      checkmarkColor: AppTheme.primaryGreen,
      labelStyle: TextStyle(color: isSelected ? AppTheme.primaryGreen : null),
      side: BorderSide(color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildRiderCard(BuildContext context, Rider rider, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
          child: Text(
            rider.riderCode,
            style: const TextStyle(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          rider.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Licence: ${rider.licenseNumber} • ${rider.zoneName ?? "Unknown Zone"}',
              style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            if (rider.linkedPlateNumber != null)
              Text(
                'Plate: ${rider.linkedPlateNumber} • ${rider.linkedBikeModel ?? ""}',
                style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                StatusPill(status: rider.status),
                const SizedBox(width: 8),
                if (rider.inspectionStatus != null)
                  StatusPill(status: rider.inspectionStatus!),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppTheme.formatLeones(rider.totalDuesPaid ?? 0.0),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.primaryGreen,
              ),
            ),
            const Text(
              'Dues Paid',
              style: TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RiderProfileScreen(rider: rider)),
          );
        },
      ),
    );
  }

  void _showFilterDialog(BuildContext context, UnionController union, List<StationZone> zones) {
    String tempZoneFilter = _zoneFilter;
    String tempInspectionFilter = _inspectionFilter;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Riders'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Station Zone', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _dialogChip('ALL', tempZoneFilter, setDialogState, (v) => tempZoneFilter = v),
                        ...zones.map((z) => _dialogChip(z.id!, tempZoneFilter, setDialogState, (v) => tempZoneFilter = v)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Inspection Status', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _dialogChip('ALL', tempInspectionFilter, setDialogState, (v) => tempInspectionFilter = v),
                        _dialogChip('PASSED', tempInspectionFilter, setDialogState, (v) => tempInspectionFilter = v),
                        _dialogChip('PENDING', tempInspectionFilter, setDialogState, (v) => tempInspectionFilter = v),
                        _dialogChip('FLAGGED', tempInspectionFilter, setDialogState, (v) => tempInspectionFilter = v),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _zoneFilter = 'ALL';
                      _inspectionFilter = 'ALL';
                      union.setZoneFilter('ALL');
                      union.setInspectionFilter('ALL');
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Clear All'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _zoneFilter = tempZoneFilter;
                      _inspectionFilter = tempInspectionFilter;
                      union.setZoneFilter(tempZoneFilter);
                      union.setInspectionFilter(tempInspectionFilter);
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dialogChip(String value, String current, StateSetter setDialogState, Function(String) onChanged) {
    final isSelected = current == value;
    return FilterChip(
      label: Text(value, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (_) {
        setDialogState(() => onChanged(value));
      },
      selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
      checkmarkColor: AppTheme.primaryGreen,
    );
  }
}