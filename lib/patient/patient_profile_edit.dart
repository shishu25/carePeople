import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../mixed/appbar.dart';
import '../services/user_storage_service.dart';

class PatientProfileEditPage extends StatefulWidget {
  final String phoneNumber;

  const PatientProfileEditPage({super.key, required this.phoneNumber});

  @override
  State<PatientProfileEditPage> createState() => _PatientProfileEditPageState();
}

class _PatientProfileEditPageState extends State<PatientProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _selectedGender = 'Male';
  bool _isSaving = false;
  bool _isLoading = true;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await UserStorageService.getUserData(widget.phoneNumber);
    if (userData != null && mounted) {
      setState(() {
        _nameController.text = userData['name'] ?? '';
        _dobController.text = userData['dateOfBirth'] ?? '';
        _addressController.text = userData['address'] ?? '';
        _selectedGender = userData['gender'] ?? 'Male';

        // Parse date if available
        if (userData['dateOfBirth'] != null &&
            userData['dateOfBirth'].isNotEmpty) {
          try {
            _selectedDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(userData['dateOfBirth']);
          } catch (e) {
            // If parsing fails, leave _selectedDate as null
          }
        }

        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ??
          DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _updateUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final success = await UserStorageService.saveUser(
          phoneNumber: widget.phoneNumber,
          name: _nameController.text.trim(),
          dateOfBirth: _dobController.text,
          address: _addressController.text.trim(),
          gender: _selectedGender,
        );

        if (mounted) {
          setState(() {
            _isSaving = false;
          });

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );

            // Go back to dashboard after a short delay
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              Navigator.pop(context);
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update profile. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const CustomAppBar(title: 'Edit Profile', showBackButton: true),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth > 600 ? 32 : 16,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 30),

                            // Title
                            const Text(
                              'Update Your Profile',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'Edit your information below',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Name field
                            Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: screenWidth > 600
                                      ? 400
                                      : double.infinity,
                                ),
                                child: TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name *',
                                    hintText: 'Enter your full name',
                                    prefixIcon: const Icon(Icons.person),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.blue,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    if (value.trim().length < 3) {
                                      return 'Name must be at least 3 characters';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Phone number field (not editable)
                            Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: screenWidth > 600
                                      ? 400
                                      : double.infinity,
                                ),
                                child: TextFormField(
                                  initialValue: widget.phoneNumber,
                                  enabled: false,
                                  decoration: InputDecoration(
                                    labelText: 'Phone Number',
                                    prefixIcon: const Icon(Icons.phone),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Date of Birth field
                            Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: screenWidth > 600
                                      ? 400
                                      : double.infinity,
                                ),
                                child: TextFormField(
                                  controller: _dobController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Date of Birth *',
                                    hintText: 'Select your date of birth',
                                    prefixIcon: const Icon(
                                      Icons.calendar_today,
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.arrow_drop_down,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.blue,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  onTap: () => _selectDate(context),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select your date of birth';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Address field
                            Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: screenWidth > 600
                                      ? 400
                                      : double.infinity,
                                ),
                                child: TextFormField(
                                  controller: _addressController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    labelText: 'Address *',
                                    hintText: 'Enter your address',
                                    prefixIcon: const Icon(Icons.location_on),
                                    alignLabelWithHint: true,
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.blue,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your address';
                                    }
                                    if (value.trim().length < 10) {
                                      return 'Address must be at least 10 characters';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Gender field with radio buttons
                            Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: screenWidth > 600
                                      ? 400
                                      : double.infinity,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey[400]!,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.people,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Gender *',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: RadioListTile<String>(
                                              title: const Text('Male'),
                                              value: 'Male',
                                              groupValue: _selectedGender,
                                              activeColor: Colors.blue,
                                              contentPadding: EdgeInsets.zero,
                                              onChanged: (value) {
                                                setState(() {
                                                  _selectedGender = value!;
                                                });
                                              },
                                            ),
                                          ),
                                          Expanded(
                                            child: RadioListTile<String>(
                                              title: const Text('Female'),
                                              value: 'Female',
                                              groupValue: _selectedGender,
                                              activeColor: Colors.blue,
                                              contentPadding: EdgeInsets.zero,
                                              onChanged: (value) {
                                                setState(() {
                                                  _selectedGender = value!;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      RadioListTile<String>(
                                        title: const Text('Other'),
                                        value: 'Other',
                                        groupValue: _selectedGender,
                                        activeColor: Colors.blue,
                                        contentPadding: EdgeInsets.zero,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedGender = value!;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Update button
                            Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: screenWidth > 600
                                      ? 400
                                      : double.infinity,
                                  minHeight: 60,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _updateUser,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                      disabledBackgroundColor: Colors.grey[300],
                                    ),
                                    child: _isSaving
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
                                              Icon(Icons.update, size: 24),
                                              SizedBox(width: 12),
                                              Text(
                                                'Update Profile',
                                                style: TextStyle(
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
