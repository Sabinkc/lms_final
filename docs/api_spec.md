# CloudsLMS — API Specification

> Status: **REVISED v0.2 — verified against backend source code.** Source: `https://github.com/ArbindDas/SujalbackendForStudentmanagement`, commit `1a863ff` (2026-08-15), cloned read-only and analyzed directly (routes, controllers, Mongoose schemas, middleware, Socket.IO handlers). **The backend was not modified and no live instance was queried** — everything below reflects the committed code, not confirmed runtime/deployed behavior (env vars, exact hostnames, and anything decided by `.env` at deploy time remain `UNKNOWN — VERIFY`, since `.env` is correctly gitignored and not in the repo). Every line is either **CONFIRMED** (read directly from source, cited by file) or `UNKNOWN — VERIFY` (genuinely not determinable from the code). Nothing below is inferred or guessed the way v0.1 of this document was.

## 0. How this replaces v0.1
The previous draft was built entirely from the product doc and live-site CSS/JS scanning, with almost everything marked `UNKNOWN — VERIFY FROM BACKEND`. This revision resolves nearly all of those markers — and reveals that the real backend is substantially larger and structured differently than the product documentation describes. See **§12 Conflicts With Product Documentation** for the full comparison. `implementation_plan.md` Phase 1's stated goal (resolve auth mechanism + response/error envelope first) is now achievable — both are answered in §2–3 below.

This pass was done as four independent read-only analyses (auth/authorization, full endpoint inventory, MongoDB models, real-time/notifications/uploads/external services) cross-checked against each other before being merged into this single document — where two passes independently reached the same conclusion (e.g. chat being class/section group chat rather than 1:1, or no push-notification integration existing), that's noted as higher-confidence; §5 (MongoDB Models) and two rows in §12 were enriched from the dedicated models pass after the initial merge.

---

## 1. Base configuration

| Item | Value | Status |
|---|---|---|
| API prefix | `/api` (e.g. `/api/auth`, `/api/students`, ...) | CONFIRMED (`server.js`) |
| Version prefix | **None** — no `/v1` segment anywhere | CONFIRMED |
| Base URL / host | Not hardcoded anywhere in source; `PORT` env var (default `4000`) is the local listen port only | `UNKNOWN — VERIFY` (deploy-specific) |
| Content-Type | `application/json` for standard bodies; `multipart/form-data` (via `multer`) for every file-upload endpoint | CONFIRMED |
| CORS allow-list | `http://localhost:5173`, `http://127.0.0.1:5173`, `https://cloudslms.com`, `https://www.cloudslms.com`, and any `*.vercel.app` subdomain; `credentials: true` | CONFIRMED (`server.js`) — this is the strongest evidence the live web frontend (Vite dev server on 5173, likely a Vercel-hosted production build) talks to this exact backend |
| Health check | `GET /` and `GET /health` (no auth) | CONFIRMED |
| Error handling | Global Express error handler: CORS rejection → 403, Multer errors → 413/400, everything else → 500 `{ success:false, message:"Internal server error" }` | CONFIRMED |

## 2. Authentication — CONFIRMED

- **Mechanism: JWT bearer token.** `Authorization: Bearer <token>` header, verified with `jsonwebtoken` against `process.env.JWT_SECRET`. A handful of GET/download routes (ID cards, some file links) also accept the token as `?token=...` in the query string via a `tokenFromQuery` middleware, for `window.open()`-style downloads that can't set headers.
- **Two parallel account collections**, both issued from the same JWT secret space:
  - `User` — roles `superadmin | admin | teacher | student | parent` (+ vestigial `user` default, used only by the public self-registration path — see below). Portal end-users.
  - `Admin` — school admin accounts. `role` is an **unrestricted string field defaulting to `"admin"`**, not a Mongoose enum — so an `"hr"` admin is possible in principle, but no controller code was found that sets `role: "hr"` on creation; how HR accounts actually get created is `UNKNOWN — VERIFY`.
  - Two more actor types exist **outside both collections**: `Receptionist` (its own schema + its own `protectReceptionist` middleware, entirely separate auth track) and `Staff` (a schema used only inside the attendance-RBAC actor resolver, role `"staff"`).
- **Access token**: `expiresIn: "60m"`. **Refresh token**: separate `process.env.REFRESH_TOKEN_SECRET`, `expiresIn: "30d"`, payload `{ id, accountType, tokenVersion }`. (`src/utils/tokenUtils.js`)
- **Refresh token transport**: sent to and from the client in the **JSON body**, not an httpOnly cookie. `POST /api/auth/login` returns `refreshToken` directly in its JSON response; `POST /api/auth/refresh` reads it from `req.body.refreshToken`. `cookie-parser` is installed and used in `server.js`, but no cookie is set on login/refresh in the code reviewed — its actual use elsewhere is `UNKNOWN — VERIFY`.
- **Logout / revocation**: `POST /api/auth/logout` (body: `{ refreshToken }`) decodes the refresh token and increments `tokenVersion` on that Admin/User document, which immediately invalidates every outstanding refresh token for that account (the next refresh attempt's `tokenVersion` won't match). Access tokens already issued remain valid until their own 60-minute expiry regardless of logout — there is **no access-token revocation**, only refresh-token revocation.
- **Multi-tenant identification is NOT a login-time field.** Login request body is exactly `{ email, password }` — no school code/subdomain/tenant identifier. `schoolId` is a property already stored on the Admin/Teacher/Student/Parent document and is resolved server-side, post-JWT-verification, from `req.admin.schoolId` / the actor's linked profile. This resolves the `ASSUMPTION` in `product_requirements.md` §2 — **there is no tenant-entry step for the mobile app to build.**
- **Login response shape** (`POST /api/auth/login`, both the Admin branch and the User branch return this same top-level shape):
```json
{
  "success": true,
  "token": "<jwt access token>",
  "refreshToken": "<jwt refresh token>",
  "role": "admin | superadmin | teacher | student | parent",
  "data": { "_id": "...", "fullName": "...", "email": "...", "role": "...", "...": "role-specific fields, e.g. schoolId/isActive for admin, isVerified for user" }
}
```
- **Error/response envelope is NOT uniform across the API.** CONFIRMED by direct inspection, not an oversight in this doc: most endpoints return `{ success: true/false, message, data }`, but a large minority return bare `{ message: "..." }` with no `success` field, and at least one debug endpoint (`parentRoutes.js` `/debug-parent`) returns `{ error: "..." }` on failure instead of `message`. **A mobile client cannot assume one envelope shape** — it must check for `data` presence defensively rather than trusting `success`.
- **401 error shape** also differs by which middleware rejected the request: `authMiddleware.protect` returns `{ message, code }` where `code` is `NO_TOKEN` / `TOKEN_EXPIRED` / `TOKEN_INVALID`; `adminAuthMiddleware.protectAdmin` returns only `{ message }`, **no `code` field at all** — a client that branches on `code` to decide "silently re-login vs. show error" (per `user_flows.md` Flow 2) will work for `protect`-guarded routes and silently fail to detect expiry on `protectAdmin`-guarded ones.
- **Self-registration exists and is public**: `POST /api/auth/register` (body: `fullName`, `email`, `password`) creates a `User` with `role: "user"` and requires OTP email verification (`POST /api/auth/verify-otp`). This path is **not described anywhere in the product documentation** — every other account type (Admin/Teacher/Student/Parent) is created by an Admin via the CRUD endpoints in §4. `UNKNOWN — VERIFY` what this generic self-registration is actually for in production.
- **Forgot password** (`/api/auth/forgot-password`, `/resend-reset-otp`, `/reset-password`) — OTP-based, CONFIRMED to exist, resolving the `ASSUMPTION` in `screens.md` "Forgot Password Screen."
- **A second, separate "PIN" reset flow also exists** (`/api/auth/forgot-pin`, `/resend-pin-otp`, `/reset-pin`) — this concept (a login PIN distinct from the password) is **not mentioned anywhere** in `product_requirements.md`, `screens.md`, or `user_flows.md`. `UNKNOWN — VERIFY` what the PIN is for (possibly a kiosk/quick-login mode) before building any UI around it.
- **Account lockout**: `otpAttempts` / `resetPasswordOtpAttempts` counters exist (max 5, per `authController.js`), but these gate **OTP retry attempts only** — no lockout-after-N-failed-logins mechanism was found anywhere. This resolves `user_flows.md` Flow 1's `ASSUMPTION`: **no login lockout exists in the code as committed.**

## 3. Authorization & Roles — CONFIRMED

**The real role model has (at least) 8 distinct actor types, not 4:**

