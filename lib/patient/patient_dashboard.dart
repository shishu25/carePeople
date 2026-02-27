import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:math';
import '../mixed/appbar.dart';
import '../services/user_storage_service.dart';
import 'patient_profile_edit.dart';
import '../appointments/book_appointment_page.dart';
import '../settings/settings_page.dart';
import '../activities/activities_page.dart';

class PatientDashboard extends StatefulWidget {
  final String phoneNumber;

  const PatientDashboard({super.key, required this.phoneNumber});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await UserStorageService.getUserData(widget.phoneNumber);
    setState(() {
      _userData = userData;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive values based on screen size
    final horizontalPadding = screenWidth * 0.04; // 4% of screen width
    final cardBorderRadius = screenWidth * 0.04; // 4% of screen width
    final welcomeFontSize = screenWidth * 0.06; // 6% of screen width
    final iconSize = screenWidth * 0.07; // 7% of screen width
    final featureCardHeight = screenHeight * 0.18; // 18% of screen height
    final buttonPadding = screenWidth * 0.06; // 6% of screen width

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Background Image with Opacity
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/images/CarePeople.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Foreground Content
          Column(
            children: [
              CustomAppBar(
                title: 'Patient Portal',
                showBackButton: false,
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No new notifications'),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Notifications',
                  ),
                ],
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: screenHeight * 0.03),

                              // Welcome Card
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.green, Colors.blue],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    cardBorderRadius,
                                  ),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                padding: EdgeInsets.all(screenWidth * 0.05),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome ${_userData?['name']?.split(' ')[0] ?? 'Mr./Mrs.'}',
                                      style: TextStyle(
                                        fontSize: welcomeFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.03),
                                    // Top Row Icons
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildQuickAccessIcon(
                                          Icons.person_outline,
                                          'Your Profile',
                                          Colors.blue[200]!,
                                          Colors.blue,
                                          iconSize,
                                          screenWidth,
                                        ),
                                        _buildQuickAccessIcon(
                                          Icons.settings_outlined,
                                          'Settings',
                                          Colors.blue[200]!,
                                          Colors.blue,
                                          iconSize,
                                          screenWidth,
                                        ),
                                        _buildQuickAccessIcon(
                                          Icons.trending_up,
                                          'Activities',
                                          Colors.blue[200]!,
                                          Colors.blue,
                                          iconSize,
                                          screenWidth,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.025),

