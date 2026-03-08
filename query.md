# Care People — Complete SQL Query Reference

> **Version:** 1.0  
> **Last Updated:** March 8, 2026  
> **Project:** Care People — Hospital Management & Patient Portal  
> **Database:** PostgreSQL / MySQL compatible

---

## Table of Contents

1. [Schema Creation (DDL)](#1-schema-creation-ddl)
2. [Seed Data](#2-seed-data)
3. [CRUD Operations — doctors](#3-crud-operations--doctors)
4. [CRUD Operations — patients](#4-crud-operations--patients)
5. [CRUD Operations — sessions](#5-crud-operations--sessions)
6. [CRUD Operations — appointments](#6-crud-operations--appointments)
7. [CRUD Operations — prescriptions](#7-crud-operations--prescriptions)
8. [CRUD Operations — prescribed_medicines](#8-crud-operations--prescribed_medicines)
9. [CRUD Operations — prescription_diagnoses](#9-crud-operations--prescription_diagnoses)
10. [JOIN Queries & Complex Queries](#10-join-queries--complex-queries)
11. [Aggregation & Analytics Queries](#11-aggregation--analytics-queries)
12. [Indexing Strategy](#12-indexing-strategy)
13. [Views (Virtual Tables)](#13-views-virtual-tables)
14. [Stored Procedures & Functions](#14-stored-procedures--functions)

---

## 1. Schema Creation (DDL)

### 1.1 Create `doctors` Table

```sql
CREATE TABLE doctors (
    id              VARCHAR(10)     PRIMARY KEY,
    name            VARCHAR(100)    NOT NULL,
    department      VARCHAR(50)     NOT NULL,
    designation     VARCHAR(100)    NOT NULL,
    degrees         VARCHAR(200)    NOT NULL,
    room_number     VARCHAR(10)     NOT NULL,
    consultation_fee DECIMAL(10,2)  NOT NULL CHECK (consultation_fee >= 0),
    consultation_days JSON          NOT NULL,
    consultation_times VARCHAR(100) NOT NULL,
    password        VARCHAR(255)    NOT NULL,
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### 1.2 Create `patients` Table

```sql
CREATE TABLE patients (
    phone_number    VARCHAR(15)     PRIMARY KEY,
    name            VARCHAR(100)    NOT NULL,
    date_of_birth   VARCHAR(20)     NOT NULL,
    address         TEXT            NOT NULL,
    gender          ENUM('Male', 'Female', 'Other') NOT NULL DEFAULT 'Male',
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       NULL ON UPDATE CURRENT_TIMESTAMP
);
```

### 1.3 Create `sessions` Table

```sql
CREATE TABLE sessions (
    id              BIGINT          PRIMARY KEY AUTO_INCREMENT,
    user_type       ENUM('patient', 'doctor') NOT NULL,
    user_identifier VARCHAR(15)     NOT NULL,
    session_data    JSON            NULL,
    login_timestamp BIGINT          NOT NULL,
    expires_at      TIMESTAMP       NOT NULL,
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_sessions_user (user_type, user_identifier),
    INDEX idx_sessions_active (is_active, expires_at)
);
```

### 1.4 Create `appointments` Table

```sql
CREATE TABLE appointments (
    id              BIGINT          PRIMARY KEY AUTO_INCREMENT,
    doctor_id       VARCHAR(10)     NOT NULL,
    doctor_name     VARCHAR(100)    NOT NULL,
    patient_phone   VARCHAR(15)     NOT NULL,
    patient_name    VARCHAR(100)    NOT NULL,
    date            VARCHAR(10)     NOT NULL,
    time_slot       VARCHAR(10)     NOT NULL,
    serial_number   INT             NOT NULL CHECK (serial_number > 0),
    status          VARCHAR(20)     NOT NULL DEFAULT 'Confirmed',
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (patient_phone) REFERENCES patients(phone_number) ON DELETE RESTRICT ON UPDATE CASCADE,

    UNIQUE KEY uk_doctor_date_slot (doctor_id, date, time_slot),
    INDEX idx_appointments_doctor (doctor_id, date),
    INDEX idx_appointments_patient (patient_phone, date),
    INDEX idx_appointments_date (date)
);
```

### 1.5 Create `prescriptions` Table

```sql
CREATE TABLE prescriptions (
    id                  VARCHAR(30)     PRIMARY KEY,
    doctor_id           VARCHAR(10)     NOT NULL,
    doctor_name         VARCHAR(100)    NOT NULL,
    doctor_department   VARCHAR(50)     NOT NULL DEFAULT '',
    doctor_designation  VARCHAR(100)    NOT NULL DEFAULT '',
    doctor_degrees      VARCHAR(200)    NOT NULL DEFAULT '',
    patient_phone       VARCHAR(15)     NOT NULL,
    patient_name        VARCHAR(100)    NOT NULL,
    appointment_date    VARCHAR(10)     NOT NULL,
    issued_at           VARCHAR(30)     NOT NULL,
    additional_notes    TEXT            NULL,
    pdf_path            VARCHAR(500)    NOT NULL,
    created_at          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (patient_phone) REFERENCES patients(phone_number) ON DELETE RESTRICT ON UPDATE CASCADE,

    INDEX idx_prescriptions_doctor (doctor_id, issued_at),
    INDEX idx_prescriptions_patient (patient_phone, issued_at),
    INDEX idx_prescriptions_date (appointment_date)
);
```

### 1.6 Create `prescribed_medicines` Table

```sql
CREATE TABLE prescribed_medicines (
    id              BIGINT          PRIMARY KEY AUTO_INCREMENT,
    prescription_id VARCHAR(30)     NOT NULL,
    name            VARCHAR(200)    NOT NULL,
    dosage          VARCHAR(100)    NOT NULL,
    frequency       VARCHAR(100)    NOT NULL,
    duration        VARCHAR(100)    NOT NULL,
    notes           TEXT            NULL,

    FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON DELETE CASCADE ON UPDATE CASCADE,

    INDEX idx_medicines_prescription (prescription_id)
);
```

### 1.7 Create `prescription_diagnoses` Table

```sql
CREATE TABLE prescription_diagnoses (
    id              BIGINT          PRIMARY KEY AUTO_INCREMENT,
    prescription_id VARCHAR(30)     NOT NULL,
    diagnosis_text  TEXT            NOT NULL,
    sort_order      INT             DEFAULT 0,

    FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON DELETE CASCADE ON UPDATE CASCADE,

    INDEX idx_diagnoses_prescription (prescription_id)
);
```

### 1.8 Drop All Tables (Reverse Order)

```sql
DROP TABLE IF EXISTS prescription_diagnoses;
DROP TABLE IF EXISTS prescribed_medicines;
DROP TABLE IF EXISTS prescriptions;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS sessions;
DROP TABLE IF EXISTS patients;
DROP TABLE IF EXISTS doctors;
```

---

## 2. Seed Data

### 2.1 Seed Doctors (from `doctors.json`)

```sql
INSERT INTO doctors (id, name, department, designation, degrees, room_number, consultation_fee, consultation_days, consultation_times, password)
VALUES
('DOC001', 'Dr. Md. Kamal Hossain', 'Cardiology', 'Senior Consultant', 'MBBS, MD, DM (Cardiology)', '301', 1500.00, '["Monday","Tuesday","Wednesday","Thursday","Saturday"]', '09:00 AM - 01:00 PM, 03:00 PM - 06:00 PM', 'Kamal@1234'),
('DOC002', 'Dr. Farhana Rahman', 'Neurology', 'Chief Neurologist', 'MBBS, MD, DM (Neurology)', '405', 1800.00, '["Sunday","Monday","Wednesday","Thursday"]', '10:00 AM - 02:00 PM, 04:00 PM - 07:00 PM', 'Farhana@1234'),
('DOC003', 'Dr. Sharmin Akter', 'Pediatrics', 'Consultant Pediatrician', 'MBBS, MD (Pediatrics)', '201', 1000.00, '["Saturday","Sunday","Monday","Tuesday","Wednesday"]', '08:00 AM - 12:00 PM, 02:00 PM - 05:00 PM', 'Sharmin@1234'),
('DOC004', 'Dr. Rafiqul Islam', 'Orthopedics', 'Senior Orthopedic Surgeon', 'MBBS, MS (Orthopedics)', '502', 1200.00, '["Sunday","Tuesday","Wednesday","Friday"]', '09:00 AM - 01:00 PM', 'Rafiqul@1234'),
('DOC005', 'Dr. Nasrin Sultana', 'Dermatology', 'Consultant Dermatologist', 'MBBS, MD (Dermatology)', '103', 900.00, '["Monday","Tuesday","Thursday","Friday","Saturday"]', '10:00 AM - 01:00 PM, 03:00 PM - 06:00 PM', 'Nasrin@1234'),
('DOC006', 'Dr. Abdul Latif Chowdhury', 'General Surgery', 'Chief Surgeon', 'MBBS, MS, FRCS', '601', 2000.00, '["Sunday","Monday","Tuesday","Thursday"]', '09:00 AM - 12:00 PM', 'Abdul@1234'),
('DOC007', 'Dr. Tahmina Begum', 'Gynecology', 'Senior Gynecologist', 'MBBS, MD (Obs & Gyn)', '304', 1300.00, '["Saturday","Sunday","Tuesday","Wednesday","Thursday"]', '10:00 AM - 02:00 PM, 04:00 PM - 06:00 PM', 'Tahmina@1234'),
('DOC008', 'Dr. Anwar Hossain', 'Ophthalmology', 'Eye Specialist', 'MBBS, MS (Ophthalmology)', '206', 800.00, '["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]', '09:00 AM - 01:00 PM, 02:00 PM - 05:00 PM', 'Anwar@1234'),
('DOC009', 'Dr. Ayesha Siddiqua', 'Psychiatry', 'Consultant Psychiatrist', 'MBBS, MD (Psychiatry)', '701', 1100.00, '["Sunday","Monday","Wednesday","Friday"]', '11:00 AM - 03:00 PM, 05:00 PM - 08:00 PM', 'Ayesha@1234'),
('DOC010', 'Dr. Mohammad Ali Khan', 'Cardiology', 'Cardiac Surgeon', 'MBBS, MS, MCh (Cardiac Surgery)', '302', 2500.00, '["Sunday","Tuesday","Thursday"]', '08:00 AM - 12:00 PM', 'MohAli@1234'),
('DOC011', 'Dr. Razia Khatun', 'Endocrinology', 'Senior Endocrinologist', 'MBBS, MD, DM (Endocrinology)', '408', 1400.00, '["Monday","Wednesday","Thursday","Saturday"]', '09:00 AM - 01:00 PM, 03:00 PM - 06:00 PM', 'Razia@1234'),
('DOC012', 'Dr. Shahidul Alam', 'Urology', 'Consultant Urologist', 'MBBS, MS (Urology)', '505', 1200.00, '["Sunday","Monday","Tuesday","Friday","Saturday"]', '10:00 AM - 01:00 PM, 04:00 PM - 07:00 PM', 'Shahidul@1234'),
('DOC013', 'Dr. Nusrat Jahan', 'Pediatrics', 'Pediatric Surgeon', 'MBBS, MS, MCh (Pediatric Surgery)', '202', 1600.00, '["Sunday","Tuesday","Wednesday","Thursday"]', '08:00 AM - 12:00 PM, 02:00 PM - 04:00 PM', 'Nusrat@1234'),
('DOC014', 'Dr. Mizanur Rahman', 'Neurology', 'Neurosurgeon', 'MBBS, MS, MCh (Neurosurgery)', '406', 2200.00, '["Monday","Wednesday","Thursday","Friday"]', '10:00 AM - 01:00 PM', 'Mizan@1234'),
('DOC015', 'Dr. Sultana Parvin', 'ENT', 'ENT Specialist', 'MBBS, MS (ENT)', '305', 950.00, '["Saturday","Sunday","Monday","Tuesday","Wednesday","Friday"]', '09:00 AM - 01:00 PM, 03:00 PM - 06:00 PM', 'Sultana@1234'),
('DOC016', 'Dr. Jahangir Alam', 'Gastroenterology', 'Senior Gastroenterologist', 'MBBS, MD, DM (Gastroenterology)', '409', 1500.00, '["Sunday","Tuesday","Wednesday","Thursday"]', '09:00 AM - 12:00 PM, 04:00 PM - 07:00 PM', 'Jahangir@1234'),
('DOC017', 'Dr. Mahbuba Khanam', 'Rheumatology', 'Consultant Rheumatologist', 'MBBS, MD (Rheumatology)', '308', 1300.00, '["Monday","Tuesday","Thursday","Saturday"]', '10:00 AM - 02:00 PM, 03:00 PM - 05:00 PM', 'Mahbuba@1234'),
('DOC018', 'Dr. Habibur Rahman', 'Pulmonology', 'Chest Specialist', 'MBBS, MD (Pulmonology)', '410', 1200.00, '["Sunday","Monday","Wednesday","Friday","Saturday"]', '09:00 AM - 01:00 PM, 02:00 PM - 05:00 PM', 'Habibur@1234'),
('DOC019', 'Dr. Shirina Akhter', 'Nephrology', 'Kidney Specialist', 'MBBS, MD, DM (Nephrology)', '411', 1400.00, '["Sunday","Tuesday","Wednesday","Thursday","Saturday"]', '10:00 AM - 02:00 PM, 04:00 PM - 06:00 PM', 'Shirina@1234'),
('DOC020', 'Dr. Alamgir Hossain', 'Oncology', 'Cancer Specialist', 'MBBS, MD, DM (Medical Oncology)', '702', 2000.00, '["Monday","Tuesday","Wednesday","Thursday","Friday"]', '09:00 AM - 12:00 PM, 03:00 PM - 06:00 PM', 'Alamgir@1234');
```

> ⚠️ **Production Note:** Passwords should be hashed with bcrypt before inserting. The above uses plain text for demonstration only.

---

## 3. CRUD Operations — `doctors`

### 3.1 CREATE — Add a New Doctor

```sql
INSERT INTO doctors (id, name, department, designation, degrees, room_number, consultation_fee, consultation_days, consultation_times, password)
VALUES (
    'DOC021',
    'Dr. New Doctor',
    'Cardiology',
    'Consultant',
    'MBBS, MD',
    '801',
    1500.00,
    '["Monday", "Wednesday", "Friday"]',
    '09:00 AM - 01:00 PM',
    '$2b$10$hashedpasswordhere'  -- bcrypt hash
);
```

### 3.2 READ — Get All Doctors

```sql
-- Used by: AppointmentService.loadDoctors()
SELECT id, name, department, designation, degrees, room_number,
       consultation_fee, consultation_days, consultation_times
FROM doctors
ORDER BY name;
```

### 3.3 READ — Get Doctor by ID (Login)

```sql
-- Used by: DoctorLoginPage._findDoctor()
SELECT *
FROM doctors
WHERE UPPER(id) = UPPER('DOC001')
  AND password = 'Kamal@1234';
```

### 3.4 READ — Get Doctors by Department

```sql
-- Used by: BookAppointmentPage._filterDoctors()
SELECT id, name, department, designation, degrees, room_number,
       consultation_fee, consultation_days, consultation_times
FROM doctors
WHERE department = 'Cardiology'
ORDER BY name;
```

### 3.5 READ — Search Doctors by Name or Department

```sql
-- Used by: BookAppointmentPage (search bar)
SELECT id, name, department, designation, degrees, room_number,
       consultation_fee, consultation_days, consultation_times
FROM doctors
WHERE LOWER(name) LIKE LOWER('%kamal%')
   OR LOWER(department) LIKE LOWER('%kamal%')
ORDER BY name;
```

### 3.6 READ — Get All Unique Departments

```sql
-- Used by: BookAppointmentPage._getDepartments()
SELECT DISTINCT department
FROM doctors
ORDER BY department;
```

### 3.7 UPDATE — Update Doctor Information

```sql
UPDATE doctors
SET name = 'Dr. Updated Name',
    designation = 'Chief Consultant',
    consultation_fee = 2000.00,
    consultation_days = '["Monday","Tuesday","Wednesday"]',
    consultation_times = '10:00 AM - 02:00 PM',
    updated_at = CURRENT_TIMESTAMP
WHERE id = 'DOC001';
```

### 3.8 UPDATE — Change Doctor Password

```sql
UPDATE doctors
SET password = '$2b$10$newhashedpassword',
    updated_at = CURRENT_TIMESTAMP
WHERE id = 'DOC001';
```

### 3.9 DELETE — Remove a Doctor

```sql
-- Warning: Will fail if doctor has appointments or prescriptions (RESTRICT)
DELETE FROM doctors WHERE id = 'DOC021';
```

---

## 4. CRUD Operations — `patients`

### 4.1 CREATE — Register New Patient

```sql
-- Used by: UserStorageService.saveUser()
INSERT INTO patients (phone_number, name, date_of_birth, address, gender, created_at)
VALUES (
    '01712345678',
    'Rahim Uddin',
    '15/06/1990',
    '123 Main Street, Dhaka, Bangladesh',
    'Male',
    CURRENT_TIMESTAMP
);
```

### 4.2 READ — Check if Patient Exists

```sql
-- Used by: UserStorageService.userExists()
SELECT EXISTS(
    SELECT 1 FROM patients WHERE phone_number = '01712345678'
) AS user_exists;
```

### 4.3 READ — Get Patient by Phone Number

```sql
-- Used by: UserStorageService.getUserData()
SELECT phone_number, name, date_of_birth, address, gender, created_at, updated_at
FROM patients
WHERE phone_number = '01712345678';
```

### 4.4 READ — Get All Patients

```sql
-- Used by: UserStorageService.getAllUsers()
SELECT phone_number, name, date_of_birth, address, gender, created_at, updated_at
FROM patients
ORDER BY created_at DESC;
```

### 4.5 UPDATE — Update Patient Profile

```sql
-- Used by: UserStorageService.updateUser() / saveUser() (overwrite)
UPDATE patients
SET name = 'Updated Name',
    date_of_birth = '20/01/1985',
    address = 'New Address, Chittagong, Bangladesh',
    gender = 'Male',
    updated_at = CURRENT_TIMESTAMP
WHERE phone_number = '01712345678';
```

### 4.6 DELETE — Delete Patient Account

```sql
-- Used by: UserStorageService.deleteUser()
-- Warning: Will fail if patient has appointments or prescriptions (RESTRICT)
DELETE FROM patients WHERE phone_number = '01712345678';
```

---

## 5. CRUD Operations — `sessions`

### 5.1 CREATE — Save Patient Session

```sql
-- Used by: SessionService.saveSession()
INSERT INTO sessions (user_type, user_identifier, session_data, login_timestamp, expires_at, is_active)
VALUES (
    'patient',
    '01712345678',
    NULL,
    UNIX_TIMESTAMP() * 1000,  -- milliseconds since epoch
    DATE_ADD(NOW(), INTERVAL 2 DAY),
    TRUE
);
```

### 5.2 CREATE — Save Doctor Session

```sql
-- Used by: SessionService.saveDoctorSession()
INSERT INTO sessions (user_type, user_identifier, session_data, login_timestamp, expires_at, is_active)
VALUES (
    'doctor',
    'DOC001',
    '{"id":"DOC001","name":"Dr. Md. Kamal Hossain","department":"Cardiology","designation":"Senior Consultant","degrees":"MBBS, MD, DM (Cardiology)","roomNumber":"301","consultationFee":1500}',
    UNIX_TIMESTAMP() * 1000,
    DATE_ADD(NOW(), INTERVAL 2 DAY),
    TRUE
);
```

### 5.3 READ — Check if Patient Session is Active

```sql
-- Used by: SessionService.isSessionActive()
SELECT id, user_identifier, login_timestamp, expires_at
FROM sessions
WHERE user_type = 'patient'
  AND user_identifier = '01712345678'
  AND is_active = TRUE
  AND expires_at > NOW()
ORDER BY created_at DESC
LIMIT 1;
```

### 5.4 READ — Check if Doctor Session is Active

```sql
-- Used by: SessionService.isDoctorSessionActive()
SELECT id, user_identifier, session_data, login_timestamp, expires_at
FROM sessions
WHERE user_type = 'doctor'
  AND is_active = TRUE
  AND expires_at > NOW()
ORDER BY created_at DESC
LIMIT 1;
```

### 5.5 READ — Get Doctor Data from Session

```sql
-- Used by: SessionService.getDoctorData()
SELECT session_data
FROM sessions
WHERE user_type = 'doctor'
  AND is_active = TRUE
  AND expires_at > NOW()
ORDER BY created_at DESC
LIMIT 1;
```

### 5.6 READ — Get Patient Phone from Session

```sql
-- Used by: SessionService.getPhoneNumber()
SELECT user_identifier
FROM sessions
WHERE user_type = 'patient'
  AND is_active = TRUE
  AND expires_at > NOW()
ORDER BY created_at DESC
LIMIT 1;
```

### 5.7 UPDATE — Deactivate Session (Logout)

```sql
-- Used by: SessionService.clearSession() / clearDoctorSession()
UPDATE sessions
SET is_active = FALSE
WHERE user_type = 'patient'
  AND user_identifier = '01712345678'
  AND is_active = TRUE;
```

### 5.8 DELETE — Clean Up Expired Sessions

```sql
-- Maintenance query: remove all expired sessions
DELETE FROM sessions
WHERE expires_at < NOW()
   OR is_active = FALSE;
```

---

## 6. CRUD Operations — `appointments`

### 6.1 CREATE — Book a New Appointment

```sql
-- Used by: AppointmentService.saveAppointment()
INSERT INTO appointments (doctor_id, doctor_name, patient_phone, patient_name, date, time_slot, serial_number, status)
VALUES (
    'DOC001',
    'Dr. Md. Kamal Hossain',
    '01712345678',
    'Rahim Uddin',
    '2026-03-15',
    '09:00 AM',
    1,
    'Confirmed'
);
```

### 6.2 READ — Get All Appointments

```sql
-- Used by: AppointmentService.loadAppointments()
SELECT doctor_id, doctor_name, patient_phone, patient_name,
       date, time_slot, serial_number, status
FROM appointments
ORDER BY date DESC, time_slot;
```

### 6.3 READ — Get Patient's Appointments

```sql
-- Used by: AppointmentService.getPatientAppointments()
SELECT doctor_id, doctor_name, patient_phone, patient_name,
       date, time_slot, serial_number, status
FROM appointments
WHERE patient_phone = '01712345678'
ORDER BY date DESC;
```

### 6.4 READ — Get Doctor's Appointments

```sql
-- Used by: AppointmentService.getDoctorAppointments()
SELECT doctor_id, doctor_name, patient_phone, patient_name,
       date, time_slot, serial_number, status
FROM appointments
WHERE doctor_id = 'DOC001'
ORDER BY date DESC;
```

### 6.5 READ — Get Doctor's Upcoming Appointments (for prescription writing)

```sql
-- Used by: WritePrescriptionPage._loadAppointments()
SELECT doctor_id, doctor_name, patient_phone, patient_name,
       date, time_slot, serial_number, status
FROM appointments
WHERE doctor_id = 'DOC001'
  AND date >= CURDATE()
ORDER BY date ASC;
```

### 6.6 READ — Get Doctor's Appointments Split by Date (Upcoming vs Previous)

```sql
-- Used by: DoctorAppointmentsPage._loadAppointments()
-- Upcoming:
SELECT * FROM appointments
WHERE doctor_id = 'DOC001'
  AND date >= CURDATE()
ORDER BY date ASC;

-- Previous:
SELECT * FROM appointments
WHERE doctor_id = 'DOC001'
  AND date < CURDATE()
ORDER BY date DESC;
```

### 6.7 READ — Get Patient's Appointments Split by Date

```sql
-- Used by: AppointmentsListPage._loadAppointments()
-- Upcoming:
SELECT * FROM appointments
WHERE patient_phone = '01712345678'
  AND date >= CURDATE()
ORDER BY date ASC;

-- Previous:
SELECT * FROM appointments
WHERE patient_phone = '01712345678'
  AND date < CURDATE()
ORDER BY date DESC;
```

### 6.8 READ — Get Booked Time Slots for a Date

```sql
-- Used by: AppointmentService.getBookedTimeSlotsForDate()
SELECT time_slot
FROM appointments
WHERE doctor_id = 'DOC001'
  AND date = '2026-03-15';
```

### 6.9 READ — Get Next Serial Number

```sql
-- Used by: AppointmentService.getNextSerialNumber()
SELECT COALESCE(MAX(serial_number), 0) + 1 AS next_serial
FROM appointments
WHERE doctor_id = 'DOC001'
  AND date = '2026-03-15';
```

### 6.10 UPDATE — Update Appointment Status

```sql
UPDATE appointments
SET status = 'Completed'
WHERE doctor_id = 'DOC001'
  AND patient_phone = '01712345678'
  AND date = '2026-03-15';
```

### 6.11 DELETE — Remove Appointment (After Prescription Generated)

```sql
-- Used by: AppointmentService.removeAppointment()
DELETE FROM appointments
WHERE doctor_id = 'DOC001'
  AND patient_phone = '01712345678'
  AND date = '2026-03-15';
```

---

## 7. CRUD Operations — `prescriptions`

### 7.1 CREATE — Create New Prescription

```sql
-- Used by: PrescriptionService.createPrescription()
INSERT INTO prescriptions (id, doctor_id, doctor_name, doctor_department, doctor_designation,
                          doctor_degrees, patient_phone, patient_name, appointment_date,
                          issued_at, additional_notes, pdf_path)
VALUES (
    'RX1709901234567',
    'DOC001',
    'Dr. Md. Kamal Hossain',
    'Cardiology',
    'Senior Consultant',
    'MBBS, MD, DM (Cardiology)',
    '01712345678',
    'Rahim Uddin',
    '2026-03-15',
    '2026-03-15T10:30:00.000',
    'Follow up in 2 weeks. Monitor blood pressure daily.',
    '/data/user/0/com.example.care_people/app_flutter/RX1709901234567.pdf'
);
```

### 7.2 READ — Get Patient's Prescriptions (Newest First)

```sql
-- Used by: PrescriptionService.getPatientPrescriptions()
SELECT p.*, 
       GROUP_CONCAT(DISTINCT pd.diagnosis_text ORDER BY pd.sort_order SEPARATOR '||') AS diagnoses,
       COUNT(DISTINCT pm.id) AS medicine_count
FROM prescriptions p
LEFT JOIN prescription_diagnoses pd ON p.id = pd.prescription_id
LEFT JOIN prescribed_medicines pm ON p.id = pm.prescription_id
WHERE p.patient_phone = '01712345678'
GROUP BY p.id
ORDER BY p.issued_at DESC;
```

### 7.3 READ — Get Doctor's Prescriptions (Newest First)

```sql
-- Used by: PrescriptionService.getDoctorPrescriptions()
SELECT p.*, 
       GROUP_CONCAT(DISTINCT pd.diagnosis_text ORDER BY pd.sort_order SEPARATOR '||') AS diagnoses,
       COUNT(DISTINCT pm.id) AS medicine_count
FROM prescriptions p
LEFT JOIN prescription_diagnoses pd ON p.id = pd.prescription_id
LEFT JOIN prescribed_medicines pm ON p.id = pm.prescription_id
WHERE p.doctor_id = 'DOC001'
GROUP BY p.id
ORDER BY p.issued_at DESC;
```

### 7.4 READ — Get Prescription by ID (with all details)

```sql
SELECT p.*,
       pd.diagnosis_text,
       pm.name AS medicine_name, pm.dosage, pm.frequency, pm.duration, pm.notes AS medicine_notes
FROM prescriptions p
LEFT JOIN prescription_diagnoses pd ON p.id = pd.prescription_id
LEFT JOIN prescribed_medicines pm ON p.id = pm.prescription_id
WHERE p.id = 'RX1709901234567'
ORDER BY pd.sort_order, pm.id;
```

### 7.5 UPDATE — Update Prescription Notes

```sql
UPDATE prescriptions
SET additional_notes = 'Updated notes: Follow up in 1 week instead.',
    pdf_path = '/new/path/to/regenerated.pdf'
WHERE id = 'RX1709901234567';
```

### 7.6 DELETE — Delete Prescription (Cascades to medicines & diagnoses)

```sql
-- Will automatically delete related prescribed_medicines and prescription_diagnoses
DELETE FROM prescriptions WHERE id = 'RX1709901234567';
```

---

## 8. CRUD Operations — `prescribed_medicines`

### 8.1 CREATE — Add Medicine to Prescription

```sql
-- Used during: PrescriptionService.createPrescription() — for each medicine
INSERT INTO prescribed_medicines (prescription_id, name, dosage, frequency, duration, notes)
VALUES
    ('RX1709901234567', 'Amlodipine', '5mg', 'Once daily', '30 days', 'Take in the morning'),
    ('RX1709901234567', 'Aspirin', '75mg', 'Once daily', '30 days', 'Take after lunch'),
    ('RX1709901234567', 'Atorvastatin', '20mg', 'Once daily at night', '30 days', NULL);
```

### 8.2 READ — Get All Medicines for a Prescription

```sql
SELECT id, prescription_id, name, dosage, frequency, duration, notes
FROM prescribed_medicines
WHERE prescription_id = 'RX1709901234567'
ORDER BY id;
```

### 8.3 UPDATE — Update a Medicine Entry

```sql
UPDATE prescribed_medicines
SET dosage = '10mg',
    frequency = 'Twice daily',
    notes = 'Updated: Take morning and night'
WHERE id = 42;
```

### 8.4 DELETE — Remove a Specific Medicine

```sql
DELETE FROM prescribed_medicines WHERE id = 42;
```

### 8.5 DELETE — Remove All Medicines for a Prescription

```sql
DELETE FROM prescribed_medicines WHERE prescription_id = 'RX1709901234567';
```

---

## 9. CRUD Operations — `prescription_diagnoses`

### 9.1 CREATE — Add Diagnoses to Prescription

```sql
-- Used during: PrescriptionService.createPrescription() — for each diagnosis
INSERT INTO prescription_diagnoses (prescription_id, diagnosis_text, sort_order)
VALUES
    ('RX1709901234567', 'Hypertension Stage 2', 0),
    ('RX1709901234567', 'Mild Coronary Artery Disease', 1),
    ('RX1709901234567', 'Hyperlipidemia', 2);
```

### 9.2 READ — Get All Diagnoses for a Prescription

```sql
SELECT id, prescription_id, diagnosis_text, sort_order
FROM prescription_diagnoses
WHERE prescription_id = 'RX1709901234567'
ORDER BY sort_order;
```

### 9.3 UPDATE — Update a Diagnosis

```sql
UPDATE prescription_diagnoses
SET diagnosis_text = 'Hypertension Stage 1 (improved)'
WHERE id = 15;
```

### 9.4 DELETE — Remove a Specific Diagnosis

```sql
DELETE FROM prescription_diagnoses WHERE id = 15;
```

---

## 10. JOIN Queries & Complex Queries

### 10.1 Get Complete Appointment Details with Doctor & Patient Info

```sql
-- Full appointment details with joined doctor and patient data
SELECT
    a.id AS appointment_id,
    a.date,
    a.time_slot,
    a.serial_number,
    a.status,
    d.id AS doctor_id,
    d.name AS doctor_name,
    d.department,
    d.designation,
    d.degrees,
    d.room_number,
    d.consultation_fee,
    p.phone_number AS patient_phone,
    p.name AS patient_name,
    p.gender,
    p.date_of_birth,
    p.address
FROM appointments a
INNER JOIN doctors d ON a.doctor_id = d.id
INNER JOIN patients p ON a.patient_phone = p.phone_number
WHERE a.date >= CURDATE()
ORDER BY a.date ASC, a.time_slot ASC;
```

### 10.2 Get Full Prescription with Diagnoses and Medicines

```sql
-- Complete prescription with all child records
SELECT
    p.id AS prescription_id,
    p.issued_at,
    p.appointment_date,
    p.additional_notes,
    p.pdf_path,
    p.doctor_name,
    p.doctor_department,
    p.doctor_designation,
    p.patient_name,
    p.patient_phone,
    pd.diagnosis_text,
    pd.sort_order AS diagnosis_order,
    pm.name AS medicine_name,
    pm.dosage,
    pm.frequency,
    pm.duration,
    pm.notes AS medicine_notes
FROM prescriptions p
LEFT JOIN prescription_diagnoses pd ON p.id = pd.prescription_id
LEFT JOIN prescribed_medicines pm ON p.id = pm.prescription_id
WHERE p.id = 'RX1709901234567'
ORDER BY pd.sort_order, pm.id;
```

### 10.3 Doctor's Patient Records — All Patients with Appointments & Prescriptions

```sql
-- Used by: PatientRecordsPage._loadData()
-- Get unique patients for a doctor with appointment and prescription counts
SELECT
    COALESCE(apt.patient_phone, rx.patient_phone) AS patient_phone,
    COALESCE(apt.patient_name, rx.patient_name) AS patient_name,
    COALESCE(apt_count, 0) AS appointment_count,
    COALESCE(rx_count, 0) AS prescription_count,
    GREATEST(
        COALESCE(apt.latest_date, ''),
        COALESCE(rx.latest_date, '')
    ) AS last_activity
FROM (
    SELECT patient_phone, patient_name,
           COUNT(*) AS apt_count,
           MAX(date) AS latest_date
    FROM appointments
    WHERE doctor_id = 'DOC001'
    GROUP BY patient_phone, patient_name
) apt
FULL OUTER JOIN (
    SELECT patient_phone, patient_name,
           COUNT(*) AS rx_count,
           MAX(LEFT(issued_at, 10)) AS latest_date
    FROM prescriptions
    WHERE doctor_id = 'DOC001'
    GROUP BY patient_phone, patient_name
) rx ON apt.patient_phone = rx.patient_phone
ORDER BY last_activity DESC;
```

> **MySQL alternative** (no FULL OUTER JOIN):
```sql
SELECT patient_phone, patient_name, apt_count, rx_count, last_activity
FROM (
    SELECT
        a.patient_phone,
        a.patient_name,
        COUNT(DISTINCT a.id) AS apt_count,
        COUNT(DISTINCT p.id) AS rx_count,
        GREATEST(
            COALESCE(MAX(a.date), ''),
            COALESCE(MAX(LEFT(p.issued_at, 10)), '')
        ) AS last_activity
    FROM appointments a
    LEFT JOIN prescriptions p ON a.patient_phone = p.patient_phone AND p.doctor_id = a.doctor_id
    WHERE a.doctor_id = 'DOC001'
    GROUP BY a.patient_phone, a.patient_name

    UNION

    SELECT
        p.patient_phone,
        p.patient_name,
        COUNT(DISTINCT a.id) AS apt_count,
        COUNT(DISTINCT p.id) AS rx_count,
        GREATEST(
            COALESCE(MAX(a.date), ''),
            COALESCE(MAX(LEFT(p.issued_at, 10)), '')
        ) AS last_activity
    FROM prescriptions p
    LEFT JOIN appointments a ON p.patient_phone = a.patient_phone AND a.doctor_id = p.doctor_id
    WHERE p.doctor_id = 'DOC001'
    GROUP BY p.patient_phone, p.patient_name
) combined
ORDER BY last_activity DESC;
```

### 10.4 Find Previous Appointment's Prescription (for Appointment History)

```sql
-- Used by: AppointmentsListPage — match prescription to past appointment
SELECT
    a.id AS appointment_id,
    a.doctor_id,
    a.doctor_name,
    a.patient_phone,
    a.date AS appointment_date,
    a.time_slot,
    a.serial_number,
    p.id AS prescription_id,
    p.issued_at,
    p.pdf_path
FROM appointments a
LEFT JOIN prescriptions p
    ON a.doctor_id = p.doctor_id
    AND a.patient_phone = p.patient_phone
    AND a.date = p.appointment_date
WHERE a.patient_phone = '01712345678'
  AND a.date < CURDATE()
ORDER BY a.date DESC;
```

### 10.5 Search Patients by Name or Phone (for Doctor Records Page)

```sql
-- Used by: PatientRecordsPage search functionality
SELECT DISTINCT
    a.patient_phone,
    a.patient_name
FROM appointments a
WHERE a.doctor_id = 'DOC001'
  AND (
      LOWER(a.patient_name) LIKE LOWER('%search_term%')
      OR a.patient_phone LIKE '%search_term%'
  )

UNION

SELECT DISTINCT
    p.patient_phone,
    p.patient_name
FROM prescriptions p
WHERE p.doctor_id = 'DOC001'
  AND (
      LOWER(p.patient_name) LIKE LOWER('%search_term%')
      OR p.patient_phone LIKE '%search_term%'
  );
```

### 10.6 Get Patient's Complete Medical History with a Specific Doctor

```sql
-- Appointments
SELECT 'appointment' AS record_type,
       a.date AS record_date,
       a.time_slot,
       a.serial_number,
       a.status,
       NULL AS prescription_id,
       NULL AS pdf_path
FROM appointments a
WHERE a.doctor_id = 'DOC001'
  AND a.patient_phone = '01712345678'

UNION ALL

-- Prescriptions
SELECT 'prescription' AS record_type,
       p.appointment_date AS record_date,
       NULL AS time_slot,
       NULL AS serial_number,
       NULL AS status,
       p.id AS prescription_id,
       p.pdf_path
FROM prescriptions p
WHERE p.doctor_id = 'DOC001'
  AND p.patient_phone = '01712345678'

ORDER BY record_date DESC;
```

### 10.7 Check Doctor Availability on a Specific Date

```sql
-- Get all booked slots for a doctor on a date, compare with total available slots
SELECT
    d.id AS doctor_id,
    d.name AS doctor_name,
    d.consultation_days,
    d.consultation_times,
    COUNT(a.id) AS booked_slots,
    -- Assuming 32 morning slots (9-12:45) + 16 afternoon slots (2-5:45) = 48 total
    (48 - COUNT(a.id)) AS available_slots
FROM doctors d
LEFT JOIN appointments a
    ON d.id = a.doctor_id
    AND a.date = '2026-03-15'
WHERE d.id = 'DOC001'
GROUP BY d.id, d.name, d.consultation_days, d.consultation_times;
```

---

## 11. Aggregation & Analytics Queries

### 11.1 Total Appointments Per Doctor

```sql
SELECT
    d.id,
    d.name,
    d.department,
    COUNT(a.id) AS total_appointments,
    SUM(CASE WHEN a.date >= CURDATE() THEN 1 ELSE 0 END) AS upcoming,
    SUM(CASE WHEN a.date < CURDATE() THEN 1 ELSE 0 END) AS completed
FROM doctors d
LEFT JOIN appointments a ON d.id = a.doctor_id
GROUP BY d.id, d.name, d.department
ORDER BY total_appointments DESC;
```

### 11.2 Total Prescriptions Per Doctor

```sql
SELECT
    d.id,
    d.name,
    d.department,
    COUNT(p.id) AS total_prescriptions,
    COUNT(DISTINCT p.patient_phone) AS unique_patients
FROM doctors d
LEFT JOIN prescriptions p ON d.id = p.doctor_id
GROUP BY d.id, d.name, d.department
ORDER BY total_prescriptions DESC;
```

### 11.3 Most Prescribed Medicines

```sql
SELECT
    pm.name AS medicine_name,
    COUNT(*) AS times_prescribed,
    COUNT(DISTINCT p.doctor_id) AS prescribed_by_doctors,
    COUNT(DISTINCT p.patient_phone) AS prescribed_to_patients
FROM prescribed_medicines pm
INNER JOIN prescriptions p ON pm.prescription_id = p.id
GROUP BY pm.name
ORDER BY times_prescribed DESC
LIMIT 20;
```

### 11.4 Appointments Per Day (Last 30 Days)

```sql
SELECT
    date,
    COUNT(*) AS total_appointments,
    COUNT(DISTINCT doctor_id) AS doctors_active,
    COUNT(DISTINCT patient_phone) AS patients_seen
FROM appointments
WHERE date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY date
ORDER BY date DESC;
```

### 11.5 Department-wise Patient Distribution

```sql
SELECT
    d.department,
    COUNT(DISTINCT a.patient_phone) AS unique_patients,
    COUNT(a.id) AS total_appointments,
    SUM(d.consultation_fee) AS total_revenue
FROM appointments a
INNER JOIN doctors d ON a.doctor_id = d.id
GROUP BY d.department
ORDER BY unique_patients DESC;
```

### 11.6 Patient Activity Summary

```sql
SELECT
    p.phone_number,
    p.name,
    p.gender,
    COUNT(DISTINCT a.id) AS total_appointments,
    COUNT(DISTINCT rx.id) AS total_prescriptions,
    MIN(a.date) AS first_visit,
    MAX(a.date) AS last_visit,
    COUNT(DISTINCT a.doctor_id) AS doctors_visited
FROM patients p
LEFT JOIN appointments a ON p.phone_number = a.patient_phone
LEFT JOIN prescriptions rx ON p.phone_number = rx.patient_phone
GROUP BY p.phone_number, p.name, p.gender
ORDER BY last_visit DESC;
```

### 11.7 Daily Revenue Report

```sql
SELECT
    a.date,
    COUNT(a.id) AS appointments,
    SUM(d.consultation_fee) AS revenue
FROM appointments a
INNER JOIN doctors d ON a.doctor_id = d.id
GROUP BY a.date
ORDER BY a.date DESC;
```

---

## 12. Indexing Strategy

### 12.1 Primary Indexes (Automatically Created)

| Table | Index | Column(s) |
|-------|-------|-----------|
| `doctors` | Primary Key | `id` |
| `patients` | Primary Key | `phone_number` |
| `sessions` | Primary Key | `id` |
| `appointments` | Primary Key | `id` |
| `prescriptions` | Primary Key | `id` |
| `prescribed_medicines` | Primary Key | `id` |
| `prescription_diagnoses` | Primary Key | `id` |

### 12.2 Foreign Key Indexes

```sql
-- These are created in the DDL above but listed here for clarity
CREATE INDEX idx_appointments_doctor ON appointments(doctor_id);
CREATE INDEX idx_appointments_patient ON appointments(patient_phone);
CREATE INDEX idx_prescriptions_doctor ON prescriptions(doctor_id);
CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_phone);
CREATE INDEX idx_medicines_prescription ON prescribed_medicines(prescription_id);
CREATE INDEX idx_diagnoses_prescription ON prescription_diagnoses(prescription_id);
```

### 12.3 Composite Indexes (Performance Optimization)

```sql
-- Appointment lookups: doctor + date is the most common query pattern
CREATE INDEX idx_appointments_doctor_date ON appointments(doctor_id, date);

-- Patient appointment lookups
CREATE INDEX idx_appointments_patient_date ON appointments(patient_phone, date);

-- Unique constraint doubles as an index for slot availability checks
-- Already defined: UNIQUE KEY uk_doctor_date_slot (doctor_id, date, time_slot)

-- Prescription lookups by doctor (sorted by issued_at)
CREATE INDEX idx_prescriptions_doctor_issued ON prescriptions(doctor_id, issued_at DESC);

-- Prescription lookups by patient (sorted by issued_at)
CREATE INDEX idx_prescriptions_patient_issued ON prescriptions(patient_phone, issued_at DESC);

-- Session validation — check active sessions by user type + identifier
CREATE INDEX idx_sessions_user_active ON sessions(user_type, user_identifier, is_active, expires_at);

-- Date-based queries for appointment filtering
CREATE INDEX idx_appointments_date ON appointments(date);

-- Department search for doctors
CREATE INDEX idx_doctors_department ON doctors(department);
```

### 12.4 Index Recommendations Summary

| Query Pattern | Recommended Index | Priority |
|---|---|---|
| Doctor's appointments for a date | `(doctor_id, date)` | **HIGH** — used on every booking |
| Patient's appointments | `(patient_phone, date)` | **HIGH** — used on dashboard |
| Slot availability check | `(doctor_id, date, time_slot)` UNIQUE | **HIGH** — prevents double booking |
| Patient prescriptions | `(patient_phone, issued_at DESC)` | **MEDIUM** — prescription list |
| Doctor prescriptions | `(doctor_id, issued_at DESC)` | **MEDIUM** — patient records |
| Session validation | `(user_type, user_identifier, is_active)` | **HIGH** — checked on every app start |
| Department filter | `(department)` | **LOW** — only 20 doctors |
| Full-text name search | Consider `FULLTEXT` index on `doctors.name` | **LOW** |

---

## 13. Views (Virtual Tables)

### 13.1 Active Appointments View

```sql
CREATE VIEW v_active_appointments AS
SELECT
    a.id,
    a.doctor_id,
    a.doctor_name,
    a.patient_phone,
    a.patient_name,
    a.date,
    a.time_slot,
    a.serial_number,
    a.status,
    d.department,
    d.designation,
    d.room_number,
    d.consultation_fee
FROM appointments a
INNER JOIN doctors d ON a.doctor_id = d.id
WHERE a.date >= CURDATE();
```

### 13.2 Prescription Summary View

```sql
CREATE VIEW v_prescription_summary AS
SELECT
    p.id,
    p.doctor_id,
    p.doctor_name,
    p.doctor_department,
    p.patient_phone,
    p.patient_name,
    p.appointment_date,
    p.issued_at,
    p.pdf_path,
    COUNT(DISTINCT pm.id) AS medicine_count,
    COUNT(DISTINCT pd.id) AS diagnosis_count
FROM prescriptions p
LEFT JOIN prescribed_medicines pm ON p.id = pm.prescription_id
LEFT JOIN prescription_diagnoses pd ON p.id = pd.prescription_id
GROUP BY p.id;
```

### 13.3 Doctor Dashboard Stats View

```sql
CREATE VIEW v_doctor_stats AS
SELECT
    d.id AS doctor_id,
    d.name AS doctor_name,
    d.department,
    COUNT(DISTINCT a_up.id) AS upcoming_appointments,
    COUNT(DISTINCT a_prev.id) AS completed_appointments,
    COUNT(DISTINCT rx.id) AS total_prescriptions,
    COUNT(DISTINCT COALESCE(a_up.patient_phone, a_prev.patient_phone, rx.patient_phone)) AS unique_patients
FROM doctors d
LEFT JOIN appointments a_up ON d.id = a_up.doctor_id AND a_up.date >= CURDATE()
LEFT JOIN appointments a_prev ON d.id = a_prev.doctor_id AND a_prev.date < CURDATE()
LEFT JOIN prescriptions rx ON d.id = rx.doctor_id
GROUP BY d.id, d.name, d.department;
```

---

## 14. Stored Procedures & Functions

### 14.1 Book Appointment (Transaction)

```sql
DELIMITER //
CREATE PROCEDURE sp_book_appointment(
    IN p_doctor_id VARCHAR(10),
    IN p_doctor_name VARCHAR(100),
    IN p_patient_phone VARCHAR(15),
    IN p_patient_name VARCHAR(100),
    IN p_date VARCHAR(10),
    IN p_time_slot VARCHAR(10),
    OUT p_serial_number INT,
    OUT p_success BOOLEAN
)
BEGIN
    DECLARE v_next_serial INT;
    DECLARE v_slot_exists INT;

    -- Start transaction
    START TRANSACTION;

    -- Check if slot is already booked
    SELECT COUNT(*) INTO v_slot_exists
    FROM appointments
    WHERE doctor_id = p_doctor_id
      AND date = p_date
      AND time_slot = p_time_slot;

    IF v_slot_exists > 0 THEN
        SET p_success = FALSE;
        SET p_serial_number = 0;
        ROLLBACK;
    ELSE
        -- Get next serial number
        SELECT COALESCE(MAX(serial_number), 0) + 1 INTO v_next_serial
        FROM appointments
        WHERE doctor_id = p_doctor_id
          AND date = p_date;

        -- Insert appointment
        INSERT INTO appointments (doctor_id, doctor_name, patient_phone, patient_name,
                                 date, time_slot, serial_number, status)
        VALUES (p_doctor_id, p_doctor_name, p_patient_phone, p_patient_name,
                p_date, p_time_slot, v_next_serial, 'Confirmed');

        SET p_serial_number = v_next_serial;
        SET p_success = TRUE;
        COMMIT;
    END IF;
END //
DELIMITER ;

-- Usage:
-- CALL sp_book_appointment('DOC001', 'Dr. Md. Kamal Hossain', '01712345678', 'Rahim', '2026-03-15', '09:00 AM', @serial, @success);
-- SELECT @serial, @success;
```

### 14.2 Create Prescription (Transaction)

```sql
DELIMITER //
CREATE PROCEDURE sp_create_prescription(
    IN p_id VARCHAR(30),
    IN p_doctor_id VARCHAR(10),
    IN p_doctor_name VARCHAR(100),
    IN p_doctor_department VARCHAR(50),
    IN p_doctor_designation VARCHAR(100),
    IN p_doctor_degrees VARCHAR(200),
    IN p_patient_phone VARCHAR(15),
    IN p_patient_name VARCHAR(100),
    IN p_appointment_date VARCHAR(10),
    IN p_issued_at VARCHAR(30),
    IN p_additional_notes TEXT,
    IN p_pdf_path VARCHAR(500),
    IN p_diagnoses JSON,
    IN p_medicines JSON
)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE diag_count INT;
    DECLARE med_count INT;

    START TRANSACTION;

    -- 1. Insert prescription record
    INSERT INTO prescriptions (id, doctor_id, doctor_name, doctor_department,
                              doctor_designation, doctor_degrees, patient_phone,
                              patient_name, appointment_date, issued_at,
                              additional_notes, pdf_path)
    VALUES (p_id, p_doctor_id, p_doctor_name, p_doctor_department,
            p_doctor_designation, p_doctor_degrees, p_patient_phone,
            p_patient_name, p_appointment_date, p_issued_at,
            p_additional_notes, p_pdf_path);

    -- 2. Insert diagnoses from JSON array
    SET diag_count = JSON_LENGTH(p_diagnoses);
    SET i = 0;
    WHILE i < diag_count DO
        INSERT INTO prescription_diagnoses (prescription_id, diagnosis_text, sort_order)
        VALUES (p_id, JSON_UNQUOTE(JSON_EXTRACT(p_diagnoses, CONCAT('$[', i, ']'))), i);
        SET i = i + 1;
    END WHILE;

    -- 3. Insert medicines from JSON array of objects
    SET med_count = JSON_LENGTH(p_medicines);
    SET i = 0;
    WHILE i < med_count DO
        INSERT INTO prescribed_medicines (prescription_id, name, dosage, frequency, duration, notes)
        VALUES (
            p_id,
            JSON_UNQUOTE(JSON_EXTRACT(p_medicines, CONCAT('$[', i, '].name'))),
            JSON_UNQUOTE(JSON_EXTRACT(p_medicines, CONCAT('$[', i, '].dosage'))),
            JSON_UNQUOTE(JSON_EXTRACT(p_medicines, CONCAT('$[', i, '].frequency'))),
            JSON_UNQUOTE(JSON_EXTRACT(p_medicines, CONCAT('$[', i, '].duration'))),
            JSON_UNQUOTE(JSON_EXTRACT(p_medicines, CONCAT('$[', i, '].notes')))
        );
        SET i = i + 1;
    END WHILE;

    -- 4. Remove the completed appointment
    DELETE FROM appointments
    WHERE doctor_id = p_doctor_id
      AND patient_phone = p_patient_phone
      AND date = p_appointment_date;

    COMMIT;
END //
DELIMITER ;

-- Usage:
-- CALL sp_create_prescription(
--     'RX1709901234567', 'DOC001', 'Dr. Md. Kamal Hossain', 'Cardiology',
--     'Senior Consultant', 'MBBS, MD, DM (Cardiology)', '01712345678', 'Rahim Uddin',
--     '2026-03-15', '2026-03-15T10:30:00.000', 'Follow up in 2 weeks',
--     '/path/to/pdf.pdf',
--     '["Hypertension Stage 2", "Hyperlipidemia"]',
--     '[{"name":"Amlodipine","dosage":"5mg","frequency":"Once daily","duration":"30 days","notes":"Morning"}]'
-- );
```

### 14.3 Clean Up Expired Sessions

```sql
DELIMITER //
CREATE PROCEDURE sp_cleanup_expired_sessions()
BEGIN
    DELETE FROM sessions
    WHERE expires_at < NOW()
       OR is_active = FALSE;
END //
DELIMITER ;

-- Schedule as an event:
CREATE EVENT IF NOT EXISTS ev_cleanup_sessions
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO CALL sp_cleanup_expired_sessions();
```

### 14.4 Get Doctor Availability Function

```sql
DELIMITER //
CREATE FUNCTION fn_get_available_slots(
    p_doctor_id VARCHAR(10),
    p_date VARCHAR(10)
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE booked INT;

    SELECT COUNT(*) INTO booked
    FROM appointments
    WHERE doctor_id = p_doctor_id
      AND date = p_date;

    -- 48 total slots per day (32 morning + 16 afternoon, 15-min intervals)
    RETURN 48 - booked;
END //
DELIMITER ;

-- Usage:
-- SELECT fn_get_available_slots('DOC001', '2026-03-15');
```

---

## Quick Reference: Relationship Summary

```
┌───────────────────────────────────────────────────────────────────┐
│                    RELATIONSHIP MAP                               │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  doctors (1) ──────< (N) appointments (N) >────── (1) patients   │
│     │                                                    │        │
│     │  One-to-Many                        One-to-Many    │        │
│     │                                                    │        │
│  doctors (1) ──────< (N) prescriptions (N) >───── (1) patients   │
│                            │                                      │
│                     ┌──────┴───────┐                              │
│                     │              │                               │
│              (1)    │       (1)    │                               │
│                ▼    │          ▼   │                               │
│       (N) prescribed│  (N) prescription                           │
│           _medicines│      _diagnoses                             │
│                                                                   │
│  ═══════════════════════════════════════════                      │
│  doctors ↔ patients : Many-to-Many (via appointments)            │
│  doctors ↔ patients : Many-to-Many (via prescriptions)           │
│  prescriptions → medicines : One-to-Many (CASCADE delete)        │
│  prescriptions → diagnoses : One-to-Many (CASCADE delete)        │
└───────────────────────────────────────────────────────────────────┘
```

---

> **End of SQL Query Reference Documentation**