| Actor | Storage | Auth middleware | Notes |
|---|---|---|---|
| `superadmin` | `User` collection, `role: "superadmin"` | `protectSuperAdmin` (exists in **two separate files** with near-duplicate logic — `authMiddleware.js` and `adminAuthMiddleware.js`) | Platform-level operator, manages all schools/tenants |
| `admin` | `Admin` collection | `protectAdmin` | School-level admin — this is `product_requirements.md`'s "Admin" |
| `hr` | `Admin` collection, `role` field is free-text (not enum) | Recognized by `attendancerbacMiddleware.ROLES.HR` in attendance/leave/staff modules | Creation path `UNKNOWN — VERIFY` |
| `teacher` | `User` collection (`role:"teacher"`) + linked `Teacher` profile doc | `protect` / `eitherAuth` / attendance RBAC | Matches product doc's "Teacher" |
| `student` | `User` collection (`role:"student"`) + linked `Student` profile doc | `protect` / attendance RBAC | Matches product doc's "Student" |
| `parent` | `User` collection (`role:"parent"`) + linked `Parent` profile doc (`students: [Student]` array) | `protect` | Matches product doc's "Parent" |
| `staff` | Separate `Staff` schema, linked by `userId` to `User` | attendance RBAC only (`CAN_MANAGE_STAFF_ATTENDANCE`, `CAN_APPLY_LEAVE`) | Non-teaching staff (accountant, librarian, driver, cleaner, security guard, IT, office staff — per `designation` enum). **Not mentioned anywhere in product docs.** |
| `receptionist` | Fully separate `Receptionist` schema + fully separate `protectReceptionist` middleware, entirely outside the `User`/`Admin`/attendance-RBAC role system | `protectReceptionist` + `checkPermission(...)` (per-receptionist boolean permission flags: `viewStudents`, `viewTeachers`, `viewParents`, `viewAttendance`) | Read-mostly front-desk role. **Not mentioned anywhere in product docs.** |

