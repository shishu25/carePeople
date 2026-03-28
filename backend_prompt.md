# FastAPI Backend Prompt Playbook for `care_people`

> **Purpose:** This file gives you a sequence of copy-paste prompts to generate a complete FastAPI backend incrementally in any AI coding tool.
> 
> **How to use:** Paste Prompt 1 first, then Prompt 2, and continue in order. Do not skip order.
> 
> **Project context baked in:** Flutter app with two roles (Patient + Doctor), appointment booking, prescription generation, 2-day sessions, currently using local JSON storage.

---

## Prompt 0 — Context Priming (paste this first once)

```text
You are building a production-ready FastAPI backend for a Flutter hospital app named Care People.

Current app behavior to preserve:
- Two roles: Patient and Doctor.
- Patient login flow: phone + OTP.
- Doctor login flow: doctor_id + password.
- Session duration is 2 days.
- Core features: doctor listing, patient profile CRUD, appointment booking, prescription creation with medicines + diagnoses.
- Existing local data has these entities: doctors, patients, appointments, prescriptions, prescribed_medicines, prescription_diagnoses, sessions.

Mandatory stack requirements:
- Python 3.12+
- FastAPI
- PostgreSQL
- SQLAlchemy 2.0 (async)
- Alembic migrations
- Pydantic v2 schemas
- JWT auth (access + refresh)
- Password hashing with passlib[bcrypt]
- OTP abstraction service (dev mode fake provider + pluggable real provider)
- Structured logging
- pytest for tests

Architecture requirements:
- Layered architecture: api/routes, core/config, db, models, schemas, repositories, services, security, tests.
- Type hints everywhere.
- Clean error handling and reusable response models.
- Environment-driven config with .env and pydantic-settings.

When generating code:
- Always provide full file tree first, then file contents.
- Keep code runnable.
- Use snake_case naming.
- Include comments only where needed.
- Follow REST conventions.

Do not implement everything at once. Wait for my next prompt after each milestone.
```

---

## Prompt 1 — Project Scaffolding & Environment Setup

```text
Milestone 1: Generate the FastAPI project scaffold and environment setup only.

Tasks:
1) Create complete backend folder structure:
   app/
     main.py
     api/
       router.py
       deps.py
       v1/
         endpoints/
     core/
       config.py
       logging.py
       exceptions.py
       constants.py
     db/
       base.py
       session.py
     models/
       __init__.py
     schemas/
       __init__.py
     repositories/
       __init__.py
     services/
       __init__.py
     security/
       __init__.py
   alembic/
   tests/
   pyproject.toml
   .env.example
   README.md

2) Use pyproject.toml with dependencies:
   fastapi, uvicorn[standard], sqlalchemy[asyncio], asyncpg,
   alembic, pydantic-settings, python-jose[cryptography], passlib[bcrypt],
   python-multipart, structlog, httpx, pytest, pytest-asyncio.

3) Add pydantic-settings config class with:
   APP_NAME, APP_ENV, DEBUG, API_V1_PREFIX,
   DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD,
   JWT_SECRET_KEY, JWT_ALGORITHM, ACCESS_TOKEN_EXPIRE_MINUTES,
   REFRESH_TOKEN_EXPIRE_DAYS,
   OTP_ENABLED, OTP_DEV_STATIC_CODE.

4) Add async SQLAlchemy engine/session setup.

5) Add FastAPI app bootstrap with:
   - CORS middleware (allow localhost + configurable origins)
   - health endpoint: GET /health
   - versioned router mounting at /api/v1

6) Provide .env.example with sensible defaults for local dev.

7) Provide run instructions in README.

Output format:
- Show full tree
- Then each file content
- End with exact command list to run locally

Do not create business models/routes yet.
```

---

## Prompt 2 — PostgreSQL Schema Design + SQLAlchemy Models + Alembic Migration

