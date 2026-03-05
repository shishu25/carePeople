import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ─────────────────────────────────────────────────────────────────────────────
//  Data model
// ─────────────────────────────────────────────────────────────────────────────

class PrescribedMedicine {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String? notes;

  PrescribedMedicine({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'dosage': dosage,
    'frequency': frequency,
    'duration': duration,
    if (notes != null) 'notes': notes,
  };

  factory PrescribedMedicine.fromJson(Map<String, dynamic> j) =>
      PrescribedMedicine(
        name: j['name'] as String,
        dosage: j['dosage'] as String,
        frequency: j['frequency'] as String,
        duration: j['duration'] as String,
        notes: j['notes'] as String?,
      );
}

class Prescription {
  final String id; // unique — timestamp-based
  final String doctorId;
  final String doctorName;
  final String doctorDepartment;
  final String doctorDesignation;
  final String doctorDegrees;
  final String patientPhone;
  final String patientName;
  final String appointmentDate;
  final String issuedAt; // ISO-8601
  final List<String> diagnosis;
  final List<PrescribedMedicine> medicines;
  final String? additionalNotes;
  final String pdfPath;

  Prescription({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.doctorDepartment,
    required this.doctorDesignation,
    required this.doctorDegrees,
    required this.patientPhone,
    required this.patientName,
    required this.appointmentDate,
    required this.issuedAt,
    required this.diagnosis,
    required this.medicines,
    this.additionalNotes,
    required this.pdfPath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'doctorId': doctorId,
    'doctorName': doctorName,
    'doctorDepartment': doctorDepartment,
    'doctorDesignation': doctorDesignation,
    'doctorDegrees': doctorDegrees,
    'patientPhone': patientPhone,
    'patientName': patientName,
    'appointmentDate': appointmentDate,
    'issuedAt': issuedAt,
    'diagnosis': diagnosis,
    'medicines': medicines.map((m) => m.toJson()).toList(),
    if (additionalNotes != null) 'additionalNotes': additionalNotes,
    'pdfPath': pdfPath,
  };

  factory Prescription.fromJson(Map<String, dynamic> j) => Prescription(
    id: j['id'] as String,
    doctorId: j['doctorId'] as String,
    doctorName: j['doctorName'] as String,
    doctorDepartment: j['doctorDepartment'] as String? ?? '',
    doctorDesignation: j['doctorDesignation'] as String? ?? '',
    doctorDegrees: j['doctorDegrees'] as String? ?? '',
    patientPhone: j['patientPhone'] as String,
    patientName: j['patientName'] as String,
    appointmentDate: j['appointmentDate'] as String,
    issuedAt: j['issuedAt'] as String,
    diagnosis: List<String>.from(j['diagnosis'] as List),
    medicines: (j['medicines'] as List)
        .map((m) => PrescribedMedicine.fromJson(m as Map<String, dynamic>))
        .toList(),
    additionalNotes: j['additionalNotes'] as String?,
    pdfPath: j['pdfPath'] as String,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Service
// ─────────────────────────────────────────────────────────────────────────────

class PrescriptionService {
  static const String _fileName = 'prescriptions.json';

  // ── Storage helpers ─────────────────────────────────────────────────────

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<List<Prescription>> _loadAll() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];
      final raw = json.decode(await file.readAsString());
      return (raw['prescriptions'] as List)
          .map((e) => Prescription.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveAll(List<Prescription> list) async {
    final file = await _getFile();
    await file.writeAsString(
      json.encode({'prescriptions': list.map((p) => p.toJson()).toList()}),
    );
  }

  // ── Public queries ──────────────────────────────────────────────────────

  /// All prescriptions for a specific patient (newest first).
  static Future<List<Prescription>> getPatientPrescriptions(
    String patientPhone,
  ) async {
    final all = await _loadAll();
    return all.where((p) => p.patientPhone == patientPhone).toList()
      ..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
  }

  /// All patients (unique phones) who have received prescriptions from this doctor.
  static Future<List<Prescription>> getDoctorPrescriptions(
    String doctorId,
  ) async {
    final all = await _loadAll();
    return all.where((p) => p.doctorId == doctorId).toList()
      ..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
  }

  // ── Generate + save ─────────────────────────────────────────────────────

  /// Builds the PDF, writes it to disk, saves the record, returns the [Prescription].
  static Future<Prescription> createPrescription({
    required String doctorId,
    required String doctorName,
    required String doctorDepartment,
    required String doctorDesignation,
    required String doctorDegrees,
    required String patientPhone,
    required String patientName,
    required String appointmentDate,
    required List<String> diagnosis,
    required List<PrescribedMedicine> medicines,
    String? additionalNotes,
  }) async {
    final now = DateTime.now();
    final id = 'RX${now.millisecondsSinceEpoch}';
    final issuedAt = now.toIso8601String();

    // 1. Generate PDF bytes
    final pdfBytes = await _buildPdf(
      id: id,
      doctorName: doctorName,
      doctorDepartment: doctorDepartment,
      doctorDesignation: doctorDesignation,
      doctorDegrees: doctorDegrees,
      patientName: patientName,
      patientPhone: patientPhone,
      appointmentDate: appointmentDate,
      issuedAt: issuedAt,
      diagnosis: diagnosis,
      medicines: medicines,
      additionalNotes: additionalNotes,
    );

    // 2. Write PDF file
    final dir = await getApplicationDocumentsDirectory();
    final pdfPath = '${dir.path}/$id.pdf';
    await File(pdfPath).writeAsBytes(pdfBytes);

    // 3. Build and persist record
    final prescription = Prescription(
      id: id,
      doctorId: doctorId,
      doctorName: doctorName,
      doctorDepartment: doctorDepartment,
      doctorDesignation: doctorDesignation,
      doctorDegrees: doctorDegrees,
      patientPhone: patientPhone,
      patientName: patientName,
      appointmentDate: appointmentDate,
      issuedAt: issuedAt,
      diagnosis: diagnosis,
      medicines: medicines,
      additionalNotes: additionalNotes,
      pdfPath: pdfPath,
    );

    final all = await _loadAll();
    all.add(prescription);
    await _saveAll(all);

    return prescription;
  }

  // ── PDF layout ──────────────────────────────────────────────────────────

  static Future<List<int>> _buildPdf({
    required String id,
    required String doctorName,
    required String doctorDepartment,
    required String doctorDesignation,
    required String doctorDegrees,
    required String patientName,
    required String patientPhone,
    required String appointmentDate,
    required String issuedAt,
    required List<String> diagnosis,
    required List<PrescribedMedicine> medicines,
    String? additionalNotes,
  }) async {
    final doc = pw.Document();

    final purple = PdfColor.fromHex('6A1B9A');
    final green = PdfColor.fromHex('2E7D32');
    final lightPurple = PdfColor.fromHex('EDE7F6');
    final grey = PdfColors.grey700;

    // Load signature image
    pw.MemoryImage? signatureImage;
    try {
      final sigBytes = await rootBundle.load(
        'assets/images/doctor_signature.png',
      );
      signatureImage = pw.MemoryImage(sigBytes.buffer.asUint8List());
    } catch (_) {
      // Signature image not found — fall back to line only
    }

    final issuedFormatted = DateFormat(
      'MMMM d, yyyy – hh:mm a',
    ).format(DateTime.parse(issuedAt));
    final apptFormatted = appointmentDate.isNotEmpty
        ? DateFormat(
            'MMMM d, yyyy',
          ).format(DateFormat('yyyy-MM-dd').parse(appointmentDate))
        : appointmentDate;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => _pdfHeader(
          purple: purple,
          green: green,
          lightPurple: lightPurple,
          doctorName: doctorName,
          doctorDepartment: doctorDepartment,
          doctorDesignation: doctorDesignation,
          doctorDegrees: doctorDegrees,
          id: id,
          issuedFormatted: issuedFormatted,
        ),
        footer: (_) => _pdfFooter(purple: purple),
        build: (_) => [
          pw.SizedBox(height: 12),

          // ── Patient info ──────────────────────────────────────────────
          _sectionTitle('Patient Information', green),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: green, width: 0.5),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              children: [
                _infoCell('Patient Name', patientName),
                pw.SizedBox(width: 20),
                _infoCell('Phone', patientPhone),
                pw.SizedBox(width: 20),
                _infoCell('Appointment Date', apptFormatted),
              ],
            ),
          ),

          pw.SizedBox(height: 14),

          // ── Diagnosis ──────────────────────────────────────────────────
          _sectionTitle('Diagnosis', purple),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: lightPurple,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: diagnosis
                  .map(
                    (d) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '• ',
                            style: pw.TextStyle(
                              color: purple,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              d,
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          pw.SizedBox(height: 14),

          // ── Medicines ──────────────────────────────────────────────────
          _sectionTitle('Prescribed Medicines', purple),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(3),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(3),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: purple),
                children: [
                  _tableHeader('Medicine'),
                  _tableHeader('Dosage'),
                  _tableHeader('Frequency'),
                  _tableHeader('Duration'),
                  _tableHeader('Notes'),
                ],
              ),
              // Data rows
              ...medicines.asMap().entries.map(
                (entry) => pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: entry.key.isEven
                        ? PdfColors.white
                        : PdfColors.grey100,
                  ),
                  children: [
                    _tableCell(entry.value.name),
                    _tableCell(entry.value.dosage),
                    _tableCell(entry.value.frequency),
                    _tableCell(entry.value.duration),
                    _tableCell(entry.value.notes ?? '—'),
                  ],
                ),
              ),
            ],
          ),

          if (additionalNotes != null && additionalNotes.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _sectionTitle('Additional Notes', grey),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                additionalNotes,
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
          ],

          pw.SizedBox(height: 30),

          // ── Signature ─────────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (signatureImage != null)
                    pw.Image(signatureImage, width: 120, height: 45),
                  pw.Container(width: 160, height: 0.5, color: PdfColors.black),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    doctorName,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  pw.Text(
                    doctorDesignation,
                    style: pw.TextStyle(color: grey, fontSize: 10),
                  ),
                  pw.Text(
                    doctorDepartment,
                    style: pw.TextStyle(color: grey, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ── PDF widget helpers ──────────────────────────────────────────────────

  static pw.Widget _pdfHeader({
    required PdfColor purple,
    required PdfColor green,
    required PdfColor lightPurple,
    required String doctorName,
    required String doctorDepartment,
    required String doctorDesignation,
    required String doctorDegrees,
    required String id,
    required String issuedFormatted,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(colors: [purple, green]),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Care People',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Medical Prescription',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 12),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Rx ID: $id',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Issued: $issuedFormatted',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 6),
        // Doctor banner
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: lightPurple,
          child: pw.Row(
            children: [
              pw.Text(
                'Dr. $doctorName',
                style: pw.TextStyle(
                  color: purple,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                '  |  $doctorDesignation  |  $doctorDepartment',
                style: pw.TextStyle(color: purple, fontSize: 10),
              ),
              if (doctorDegrees.isNotEmpty)
                pw.Text(
                  '  ($doctorDegrees)',
                  style: pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _pdfFooter({required PdfColor purple}) {
    return pw.Column(
      children: [
        pw.Divider(color: purple, thickness: 0.5),
        pw.Text(
          'This prescription is generated digitally by Care People. '
          'It is valid only when verified by the issuing physician.',
          style: pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: color,
          fontWeight: pw.FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  static pw.Widget _infoCell(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            color: PdfColors.grey600,
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
      ],
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  static pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }
}
