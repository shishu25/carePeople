import 'package:flutter/material.dart';
import '../mixed/appbar.dart';
import '../services/user_storage_service.dart';
import 'patient_login.dart';

class PatientDashboard extends StatefulWidget {
  final String phoneNumber;

  const PatientDashboard({
    super.key,
    required this.phoneNumber,
  });

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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    // Navigate back to login page and clear navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const PatientLoginPage(),
      ),
      (route) => false, // Remove all previous routes
    );

    // Show logout success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged out successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          CustomAppBar(
            title: 'Dashboard',
            showBackButton: false,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: _showLogoutDialog,
                tooltip: 'Logout',
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth > 600 ? 32 : 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 30),

                          // Welcome message
                          Text(
                            'Welcome, ${_userData?['name'] ?? 'Patient'}!',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Profile Card
                          Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    screenWidth > 600 ? 600 : double.infinity,
                              ),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.person,
                                            color: Colors.green,
                                            size: 28,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Your Profile',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 24),
                                      const Divider(),
                                      const SizedBox(height: 16),

                                      // Name
                                      _buildInfoRow(
                                        Icons.person_outline,
                                        'Name',
                                        _userData?['name'] ?? 'N/A',
                                      ),

                                      const SizedBox(height: 16),

                                      // Phone
                                      _buildInfoRow(
                                        Icons.phone,
                                        'Phone Number',
                                        _userData?['phoneNumber'] ?? 'N/A',
                                      ),

                                      const SizedBox(height: 16),

                                      // Date of Birth
                                      _buildInfoRow(
                                        Icons.cake,
                                        'Date of Birth',
                                        _userData?['dateOfBirth'] ?? 'N/A',
                                      ),

                                      const SizedBox(height: 16),

                                      // Gender
                                      _buildInfoRow(
                                        Icons.people,
                                        'Gender',
                                        _userData?['gender'] ?? 'N/A',
                                      ),

                                      const SizedBox(height: 16),

                                      // Address
                                      _buildInfoRow(
                                        Icons.location_on,
                                        'Address',
                                        _userData?['address'] ?? 'N/A',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Action Buttons
                          Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    screenWidth > 600 ? 600 : double.infinity,
                              ),
                              child: Column(
                                children: [
                                  _buildActionCard(
                                    context,
                                    Icons.calendar_today,
                                    'Appointments',
                                    'View and manage your appointments',
                                    Colors.blue,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildActionCard(
                                    context,
                                    Icons.medical_services,
                                    'Medical Records',
                                    'Access your medical history',
                                    Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildActionCard(
                                    context,
                                    Icons.medication,
                                    'Prescriptions',
                                    'View your prescriptions',
                                    Colors.orange,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.green,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title feature coming soon!'),
              backgroundColor: color,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
