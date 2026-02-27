import 'package:flutter/material.dart';
import '../models/appointment_models.dart';
import '../mixed/appbar.dart';

class DoctorProfilePage extends StatelessWidget {
  final Doctor doctor;

  const DoctorProfilePage({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const CustomAppBar(title: 'Doctor Profile', showBackButton: true),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header Section with Doctor's Basic Info
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[700]!, Colors.blue[500]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: EdgeInsets.all(screenWidth * 0.06),
                    child: Column(
                      children: [
                        // Doctor Avatar
                        Container(
                          width: screenWidth * 0.3,
                          height: screenWidth * 0.3,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              doctor.name.split(' ')[1][0],
                              style: TextStyle(
                                fontSize: screenWidth * 0.12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        // Doctor Name
                        Text(
                          doctor.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        // Designation
                        Text(
                          doctor.designation,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Details Section
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      children: [
                        // Consultation Fee Card (Prominent)
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: Colors.green[50],
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(screenWidth * 0.05),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.payments,
                                  size: screenWidth * 0.12,
                                  color: Colors.green[700],
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                const Text(
                                  'Consultation Fee',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                Text(
                                  '৳${doctor.consultationFee.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.02),

                        // Department Card
                        _buildInfoCard(
                          icon: Icons.local_hospital,
                          title: 'Department',
                          value: doctor.department,
                          color: Colors.blue,
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        // Degrees Card
                        _buildInfoCard(
                          icon: Icons.school,
                          title: 'Qualifications',
                          value: doctor.degrees,
                          color: Colors.purple,
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        // Specialization Description
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth * 0.04),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.orange[700],
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'About',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _getDoctorDescription(doctor.department),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        // Experience & Availability Info
                        Row(
                          children: [
                            Expanded(
                              child: _buildSmallInfoCard(
                                icon: Icons.work_outline,
                                title: 'Experience',
                                value: '10+ Years',
                                color: Colors.teal,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: _buildSmallInfoCard(
                                icon: Icons.star,
                                title: 'Rating',
                                value: '4.8/5.0',
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        // Consultation Schedule
                        if (doctor.consultationDays.isNotEmpty)
                          _buildScheduleCard(),

                        SizedBox(height: screenHeight * 0.03),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Consultation Schedule',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Available Days
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Days: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Expanded(
                  child: Text(
                    doctor.consultationDays.join(', '),
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Consultation Times
            if (doctor.consultationTimes.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Timing: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      doctor.consultationTimes,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  String _getDoctorDescription(String department) {
    final descriptions = {
      'Cardiology':
          'Specializes in diagnosing and treating heart conditions, cardiovascular diseases, and related disorders. Expert in cardiac care and preventive cardiology.',
      'Neurology':
          'Expert in treating disorders of the nervous system, including brain, spinal cord, and nerve-related conditions.',
      'Pediatrics':
          'Dedicated to the health and medical care of infants, children, and adolescents. Provides comprehensive pediatric care.',
      'Orthopedics':
          'Specializes in the diagnosis, treatment, and prevention of disorders of the bones, joints, ligaments, tendons, and muscles.',
      'Dermatology':
          'Expert in diagnosing and treating skin, hair, and nail conditions. Provides both medical and cosmetic dermatology services.',
      'General Surgery':
          'Performs a wide range of surgical procedures with expertise in abdominal surgery and trauma care.',
      'Gynecology':
          'Specializes in women\'s reproductive health, pregnancy care, and gynecological conditions.',
      'Ophthalmology':
          'Expert in eye care, treating vision problems, eye diseases, and performing eye surgeries.',
      'Psychiatry':
          'Specializes in mental health disorders, providing diagnosis, treatment, and counseling services.',
      'Endocrinology':
          'Expert in hormone-related disorders, diabetes management, and metabolic conditions.',
      'Urology':
          'Specializes in urinary tract and male reproductive system disorders.',
      'ENT':
          'Expert in treating ear, nose, and throat conditions, including hearing and balance disorders.',
      'Gastroenterology':
          'Specializes in digestive system disorders, liver diseases, and gastrointestinal conditions.',
      'Rheumatology':
          'Expert in autoimmune diseases, arthritis, and musculoskeletal disorders.',
      'Pulmonology':
          'Specializes in respiratory system disorders and lung diseases.',
      'Nephrology': 'Expert in kidney diseases, dialysis, and renal care.',
      'Oncology':
          'Specializes in cancer diagnosis, treatment, and patient care with comprehensive oncology services.',
    };

    return descriptions[department] ??
        'Highly qualified medical professional dedicated to providing excellent patient care and treatment.';
  }
}
