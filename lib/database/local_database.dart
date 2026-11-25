import 'dart:math';
import 'package:intl/intl.dart';
import '../models/profile.dart';
import '../models/station_zone.dart';
import '../models/rider.dart';
import '../models/bike.dart';
import '../models/fee_type.dart';
import '../models/daily_log.dart';
import '../models/payment_receipt.dart';
import '../models/safety_inspection.dart';
import '../models/station_permit.dart';
import '../models/compliance_dispute.dart';
import '../models/union_announcement.dart';
import '../models/app_notification.dart';
import '../models/audit_trail_log.dart';
import 'seed_data.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;
  LocalDatabase._internal() {
    initDatabase();
  }

  // Database tables
  final List<StationZone> stationZones = [];
  final List<FeeType> feeTypes = [];
  final List<Profile> profiles = [];
  final List<Rider> riders = [];
  final List<Bike> bikes = [];
  final List<DailyLog> dailyLogs = [];
  final List<PaymentReceipt> paymentReceipts = [];
  final List<SafetyInspection> safetyInspections = [];
  final List<StationPermit> stationPermits = [];
  final List<ComplianceDispute> complianceDisputes = [];
  final List<UnionAnnouncement> unionAnnouncements = [];
  final List<AppNotification> notifications = [];
  final List<AuditTrailLog> auditTrailLogs = [];

  void initDatabase() {
    stationZones.clear();
    stationZones.addAll(SeedData.getStationZones());

    feeTypes.clear();
    feeTypes.addAll(SeedData.getFeeTypes());

    profiles.clear();
    profiles.addAll(SeedData.getProfiles());

    riders.clear();
    riders.addAll(SeedData.getRiders());

    bikes.clear();
    bikes.addAll(SeedData.getBikes());

    dailyLogs.clear();
    dailyLogs.addAll(SeedData.getDailyLogs());

    paymentReceipts.clear();
    paymentReceipts.addAll(SeedData.getPaymentReceipts());

    safetyInspections.clear();
    safetyInspections.addAll(SeedData.getSafetyInspections());

    stationPermits.clear();
    stationPermits.addAll(SeedData.getStationPermits());

    complianceDisputes.clear();
    complianceDisputes.addAll(SeedData.getComplianceDisputes());

    unionAnnouncements.clear();
    unionAnnouncements.addAll(SeedData.getUnionAnnouncements());

    notifications.clear();
    notifications.addAll(SeedData.getNotifications());

    auditTrailLogs.clear();
    auditTrailLogs.addAll(SeedData.getAuditTrailLogs());

    _relinkAuxiliaryFields();
  }

  void _relinkAuxiliaryFields() {
    for (var r in riders) {
      final zone = stationZones.cast<StationZone?>().firstWhere(
            (z) => z?.id == r.zoneId,
            orElse: () => null,
          );
      r.zoneName = zone?.name ?? r.zoneName;

      final b = bikes.cast<Bike?>().firstWhere(
            (bk) => bk?.riderId == r.id,
            orElse: () => null,
          );
      if (b != null) {
        r.linkedPlateNumber = b.plateNumber;
        r.linkedBikeModel = b.model;
        r.isInspected = b.isInspected;
        r.totalDuesPaid = b.totalDuesPaid;
        r.inspectionStatus = b.inspectionStatus;
      }
    }

    for (var b in bikes) {
      final r = riders.cast<Rider?>().firstWhere(
            (rd) => rd?.id == b.riderId,
            orElse: () => null,
          );
      if (r != null) {
        b.riderName = r.fullName;
        b.riderPhone = r.phoneNumber;
        b.riderCode = r.riderCode;
      }
      final zone = stationZones.cast<StationZone?>().firstWhere(
            (z) => z?.id == b.zoneId,
            orElse: () => null,
          );
      b.zoneName = zone?.name ?? b.zoneName;
    }
  }

  /// Transactional Payment Execution (Mirrors Supabase RPC `process_union_payment`)
  Map<String, dynamic> processUnionPayment({
    required String bikeId,
    required String riderId,
    required String feeTypeId,
    required double amount,
    String paymentMethod = 'CASH_OFFICIAL',
    String? notes,
    String? recorderProfileId,
  }) {
    if (amount <= 0) {
      throw Exception(
          'Invalid payment amount. Amount must be strictly greater than zero.');
    }

    final bikeIndex = bikes.indexWhere((b) => b.id == bikeId);
    if (bikeIndex == -1) {
      throw Exception('Motorcycle with ID $bikeId not found.');
    }
    final bike = bikes[bikeIndex];

    final riderIndex = riders.indexWhere((r) => r.id == riderId);
    if (riderIndex == -1) {
      throw Exception('Rider with ID $riderId not found.');
    }
    final rider = riders[riderIndex];

    final feeTypeIndex = feeTypes.indexWhere((f) => f.id == feeTypeId);
    final feeType = feeTypeIndex != -1 ? feeTypes[feeTypeIndex] : null;

    final now = DateTime.now();
    final randomSuffix =
        (Random().nextInt(9000) + 1000).toString(); // 4-digit random
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final logCode = 'LOG-$dateStr-$randomSuffix';
    final receiptNumber = 'RCP-$dateStr-$randomSuffix';
    final logId = 'local-log-${now.millisecondsSinceEpoch}';
    final receiptId = 'local-rcp-${now.millisecondsSinceEpoch}';

    // 1. Immutable log creation
    final newLog = DailyLog(
      id: logId,
      logCode: logCode,
      bikeId: bikeId,
      riderId: riderId,
      zoneId: bike.zoneId ?? rider.zoneId,
      feeTypeId: feeTypeId,
      amount: amount,
      paymentMethod: paymentMethod,
      recordedByProfileId: recorderProfileId,
      notes: notes,
      paidAt: now,
      plateNumber: bike.plateNumber,
      riderName: rider.fullName,
      riderCode: rider.riderCode,
      feeTypeName: feeType?.name ?? 'Union Dues',
      feeTypeCode: feeType?.code ?? 'DAILY_LEVY',
      zoneName: rider.zoneName,
    );
    dailyLogs.insert(0, newLog);

    // 2. Receipt creation
    final newReceipt = PaymentReceipt(
      id: receiptId,
      receiptNumber: receiptNumber,
      dailyLogId: logId,
      riderId: riderId,
      bikeId: bikeId,
      amount: amount,
      currency: 'SLE',
      issuedAt: now,
      plateNumber: bike.plateNumber,
      riderName: rider.fullName,
      riderCode: rider.riderCode,
      feeTypeName: feeType?.name ?? 'Union Dues',
      paymentMethod: paymentMethod,
    );
    paymentReceipts.insert(0, newReceipt);

    // 3. Atomically update total dues paid
    bike.totalDuesPaid += amount;
    bike.updatedAt = now;
    rider.totalDuesPaid = bike.totalDuesPaid;

    // 4. Audit trail
    auditTrailLogs.insert(
      0,
      AuditTrailLog(
        id: 'audit-${now.millisecondsSinceEpoch}',
        actorProfileId: recorderProfileId,
        action: 'PROCESS_PAYMENT',
        tableName: 'daily_logs',
        recordId: logId,
        details: {
          'amount': amount,
          'log_code': logCode,
          'receipt_number': receiptNumber,
          'payment_method': paymentMethod,
          'plate': bike.plateNumber,
          'rider_code': rider.riderCode,
        },
        createdAt: now,
        actorName: 'Union Gateway System',
      ),
    );

    // 5. Rider notification
    if (rider.profileId != null) {
      final currencyFormatted = NumberFormat.currency(symbol: 'Le ', decimalDigits: 2).format(amount);
      notifications.insert(
        0,
        AppNotification(
          id: 'notif-${now.millisecondsSinceEpoch}',
          recipientProfileId: rider.profileId!,
          title: 'Payment Confirmed',
          body:
              'Your payment of $currencyFormatted has been recorded under receipt $receiptNumber.',
          category: 'PAYMENT',
          isRead: false,
          createdAt: now,
        ),
      );
    }

    return {
      'success': true,
      'log_id': logId,
      'log_code': logCode,
      'receipt_id': receiptId,
      'receipt_number': receiptNumber,
      'amount': amount,
      'total_dues_paid': bike.totalDuesPaid,
      'paid_at': now.toIso8601String(),
      'receipt': newReceipt,
      'daily_log': newLog,
    };
  }

  /// Register Rider & Motorcycle
  Map<String, dynamic> registerRiderWithBike({
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
  }) {
    // 1. Validations
    if (riderCode.trim().isEmpty ||
        fullName.trim().isEmpty ||
        phoneNumber.trim().isEmpty ||
        licenseNumber.trim().isEmpty ||
        plateNumber.trim().isEmpty) {
      throw Exception('All mandatory rider and motorcycle fields must be completed.');
    }

    final upperRiderCode = riderCode.trim().toUpperCase();
    final upperPlate = plateNumber.trim().toUpperCase();
    final upperLicense = licenseNumber.trim().toUpperCase();

    if (riders.any((r) => r.riderCode.toUpperCase() == upperRiderCode)) {
      throw Exception('Rider Code "$upperRiderCode" is already registered in the union.');
    }
    if (riders.any((r) => r.licenseNumber.toUpperCase() == upperLicense)) {
      throw Exception('Driver\'s Licence "$upperLicense" is already in use by another rider.');
    }
    if (bikes.any((b) => b.plateNumber.toUpperCase() == upperPlate)) {
      throw Exception('Motorcycle plate "$upperPlate" is already registered.');
    }

    final now = DateTime.now();
    final profileId = 'prof-${now.millisecondsSinceEpoch}';
    final riderId = 'rider-${now.millisecondsSinceEpoch}';
    final bikeId = 'bike-${now.millisecondsSinceEpoch}';

    final zone = stationZones.firstWhere(
      (z) => z.id == zoneId,
      orElse: () => stationZones.first,
    );

    // Profile
    final newProfile = Profile(
      id: profileId,
      username: upperRiderCode,
      fullName: fullName.trim(),
      phoneNumber: phoneNumber.trim(),
      role: 'rider',
      avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=$upperRiderCode',
      authProvider: 'email',
      createdAt: now,
    );
    profiles.add(newProfile);

    // Rider
    final newRider = Rider(
      id: riderId,
      riderCode: upperRiderCode,
      profileId: profileId,
      fullName: fullName.trim(),
      phoneNumber: phoneNumber.trim(),
      licenseNumber: upperLicense,
      zoneId: zone.id,
      emergencyContactName: emergencyContactName?.trim(),
      emergencyContactPhone: emergencyContactPhone?.trim(),
      status: 'ACTIVE',
      registeredAt: now,
      zoneName: zone.name,
      linkedPlateNumber: upperPlate,
      linkedBikeModel: model.trim(),
      isInspected: false,
      totalDuesPaid: 0.0,
      inspectionStatus: 'PENDING',
    );
    riders.add(newRider);

    // Bike (starts with PENDING inspection status as requested)
    final newBike = Bike(
      id: bikeId,
      plateNumber: upperPlate,
      riderId: riderId,
      zoneId: zone.id,
      make: make.trim(),
      model: model.trim(),
      color: color.trim(),
      manufactureYear: manufactureYear,
      chassisNumber: chassisNumber?.trim() ?? 'CH-$upperPlate',
      inspectionStatus: 'PENDING',
      isInspected: false,
      totalDuesPaid: 0.0,
      createdAt: now,
      riderName: fullName.trim(),
      riderPhone: phoneNumber.trim(),
      riderCode: upperRiderCode,
      zoneName: zone.name,
    );
    bikes.add(newBike);

    // Audit trail
    auditTrailLogs.insert(
      0,
      AuditTrailLog(
        id: 'audit-${now.millisecondsSinceEpoch}',
        actorProfileId: profileId,
        action: 'REGISTER_RIDER_BIKE',
        tableName: 'riders',
        recordId: riderId,
        details: {
          'rider_code': upperRiderCode,
          'plate': upperPlate,
          'license': upperLicense,
          'zone': zone.name,
        },
        createdAt: now,
        actorName: 'Union Registrar',
      ),
    );

    // Notification
    notifications.insert(
      0,
      AppNotification(
        id: 'notif-${now.millisecondsSinceEpoch}',
        recipientProfileId: profileId,
        title: 'Registration Successful',
        body: 'Welcome to TransitFlow SL! Your bike $upperPlate is pending road safety inspection.',
        category: 'GENERAL',
        isRead: false,
        createdAt: now,
      ),
    );

    return {
      'success': true,
      'rider': newRider,
      'bike': newBike,
      'profile': newProfile,
    };
  }

  /// Record Safety Inspection
  Map<String, dynamic> recordSafetyInspection({
    required String bikeId,
    required bool brakesOk,
    required bool lightsOk,
    required bool tiresOk,
    required bool helmetGearOk,
    required String status, // 'PASSED', 'PENDING', 'FLAGGED'
    String? remarks,
    String? inspectorProfileId,
    String? inspectorName,
  }) {
    final bike = bikes.firstWhere((b) => b.id == bikeId);
    final rider = riders.firstWhere((r) => r.id == bike.riderId);

    final now = DateTime.now();
    final inspectionId = 'insp-${now.millisecondsSinceEpoch}';
    final randomSuffix = (Random().nextInt(900) + 100).toString();
    final inspectionCode = 'INSP-${DateFormat('yyyyMM').format(now)}-$randomSuffix';

    final isPassed = status == 'PASSED';
    bike.inspectionStatus = status;
    bike.isInspected = isPassed;
    bike.updatedAt = now;

    rider.inspectionStatus = status;
    rider.isInspected = isPassed;

    final newInsp = SafetyInspection(
      id: inspectionId,
      inspectionCode: inspectionCode,
      bikeId: bikeId,
      riderId: rider.id,
      inspectorProfileId: inspectorProfileId,
      brakesOk: brakesOk,
      lightsOk: lightsOk,
      tiresOk: tiresOk,
      helmetGearOk: helmetGearOk,
      status: status,
      remarks: remarks,
      inspectedAt: now,
      expiresAt: now.add(const Duration(days: 90)),
      plateNumber: bike.plateNumber,
      bikeModel: bike.model,
      riderName: rider.fullName,
      inspectorName: inspectorName ?? 'Station Safety Officer',
    );
    safetyInspections.insert(0, newInsp);

    // Audit trail
    auditTrailLogs.insert(
      0,
      AuditTrailLog(
        id: 'audit-${now.millisecondsSinceEpoch}',
        actorProfileId: inspectorProfileId,
        action: 'RECORD_INSPECTION',
        tableName: 'safety_inspections',
        recordId: inspectionId,
        details: {
          'plate': bike.plateNumber,
          'status': status,
          'brakes': brakesOk,
          'lights': lightsOk,
          'tires': tiresOk,
          'helmet': helmetGearOk,
        },
        createdAt: now,
        actorName: inspectorName ?? 'Safety Inspector',
      ),
    );

    // Notification to rider
    if (rider.profileId != null) {
      notifications.insert(
        0,
        AppNotification(
          id: 'notif-${now.millisecondsSinceEpoch}',
          recipientProfileId: rider.profileId!,
          title: isPassed ? 'Safety Inspection Passed' : 'Inspection $status',
          body: isPassed
              ? 'Your bike ${bike.plateNumber} has PASSED inspection. Valid for 90 days.'
              : 'Bike ${bike.plateNumber} has been marked $status. Remarks: ${remarks ?? "See inspector."}',
          category: 'INSPECTION',
          isRead: false,
          createdAt: now,
        ),
      );
    }

    return {
      'success': true,
      'inspection': newInsp,
      'bike': bike,
    };
  }

  /// Submit a Compliance Dispute
  ComplianceDispute submitDispute({
    required String riderId,
    required String bikeId,
    String? dailyLogId,
    required String subject,
    required String description,
  }) {
    final now = DateTime.now();
    final randomSuffix = (Random().nextInt(900) + 100).toString();
    final ticketCode = 'DISP-${DateFormat('yyyy').format(now)}-$randomSuffix';
    final rider = riders.firstWhere((r) => r.id == riderId);
    final bike = bikes.firstWhere((b) => b.id == bikeId);

    final dispute = ComplianceDispute(
      id: 'disp-${now.millisecondsSinceEpoch}',
      ticketCode: ticketCode,
      riderId: riderId,
      bikeId: bikeId,
      dailyLogId: dailyLogId,
      subject: subject,
      description: description,
      status: 'OPEN',
      createdAt: now,
      riderName: rider.fullName,
      plateNumber: bike.plateNumber,
    );
    complianceDisputes.insert(0, dispute);
    return dispute;
  }

  /// Update Dispute Status
  void updateDisputeStatus({
    required String disputeId,
    required String status,
    required String resolutionNotes,
  }) {
    final dispute = complianceDisputes.firstWhere((d) => d.id == disputeId);
    dispute.status = status;
    dispute.resolutionNotes = resolutionNotes;
    if (status == 'RESOLVED' || status == 'REJECTED') {
      dispute.resolvedAt = DateTime.now();
    }
  }

  /// Mark Notification Read
  void markNotificationAsRead(String id) {
    final notif = notifications.firstWhere((n) => n.id == id);
    notif.isRead = true;
  }

  void markAllNotificationsAsRead() {
    for (var n in notifications) {
      n.isRead = true;
    }
  }

  /// Table counts for Supabase / Local Diagnostics
  Map<String, int> getTableCounts() {
    return {
      'profiles': profiles.length,
      'station_zones': stationZones.length,
      'riders': riders.length,
      'bikes': bikes.length,
      'fee_types': feeTypes.length,
      'daily_logs': dailyLogs.length,
      'payment_receipts': paymentReceipts.length,
      'safety_inspections': safetyInspections.length,
      'station_permits': stationPermits.length,
      'compliance_disputes': complianceDisputes.length,
      'union_announcements': unionAnnouncements.length,
      'notifications': notifications.length,
      'audit_trail_logs': auditTrailLogs.length,
    };
  }

  /// Total Revenue in Sierra Leonean Leones
  double get totalRevenue =>
      bikes.fold(0.0, (sum, bike) => sum + bike.totalDuesPaid);

  /// Inspected Bike Count
  int get inspectedCount => bikes.where((b) => b.isInspected).length;

  /// Inspection Compliance Rate (%)
  double get complianceRate =>
      bikes.isEmpty ? 0.0 : (inspectedCount / bikes.length) * 100.0;
}