import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../mixed/appbar.dart';
import '../services/prescription_service.dart';

class PrescriptionsListPage extends StatefulWidget {
  final String phoneNumber;

  const PrescriptionsListPage({super.key, required this.phoneNumber});

  @override
  State<PrescriptionsListPage> createState() => _PrescriptionsListPageState();
}

class _PrescriptionsListPageState extends State<PrescriptionsListPage> {
  List<Prescription> _prescriptions = [];
  bool _isLoading = true;

  static const _purple = Color(0xFF6A1B9A);
  static const _green = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final list = await PrescriptionService.getPatientPrescriptions(
      widget.phoneNumber,
    );
    setState(() {
      _prescriptions = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const CustomAppBar(title: 'My Prescriptions', showBackButton: true),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _prescriptions.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      itemCount: _prescriptions.length,
                      itemBuilder: (context, i) =>
                          _buildCard(_prescriptions[i], screenWidth),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Prescriptions Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your prescriptions will appear here\nafter a doctor generates one for you.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ── Prescription card — clean summary + one PDF button ──────────────────
  Widget _buildCard(Prescription rx, double screenWidth) {
    final issuedDate = DateFormat(
      'MMM dd, yyyy',
    ).format(DateTime.parse(rx.issuedAt));
    final apptDate = _fmtDate(rx.appointmentDate);

    return Card(
      margin: EdgeInsets.only(bottom: screenWidth * 0.04),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient header ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: 14,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_purple, _green],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit_document, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rx.doctorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        rx.doctorDepartment,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      issuedDate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Appt: $apptDate',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Open PDF button ────────────────────────────────────────
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openPdf(rx),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Open Prescription PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Open PDF ─────────────────────────────────────────────────────────────
  Future<void> _openPdf(Prescription rx) async {
    final file = File(rx.pdfPath);
    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF not found. It may have been deleted.'),
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

  String _fmtDate(String d) {
    try {
      return DateFormat(
        'MMM dd, yyyy',
      ).format(DateFormat('yyyy-MM-dd').parse(d));
    } catch (_) {
      return d;
    }
  }
}