- **Authorization middleware is not one system** — it's at least six different, independently-written mechanisms layered onto different route files: `protect`, `protectAdmin`, `protectSuperAdmin` (×2 implementations), `protectAny`, `protectReceptionist`, and `attachActor`+`requireRole(...)`. A response-monkeypatching shim called `eitherAuth` (also duplicated as an inline function in 2+ route files before being extracted to `middleware/eitherAuth.js`) tries `protectAdmin` first and falls back to `protect` on 401/403 — its own in-code comment says it was a bug-fix retrofit after `/api/teachers/assignments` was found to 401 every teacher because it had `protectAdmin` alone with no fallback.
- **Plan-limit gating**: `checkPlanLimit(resource)` middleware blocks Teacher/Student/Class creation once a school's subscription plan quota is hit — CONFIRMED (`checkPlanLimit.js`), not mentioned in any product doc.
- **Two route files with full, working handlers are never mounted in `server.js` at all** — `sectionsRoutes.js` (lowercase `s`, duplicate of `sectionRoutes.js`) and `Notificationroutesadditions.js` (a 3-route notification file) are dead code, unreachable via HTTP. Verified by diffing the route-file directory listing against every `app.use(...)` line in `server.js`.
- **`organizationRoutes.js` and the core CRUD routes in `schoolRoutes.js` (`GET/POST /`, `GET/PUT/DELETE /:id`) have no auth middleware applied at all** — CONFIRMED by direct inspection of those two files; every handler is registered with no `protect`/`protectAdmin`/`protectSuperAdmin` argument. `POST /api/subscriptions/seed-plans` is similarly unauthenticated, with an in-code comment "Dev/seed (protect in production)" acknowledging it. This is a factual property of the code as committed, reported here because it directly affects what the mobile client can/should assume is actually protected server-side (relevant to `implementation_plan.md`'s Phase 11 item: "verify CRUD boundaries are enforced server-side, not just UI-hidden").

## 4. Endpoint inventory — CONFIRMED

All paths below are relative to their mount prefix in `server.js`. Auth column names the middleware exactly as it appears in the route file.

### 4.1 Auth — `/api/auth` (`authRoutes.js`)
| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `/register` | public | body: `fullName, email, password` → creates `User` role `"user"`, sends OTP |
| POST | `/verify-otp` | public | |
| POST | `/resend-verification`, `/resend-otp` | public | same handler, two aliases |
| POST | `/forgot-password`, `/resend-reset-otp`, `/reset-password` | public | |
| POST | `/forgot-pin`, `/resend-pin-otp`, `/reset-pin` | public | separate PIN concept, purpose `UNKNOWN — VERIFY` |
| POST | `/login` | public | body: `email, password` → see §2 response shape |
| POST | `/refresh` | public (validates refresh token itself) | body: `refreshToken` |
| POST | `/logout` | public (validates refresh token itself) | body: `refreshToken` |
| GET | `/by-email` | `protect` | query: `email` |
| GET | `/users` | `protect` | returns Admins+Teachers+Students+Parents+plain Users combined |

### 4.1a Academic Structure — Classes & Sections `/api/classes` + `/api/sections` (`classRoutes.js`, `sectionRoutes.js` → `Classcontroller.js`, `Sectioncontroller.js`) — CONFIRMED 2026-08-23, was `UNKNOWN — VERIFY`
Resolves the one open item blocking `implementation_backlog.md` E2-F1-T4. `sectionsRoutes.js` (plural, lowercase `s`) exists but is **not mounted anywhere in `server.js`** — confirmed dead code, ignore it.

**Classes** — `/api/classes`, all `protectAdmin`:
| Method | Path | Auth | Body / Notes |
|---|---|---|---|
| POST | `/` | `protectAdmin` + `checkPlanLimit("class")` | body: `name, description` |
| GET | `/`, GET `/:id` | `protectAdmin` | |
| PUT | `/:id` | `protectAdmin` | body: `name, description, status` |
| DELETE | `/:id` | `protectAdmin` | |

**Sections** — nested create/list under `/api/classes/:classId/sections`, everything else under `/api/sections`:
| Method | Path | Auth | Body / Notes |
|---|---|---|---|
| POST | `/api/classes/:classId/sections` | `protectAdmin` | body: `name` |
| GET | `/api/classes/:classId/sections` | `protectAdmin` | list by class |
| GET | `/api/sections/:id` | `eitherAuth`+`attachActor` | any authenticated actor, not Admin-only |
| PUT | `/api/sections/:id` | `protectAdmin` | body: `name, classId, status` |
| DELETE | `/api/sections/:id` | `protectAdmin` | |
| PATCH | `/api/sections/:id/teachers` | `protectAdmin` | body: `teacherIds` — assign teachers to section |
| PATCH | `/api/sections/:id/students` | `protectAdmin` | body: `studentIds, action` — roster management; cross-check against `Student.sectionId`/`.class`/`.section` (§5) before assuming which one is authoritative when building Students (§4.2) |
| GET | `/api/sections/:id/students` | `eitherAuth`+`attachActor` | roster read |
| GET | `/api/sections/my/teacher` | `eitherAuth`+`attachActor` | self-service, not Admin scope |
| GET | `/api/sections/my/student` | `protect` | self-service, not Admin scope |

### 4.2 Users — Students `/api/students` (`studentRoutes.js` → `studentController.js`)
| Method | Path | Auth | Body / Notes |
|---|---|---|---|
| GET | `/me` | `protect` | own profile |
| PUT | `/me`, PUT `/me/password` | `protect` | self-update |
| GET | `/me/lite` | `protect` | |
| GET | `/parent-lookup` | `protect` | |
| GET | `/school` | `protect` | students for the calling teacher |
| GET | `/available-users` | `protectAdmin` | |
| GET | `/bulk-import/template`, POST `/bulk-import` | `protectAdmin` + `checkPlanLimit("student")` | Excel bulk import via `multer` single-file upload |
| GET | `/export` | `protectAdmin` | Excel export |
| POST | `/` | `protectAdmin` + `checkPlanLimit("student")` | body: `fullName, email\|userId, password?, admissionNumber, rollNumber, class, section, parentId, dob, address, phone` — CONFIRMED admission number is unique **per school**, not globally (compound partial index) |
| GET | `/` , GET `/:id` | `protectAdmin` | |
| PUT | `/:id`, DELETE `/:id` | `protectAdmin` | |

### 4.3 Users — Teachers `/api/teachers` (`teacherRoutes.js` → `teacherController.js` + `TeacherassignmentController.js`)
| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/me` | `protect` | own profile |
| PUT | `/update-profile`, PUT `/change-password` | `protect` | |
| GET | `/assignments` | `eitherAuth`+`attachActor` | **separate parallel assignment system**, see §4.5 |
| POST | `/assignments`, GET `/assignments/all`, DELETE `/assignments/:id` | `protectAdmin` | |
| POST | `/` | `protectAdmin` + `checkPlanLimit("teacher")` | create |
| GET | `/`, GET `/school` (alias), GET `/:id` | `protectAdmin` | |
| PUT | `/:id`, DELETE `/:id` | `protectAdmin` | |

### 4.4 Users — Parents `/api/parents` (`parentRoutes.js` → `parentController.js`)
| Method | Path | Auth | Notes |
|---|---|---|---|
| GET `/me`, PUT `/me`, PUT `/me/password` | `protect` | self |
| GET `/dashboard` | `protect` | parent dashboard aggregate |
| GET `/child/:studentId/attendance`, GET `/child/:studentId/fees` | `protect` | scoped to the parent's linked children |
| POST `/`, GET `/`, GET `/export`, GET `/:id`, PUT `/:id`, DELETE `/:id` | `protectAdmin` | CRUD |
| GET `/debug-parent` | **none** | hardcoded test user id, returns diagnostic JSON — a leftover debug route with **no auth guard** |

### 4.5 Assignments — **two independent, parallel systems** (major finding, see §12)
| System | Mount | Model | Notes |
|---|---|---|---|
| A | `/api/assignments` (`assignmentRoutes.js` → `assignmentController.js`) | `Assignment` + `AssignmentSubmission` | Full lifecycle: create/list/get/update/delete, class+section scoped, `sectionId`-aware, student submit with up to 5 file attachments, teacher grade with numeric `marks`+`remarks` |
| B | `/api/teachers/assignments` (nested in `teacherRoutes.js` → `TeacherassignmentController.js`) | `Teacherassignmentschema.js` (separate model, fields not verified this pass — `UNKNOWN — VERIFY`) | create (admin only)/list/delete — no submission or grading endpoints found in this system |

System A detail (the one that matches `product_requirements.md`'s "Assignments" module):
| Method | Path | Auth | Body / Response |
|---|---|---|---|
| POST | `/` | `protect` (teacher only, checked via `Teacher.findOne`) | body: `title, description, subject, dueDate, attachment?, sectionId` (or legacy `class`/`section` strings) — server derives class/section from `sectionId` when given |
| GET | `/` | `protect` | role-aware: admin→all in school, teacher→own, parent→children's classes, student→own class |
| GET | `/class/:class/section/:section` | `protect` | |
| GET | `/my-submissions` | `protect` (student) | |
| GET | `/:id` | `protect` | |
| PATCH | `/:id`, DELETE | `protect` | |
| POST | `/submit` | `protect` + `documentUpload.array("files", 5)` | body: `assignmentId, submissionText` + up to 5 files. **Confirmed rule**: first submission blocked (400) if past `dueDate`; resubmission allowed any time **before grading**, regardless of due date, once graded (`gradedAt` set) it's locked (409) |
| GET | `/:assignmentId/submissions` | `protect` (teacher) | |
| PATCH | `/submissions/:submissionId/grade` | `protect` (teacher) | Grading is a **numeric `marks` + text `remarks`**, not a boolean checked-flag — resolves the `UNKNOWN` in `screens.md` "Assignment Submissions Review" |

### 4.6 Attendance — fragmented across 6 route files, mounted under `/api/attendance` (`attendenceRoutes.js` is the parent router)
| Sub-path | File | Scope |
|---|---|---|
| `/api/attendance/me` | `attendenceRoutes.js` | resolves the caller's own Student/Teacher/Staff profile id |
| `/api/attendance/logs` | `attendancelogsController.js` | Admin/Superadmin read-only audit log |
| `/api/attendance/reports/*` | `attendancereportsController.js` | `student`, `student/:studentId`, `teacher`, `staff`, `leave`, `analytics/low-attendance` |
| `/api/attendance/student` | `studentattendanceRoutes.js` → `studentattendanceController.js` | POST create (teacher/admin — **locks immediately** per in-code comment), PUT/DELETE/PATCH `:id/unlock` (admin/superadmin only — **teachers cannot edit or unlock once submitted**, resolving the `ASSUMPTION` in `user_flows.md` Flow 4), GET list, GET `/:studentId` |
| `/api/attendance/teacher` | `teacherattendanceRoutes.js` → `teacherattendanceController.js` | POST/PUT/DELETE restricted to Admin/HR only — **teachers can never mark or edit their own attendance**, except `POST /self-checkin` (one-time daily self-check-in) and `GET /today-summary` (read-only) |
| `/api/attendance/staff` | `staffattendanceRoutes.js` → `staffattendanceController.js` | Admin/HR mark & edit; delete further restricted to Admin only (not HR) |
| `/api/attendance/corrections` | `attendancecorrectionRoutes.js` → `attendancecorrectionController.js` | Teacher/HR/Staff/Admin can `POST` a correction request; only Admin/Superadmin can `PATCH :id/approve` / `:id/reject`. **This is the "attendance correction" capability `gap_analysis.md` §4 flagged as asserted-but-unbuilt — it is real and exists as its own dedicated request/approve workflow**, not an inline edit on the attendance record itself |
| `/api/attendance/leave` | `leaverequestRoutes.js` → `leaverequestController.js` | Student/Teacher/Staff `POST` to apply; Admin/Superadmin `PATCH :id/approve`/`:id/reject` |
| `/api/attendance/qr` | `qrAttendanceRoutes.js` (mounted **separately**, not nested) → `qrAttendanceController.js` | `POST /generate` (teacher), `POST /scan` (student), `GET /report` (teacher) — **QR-code-based attendance is a real, distinct mechanism not mentioned anywhere in the product docs** |
| `/api/attendance/my-child` | `attendenceRoutes.js` → `attendanceController.js` | Parent's view of their child's attendance |

### 4.7 Notices — `/api/notices` (`noticeRoutes.js` → `noticeController.js`)
| Method | Path | Auth | Notes |
|---|---|---|---|
| POST/GET `/superadmin`, PUT/DELETE `/superadmin/:id` | `protectSuperAdmin` | platform-wide notices, `schoolId: null` |
| POST `/`, GET `/`, PUT `/:id`, DELETE `/:id` | `protectAdmin` | school-scoped, `audience` enum: `students\|teachers\|parents\|admins\|all` |
| GET `/my` | `protect` | student/teacher/parent's own visible notices |
| GET `/:id` | `protect` | |
- **Teachers have no notice-creation endpoint in this backend at all** — `noticeRoutes.js` only grants create to `protectAdmin` (school-wide) and `protectSuperAdmin` (platform-wide). This directly conflicts with `product_requirements.md` §4.1 item 5 ("Admin **or Teacher** publishes") and with the Teacher "Create/Edit Notice" screen added to `screens.md` in the previous documentation pass — see §12.
- Creating a notice **does trigger real notification fan-out** (in-app `Notification` docs + Resend email) to the matching audience — CONFIRMED (`noticeController.createNotice` calls a `sendToGroup` helper per audience segment).

### 4.8 Exams & Results — `/api/exams` + `/api/results` (`examRoutes.js`, `resultRoutes.js`)
| Method | Path | Auth | Notes |
|---|---|---|---|
| GET `/exams/my`, GET `/exams/my-result/:examId` | `protect` | |
| POST `/exams/subject-marks` | `protect` (teacher) | teacher submits marks for their subject |
| POST `/exams`, POST `/exams/publish-results`, GET/PUT/DELETE `/exams`, `/exams/:id` | `protectAdmin` | |
| GET `/results/my`, `/results/my/:examId`, `/results/report-card/:examId/:studentId` | `protect` | |
| GET `/results/child/:studentId` | `protect` (parent) | |
| POST `/results/publish`, GET `/results/exam/:examId`, PUT/DELETE `/results/:id` | `protectAdmin` | |
- Publishing a result triggers a Resend email (`resultNotificationTemplate` in `notificationService.js`) — CONFIRMED real notification behavior for exams/results.

### 4.9 Fees & Payments — `/api/fees` + `/api/payments` (`feeRoutes.js`, `paymentRoutes.js`)
| Method | Path | Auth | Notes |
|---|---|---|---|
| POST `/fees`, GET `/fees` (`?status=`), PUT/DELETE `/fees/:id` | `protectAdmin` | supports lump-sum or `isInstallment` fee plans |
| GET `/fees/export` | `protectAdmin` | Excel export |
| GET `/fees/:id`, GET `/fees/student/:studentId`, GET `/fees/:feeId/receipt` | `protect` | PDF receipt download (`pdfkit`) |
| POST `/payments/fee/submit` | `protect` (student/parent) | body: `feeId, installmentId?, phoneNumber, transactionPin` — **in-app fee payment IS implemented**, but as a **manual-verification** flow, not a payment-gateway API integration: the payer submits the phone number + transaction PIN eSewa/Khalti/bank-transfer shows after payment, and an Admin cross-checks it manually |
| GET `/payments/fee/pending`, POST `/payments/fee/approve/:id`, POST `/payments/fee/reject/:id` | `protectAdmin` | manual review queue |
| GET `/payments/history` | `protectAdmin` | GET `/payments/my-payments` | `protect` |
- This resolves `user_flows.md` Flow 7's open question — in-app payment **is in scope**, but not via a payment-gateway SDK. See §12.

### 4.10 Payroll — `/api/payroll` (`payrollRoutes.js` → `payrollController.js`)
| Method | Path | Auth |
|---|---|---|
| GET `/my`, GET `/slip/:id` | `protect` (staff self-service payslip) |
| POST `/salary-config`, GET `/salary-config` | `protectAdmin` |
| POST `/generate`, POST `/generate-bulk` | `protectAdmin` |
| PUT/PATCH `/:id/mark-paid`, PATCH `/:id/pay` (all 3 aliases for the same action) | `protectAdmin` |
| GET `/`, PUT `/:id`, DELETE `/:id` | `protectAdmin` |
- Payroll covers `staffModel: Teacher \| Admin \| Receptionist` (per `payrollSchema.js`) — **not the generic `Staff` model**, an internal inconsistency in the backend itself, noted for completeness.
- Salary breakdown fields (basic, allowances: houseRent/transport/medical/other, deductions: tax/PF/absence/loan/other, attendance-based deduction via `workingDays`/`presentDays`/`absentDays`) are all CONFIRMED real fields — considerably richer than `product_requirements.md`'s one-line description of "Teacher Salary Management."

### 4.11 Chat — `/api/group-chats` (`groupChatRoutes.js` → `groupChatController.js` + `groupMessageController.js`) + Socket.IO
See §8 (Chat architecture) for the full picture — this is a **class/section group chat**, not 1:1 Teacher↔Student/Teacher↔Parent messaging.
| Method | Path | Auth |
|---|---|---|
| GET `/eligible-targets`, GET `/preview-roster` | `protectAny` |
| POST `/`, GET `/`, GET `/:id` | `protectAny` |
| PATCH `/:id/members`, PATCH `/:id/archive`, DELETE `/:id` | `protectAny` |
| GET `/:conversationId/messages`, PATCH `/:conversationId/messages/read` | `protectAny` |
| POST `/:conversationId/messages` | `protectAny` + `uploadChatMedia` + `enforceMediaSizeLimits` + `pushMediaToCloudinary` | text and/or one media attachment (image/video/voice) |

### 4.12 Notifications — `/api/notifications` (`notificationRoutes.js` → `notificationController.js`)
| Method | Path | Auth |
|---|---|---|
| GET `/` | `protect` | own notifications |
| PATCH `/read-all` | `protect` |
| PATCH `/:id/read` | `protect` |
- A near-identical, **separately maintained** notification route set exists for Teachers at the oddly-cased mount `/api/Teachernotificationroutes/` (`Teachernotificationroutes.js` → `Teachernotificationcontroller.js`, same 3 operations). `Notificationroutesadditions.js` (a third, near-duplicate implementation) is **not mounted anywhere** — dead code. See §12.

### 4.13 File Upload — `/api/upload` (`uploadRoutes.js` → `uploadController.js`) + module-specific upload routes
| Method | Path | Auth | Purpose |
|---|---|---|---|
| POST `/upload/document` | `protectAdmin` | any file, 10MB cap, Cloudinary |
| POST `/upload/photo/:type/:id` | `protectAdmin` | photo for any user type, 5MB cap, image-only |
| POST `/upload/my-photo` | `protect` | self photo upload |
| GET `/upload/documents`, DELETE `/upload/documents/:id` | `protectAdmin` | |
| PUT `/schools/me/branding` | `protectAdmin` | school logo/branding upload |
| GET/PUT `/schools/payment-qr` | `protectAdmin` | static eSewa/Khalti/bank QR image, shown on the fee-payment screen |
| POST `/group-chats/:id/messages` (media) | `protectAny` | see §4.11 / §7 |

### 4.14 Modules with **no counterpart anywhere in the product documentation** (compact inventory — full CRUD verified to exist, deep body-shape not transcribed here since none of it maps to any mobile doc)
| Module | Mount | Auth | What it is |
|---|---|---|---|
| Organizations | `/api/organizations` | **none** | generic org CRUD, no auth guard at all |
| Audit Logs | `/api/audit-logs` | `protectSuperAdmin` | security/action audit trail |
| Superadmin | `/api/superadmin` (×2 route files mounted on the same prefix) | `protect`+`authorizeRoles("superadmin")` / `protectSuperAdmin` | platform admin CRUD, dashboard stats, 2FA toggle |
| Schools | `/api/schools` | **core CRUD (`GET/POST /`, `GET/PUT/DELETE /:id`) has no auth guard**; `/me`, branding, payment-qr are `protectAdmin`; `manual-create` is `protectSuperAdmin` | tenant (school) management — this is the actual multi-tenancy backbone |
| Subscriptions & Plans | `/api/subscriptions` | mixed: `/plans` and `/demo` are public, rest `protect`/`protectSuperAdmin` | `POST /demo` is the literal backend for the "7-day free demo, no commitment" flow in `product_requirements.md` §2 |
| Leads | `/api/leads` | `protectAdmin` | sales/CRM lead tracking |
| Complaints | `/api/complaints` | `protect` (self) / `protectAdmin` (admin) | grievance/ticket system |
| Receptionist | `/api/receptionist` | `protectAdmin` (mgmt) / `protectReceptionist` (self) | front-desk role, see §3 |
| Departments | `/api/admin/departments` | `protectAdmin` | staff org structure |
| Dashboard / Admin Dashboard | `/api/admin/dashboard` (**two route files mounted on the identical prefix — 3 paths collide**: `admissions-overview`, `teacher-overview`, `fee-collection` are defined in both `Dashboardroutes.js` and `adminDashboardRoutes.js`; Express resolves to the first-mounted router, so `adminDashboardController`'s versions of those 3 are dead code) | `protectAdmin` | aggregate stats for Admin home screen |
| Reports | `/api/reports` | `protectAdmin` | `academic`, `financial`, `attendance`, `system` — resolves `api_spec.md` v0.1 §3.12's `UNKNOWN` |
| Search | `/api/search` | `protect` | global search |
| Contacts | `/api/contacts` | public `POST /` (marketing-site contact form), rest `protectSuperAdmin` | not an in-app mobile feature |
| Events | `/api/events` | `protect`/`protectAdmin` | school calendar/events, separate model from Exam Schedules |
| Backup | `/api/backup` | `authorizeRoles("superadmin")` / `protectAdmin` | full or per-school DB backup/restore |
| ID Cards | `/api/id-cards` | `protectAdmin` / `protect` (own) | PDF+QR ID card generation (`pdfkit`, `qrcode`) |
| Timetable | `/api/timetable` | `protect` (view) / `protectAdmin` (manage) | class timetable, separate from Exam/Academic Schedules |
| Student Follow-ups | `/api/admin/student-followups` | `protectAdmin` | CRM-style prospective/enrolled-student visit log, with Excel export |

---

## 5. MongoDB Models — CONFIRMED

Mongoose + MongoDB, ObjectId-style string IDs throughout (no UUID or custom string IDs found anywhere) — confirming `architecture.md`'s `String id` convention was the right call. 47 schema files exist in `src/model/`; every one below was read in full this pass. Multi-tenancy key: nearly every schema carries `schoolId` (ref `School`) — the two exceptions are `Contact` (public marketing form, not school-scoped) and `Plan` (a global catalog `Subscription` references).

**Auth / identity / tenancy**
- **User** (`userSchema.js`): `fullName*`, `email*` (unique, lowercase), `password*` (select:false, bcrypt), `role` (enum `superadmin|admin|teacher|student|parent|user`, default `user`), `isVerified` (default false), `otp`/`otpExpires`/`otpAttempts` (select:false — email-verify OTP), `resetPasswordOtp`/`resetPasswordOtpExpires`/`resetPasswordOtpAttempts` (select:false), `tokenVersion` (default 0), `phone`, `schoolId` (ref School, nullable).
- **Admin** (`adminSchema.js`): `fullName*`, `email*` (unique), `password*`, `phone`, `role` (String, default `"admin"`, **not an enum**), `profileImage`, `isActive` (default true), `schoolId` (ref School), `createdBy`/`userId` (ref User), `tokenVersion`.
- **Organization** (`organizationSchema.js`): `fullName*`, `email*` (unique), `password*`, `phone`, `schoolId` (ref School, nullable). Minimal — exact relationship to `School` not resolvable from schema alone, `UNKNOWN — VERIFY`.
- **School** (`schoolSchema.js`, tenant root): `name*`, `address*`, `phone*`, `email*` (unique), `isActive` (default true), `paymentQrUrl`, `activePlan` (ref Plan), `subscriptionStatus` (enum `active|expired|cancelled|pending`), `subscriptionEndDate`, `logo`, `principalSign`, `schoolStamp`, `settings: {maintenanceMode, openRegistration, esewaMode (enum sandbox|live)}`.
- **Plan** (`planSchema.js`): `name*` (unique, enum `basic|standard|premium|demo`), `price`, `features: {maxStudents/maxTeachers/maxAdmins/maxParents/maxClasses, hasQRAttendance, hasOnlinePayment, hasCRM, hasDocumentUpload, hasTimetable, hasNotifications, storageGB}` (all Booleans except the numeric caps), `isActive`.
- **Subscription** (`subscriptionSchema.js`): `school` (ref School, nullable pre-approval), `plan*` (ref Plan), `status` (enum `pending|active|rejected|cancelled|expired`), `months`/`durationDays`, `isDemo`, `totalAmount`, `startDate`/`endDate`, `paymentMethod*` (enum `esewa|cash|manual|demo`), `transactionId`, `requestingUserEmail/Name/Phone/Id`, `approvedAt/rejectedAt/rejectReason/cancelledAt`, `autoRenew` (default true), `remindersSent: {day10/5/2/1}`.
- **OTP** (`otp.js`, standalone): `email*`, `otp*`, `fullName`/`password` (registration only), `expiresAt*`. **Coexists with the separate inline `otp`/`resetPasswordOtp` fields already on `User`** — two OTP mechanisms in the codebase; which flow uses which is `UNKNOWN — VERIFY`.

**People**
- **Teacher** (`teacherSchema.js`): `userId*` (unique, ref User), `schoolId*`, `createdBy` (ref Admin), `employeeId*` (unique per school), `department*`, `qualification`, `subjects` (String array), `experience` (default 0), `joiningDate`, `salary` (default 0), `address`, `phone`, `bankAccountNumber`, `profileImage`, `status` (enum `active|on_leave|inactive`), mirrored `email`/`password`.
- **Student** (`studentSchema.js`): `userId*` (ref User), `schoolId*`, `createdBy` (ref Admin), `admissionNumber` (sparse, unique per school), `rollNumber`, `class*` (free-text String, **not a Class ref**), `section*` (String), `sectionId` (ref Section, nullable), `parentId` (ref **User**, not ref Parent, nullable), `guardianName` (free-text fallback), `dob`, `address`, `phone`, `profileImage`, `status` (enum `active|inactive|left`), mirrored `email`/`password`.
- **Parent** (`parentSchema.js`): `userId*` (unique, ref User), `schoolId*`, `createdBy` (ref Admin), `occupation`, `address`, `phone`, `students` (Array ref Student — **many-to-many, one parent ↔ multiple children**), `status` (enum `active|inactive`), mirrored `email`/`password`.
- **Staff** (`staffSchema.js`, non-teaching): `userId*` (unique), `schoolId*`, `employeeId`, `designation*` (enum `Accountant|Receptionist|Librarian|Driver|Cleaner|Security Guard|IT Staff|Office Staff|Others`), `department`, `phone`, `joiningDate`, `isActive`.
- **Receptionist** (`receptionistSchema.js`): `userId*` (unique), `schoolId*`, `createdBy` (ref Admin), `employeeId` (unique), `phone`, `address`, `profileImage`, `permissions: {viewStudents/viewTeachers/viewParents/viewAttendance}` (Booleans, default true), `status`.

**Academic structure**
- **Class** (`Classschema.js`): `name*`, `schoolId*` (unique per name), `createdBy` (ref Admin), `description`, `status`.
- **Section** (`Sectionschema.js`): `name*`, `classId*` (ref Class), `schoolId*` (unique per class+name), `createdBy` (ref Admin), `teachers` (Array ref Teacher) — **students are not embedded here; `Student.sectionId` is the roster source of truth.**
- **Department** (`Departmentschema.js`): `name*` (unique per school), `schoolId*`, `createdBy` (ref Admin), `headOfDepartmentId` (ref Teacher, nullable), `description`, `classes` (String array), `status`.
- **Timetable** (`timetableSchema.js`): `schoolId*`, `className*`, `section*`, `type` (enum `fixed|dynamic`), `weekNumber`, `year`, `schedule: [{day* enum Mon–Sat, periods: [{periodNumber*, subject*, teacherId (ref Teacher), startTime*, endTime*, room}]}]`, `createdBy` (ref Admin), `isActive`.

**Attendance — fragmented across 10 distinct models, not one** (resolves `feature_matrix.md`'s single-row treatment and `gap_analysis.md` §4's open "correction" question)
- **Attendance** (`attendenceSchema.js`, legacy flat model): `studentId*` (ref Student), `schoolId*`, `date*` (String), `status` (enum `present|absent|late`), `method` (enum `manual|qr|face`), `markedBy` (ref User), `note`. Unique `(studentId, date)`. Explicitly superseded per its successor's code comments — whether QR-attendance still writes here is `UNKNOWN — VERIFY`.
- **AttendanceSession** (`Attendancesessionschema.js`, one register-taking event): `schoolId*`, `teacher*` (ref Teacher), `academicYear*`, `semester*`, `class*`, `section*`, `subject*`, `sectionId` (ref Section, nullable), `date*`, `presentCount/absentCount/lateCount/totalCount` (denormalized), `locked` (default false), `lockedBy` (ref Admin), `lockedAt`, `createdBy*`/`updatedBy` (ref User). Unique `(teacher, class, section, subject, date)`.
- **AttendanceRecord** (`Attendancerecordschema.js`, one per student per session): `attendanceSession*` (ref AttendanceSession), `student*` (ref Student), `schoolId*`, `status` (enum `present|absent|late|leave|half-day`), `remarks`. Unique `(attendanceSession, student)`.
- **TeacherAttendance** (`TeacherAttendanceSchema.js`): `schoolId*`, `teacher*` (ref Teacher), `date*`, `status*` (enum `present|absent|late|leave|half-day|holiday`), `remarks`, `markedBy*` (ref Admin), `updatedBy`. Unique `(teacher, date)`. **Admin/HR-marked only** — schema comments state a teacher can never mark their own attendance.
- **StaffAttendance** (`staffattendanceSchema.js`): mirrors TeacherAttendance but for `staff*` (ref Staff), plus a `designation` snapshot. Admin/HR-marked only.
- **AttendanceCorrection** (`attendanceCorrectionSchema.js`): `schoolId*`, `targetType*` (enum `StudentAttendance|TeacherAttendance|StaffAttendance`), the matching nullable target ref, `oldStatus*`, `newStatus*`, `reason*`, `status` (enum `pending|approved|rejected`), `requestedBy*` (ref User), `reviewedBy` (ref Admin), `reviewNote`, `reviewedAt`. Confirms correction is a **request/approve workflow**, not a direct edit.
- **AttendanceLog** (`attendanceLogSchema.js`, permanent, append-only): `schoolId*`, `recordType*`, `recordId*` (ObjectId, no ref), `oldStatus*/newStatus*`, `reason`, `source*` (enum `correction|direct_edit`), `correctionId` (ref AttendanceCorrection, nullable), `editedBy*` (ref Admin), `editedAt`.
- **AttendanceSettings** (`attendanceSettingsSchema.js`, one per school): `schoolId*` (unique), `lowAttendancePercentageThreshold` (default 75), `workingDays`, `holidayDates`, five `notifyOn*` Booleans (all default true), `updatedBy` (ref Admin).
- **WeeklyRegister** (`WeeklyRegisterSchema.js`, one per school per year+semester): `schoolId*`, `academicYear*`, `semester*`, `entries: [{teacher* (ref Teacher), class*, section*, subject*, dayOfWeek* (enum sun–sat)}]`, `createdBy*`/`updatedBy` (ref Admin). This is what a Teacher reads to know what they're authorized to mark that day.
- **TeacherAssignment** (`Teacherassignmentschema.js` — distinct from the `Assignment`/homework model, an unfortunate naming collision): `teacher*` (ref Teacher), `schoolId*`, `academicYear*`, `semester*`, `class*`, `section*`, `subject*`, `createdBy` (ref Admin). Unique on the full tuple — this is the authorization record behind `/api/teachers/assignments` (§4.5 System B).

**Assignments (homework) & Exams**
- **Assignment** (`assignmentSchema.js`): `title*`, `description*`, `class*`, `section*`, `subject*`, `sectionId` (ref Section, nullable), `teacherId*` (ref Teacher), `schoolId*`, `dueDate*`, `attachment` (single String, default `""`), `status` (enum `active|closed`).
- **AssignmentSubmission** (`assignmentSubmissionSchema .js` — filename literally has a space before `.js`): `assignmentId*` (ref Assignment), `studentId*` (ref Student), `schoolId*`, `submissionText`, `attachment` (legacy single String), `attachments: [{url*, publicId, fileType, fileName, fileSize}]` (current, up to 5 per §4.5), `submittedAt`, **`marks` (Number, nullable — confirms grading is a numeric score)**, `remarks`, `gradedBy` (ref Teacher), `gradedAt`. Unique `(assignmentId, studentId)` — one submission doc per student, updated on resubmit.
- **Exam** (`examSchema.js`): `title*`, `schoolId*`, `createdBy` (ref Admin), `className*`, `section` (nullable), `subjects: [{name*, fullMarks*, passMarks*, examDate*, examTime, room}]`, `examDate*`, `status` (enum `upcoming|ongoing|completed|published`), `results: [{studentId, marks[], totalObtained, totalFull, percentage, grade, isPassed, remarks}]` — **results are embedded directly in Exam in addition to a separate Result model below; which one the controllers actually read/write is `UNKNOWN — VERIFY`, a likely internal duplication.**
- **Result** (`resultSchema.js`): `examId*` (ref Exam), `studentId*` (ref Student), `schoolId*`, `className*`, `section`, `marks: [{subject*, fullMarks*, passMarks*, obtainedMarks*, isPassed, grade}]`, `totalObtained/totalFull/percentage/grade/isPassed/rank`, `remarks`, `publishedBy` (ref Admin), `isPublished`. Unique `(examId, studentId)`.

**Fees & Payroll**
- **Fee** (`feeSchema.js`): `studentId*` (ref Student), `schoolId*`, `createdBy` (ref Admin), `title*`, `description`, `totalAmount*`, `discountPercent/discountAmount`, `paidAmount`, `remainingAmount*`, `dueDate*`, `isInstallment`, `installments: [{installmentNumber*, title, amount*, dueDate*, paidAmount, status (enum pending|partial|paid)}]`, `status`.
- **Payment** (`paymentSchema.js`): `feeId*` (ref Fee), `installmentId` (nullable, no ref), `studentId*`, `schoolId*`, `submittedBy*` (ref User), `amount*`, `method` (enum `esewa|khalti|bank_qr|cash`), `phoneNumber*` (payer's phone), `transactionPin*` (the confirmation code eSewa/Khalti shows after transfer — Admin cross-checks manually), `status` (enum `pending|approved|rejected`), `rejectionNote`, `reviewedBy` (ref Admin), `reviewedAt`.
- **Payroll** (`payrollSchema.js`): `schoolId*`, `staffId*` (refPath `staffModel`), `staffModel*` (enum `Teacher|Admin|Receptionist` — **the generic `Staff` model is not included**, an internal backend inconsistency), `month*/year*`, `basicSalary*`, `allowances {houseRent/transport/medical/other}`, `deductions {tax/providentFund/absence/loan/other}`, auto-calculated `totalAllowances/totalDeductions/grossSalary/netSalary`, `workingDays/presentDays/absentDays`, `status` (enum `pending|paid|cancelled`), `paidAt`, `paidBy` (ref Admin), `paymentMethod` (enum `cash|bank|cheque`), `remarks`, `generatedBy` (enum `manual|auto`). Unique `(staffId, month, year)`.
- **StaffSalary** (`staffSalarySchema.js`, a salary *template*, separate from Payroll's monthly runs): `schoolId*`, `staffId*` (unique, refPath `staffModel`), `staffModel*` (same enum as Payroll), `basicSalary*`, `allowances`, `pfRate` (default 10%), `taxRate` (default 5%), `workingDays` (default 26), `isActive`.

**Notices, Notifications, Chat, Events**
- **Notice** (`noticeSchema.js`): `title*`, `description*`, `schoolId` (ref School, nullable = global/superadmin notice), `isGlobal`, `createdBy*` (refPath `createdByModel`), `createdByModel*` (**enum `Admin, User` only — `Teacher` is not a valid creator**), `audience` (enum `students|teachers|parents|admins|all`), `isImportant`, `publishDate`, `expiryDate`. **No attachment field exists on this schema at all** — conflicts with `screens.md`'s Notice attachment UI (see §12 addendum below).
- **Notification** (`notificationSchema.js`): `recipient*` (ref User), `schoolId` (nullable), `title*`, `message*`, `type` (enum `fee|attendance|attendance_correction|assignment|general|subscription|payroll` — **no `exam`/`schedule`/`notice` type value**, despite notices and exams triggering real notifications per §4.7–4.8), `isRead` (default false), `refId` (no ref constraint), `refModel` (enum `Fee|Attendance|AttendanceSession|AttendanceRecord|AttendanceCorrection|Assignment|Exam|Result|Subscription|null`). No delivery-channel field.
- **GroupConversation** / **GroupMessage** — see §7 (Chat Architecture) for full field detail; unchanged from the original rewrite.
- **SchoolEvent** (`schoolEventSchema.js`): `schoolId*`, `title*`, `description`, `date*` (String), `audience` (enum `all|students|parents|teachers|staff`), `isImportant`, `createdBy` (ref User). A third, distinct calendar concept alongside Exam and Notice — not in any product doc.

**Operational / back-office (undocumented modules, §4.14)**
- **LeaveRequest** (`leaveRequestSchema.js`): `schoolId*`, `applicantType*` (enum `Student|Teacher|Staff`), `applicant*` (refPath), `fromDate*/toDate*`, `reason*`, `status` (enum `pending|approved|rejected`), `reviewedBy` (ref Admin), `reviewNote`, `reviewedAt`.
- **Complaint** (`complaintSchema.js`): `schoolId*`, `raisedBy*` (ref User), `raisedByRole*` (enum `student|parent|teacher`), `title*`, `description*`, `category` (enum `academic|fee|staff|facility|transport|other`), `priority` (enum `low|medium|high|urgent`), `ticketNumber` (auto `"TKT-00001"`, unique), `status` (enum `open|in-progress|resolved|closed|rejected`), `assignedTo` (ref Admin), `resolution`, `resolvedAt/resolvedBy`, `comments: [{author, authorRole, message*, createdAt}]`.
- **StudentFollowup** (`StudentfollowupSchema.js`, CRM-style prospective/at-risk tracking): `schoolId*`, `studentName*/faculty*/email*/contactNumber*/address*/followUpNote*`, `visitDate`, `status` (enum `pending|in-progress|resolved`), `createdBy*` (ref Admin).
- **Lead** (`leadSchema.js`, admissions pipeline): `schoolId*`, `studentName*/parentName*/email*/phone*/address/applyingForClass*`, `status` (enum `inquiry|contacted|applied|interview|admitted|rejected|dropped`), `source` (enum `walk-in|phone|website|referral|social-media|other`), `assignedTo` (ref Admin), `notes`, `followUpDate`, `createdBy`.
- **Document** (`documentSchema.js`, generic Cloudinary-backed store): `schoolId*`, `ownerId*` (refPath `ownerModel`), `ownerModel*` (enum `Student|Teacher|Parent|Admin|School`), `title*`, `documentType*` (enum incl. `marksheet|certificate|id_card|birth_certificate|transfer_certificate|character_certificate|cv|teaching_license|academic_certificate|experience_letter|school_license|registration|tax_document|photo|other`), `fileUrl*`, `publicId*`, `fileType`, `fileSize`, `uploadedBy` (ref User). **Almost certainly the real backing store for `product_requirements.md` §4.2's "ID Card"/"Certificate" bundle-scan signals** — one generic document model, not separate modules.
- **Contact** (`ContactSchema.js`, public marketing-site form, not school-scoped): `name*`, `email*`, `role` (enum `administrator|it-director|teacher|other`), `message*`, `status` (enum `new|read|replied`), `reply: {message, repliedBy, repliedAt}`.
- **AuditLog** (`AuditLog.js`): `action*`, `user` (default `"System"`), `userId` (no ref), `role` (default `"system"`), `category` (enum `Auth|User|Settings|Security`), `status` (enum `success|warning|danger`), `ip`, `meta` (Mixed).

---

## 6. File Uploads — CONFIRMED

All file storage is **Cloudinary** (external, not local disk) via `multer` with **in-memory storage** (`multer.memoryStorage()` — the file arrives as a `Buffer`, the controller/middleware then streams it to Cloudinary explicitly). Three distinct upload configurations exist:

| Config | Where | Allowed types | Size cap | Used by |
|---|---|---|---|---|
| `photoUpload` | `cloudinaryConfig.js` | image only | 5MB | profile photos (self and admin-assigned) |
| `documentUpload` | `cloudinaryConfig.js` | any | 10MB | general documents, assignment attachments (up to 5 per submission) |
| Chat media upload | `chatMediaUpload.js` | image (jpeg/png/webp/gif), video (mp4/quicktime/webm/3gpp), audio/voice (webm/mp4/mpeg/ogg/wav) | image 15MB / video 100MB / voice 25MB (hard multer ceiling 100MB, checked twice) | one attachment per group chat message, folder `edumanage/chat/{conversationId}` |

No local/on-server file storage was found anywhere. This resolves `api_spec.md` v0.1 §4's file-upload-mechanism `UNKNOWN` — it's Cloudinary, buffer-then-stream, not a separate upload-then-reference REST step (the file is uploaded in the same request as the resource it attaches to).

## 7. Chat Architecture — CONFIRMED, **conflicts with product docs — see §12**

- **Model**: class/section-scoped **group chat**, not 1:1 messaging. A `GroupConversation` belongs to a `classId` (+ optional `sectionId`), has an array of `teachers` and an array of `members` (**typed to reference only `Student`** — there is no field for Parent participants in the schema at all).
- **Roles that can send messages**: `GroupMessage.senderRole` is a 2-value enum, `["teacher", "student"]`. **Parents cannot send or receive group chat messages** — confirmed at the schema level, not just a missing UI screen.
- **Creation**: a Teacher creates the group (`createdBy: Teacher`, required).
- **REST layer**: `/api/group-chats/*` (§4.11) handles conversation CRUD, message history (paginated — pagination mechanism not verified in detail this pass, `UNKNOWN — VERIFY` exact query params), read receipts, and message send (with optional one media attachment).
- **Real-time layer**: **Socket.IO**, confirmed (`socket.io` in `package.json`, wired in `server.js` with a raw `http.Server` — the code's own comment notes an earlier version never created that server, so socket connections never actually worked until this fix). Socket auth (`authenticateSocket.js`) verifies the JWT and resolves the connecting account as **either a `Teacher` or a `Student` only** — `Admin`/`Parent` sockets are rejected outright (`next(new Error("User is neither a teacher nor a student"))`). **This means Parents cannot connect to the real-time chat layer at all, even if a future UI tried to give them message-read access.**
- **Socket events**: `group:join` (with ack), `group:leave`, `group:typing` (broadcast to room), `group:read` → broadcasts `group:read-receipt`. New messages are emitted server-side from the REST send handler itself (`io.to("group:"+conversationId).emit("group:new-message", payload)`) — sending is REST, not a socket emit from the client; only the live fan-out to other room members is via socket.
- **No 1:1 messaging of any kind exists in this codebase** — no Teacher↔Parent, Teacher↔single-Student, or Admin-initiated conversation model was found anywhere.

## 8. Notification Architecture — CONFIRMED, **conflicts with product docs — see §12**

- **Persistence**: every notification is a `Notification` document (`recipient`, `schoolId`, `title`, `message`, `type` enum `fee|attendance|attendance_correction|assignment|general|subscription|payroll`, `isRead`, optional `refId`/`refModel` polymorphic reference).
- **Delivery channels, confirmed**: (1) in-app, via `GET /api/notifications` (poll/pull, not pushed to the client) and (2) email, via Resend (`sendEmail.js`), for the specific events that call `notificationService.notify(...)` with an `email`/`emailHtml` payload — confirmed for: new notice (`noticeController`), exam schedule, published results, OTP, admin-welcome-with-credentials, fee-due/overdue reminders.
- **No push notification provider of any kind is integrated.** A full-repo grep for `firebase`, `fcm`, `push notification`, `apns`, `expo-server`, `onesignal` returned **zero matches**. This resolves — by contradicting — the `ASSUMPTION` in `product_requirements.md` §6 and `architecture.md` §9 that FCM would be used: **there is no push notification backend to integrate against today.** A mobile client can only poll `GET /api/notifications` or wait for email.
- **No real-time delivery for notifications** — unlike Chat, no Socket.IO event exists for notifications; the only real-time channel in the entire backend is the group-chat socket namespace (§7).
- **Scheduled/automatic notification jobs are wired but disabled.** `server.js` imports `startFeeNotificationJob`, `startSubscriptionCron`, `startBackupCron`, `startPayrollCron`, `startSalaryReminderCron` — every one of these calls is **commented out** in the committed `server.js`. As shipped, none of the automatic recurring notification triggers (fee-due reminders, subscription-expiry checks, payroll reminders) actually run on a schedule; notifications only fire synchronously from direct user actions (e.g., an Admin publishing a notice).

## 9. Real-Time Communication — CONFIRMED

**Scoped to Group Chat only.** Confirmed by grepping the entire `src/` tree for Socket.IO usage outside `src/sockets/` — no other module emits or listens on a socket. Attendance's "instantly visible to Admin + parent" behavior (`product_requirements.md` §4.1 item 3) is **not real-time** in the backend — it's a normal REST write, visible to other roles only the next time they call a GET endpoint. See §12.

## 10. External Services — CONFIRMED

| Service | Package | Purpose | Notes |
|---|---|---|---|
| **Cloudinary** | `cloudinary`, `multer-storage-cloudinary` (installed but not actually used — see §6, uploads go through manual buffer-streaming instead) | all file storage | photos, documents, assignment attachments, chat media, school branding, payment QR images |
| **Resend** | `resend` | all transactional email | OTP, notices, exam/result notifications, fee reminders, admin welcome-with-credentials. **The sole active email path** — see below |
| **eSewa / Khalti / bank QR / cash** | none (no gateway SDK) | fee payment method labels only | **Not a live payment-gateway integration** — the school uploads a static QR image, the payer manually enters a phone number + transaction PIN from their own eSewa/Khalti app after paying, and an Admin manually cross-checks and approves/rejects. `School.settings.esewaMode` (`sandbox`/`live`) exists on the schema but no eSewa API call was found anywhere in the codebase. |
| **Google Meet / Zoom / any video-meeting service** | — | — | **Not present.** A full-repo grep for `google meet`, `zoom`, `meeting link` returned zero matches — see §12, this is the single biggest missing-feature finding |
| **`nodemailer`, `@emailjs/nodejs`** | listed in `package.json` | — | **Installed but unused** — grepped the entire `src/` tree, zero `require`/`import` of either package. The active email path is Resend exclusively. |
| **`node-cron`** | `node-cron` | scheduled jobs | wired but **all cron starts are commented out** in `server.js` — see §8 |
| **`pdfkit` + `qrcode`** | — | PDF generation (fee receipts, report cards, ID cards) + QR generation (ID cards, QR-based attendance) | |
| **`exceljs` + `xlsx`** | — | bulk import/export (students, fees, follow-ups) | |
| **`sharp`** | — | image processing (likely resize/optimize before/after Cloudinary) | exact usage sites not traced this pass, `UNKNOWN — VERIFY` |
| **`nepali-date-converter`** | — | Nepali (Bikram Sambat) calendar support | referenced in code comments (e.g. fee due-date formatting) — confirms a Nepal-market product, consistent with `gap_analysis.md`'s speculation about Nepali payment services |

---

## 11. Remaining `UNKNOWN — VERIFY` items

These could not be resolved from static source reading alone and need either a running instance, the `.env` file, or a question to the backend team:

- Production base URL / hosting provider (code only shows `PORT` env var + a CORS allow-list implying Vercel + a custom domain).
- Exact pagination convention for chat message history and any other list endpoint (query params like `page`/`limit`/`cursor` were not confirmed present or absent across every list endpoint — spot-checked a few, not exhaustive).
- How an `"hr"`-role Admin account actually gets created (no controller path found that sets it).
- The real purpose of the public `POST /api/auth/register` self-registration path and the separate PIN-reset flow.
- `sharp`'s exact call sites and effect (resize? format conversion? watermark?).
- Whether the "Transport," "ID Card" (confirmed to exist — §4.14), "Library," "Certificate" terms flagged in `product_requirements.md` §4.2 from the live-site JS bundle scan have further backend modules beyond ID Cards — a targeted grep for "Transport," "Library," "Certificate" route/model names was **not performed this pass**; only ID Cards and (via Payroll) something Leave-adjacent were confirmed. Recommend a follow-up grep before finalizing scope.

---

## 12. Conflicts With Product Documentation

Cross-referenced against `product_requirements.md`, `feature_matrix.md`, `screens.md`, `user_flows.md`. Each item below is a factual mismatch between what the code does and what the mobile docs assumed or asserted — not a judgment about which side is "right." Where the earlier docs made an explicit `ASSUMPTION` that turned out wrong, that's called out as **resolved**, not as a defect in those docs — they were correctly hedged.

| # | Area | Product docs say | Backend actually does | Severity |
|---|---|---|---|---|
| 1 | **Online Classes** | `product_requirements.md` §4.1 item 9: Teacher shares a meeting link (e.g. Google Meet), Student joins — an entire module, with dedicated screens in `screens.md` §D/E and a full user flow in `user_flows.md` Flow 10 | **No such feature exists anywhere in the backend.** No route, no model field, no meeting-link concept, zero grep matches for "meet"/"zoom"/"meeting link" in the entire source tree | **High** — the whole "Online Classes" epic in `implementation_backlog.md` (E9) has nothing to integrate against; either this is unbuilt on the backend, planned for a different repo, or was never real |
| 2 | **Chat scope** | Described as Teacher↔Student and Teacher↔Parent messaging (`product_requirements.md` §4.1 item 10, `feature_matrix.md` chat rows for both pairs) | It's **class/section group chat**, Teacher↔Student(s) only. **Parents have no schema field, no send permission, and are explicitly rejected at the Socket.IO auth layer.** There is no 1:1 conversation model of any kind | **High** — `implementation_backlog.md` E10 (Chat) was scoped around 1:1 threads; the real shape is one group per class/section |
| 3 | **Push notifications** | `product_requirements.md` §6/§7 assumed FCM; `architecture.md` §9 deferred FCM wiring pending confirmation | **No push provider integrated at all** (zero grep matches). Delivery is in-app poll + email only | **Medium** — resolves the open question definitively as "not yet built," rather than "unconfirmed" |
| 4 | **"Instantly visible" attendance** | `product_requirements.md` §4.1 item 3 / `user_flows.md` Flow 4 describe attendance as instantly visible to Admin + parent, implying some live-push behavior | Plain REST write; visibility to other roles happens on their next `GET`, no real-time channel touches attendance at all (only Chat uses Socket.IO) | **Low-Medium** — doesn't block building the UI, but "instant" should not be read as "push-driven" |
| 5 | **Roles** | Exactly 4 roles (Admin/Teacher/Student/Parent), stated as confirmed in `product_requirements.md` §3 | **8 distinct actor types** exist in the auth/authorization code: superadmin, admin, hr, teacher, student, parent, staff, receptionist | **High** for the Admin surface specifically — if any HR/Staff/Receptionist workflows are meant to be in the mobile app's scope, `feature_matrix.md` and `screens.md` need entirely new rows/screens. If they're genuinely web-admin-only, that should be an explicit scope decision, not a silent gap |
| 6 | **Notices — who can create** | `product_requirements.md` §4.1 item 5: "Admin **or Teacher** publishes"; `screens.md` was updated last pass to add a Teacher "Create/Edit Notice" screen | **Only Admin and Superadmin have a create-notice endpoint.** No teacher-facing notice-creation route exists in `noticeRoutes.js` | **High** — the screen added to `screens.md` in the prior gap-analysis pass has no backend to call; needs a decision (build the endpoint, or roll back the screen) |
| 7 | **Assignments — delete rights** — **RESOLVED 2026-08-26, controller traced + live-verified** | `feature_matrix.md` gives Teacher only `C R U` (no delete) on Assignments; `screens.md` (flagged as conflicting in the prior pass) lists a delete action | `deleteAssignment` (`assignmentController.js`) does enforce real ownership: it branches on `req.admin` (Admin → any assignment in their school) vs. else (Teacher → only `Teacher.findOne({userId: req.user._id})`'s own assignments, 403 otherwise). **But the route only applies `protect`, never `protectAdmin`** (`assignmentRoutes.js:47`) — and `protect` (`authMiddleware.js`) never sets `req.admin`, only `protectAdmin` does. So the `req.admin` branch is **dead code on this specific route**: a real Admin account gets rejected too, falling into the Teacher-lookup branch and failing it. **Live-verified against the running local backend** (2026-08-26): Student → `403`, Admin → `403` (confirms the bug — an Admin genuinely cannot delete an assignment through this endpoint, contradicting the code's own "Admin can delete any assignment" comment), owning Teacher → `200` success | **Resolved as Medium→Low for this app**: Teacher delete is real and correctly ownership-scoped (settles the `feature_matrix.md` conflict — Teacher does have working delete rights). The Admin dead-code bug is real but **doesn't affect this app** — the mobile client only ever shows a delete action to Teacher, never Admin (`assignments_list_screen.dart`), so nothing here needs a client-side change. Worth flagging to whoever owns the backend/web-admin panel, since any Admin-facing UI calling this same route would silently fail to delete. |
| 8 | **In-app fee payment** | `user_flows.md` Flow 7 explicitly treats this as **out of scope** ("doc only describes viewing, not paying... treat as out of scope until confirmed") | **It's implemented** — `POST /api/payments/fee/submit` — but as a manual phone-number + transaction-PIN verification flow reviewed by an Admin, not a payment-gateway checkout | **High** — this was explicitly excluded from `implementation_backlog.md` (E7-F4, "out of scope, not backlogged"); it needs to be added back in as a real, backend-supported feature, scoped correctly (manual verification, not gateway SDK) |
| 9 | **Attendance correction** | `gap_analysis.md` §4 flagged Admin's "correction" capability as asserted in `feature_matrix.md` but with no corresponding screen action, and recommended **not** building it until confirmed | **It's real and fully built** — a dedicated request/approve/reject workflow (`/api/attendance/corrections`), separate from directly editing an attendance record | **Medium** — this should now be un-flagged and given a proper screen/flow, since it's confirmed real, just modeled differently than `feature_matrix.md` assumed (a correction *request*, not a direct edit) |
| 10 | **Modules with zero mobile-doc presence** | N/A | Organizations, Superadmin platform administration, full multi-tenant School CRUD, Subscriptions/Plans (incl. the literal "7-day free demo" endpoint), Leads/CRM, Complaints, Receptionist role, Departments, admin Dashboard/Reports/Search, Contacts (marketing form), Events (separate from Exam Schedules), Backup/Restore, ID Cards, Timetable (separate from Exam Schedules), Student Follow-ups, QR-code attendance, staff Leave requests | **High** for scoping — none of this is necessarily mobile-in-scope, but it confirms `product_requirements.md` §4.2's suspicion (Transport/Leave/ID Card/Library/Certificate) was an undercount; the real gap between "what the marketing doc describes" and "what the product actually is" is much larger than a handful of bundle terms suggested |
| 11 | **Multi-tenancy at login** | `product_requirements.md` §2 flagged as `ASSUMPTION`: unclear if login needs a school code/subdomain | **Resolved** — no tenant field at login; `schoolId` is resolved server-side from the account. No UI change needed beyond plain email+password | **Resolved (positive)** |
| 12 | **Grading model** | `screens.md` "Assignment Submissions Review" flagged as `UNKNOWN`: checked-flag vs. score | **Resolved** — numeric `marks` + text `remarks` | **Resolved (positive)** |
| 13 | **Late submission rule** | `user_flows.md` Flow 5 flagged as `UNKNOWN` | **Resolved** — first submission blocked past due date; resubmission allowed any time before grading | **Resolved (positive)** |
| 14 | **Credential delivery on account creation** | `user_flows.md` Flow 3 flagged as `ASSUMPTION`: auto-emailed vs. manually relayed | **Resolved for Admin accounts** — `adminWelcomeEmailTemplate` confirms Admin credentials (including plaintext password) are emailed automatically. Teacher/Student/Parent creation flows were not traced for the same email-send call this pass — `UNKNOWN — VERIFY` whether they get the same treatment | **Partially resolved** |
| 15 | **Notice attachments** | `product_requirements.md` §4.1 item 5 and `screens.md`'s Notices List/Detail and Create Notice screens all describe an optional attachment on a notice | **`noticeSchema.js` has no attachment field of any kind** — title, description, audience, dates, and creator fields only. A notice cannot carry a file in this backend as committed | **Medium** — the attachment picker/tap-to-view affordance in `screens.md` §B/§C has nothing to bind to; either the schema needs a field added or that part of the screen spec should be marked out of scope for v1 |
| 16 | **Exam results — duplicate storage** | N/A (product docs don't describe the internal data model) | `examSchema.js` embeds a `results[]` array directly on the Exam document, **in addition to** the fully separate `Result` collection (`resultSchema.js`) that mirrors the same data. Which one the controllers treat as the source of truth is `UNKNOWN — VERIFY` | **Low** — an internal backend inconsistency, not a product-doc conflict, but worth flagging before building any Result-consuming screen so the mobile client reads from the correct source |

**Backend code-quality note (not a product-doc conflict, flagged for awareness only):** `receptionistController.js` sets `user.role = "receptionist"` on a `User` document, but `userSchema.js`'s `role` enum is `superadmin|admin|teacher|student|parent|user` — `"receptionist"` is not a member. As written, that `.save()` call would fail Mongoose enum validation. Not fixed here per the "do not modify backend" instruction — reported so it isn't mistaken for a working, tested code path if the mobile app ever needs to model a Receptionist account.

### Recommended next actions (not performed here — planning only, per the "do not modify backend" and "do not invent" instructions)
1. Decide, with the backend team, whether Online Classes (#1) is genuinely absent or lives in a different service — this blocks `implementation_backlog.md` Epic E9 entirely.
2. Rescope Chat (#2) and Notices (#6) in `feature_matrix.md`/`screens.md`/`user_flows.md`/`implementation_backlog.md` to match the real group-chat model and Admin-only notice creation, or confirm a backend change is planned.
3. Un-defer push notifications planning (#3) as "not built yet" rather than "unconfirmed," and decide whether FCM gets added to the backend or the mobile app accepts poll+email-only for v1.
4. Add fee payment submission (#8) back into scope, sized as a manual-verification flow, not a gateway integration.
5. Formally scope-decide the 8-actor role reality (#5) and the fifteen-plus undocumented modules (#10) — most are very likely web-admin/back-office only, but that should be a stated decision, not an implicit one.
6. Decide whether Notice attachments (#15) get added to the schema or the attachment affordance is dropped from `screens.md`'s Notice screens for v1 — don't build a picker UI against a field that doesn't exist server-side.
