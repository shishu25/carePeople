import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_models.dart';
import '../services/appointment_service.dart';
import '../mixed/appbar.dart';

/// Shows all appointments booked with a specific doctor, split into
/// Upcoming and Previous tabs.  Patients are identified by name and
/// phone number; each card shows serial, date, time slot, and status.
class DoctorAppointmentsPage extends StatefulWidget {
  final String doctorId;
  final String doctorName;

  const DoctorAppointmentsPage({
    super.key,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Appointment> _upcomingAppointments = [];
  List<Appointment> _previousAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);

    final appointments = await AppointmentService.getDoctorAppointments(
      widget.doctorId,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcoming = <Appointment>[];
    final previous = <Appointment>[];

    for (final appt in appointments) {
      try {
        final apptDate = DateFormat('yyyy-MM-dd').parse(appt.date);
        if (apptDate.isAfter(today) || apptDate.isAtSameMomentAs(today)) {
          upcoming.add(appt);
        } else {
          previous.add(appt);
        }
      } catch (_) {
        previous.add(appt);
      }
    }

    // Upcoming: soonest first; Previous: latest first
    upcoming.sort((a, b) => a.date.compareTo(b.date));
    previous.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _upcomingAppointments = upcoming;
      _previousAppointments = previous;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // ── AppBar ──────────────────────────────────────────────────────
          CustomAppBar(
            title: 'My Appointments',
            subtitle: widget.doctorName,
            showBackButton: true,
            gradientColors: const [Color(0xFF6A1B9A), Color(0xFF2E7D32)],
          ),

          // ── Summary badge row ───────────────────────────────────────────
          if (!_isLoading)
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: 10,
              ),
              child: Row(
                children: [
                  _buildSummaryChip(
                    label: 'Upcoming',
                    count: _upcomingAppointments.length,
                    color: Colors.green[700]!,
                    bgColor: Colors.green[50]!,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryChip(
                    label: 'Completed',
                    count: _previousAppointments.length,
                    color: Colors.grey[700]!,
                    bgColor: Colors.grey[200]!,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryChip(
                    label: 'Total',
                    count:
                        _upcomingAppointments.length +
                        _previousAppointments.length,
                    color: Colors.purple[700]!,
                    bgColor: Colors.purple[50]!,
                  ),
                ],
              ),
            ),

          // ── Tab bar ─────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.purple[700],
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.purple[700],
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Previous'),
              ],
            ),
          ),

          // ── Tab views ───────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_upcomingAppointments, isUpcoming: true),
                      _buildList(_previousAppointments, isUpcoming: false),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Summary chip ─────────────────────────────────────────────────────────
  Widget _buildSummaryChip({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Appointment list ──────────────────────────────────────────────────────
  Widget _buildList(
    List<Appointment> appointments, {
    required bool isUpcoming,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.event_available : Icons.history,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming
                  ? 'No upcoming appointments'
                  : 'No previous appointments',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUpcoming
                  ? 'Patients can book appointments through the Patient Portal'
                  : 'Completed appointments will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: EdgeInsets.all(screenWidth * 0.04),
        itemCount: appointments.length,
        itemBuilder: (context, index) =>
            _buildCard(appointments[index], isUpcoming: isUpcoming),
      ),
    );
  }

  // ── Appointment card ──────────────────────────────────────────────────────
  Widget _buildCard(Appointment appt, {required bool isUpcoming}) {
    final initials = _initials(appt.patientName);
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      margin: EdgeInsets.only(bottom: screenWidth * 0.04),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Patient info row ─────────────────────────────────────────
            Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isUpcoming ? Colors.purple[100] : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isUpcoming
                            ? Colors.purple[700]
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Name + phone
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appt.patientName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 13, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            appt.patientPhone,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isUpcoming ? Colors.green[50] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isUpcoming
                          ? Colors.green[300]!
                          : Colors.grey[400]!,
                    ),
                  ),
                  child: Text(
                    isUpcoming ? 'Upcoming' : 'Completed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isUpcoming ? Colors.green[700] : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),

            // ── Appointment details grid ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _detailItem(
                    Icons.calendar_today,
                    'Date',
                    _formatDate(appt.date),
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _detailItem(
                    Icons.access_time,
                    'Time',
                    appt.timeSlot,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _detailItem(
                    Icons.confirmation_number,
                    'Serial',
                    '#${appt.serialNumber}',
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _detailItem(
                    Icons.check_circle_outline,
                    'Status',
                    appt.status,
                    isUpcoming ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),

            // ── Reminder banner for upcoming ─────────────────────────────
            if (isUpcoming) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.purple[700],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Patient should arrive 10 minutes early',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Detail item (icon + label + value) ────────────────────────────────────
  Widget _detailItem(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateFormat('yyyy-MM-dd').parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}
