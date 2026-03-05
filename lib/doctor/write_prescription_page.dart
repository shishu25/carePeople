import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../mixed/appbar.dart';
import '../models/appointment_models.dart';
import '../services/appointment_service.dart';
import '../services/prescription_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Entry point — 3-step stepper page
// ─────────────────────────────────────────────────────────────────────────────

class WritePrescriptionPage extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String doctorDepartment;
  final String doctorDesignation;
  final String doctorDegrees;

  const WritePrescriptionPage({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.doctorDepartment,
    required this.doctorDesignation,
    required this.doctorDegrees,
  });

  @override
  State<WritePrescriptionPage> createState() => _WritePrescriptionPageState();
}

class _WritePrescriptionPageState extends State<WritePrescriptionPage> {
  int _step = 0; // 0 = select patient, 1 = diagnosis+medicines, 2 = review

  // ── Step 0 state ────────────────────────────────────────────────────────
  List<Appointment> _appointments = [];
  bool _loadingAppts = true;
  Appointment? _selectedAppointment;

  // ── Step 1 state ────────────────────────────────────────────────────────
  final _diagnosisController = TextEditingController();
  final List<String> _diagnosisList = [];

  final _medNameCtrl = TextEditingController();
  final _medDosageCtrl = TextEditingController();
  final _medFreqCtrl = TextEditingController();
  final _medDurCtrl = TextEditingController();
  final _medNotesCtrl = TextEditingController();
  final List<PrescribedMedicine> _medicines = [];

  final _notesCtrl = TextEditingController();

  // ── Step 2 state ────────────────────────────────────────────────────────
  bool _generating = false;

