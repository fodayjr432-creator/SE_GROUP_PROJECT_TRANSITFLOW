import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../controllers/union_controller.dart';
import '../models/bike.dart';
import '../models/safety_inspection.dart';
import '../widgets/status_pill.dart';
import '../widgets/date_range_filter.dart';
import 'bike_detail_screen.dart';

/// Screen 11: Safety Inspection & Vehicle Verification Screen
/// Enables station safety marshals to conduct the 4-point roadworthiness inspection,
/// toggle brake/light/tire/helmet criteria, issue 90-day certificates, or flag non-compliant bikes.
class SafetyInspectionScreen extends StatefulWidget {
  final String? preselectedBikeId;

  const SafetyInspectionScreen({super.key, this.preselectedBikeId});

  @override
  State<SafetyInspectionScreen> createState() => _SafetyInspectionScreenState();
}

class _SafetyInspectionScreenState extends State<SafetyInspectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedBikeId;
  bool _brakesOk = true;
  bool _lightsOk = true;
  bool _tiresOk = true;
  bool _helmetGearOk = true;
  String _decisionStatus = 'PASSED';
  final TextEditingController _remarksController = TextEditingController();
  String _historyFilter = 'ALL';
  DateTime? _inspectionDateRangeStart;
  DateTime? _inspectionDateRangeEnd;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedBikeId = widget.preselectedBikeId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _updateDecisionStatus() {
    // If all pass, set to PASSED; if any fails, set to FLAGGED
    if (_brakesOk && _lightsOk && _tiresOk && _helmetGearOk) {
      setState(() => _decisionStatus = 'PASSED');
    } else {
      setState(() => _decisionStatus = 'FLAGGED');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final union = context.watch<UnionController>();
    final auth = context.watch<AuthController>();

    final allBikes = union.bikes;
    if (_selectedBikeId == null && allBikes.isNotEmpty) {
      _selectedBikeId = allBikes.first.id;
    }

    final currentBike = allBikes.firstWhere(
      (b) => b.id == _selectedBikeId,
      orElse: () => allBikes.first,
    );

    final allInspections = union.inspections;
    final filteredInspections = allInspections.where((i) {
      final matchesStatus = _historyFilter == 'ALL' || i.status.toUpperCase() == _historyFilter;
      final matchesStartDate = _inspectionDateRangeStart == null || i.inspectedAt.isAfter(_inspectionDateRangeStart!.subtract(const Duration(days: 1)));
      final matchesEndDate = _inspectionDateRangeEnd == null || i.inspectedAt.isBefore(_inspectionDateRangeEnd!.add(const Duration(days: 1)));
      return matchesStatus && matchesStartDate && matchesEndDate;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Safety & Roadworthiness'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          tabs: const [
            Tab(icon: Icon(Icons.fact_check_outlined), text: 'Conduct Check'),
            Tab(icon: Icon(Icons.history_rounded), text: 'Safety Records'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Conduct Inspection
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Vehicle Selector Dropdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Commercial Motorcycle',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedBikeId,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: allBikes.map((b) {
                          return DropdownMenuItem(
                            value: b.id,
                            child: Text('${b.plateNumber} • ${b.model} (${b.riderName ?? "Unassigned"})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedBikeId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Current Status: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              StatusPill(status: currentBike.inspectionStatus),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => BikeDetailScreen(bike: currentBike)),
                              );
                            },
                            child: const Text('View Specs →', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 4-Point Mandatory Inspection Checklist
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mandatory 4-Point Checklist',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentBlue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'SDG 11.2 Safety Target',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Check 1: Brakes
                      _checklistSwitch(
                        icon: Icons.speed_rounded,
                        title: '1. Dual Braking System',
                        subtitle: 'Front and rear brakes hold firm and respond immediately',
                        value: _brakesOk,
                        onChanged: (val) {
                          setState(() {
                            _brakesOk = val;
                            _updateDecisionStatus();
                          });
                        },
                      ),
                      const Divider(),

                      // Check 2: Lights
                      _checklistSwitch(
                        icon: Icons.lightbulb_outline_rounded,
                        title: '2. Headlights & Turn Signals',
                        subtitle: 'Clear night beam, tail indicator, and functioning indicators',
                        value: _lightsOk,
                        onChanged: (val) {
                          setState(() {
                            _lightsOk = val;
                            _updateDecisionStatus();
                          });
                        },
                      ),
                      const Divider(),

                      // Check 3: Tires
                      _checklistSwitch(
                        icon: Icons.tire_repair_rounded,
                        title: '3. Tyre Tread & Pressure',
                        subtitle: 'Tread depth >= 2mm; no exposed wire cords or severe cracks',
                        value: _tiresOk,
                        onChanged: (val) {
                          setState(() {
                            _tiresOk = val;
                            _updateDecisionStatus();
                          });
                        },
                      ),
                      const Divider(),

                      // Check 4: Helmets
                      _checklistSwitch(
                        icon: Icons.sports_motorsports_rounded,
                        title: '4. Dual Certified Helmets',
                        subtitle: 'Certified helmets available for both rider and passenger',
                        value: _helmetGearOk,
                        onChanged: (val) {
                          setState(() {
                            _helmetGearOk = val;
                            _updateDecisionStatus();
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Decision & Remarks Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Inspection Verdict & Action',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _verdictChip('PASSED', AppTheme.primaryGreen, Icons.check_circle),
                          const SizedBox(width: 8),
                          _verdictChip('FLAGGED', AppTheme.statusFlagged, Icons.warning_rounded),
                          const SizedBox(width: 8),
                          _verdictChip('PENDING', AppTheme.statusPending, Icons.hourglass_top),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _remarksController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Inspector Remarks & Defect Notes',
                          hintText: 'e.g., Rear tyre bald, replace before entering Wellington route.',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Submit Button
                ElevatedButton.icon(
                  onPressed: () {
                    final inspectorName = auth.currentProfile?.fullName ?? 'Safety Inspector Alpha';
                    final inspectorId = auth.currentProfile?.id;

                    union.recordSafetyInspection(
                      bikeId: currentBike.id,
                      brakesOk: _brakesOk,
                      lightsOk: _lightsOk,
                      tiresOk: _tiresOk,
                      helmetGearOk: _helmetGearOk,
                      status: _decisionStatus,
                      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
                      inspectorProfileId: inspectorId,
                      inspectorName: inspectorName,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Inspection recorded for ${currentBike.plateNumber}: $_decisionStatus.',
                        ),
                        backgroundColor: _decisionStatus == 'PASSED'
                            ? AppTheme.primaryGreen
                            : AppTheme.statusFlagged,
                      ),
                    );

                    _remarksController.clear();
                    _tabController.animateTo(1);
                  },
                  icon: const Icon(Icons.verified, size: 20),
                  label: Text(
                    'Sign & Record Inspection for ${currentBike.plateNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _decisionStatus == 'PASSED'
                        ? AppTheme.primaryGreen
                        : (_decisionStatus == 'FLAGGED' ? AppTheme.statusFlagged : AppTheme.goldenAmber),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // TAB 2: Historical Safety Records
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _historyFilterChip('ALL', 'All Inspections (${allInspections.length})'),
                      const SizedBox(width: 8),
                      _historyFilterChip('PASSED', 'Passed (${allInspections.where((i) => i.isPassed).length})'),
                      const SizedBox(width: 8),
                      _historyFilterChip('FLAGGED', 'Flagged (${allInspections.where((i) => i.isFlagged).length})'),
                      const SizedBox(width: 8),
                      _historyFilterChip('PENDING', 'Pending (${allInspections.where((i) => i.isPending).length})'),
                    ],
                  ),
                ),
              ),
              // Date Range Filter
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: DateRangeFilter(
                  initialStart: _inspectionDateRangeStart,
                  initialEnd: _inspectionDateRangeEnd,
                  onStartChanged: (date) => setState(() => _inspectionDateRangeStart = date),
                  onEndChanged: (date) => setState(() => _inspectionDateRangeEnd = date),
                  onClear: () => setState(() {
                    _inspectionDateRangeStart = null;
                    _inspectionDateRangeEnd = null;
                  }),
                ),
              ),
              Expanded(
                child: filteredInspections.isEmpty
                    ? Center(
                        child: Text(
                          'No inspection records found for selected filter.',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredInspections.length,
                        itemBuilder: (context, index) {
                          final insp = filteredInspections[index];
                          return _inspectionRecordCard(insp, isDark);
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _checklistSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: value ? AppTheme.primaryGreen : AppTheme.statusFlagged, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppTheme.primaryGreen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _verdictChip(String status, Color color, IconData icon) {
    final isSelected = _decisionStatus == status;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _decisionStatus = status),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade400,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey.shade600, size: 20),
              const SizedBox(height: 4),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyFilterChip(String filterKey, String label) {
    final isSelected = _historyFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _historyFilter = filterKey);
      },
      selectedColor: AppTheme.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _inspectionRecordCard(SafetyInspection insp, bool isDark) {
    final dateFormat = DateFormat('dd MMM yyyy • HH:mm');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: insp.isPassed
              ? AppTheme.primaryGreen.withOpacity(0.3)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        insp.plateNumber ?? 'BIKE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      insp.inspectionCode,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                StatusPill(status: insp.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _miniCheck('Brakes', insp.brakesOk),
                const SizedBox(width: 12),
                _miniCheck('Lights', insp.lightsOk),
                const SizedBox(width: 12),
                _miniCheck('Tires', insp.tiresOk),
                const SizedBox(width: 12),
                _miniCheck('Helmet', insp.helmetGearOk),
              ],
            ),
            if (insp.remarks != null && insp.remarks!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Remarks: ${insp.remarks}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 10),
            Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Inspector: ${insp.inspectorName ?? "Station Officer"}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  dateFormat.format(insp.inspectedAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniCheck(String label, bool isOk) {
    return Row(
      children: [
        Icon(isOk ? Icons.check_circle : Icons.cancel, size: 14, color: isOk ? AppTheme.primaryGreen : AppTheme.statusFlagged),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
