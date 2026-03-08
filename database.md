# Care People — Complete Database Architecture

> **Version:** 1.0  
> **Last Updated:** March 8, 2026  
> **Project:** Care People — Hospital Management & Patient Portal (Flutter)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Current Storage Architecture](#2-current-storage-architecture)
3. [Proposed Relational Database Schema](#3-proposed-relational-database-schema)
4. [Table Definitions](#4-table-definitions)
   - 4.1 [doctors](#41-doctors)
   - 4.2 [patients](#42-patients)
   - 4.3 [sessions](#43-sessions)
   - 4.4 [appointments](#44-appointments)
   - 4.5 [prescriptions](#45-prescriptions)
   - 4.6 [prescribed_medicines](#46-prescribed_medicines)
   - 4.7 [prescription_diagnoses](#47-prescription_diagnoses)
5. [Entity-Relationship Diagram (ERD)](#5-entity-relationship-diagram-erd)
6. [Table Relationships](#6-table-relationships)
7. [Database Flow — How Data Moves Through the System](#7-database-flow--how-data-moves-through-the-system)
   - 7.1 [User Registration & Authentication Flow](#71-user-registration--authentication-flow)
   - 7.2 [Appointment Booking Flow](#72-appointment-booking-flow)
   - 7.3 [Prescription Creation Flow](#73-prescription-creation-flow)
   - 7.4 [Data Retrieval Flows](#74-data-retrieval-flows)
8. [Constraints & Business Rules](#8-constraints--business-rules)
9. [Migration Path — JSON to SQL](#9-migration-path--json-to-sql)

---

## 1. Overview

**Care People** is a Flutter-based hospital management application with two primary user roles:

| Role | Description |
|------|-------------|
| **Patient** | Registers via phone number + OTP, manages profile, books appointments, views prescriptions |
| **Doctor** | Logs in with Doctor ID + Password, views appointments, writes prescriptions, manages patient records |

The system currently uses **local JSON file storage** (`SharedPreferences` for sessions and JSON files in the application documents directory for persistent data). This document maps the **current data structures** to a proper **relational database schema** for production use.

---

## 2. Current Storage Architecture

The app currently stores data in the following locations:

| Storage Layer | File / Mechanism | Purpose |
|---|---|---|
| `assets/data/doctors.json` | Bundled asset (read-only) | Doctor master data (20 doctors with credentials) |
| `assets/data/dummy_schedule.json` | Bundled asset (read-only) | Empty appointment template |
| `SharedPreferences` | Key-value store | Patient & Doctor session management |
| `{app_docs}/users.json` | Local JSON file | Patient profile data (keyed by phone number) |
| `{app_docs}/appointments.json` | Local JSON file | All appointment records |
| `{app_docs}/prescriptions.json` | Local JSON file | All prescription records |
| `{app_docs}/*.pdf` | Local PDF files | Generated prescription PDFs |

### Current Data Models (from Dart code):

- **`Doctor`** — defined in `lib/models/appointment_models.dart`
- **`Appointment`** — defined in `lib/models/appointment_models.dart`
- **`Prescription`** — defined in `lib/services/prescription_service.dart`
- **`PrescribedMedicine`** — defined in `lib/services/prescription_service.dart`
- **Patient (User)** — stored as a Map in `UserStorageService`
- **Session** — stored via `SessionService` in `SharedPreferences`

---

## 3. Proposed Relational Database Schema

Below is the normalized relational database schema that maps all existing data structures into a proper SQL database (PostgreSQL/MySQL compatible).

### Schema Diagram (Text)

```
┌─────────────┐       ┌──────────────────┐       ┌─────────────────┐
│   doctors    │       │   appointments   │       │    patients     │
├─────────────┤       ├──────────────────┤       ├─────────────────┤
│ id (PK)     │◄──────│ doctor_id (FK)   │───────►│ phone_number(PK)│
│ name        │       │ patient_phone(FK)│       │ name            │
│ department  │       │ date             │       │ date_of_birth   │
│ designation │       │ time_slot        │       │ address         │
│ degrees     │       │ serial_number    │       │ gender          │
│ room_number │       │ status           │       │ created_at      │
│ consult_fee │       └──────────────────┘       │ updated_at      │
│ consult_days│                                   └─────────────────┘
│ consult_time│       ┌──────────────────┐              │
│ password    │       │  prescriptions   │              │
└─────────────┘       ├──────────────────┤              │
       │              │ id (PK)          │              │
       └──────────────│ doctor_id (FK)   │              │
                      │ patient_phone(FK)│──────────────┘
                      │ appointment_date │
                      │ issued_at        │
                      │ additional_notes │
                      │ pdf_path         │
                      └──────┬───────────┘
                             │
              ┌──────────────┼──────────────┐
              │                             │
   ┌──────────▼─────────┐     ┌─────────────▼────────┐
   │prescribed_medicines │     │prescription_diagnoses │
   ├────────────────────┤     ├──────────────────────┤
   │ id (PK)            │     │ id (PK)              │
   │ prescription_id(FK)│     │ prescription_id (FK) │
   │ name               │     │ diagnosis_text       │
   │ dosage             │     └──────────────────────┘
   │ frequency          │
   │ duration           │
   │ notes              │
   └────────────────────┘

   ┌──────────────────┐
   │    sessions       │
   ├──────────────────┤
   │ id (PK)          │
   │ user_type        │
   │ user_identifier  │
   │ session_data     │
   │ login_timestamp  │
   │ expires_at       │
   │ is_active        │
   └──────────────────┘
```

---

## 4. Table Definitions

### 4.1 `doctors`

**Purpose:** Stores all doctor information. This is the master table for medical professionals registered in the hospital system. Currently loaded from `assets/data/doctors.json`.

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| `id` | `VARCHAR(10)` | `PRIMARY KEY` | Unique doctor identifier (e.g., "DOC001") |
| `name` | `VARCHAR(100)` | `NOT NULL` | Full name with title (e.g., "Dr. Md. Kamal Hossain") |
| `department` | `VARCHAR(50)` | `NOT NULL` | Medical department (e.g., "Cardiology", "Neurology") |
| `designation` | `VARCHAR(100)` | `NOT NULL` | Professional title (e.g., "Senior Consultant") |
| `degrees` | `VARCHAR(200)` | `NOT NULL` | Academic qualifications (e.g., "MBBS, MD, DM (Cardiology)") |
| `room_number` | `VARCHAR(10)` | `NOT NULL` | Consultation room (e.g., "301") |
| `consultation_fee` | `DECIMAL(10,2)` | `NOT NULL, CHECK(consultation_fee >= 0)` | Fee in BDT (e.g., 1500.00) |
| `consultation_days` | `JSON` / `TEXT` | `NOT NULL` | Array of weekday names (e.g., `["Monday","Tuesday"]`) |
| `consultation_times` | `VARCHAR(100)` | `NOT NULL` | Time range string (e.g., "09:00 AM - 01:00 PM, 03:00 PM - 06:00 PM") |
| `password` | `VARCHAR(255)` | `NOT NULL` | Hashed password for doctor login |
| `created_at` | `TIMESTAMP` | `DEFAULT CURRENT_TIMESTAMP` | Record creation timestamp |
| `updated_at` | `TIMESTAMP` | `DEFAULT CURRENT_TIMESTAMP ON UPDATE` | Last modification timestamp |

**Notes:**
- 20 doctors are seeded from the JSON asset file.
- `consultation_days` stores a JSON array of day names.
- In production, `password` should be stored as a **bcrypt hash**, not plain text.

---

### 4.2 `patients`

**Purpose:** Stores registered patient profile information. Patients are uniquely identified by their phone number. Data is created during the signup process after OTP verification.

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| `phone_number` | `VARCHAR(15)` | `PRIMARY KEY` | 11-digit Bangladeshi phone number (unique identifier) |
| `name` | `VARCHAR(100)` | `NOT NULL` | Patient full name |
| `date_of_birth` | `VARCHAR(20)` | `NOT NULL` | Date of birth in "dd/MM/yyyy" format |
| `address` | `TEXT` | `NOT NULL` | Full residential address (min 10 characters) |
| `gender` | `ENUM('Male','Female','Other')` | `NOT NULL, DEFAULT 'Male'` | Patient gender |
| `created_at` | `TIMESTAMP` | `DEFAULT CURRENT_TIMESTAMP` | Account creation timestamp (ISO-8601) |
| `updated_at` | `TIMESTAMP` | `NULL` | Last profile update timestamp |

**Notes:**
- Phone number serves as both the primary key and login identifier.
- Currently stored in `users.json` keyed by phone number.
- The `UserStorageService` handles CRUD operations for this entity.

---

### 4.3 `sessions`

**Purpose:** Manages authentication sessions for both patients and doctors. Sessions expire after 2 days. Currently implemented via `SharedPreferences` in `SessionService`.

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| `id` | `INT` / `BIGINT` | `PRIMARY KEY, AUTO_INCREMENT` | Unique session identifier |
| `user_type` | `ENUM('patient','doctor')` | `NOT NULL` | Type of user this session belongs to |
| `user_identifier` | `VARCHAR(15)` | `NOT NULL` | Phone number (patient) or Doctor ID (doctor) |
| `session_data` | `JSON` / `TEXT` | `NULL` | Additional session data (doctor data stored as JSON for doctor sessions) |
| `login_timestamp` | `BIGINT` | `NOT NULL` | Login time in milliseconds since epoch |
| `expires_at` | `TIMESTAMP` | `NOT NULL` | Session expiry (login_timestamp + 2 days) |
| `is_active` | `BOOLEAN` | `NOT NULL, DEFAULT TRUE` | Whether session is currently active |
| `created_at` | `TIMESTAMP` | `DEFAULT CURRENT_TIMESTAMP` | Record creation timestamp |

**Notes:**
- Session duration is fixed at **2 days** (`_sessionDurationDays = 2`).
- Patient sessions store: `isLoggedIn`, `phoneNumber`, `loginTimestamp`.
- Doctor sessions store: `doctorIsLoggedIn`, `doctorId`, `doctorData` (full JSON), `doctorLoginTimestamp`.
- On app launch, the system checks doctor session first, then patient session.

---

### 4.4 `appointments`

**Purpose:** Stores all booked appointments between patients and doctors. Each appointment represents a specific time slot on a specific date with a doctor. Managed by `AppointmentService`.

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| `id` | `INT` / `BIGINT` | `PRIMARY KEY, AUTO_INCREMENT` | Unique appointment identifier |
| `doctor_id` | `VARCHAR(10)` | `NOT NULL, FOREIGN KEY → doctors(id)` | Reference to the doctor |
| `doctor_name` | `VARCHAR(100)` | `NOT NULL` | Denormalized doctor name for display |
| `patient_phone` | `VARCHAR(15)` | `NOT NULL, FOREIGN KEY → patients(phone_number)` | Reference to the patient |
| `patient_name` | `VARCHAR(100)` | `NOT NULL` | Denormalized patient name for display |
| `date` | `VARCHAR(10)` | `NOT NULL` | Appointment date in "yyyy-MM-dd" format |
| `time_slot` | `VARCHAR(10)` | `NOT NULL` | Time slot string (e.g., "09:00 AM", "02:30 PM") |
| `serial_number` | `INT` | `NOT NULL, CHECK(serial_number > 0)` | Auto-incremented serial per doctor per date |
| `status` | `VARCHAR(20)` | `NOT NULL, DEFAULT 'Confirmed'` | Appointment status ("Confirmed", etc.) |
| `created_at` | `TIMESTAMP` | `DEFAULT CURRENT_TIMESTAMP` | Booking creation timestamp |

**Unique Constraint:** `UNIQUE(doctor_id, date, time_slot)` — prevents double-booking the same slot.

**Notes:**
- Time slots are generated in 15-minute intervals: Morning (9:00 AM – 12:45 PM), Afternoon (2:00 PM – 5:45 PM).
- Serial numbers are auto-calculated per doctor per date (highest serial + 1).
- `doctor_name` and `patient_name` are denormalized for performance.
- Appointments are removed after a prescription is generated for them.
- Currently stored in `appointments.json`.

---

### 4.5 `prescriptions`

**Purpose:** Stores prescription records generated by doctors for patients. Each prescription is linked to a specific appointment and contains diagnosis and medicine details. A PDF file is generated and stored alongside.

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| `id` | `VARCHAR(30)` | `PRIMARY KEY` | Unique ID — format "RX{timestamp_ms}" (e.g., "RX1709901234567") |
| `doctor_id` | `VARCHAR(10)` | `NOT NULL, FOREIGN KEY → doctors(id)` | Reference to prescribing doctor |
| `doctor_name` | `VARCHAR(100)` | `NOT NULL` | Denormalized doctor name |
| `doctor_department` | `VARCHAR(50)` | `NOT NULL` | Denormalized department |
| `doctor_designation` | `VARCHAR(100)` | `NOT NULL` | Denormalized designation |
| `doctor_degrees` | `VARCHAR(200)` | `NOT NULL` | Denormalized degrees |
| `patient_phone` | `VARCHAR(15)` | `NOT NULL, FOREIGN KEY → patients(phone_number)` | Reference to the patient |
| `patient_name` | `VARCHAR(100)` | `NOT NULL` | Denormalized patient name |
| `appointment_date` | `VARCHAR(10)` | `NOT NULL` | Date of the appointment in "yyyy-MM-dd" format |
| `issued_at` | `VARCHAR(30)` | `NOT NULL` | Prescription creation timestamp (ISO-8601 string) |
| `additional_notes` | `TEXT` | `NULL` | Optional free-text doctor notes |
| `pdf_path` | `VARCHAR(500)` | `NOT NULL` | File system path to the generated PDF |
| `created_at` | `TIMESTAMP` | `DEFAULT CURRENT_TIMESTAMP` | Record creation timestamp |

**Notes:**
- Prescription ID is timestamp-based: `RX${DateTime.now().millisecondsSinceEpoch}`.
- Doctor fields are denormalized to preserve the doctor's info at the time of prescription.
- Diagnoses and medicines are stored in separate child tables (normalized).
- The PDF is generated using the `pdf` Flutter package and stored locally.
- Currently stored in `prescriptions.json`.

---

### 4.6 `prescribed_medicines`

**Purpose:** Stores individual medicine entries within a prescription. Each prescription can have multiple medicines (one-to-many relationship).

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| `id` | `INT` / `BIGINT` | `PRIMARY KEY, AUTO_INCREMENT` | Unique medicine entry ID |
| `prescription_id` | `VARCHAR(30)` | `NOT NULL, FOREIGN KEY → prescriptions(id) ON DELETE CASCADE` | Parent prescription |
| `name` | `VARCHAR(200)` | `NOT NULL` | Medicine name |
| `dosage` | `VARCHAR(100)` | `NOT NULL` | Dosage amount (e.g., "500mg", "10ml") |
| `frequency` | `VARCHAR(100)` | `NOT NULL` | Intake frequency (e.g., "3 times daily", "After meals") |
| `duration` | `VARCHAR(100)` | `NOT NULL` | Duration of intake (e.g., "7 days", "2 weeks") |
| `notes` | `TEXT` | `NULL` | Optional notes for this medicine |

**Notes:**
- Defined as the `PrescribedMedicine` class in `prescription_service.dart`.
- At least one medicine is required per prescription (validated in UI).
- Cascading delete ensures medicines are removed with their prescription.

---

### 4.7 `prescription_diagnoses`

**Purpose:** Stores individual diagnosis entries for a prescription. Each prescription can have multiple diagnoses (one-to-many relationship).

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| `id` | `INT` / `BIGINT` | `PRIMARY KEY, AUTO_INCREMENT` | Unique diagnosis entry ID |
| `prescription_id` | `VARCHAR(30)` | `NOT NULL, FOREIGN KEY → prescriptions(id) ON DELETE CASCADE` | Parent prescription |
| `diagnosis_text` | `TEXT` | `NOT NULL` | Diagnosis description |
| `sort_order` | `INT` | `DEFAULT 0` | Display order of the diagnosis |

**Notes:**
- Diagnoses are stored as a `List<String>` in the Dart model, normalized here into a separate table.
- At least one diagnosis is required per prescription (validated in UI).

---

## 5. Entity-Relationship Diagram (ERD)

```
                          ┌──────────────┐
                          │   doctors    │
                          │──────────────│
                          │ PK: id       │
                          └──────┬───────┘
                                 │
                    ┌────────────┼────────────┐
                    │ 1          │ 1           │
                    │            │             │
                    ▼ *          ▼ *           │
          ┌──────────────┐  ┌─────────────┐   │
          │ appointments │  │prescriptions│   │
          │──────────────│  │─────────────│   │
          │ FK: doctor_id│  │FK: doctor_id│   │
          │ FK: pat_phone│  │FK: pat_phone│   │
          └──────┬───────┘  └──────┬──────┘   │
                 │                 │           │
                 │            ┌────┼────┐      │
                 │            │         │      │
                 │            ▼ *       ▼ *    │
                 │   ┌────────────┐ ┌────────────────────┐
                 │   │ prescribed │ │ prescription       │
                 │   │ _medicines │ │ _diagnoses         │
                 │   └────────────┘ └────────────────────┘
                 │
                 ▼
          ┌──────────────┐
          │   patients   │
          │──────────────│
          │PK: phone_num │
          └──────────────┘
```

**Cardinalities:**
- **Doctor → Appointments**: One-to-Many (1:N)
- **Patient → Appointments**: One-to-Many (1:N)
- **Doctor → Prescriptions**: One-to-Many (1:N)
- **Patient → Prescriptions**: One-to-Many (1:N)
- **Prescription → Prescribed Medicines**: One-to-Many (1:N)
- **Prescription → Prescription Diagnoses**: One-to-Many (1:N)
- **Doctor ↔ Patient**: Many-to-Many (M:N) — through appointments and prescriptions

---

## 6. Table Relationships

| Relationship | Type | Description |
|---|---|---|
| `doctors` → `appointments` | **One-to-Many** | A doctor can have many appointments |
| `patients` → `appointments` | **One-to-Many** | A patient can book many appointments |
| `doctors` → `prescriptions` | **One-to-Many** | A doctor can write many prescriptions |
| `patients` → `prescriptions` | **One-to-Many** | A patient can have many prescriptions |
| `prescriptions` → `prescribed_medicines` | **One-to-Many** | Each prescription has multiple medicines |
| `prescriptions` → `prescription_diagnoses` | **One-to-Many** | Each prescription has multiple diagnoses |
| `doctors` ↔ `patients` (via `appointments`) | **Many-to-Many** | A doctor treats many patients; a patient visits many doctors |
| `doctors` ↔ `patients` (via `prescriptions`) | **Many-to-Many** | Same M:N relationship through prescription records |

---

## 7. Database Flow — How Data Moves Through the System

### 7.1 User Registration & Authentication Flow

#### Patient Registration Flow

```
1. Patient opens app → SplashPage → IdentificationPage
2. Patient selects "I am Patient" → PatientLoginPage
3. Patient enters 11-digit phone number
4. System generates 6-digit OTP (client-side Random.secure())
5. Patient navigates to PatientOtpPage with phone + OTP
6. Patient enters OTP → Verification:
   ├─ OTP matches:
   │   ├─ SessionService.saveSession(phoneNumber) → saves to SharedPreferences
   │   │   - Sets isLoggedIn = true
   │   │   - Stores phoneNumber
   │   │   - Stores loginTimestamp (epoch ms)
   │   │
   │   ├─ UserStorageService.userExists(phone)?
   │   │   ├─ YES → Navigate to PatientDashboard
   │   │   └─ NO  → Navigate to PatientSignupPage
   │   │            └─ User fills: name, dateOfBirth, address, gender
   │   │            └─ UserStorageService.saveUser() → writes to users.json
   │   │            └─ Navigate to PatientDashboard
   │   │
   └─ OTP does not match:
       └─ Show error, clear OTP fields
```

**Data Written:**
- `sessions` table: new session record
- `patients` table: new patient record (if first-time user)

#### Doctor Authentication Flow

```
1. Doctor selects "I am Doctor" → DoctorLoginPage
2. Doctor enters Doctor ID + Password
3. System loads doctors.json, finds matching ID + password
   ├─ Match found:
   │   ├─ SessionService.saveDoctorSession(doctorData) → SharedPreferences
   │   │   - Sets doctorIsLoggedIn = true
   │   │   - Stores doctorId, doctorData (full JSON), doctorLoginTimestamp
   │   └─ Navigate to DoctorDashboard
   │
   └─ No match:
       └─ Show "Invalid Doctor ID or Password" error
```

**Data Read:** `doctors` table (or doctors.json asset)
**Data Written:** `sessions` table: new doctor session record

#### Session Validation (App Startup)

```
1. App starts → AuthenticationWrapper
2. Check isDoctorSessionActive():
   ├─ Active (< 2 days) → Load doctorData → DoctorDashboard
   └─ Expired → clearDoctorSession()
3. Check isSessionActive() (patient):
   ├─ Active (< 2 days) → Load phoneNumber → PatientDashboard
   └─ Expired → clearSession()
4. Neither active → Show SplashPage
```

### 7.2 Appointment Booking Flow

```
1. Patient on Dashboard → "Book Appointment" → BookAppointmentPage
2. System loads all doctors from doctors.json → AppointmentService.loadDoctors()
3. System loads patient data → UserStorageService.getUserData(phone)
4. Patient filters/searches doctors by department or name
5. Patient selects a doctor → Views doctor profile (optional)
6. Patient selects a date (must be consultation day of selected doctor)
7. System checks booked slots → AppointmentService.getBookedTimeSlotsForDate(doctorId, date)
8. Patient selects available time slot (15-min intervals)
9. System generates serial number → AppointmentService.getNextSerialNumber(doctorId, date)
10. System creates Appointment object:
    {
      doctorId, doctorName, patientPhone, patientName,
      date, timeSlot, serialNumber, status: "Confirmed"
    }
11. AppointmentService.saveAppointment() → Reads existing appointments.json,
    appends new appointment, writes back to file
```

**Data Read:** `doctors`, `appointments`, `patients`
**Data Written:** `appointments` table: new appointment record

### 7.3 Prescription Creation Flow

```
1. Doctor on Dashboard → "Write Prescription" → WritePrescriptionPage
2. Step 0 — Select Patient:
   └─ Load doctor's appointments → AppointmentService.getDoctorAppointments(doctorId)
   └─ Filter to upcoming/today appointments only
   └─ Doctor selects an appointment (patient)

3. Step 1 — Diagnosis & Medicines:
   └─ Doctor adds diagnoses (free text, multiple entries)
   └─ Doctor adds medicines:
       - Name, Dosage, Frequency, Duration, Notes (optional)
       - Multiple medicines can be added
   └─ Optional: Additional notes (free text)

4. Step 2 — Review & Generate:
   └─ Doctor reviews all entered data
   └─ Clicks "Generate Prescription"
   └─ PrescriptionService.createPrescription():
       a. Generate ID: "RX{epoch_ms}"
       b. Generate PDF using pdf package → _buildPdf()
       c. Save PDF to: {app_docs}/{RX_id}.pdf
       d. Create Prescription record with all data
       e. Append to prescriptions.json
       f. Return Prescription object
   └─ AppointmentService.removeAppointment() → removes the completed appointment
   └─ Show success dialog with prescription details
```

**Data Read:** `appointments`, `doctors` (from session)
**Data Written:** `prescriptions`, `prescribed_medicines`, `prescription_diagnoses`
**Data Deleted:** `appointments` (the fulfilled appointment is removed)

### 7.4 Data Retrieval Flows

| Action | Service Method | Query Description |
|--------|----------------|-------------------|
| Patient views appointments | `AppointmentService.getPatientAppointments(phone)` | Filter appointments by patientPhone, split into upcoming/previous by date |
| Doctor views appointments | `AppointmentService.getDoctorAppointments(doctorId)` | Filter appointments by doctorId, split into upcoming/previous by date |
| Patient views prescriptions | `PrescriptionService.getPatientPrescriptions(phone)` | Filter prescriptions by patientPhone, sort by issuedAt DESC |
| Doctor views prescriptions | `PrescriptionService.getDoctorPrescriptions(doctorId)` | Filter prescriptions by doctorId, sort by issuedAt DESC |
| Doctor views patient records | Load both appointments + prescriptions for doctorId, group by patientPhone | Combined view of all patient interactions |
| Check booked time slots | `AppointmentService.getBookedTimeSlotsForDate(doctorId, date)` | Filter appointments by doctor + date, return time_slot list |
| Get next serial number | `AppointmentService.getNextSerialNumber(doctorId, date)` | Find MAX(serial_number) for doctor+date, return +1 |
| Patient profile edit | `UserStorageService.getUserData(phone)` + `saveUser()` | Read and update patient record |

---

## 8. Constraints & Business Rules

### Data Validation Rules

| Rule | Implementation |
|---|---|
| Phone number must be exactly 11 digits | Validated in `PatientLoginPage` UI |
| Patient name must be ≥ 3 characters | Validated in `PatientSignupPage` form |
| Patient address must be ≥ 10 characters | Validated in `PatientSignupPage` form |
| Gender must be Male, Female, or Other | Dropdown selection in UI |
| OTP must be exactly 6 digits | Validated in `PatientOtpPage` UI |
| Doctor ID must match existing record | Verified against `doctors.json` |
| Password must match doctor's password | Verified against `doctors.json` |
| Appointment date must be a consultation day | Filtered by `consultationDays` |
| Appointment date must be in the future | Date picker `firstDate` is tomorrow |
| Time slot must not be already booked | Checked via `getBookedTimeSlotsForDate()` |
| At least 1 diagnosis required per prescription | Validated in `WritePrescriptionPage` |
| At least 1 medicine required per prescription | Validated in `WritePrescriptionPage` |
| Medicine must have name, dosage, frequency, duration | Validated in `_addMedicine()` |
| Session expires after 2 days | Checked in `isSessionActive()` / `isDoctorSessionActive()` |
| Consultation fee must be ≥ 0 | Data constraint |

### Database-Level Constraints

```sql
-- Unique constraint: prevent double-booking
UNIQUE (doctor_id, date, time_slot) ON appointments

-- Foreign keys with referential integrity
FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE RESTRICT
FOREIGN KEY (patient_phone) REFERENCES patients(phone_number) ON DELETE RESTRICT

-- Cascading deletes for child records
FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON DELETE CASCADE
  -- Applied to: prescribed_medicines, prescription_diagnoses

-- Check constraints
CHECK (serial_number > 0) ON appointments
CHECK (consultation_fee >= 0) ON doctors
CHECK (gender IN ('Male', 'Female', 'Other')) ON patients
CHECK (user_type IN ('patient', 'doctor')) ON sessions
```

---

## 9. Migration Path — JSON to SQL

When migrating from the current local JSON storage to a relational database:

### Step 1: Seed Doctors Table
```
Read doctors.json → INSERT INTO doctors for each doctor
Hash all passwords using bcrypt before inserting
```

### Step 2: Migrate Users
```
Read users.json → For each phone_number key:
  INSERT INTO patients (phone_number, name, date_of_birth, address, gender, created_at)
```

### Step 3: Migrate Appointments
```
Read appointments.json → For each appointment:
  INSERT INTO appointments (doctor_id, doctor_name, patient_phone, patient_name,
                           date, time_slot, serial_number, status)
```

### Step 4: Migrate Prescriptions
```
Read prescriptions.json → For each prescription:
  1. INSERT INTO prescriptions (id, doctor_id, ..., pdf_path)
  2. For each diagnosis string:
     INSERT INTO prescription_diagnoses (prescription_id, diagnosis_text, sort_order)
  3. For each medicine:
     INSERT INTO prescribed_medicines (prescription_id, name, dosage, frequency, duration, notes)
```

### Step 5: Replace Service Layer
```
Replace UserStorageService    → API calls to patients endpoints
Replace AppointmentService    → API calls to appointments endpoints
Replace PrescriptionService   → API calls to prescriptions endpoints
Replace SessionService        → Token-based auth (JWT)
Replace doctors.json loading  → API calls to doctors endpoints
```

---

> **End of Database Architecture Documentation**
