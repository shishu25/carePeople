import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:math';
import '../mixed/appbar.dart';
import '../home/spashpage/identification.dart';
import '../services/session_service.dart';
import 'doctor_appointments_page.dart';
import 'write_prescription_page.dart';
import 'patient_records_page.dart';

class DoctorDashboard extends StatefulWidget {
  final Map<String, dynamic> doctorData;

  const DoctorDashboard({super.key, required this.doctorData});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  // ── Parsed doctor fields ──────────────────────────────────────────────────
  late final String _name;
  late final String _department;
  late final String _designation;
  late final String _doctorId;
  late final String _degrees;
  late final String _roomNumber;
  late final num _consultationFee;
  late final List<dynamic> _consultationDays;
  late final String _consultationTimes;

  @override
  void initState() {
    super.initState();
    final d = widget.doctorData;
    _name = d['name'] ?? 'Doctor';
    _department = d['department'] ?? '';
    _designation = d['designation'] ?? '';
    _doctorId = d['id'] ?? '';
    _degrees = d['degrees'] ?? '';
    _roomNumber = d['roomNumber'] ?? d['room_number'] ?? 'N/A';
    _consultationFee = d['consultationFee'] ?? d['consultation_fee'] ?? 0;
    _consultationDays = d['consultationDays'] ?? d['consultation_days'] ?? [];
    _consultationTimes =
        d['consultationTimes'] ?? d['consultation_times'] ?? 'N/A';
  }

  // ── Grid items ─────────────────────────────────────────────────────────────
  static const List<_GridItem> _gridItems = [
    _GridItem(
      icon: Icons.event_note_outlined,
      title: 'Appointments',
      bgColor: Color(0xFFA5D6A7), // green[300]
      iconColor: Colors.green,
    ),
    _GridItem(
      icon: Icons.people_outline,
      title: 'Patient\nRecords',
      bgColor: Color(0xFF80DEEA), // cyan[200]
      iconColor: Colors.blue,
    ),
    _GridItem(
      icon: Icons.edit_note_outlined,
      title: 'Write\nPrescription',
      bgColor: Color(0xFFBF360C), // deepOrange[900]
      iconColor: Color(0xFFFFEE58), // yellow[400]
    ),
    _GridItem(
      icon: Icons.bar_chart_outlined,
      title: 'Report\nAnalytics',
      bgColor: Colors.black,
      iconColor: Colors.blueAccent,
    ),
    _GridItem(
      icon: Icons.newspaper_outlined,
      title: 'Hospital\nNews',
      bgColor: Color(0xFFFFCDD2), // red[100]
      iconColor: Colors.red,
    ),
    _GridItem(
      icon: Icons.auto_awesome,
      title: 'AI\nAssistant',
      bgColor: Color(0xFFE1BEE7), // purple[100]
      iconColor: Colors.purple,
    ),
  ];

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = screenWidth * 0.04;
    final cardBorderRadius = screenWidth * 0.04;
    final featureCardHeight = screenHeight * 0.18;
    final iconSize = screenWidth * 0.07;
    final welcomeFontSize = screenWidth * 0.06;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Subtle background watermark, same as Patient Dashboard
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/images/CarePeople.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              CustomAppBar(
                title: 'Doctor Portal',
                showBackButton: false,
                gradientColors: const [Color(0xFF6A1B9A), Color(0xFF2E7D32)],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: screenHeight * 0.03),

                        // ── Welcome Card (mirrors Patient Portal card) ──────
                        _buildWelcomeCard(
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          cardBorderRadius: cardBorderRadius,
                          welcomeFontSize: welcomeFontSize,
                          iconSize: iconSize,
                        ),

                        SizedBox(height: screenHeight * 0.025),

