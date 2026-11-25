import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/daily_log.dart';
import '../models/rider.dart';
import '../models/bike.dart';
import '../controllers/union_controller.dart';
import '../widgets/date_range_filter.dart';
import 'payment_receipt_screen.dart';
import 'payment_gateway_screen.dart';

/// Screen 8: Rider Personal Payment Ledger Screen
/// Filterable, searchable chronological list of all immutable transactions for the rider's motorcycle.
class RiderLedgerScreen extends StatefulWidget {
  final Rider? rider;
  final Bike? bike;

  const RiderLedgerScreen({super.key, this.rider, this.bike});

  @override
  State<RiderLedgerScreen> createState() => _RiderLedgerScreenState();
}

class _RiderLedgerScreenState extends State<RiderLedgerScreen> {
  String _selectedFeeFilter = 'ALL';
  String _selectedPaymentStatusFilter = 'ALL';
  String _searchQuery = '';
  DateTime? _dateRangeStart;
  DateTime? _dateRangeEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final union = context.watch<UnionController>();

    final targetBike = widget.bike ??
        (widget.rider != null
            ? union.bikes.firstWhere(
                (b) => b.riderId == widget.rider!.id,
                orElse: () => union.bikes.first,
              )
            : (union.bikes.isNotEmpty ? union.bikes.first : null));

    final targetRider = widget.rider ??
        (targetBike != null
            ? union.riders.firstWhere(
                (r) => r.id == targetBike.riderId,
                orElse: () => union.riders.first,
              )
            : null);

    // Get logs for this bike
    final allBikeLogs = targetBike != null
        ? union.dailyLogs.where((l) => l.bikeId == targetBike.id).toList()
        : union.dailyLogs;

    // Filter by fee, payment status, date range, and query
    final filteredLogs = allBikeLogs.where((l) {
      final matchesFee = _selectedFeeFilter == 'ALL' || l.feeTypeCode == _selectedFeeFilter;
      final matchesPaymentStatus = _selectedPaymentStatusFilter == 'ALL' || l.paymentStatus.name.toUpperCase() == _selectedPaymentStatusFilter.toUpperCase();
      final matchesStartDate = _dateRangeStart == null || l.paidAt.isAfter(_dateRangeStart!.subtract(const Duration(days: 1)));
      final matchesEndDate = _dateRangeEnd == null || l.paidAt.isBefore(_dateRangeEnd!.add(const Duration(days: 1)));
      final matchesQuery = _searchQuery.isEmpty ||
          l.logCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (l.feeTypeName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (l.paymentMethod?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesFee && matchesPaymentStatus && matchesStartDate && matchesEndDate && matchesQuery;
    }).toList();

    final totalPaid = allBikeLogs.fold(0.0, (sum, l) => sum + l.amount);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('${targetBike?.plateNumber ?? "Okada"} Payment Ledger'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card_rounded),
            tooltip: 'Make Payment',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentGatewayScreen(
                    preselectedRiderId: targetRider?.id,
                    preselectedBikeId: targetBike?.id,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Total Dues KPI Header
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [Colors.white, const Color(0xFFF1F5F9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cumulative Dues Paid',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppTheme.formatLeones(totalPaid),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${allBikeLogs.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const Text(
                        'Transactions',
                        style: TextStyle(fontSize: 10, color: AppTheme.primaryGreen),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search & Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by Log Code or Fee Type...',
                prefixIcon: Icon(Icons.search_rounded),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
              },
            ),
          ),

          const SizedBox(height: 10),

          // Fee Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildFilterChip('All Fees', 'ALL'),
                const SizedBox(width: 8),
                _buildFilterChip('Daily Levy', 'DAILY_LEVY'),
                const SizedBox(width: 8),
                _buildFilterChip('Safety Fine', 'SAFETY_FINE'),
                const SizedBox(width: 8),
                _buildFilterChip('Annual Permit', 'ANNUAL_PERMIT'),
                const SizedBox(width: 8),
                _buildFilterChip('Custom', 'CUSTOM_PAYMENT'),
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
                _buildFilterChip('All Status', 'ALL'),
                const SizedBox(width: 8),
                _buildFilterChip('Paid', 'PAID'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'PENDING'),
                const SizedBox(width: 8),
                _buildFilterChip('Failed', 'FAILED'),
                const SizedBox(width: 8),
                _buildFilterChip('Refunded', 'REFUNDED'),
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

          const SizedBox(height: 12),

          // Ledger List
          Expanded(
            child: filteredLogs.isEmpty
                ? const Center(
                    child: Text(
                      'No matching transaction records in ledger.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredLogs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final log = filteredLogs[idx];
                      return Card(
                        elevation: 0.5,
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.receipt_rounded, color: AppTheme.primaryGreen, size: 22),
                          ),
                          title: Text(
                            log.feeTypeName ?? 'Union Fee',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${log.logCode} • ${log.paymentMethod ?? "CASH"}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              Text(
                                AppTheme.formatDate(log.paidAt),
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                              const SizedBox(height: 2),
                              _buildStatusChip(log.paymentStatus),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                AppTheme.formatLeones(log.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Receipt →',
                                style: TextStyle(fontSize: 10, color: AppTheme.accentBlue),
                              ),
                            ],
                          ),
                          onTap: () {
                            final receipt = union.receipts.firstWhere(
                              (r) => r.dailyLogId == log.id,
                              orElse: () => union.receipts.first,
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaymentReceiptScreen(
                                  receipt: receipt,
                                  dailyLog: log,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String code) {
    final isFeeFilter = ['ALL', 'DAILY_LEVY', 'SAFETY_FINE', 'ANNUAL_PERMIT', 'CUSTOM_PAYMENT'].contains(code);
    final isStatusFilter = ['ALL', 'PAID', 'PENDING', 'FAILED', 'REFUNDED'].contains(code);
    final isSelected = isFeeFilter
        ? _selectedFeeFilter == code
        : _selectedPaymentStatusFilter == code;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryGreen,
      onSelected: (_) {
        setState(() {
          if (isFeeFilter) {
            _selectedFeeFilter = code;
          } else if (isStatusFilter) {
            _selectedPaymentStatusFilter = code;
          }
        });
      },
    );
  }

  Widget _buildStatusChip(PaymentStatus status) {
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
}