```text
Milestone 2: Design DB schema for Care People and implement SQLAlchemy models + initial Alembic migration.

Use PostgreSQL and justify briefly why: reliability, ACID, indexing, JSONB support, relational integrity, concurrency.

Create these tables with constraints:

1) doctors
- id (PK, string like DOC001)
- name, department, designation, degrees, room_number
- consultation_fee (numeric >= 0)
- consultation_days (JSONB array of weekdays)
- consultation_times (text)
- password_hash (not plain password)
- is_active (bool default true)
- created_at, updated_at

2) patients
- phone_number (PK)
- name
- date_of_birth (date)
- address
- gender (enum: male,female,other)
- created_at, updated_at

3) sessions
- id (UUID PK)
- user_type (enum: patient,doctor)
- user_identifier (phone or doctor_id)
- refresh_token_hash
- login_at
- expires_at
- revoked_at nullable
- metadata_json JSONB nullable

4) appointments
- id (bigserial PK)
- doctor_id FK->doctors.id
- patient_phone FK->patients.phone_number
- appointment_date (date)
- time_slot (varchar)
- serial_number (int > 0)
- status enum: confirmed,cancelled,completed (default confirmed)
- notes nullable
- created_at
- unique constraint (doctor_id, appointment_date, time_slot)
- index (doctor_id, appointment_date)
- index (patient_phone, appointment_date)

5) prescriptions
- id (string PK, e.g. RX timestamp or UUID)
- doctor_id FK
- patient_phone FK
- appointment_id nullable FK->appointments.id
- appointment_date (date)
- issued_at (timestamp)
- additional_notes nullable
- pdf_path nullable
- created_at

6) prescription_diagnoses
- id (bigserial PK)
- prescription_id FK cascade delete
- diagnosis_text
- sort_order int default 0

7) prescribed_medicines
- id (bigserial PK)
- prescription_id FK cascade delete
- name, dosage, frequency, duration
- notes nullable

Requirements:
- SQLAlchemy 2.0 declarative models
- shared Timestamp mixin
- proper relationships and back_populates
- enums using Python Enum
- Alembic init migration generated and shown

Also include:
- ERD in mermaid inside README section
- seed script for 20 doctors placeholder data (with hashed passwords)

Output:
- Updated tree
- New/changed file contents
- Alembic commands to apply migration
```

---

## Prompt 3 — Pydantic Schemas + Validation Contracts

```text
Milestone 3: Create Pydantic v2 schemas (request/response contracts) for all modules.

Requirements:
1) Base response envelope:
- success: bool
- message: str
- data: Any | None
- error_code: str | None

2) Auth schemas:
- PatientSendOtpRequest(phone_number)
- PatientVerifyOtpRequest(phone_number, otp_code)
- DoctorLoginRequest(doctor_id, password)
- TokenResponse(access_token, refresh_token, token_type, expires_in)
- RefreshTokenRequest(refresh_token)

3) Patient schemas:
- PatientCreate, PatientUpdate, PatientOut
- Validate Bangladesh-like phone format (configurable regex)

4) Doctor schemas:
- DoctorOut (never expose password_hash)
- DoctorListFilters(department, day, search)

5) Appointment schemas:
- AppointmentCreate
- AppointmentOut
- AppointmentListQuery
- SlotAvailabilityResponse(available_slots, booked_slots)

6) Prescription schemas:
- MedicineCreate
- DiagnosisCreate
- PrescriptionCreate
- PrescriptionOut with nested diagnosis + medicines

7) Add field validations:
- non-empty names
- max lengths
- appointment_date cannot be in the past (except configurable override)
- dosage/frequency/duration required

8) Add schema conversion compatibility with existing Flutter naming where useful:
- support aliases for camelCase incoming fields (doctorId, patientPhone etc.)

Output:
- file tree changes
- schema files content
- examples for request/response JSON for each major endpoint
```

---

## Prompt 4 — Authentication & Security Layer (JWT + OTP + Role Guards)