                        // ── Feature grid (3 rows × 2 cols) ─────────────────
                        for (int row = 0; row < 3; row++) ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildFeatureCard(
                                  item: _gridItems[row * 2],
                                  cardHeight: featureCardHeight,
                                  screenWidth: screenWidth,
                                  borderRadius: cardBorderRadius,
                                  onTap: switch (row * 2) {
                                    0 => () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DoctorAppointmentsPage(
                                          doctorId: _doctorId,
                                          doctorName: _name,
                                        ),
                                      ),
                                    ),
                                    2 => () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => WritePrescriptionPage(
                                          doctorId: _doctorId,
                                          doctorName: _name,
                                          doctorDepartment: _department,
                                          doctorDesignation: _designation,
                                          doctorDegrees: _degrees,
                                        ),
                                      ),
                                    ),
                                    _ => null,
                                  },
                                ),
                              ),
                              SizedBox(width: horizontalPadding),
                              Expanded(
                                child: _buildFeatureCard(
                                  item: _gridItems[row * 2 + 1],
                                  cardHeight: featureCardHeight,
                                  screenWidth: screenWidth,
                                  borderRadius: cardBorderRadius,
                                  onTap: switch (row * 2 + 1) {
                                    1 => () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PatientRecordsPage(
                                          doctorId: _doctorId,
                                          doctorName: _name,
                                        ),
                                      ),
                                    ),
                                    _ => null,
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (row < 2) SizedBox(height: horizontalPadding),
                        ],

                        SizedBox(height: screenHeight * 0.02),

                        // ── Contact Hospital Assistant banner ───────────────
                        _buildAssistantBanner(
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                        ),

                        SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      // ── Bottom bar — App Tour (same style as Patient Portal) ─────────────
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(
          horizontalPadding,
          0,
          horizontalPadding,
          screenHeight * 0.06,
        ),
        child: Material(
          color: const Color(
            0xFFE1BEE7,
          ), // light purple — same as Patient Portal
          borderRadius: BorderRadius.circular(30),
          elevation: 2,
          child: InkWell(
            onTap: _showAppTourModal,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: screenHeight * 0.02,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        color: Colors.black,
                        size: screenWidth * 0.06,
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Text(
                        'App Tour',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.black,
                    size: screenWidth * 0.07,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Welcome Card ──────────────────────────────────────────────────────────
  Widget _buildWelcomeCard({
    required double screenWidth,
    required double screenHeight,
    required double cardBorderRadius,
    required double welcomeFontSize,
    required double iconSize,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF2E7D32)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      padding: EdgeInsets.all(screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome $_name',
            style: TextStyle(
              fontSize: welcomeFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: screenHeight * 0.03),

          // ── Quick-access icons row (Profile · Settings · Hospital Assistant) ─
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickIcon(
                icon: Icons.person_outline,
                label: 'Profile',
                backgroundColor: Colors.purple[200]!,
                iconColor: Colors.purple,
                iconSize: iconSize,
                screenWidth: screenWidth,
                onTap: () => _showProfileSheet(context, screenWidth),
              ),
              _buildQuickIcon(
                icon: Icons.settings_outlined,
                label: 'Settings',
                backgroundColor: Colors.purple[200]!,
                iconColor: Colors.purple,
                iconSize: iconSize,
                screenWidth: screenWidth,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorSettingsPage(
                        doctorName: _name,
                        doctorId: _doctorId,
                      ),
                    ),
                  );
                },
              ),
              _buildQuickIcon(
                icon: Icons.support_agent,
                label: 'Assistant',
                backgroundColor: Colors.purple[200]!,
                iconColor: Colors.purple,
                iconSize: iconSize,
                screenWidth: screenWidth,
                onTap: () => _showHospitalAssistantSheet(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Quick-access icon button (identical pattern to Patient Portal) ─────────
  Widget _buildQuickIcon({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color? iconColor,
    required double iconSize,
    required double screenWidth,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(screenWidth * 0.03),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: iconSize),
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Feature card (identical pattern to Patient Portal) ────────────────────
  Widget _buildFeatureCard({
    required _GridItem item,
    required double cardHeight,
    required double screenWidth,
    required double borderRadius,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () => _showComingSoon(item.title.replaceAll('\n', ' ')),
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              item.bgColor,
              item.iconColor?.withOpacity(0.3) ?? item.bgColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: item.iconColor, size: screenWidth * 0.12),
            SizedBox(height: screenWidth * 0.03),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Profile bottom sheet ───────────────────────────────────────────────────
  void _showProfileSheet(BuildContext context, double screenWidth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Sheet header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Doctor Profile',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar + name block
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.blue[100],
                              child: Text(
                                _name.length > 4
                                    ? _name[4].toUpperCase()
                                    : _name[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _designation,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _doctorId,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Profile Info ─────────────────────────────────
                        _profileTile(
                          icon: Icons.local_hospital_outlined,
                          label: 'Department',
                          value: _department,
                        ),
                        _profileTile(
                          icon: Icons.school_outlined,
                          label: 'Degrees',
                          value: _degrees,
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'Consultation Info',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),

                        // Room + Fee row
                        Row(
                          children: [
                            Expanded(
                              child: _infoChip(
                                icon: Icons.meeting_room_outlined,
                                label: 'Room',
                                value: _roomNumber,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _infoChip(
                                icon: Icons.payments_outlined,
                                label: 'Fee',
                                value: '৳$_consultationFee',
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Consultation Days
                        const Text(
                          'Consultation Days',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _consultationDays.map((day) {
                            return Chip(
                              label: Text(
                                day.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              backgroundColor: Colors.blue[50],
                              side: BorderSide(color: Colors.blue[200]!),
                              labelStyle: TextStyle(color: Colors.blue[800]),
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // Consultation Times
                        _profileTile(
                          icon: Icons.schedule_outlined,
                          label: 'Consultation Hours',
                          value: _consultationTimes,
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _profileTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue[600]),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Contact Hospital Assistant banner ─────────────────────────────────────
  Widget _buildAssistantBanner({
    required double screenWidth,
    required double screenHeight,
  }) {
    return InkWell(
      onTap: () => _showHospitalAssistantSheet(context),
      borderRadius: BorderRadius.circular(screenWidth * 0.04),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.022,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFF2E7D32)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent,
                color: Colors.white,
                size: screenWidth * 0.07,
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Hospital Assistant',
                    style: TextStyle(
                      fontSize: screenWidth * 0.042,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    'Get help or report issues',
                    style: TextStyle(
                      fontSize: screenWidth * 0.032,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: screenWidth * 0.07,
            ),
          ],
        ),
      ),
    );
  }

  // ── App Tour modal trigger ─────────────────────────────────────────────────
  final List<String> _appTourVideos = [
    'dQw4w9WgXcQ',
    'kJQP7kiw5Fk',
    '9bZkp7q19f0',
    'hTWKbfoikeg',
  ];

  void _showAppTourModal() {
    final random = Random();
    final videoId = _appTourVideos[random.nextInt(_appTourVideos.length)];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (_) => _AppTourModal(videoId: videoId),
    );
  }

  // ── Hospital Assistant sheet ───────────────────────────────────────────────
  void _showHospitalAssistantSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.75,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.support_agent,
                            color: Colors.purple[700],
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Hospital Assistant',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Info card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.purple[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need help?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[800],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Contact the hospital administration for any technical issues, account problems, or general inquiries.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Contact options
                        _assistantOption(
                          icon: Icons.phone_outlined,
                          title: 'Call Administration',
                          subtitle: '+880 1800-000000',
                          color: Colors.green,
                          onTap: () => _showComingSoon('Call Administration'),
                        ),
                        const SizedBox(height: 10),
                        _assistantOption(
                          icon: Icons.email_outlined,
                          title: 'Send Email',
                          subtitle: 'admin@carepeople.com',
                          color: Colors.blue,
                          onTap: () => _showComingSoon('Send Email'),
                        ),
                        const SizedBox(height: 10),
                        _assistantOption(
                          icon: Icons.chat_outlined,
                          title: 'Live Chat',
                          subtitle: 'Chat with support team',
                          color: Colors.orange,
                          onTap: () => _showComingSoon('Live Chat'),
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _assistantOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon!'),
        backgroundColor: Colors.purple[700],
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── Data class for grid items ──────────────────────────────────────────────────
class _GridItem {
  final IconData icon;
  final String title;
  final Color bgColor;
  final Color? iconColor;

  const _GridItem({
    required this.icon,
    required this.title,
    required this.bgColor,
    this.iconColor,
  });
}

// ── App Tour Modal (YouTube — same structure as Patient Portal) ────────────────
class _AppTourModal extends StatefulWidget {
  final String videoId;

  const _AppTourModal({required this.videoId});

  @override
  State<_AppTourModal> createState() => _AppTourModalState();
}

class _AppTourModalState extends State<_AppTourModal> {
  late YoutubePlayerController _ytController;

  @override
  void initState() {
    super.initState();
    _ytController = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
      ),
    );
  }

  @override
  void dispose() {
    _ytController.pause();
    _ytController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'App Tour',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // YouTube Player
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: YoutubePlayer(
                            controller: _ytController,
                            showVideoProgressIndicator: true,
                            progressIndicatorColor: Colors.purple,
                            onReady: () {},
                            onEnded: (_) {},
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome to the Doctor Portal',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Explore how to use the Care People Doctor Portal — manage appointments, access patient records, write prescriptions, and more.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Doctor Settings Page (mirrors Patient Settings exactly) ───────────────────
class DoctorSettingsPage extends StatefulWidget {
  final String doctorName;
  final String doctorId;

  const DoctorSettingsPage({
    super.key,
    required this.doctorName,
    required this.doctorId,
  });

  @override
  State<DoctorSettingsPage> createState() => _DoctorSettingsPageState();
}

class _DoctorSettingsPageState extends State<DoctorSettingsPage> {
  bool _notificationsEnabled = true;
  String _appAppearance = 'System';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const CustomAppBar(title: 'Settings', showBackButton: true),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  children: [
                    // Notifications Card
                    _buildSettingsCard(
                      child: SwitchListTile(
                        title: const Text(
                          'Notifications',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        secondary: const Icon(Icons.notifications_outlined),
                        value: _notificationsEnabled,
                        activeColor: Colors.blue,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                      ),
                    ),

                    SizedBox(height: screenWidth * 0.04),

                    // App Appearance Card
                    _buildSettingsCard(
                      child: ListTile(
                        leading: const Icon(Icons.palette_outlined),
                        title: const Text(
                          'App Appearance',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        trailing: DropdownButton<String>(
                          value: _appAppearance,
                          underline: const SizedBox(),
                          items: ['System', 'Light', 'Dark']
                              .map(
                                (mode) => DropdownMenuItem(
                                  value: mode,
                                  child: Text(mode),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _appAppearance = value!;
                            });
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: screenWidth * 0.04),

                    // Security, Terms, Privacy, Help Card
                    _buildSettingsCard(
                      child: Column(
                        children: [
                          _buildSettingsTile(
                            icon: Icons.security_outlined,
                            title: 'Security',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Security settings coming soon!',
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          _buildSettingsTile(
                            icon: Icons.description_outlined,
                            title: 'Terms & Conditions',
                            trailing: Icons.link,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Opening Terms & Conditions...',
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          _buildSettingsTile(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            trailing: Icons.link,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Opening Privacy Policy...'),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          _buildSettingsTile(
                            icon: Icons.help_outline,
                            title: 'Help',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Help center coming soon!'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenWidth * 0.04),

                    // Invite & Logout Card
                    _buildSettingsCard(
                      child: Column(
                        children: [
                          _buildSettingsTile(
                            icon: Icons.person_add_outlined,
                            title: 'Invite a Friend',
                            trailing: Icons.link,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Share feature coming soon!'),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          _buildSettingsTile(
                            icon: Icons.logout,
                            title: 'Logout',
                            textColor: Colors.red,
                            onTap: () => _showLogoutDialog(context),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenWidth * 0.04),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    IconData? trailing,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: textColor,
        ),
      ),
      trailing: Icon(trailing ?? Icons.chevron_right, color: Colors.grey[600]),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx); // close dialog
                await SessionService.clearDoctorSession();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const IdentificationPage()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
