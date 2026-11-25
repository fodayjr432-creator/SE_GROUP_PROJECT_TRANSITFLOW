import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/rider.dart';
import '../controllers/union_controller.dart';
import '../widgets/status_pill.dart';
import 'bike_detail_screen.dart';
import 'rider_ledger_screen.dart';
import 'disputes_screen.dart';

/// Screen 5: Rider Compliance & Licence Profile Screen
/// Full rider identity, licence number, phone, assigned Freetown station zone,
/// registration date, and bike compliance summary.
class RiderProfileScreen extends StatelessWidget {
  final Rider? rider;

  const RiderProfileScreen({super.key, this.rider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final union = context.watch<UnionController>();

    final targetRider = rider ?? (union.riders.isNotEmpty ? union.riders.first : null);
    final linkedBike = targetRider != null
        ? union.bikes.firstWhere(
            (b) => b.riderId == targetRider.id,
            orElse: () => union.bikes.first,
          )
        : null;

    if (targetRider == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rider Profile')),
        body: const Center(child: Text('No rider profile found.')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Rider Compliance Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem_outlined),
            tooltip: 'File Appeal',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DisputesScreen(
                    defaultRiderId: targetRider.id,
                    defaultBikeId: linkedBike?.id,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            // Top Header Card with Rider Code Badge
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, Color(0xFF0B6B3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        child: Text(
                          targetRider.riderCode,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              targetRider.fullName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Phone: ${targetRider.phoneNumber}',
                              style: const TextStyle(fontSize: 13, color: Colors.white70),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Terminal: ${targetRider.zoneName ?? "Freetown Zone"}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderStat('Union Status', targetRider.status, Colors.white),
                      _buildHeaderStat(
                        'Dues Paid',
                        AppTheme.formatLeones(targetRider.totalDuesPaid ?? 0.0),
                        AppTheme.goldenAmber,
                      ),
                      _buildHeaderStat(
                        'Inspection',
                        targetRider.inspectionStatus ?? 'PENDING',
                        Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Official Driver's Licence & Identity Specs Card
            Card(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.badge_rounded, color: AppTheme.accentBlue),
                        SizedBox(width: 8),
                        Text(
                          'Licence & Identity Verification',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow('Driver\'s Licence #', targetRider.licenseNumber, isHighlight: true),
                    _buildInfoRow('Rider Code (Union ID)', targetRider.riderCode),
                    _buildInfoRow('Registration Date', AppTheme.formatDateOnly(targetRider.registeredAt)),
                    _buildInfoRow('Station Terminal', targetRider.zoneName ?? 'Lumley Junction'),
                    _buildInfoRow('Operating City', 'Freetown, Sierra Leone'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Emergency Contact Card
            Card(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.contact_phone_rounded, color: AppTheme.statusPending),
                        SizedBox(width: 8),
                        Text(
                          'Emergency Contact Information',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      'Emergency Contact',
                      targetRider.emergencyContactName ?? 'Fatmata Bah',
                    ),
                    _buildInfoRow(
                      'Emergency Phone',
                      targetRider.emergencyContactPhone ?? '076998811',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Linked Motorcycle Fleet Card
            if (linkedBike != null)
              Card(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.two_wheeler_rounded, color: AppTheme.primaryGreen),
                              SizedBox(width: 8),
                              Text(
                                'Linked Okada Motorcycle',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          StatusPill(status: linkedBike.inspectionStatus),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildInfoRow('Plate Number', linkedBike.plateNumber, isHighlight: true),
                      _buildInfoRow('Make & Model', '${linkedBike.make} ${linkedBike.model}'),
                      _buildInfoRow('Colour & Year', '${linkedBike.color} • ${linkedBike.manufactureYear}'),
                      _buildInfoRow('Chassis / VIN', linkedBike.chassisNumber ?? 'N/A'),
                      _buildInfoRow('Total Dues Paid', AppTheme.formatLeones(linkedBike.totalDuesPaid)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BikeDetailScreen(bike: linkedBike),
                                  ),
                                );
                              },
                              child: const Text('View Bike Specs'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RiderLedgerScreen(
                                      rider: targetRider,
                                      bike: linkedBike,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Bike Ledger'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? AppTheme.primaryGreen : null,
            ),
          ),
        ],
      ),
    );
  }
}