```text
Milestone 4: Implement complete auth/security module.

Implement:
1) Password hashing helpers with passlib bcrypt:
- hash_password
- verify_password

2) JWT helpers:
- create_access_token (short TTL)
- create_refresh_token (2-day default to match app behavior)
- decode/validate token
- include role + subject + jti in claims

3) OTP service abstraction:
- interface/protocol for send_otp and verify_otp
- DevOtpProvider: fixed code from env (or generated + in-memory store)
- placeholder RealOtpProvider class with TODO hooks

4) Auth service flows:
- patient_send_otp(phone)
- patient_verify_otp(phone, code) -> tokens, auto-create patient shell if not exists (optional flag)
- doctor_login(doctor_id, password) -> tokens
- refresh token endpoint logic (rotate token + revoke old session)
- logout endpoint (revoke refresh token/session)

5) Session persistence:
- store refresh_token_hash in sessions table
- revoke on logout/rotation

6) Security dependencies:
- get_current_user
- require_patient
- require_doctor

7) API endpoints under /api/v1/auth:
- POST /patient/send-otp
- POST /patient/verify-otp
- POST /doctor/login
- POST /refresh
- POST /logout

8) Hardening best practices:
- constant-time compare
- never return whether doctor_id exists vs password incorrect
- rate-limit ready hooks (interface)

Output:
- new files and code
- simple sequence diagram (mermaid) for login/refresh
- minimal tests for auth happy path + invalid token
```

---

## Prompt 5 — Doctors & Patients APIs (Flow-Aligned)

```text
Milestone 5: Implement Doctors and Patients modules with repository + service + router layers.

Doctors API requirements:
- GET /api/v1/doctors
  - filters: department, available_day, search, page, size
  - returns paginated doctor list
- GET /api/v1/doctors/{doctor_id}
- GET /api/v1/doctors/departments

Patients API requirements:
- GET /api/v1/patients/me (patient token)
- PUT /api/v1/patients/me
- GET /api/v1/patients/{phone_number} (doctor/admin only; for now doctor allowed)
- POST /api/v1/patients (for registration if needed)

Implementation rules:
- Use repository classes for DB access.
- Service layer handles business validation.
- Router layer stays thin.
- Proper HTTP codes (200, 201, 400, 401, 403, 404, 409).

Compatibility note:
- Match Flutter fields so frontend migration is easy.

Output:
- full code for repositories/services/routes
- unit tests for list doctors and update patient profile
```

---

## Prompt 6 — Appointments APIs with Slot + Serial Logic

```text
Milestone 6: Implement appointments module with strict booking rules.

Endpoints:
- POST /api/v1/appointments
- GET /api/v1/appointments/patient/{phone_number}
- GET /api/v1/appointments/doctor/{doctor_id}
- GET /api/v1/appointments/slots/{doctor_id}/{date}
- GET /api/v1/appointments/serial/{doctor_id}/{date}
- DELETE /api/v1/appointments/{appointment_id}

Business rules:
1) No double-booking same doctor/date/time_slot (enforced DB + graceful API message).
2) serial_number increments per doctor per date.
3) Patient can only view own appointments unless doctor role.
4) Optional cancellation window setting.
5) Status transitions: confirmed -> cancelled or completed.

Implementation requirements:
- transactional booking logic
- conflict handling for unique violation
- query optimization with indexes
- pagination for listing endpoints

Output:
- module code (schema/repo/service/router)
- test cases:
  - book success
  - duplicate slot conflict
  - next serial generation
```

---

## Prompt 7 — Prescriptions APIs with Nested Children + Transaction

```text
Milestone 7: Implement prescriptions module with transactional creation.

Endpoints:
- POST /api/v1/prescriptions (doctor only)
- GET /api/v1/prescriptions/patient/{phone_number}
- GET /api/v1/prescriptions/doctor/{doctor_id}
- GET /api/v1/prescriptions/{prescription_id}

Prescription create payload contains:
- doctor_id, patient_phone, appointment_date, additional_notes
- diagnoses[] (ordered)
- medicines[] (name, dosage, frequency, duration, notes)

Rules:
1) Save parent prescription + diagnoses + medicines in one DB transaction.
2) Optionally mark linked appointment as completed.
3) Return nested prescription response.
4) Support newest-first ordering by issued_at.

Implementation details:
- repositories for parent and child inserts
- service handles transaction boundary
- route protected by doctor role

Output:
- full module code
- tests for create + retrieval with nested children
```

---

## Prompt 8 — Unified API Router, Error Handling, and OpenAPI Polishing

