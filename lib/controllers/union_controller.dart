import 'package:flutter/material.dart';
import '../models/rider.dart';
import '../models/bike.dart';
import '../models/station_zone.dart';
import '../models/fee_type.dart';
import '../models/daily_log.dart';
import '../models/payment_receipt.dart';
import '../models/safety_inspection.dart';
import '../models/compliance_dispute.dart';
import '../models/union_announcement.dart';
import '../models/app_notification.dart';
import '../models/audit_trail_log.dart';
import '../services/rider_service.dart';
import '../services/payment_service.dart';
import '../services/inspection_service.dart';
import '../services/station_service.dart';
import '../services/governance_service.dart';
import '../database/local_database.dart';

class UnionController extends ChangeNotifier {
  final RiderService _riderService = RiderService();
  final PaymentService _paymentService = PaymentService();
  final InspectionService _inspectionService = InspectionService();
  final StationService _stationService = StationService();
  final GovernanceService _governanceService = GovernanceService();
  final LocalDatabase _db = LocalDatabase();

  bool _isLoading = false;
  String? _statusMessage;
  String _riderSearchQuery = '';
  String _selectedZoneFilter = 'ALL';
  String _selectedInspectionFilter = 'ALL';
  DateTime? _logDateRangeStart;
  DateTime? _logDateRangeEnd;
  String _selectedPaymentStatusFilter = 'ALL';

  bool get isLoading => _isLoading;
  String? get statusMessage => _statusMessage;
  String get riderSearchQuery => _riderSearchQuery;
  String get selectedZoneFilter => _selectedZoneFilter;
  String get selectedInspectionFilter => _selectedInspectionFilter;
  DateTime? get logDateRangeStart => _logDateRangeStart;
  DateTime? get logDateRangeEnd => _logDateRangeEnd;
  String get selectedPaymentStatusFilter => _selectedPaymentStatusFilter;

  // Data Getters
  List<Rider> get riders => _riderService.getAllRiders();
  List<Bike> get bikes => _riderService.getAllBikes();
  List<StationZone> get stations => _stationService.getAllStations();
  List<FeeType> get feeTypes => _paymentService.getFeeTypes();
  List<DailyLog> get dailyLogs => _paymentService.getAllDailyLogs();
  List<PaymentReceipt> get receipts => _paymentService.getAllReceipts();
  List<SafetyInspection> get inspections => _inspectionService.getAllInspections();
  List<ComplianceDispute> get disputes => _governanceService.getAllDisputes();
  List<UnionAnnouncement> get announcements => _governanceService.getAllAnnouncements();
  List<AppNotification> get notifications => _governanceService.getAllNotifications();
  List<AuditTrailLog> get auditLogs => _governanceService.getAllAuditLogs();

  // Search & Filter for Riders
  List<Rider> get filteredRiders {
    return riders.where((r) {
      final matchesQuery = _riderSearchQuery.isEmpty ||
          r.fullName.toLowerCase().contains(_riderSearchQuery.toLowerCase()) ||
          r.riderCode.toLowerCase().contains(_riderSearchQuery.toLowerCase()) ||
          r.licenseNumber.toLowerCase().contains(_riderSearchQuery.toLowerCase()) ||
          (r.linkedPlateNumber?.toLowerCase().contains(_riderSearchQuery.toLowerCase()) ?? false);

      final matchesZone = _selectedZoneFilter == 'ALL' ||
          r.zoneId == _selectedZoneFilter ||
          r.zoneName == _selectedZoneFilter;

      final matchesInspection = _selectedInspectionFilter == 'ALL' ||
          (r.inspectionStatus?.toUpperCase() == _selectedInspectionFilter.toUpperCase());

      return matchesQuery && matchesZone && matchesInspection;
    }).toList();
  }

