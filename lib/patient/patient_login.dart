import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
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
  bool _isSendingOTP = false;

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

  String _generateOTP() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<void> _sendOTP() async {
    if (_isValidNumber && !_isSendingOTP) {
      setState(() {
        _isSendingOTP = true;
      });

      try {
        // Generate OTP
        final otp = _generateOTP();

        // Show loading dialog
        if (mounted) {
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
                        Text('Generating OTP...'),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }

        // Simulate network delay
        await Future.delayed(const Duration(seconds: 1));

        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP generated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Navigate to OTP page with the generated OTP and phone number
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientOtpPage(
                phoneNumber: _mobileController.text,
                generatedOTP: otp,
              ),
            ),
          );
        }
      } catch (e) {
        // Close loading dialog if open
        if (mounted) {
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSendingOTP = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          // Custom AppBar
          const CustomAppBar(title: '', showBackButton: true),

          // Content area with responsive horizontal padding
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth > 600 ? 32 : 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: screenHeight - 200),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),

                      // Welcome text
                      const Text(
                        'Patient Portal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const SizedBox(height: 50),

                      // Logo image - responsive sizing
                      Center(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Image.asset(
                              'assets/images/CarePeople.png',
                              height: screenHeight * 0.25,
                              width: constraints.maxWidth * 0.8,
                              fit: BoxFit.contain,
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Mobile number input field - centered with max width
                      Center(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: screenWidth > 600 ? 400 : double.infinity,
                          ),
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
                                borderSide: const BorderSide(
                                  color: Colors.green,
                                  width: 2,
                                ),
                              ),
                              counterText: '${_mobileController.text.length}/11',
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Send OTP button - centered with max width
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: screenWidth > 600 ? 400 : double.infinity,
                            minHeight: 60,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isValidNumber && !_isSendingOTP
                                  ? _sendOTP
                                  : null,
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
                              child: _isSendingOTP
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
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
                                            fontSize: 18,
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