```text
Milestone 8: Integrate all routers and add robust API ergonomics.

Tasks:
1) Build central v1 router and include all modules:
   auth, doctors, patients, appointments, prescriptions.
2) Add global exception handlers:
   - validation errors
   - custom domain exceptions
   - SQLAlchemy errors
   - generic 500
3) Add request ID middleware and structured logs per request.
4) Customize OpenAPI docs:
   - tags
   - endpoint descriptions
   - auth bearer scheme
   - examples for key endpoints
5) Add /health and /ready endpoints.
6) Add consistent response envelope helper.

Output:
- changed files
- screenshot-style text summary of OpenAPI sections
- sample curl snippets for each module
```

---

## Prompt 9 — Production Environment, Docker, and CI Basics

```text
Milestone 9: Make backend deployment-ready with Docker and basic CI.

Implement:
1) Dockerfile (multi-stage, slim image)
2) docker-compose.yml with:
   - api service
   - postgres service
   - optional pgadmin
3) Alembic migration on startup strategy (safe approach)
4) .env.example expanded for production knobs
5) Logging config for prod vs dev
6) Security best practices checklist:
   - JWT secret management
   - HTTPS termination note
   - CORS restrictions
   - brute-force mitigation hooks
7) GitHub Actions workflow:
   - install deps
   - run lint (ruff optional)
   - run tests

Output:
- infra files content
- local docker run steps
- CI yaml
```

---

## Prompt 10 — Flutter Integration Contract (Migration from Local JSON)

```text
Milestone 10: Create integration mapping docs and compatibility layer for Flutter app migration.

Need:
1) Endpoint mapping table from old Flutter service methods to new API endpoints:
   - AppointmentService methods
   - PrescriptionService methods
   - UserStorageService methods
   - SessionService methods
2) JSON field compatibility notes (camelCase vs snake_case).
3) Auth token handling recommendations for Flutter (access + refresh flow).
4) Error code mapping for UI messages.
5) Minimal API client examples (Dart pseudo-code acceptable).
6) Stepwise migration strategy:
   - phase 1 read-only (doctors)
   - phase 2 appointments
   - phase 3 prescriptions
   - phase 4 session/auth hard switch

Output:
- migration.md ready for frontend team
- include rollback strategy per phase
```

---

## Prompt 11 — Test Suite Expansion & Quality Gates

```text
Milestone 11: Add comprehensive tests and enforce quality gates.

Requirements:
1) Test architecture:
- unit tests for services
- integration tests for APIs with test DB
- auth tests (token expiry, role checks)
2) Add fixtures for doctors/patients/appointments.
3) Add test for booking race condition (or simulated conflict).
4) Add coverage command and target >= 85% for service layer.
5) Add Makefile commands:
- make dev
- make test
- make lint
- make migrate

Output:
- tests tree
- key test files
- commands and expected output examples
```

---

## Prompt 12 — Final Hardening & Handover

```text
Milestone 12: Perform final backend hardening and produce handover docs.

Deliverables:
1) Final architecture summary (module boundaries + responsibilities)
2) DB schema summary + migration history
3) Operational runbook:
   - startup
   - migration
   - backup/restore PostgreSQL
   - common incident playbooks
4) Security review checklist
5) Performance checklist (indexes, query plans, pagination defaults)
6) Known limitations + future roadmap

Also produce:
- README final version
- API quickstart
- Postman collection (or openapi export instructions)

Output should be concise, production-oriented, and developer-friendly.
```

---

## Recommended Prompt Execution Order

1. Prompt 0 (once)
2. Prompt 1
3. Prompt 2
4. Prompt 3
5. Prompt 4
6. Prompt 5
7. Prompt 6
8. Prompt 7
9. Prompt 8
10. Prompt 9
11. Prompt 10
12. Prompt 11
13. Prompt 12

---

## Notes for Best Results

- Ask the AI tool to **only modify/add files relevant to the current milestone**.
- After each milestone, run tests before moving forward.
- Keep PostgreSQL as the single source of truth (no local JSON writes).
- Keep OTP provider pluggable so you can switch from dev OTP to real SMS gateway later.
- Use migration files for all schema changes (never manual prod edits).
- Store only password hashes and hashed refresh tokens.

---

## Optional One-Liner Master Prompt (if you want strict behavior)

```text
Follow milestone-by-milestone generation. Do not skip steps. At each step: show file tree delta, then full file content for changed files, then exact run/test commands, then wait for confirmation.
```

---

**End of `backend_prompt.md`**
