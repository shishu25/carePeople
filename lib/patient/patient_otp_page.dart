import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../mixed/appbar.dart';
import '../services/user_storage_service.dart';
import 'patient_signup.dart';
import 'patient_dashboard.dart';

class PatientOtpPage extends StatefulWidget {
  final String phoneNumber;
  final String generatedOTP;

  const PatientOtpPage({
    super.key,
    required this.phoneNumber,
    required this.generatedOTP,
  });

  @override
  State<PatientOtpPage> createState() => _PatientOtpPageState();
}

class _PatientOtpPageState extends State<PatientOtpPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isVerifying = false;

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _getEnteredOTP() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  String _generateOTP() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  bool _checkOTP(String enteredOTP, String sentOTP) {
    return enteredOTP.trim() == sentOTP.trim();
  }

  Future<void> _verifyOTP() async {
    final enteredOTP = _getEnteredOTP();

    if (enteredOTP.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete 6-digit OTP'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    // Simulate verification delay
    await Future.delayed(const Duration(milliseconds: 500));

    final isValid = _checkOTP(enteredOTP, widget.generatedOTP);

    setState(() {
      _isVerifying = false;
    });

    if (isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Check if user exists
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          final userExists = await UserStorageService.userExists(
            widget.phoneNumber,
          );

          if (userExists) {
            // User exists, navigate to dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PatientDashboard(phoneNumber: widget.phoneNumber),
              ),
            );
          } else {
            // New user, navigate to signup
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PatientSignupPage(phoneNumber: widget.phoneNumber),
              ),
            );
          }
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );

        // Clear OTP fields
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    }
  }

  Future<void> _resendOTP() async {
    // Generate new OTP
    final newOTP = _generateOTP();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating new OTP...'),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.of(context).pop();

      // Update the generated OTP by navigating to a new page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PatientOtpPage(
            phoneNumber: widget.phoneNumber,
            generatedOTP: newOTP,
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New OTP generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Column(
        children: [
          // Custom AppBar
          const CustomAppBar(title: 'Verify OTP', showBackButton: true),

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

                      // OTP icon
                      Icon(
                        Icons.lock_outline,
                        size: 100,
                        color: Colors.green[400],
                      ),

                      const SizedBox(height: 30),

                      // Title
                      const Text(
                        'Verify OTP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Message
                      Text(
                        'Enter the verification code\nPhone: ${widget.phoneNumber}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),

                      const SizedBox(height: 20),

                      // Testing mode - show OTP
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Testing Mode',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your OTP: ${widget.generatedOTP}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // OTP Input Fields
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (index) {
                          return Container(
                            width: 50,
                            height: 60,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: TextField(
                              controller: _otpControllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.green,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                if (value.length == 1 && index < 5) {
                                  _focusNodes[index + 1].requestFocus();
                                } else if (value.isEmpty && index > 0) {
                                  _focusNodes[index - 1].requestFocus();
                                }

                                // Auto-verify when all 6 digits are entered
                                if (index == 5 && value.length == 1) {
                                  _verifyOTP();
                                }
                              },
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 40),

                      // Verify Button
                      SizedBox(
                        width: double.infinity,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 400,
                            minHeight: 60,
                          ),
                          child: ElevatedButton(
                            onPressed: _isVerifying ? null : _verifyOTP,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                            child: _isVerifying
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, size: 24),
                                      SizedBox(width: 12),
                                      Text(
                                        'Verify OTP',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Resend OTP Button
                      TextButton.icon(
                        onPressed: _resendOTP,
                        icon: const Icon(Icons.refresh),
                        label: const Text(
                          'Resend OTP via WhatsApp',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Debug info (for testing only)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '🔍 Testing Mode',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Generated OTP: ${widget.generatedOTP}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '(This is shown for testing purposes only)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
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