  // Search & Filter for Daily Logs
  List<DailyLog> filterLogs({
    String? zoneId,
    String? feeTypeCode,
    String? query,
    DateTime? startDate,
    DateTime? endDate,
    String? paymentStatus,
  }) {
    final effectiveStart = startDate ?? _logDateRangeStart;
    final effectiveEnd = endDate ?? _logDateRangeEnd;
    final effectivePaymentStatus = paymentStatus ?? _selectedPaymentStatusFilter;

    return dailyLogs.where((l) {
      final matchesZone = zoneId == null || zoneId == 'ALL' || l.zoneId == zoneId || l.zoneName == zoneId;
      final matchesFee = feeTypeCode == null || feeTypeCode == 'ALL' || l.feeTypeCode == feeTypeCode;
      final matchesQuery = query == null ||
          query.isEmpty ||
          (l.plateNumber?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
          (l.riderName?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
          l.logCode.toLowerCase().contains(query.toLowerCase());
      final matchesStartDate = effectiveStart == null || l.paidAt.isAfter(effectiveStart.subtract(const Duration(days: 1)));
      final matchesEndDate = effectiveEnd == null || l.paidAt.isBefore(effectiveEnd.add(const Duration(days: 1)));
      final matchesPaymentStatus = effectivePaymentStatus == 'ALL' || l.paymentStatus.name.toUpperCase() == effectivePaymentStatus.toUpperCase();

      return matchesZone && matchesFee && matchesQuery && matchesStartDate && matchesEndDate && matchesPaymentStatus;
    }).toList();
  }

  // Analytics Metrics
  Map<String, dynamic> fetchAnalytics() {
    final allBikes = bikes;
    final totalRevenue = _db.totalRevenue;
    final inspectedCount = _db.inspectedCount;
    final complianceRate = _db.complianceRate;
    final pendingCount = allBikes.where((b) => b.isPending).length;
    final flaggedCount = allBikes.where((b) => b.isFlagged).length;

    // Station breakdown
    final stationBreakdown = stations.map((s) {
      final bikesInStation = allBikes.where((b) => b.zoneId == s.id).toList();
      final revenue = bikesInStation.fold(0.0, (sum, b) => sum + b.totalDuesPaid);
      final compliant = bikesInStation.where((b) => b.isInspected).length;
      return {
        'zone': s,
        'bikeCount': bikesInStation.length,
        'revenue': revenue,
        'compliantCount': compliant,
        'complianceRate': bikesInStation.isEmpty ? 0.0 : (compliant / bikesInStation.length) * 100,
      };
    }).toList();

    return {
      'totalRiders': riders.length,
      'totalBikes': allBikes.length,
      'inspectedCount': inspectedCount,
      'pendingCount': pendingCount,
      'flaggedCount': flaggedCount,
      'complianceRate': complianceRate,
      'totalRevenue': totalRevenue,
      'stationBreakdown': stationBreakdown,
      'totalTransactions': dailyLogs.length,
    };
  }

  void setRiderSearchQuery(String query) {
    _riderSearchQuery = query;
    notifyListeners();
  }

  void setZoneFilter(String zone) {
    _selectedZoneFilter = zone;
    notifyListeners();
  }

  void setInspectionFilter(String filter) {
    _selectedInspectionFilter = filter;
    notifyListeners();
  }

  void setLogDateRange({DateTime? start, DateTime? end}) {
    _logDateRangeStart = start;
    _logDateRangeEnd = end;
    notifyListeners();
  }

  void clearLogDateRange() {
    _logDateRangeStart = null;
    _logDateRangeEnd = null;
    notifyListeners();
  }

  void setPaymentStatusFilter(String filter) {
    _selectedPaymentStatusFilter = filter;
    notifyListeners();
  }

  /// Process direct payment transaction
  Future<Map<String, dynamic>> processPayment({
    required String bikeId,
    required String riderId,
    required String feeTypeId,
    required double amount,
    String paymentMethod = 'CASH_OFFICIAL',
    String? notes,
    String? recorderProfileId,
  }) async {
    _isLoading = true;
    _statusMessage = null;
    notifyListeners();

    try {
      final result = await _paymentService.processPayment(
        bikeId: bikeId,
        riderId: riderId,
        feeTypeId: feeTypeId,
        amount: amount,
        paymentMethod: paymentMethod,
        notes: notes,
        recorderProfileId: recorderProfileId,
      );

      _isLoading = false;
      _statusMessage = 'Payment of Le ${amount.toStringAsFixed(2)} processed successfully.';
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _statusMessage = 'Payment Error: ${e.toString().replaceAll("Exception: ", "")}';
      notifyListeners();
      rethrow;
    }
  }

  /// Register new rider & motorcycle
  Future<Map<String, dynamic>> registerRiderWithBike({
    required String riderCode,
    required String fullName,
    required String phoneNumber,
    required String licenseNumber,
    required String zoneId,
    required String password,
    required String plateNumber,
    required String model,
    String make = 'Bajaj',
    String color = 'Red',
    int manufactureYear = 2024,
    String? chassisNumber,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    _isLoading = true;
    _statusMessage = null;
    notifyListeners();

    try {
      final result = _riderService.registerRiderWithBike(
        riderCode: riderCode,
        fullName: fullName,
        phoneNumber: phoneNumber,
        licenseNumber: licenseNumber,
        zoneId: zoneId,
        password: password,
        plateNumber: plateNumber,
        model: model,
        make: make,
        color: color,
        manufactureYear: manufactureYear,
        chassisNumber: chassisNumber,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
      );

      _isLoading = false;
      _statusMessage = 'Rider $fullName & bike $plateNumber registered successfully.';
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _statusMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  /// Record safety inspection
  void recordSafetyInspection({
    required String bikeId,
    required bool brakesOk,
    required bool lightsOk,
    required bool tiresOk,
    required bool helmetGearOk,
    required String status,
    String? remarks,
    String? inspectorProfileId,
    String? inspectorName,
  }) {
    _inspectionService.recordInspection(
      bikeId: bikeId,
      brakesOk: brakesOk,
      lightsOk: lightsOk,
      tiresOk: tiresOk,
      helmetGearOk: helmetGearOk,
      status: status,
      remarks: remarks,
      inspectorProfileId: inspectorProfileId,
      inspectorName: inspectorName,
    );
    notifyListeners();
  }

  /// Submit dispute
  ComplianceDispute submitDispute({
    required String riderId,
    required String bikeId,
    String? dailyLogId,
    required String subject,
    required String description,
  }) {
    final d = _governanceService.submitDispute(
      riderId: riderId,
      bikeId: bikeId,
      dailyLogId: dailyLogId,
      subject: subject,
      description: description,
    );
    notifyListeners();
    return d;
  }

  /// Resolve dispute
  void resolveDispute({
    required String disputeId,
    required String status,
    required String resolutionNotes,
  }) {
    _governanceService.updateDisputeStatus(
      disputeId: disputeId,
      status: status,
      resolutionNotes: resolutionNotes,
    );
    notifyListeners();
  }

  /// Mark notification read
  void markNotificationRead(String id) {
    _governanceService.markNotificationRead(id);
    notifyListeners();
  }

  void markAllNotificationsRead() {
    _governanceService.markAllNotificationsRead();
    notifyListeners();
  }
}