                              // Grid of Feature Cards
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildFeatureCard(
                                      Icons.calendar_today,
                                      'Book\nAppointment',
                                      Colors.green[300]!,
                                      Colors.green,
                                      featureCardHeight,
                                      screenWidth,
                                      cardBorderRadius,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                BookAppointmentPage(
                                                  phoneNumber:
                                                      widget.phoneNumber,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(width: horizontalPadding),
                                  Expanded(
                                    child: _buildFeatureCard(
                                      Icons.local_hospital_outlined,
                                      'Department Info',
                                      Colors.lightBlueAccent[100]!,
                                      Colors.blue,
                                      featureCardHeight,
                                      screenWidth,
                                      cardBorderRadius,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: horizontalPadding),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildFeatureCard(
                                      Icons.medical_services_outlined,
                                      'Doctor Info',
                                      Colors.deepOrange[800]!,
                                      Colors.yellow[400],
                                      featureCardHeight,
                                      screenWidth,
                                      cardBorderRadius,
                                    ),
                                  ),
                                  SizedBox(width: horizontalPadding),
                                  Expanded(
                                    child: _buildFeatureCard(
                                      Icons.local_pharmacy_outlined,
                                      'Tests',
                                      Colors.black,
                                      Colors.blueAccent,
                                      featureCardHeight,
                                      screenWidth,
                                      cardBorderRadius,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: horizontalPadding),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildFeatureCard(
                                      Icons.emergency,
                                      'Emergency\nService',
                                      Colors.red[50]!,
                                      Colors.red,
                                      featureCardHeight,
                                      screenWidth,
                                      cardBorderRadius,
                                    ),
                                  ),
                                  SizedBox(width: horizontalPadding),
                                  Expanded(
                                    child: _buildFeatureCard(
                                      Icons.auto_awesome,
                                      'AI Suggestion',
                                      Colors.purple[100]!,
                                      Colors.purple,
                                      featureCardHeight,
                                      screenWidth,
                                      cardBorderRadius,
                                    ),
                                  ),
                                ],
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
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(
          horizontalPadding,
          0,
          horizontalPadding,
          screenHeight * 0.06,
        ),
        child: Material(
          color: const Color(0xFFE1BEE7), // Light purple color
          borderRadius: BorderRadius.circular(30),
          elevation: 2,
          child: InkWell(
            onTap: _showHospitalTourModal,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: buttonPadding,
                vertical: screenHeight * 0.02,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.home,
                        color: Colors.black,
                        size: screenWidth * 0.06,
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Text(
                        'Hospital Tour',
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

  // List of random YouTube video IDs for hospital tours
  final List<String> _hospitalTourVideos = [
    'dQw4w9WgXcQ', // Replace with actual hospital tour video IDs
    'kJQP7kiw5Fk', // Replace with actual hospital tour video IDs
    '9bZkp7q19f0', // Replace with actual hospital tour video IDs
    'hTWKbfoikeg', // Replace with actual hospital tour video IDs
  ];

  void _showHospitalTourModal() {
    // Get a random video ID
    final random = Random();
    final videoId =
        _hospitalTourVideos[random.nextInt(_hospitalTourVideos.length)];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return _HospitalTourModal(videoId: videoId);
      },
    );
  }

  Widget _buildQuickAccessIcon(
    IconData icon,
    String label,
    Color backgroundColor,
    Color? iconColor,
    double iconSize,
    double screenWidth,
  ) {
    return InkWell(
      onTap: () {
        if (label == 'Your Profile') {
          // Navigate to profile edit page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PatientProfileEditPage(phoneNumber: widget.phoneNumber),
            ),
          ).then((_) {
            // Reload user data when returning from profile edit
            _loadUserData();
          });
        } else if (label == 'Settings') {
          // Navigate to settings page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SettingsPage(phoneNumber: widget.phoneNumber),
            ),
          );
        } else if (label == 'Activities') {
          // Navigate to activities page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ActivitiesPage(phoneNumber: widget.phoneNumber),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label feature coming soon!'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
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

  Widget _buildFeatureCard(
    IconData icon,
    String title,
    Color backgroundColor,
    Color? iconColor,
    double cardHeight,
    double screenWidth,
    double borderRadius, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap:
          onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title feature coming soon!'),
                backgroundColor: iconColor,
                duration: const Duration(seconds: 2),
              ),
            );
          },
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              backgroundColor,
              iconColor?.withOpacity(0.3) ?? backgroundColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: screenWidth * 0.12),
            SizedBox(height: screenWidth * 0.03),
            Text(
              title,
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
}

// Separate StatefulWidget for Hospital Tour Modal to properly manage YouTube controller
class _HospitalTourModal extends StatefulWidget {
  final String videoId;

  const _HospitalTourModal({required this.videoId});

  @override
  State<_HospitalTourModal> createState() => _HospitalTourModalState();
}

class _HospitalTourModalState extends State<_HospitalTourModal> {
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
                      'Hospital Tour',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.pop(context);
                      },
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
                        // YouTube Video Player
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: YoutubePlayer(
                            controller: _ytController,
                            showVideoProgressIndicator: true,
                            progressIndicatorColor: Colors.blue,
                            onReady: () {
                              // Video is ready to play
                            },
                            onEnded: (metadata) {
                              // Video has ended
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Description
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
                                'Welcome to our Hospital Tour',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Take a virtual tour of our facilities and learn more about our services, departments, and state-of-the-art medical equipment.',
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
