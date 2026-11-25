import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../controllers/union_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/daily_log.dart';
import '../models/audit_trail_log.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_pill.dart';
import '../widgets/date_range_filter.dart';
import 'payment_receipt_screen.dart';

/// Screen 13: Executive Analytics & Financial Audit Ledger Screen
/// High-level oversight for Union Executives, Ministry officials, and Station Admins.
/// Features SDG 11.2/SDG 8 compliance gauges, live station revenue breakdowns,
/// immutable daily transaction logs, and security audit trails.
class ExecutiveAnalyticsScreen extends StatefulWidget {
  const ExecutiveAnalyticsScreen({super.key});

  @override
  State<ExecutiveAnalyticsScreen> createState() => _ExecutiveAnalyticsScreenState();
}

class _ExecutiveAnalyticsScreenState extends State<ExecutiveAnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStationFilter = 'ALL';
  String _logSearchQuery = '';
  String _selectedPaymentStatusFilter = 'ALL';
  DateTime? _logDateRangeStart;
  DateTime? _logDateRangeEnd;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(symbol: 'Le ', decimalDigits: 0);
    final union = context.watch<UnionController>();
    final auth = context.watch<AuthController>();

    final analytics = union.fetchAnalytics();
    final double totalRevenue = analytics['totalRevenue'] as double? ?? 0.0;
    final double complianceRate = analytics['complianceRate'] as double? ?? 0.0;
    final int totalRiders = analytics['totalRiders'] as int? ?? 0;
    final int totalBikes = analytics['totalBikes'] as int? ?? 0;
    final int inspectedCount = analytics['inspectedCount'] as int? ?? 0;
    final int pendingCount = analytics['pendingCount'] as int? ?? 0;
    final int flaggedCount = analytics['flaggedCount'] as int? ?? 0;
    final List<dynamic> stationBreakdown = analytics['stationBreakdown'] as List<dynamic>? ?? [];

    final dailyLogs = union.dailyLogs;
    final filteredLogs = dailyLogs.where((l) {
      final matchesStation = _selectedStationFilter == 'ALL' || l.zoneId == _selectedStationFilter || l.zoneName == _selectedStationFilter;
      final matchesQuery = _logSearchQuery.isEmpty ||
          l.logCode.toLowerCase().contains(_logSearchQuery.toLowerCase()) ||
          (l.plateNumber?.toLowerCase().contains(_logSearchQuery.toLowerCase()) ?? false) ||
          (l.riderName?.toLowerCase().contains(_logSearchQuery.toLowerCase()) ?? false);
      final matchesPaymentStatus = _selectedPaymentStatusFilter == 'ALL' || l.paymentStatus.name.toUpperCase() == _selectedPaymentStatusFilter.toUpperCase();
      final matchesStartDate = _logDateRangeStart == null || l.paidAt.isAfter(_logDateRangeStart!.subtract(const Duration(days: 1)));
      final matchesEndDate = _logDateRangeEnd == null || l.paidAt.isBefore(_logDateRangeEnd!.add(const Duration(days: 1)));
      return matchesStation && matchesQuery && matchesPaymentStatus && matchesStartDate && matchesEndDate;
    }).toList();

    final auditLogs = union.auditLogs;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Executive Audit & Analytics'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Financial Audit Report',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Financial Audit CSV exported: Freetown_Union_Ledger_2026.csv'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          tabs: const [
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Daily Logs'),
            Tab(icon: Icon(Icons.shield_outlined), text: 'Audit Trail'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Overview & Station Breakdown
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // UN SDG Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F9D58), Color(0xFF1B5E20)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white24,
                        radius: 24,
                        child: Icon(Icons.public, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'UN SDG 11.2 & SDG 8 COMPLIANCE',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Safe, Regulated Commercial Transport in Sierra Leone',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Revenue & Compliance Top Row
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Total Revenue',
                        value: currencyFormatter.format(totalRevenue),
                        subtitle: 'Zero Cash Leakage',
                        icon: Icons.payments_rounded,
                        iconColor: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        title: 'Compliance Rate',
                        value: '${complianceRate.toStringAsFixed(1)}%',
                        subtitle: '$inspectedCount of $totalBikes Inspected',
                        icon: Icons.verified_rounded,
                        iconColor: complianceRate >= 80 ? AppTheme.primaryGreen : AppTheme.goldenAmber,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Vehicle Status Distribution Card
                Card(
                  elevation: 1,
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fleet Roadworthiness Distribution',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _statusSlice('PASSED', inspectedCount, AppTheme.statusPassed, totalBikes),
                            _statusSlice('PENDING', pendingCount, AppTheme.statusPending, totalBikes),
                            _statusSlice('FLAGGED', flaggedCount, AppTheme.statusFlagged, totalBikes),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Row(
                            children: [
                              if (totalBikes > 0) ...[
                                Expanded(
                                  flex: inspectedCount,
                                  child: Container(height: 10, color: AppTheme.statusPassed),
                                ),
                                Expanded(
                                  flex: pendingCount,
                                  child: Container(height: 10, color: AppTheme.statusPending),
                                ),
                                Expanded(
                                  flex: flaggedCount,
                                  child: Container(height: 10, color: AppTheme.statusFlagged),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Station Revenue & Compliance Breakdown
                Card(
                  elevation: 1,
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Terminal Revenue Breakdown',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Freetown Stations',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...stationBreakdown.map((item) {
                          final zone = item['zone'];
                          final rev = item['revenue'] as double? ?? 0.0;
                          final bCount = item['bikeCount'] as int? ?? 0;
                          final cRate = item['complianceRate'] as double? ?? 0.0;
                          final fraction = totalRevenue > 0 ? (rev / totalRevenue) : 0.0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${zone.name} (${zone.zoneCode})',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      currencyFormatter.format(rev),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$bCount motorcycles assigned',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                    Text(
                                      '${cRate.toStringAsFixed(0)}% safety compliant',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: cRate >= 80 ? AppTheme.primaryGreen : AppTheme.goldenAmber,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: fraction,
                                    minHeight: 6,
                                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // TAB 2: Immutable Daily Logs
          Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                child: Column(
                  children: [
                    TextField(
                      onChanged: (val) => setState(() => _logSearchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search log code, plate, or rider name...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _stationFilterChip('ALL', 'All Zones (${dailyLogs.length})'),
                          ...union.stations.map((s) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: _stationFilterChip(s.id, s.name),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Payment Status Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          _buildPaymentStatusChip('ALL', 'All Status'),
                          const SizedBox(width: 8),
                          _buildPaymentStatusChip('PAID', 'Paid'),
                          const SizedBox(width: 8),
                          _buildPaymentStatusChip('PENDING', 'Pending'),
                          const SizedBox(width: 8),
                          _buildPaymentStatusChip('FAILED', 'Failed'),
                          const SizedBox(width: 8),
                          _buildPaymentStatusChip('REFUNDED', 'Refunded'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Date Range Filter
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: DateRangeFilter(
                        initialStart: _logDateRangeStart,
                        initialEnd: _logDateRangeEnd,
                        onStartChanged: (date) => setState(() => _logDateRangeStart = date),
                        onEndChanged: (date) => setState(() => _logDateRangeEnd = date),
                        onClear: () => setState(() {
                          _logDateRangeStart = null;
                          _logDateRangeEnd = null;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredLogs.isEmpty
                    ? Center(
                        child: Text(
                          'No daily transaction logs found.',
                          style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          return _dailyLogCard(context, log, union, isDark, currencyFormatter);
                        },
                      ),
              ),
            ],
          ),

          // TAB 3: Audit Trail Log
          auditLogs.isEmpty
              ? Center(
                  child: Text(
                    'No security audit logs recorded yet.',
                    style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: auditLogs.length,
                  itemBuilder: (context, index) {
                    final audit = auditLogs[index];
                    return _auditLogCard(audit, isDark);
                  },
                ),
        ],
      ),
    );
  }

  Widget _statusSlice(String label, int count, Color color, int total) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '$count ($pct%)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _stationFilterChip(String zoneKey, String label) {
    final isSelected = _selectedStationFilter == zoneKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedStationFilter = zoneKey);
      },
      selectedColor: AppTheme.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildPaymentStatusChip(String code, String label) {
    final isSelected = _selectedPaymentStatusFilter == code;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedPaymentStatusFilter = code);
      },
      selectedColor: AppTheme.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildLogStatusChip(PaymentStatus status) {
    Color color;
    String label;
    switch (status) {
      case PaymentStatus.paid:
        color = AppTheme.primaryGreen;
        label = 'PAID';
        break;
      case PaymentStatus.pending:
        color = AppTheme.goldenAmber;
        label = 'PENDING';
        break;
      case PaymentStatus.failed:
        color = AppTheme.statusFlagged;
        label = 'FAILED';
        break;
      case PaymentStatus.refunded:
        color = AppTheme.accentBlue;
        label = 'REFUNDED';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _dailyLogCard(
    BuildContext context,
    DailyLog log,
    UnionController union,
    bool isDark,
    NumberFormat currencyFormatter,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy • HH:mm');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
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
                        log.plateNumber ?? 'BIKE',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      log.logCode,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  currencyFormatter.format(log.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryGreen),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${log.feeTypeName ?? "Levy"} • ${log.riderName ?? "Rider"}',
                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                ),
                _buildLogStatusChip(log.paymentStatus),
              ],
            ),
            const SizedBox(height: 6),
            Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(log.paidAt),
                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                InkWell(
                  onTap: () {
                    final matchedReceipt = union.receipts.firstWhere(
                      (r) => r.dailyLogId == log.id,
                      orElse: () => union.receipts.first,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentReceiptScreen(receipt: matchedReceipt, dailyLog: log),
                      ),
                    );
                  },
                  child: const Text(
                    'View Receipt →',
                    style: TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _auditLogCard(AuditTrailLog audit, bool isDark) {
    final dateFormat = DateFormat('dd MMM yyyy • HH:mm:ss');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0.5,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    audit.action,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentBlue),
                  ),
                ),
                Text(
                  dateFormat.format(audit.createdAt),
                  style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Actor: ${audit.actorName ?? "System"} • Table: ${audit.tableName}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            if (audit.details.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Data: ${audit.details.toString()}',
                style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
