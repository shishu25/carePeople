import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../mixed/appbar.dart';
import 'patient_otp_page.dart';

class PatientLoginPage extends StatefulWidget {
  const PatientLoginPage({super.key});

  @override
  State<PatientLoginPage> createState() => _PatientLoginPageState();
}

class _PatientLoginPageState extends State<PatientLoginPage> {
  final TextEditingController _mobileController = TextEditingController();
  bool _isValidNumber = false;

  @override
  void initState() {
    super.initState();
    _mobileController.addListener(_validatePhoneNumber);
  }

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  void _validatePhoneNumber() {
    setState(() {
      _isValidNumber = _mobileController.text.length == 11;
    });
  }

  void _sendOTP() {
    if (_isValidNumber) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PatientOtpPage()),
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
          const CustomAppBar(title: 'Patient Login', showBackButton: true),

          // Content area with 16px horizontal padding
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: screenHeight - 200),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),

                      // Welcome text
                      const Text(
                        'Welcome Patient!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Please enter your mobile number to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),

                      const SizedBox(height: 50),

                      // Mobile number icon
                      Icon(
                        Icons.phone_android,
                        size: 80,
                        color: Colors.green[400],
                      ),

                      const SizedBox(height: 40),

                      // Mobile number input field
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: TextField(
                          controller: _mobileController,
                          keyboardType: TextInputType.number,
                          maxLength: 11,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Mobile Number',
                            hintText: 'Enter 11 digit number',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.green,
                                width: 2,
                              ),
                            ),
                            counterText: '${_mobileController.text.length}/11',
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Send OTP button
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 400,
                              minHeight: 60,
                            ),
                            child: ElevatedButton(
                              onPressed: _isValidNumber ? _sendOTP : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isValidNumber
                                    ? Colors.green
                                    : Colors.grey,
                                foregroundColor: Colors.white,
                                elevation: _isValidNumber ? 3 : 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                disabledBackgroundColor: Colors.grey[300],
                                disabledForegroundColor: Colors.grey[500],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isValidNumber
                                        ? Icons.send
                                        : Icons.lock_outline,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _isValidNumber
                                        ? 'Send OTP'
                                        : 'Enter 11 Digits',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
