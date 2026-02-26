import 'package:flutter/material.dart';
import '../mixed/appbar.dart';

class PatientOtpPage extends StatelessWidget {
  const PatientOtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Column(
        children: [
          // Custom AppBar
          const CustomAppBar(
            title: 'Verify OTP',
            showBackButton: true,
          ),

          // Content area with 16px horizontal padding
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: screenHeight - 200),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // Success icon
                      Icon(
                        Icons.mark_email_read,
                        size: 100,
                        color: Colors.green[400],
                      ),

                      const SizedBox(height: 30),

                      // Title
                      const Text(
                        'OTP Sent Successfully!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Message
                      Text(
                        'A verification code has been sent to your mobile number',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),

                      const SizedBox(height: 50),

                      // Placeholder for OTP input (can be implemented later)
                      Text(
                        'OTP verification page\n(To be implemented)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
