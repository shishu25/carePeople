# Care People — Backend Implementation Guide

> **PostgreSQL + Node.js + Express + Flutter Integration**  
> **Last Updated:** March 8, 2026

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Prerequisites & Setup](#2-prerequisites--setup)
3. [Step 1 — PostgreSQL Database Setup](#3-step-1--postgresql-database-setup)
4. [Step 2 — Node.js Project Setup](#4-step-2--nodejs-project-setup)
5. [Step 3 — Database Connection (pg)](#5-step-3--database-connection-pg)
6. [Step 4 — Create Table Schemas](#6-step-4--create-table-schemas)
7. [Step 5 — Build API Routes](#7-step-5--build-api-routes)
8. [Step 6 — Controller & Query Examples](#8-step-6--controller--query-examples)
9. [Step 7 — Authentication with JWT](#9-step-7--authentication-with-jwt)
10. [Step 8 — Connect Flutter to Backend](#10-step-8--connect-flutter-to-backend)
11. [Step 9 — Replace Local Services](#11-step-9--replace-local-services)
12. [Folder Structure Summary](#12-folder-structure-summary)
13. [Environment Variables](#13-environment-variables)
14. [Quick Command Reference](#14-quick-command-reference)

---

## 1. Architecture Overview

```
┌──────────────────┐        HTTP/REST         ┌──────────────────┐
│   Flutter App    │  ◄────────────────────►   │  Node.js + Express│
│  (Frontend)      │     JSON requests/        │  (Backend API)    │
│                  │     responses             │                   │
└──────────────────┘                           └────────┬─────────┘
                                                        │
                                                        │  pg (node-postgres)
                                                        │
                                               ┌────────▼─────────┐
                                               │   PostgreSQL     │
                                               │   Database       │
                                               └──────────────────┘
```

**What changes:**

| Before (Current) | After (New) |
|---|---|
| `doctors.json` (asset file) | `doctors` table in PostgreSQL |
| `users.json` (local file) | `patients` table in PostgreSQL |
| `appointments.json` (local file) | `appointments` table in PostgreSQL |
| `prescriptions.json` (local file) | `prescriptions` + child tables in PostgreSQL |
| `SharedPreferences` (sessions) | JWT tokens stored in `SharedPreferences` |
| Direct file read/write in Dart | HTTP calls to Node.js REST API |

---

## 2. Prerequisites & Setup

Install these on your machine before starting:

| Tool | Version | Install Command (macOS) |
|---|---|---|
| **Node.js** | v18+ | `brew install node` |
| **PostgreSQL** | v15+ | `brew install postgresql@15` |
| **npm** | comes with Node | — |
| **Postman** (optional) | latest | Download from postman.com |

Start PostgreSQL:

```bash
brew services start postgresql@15
```

---

## 3. Step 1 — PostgreSQL Database Setup

### 3.1 Create the Database

Open terminal and run:

```bash
# Enter PostgreSQL shell
psql postgres

# Inside psql:
CREATE DATABASE care_people;
CREATE USER care_admin WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE care_people TO care_admin;

# Connect to the new database
\c care_people

# Exit
\q
```

### 3.2 Create All Tables

Connect and run the DDL. Create a file called `schema.sql`:

```sql
-- ============================================================
-- Care People — PostgreSQL Schema
-- ============================================================

-- 1. Doctors
CREATE TABLE doctors (
    id                  VARCHAR(10)   PRIMARY KEY,
    name                VARCHAR(100)  NOT NULL,
    department          VARCHAR(50)   NOT NULL,
    designation         VARCHAR(100)  NOT NULL,
    degrees             VARCHAR(200)  NOT NULL,
    room_number         VARCHAR(10)   NOT NULL,
    consultation_fee    DECIMAL(10,2) NOT NULL CHECK (consultation_fee >= 0),
    consultation_days   JSONB         NOT NULL,
    consultation_times  VARCHAR(100)  NOT NULL,
    password            VARCHAR(255)  NOT NULL,
    created_at          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
);

-- 2. Patients
CREATE TABLE patients (
    phone_number    VARCHAR(15)   PRIMARY KEY,
    name            VARCHAR(100)  NOT NULL,
    date_of_birth   VARCHAR(20)   NOT NULL,
    address         TEXT          NOT NULL,
    gender          VARCHAR(10)   NOT NULL DEFAULT 'Male' CHECK (gender IN ('Male','Female','Other')),
    created_at      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP     NULL
);

-- 3. Appointments
CREATE TABLE appointments (
    id              SERIAL        PRIMARY KEY,
    doctor_id       VARCHAR(10)   NOT NULL REFERENCES doctors(id) ON DELETE RESTRICT,
    doctor_name     VARCHAR(100)  NOT NULL,
    patient_phone   VARCHAR(15)   NOT NULL REFERENCES patients(phone_number) ON DELETE RESTRICT,
    patient_name    VARCHAR(100)  NOT NULL,
    date            VARCHAR(10)   NOT NULL,
    time_slot       VARCHAR(10)   NOT NULL,
    serial_number   INT           NOT NULL CHECK (serial_number > 0),
    status          VARCHAR(20)   NOT NULL DEFAULT 'Confirmed',
    created_at      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(doctor_id, date, time_slot)
);

-- 4. Prescriptions
CREATE TABLE prescriptions (
    id                  VARCHAR(30)   PRIMARY KEY,
    doctor_id           VARCHAR(10)   NOT NULL REFERENCES doctors(id),
    doctor_name         VARCHAR(100)  NOT NULL,
    doctor_department   VARCHAR(50)   NOT NULL DEFAULT '',
    doctor_designation  VARCHAR(100)  NOT NULL DEFAULT '',
    doctor_degrees      VARCHAR(200)  NOT NULL DEFAULT '',
    patient_phone       VARCHAR(15)   NOT NULL REFERENCES patients(phone_number),
    patient_name        VARCHAR(100)  NOT NULL,
    appointment_date    VARCHAR(10)   NOT NULL,
    issued_at           VARCHAR(30)   NOT NULL,
    additional_notes    TEXT          NULL,
    pdf_path            VARCHAR(500)  NOT NULL,
    created_at          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
);

-- 5. Prescribed Medicines
CREATE TABLE prescribed_medicines (
    id              SERIAL        PRIMARY KEY,
    prescription_id VARCHAR(30)   NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
    name            VARCHAR(200)  NOT NULL,
    dosage          VARCHAR(100)  NOT NULL,
    frequency       VARCHAR(100)  NOT NULL,
    duration        VARCHAR(100)  NOT NULL,
    notes           TEXT          NULL
);

-- 6. Prescription Diagnoses
CREATE TABLE prescription_diagnoses (
    id              SERIAL        PRIMARY KEY,
    prescription_id VARCHAR(30)   NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
    diagnosis_text  TEXT          NOT NULL,
    sort_order      INT           DEFAULT 0
);

-- ============================================================
-- Indexes
-- ============================================================
CREATE INDEX idx_appointments_doctor_date ON appointments(doctor_id, date);
CREATE INDEX idx_appointments_patient_date ON appointments(patient_phone, date);
CREATE INDEX idx_prescriptions_doctor ON prescriptions(doctor_id, issued_at DESC);
CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_phone, issued_at DESC);
```

Run it:

```bash
psql -U care_admin -d care_people -f schema.sql
```

---

## 4. Step 2 — Node.js Project Setup

### 4.1 Initialize the Project

```bash
# Create backend folder (outside or inside the Flutter project)
mkdir care_people_backend
cd care_people_backend

# Initialize
npm init -y

# Install dependencies
npm install express pg dotenv cors bcrypt jsonwebtoken
npm install --save-dev nodemon
```

| Package | Purpose |
|---|---|
| `express` | Web framework for REST API |
| `pg` | PostgreSQL client for Node.js |
| `dotenv` | Load environment variables from `.env` |
| `cors` | Allow Flutter app to make requests |
| `bcrypt` | Hash doctor passwords |
| `jsonwebtoken` | JWT tokens for authentication |
| `nodemon` | Auto-restart server during development |

### 4.2 Add Scripts to `package.json`

```json
{
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js"
  }
}
```

---

## 5. Step 3 — Database Connection (pg)

Create `src/config/db.js`:

```javascript
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host:     process.env.DB_HOST     || 'localhost',
  port:     process.env.DB_PORT     || 5432,
  database: process.env.DB_NAME     || 'care_people',
  user:     process.env.DB_USER     || 'care_admin',
  password: process.env.DB_PASSWORD || 'your_secure_password',
});

// Test connection on startup
pool.query('SELECT NOW()')
  .then(() => console.log('✅ PostgreSQL connected'))
  .catch(err => console.error('❌ DB connection error:', err.message));

module.exports = pool;
```

---

## 6. Step 4 — Create Table Schemas

Already done in Step 1 via `schema.sql`. Seed the doctors:

Create `seed.sql`:

```sql
INSERT INTO doctors (id, name, department, designation, degrees, room_number, consultation_fee, consultation_days, consultation_times, password)
VALUES
('DOC001', 'Dr. Md. Kamal Hossain', 'Cardiology', 'Senior Consultant', 'MBBS, MD, DM (Cardiology)', '301', 1500.00, '["Monday","Tuesday","Wednesday","Thursday","Saturday"]', '09:00 AM - 01:00 PM, 03:00 PM - 06:00 PM', '$2b$10$HASH_HERE'),
('DOC002', 'Dr. Farhana Rahman', 'Neurology', 'Chief Neurologist', 'MBBS, MD, DM (Neurology)', '405', 1800.00, '["Sunday","Monday","Wednesday","Thursday"]', '10:00 AM - 02:00 PM, 04:00 PM - 07:00 PM', '$2b$10$HASH_HERE');
-- ... add all 20 doctors (see query.md for full list)
-- IMPORTANT: Hash passwords with bcrypt before inserting!
```

To hash passwords, use a quick Node script:

```javascript
// hash_passwords.js
const bcrypt = require('bcrypt');

const passwords = ['Kamal@1234', 'Farhana@1234']; // etc.
passwords.forEach(async (pw) => {
  const hash = await bcrypt.hash(pw, 10);
  console.log(`${pw} => ${hash}`);
});
```

Run: `node hash_passwords.js` → copy hashes into `seed.sql`.

---

## 7. Step 5 — Build API Routes

### 7.1 Entry Point — `src/server.js`

```javascript
const express = require('express');
const cors    = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth',          require('./routes/auth.routes'));
app.use('/api/doctors',       require('./routes/doctor.routes'));
app.use('/api/patients',      require('./routes/patient.routes'));
app.use('/api/appointments',  require('./routes/appointment.routes'));
app.use('/api/prescriptions', require('./routes/prescription.routes'));

// Health check
app.get('/api/health', (req, res) => res.json({ status: 'ok' }));

app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});
```

### 7.2 API Route Files

Every route file follows the same pattern. Here is the full route map:

| Method | Endpoint | Description | Maps to Flutter Service |
|---|---|---|---|
| **Auth** | | | |
| `POST` | `/api/auth/patient/send-otp` | Generate & send OTP | `PatientLoginPage._sendOTP()` |
| `POST` | `/api/auth/patient/verify-otp` | Verify OTP, return JWT | `PatientOtpPage._verifyOTP()` |
| `POST` | `/api/auth/doctor/login` | Doctor login, return JWT | `DoctorLoginPage._handleLogin()` |
| `POST` | `/api/auth/logout` | Invalidate token | `SessionService.clearSession()` |
| **Doctors** | | | |
| `GET` | `/api/doctors` | Get all doctors | `AppointmentService.loadDoctors()` |
| `GET` | `/api/doctors/:id` | Get doctor by ID | Doctor profile |
| `GET` | `/api/doctors/departments` | Get unique departments | `BookAppointmentPage._getDepartments()` |
| **Patients** | | | |
| `GET` | `/api/patients/:phone` | Get patient profile | `UserStorageService.getUserData()` |
| `POST` | `/api/patients` | Register new patient | `UserStorageService.saveUser()` |
| `PUT` | `/api/patients/:phone` | Update patient profile | `UserStorageService.updateUser()` |
| **Appointments** | | | |
| `POST` | `/api/appointments` | Book appointment | `AppointmentService.saveAppointment()` |
| `GET` | `/api/appointments/patient/:phone` | Patient's appointments | `AppointmentService.getPatientAppointments()` |
| `GET` | `/api/appointments/doctor/:id` | Doctor's appointments | `AppointmentService.getDoctorAppointments()` |
| `GET` | `/api/appointments/slots/:doctorId/:date` | Booked slots for date | `AppointmentService.getBookedTimeSlotsForDate()` |
| `GET` | `/api/appointments/serial/:doctorId/:date` | Next serial number | `AppointmentService.getNextSerialNumber()` |
| `DELETE` | `/api/appointments` | Remove appointment | `AppointmentService.removeAppointment()` |
| **Prescriptions** | | | |
| `POST` | `/api/prescriptions` | Create prescription | `PrescriptionService.createPrescription()` |
| `GET` | `/api/prescriptions/patient/:phone` | Patient's prescriptions | `PrescriptionService.getPatientPrescriptions()` |
| `GET` | `/api/prescriptions/doctor/:id` | Doctor's prescriptions | `PrescriptionService.getDoctorPrescriptions()` |
| `GET` | `/api/prescriptions/:id` | Single prescription detail | Full prescription view |

---

## 8. Step 6 — Controller & Query Examples

### 8.1 Doctor Routes — `src/routes/doctor.routes.js`

```javascript
const router = require('express').Router();
const pool   = require('../config/db');

// GET /api/doctors — Get all doctors
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, name, department, designation, degrees, room_number,
              consultation_fee, consultation_days, consultation_times
       FROM doctors ORDER BY name`
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/doctors/:id
router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, name, department, designation, degrees, room_number,
              consultation_fee, consultation_days, consultation_times
       FROM doctors WHERE id = $1`,
      [req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Doctor not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
```

### 8.2 Patient Routes — `src/routes/patient.routes.js`

```javascript
const router = require('express').Router();
const pool   = require('../config/db');

// POST /api/patients — Register new patient
router.post('/', async (req, res) => {
  const { phone_number, name, date_of_birth, address, gender } = req.body;
  try {
    const result = await pool.query(
      `INSERT INTO patients (phone_number, name, date_of_birth, address, gender)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [phone_number, name, date_of_birth, address, gender]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/patients/:phone — Get patient by phone
router.get('/:phone', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM patients WHERE phone_number = $1',
      [req.params.phone]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Patient not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/patients/:phone — Update patient
router.put('/:phone', async (req, res) => {
  const { name, date_of_birth, address, gender } = req.body;
  try {
    const result = await pool.query(
      `UPDATE patients
       SET name = $1, date_of_birth = $2, address = $3, gender = $4, updated_at = NOW()
       WHERE phone_number = $5 RETURNING *`,
      [name, date_of_birth, address, gender, req.params.phone]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Patient not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
```

### 8.3 Appointment Routes — `src/routes/appointment.routes.js`

```javascript
const router = require('express').Router();
const pool   = require('../config/db');

// POST /api/appointments — Book appointment
router.post('/', async (req, res) => {
  const { doctor_id, doctor_name, patient_phone, patient_name, date, time_slot } = req.body;
  try {
    // Get next serial number
    const serialResult = await pool.query(
      `SELECT COALESCE(MAX(serial_number), 0) + 1 AS next_serial
       FROM appointments WHERE doctor_id = $1 AND date = $2`,
      [doctor_id, date]
    );
    const serial_number = serialResult.rows[0].next_serial;

    const result = await pool.query(
      `INSERT INTO appointments (doctor_id, doctor_name, patient_phone, patient_name, date, time_slot, serial_number)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [doctor_id, doctor_name, patient_phone, patient_name, date, time_slot, serial_number]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    if (err.code === '23505') { // unique violation
      return res.status(409).json({ error: 'Time slot already booked' });
    }
    res.status(500).json({ error: err.message });
  }
});

// GET /api/appointments/patient/:phone
router.get('/patient/:phone', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM appointments WHERE patient_phone = $1 ORDER BY date DESC`,
      [req.params.phone]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/appointments/doctor/:id
router.get('/doctor/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM appointments WHERE doctor_id = $1 ORDER BY date DESC`,
      [req.params.id]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/appointments/slots/:doctorId/:date — booked slots
router.get('/slots/:doctorId/:date', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT time_slot FROM appointments WHERE doctor_id = $1 AND date = $2`,
      [req.params.doctorId, req.params.date]
    );
    res.json(result.rows.map(r => r.time_slot));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/appointments — Remove appointment
router.delete('/', async (req, res) => {
  const { doctor_id, patient_phone, date } = req.body;
  try {
    await pool.query(
      `DELETE FROM appointments WHERE doctor_id = $1 AND patient_phone = $2 AND date = $3`,
      [doctor_id, patient_phone, date]
    );
    res.json({ message: 'Appointment removed' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
```

### 8.4 Prescription Routes — `src/routes/prescription.routes.js`

```javascript
const router = require('express').Router();
const pool   = require('../config/db');

// POST /api/prescriptions — Create prescription (with diagnoses + medicines)
router.post('/', async (req, res) => {
  const client = await pool.connect(); // use transaction
  try {
    await client.query('BEGIN');

    const {
      id, doctor_id, doctor_name, doctor_department, doctor_designation,
      doctor_degrees, patient_phone, patient_name, appointment_date,
      issued_at, additional_notes, pdf_path, diagnoses, medicines
    } = req.body;

    // 1. Insert prescription
    await client.query(
      `INSERT INTO prescriptions
       (id, doctor_id, doctor_name, doctor_department, doctor_designation,
        doctor_degrees, patient_phone, patient_name, appointment_date,
        issued_at, additional_notes, pdf_path)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)`,
      [id, doctor_id, doctor_name, doctor_department, doctor_designation,
       doctor_degrees, patient_phone, patient_name, appointment_date,
       issued_at, additional_notes, pdf_path]
    );

    // 2. Insert diagnoses
    for (let i = 0; i < diagnoses.length; i++) {
      await client.query(
        `INSERT INTO prescription_diagnoses (prescription_id, diagnosis_text, sort_order)
         VALUES ($1, $2, $3)`,
        [id, diagnoses[i], i]
      );
    }

    // 3. Insert medicines
    for (const med of medicines) {
      await client.query(
        `INSERT INTO prescribed_medicines (prescription_id, name, dosage, frequency, duration, notes)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [id, med.name, med.dosage, med.frequency, med.duration, med.notes || null]
      );
    }

    // 4. Remove the completed appointment
    await client.query(
      `DELETE FROM appointments WHERE doctor_id = $1 AND patient_phone = $2 AND date = $3`,
      [doctor_id, patient_phone, appointment_date]
    );

    await client.query('COMMIT');
    res.status(201).json({ message: 'Prescription created', id });
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
});

// GET /api/prescriptions/patient/:phone
router.get('/patient/:phone', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM prescriptions WHERE patient_phone = $1 ORDER BY issued_at DESC`,
      [req.params.phone]
    );

    // For each prescription, load diagnoses and medicines
    const prescriptions = [];
    for (const rx of result.rows) {
      const diag = await pool.query(
        'SELECT diagnosis_text FROM prescription_diagnoses WHERE prescription_id = $1 ORDER BY sort_order',
        [rx.id]
      );
      const meds = await pool.query(
        'SELECT name, dosage, frequency, duration, notes FROM prescribed_medicines WHERE prescription_id = $1',
        [rx.id]
      );
      prescriptions.push({
        ...rx,
        diagnoses: diag.rows.map(d => d.diagnosis_text),
        medicines: meds.rows
      });
    }

    res.json(prescriptions);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/prescriptions/doctor/:id
router.get('/doctor/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM prescriptions WHERE doctor_id = $1 ORDER BY issued_at DESC`,
      [req.params.id]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
```

### 8.5 Auth Routes — `src/routes/auth.routes.js`

```javascript
const router  = require('express').Router();
const pool    = require('../config/db');
const bcrypt  = require('bcrypt');
const jwt     = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'care_people_secret_key';

// POST /api/auth/patient/send-otp
router.post('/patient/send-otp', async (req, res) => {
  const { phone_number } = req.body;
  // Generate 6-digit OTP
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  // In production: send via SMS gateway (e.g., Twilio, SSL Wireless)
  // For now: return it in response (testing mode)
  res.json({ message: 'OTP sent', otp }); // Remove 'otp' in production!
});

// POST /api/auth/patient/verify-otp
router.post('/patient/verify-otp', async (req, res) => {
  const { phone_number, otp, expected_otp } = req.body;

  if (otp !== expected_otp) {
    return res.status(401).json({ error: 'Invalid OTP' });
  }

  // Check if patient exists
  const patient = await pool.query(
    'SELECT * FROM patients WHERE phone_number = $1',
    [phone_number]
  );

  // Generate JWT (expires in 2 days — matches current session logic)
  const token = jwt.sign(
    { phone_number, role: 'patient' },
    JWT_SECRET,
    { expiresIn: '2d' }
  );

  res.json({
    token,
    is_new_user: patient.rows.length === 0,
    user: patient.rows[0] || null
  });
});

// POST /api/auth/doctor/login
router.post('/doctor/login', async (req, res) => {
  const { doctor_id, password } = req.body;
  try {
    const result = await pool.query('SELECT * FROM doctors WHERE UPPER(id) = UPPER($1)', [doctor_id]);

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid Doctor ID or Password' });
    }

    const doctor = result.rows[0];
    const passwordMatch = await bcrypt.compare(password, doctor.password);

    if (!passwordMatch) {
      return res.status(401).json({ error: 'Invalid Doctor ID or Password' });
    }

    // Generate JWT
    const token = jwt.sign(
      { doctor_id: doctor.id, role: 'doctor' },
      JWT_SECRET,
      { expiresIn: '2d' }
    );

    // Remove password from response
    delete doctor.password;

    res.json({ token, doctor });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
```

---

## 9. Step 7 — Authentication with JWT

### 9.1 Middleware — `src/middleware/auth.js`

```javascript
const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'care_people_secret_key';

function verifyToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // "Bearer <token>"

  if (!token) return res.status(401).json({ error: 'No token provided' });

  jwt.verify(token, JWT_SECRET, (err, decoded) => {
    if (err) return res.status(403).json({ error: 'Invalid or expired token' });
    req.user = decoded; // { phone_number, role } or { doctor_id, role }
    next();
  });
}

module.exports = verifyToken;
```

### 9.2 Protect Routes

```javascript
const verifyToken = require('../middleware/auth');

// Add to any route that needs authentication:
router.get('/patient/:phone', verifyToken, async (req, res) => {
  // req.user is available here
  // ...
});
```

---

## 10. Step 8 — Connect Flutter to Backend

### 10.1 Create an API Service in Flutter

Create `lib/services/api_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Change this to your server IP/URL
  // For Android emulator: 'http://10.0.2.2:3000/api'
  // For iOS simulator:    'http://localhost:3000/api'
  // For real device:      'http://YOUR_IP:3000/api'
  static const String baseUrl = 'http://localhost:3000/api';

  // ── Token Management ─────────────────────────────────────
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  // ── HTTP Helpers ──────────────────────────────────────────
  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> delete(String endpoint, {Map<String, dynamic>? body}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error ${response.statusCode}: ${response.body}');
    }
  }
}
```

---

## 11. Step 9 — Replace Local Services

### 11.1 Replace `UserStorageService` → API Calls

**Before** (local JSON):
```dart
await UserStorageService.saveUser(phoneNumber: ..., name: ..., ...);
```

**After** (API call):
```dart
await ApiService.post('/patients', {
  'phone_number': phoneNumber,
  'name': name,
  'date_of_birth': dateOfBirth,
  'address': address,
  'gender': gender,
});
```

### 11.2 Replace `AppointmentService` → API Calls

| Old Method | New API Call |
|---|---|
| `loadDoctors()` | `ApiService.get('/doctors')` |
| `saveAppointment(appt)` | `ApiService.post('/appointments', appt.toJson())` |
| `getPatientAppointments(phone)` | `ApiService.get('/appointments/patient/$phone')` |
| `getDoctorAppointments(id)` | `ApiService.get('/appointments/doctor/$id')` |
| `getBookedTimeSlotsForDate(id, date)` | `ApiService.get('/appointments/slots/$id/$date')` |
| `getNextSerialNumber(id, date)` | `ApiService.get('/appointments/serial/$id/$date')` |
| `removeAppointment(...)` | `ApiService.delete('/appointments', body: {...})` |

### 11.3 Replace `PrescriptionService` → API Calls

| Old Method | New API Call |
|---|---|
| `getPatientPrescriptions(phone)` | `ApiService.get('/prescriptions/patient/$phone')` |
| `getDoctorPrescriptions(id)` | `ApiService.get('/prescriptions/doctor/$id')` |
| `createPrescription(...)` | `ApiService.post('/prescriptions', {...})` |

### 11.4 Replace `SessionService` → JWT

| Old Method | New Approach |
|---|---|
| `saveSession(phone)` | `ApiService.saveToken(jwt)` |
| `isSessionActive()` | Check if token exists + not expired |
| `getPhoneNumber()` | Decode JWT payload |
| `clearSession()` | `ApiService.clearToken()` |
| `saveDoctorSession(data)` | `ApiService.saveToken(jwt)` + store doctor data |
| `isDoctorSessionActive()` | Check if token exists + role == 'doctor' |

### 11.5 Example — Updated Appointment Service

```dart
// lib/services/appointment_service.dart (UPDATED)
import 'api_service.dart';
import '../models/appointment_models.dart';

class AppointmentService {
  static Future<List<Doctor>> loadDoctors() async {
    final List<dynamic> data = await ApiService.get('/doctors');
    return data.map((json) => Doctor.fromJson(json)).toList();
  }

  static Future<bool> saveAppointment(Appointment appointment) async {
    try {
      await ApiService.post('/appointments', appointment.toJson());
      return true;
    } catch (e) {
      print('Error saving appointment: $e');
      return false;
    }
  }

  static Future<List<Appointment>> getPatientAppointments(String phone) async {
    final List<dynamic> data = await ApiService.get('/appointments/patient/$phone');
    return data.map((json) => Appointment.fromJson(json)).toList();
  }

  static Future<List<Appointment>> getDoctorAppointments(String doctorId) async {
    final List<dynamic> data = await ApiService.get('/appointments/doctor/$doctorId');
    return data.map((json) => Appointment.fromJson(json)).toList();
  }

  static Future<List<String>> getBookedTimeSlotsForDate(String doctorId, String date) async {
    final List<dynamic> data = await ApiService.get('/appointments/slots/$doctorId/$date');
    return data.cast<String>();
  }

  static Future<int> getNextSerialNumber(String doctorId, String date) async {
    final data = await ApiService.get('/appointments/serial/$doctorId/$date');
    return data['next_serial'] as int;
  }

  static Future<bool> removeAppointment({
    required String doctorId,
    required String patientPhone,
    required String date,
  }) async {
    try {
      await ApiService.delete('/appointments', body: {
        'doctor_id': doctorId,
        'patient_phone': patientPhone,
        'date': date,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

---

## 12. Folder Structure Summary

### Backend (`care_people_backend/`)

```
care_people_backend/
├── .env                        # Environment variables
├── package.json
├── schema.sql                  # Database DDL
├── seed.sql                    # Doctor seed data
├── hash_passwords.js           # One-time password hash utility
└── src/
    ├── server.js               # Entry point
    ├── config/
    │   └── db.js               # PostgreSQL connection pool
    ├── middleware/
    │   └── auth.js             # JWT verification middleware
    └── routes/
        ├── auth.routes.js      # Login, OTP, register
        ├── doctor.routes.js    # Doctor CRUD
        ├── patient.routes.js   # Patient CRUD
        ├── appointment.routes.js  # Appointment CRUD
        └── prescription.routes.js # Prescription CRUD
```

### Flutter Changes (`lib/services/`)

```
lib/services/
├── api_service.dart            # NEW — HTTP client with JWT
├── appointment_service.dart    # UPDATED — calls API instead of local JSON
├── prescription_service.dart   # UPDATED — calls API instead of local JSON
├── user_storage_service.dart   # UPDATED — calls API instead of local JSON
└── session_service.dart        # UPDATED — uses JWT from SharedPreferences
```

---

## 13. Environment Variables

Create `.env` in the backend root:

```env
# Server
PORT=3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=care_people
DB_USER=care_admin
DB_PASSWORD=your_secure_password

# JWT
JWT_SECRET=your_very_long_random_secret_key_here_abc123
```

> ⚠️ **Never commit `.env` to Git.** Add it to `.gitignore`.

---

## 14. Quick Command Reference

### Run Everything

```bash
# Terminal 1 — Start PostgreSQL (if not running)
brew services start postgresql@15

# Terminal 2 — Start Backend
cd care_people_backend
npm run dev
# → Server running on http://localhost:3000

# Terminal 3 — Run Flutter App
cd care_people
flutter run
```

### Test API with curl

```bash
# Health check
curl http://localhost:3000/api/health

# Get all doctors
curl http://localhost:3000/api/doctors

# Patient login — send OTP
curl -X POST http://localhost:3000/api/auth/patient/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone_number":"01712345678"}'

# Doctor login
curl -X POST http://localhost:3000/api/auth/doctor/login \
  -H "Content-Type: application/json" \
  -d '{"doctor_id":"DOC001","password":"Kamal@1234"}'

# Book appointment (with token)
curl -X POST http://localhost:3000/api/appointments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "doctor_id":"DOC001",
    "doctor_name":"Dr. Md. Kamal Hossain",
    "patient_phone":"01712345678",
    "patient_name":"Rahim Uddin",
    "date":"2026-03-15",
    "time_slot":"09:00 AM"
  }'
```

### Database Commands

```bash
# Connect to database
psql -U care_admin -d care_people

# Run schema
psql -U care_admin -d care_people -f schema.sql

# Seed doctors
psql -U care_admin -d care_people -f seed.sql

# Check tables
psql -U care_admin -d care_people -c "\dt"

# Query a table
psql -U care_admin -d care_people -c "SELECT id, name FROM doctors;"
```

---

### Summary — Implementation Order

| # | Task | Time Estimate |
|---|---|---|
| 1 | Install PostgreSQL + Node.js | 15 min |
| 2 | Create database + run `schema.sql` | 10 min |
| 3 | Hash passwords + run `seed.sql` | 10 min |
| 4 | Set up Node.js project + install packages | 10 min |
| 5 | Create `db.js` + `server.js` + `.env` | 15 min |
| 6 | Build auth routes (OTP + doctor login + JWT) | 30 min |
| 7 | Build doctor, patient, appointment, prescription routes | 1–2 hrs |
| 8 | Test all routes with Postman / curl | 30 min |
| 9 | Create `api_service.dart` in Flutter | 20 min |
| 10 | Replace local service methods with API calls | 1–2 hrs |
| 11 | Test Flutter app end-to-end | 30 min |
| **Total** | | **~5–6 hours** |

---

> **End of Backend Implementation Guide**
