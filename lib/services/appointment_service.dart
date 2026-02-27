import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/appointment_models.dart';

class AppointmentService {
  static Future<List<Doctor>> loadDoctors() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/doctors.json');
      final Map<String, dynamic> data = json.decode(response);
      final List<dynamic> doctorsJson = data['doctors'];
      return doctorsJson.map((json) => Doctor.fromJson(json)).toList();
    } catch (e) {
      print('Error loading doctors: $e');
      return [];
    }
  }

  static Future<List<Appointment>> loadAppointments() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/appointments.json');

      if (await file.exists()) {
        final String response = await file.readAsString();
        final Map<String, dynamic> data = json.decode(response);
        final List<dynamic> appointmentsJson = data['appointments'] ?? [];
        return appointmentsJson
            .map((json) => Appointment.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error loading appointments: $e');
      return [];
    }
  }

  static Future<bool> saveAppointment(Appointment appointment) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/appointments.json');

      List<Appointment> appointments = await loadAppointments();
      appointments.add(appointment);

      final Map<String, dynamic> data = {
        'appointments': appointments.map((a) => a.toJson()).toList(),
      };

      await file.writeAsString(json.encode(data));
      return true;
    } catch (e) {
      print('Error saving appointment: $e');
      return false;
    }
  }

  static Future<int> getNextSerialNumber(
      String doctorId, String date) async {
    try {
      final appointments = await loadAppointments();
      final doctorAppointments = appointments
          .where((a) => a.doctorId == doctorId && a.date == date)
          .toList();

      if (doctorAppointments.isEmpty) {
        return 1;
      }

      // Find the highest serial number
      int maxSerial = doctorAppointments
          .map((a) => a.serialNumber)
          .reduce((a, b) => a > b ? a : b);

      return maxSerial + 1;
    } catch (e) {
      print('Error getting next serial: $e');
      return 1;
    }
  }

  static Future<List<String>> getBookedTimeSlotsForDate(
      String doctorId, String date) async {
    try {
      final appointments = await loadAppointments();
      return appointments
          .where((a) => a.doctorId == doctorId && a.date == date)
          .map((a) => a.timeSlot)
          .toList();
    } catch (e) {
      print('Error getting booked slots: $e');
      return [];
    }
  }

  static List<String> generateTimeSlots() {
    List<String> slots = [];
    // Morning slots: 9:00 AM to 12:45 PM
    for (int hour = 9; hour <= 12; hour++) {
      for (int minute = 0; minute < 60; minute += 15) {
        if (hour == 12 && minute > 45) break;
        final time =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        slots.add('$time AM');
      }
    }

    // Afternoon slots: 2:00 PM to 5:45 PM
    for (int hour = 2; hour <= 5; hour++) {
      for (int minute = 0; minute < 60; minute += 15) {
        if (hour == 5 && minute > 45) break;
        final time =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        slots.add('$time PM');
      }
    }

    return slots;
  }

  static Future<List<Appointment>> getPatientAppointments(
      String phoneNumber) async {
    try {
      final appointments = await loadAppointments();
      return appointments
          .where((a) => a.patientPhone == phoneNumber)
          .toList();
    } catch (e) {
      print('Error getting patient appointments: $e');
      return [];
    }
  }
}
