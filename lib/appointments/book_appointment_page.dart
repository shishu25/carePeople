import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_models.dart';
import '../services/appointment_service.dart';
import '../services/user_storage_service.dart';
import '../mixed/appbar.dart';
import 'doctor_profile_page.dart';

class BookAppointmentPage extends StatefulWidget {
  final String phoneNumber;

  const BookAppointmentPage({super.key, required this.phoneNumber});

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  List<Doctor> _allDoctors = [];
  List<Doctor> _filteredDoctors = [];
  Doctor? _selectedDoctor;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  int? _generatedSerial;
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedDepartment = 'All';
  Map<String, dynamic>? _userData;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final doctors = await AppointmentService.loadDoctors();
    final userData = await UserStorageService.getUserData(widget.phoneNumber);
    setState(() {
      _allDoctors = doctors;
      _filteredDoctors = doctors;
      _userData = userData;
      _isLoading = false;
    });
  }

  List<String> _getDepartments() {
    final departments = _allDoctors.map((d) => d.department).toSet().toList()
      ..sort();
    return ['All', ...departments];
  }

  void _filterDoctors() {
    setState(() {
      _filteredDoctors = _allDoctors.where((doctor) {
        final matchesDepartment =
            _selectedDepartment == 'All' ||
            doctor.department == _selectedDepartment;
        final matchesSearch =
            _searchQuery.isEmpty ||
            doctor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            doctor.department.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
        return matchesDepartment && matchesSearch;
      }).toList();
    });
  }

  DateTime _getNextAvailableDate() {
    if (_selectedDoctor == null)
      return DateTime.now().add(const Duration(days: 1));

    DateTime currentDate = DateTime.now();
    for (int i = 1; i <= 30; i++) {
      final nextDate = currentDate.add(Duration(days: i));
      final dayName = DateFormat('EEEE').format(nextDate);
      if (_selectedDoctor!.consultationDays.contains(dayName)) {
        return nextDate;
      }
    }
    return currentDate.add(const Duration(days: 1));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const CustomAppBar(title: 'Book Appointment', showBackButton: true),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSearchSection(screenWidth),
                        SizedBox(height: screenWidth * 0.04),
                        if (_selectedDoctor == null) ...[
                          _buildDoctorsList(screenWidth, screenHeight),
                        ] else ...[
                          _buildBookingSection(screenWidth, screenHeight),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by doctor name or department...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
            _filterDoctors();
          },
        ),
        SizedBox(height: screenWidth * 0.03),
        // Department Filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _getDepartments().map((dept) {
              final isSelected = _selectedDepartment == dept;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(dept),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedDepartment = dept);
                    _filterDoctors();
                  },
                  backgroundColor: Colors.white,
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorsList(double screenWidth, double screenHeight) {
    if (_filteredDoctors.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.08),
          child: Text(
            'No doctors found',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: screenWidth * 0.04,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _filteredDoctors.map((doctor) {
        return Card(
          margin: EdgeInsets.only(bottom: screenHeight * 0.015),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: screenWidth * 0.075,
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        doctor.name.substring(4, 5),
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctor.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth * 0.04,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.005),
                          Text(
                            doctor.designation,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: screenWidth * 0.033,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.003),
                          Text(
                            doctor.degrees,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: screenWidth * 0.028,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.015),
                Row(
                  children: [
                    Icon(
                      Icons.local_hospital,
                      size: screenWidth * 0.035,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    Flexible(
                      child: Text(
                        doctor.department,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: screenWidth * 0.033,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Icon(
                      Icons.payments,
                      size: screenWidth * 0.035,
                      color: Colors.green[600],
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    Text(
                      '৳${doctor.consultationFee.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: screenWidth * 0.033,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.015),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DoctorProfilePage(doctor: doctor),
                            ),
                          );
                        },
                        icon: Icon(Icons.person, size: screenWidth * 0.04),
                        label: Text(
                          'View Profile',
                          style: TextStyle(fontSize: screenWidth * 0.03),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.012,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.02,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedDoctor = doctor;
                            _selectedDate = null;
                            _selectedTimeSlot = null;
                            _generatedSerial = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.012,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.02,
                            ),
                          ),
                        ),
                        child: Text(
                          'Select',
                          style: TextStyle(fontSize: screenWidth * 0.03),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBookingSection(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selected Doctor Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selected Doctor',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.045,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedDoctor = null;
                          _selectedDate = null;
                          _selectedTimeSlot = null;
                          _generatedSerial = null;
                        });
                      },
                      child: Text(
                        'Change',
                        style: TextStyle(fontSize: screenWidth * 0.035),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Text(
                  _selectedDoctor!.name,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  '${_selectedDoctor!.designation} - ${_selectedDoctor!.department}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: screenWidth * 0.035,
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  'Consultation Fee: ৳${_selectedDoctor!.consultationFee.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: screenWidth * 0.04),

        // Date Selection
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Date',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.04,
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _getNextAvailableDate(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                      selectableDayPredicate: (DateTime date) {
                        // Only allow dates that match doctor's consultation days
                        final dayName = DateFormat('EEEE').format(date);
                        return _selectedDoctor!.consultationDays.contains(
                          dayName,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                        _selectedTimeSlot = null;
                        _generatedSerial = null;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            _selectedDate == null
                                ? 'Choose a date'
                                : DateFormat(
                                    'EEEE, MMM dd, yyyy',
                                  ).format(_selectedDate!),
                            style: TextStyle(
                              fontSize: screenWidth * 0.037,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today,
                          color: Colors.blue,
                          size: screenWidth * 0.05,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_selectedDate != null) ...[
          SizedBox(height: screenWidth * 0.04),
          _buildTimeSlotSelection(screenWidth, screenHeight),
        ],

        if (_generatedSerial != null) ...[
          SizedBox(height: screenWidth * 0.04),
          _buildConfirmationCard(screenWidth, screenHeight),
        ],
      ],
    );
  }

  Widget _buildTimeSlotSelection(double screenWidth, double screenHeight) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Time Slot',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.04,
              ),
            ),
            SizedBox(height: screenHeight * 0.015),
            FutureBuilder<List<String>>(
              future: AppointmentService.getBookedTimeSlotsForDate(
                _selectedDoctor!.id,
                DateFormat('yyyy-MM-dd').format(_selectedDate!),
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final bookedSlots = snapshot.data!;
                final allSlots = AppointmentService.generateTimeSlots();

                return Wrap(
                  spacing: screenWidth * 0.02,
                  runSpacing: screenHeight * 0.01,
                  children: allSlots.map((slot) {
                    final isBooked = bookedSlots.contains(slot);
                    final isSelected = _selectedTimeSlot == slot;

                    return ChoiceChip(
                      label: Text(
                        slot,
                        style: TextStyle(fontSize: screenWidth * 0.032),
                      ),
                      selected: isSelected,
                      onSelected: isBooked
                          ? null
                          : (selected) async {
                              if (selected) {
                                setState(() => _selectedTimeSlot = slot);
                                // Generate serial number
                                final serial =
                                    await AppointmentService.getNextSerialNumber(
                                      _selectedDoctor!.id,
                                      DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(_selectedDate!),
                                    );
                                setState(() => _generatedSerial = serial);
                              }
                            },
                      backgroundColor: isBooked
                          ? Colors.grey[300]
                          : Colors.white,
                      selectedColor: Colors.blue,
                      labelStyle: TextStyle(
                        color: isBooked
                            ? Colors.grey[500]
                            : (isSelected ? Colors.white : Colors.black),
                        fontWeight: FontWeight.w500,
                        fontSize: screenWidth * 0.032,
                      ),
                      side: BorderSide(
                        color: isBooked
                            ? Colors.grey[400]!
                            : (isSelected ? Colors.blue : Colors.grey[300]!),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationCard(double screenWidth, double screenHeight) {
    return Card(
      color: Colors.green[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        side: BorderSide(color: Colors.green[300]!),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.confirmation_number,
                  color: Colors.green[700],
                  size: screenWidth * 0.08,
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Serial Number',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '#$_generatedSerial',
                        style: TextStyle(
                          fontSize: screenWidth * 0.08,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
            const Divider(),
            SizedBox(height: screenHeight * 0.015),
            _buildInfoRow('Doctor', _selectedDoctor!.name, screenWidth),
            _buildInfoRow(
              'Date',
              DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate!),
              screenWidth,
            ),
            _buildInfoRow('Time', _selectedTimeSlot!, screenWidth),
            _buildInfoRow('Room', _selectedDoctor!.roomNumber, screenWidth),
            _buildInfoRow(
              'Fee',
              '৳${_selectedDoctor!.consultationFee.toStringAsFixed(0)}',
              screenWidth,
            ),
            SizedBox(height: screenHeight * 0.02),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                ),
                child: Text(
                  'Confirm Appointment',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: Colors.grey[700],
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: screenWidth * 0.035,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAppointment() async {
    if (_selectedDoctor == null ||
        _selectedDate == null ||
        _selectedTimeSlot == null ||
        _generatedSerial == null) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final appointment = Appointment(
      doctorId: _selectedDoctor!.id,
      doctorName: _selectedDoctor!.name,
      patientPhone: widget.phoneNumber,
      patientName: _userData?['name'] ?? 'Patient',
      date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      timeSlot: _selectedTimeSlot!,
      serialNumber: _generatedSerial!,
    );

    final success = await AppointmentService.saveAppointment(appointment);

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      if (success) {
        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Appointment confirmed successfully!')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back to dashboard
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to book appointment. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
