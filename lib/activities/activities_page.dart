import 'package:flutter/material.dart';
import '../mixed/appbar.dart';
import '../appointments/appointments_list_page.dart';

class ActivitiesPage extends StatelessWidget {
  final String phoneNumber;

  const ActivitiesPage({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const CustomAppBar(
            title: 'Activities',
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(screenWidth * 0.05),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[600]!, Colors.blue[400]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.trending_up,
                            color: Colors.white,
                            size: 40,
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          const Text(
                            'Your Activities',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.005),
                          const Text(
                            'Track and manage your healthcare activities',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Activity Options Grid
                  _buildActivityCard(
                    context,
                    icon: Icons.calendar_month,
                    title: 'Appointments',
                    description: 'View and manage your appointments',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppointmentsListPage(
                            phoneNumber: phoneNumber,
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  _buildActivityCard(
                    context,
                    icon: Icons.medical_services,
                    title: 'Medical Records',
                    description: 'Access your health records',
                    color: Colors.purple,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Medical Records feature coming soon!'),
                          backgroundColor: Colors.purple,
                        ),
                      );
                    },
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  _buildActivityCard(
                    context,
                    icon: Icons.medication,
                    title: 'Prescriptions',
                    description: 'View your prescriptions and medications',
                    color: Colors.orange,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Prescriptions feature coming soon!'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  _buildActivityCard(
                    context,
                    icon: Icons.science,
                    title: 'Lab Reports',
                    description: 'Check your test results and lab reports',
                    color: Colors.teal,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lab Reports feature coming soon!'),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    },
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  _buildActivityCard(
                    context,
                    icon: Icons.payment,
                    title: 'Billing & Payments',
                    description: 'View bills and payment history',
                    color: Colors.blue,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Billing feature coming soon!'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
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
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
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
                size: 20,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
