import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../mixed/appbar.dart';
import '../models/appointment_models.dart';
import '../services/appointment_service.dart';
import '../services/prescription_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Patient Records — shows unique patients + their prescriptions
// ─────────────────────────────────────────────────────────────────────────────

class PatientRecordsPage extends StatefulWidget {
  final String doctorId;
  final String doctorName;

  const PatientRecordsPage({
    super.key,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  State<PatientRecordsPage> createState() => _PatientRecordsPageState();
}

class _PatientRecordsPageState extends State<PatientRecordsPage> {
  static const _purple = Color(0xFF6A1B9A);
  static const _green = Color(0xFF2E7D32);

  bool _loading = true;
  // keyed by patientPhone
  Map<String, _PatientRecord> _records = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    // Load all appointments and prescriptions for this doctor in parallel
    final apptsFuture = AppointmentService.getDoctorAppointments(
      widget.doctorId,
    );
    final rxFuture = PrescriptionService.getDoctorPrescriptions(
      widget.doctorId,
    );

    final results = await Future.wait([apptsFuture, rxFuture]);
    final appointments = results[0] as List<Appointment>;
    final prescriptions = results[1] as List<Prescription>;

    // Build per-patient records
    final map = <String, _PatientRecord>{};

    for (final appt in appointments) {
      map
          .putIfAbsent(
            appt.patientPhone,
            () => _PatientRecord(
              phone: appt.patientPhone,
              name: appt.patientName,
            ),
          )
          .appointments
          .add(appt);
    }

    for (final rx in prescriptions) {
      map
          .putIfAbsent(
            rx.patientPhone,
            () => _PatientRecord(phone: rx.patientPhone, name: rx.patientName),
          )
          .prescriptions
          .add(rx);
    }

    // Sort appointments / prescriptions within each record
    for (final record in map.values) {
      record.appointments.sort((a, b) => b.date.compareTo(a.date));
      record.prescriptions.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    }

    setState(() {
      _records = map;
      _loading = false;
    });
  }

  List<_PatientRecord> get _filtered {
    final q = _searchQuery.toLowerCase();
    return _records.values
        .where(
          (r) =>
              q.isEmpty ||
              r.name.toLowerCase().contains(q) ||
              r.phone.contains(q),
        )
        .toList()
      ..sort((a, b) {
        // Most-recent-activity date for record a
        String latestA = '';
        if (a.appointments.isNotEmpty) latestA = a.appointments.first.date;
        if (a.prescriptions.isNotEmpty) {
          final rxDate = a.prescriptions.first.issuedAt.substring(0, 10);
          if (rxDate.compareTo(latestA) > 0) latestA = rxDate;
        }
        // Most-recent-activity date for record b
        String latestB = '';
        if (b.appointments.isNotEmpty) latestB = b.appointments.first.date;
        if (b.prescriptions.isNotEmpty) {
          final rxDate = b.prescriptions.first.issuedAt.substring(0, 10);
          if (rxDate.compareTo(latestB) > 0) latestB = rxDate;
        }
        return latestB.compareTo(latestA); // newest first
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          CustomAppBar(
            title: 'Patient Records',
            subtitle: widget.doctorName,
            showBackButton: true,
            gradientColors: const [_purple, _green],
          ),
          if (!_loading) _buildSearchBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by name or phone…',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _buildBody() {
    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No patient records yet'
                  : 'No matching patients',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Patients will appear here once they book appointments or receive prescriptions.'
                  : 'Try a different search term.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        itemCount: list.length,
        itemBuilder: (context, i) => _buildPatientCard(list[i]),
      ),
    );
  }

  Widget _buildPatientCard(_PatientRecord record) {
    final initials = _initials(record.name);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.purple[100],
            child: Text(
              initials,
              style: const TextStyle(
                color: _purple,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          title: Text(
            record.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    record.phone,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  _statChip(
                    '${record.appointments.length} Appts',
                    Colors.blue[50]!,
                    Colors.blue[700]!,
                  ),
                  const SizedBox(width: 6),
                  _statChip(
                    '${record.prescriptions.length} Rx',
                    Colors.purple[50]!,
                    Colors.purple[700]!,
                  ),
                ],
              ),
            ],
          ),
          childrenPadding: EdgeInsets.fromLTRB(
            MediaQuery.of(context).size.width * 0.04,
            0,
            MediaQuery.of(context).size.width * 0.04,
            16,
          ),
          children: [
            // ── Appointments section ──────────────────────────────
            if (record.appointments.isNotEmpty) ...[
              _subSectionHeader(
                Icons.event_note_outlined,
                'Appointments',
                Colors.blue[700]!,
              ),
              ...record.appointments.map((appt) => _appointmentTile(appt)),
            ],

            // ── Prescriptions section ─────────────────────────────
            if (record.prescriptions.isNotEmpty) ...[
              const SizedBox(height: 8),
              _subSectionHeader(
                Icons.description_outlined,
                'Prescriptions',
                _purple,
              ),
              ...record.prescriptions.map((rx) => _prescriptionTile(rx)),
            ],

            if (record.appointments.isEmpty && record.prescriptions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'No records found.',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _appointmentTile(Appointment appt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(appt.date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${appt.timeSlot}  •  Serial #${appt.serialNumber}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Text(
              appt.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _prescriptionTile(Prescription rx) {
    final issued = DateFormat(
      'MMM dd, yyyy',
    ).format(DateTime.parse(rx.issuedAt));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 18, color: _purple),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rx: ${rx.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: _purple,
                  ),
                ),
                Text(
                  'Issued: $issued  •  ${rx.medicines.length} medicine(s)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (rx.diagnosis.isNotEmpty)
                  Text(
                    rx.diagnosis.take(2).join(', ') +
                        (rx.diagnosis.length > 2 ? '…' : ''),
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _openPdfButton(rx),
        ],
      ),
    );
  }

  Widget _openPdfButton(Prescription rx) {
    return InkWell(
      onTap: () => _openPdf(rx),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _purple,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
      ),
    );
  }

  Future<void> _openPdf(Prescription rx) async {
    final file = File(rx.pdfPath);
    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF file not found. It may have been deleted.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final result = await OpenFile.open(rx.pdfPath);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open PDF: ${result.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _subSectionHeader(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatDate(String dateStr) {
    try {
      return DateFormat(
        'MMM dd, yyyy',
      ).format(DateFormat('yyyy-MM-dd').parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Internal view model
// ─────────────────────────────────────────────────────────────────────────────

class _PatientRecord {
  final String phone;
  final String name;
  final List<Appointment> appointments = [];
  final List<Prescription> prescriptions = [];

  _PatientRecord({required this.phone, required this.name});
}
