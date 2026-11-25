enum PaymentStatus {
  paid,
  pending,
  failed,
  refunded,
}

class DailyLog {
  final String id;
  final String logCode; // e.g. LOG-20261124-001
  final String bikeId;
  final String riderId;
  final String? zoneId;
  final String feeTypeId;
  final double amount;
  final String paymentMethod; // 'CASH_OFFICIAL', 'ORANGE_MONEY', 'AFRICEL_MONEY', 'CARD', 'ONLINE'
  final PaymentStatus paymentStatus;
  final String? recordedByProfileId;
  final String? notes;
  final DateTime paidAt;

  // Auxiliary join fields for UI display
  String? plateNumber;
  String? riderName;
  String? riderCode;
  String? feeTypeName;
  String? feeTypeCode;
  String? zoneName;

  DailyLog({
    required this.id,
    required this.logCode,
    required this.bikeId,
    required this.riderId,
    this.zoneId,
    required this.feeTypeId,
    required this.amount,
    this.paymentMethod = 'CASH_OFFICIAL',
    this.paymentStatus = PaymentStatus.paid,
    this.recordedByProfileId,
    this.notes,
    DateTime? paidAt,
    this.plateNumber,
    this.riderName,
    this.riderCode,
    this.feeTypeName,
    this.feeTypeCode,
    this.zoneName,
  }) : paidAt = paidAt ?? DateTime.now();

  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog(
      id: json['id'] as String,
      logCode: json['log_code'] as String,
      bikeId: json['bike_id'] as String,
      riderId: json['rider_id'] as String,
      zoneId: json['zone_id'] as String?,
      feeTypeId: json['fee_type_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String? ?? 'CASH_OFFICIAL',
      paymentStatus: _parsePaymentStatus(json['payment_status'] as String?),
      recordedByProfileId: json['recorded_by_profile_id'] as String?,
      notes: json['notes'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      plateNumber: json['plate_number'] as String?,
      riderName: json['rider_name'] as String?,
      riderCode: json['rider_code'] as String?,
      feeTypeName: json['fee_type_name'] as String?,
      feeTypeCode: json['fee_type_code'] as String?,
      zoneName: json['zone_name'] as String?,
    );
  }

  static PaymentStatus _parsePaymentStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'paid':
      default:
        return PaymentStatus.paid;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'log_code': logCode,
      'bike_id': bikeId,
      'rider_id': riderId,
      'zone_id': zoneId,
      'fee_type_id': feeTypeId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus.name,
      'recorded_by_profile_id': recordedByProfileId,
      'notes': notes,
      'paid_at': paidAt.toIso8601String(),
    };
  }
}
