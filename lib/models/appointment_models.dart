class Doctor {
  final String id;
  final String name;
  final String department;
  final String designation;
  final String degrees;
  final String roomNumber;
  final double consultationFee;
  final List<String> consultationDays;
  final String consultationTimes;

  Doctor({
    required this.id,
    required this.name,
    required this.department,
    required this.designation,
    required this.degrees,
    required this.roomNumber,
    required this.consultationFee,
    required this.consultationDays,
    required this.consultationTimes,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as String,
      name: json['name'] as String,
      department: json['department'] as String,
      designation: json['designation'] as String,
      degrees: json['degrees'] as String,
      roomNumber: json['roomNumber'] as String,
      consultationFee: (json['consultationFee'] as num).toDouble(),
      consultationDays: List<String>.from(json['consultationDays'] as List),
      consultationTimes: json['consultationTimes'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'designation': designation,
      'degrees': degrees,
      'roomNumber': roomNumber,
      'consultationFee': consultationFee,
      'consultationDays': consultationDays,
      'consultationTimes': consultationTimes,
    };
  }
}

class Appointment {
  final String doctorId;
  final String doctorName;
  final String patientPhone;
  final String patientName;
  final String date;
  final String timeSlot;
  final int serialNumber;
  final String status;

  Appointment({
    required this.doctorId,
    required this.doctorName,
    required this.patientPhone,
    required this.patientName,
    required this.date,
    required this.timeSlot,
    required this.serialNumber,
    this.status = 'Confirmed',
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      doctorId: json['doctorId'] as String,
      doctorName: json['doctorName'] as String,
      patientPhone: json['patientPhone'] as String,
      patientName: json['patientName'] as String,
      date: json['date'] as String,
      timeSlot: json['timeSlot'] as String,
      serialNumber: json['serialNumber'] as int,
      status: json['status'] as String? ?? 'Confirmed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'doctorName': doctorName,
      'patientPhone': patientPhone,
      'patientName': patientName,
      'date': date,
      'timeSlot': timeSlot,
      'serialNumber': serialNumber,
      'status': status,
    };
  }
}
