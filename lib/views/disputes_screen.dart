import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../controllers/union_controller.dart';
import '../models/compliance_dispute.dart';
import '../widgets/status_pill.dart';
import '../widgets/date_range_filter.dart';

/// Screen 10: Compliance & Levy Disputes Screen
/// Allows commercial riders to appeal wrongful fines, duplicate daily levies,
/// or safety flags. Provides union executives and station marshals with ticket resolution tools.
class DisputesScreen extends StatefulWidget {
  final String? defaultRiderId;
  final String? defaultBikeId;

  const DisputesScreen({
    super.key,
    this.defaultRiderId,
    this.defaultBikeId,
  });

  @override
  State<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends State<DisputesScreen> {
  String _selectedStatusFilter = 'ALL';
  String _searchQuery = '';
  DateTime? _dateRangeStart;
  DateTime? _dateRangeEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final union = context.watch<UnionController>();
    final auth = context.watch<AuthController>();

    final allDisputes = union.disputes;
    final filteredDisputes = allDisputes.where((d) {
      final matchesStatus = _selectedStatusFilter == 'ALL' || d.status.toUpperCase() == _selectedStatusFilter;
      final matchesQuery = _searchQuery.isEmpty ||
          d.ticketCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (d.plateNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (d.riderName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesStartDate = _dateRangeStart == null || d.createdAt.isAfter(_dateRangeStart!.subtract(const Duration(days: 1)));
      final matchesEndDate = _dateRangeEnd == null || d.createdAt.isBefore(_dateRangeEnd!.add(const Duration(days: 1)));
      return matchesStatus && matchesQuery && matchesStartDate && matchesEndDate;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Disputes & Appeals'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'File Appeal',
            onPressed: () => _showNewDisputeSheet(context, union, auth),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search by ticket ID, plate, or subject...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('ALL', 'All Tickets (${allDisputes.length})'),
                      const SizedBox(width: 8),
                      _filterChip('OPEN', 'Open (${allDisputes.where((d) => d.isOpen).length})'),
                      const SizedBox(width: 8),
                      _filterChip('IN_REVIEW', 'In Review'),
                      const SizedBox(width: 8),
                      _filterChip('RESOLVED', 'Resolved (${allDisputes.where((d) => d.isResolved).length})'),
                      const SizedBox(width: 8),
                      _filterChip('REJECTED', 'Rejected'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Date Range Filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DateRangeFilter(
                    initialStart: _dateRangeStart,
                    initialEnd: _dateRangeEnd,
                    onStartChanged: (date) => setState(() => _dateRangeStart = date),
                    onEndChanged: (date) => setState(() => _dateRangeEnd = date),
                    onClear: () => setState(() {
                      _dateRangeStart = null;
                      _dateRangeEnd = null;
                    }),
                  ),
                ),
              ],
            ),
          ),

          // Disputes List
          Expanded(
            child: filteredDisputes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 64,
                          color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No disputes found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'All rider transactions and inspections are in full compliance.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showNewDisputeSheet(context, union, auth),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('File New Appeal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filteredDisputes.length,
                    itemBuilder: (context, index) {
                      final dispute = filteredDisputes[index];
                      return _buildDisputeCard(context, dispute, union, auth, isDark);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewDisputeSheet(context, union, auth),
        backgroundColor: AppTheme.goldenAmber,
        foregroundColor: Colors.black87,
        icon: const Icon(Icons.add),
        label: const Text('File Dispute', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _filterChip(String statusKey, String label) {
    final isSelected = _selectedStatusFilter == statusKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedStatusFilter = statusKey);
      },
      selectedColor: AppTheme.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildDisputeCard(
    BuildContext context,
    ComplianceDispute dispute,
    UnionController union,
    AuthController auth,
    bool isDark,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy • HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: dispute.isOpen
              ? AppTheme.goldenAmber.withOpacity(0.4)
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
                        color: AppTheme.primaryGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dispute.ticketCode,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (dispute.plateNumber != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          dispute.plateNumber!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                StatusPill(status: dispute.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              dispute.subject,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dispute.description,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              ),
            ),
            if (dispute.resolutionNotes != null && dispute.resolutionNotes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: AppTheme.primaryGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Union Executive Resolution:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dispute.resolutionNotes!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filed by: ${dispute.riderName ?? "Okada Rider"} • ${dateFormat.format(dispute.createdAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                if ((auth.isAdmin || auth.isExecutive) && dispute.isOpen)
                  TextButton.icon(
                    onPressed: () => _showResolveDisputeDialog(context, dispute, union),
                    icon: const Icon(Icons.gavel_rounded, size: 16),
                    label: const Text('Resolve'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.goldenAmber,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNewDisputeSheet(BuildContext context, UnionController union, AuthController auth) {
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedRiderId = widget.defaultRiderId ?? auth.currentRider?.id ?? union.riders.first.id;
    String? selectedBikeId = widget.defaultBikeId ?? auth.currentBike?.id ?? union.bikes.first.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'File Union Dispute or Appeal',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Rider Selector
                    DropdownButtonFormField<String>(
                      value: selectedRiderId,
                      decoration: const InputDecoration(
                        labelText: 'Select Rider',
                        border: OutlineInputBorder(),
                      ),
                      items: union.riders.map((r) {
                        return DropdownMenuItem(
                          value: r.id,
                          child: Text('${r.fullName} (${r.riderCode})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setSheetState(() {
                          selectedRiderId = val;
                          final matchBike = union.bikes.firstWhere(
                            (b) => b.riderId == val,
                            orElse: () => union.bikes.first,
                          );
                          selectedBikeId = matchBike.id;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Bike Selector
                    DropdownButtonFormField<String>(
                      value: selectedBikeId,
                      decoration: const InputDecoration(
                        labelText: 'Select Motorcycle Plate',
                        border: OutlineInputBorder(),
                      ),
                      items: union.bikes.map((b) {
                        return DropdownMenuItem(
                          value: b.id,
                          child: Text('${b.plateNumber} • ${b.model}'),
                        );
                      }).toList(),
                      onChanged: (val) => setSheetState(() => selectedBikeId = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subjectCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dispute Subject',
                        hintText: 'e.g., Duplicate daily levy collected at Lumley',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Detailed Explanation',
                        hintText: 'Provide full details, station marshal name, and receipts...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (subjectCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill in subject and description.')),
                          );
                          return;
                        }
                        union.submitDispute(
                          riderId: selectedRiderId!,
                          bikeId: selectedBikeId!,
                          subject: subjectCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dispute filed successfully. Assigned ticket tracking number.'),
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Submit Formal Appeal', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showResolveDisputeDialog(BuildContext context, ComplianceDispute dispute, UnionController union) {
    final resolutionCtrl = TextEditingController();
    String selectedStatus = 'RESOLVED';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text('Resolve Dispute ${dispute.ticketCode}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Subject: ${dispute.subject}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Resolution Outcome', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'RESOLVED', child: Text('RESOLVED - Grant Refund / Dismiss Fine')),
                        DropdownMenuItem(value: 'REJECTED', child: Text('REJECTED - Uphold Union Fine')),
                      ],
                      onChanged: (val) => setDialogState(() => selectedStatus = val!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: resolutionCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Executive Resolution Notes',
                        hintText: 'Enter formal ruling and station follow-up instructions...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (resolutionCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter resolution notes.')),
                      );
                      return;
                    }
                    union.resolveDispute(
                      disputeId: dispute.id,
                      status: selectedStatus,
                      resolutionNotes: resolutionCtrl.text.trim(),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Dispute ${dispute.ticketCode} has been marked $selectedStatus.'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm Resolution'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