  static const _purple = Color(0xFF6A1B9A);
  static const _green = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _medNameCtrl.dispose();
    _medDosageCtrl.dispose();
    _medFreqCtrl.dispose();
    _medDurCtrl.dispose();
    _medNotesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    final appts =
        await AppointmentService.getDoctorAppointments(widget.doctorId);
    // Only upcoming appointments
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = appts.where((a) {
      try {
        final d = DateFormat('yyyy-MM-dd').parse(a.date);
        return d.isAtSameMomentAs(today) || d.isAfter(today);
      } catch (_) {
        return false;
      }
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    setState(() {
      _appointments = upcoming;
      _loadingAppts = false;
    });
  }

  // ── Navigation helpers ──────────────────────────────────────────────────

  void _nextStep() => setState(() => _step++);
  void _prevStep() => setState(() => _step--);

  // ── Diagnosis helpers ───────────────────────────────────────────────────

  void _addDiagnosis() {
    final text = _diagnosisController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _diagnosisList.add(text);
      _diagnosisController.clear();
    });
  }

  void _removeDiagnosis(int index) =>
      setState(() => _diagnosisList.removeAt(index));

  // ── Medicine helpers ────────────────────────────────────────────────────

  void _addMedicine() {
    if (_medNameCtrl.text.trim().isEmpty ||
        _medDosageCtrl.text.trim().isEmpty ||
        _medFreqCtrl.text.trim().isEmpty ||
        _medDurCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill Name, Dosage, Frequency and Duration.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    setState(() {
      _medicines.add(PrescribedMedicine(
        name: _medNameCtrl.text.trim(),
        dosage: _medDosageCtrl.text.trim(),
        frequency: _medFreqCtrl.text.trim(),
        duration: _medDurCtrl.text.trim(),
        notes: _medNotesCtrl.text.trim().isEmpty
            ? null
            : _medNotesCtrl.text.trim(),
      ));
      _medNameCtrl.clear();
      _medDosageCtrl.clear();
      _medFreqCtrl.clear();
      _medDurCtrl.clear();
      _medNotesCtrl.clear();
    });
  }

  void _removeMedicine(int index) =>
      setState(() => _medicines.removeAt(index));

  // ── Generate PDF ────────────────────────────────────────────────────────

  Future<void> _generatePrescription() async {
    if (_selectedAppointment == null) return;
    if (_diagnosisList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please add at least one diagnosis.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please add at least one medicine.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _generating = true);

    try {
      final prescription = await PrescriptionService.createPrescription(
        doctorId: widget.doctorId,
        doctorName: widget.doctorName,
        doctorDepartment: widget.doctorDepartment,
        doctorDesignation: widget.doctorDesignation,
        doctorDegrees: widget.doctorDegrees,
        patientPhone: _selectedAppointment!.patientPhone,
        patientName: _selectedAppointment!.patientName,
        appointmentDate: _selectedAppointment!.date,
        diagnosis: _diagnosisList,
        medicines: _medicines,
        additionalNotes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
      );

      // Remove the appointment now that the prescription has been generated
      await AppointmentService.removeAppointment(
        doctorId: widget.doctorId,
        patientPhone: _selectedAppointment!.patientPhone,
        date: _selectedAppointment!.date,
      );

      if (!mounted) return;
      setState(() => _generating = false);

      await showDialog(
        context: context,
        builder: (_) => _SuccessDialog(
          prescription: prescription,
          doctorName: widget.doctorName,
        ),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _generating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error generating prescription: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          CustomAppBar(
            title: 'Write Prescription',
            showBackButton: true,
            gradientColors: const [_purple, _green],
          ),
          // Stepper indicator
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.04),
              child: _buildCurrentStep(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step indicator ──────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    const labels = ['Select Patient', 'Diagnosis & Medicines', 'Review'];
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
          vertical: 12, horizontal: screenWidth * 0.04),
      child: Row(
        children: List.generate(labels.length, (i) {
          final done = i < _step;
          final active = i == _step;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: done
                          ? _green
                          : active
                              ? _purple
                              : Colors.grey[300],
                      child: done
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 16)
                          : Text('${i + 1}',
                              style: TextStyle(
                                  color:
                                      active ? Colors.white : Colors.grey[600],
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 10,
                        color: active ? _purple : Colors.grey[600],
                        fontWeight: active
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                if (i < labels.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      color: done ? _green : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Step dispatcher ─────────────────────────────────────────────────────

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      default:
        return const SizedBox();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STEP 0 — Select Patient
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildStep0() {
    if (_loadingAppts) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator()));
    }

    if (_appointments.isEmpty) {
      return _emptyState(
        icon: Icons.event_busy,
        title: 'No Upcoming Appointments',
        subtitle:
            'Prescriptions can only be written for patients with upcoming appointments.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.person_search, 'Select a Patient'),
        const SizedBox(height: 12),
        ..._appointments.map((appt) => _buildPatientCard(appt)).toList(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _selectedAppointment == null ? null : _nextStep,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next: Diagnosis & Medicines'),
            style: _primaryBtn(),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientCard(Appointment appt) {
    final isSelected = _selectedAppointment?.patientPhone == appt.patientPhone &&
        _selectedAppointment?.date == appt.date;
    final initials = _initials(appt.patientName);

    return GestureDetector(
      onTap: () => setState(() => _selectedAppointment = appt),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _purple : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: _purple.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  isSelected ? _purple : Colors.purple[100]!,
              child: Text(
                initials,
                style: TextStyle(
                  color: isSelected ? Colors.white : _purple,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appt.patientName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87)),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.phone, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(appt.patientPhone,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[600])),
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.calendar_today,
                        size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(appt.date),
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time,
                        size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(appt.timeSlot,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[600])),
                  ]),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: _purple, size: 26),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STEP 1 — Diagnosis + Medicines
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Patient summary chip
        _selectedPatientChip(),
        const SizedBox(height: 20),

        // ── Diagnosis ─────────────────────────────────────────────────
        _sectionHeader(Icons.medical_information_outlined, 'Diagnosis'),
        const SizedBox(height: 10),
        _diagnosisInputRow(),
        const SizedBox(height: 8),
        if (_diagnosisList.isEmpty)
          _hintText('Add at least one diagnosis item above.')
        else
          ..._diagnosisList.asMap().entries.map((e) => _diagnosisChip(e.key, e.value)),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),

        // ── Medicines ─────────────────────────────────────────────────
        _sectionHeader(Icons.medication_outlined, 'Medicines'),
        const SizedBox(height: 10),
        _medicineInputForm(),
        const SizedBox(height: 8),
        if (_medicines.isEmpty)
          _hintText('Add at least one prescribed medicine above.')
        else
          ..._medicines.asMap().entries.map((e) => _medicineRow(e.key, e.value)),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),

        // ── Additional notes ──────────────────────────────────────────
        _sectionHeader(Icons.notes_outlined, 'Additional Notes (optional)'),
        const SizedBox(height: 10),
        TextField(
          controller: _notesCtrl,
          maxLines: 3,
          decoration: _inputDec('e.g. Avoid spicy food, rest for 3 days…'),
        ),

        const SizedBox(height: 24),

        // ── Navigation ────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _prevStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: _outlinedBtn(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (_diagnosisList.isNotEmpty && _medicines.isNotEmpty)
                    ? _nextStep
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Review'),
                style: _primaryBtn(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _diagnosisInputRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _diagnosisController,
            decoration: _inputDec('Enter diagnosis (e.g. Hypertension)'),
            onSubmitted: (_) => _addDiagnosis(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _addDiagnosis,
          style: ElevatedButton.styleFrom(
            backgroundColor: _purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _diagnosisChip(int index, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: _purple),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 14, color: Colors.black87))),
          InkWell(
            onTap: () => _removeDiagnosis(index),
            child: const Icon(Icons.close, size: 18, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _medicineInputForm() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: _medNameCtrl,
                      decoration: _inputDec('Medicine name *'))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: _medDosageCtrl,
                      decoration: _inputDec('Dosage (e.g. 500mg) *'))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: _medFreqCtrl,
                      decoration:
                          _inputDec('Frequency (e.g. Twice daily) *'))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: _medDurCtrl,
                      decoration: _inputDec('Duration (e.g. 7 days) *'))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: _medNotesCtrl,
                      decoration:
                          _inputDec('Notes (e.g. After meals)'))),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _addMedicine,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _medicineRow(int index, PrescribedMedicine med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: _green,
            child: Text('${index + 1}',
                style:
                    const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87)),
                const SizedBox(height: 2),
                Text(
                  '${med.dosage}  •  ${med.frequency}  •  ${med.duration}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                if (med.notes != null)
                  Text('Note: ${med.notes}',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          InkWell(
            onTap: () => _removeMedicine(index),
            child: const Icon(Icons.delete_outline,
                size: 20, color: Colors.red),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STEP 2 — Review & Generate
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _selectedPatientChip(),
        const SizedBox(height: 20),

        // Diagnosis summary
        _reviewSection(
          icon: Icons.medical_information_outlined,
          title: 'Diagnosis',
          color: _purple,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _diagnosisList
                .map((d) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        const Icon(Icons.circle, size: 7, color: _purple),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(d,
                                style: const TextStyle(fontSize: 14))),
                      ]),
                    ))
                .toList(),
          ),
        ),

        const SizedBox(height: 12),

        // Medicines summary
        _reviewSection(
          icon: Icons.medication_outlined,
          title: 'Medicines (${_medicines.length})',
          color: _green,
          child: Column(
            children: _medicines.asMap().entries.map((e) {
              final m = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                        radius: 11,
                        backgroundColor: _green,
                        child: Text('${e.key + 1}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text(
                              '${m.dosage}  •  ${m.frequency}  •  ${m.duration}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                          if (m.notes != null)
                            Text('Note: ${m.notes}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black45)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        if (_notesCtrl.text.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _reviewSection(
            icon: Icons.notes_outlined,
            title: 'Additional Notes',
            color: Colors.orange[700]!,
            child: Text(_notesCtrl.text.trim(),
                style: const TextStyle(fontSize: 14)),
          ),
        ],

        const SizedBox(height: 24),

        // Doctor info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple[200]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_hospital_outlined, color: _purple),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dr. ${widget.doctorName}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(
                    '${widget.doctorDesignation}  •  ${widget.doctorDepartment}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _generating ? null : _prevStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: _outlinedBtn(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _generating ? null : _generatePrescription,
                icon: _generating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_generating
                    ? 'Generating…'
                    : 'Generate Prescription'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Shared widgets ──────────────────────────────────────────────────────

  Widget _selectedPatientChip() {
    if (_selectedAppointment == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _purple,
            child: Text(
              _initials(_selectedAppointment!.patientName),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_selectedAppointment!.patientName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              Text(
                '${_selectedAppointment!.patientPhone}  •  ${_formatDate(_selectedAppointment!.date)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reviewSection({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: color)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _purple, size: 22),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _purple)),
      ],
    );
  }

  Widget _hintText(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(text,
            style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      );

  Widget _emptyState(
          {required IconData icon,
          required String title,
          required String subtitle}) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 72, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(title,
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500])),
            ],
          ),
        ),
      );

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _purple, width: 1.5),
        ),
      );

  ButtonStyle _primaryBtn() => ElevatedButton.styleFrom(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  ButtonStyle _outlinedBtn() => OutlinedButton.styleFrom(
        foregroundColor: _purple,
        side: const BorderSide(color: _purple),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatDate(String dateStr) {
    try {
      return DateFormat('MMM dd, yyyy')
          .format(DateFormat('yyyy-MM-dd').parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Success dialog shown after generation
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessDialog extends StatelessWidget {
  final Prescription prescription;
  final String doctorName;

  const _SuccessDialog(
      {required this.prescription, required this.doctorName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 36,
            backgroundColor: Color(0xFF2E7D32),
            child: Icon(Icons.check, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Prescription Generated!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'The prescription for ${prescription.patientName} has been saved and added to their patient record.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Rx ID: ${prescription.id}',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700]),
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A1B9A),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
