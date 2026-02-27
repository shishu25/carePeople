import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_models.dart';
import '../services/appointment_service.dart';
import '../mixed/appbar.dart';
import 'doctor_profile_page.dart';

class AppointmentsListPage extends StatefulWidget {
  final String phoneNumber;

  const AppointmentsListPage({super.key, required this.phoneNumber});

  @override
  State<AppointmentsListPage> createState() => _AppointmentsListPageState();
}

class _AppointmentsListPageState extends State<AppointmentsListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Appointment> _upcomingAppointments = [];
  List<Appointment> _previousAppointments = [];
  List<Doctor> _allDoctors = [];
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

    final appointments =
        await AppointmentService.getPatientAppointments(widget.phoneNumber);
    final doctors = await AppointmentService.loadDoctors();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Categorize appointments
    final upcoming = <Appointment>[];
    final previous = <Appointment>[];

    for (var appointment in appointments) {
      try {
        final appointmentDate = DateFormat('yyyy-MM-dd').parse(appointment.date);
        if (appointmentDate.isAfter(today) ||
            appointmentDate.isAtSameMomentAs(today)) {
          upcoming.add(appointment);
        } else {
          previous.add(appointment);
        }
      } catch (e) {
        // If date parsing fails, add to previous
        previous.add(appointment);
      }
    }

    // Sort upcoming ascending (soonest first), previous descending (latest first)
    upcoming.sort((a, b) => a.date.compareTo(b.date));
    previous.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _upcomingAppointments = upcoming;
      _previousAppointments = previous;
      _allDoctors = doctors;
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
          const CustomAppBar(
            title: 'My Appointments',
            showBackButton: true,
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue[700],
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.blue[700],
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAppointmentList(_upcomingAppointments, true, screenWidth),
                      _buildAppointmentList(_previousAppointments, false, screenWidth),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(
      List<Appointment> appointments, bool isUpcoming, double screenWidth) {
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
                  ? 'Book your first appointment to see it here'
                  : 'Your appointment history will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
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
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          final doctor = _allDoctors.firstWhere(
            (d) => d.id == appointment.doctorId,
            orElse: () => Doctor(
              id: appointment.doctorId,
              name: appointment.doctorName,
              department: 'Unknown',
              designation: '',
              degrees: '',
              roomNumber: '',
              consultationFee: 0,
              consultationDays: [],
              consultationTimes: '',
            ),
          );

          return _buildAppointmentCard(
            appointment,
            doctor,
            isUpcoming,
            screenWidth,
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(
    Appointment appointment,
    Doctor doctor,
    bool isUpcoming,
    double screenWidth,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorProfilePage(doctor: doctor),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Info Row
              Row(
                children: [
                  // Doctor Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isUpcoming ? Colors.blue[100] : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        doctor.name.split(' ')[1][0],
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isUpcoming ? Colors.blue[700] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Doctor Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doctor.department,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (doctor.designation.isNotEmpty)
                          Text(
                            doctor.designation,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isUpcoming
                          ? Colors.green[50]
                          : Colors.grey[200],
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
                        color: isUpcoming
                            ? Colors.green[700]
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Appointment Details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.calendar_today,
                      'Date',
                      _formatDate(appointment.date),
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.access_time,
                      'Time',
                      appointment.timeSlot,
                      Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.confirmation_number,
                      'Serial',
                      '#${appointment.serialNumber}',
                      Colors.purple,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.room,
                      'Room',
                      doctor.roomNumber,
                      Colors.teal,
                    ),
                  ),
                ],
              ),

              if (isUpcoming) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please arrive 10 minutes early',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
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
      ),
    );
  }

  Widget _buildDetailItem(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateFormat('yyyy-MM-dd').parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
