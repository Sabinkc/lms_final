# CloudsLMS Flutter — Production Implementation Backlog

> Status: DRAFT v0.2 — planning artifact only, **no code written**. Derived from `product_requirements.md`, `feature_matrix.md`, `screens.md`, `user_flows.md`, `design_system.md`, `architecture.md`, `api_spec.md`, `implementation_plan.md`, and `gap_analysis.md`. Every item traces back to one of those docs; nothing here introduces a feature, screen, or rule that isn't already stated or explicitly flagged as an assumption in them. Where a doc marks something `UNKNOWN`/`ASSUMPTION`/`DISCREPANCY`, this backlog carries that flag forward rather than resolving it.
>
> **v0.2 update**: `api_spec.md` was rewritten with facts verified against the real backend source (`https://github.com/ArbindDas/SujalbackendForStudentmanagement`, cloned read-only). Every task previously tagged `[BLOCKED BY BACKEND]` was re-checked against it: most moved to **ready-to-wire** (a real, confirmed endpoint now exists — cited inline), a handful moved to a new **`[BLOCKED — NO BACKEND SUPPORT]`** status (the backend confirms the feature does not exist at all — Online Classes, Teacher notice creation, push/FCM — these need a product/backend decision, not more integration work), and a few remain genuinely `UNKNOWN — VERIFY` per `api_spec.md`'s own remaining-unknowns list (§11). Fee payment (E7) was un-parked from "out of scope" — it's confirmed implemented. Chat (E10) was rescoped from a 1:1 messaging model to the confirmed class/section group-chat model. See each epic's notes for specifics, and Appendix C for the new "no backend support" bucket.

## How to read this backlog

**Hierarchy**: `Epic → Feature → Task → Subtask`, IDs like `E3-F2-T1-S2` (Epic 3, Feature 2, Task 1, Subtask 2) for traceability into sprint tooling.

**Attributes** — assigned at Epic/Feature/Task level in full; Subtasks inherit **Priority**, **Role**, and **Dependencies** from their parent Task unless explicitly overridden, and carry their own **Complexity** and **Testing** tag inline (the two attributes that actually vary at that granularity) — this keeps ~300 subtasks scannable instead of repeating five identical columns per line.

| Attribute | Values |
|---|---|
| **Priority** | `P0` blocking/critical-path · `P1` high, core MVP · `P2` medium, important but not launch-blocking · `P3` low, polish/nice-to-have |
| **Role** | The end-user role(s) this serves — `Admin`/`Teacher`/`Student`/`Parent`/`All` — or `System` for cross-cutting infrastructure with no direct end-user role |
| **Dependencies** | Other backlog items (by ID) that must land first |
| **Backend Dependency** | `None` (mock-repository-sufficient) · or the specific `UNKNOWN` it needs resolved, citing `api_spec.md` |
| **UI Dependency** | `None` · or what's needed from `design_system.md`/`screens.md` (e.g. visual verification, an undecided nav IA) |
| **Complexity** | `S` small (~part of a day) · `M` medium (~1–3 days) · `L` large (~3–7 days) · `XL` (>1 week, should be split further before sprint planning) — relative sizing, not a time commitment |
| **Testing** | `Unit` · `Widget` · `Integration (mock)` · `Integration (live)` · `Golden` (visual/theme regression) · `Manual QA` · `N/A` |

**Status tag** — every Feature and Task carries one of:
- **`[CAN IMPLEMENT NOW]`** — buildable today against a mock repository per `architecture.md`'s Repository pattern (§1, §5); no real backend contract required to build and unit/widget-test it. As of v0.2, most items also carry a confirmed real endpoint to wire against — noted inline as "ready to wire."
- **`[BLOCKED BY BACKEND]`** — a specific fact this task needs is still genuinely `UNKNOWN — VERIFY` per `api_spec.md` (not "we haven't looked yet" — `api_spec.md` looked and couldn't determine it statically). Cited to the specific remaining unknown, not a generic "endpoint unknown."
- **`[BLOCKED — NO BACKEND SUPPORT]`** *(new in v0.2)* — `api_spec.md` positively confirms the backend does **not** implement this at all (not merely undocumented — actually absent: zero routes, zero model fields, zero grep matches). This is a different kind of blocker: it needs a product/backend-team decision (build it, or drop it from mobile v1), not more mobile-side integration work. Do not schedule engineering time against these until that decision is made.

This backlog is organized **by module (Epic)** for engineering execution — you build a module's UI and its backend wiring close together in the same sprint once unblocked. For sprint-planning convenience, **Appendix A** and **Appendix B** at the end re-list every item split purely by status, satisfying the literal Can-Now/Blocked separation without breaking module cohesion in the main body.

**Sequencing**: this backlog does not repeat `implementation_plan.md`'s phase rationale — treat that document as the authoritative *ordering*, and this one as the authoritative *decomposition* within each phase.

---

## E0 — Foundation & Core Architecture
**Priority**: P0 · **Role**: System · **Dependencies**: none · **Backend Dep**: partial (see split) · **UI Dep**: `design_system.md` tokens (available) · **Complexity**: L · **Testing**: Unit + Widget

### E0-F1 — Project Scaffolding & DI `[CAN IMPLEMENT NOW]`
*architecture.md §2, §5*

| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E0-F1-T1 | Create feature-based folder structure | P0 | System | — | None | None | S | N/A |
| E0-F1-T2 | Build `Result<T>` wrapper + typed exceptions | P0 | System | E0-F1-T1 | None | None | S | Unit |
| E0-F1-T3 | Build service locator wiring mock repos for every feature | P0 | System | E0-F1-T1 | None | None | M | Unit |
| E0-F1-T4 | `main.dart` skeleton: `MultiProvider` + `MaterialApp` | P0 | System | E0-F1-T3 | None | None | S | Widget |

- E0-F1-T1-S1 build `core/`, `features/`, `shared/` dirs — C:S, Test:N/A
- E0-F1-T1-S2 stub one folder per confirmed module (auth, attendance, assignments, exams_schedule, fees, payroll, notices, chat, notifications, online_classes, admin_management, profile) — C:S, Test:N/A
- E0-F1-T2-S1 `NetworkException`/`UnauthorizedException`/`ValidationException`/`ServerException`/`UnknownException` types — C:S, Test:Unit
- E0-F1-T3-S1 wire mock repos for each feature into the locator — C:M, Test:Unit
- E0-F1-T3-S2 verify swap-to-http is a single-point change (spike/smoke test) — C:S, Test:Unit

### E0-F2 — Local Storage `[CAN IMPLEMENT NOW]`
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E0-F2-T1 | Secure storage service (token, refresh token slot) | P0 | System | E0-F1-T1 | None | None | S | Unit |
| E0-F2-T2 | Local prefs service (theme, last-selected child, cached UI state) | P1 | System | E0-F1-T1 | None | None | S | Unit |

### E0-F3 — Theming `[CAN IMPLEMENT NOW]` (visual sign-off pending)
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E0-F3-T1 | `AppTheme` light/dark from extracted color + radius tokens | P0 | System | E0-F1-T1 | None | None | M | Golden |
| E0-F3-T2 | Typography scale (Material 3 default, Inter/Roboto fallback) | P1 | System | E0-F3-T1 | None | Needs visual verification (design_system.md §2) | S | Golden |
| E0-F3-T3 | Component theme: buttons, cards, text fields, app bar | P1 | System | E0-F3-T1 | None | Needs visual verification (design_system.md §5) | M | Golden |
| E0-F3-T4 | `ThemeMode.system` default + manual override, persisted | P1 | System | E0-F2-T2, E0-F3-T1 | None | None | S | Widget |

### E0-F4 — Routing & Role Guards `[CAN IMPLEMENT NOW]`
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E0-F4-T1 | Central route table (`app_router.dart`) | P0 | System | E0-F1-T4 | None | Nav IA decision still open (`design_system.md` §5 internal inconsistency — see gap_analysis §4) | M | Widget |
| E0-F4-T2 | Role-based guard (checks `AuthProvider` role vs. route allow-list) | P0 | All | E0-F4-T1, E1-F1-T4 | None | None | M | Unit + Widget |
| E0-F4-T3 | Four empty role Dashboard placeholders | P0 | All | E0-F4-T2 | None | None | S | Widget |

### E0-F5 — Shared Loading/Empty/Error Widgets `[CAN IMPLEMENT NOW]`
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E0-F5-T1 | `LoadingView` (skeleton, per `screens.md` convention) | P0 | All | E0-F1-T1 | None | None | S | Widget |
| E0-F5-T2 | `EmptyStateView` (illustration + message + optional CTA) | P0 | All | E0-F1-T1 | None | None | S | Widget |
| E0-F5-T3 | `ErrorView` (retry callback, network vs. server distinction) | P0 | All | E0-F1-T1 | None | None | S | Widget |

### E0-F6 — Real API Client Integration `[CAN IMPLEMENT NOW]` for T2–T4 (ready to wire); T1 remains `[BLOCKED BY BACKEND]`
*api_spec.md §1, §2, §4, §7*
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E0-F6-T1 | Configure real base URL + version prefix via `--dart-define` | P0 | System | E0-F1-T1 | **Blocked** — production host/port genuinely `UNKNOWN — VERIFY` (api_spec.md §1, §11 — not in source, deploy-specific; API prefix `/api` and "no version segment" ARE confirmed) | None | S | N/A |
| E0-F6-T2 | Auth-header injection matching real auth scheme | P0 | System | E0-F6-T1, E1-F2 | **Confirmed** — `Authorization: Bearer <token>` header (JWT); a few GET/download routes also accept `?token=` query param (api_spec.md §2) | None | M | Unit |
| E0-F6-T3 | Error mapping to real response/error envelope | P0 | System | E0-F6-T1 | **Confirmed, but non-uniform** — most endpoints return `{success,message,data}`, a minority return bare `{message}`, one debug endpoint returns `{error}` instead of `message`. Map defensively (check for `data` presence, don't trust `success` alone); 401 shape also differs by which middleware rejected the request (`protect` returns a `code` field, `protectAdmin` doesn't) — see api_spec.md §2 for both call-outs | None | M | Unit |
| E0-F6-T4 | `RealtimeService` abstraction bound to real transport | P1 | System | E0-F6-T1 | **Confirmed** — Socket.IO v4, JWT passed via the connection's `auth` handshake option (not a header/cookie), scoped to chat only (no notification real-time channel exists) — see api_spec.md §7 and E10-F2 | None | L | Integration (live) |

---

## E1 — Authentication & Session
**Priority**: P0 · **Role**: All · **Dependencies**: E0 · **Backend Dep**: split · **UI Dep**: None · **Complexity**: L · **Testing**: Widget + Unit

### E1-F1 — Login UI (mock) `[CAN IMPLEMENT NOW]`
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E1-F1-T1 | Splash screen (session check → route) | P0 | All | E0-F1-T3 | None | None | S | Widget |
| E1-F1-T2 | Login screen UI + client-side validation | P0 | All | E0-F5 | None | None | M | Widget |
| E1-F1-T3 | Forgot Password screen UI | P2 | All | E1-F1-T2 | None (existence itself is `ASSUMPTION` — `screens.md` "Forgot Password Screen") | None | S | Widget |
| E1-F1-T4 | `AuthProvider` (mock): session state, current user/role | P0 | All | E0-F1-T3 | None | None | M | Unit |
| E1-F1-T5 | Logout flow + confirmation dialog | P0 | All | E1-F1-T4 | None | None | S | Widget |

- E1-F1-T1-S1 logo + progress indicator while mock session check runs — C:S, Test:Widget
- E1-F1-T1-S2 silent fallback to Login on corrupt/expired session — C:S, Test:Unit
- E1-F1-T2-S1 credential fields (scheme placeholder: email/username + password) — C:S, Test:Widget
- E1-F1-T2-S2 inline error state (bad credentials) vs. banner (network failure) — C:S, Test:Widget
- E1-F1-T4-S1 mock login against seeded fixture users (one per role) — C:M, Test:Unit
- E1-F1-T5-S1 clear token, cancel in-flight requests, route to Login — C:S, Test:Unit
- E1-F1-T5-S2 silent variant for 401-triggered logout with "session expired" toast — C:S, Test:Widget

### E1-F2 — Real Auth Integration `[CAN IMPLEMENT NOW]` for T1/T3/T4 (ready to wire); T2 resolved-no-work; T5 removed
*product_requirements.md §7 items 2,4; api_spec.md §2, §4.1*
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E1-F2-T1 | Real login API call | P0 | All | E1-F1, E0-F6-T2 | **Confirmed** — `POST /api/auth/login`, body `{email, password}`, returns `{success, token, refreshToken, role, data}` (api_spec.md §2, §4.1). Client must branch on `role` in the response, not assume a schema/school field | None | M | Integration (live) |
| E1-F2-T2 | Multi-tenant identification on login | P0 | All | E1-F2-T1 | **Confirmed resolved — no work needed.** Login body is exactly `{email, password}`; `schoolId` is resolved server-side from the account, not supplied by the client (api_spec.md §2). This task is complete as soon as T1 lands; do not add a tenant/school-code field to the Login screen | None | — | N/A |
| E1-F2-T3 | Token refresh flow | P1 | All | E1-F2-T1 | **Confirmed** — `POST /api/auth/refresh`, body `{refreshToken}`, returns fresh `{token, refreshToken}` pair. Access token: 60m expiry. Refresh token: 30d expiry, revoked via server-side `tokenVersion` bump on logout — no access-token revocation, only refresh (api_spec.md §2) | None | M | Integration (live) |
| E1-F2-T4 | Real Forgot-Password flow | P2 | All | E1-F1-T3 | **Confirmed** — `POST /api/auth/forgot-password`, `/resend-reset-otp`, `/reset-password`, OTP-based (api_spec.md §2, §4.1). Note: a second, separate "PIN reset" flow also exists (`/forgot-pin` etc.) whose purpose is `UNKNOWN — VERIFY` (api_spec.md §11) — do not build UI for it without more information, it may not be a mobile-relevant concept | None | M | Integration (live) |
| E1-F2-T5 | Account lockout policy enforcement | ~~P2~~ | All | E1-F2-T1 | **Confirmed absent — remove this task.** `api_spec.md` §2 confirms no lockout-after-N-failed-logins mechanism exists anywhere in the backend (only OTP-retry-attempt counters, a different concept). There is nothing to enforce against; do not build client-side lockout UI implying a server policy that doesn't exist | None | — | N/A |

---

## E2 — Admin: Academic Structure & User Management
**Priority**: P0 · **Role**: Admin (Manage Parents also touches Parent/Student linkage) · **Dependencies**: E0, E1 · **Backend Dep**: split · **UI Dep**: None · **Complexity**: XL · **Testing**: Widget + Unit

### E2-F1 — Manage Classes/Sections/Subjects `[DONE]` — built and verified live 2026-08-23
*product_requirements.md §4.1 item 2; screens.md §C; this is the hard onboarding prerequisite per user_flows.md Flow 3*
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E2-F1-T1 | List screen (classes/sections/subjects), skeleton/empty/error | P0 | Admin | E0-F5, E1-F1-T4 | **Done** | None | M | Widget — done |
| E2-F1-T2 | Add/Edit form | P0 | Admin | E2-F1-T1 | **Done** | None | M | Widget — done |
| E2-F1-T3 | Delete/archive confirm flow | P1 | Admin | E2-F1-T1 | **Done** | None | S | Widget — done |
| E2-F1-T4 | Wire to real endpoints | P0 | Admin | E2-F1-T1..T3, E0-F6 | **Done** — full path/method/body list read directly from `classRoutes.js`/`sectionRoutes.js` (api_spec.md §4.1a). `sectionsRoutes.js` (plural) confirmed dead code, not mounted. Verified live by the user in Chrome against the local backend. One remaining sub-question: `PATCH /api/sections/:id/students` vs. `Student.sectionId`/`.class`/`.section` as the roster-assignment path of record — resolve empirically when building E2-F3 | None | M | Integration (live) — done |

### E2-F2 — Manage Teachers `[DONE]` — built and verified live 2026-08-23
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E2-F2-T1 | List + search/filter, skeleton/empty/error | P0 | Admin | E0-F5 | **Done** | None | M | Widget — done |
| E2-F2-T2 | Add/Edit form | P0 | Admin | E2-F2-T1 | **Done** — body confirmed directly against `teacherController.js`'s `createTeacher`/`updateTeacher` | None | M | Widget — done |
| E2-F2-T3 | Detail screen | P1 | Admin | E2-F2-T1 | Parked — same scope call as Classes/Sections; the edit dialog already surfaces every field | None | S | Not built |
| E2-F2-T4 | Deactivate/delete action | P1 | Admin | E2-F2-T1 | **Done** | None | S | Widget — done |
| E2-F2-T5 | Wire to real endpoints incl. credential-issuance side effect | P0 | Admin | E2-F2-T1..T4, E0-F6 | **Done — resolved.** Read `teacherController.js`'s `createTeacher` directly: it **does** send a welcome-credentials email (same template pattern as Admin creation) regardless of whether a password was supplied. Verified live by the user in Chrome | None | L | Integration (live) — done |

### E2-F3 — Manage Students `[DONE]` — built and verified live 2026-08-23, bulk-import/export included per user's confirmed decision
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E2-F3-T1 | List + filter by class, skeleton/empty/error | P0 | Admin | E0-F5, E2-F1-T1 | **Done** — list, class-filter chips, plus `GET /export` and `GET /bulk-import/template` + `POST /bulk-import` all built (user confirmed include-in-v1) | None | M | Widget — done |
| E2-F3-T2 | Add/Edit form incl. class/section assignment | P0 | Admin | E2-F3-T1, E2-F1 | **Done** — cascading class→section dropdowns sourced from `ClassRepository`/`SectionRepository`, submitting names (not ids) per `studentSchema.js`'s free-text `class`/`section` fields | None | M | Widget — done |
| E2-F3-T3 | Detail screen | P1 | Admin | E2-F3-T1 | Parked — same scope call as Teachers | None | S | Not built |
| E2-F3-T4 | Wire to real endpoints | P0 | Admin | E2-F3-T1..T3, E0-F6 | **Done** — full CRUD plus bulk-import/export/template-download, all against the real backend. Auto-email-on-creation confirmed (shared question with E2-F2-T5, same `sendEmail` pattern in `studentController.js`'s `createStudent`) | None | L | Integration (live) — done |

### E2-F4 — Manage Parents `[DONE]` — built 2026-08-23, not yet click-through-verified
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E2-F4-T1 | List screen | P0 | Admin | E0-F5 | **Done** — `GET /export` not built (no toolbar button; export/download infra from E2-F3 exists if wanted later) | None | M | Widget — done |
| E2-F4-T2 | Add/Edit form + link/unlink child picker (from Student list) | P0 | Admin | E2-F4-T1, E2-F3-T1 | **Done** — multi-select `CheckboxListTile` list sourced from `StudentRepository`, submits the full replacement `students` id array per `updateParent`'s diff-based semantics | None | M | Widget — done |
| E2-F4-T3 | "Add parent" entry point from Student Detail | P2 | Admin | E2-F3-T3, E2-F4-T2 | N/A — no Student Detail screen exists (parked, see E2-F3-T3) | None | S | Not built |
| E2-F4-T4 | Wire to real endpoints | P0 | Admin | E2-F4-T1..T3, E0-F6 | **Done** — full CRUD against `/api/parents`. Self-service endpoints (`GET /me`, `/dashboard`, `/child/:id/attendance`, `/child/:id/fees`) belong to the Parent-role app surface, not Admin management — out of scope here, revisit when the Parent role's own screens are built | None | M | Integration — built, **live click-through not yet done** |

---

## E3 — Attendance
**Priority**: P0 · **Role**: Admin/Teacher/Student/Parent · **Dependencies**: E0, E1, E2-F1, E2-F3 · **Backend Dep**: mostly confirmed, ready to wire · **UI Dep**: None · **Complexity**: L · **Testing**: Widget + Unit + Manual QA

**Backend note**: `api_spec.md` §5 confirms *student* attendance (this Epic's scope) is backed by two models — a legacy flat `Attendance` model and the current `AttendanceSession`+`AttendanceRecord` pair — plus 8 more attendance-adjacent models (Teacher/Staff attendance, Correction, Log, Settings, WeeklyRegister, TeacherAssignment) that are out of this product doc's 4-role scope and not backlogged here. Two things this unlocked: (1) the Teacher edit-cutoff rule is now known exactly (locks immediately on submit — see F1-T4), and (2) attendance correction is confirmed real as a request/approve workflow, not a direct edit (see the new F6 below). Also flagged, not backlogged: `api_spec.md` §4.6 confirms a fully-built **QR-code attendance** mechanism (`/api/attendance/qr` — `POST /generate` teacher, `POST /scan` student, `GET /report`) with zero presence in any product doc — this needs the same product-scope decision as the other undocumented modules in `implementation_plan.md`'s Sequencing rationale before it gets its own Feature here.

### E3-F1 — Teacher: Mark Attendance `[DONE except T5]` — built 2026-08-23, not yet live-verified
*product_requirements.md §4.1 item 3; user_flows.md Flow 4*
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E3-F1-T1 | Load today's class roster (mock), skeleton/empty | P0 | Teacher | E2-F3 | **Done, wired for real** — section picker (`GET /api/sections/my/teacher`) → roster (`GET /api/sections/:id/students`), skipped the mock stage and went straight to live since the endpoints were already confirmed from Phase B | None | M | Widget — done |
| E3-F1-T2 | Mark present/absent/late per student, local state | P0 | Teacher | E3-F1-T1 | **Done** — per-student status dropdown (5 states: present/absent/late/leave/half-day), defaults present | None | M | Widget — done |
| E3-F1-T3 | Submit action with preserved-state-on-failure behavior | P0 | Teacher | E3-F1-T2 | **Done** — a failed submit (e.g. duplicate-session 409) leaves the roster and chosen statuses intact, surfaces the backend message, and the Submit button stays enabled to retry | None | M | Widget — done |
| E3-F1-T4 | Wire real save + edit-cutoff rule | P0 | Teacher | E3-F1-T3, E0-F6 | **Done** — `POST /api/attendance/student`. Confirmed: the record **locks immediately** on save; a Teacher cannot edit or unlock it afterward. A successful submit disables the status dropdowns and swaps the submit button for a "locked" confirmation client-side, matching the server-side reality | None | M | Integration — built, **live click-through not yet done** |
| E3-F1-T5 | In-app notification on save (rescoped from "real-time fan-out") | P2 | Teacher/Parent | E3-F1-T4, E11-F1 | Not built — still genuinely `UNKNOWN — VERIFY` whether attendance triggers an in-app `Notification`, and this is P2; revisit alongside E11 (Notifications) once that module exists to poll against | None | M | Not built |

### E3-F2 — Teacher: Attendance History `[DONE]` — built 2026-08-23, not yet live-verified
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E3-F2-T1 | Date/student filter UI over mock data | P1 | Teacher | E3-F1-T1 | **Done, wired for real** — date filter only, no student filter (the confirmed `GET /api/attendance/student` endpoint filters by date/class/section/subject, not by an individual student, on this list route) | None | S | Widget — done |
| E3-F2-T2 | Wire real history query | P1 | Teacher | E3-F2-T1, E0-F6 | **Done** — `GET /api/attendance/student?date=`, auto-scoped server-side to the calling teacher's own sessions. `date` is a required filter (400 without it), so this reads as "sessions submitted on this date" rather than an unbounded history — resolved by making the screen a date-picker, not a scroll-forever list. `GET /:studentId` and the `/reports/*` aggregate endpoints not used here — they belong to Student/Parent (E3-F4/F5) and Admin (E3-F3) views respectively | None | S | Integration — built, **live click-through not yet done** |

### E3-F3 — Admin: Attendance Overview `[DONE]` — built 2026-08-23, not yet live-verified; correction action removed (see new F6)
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E3-F3-T1 | School-wide summary list, filter by class/date | P1 | Admin | E2-F1, E2-F3 | **Done, but simpler than originally scoped** — built against `GET /api/attendance/student?date=&class=&section=` (the same session-list endpoint Teacher History uses; an Admin token isn't teacher-scoped server-side, so it naturally returns every session in the school), not the `/reports/*` aggregate endpoints — those return totals/percentages, not a session-by-session list, so they didn't fit "list, filter by class/date" as directly. `/reports/*` and `/logs` remain available if an aggregate summary card gets added later | None | M | Widget — done |
| E3-F3-T2 | Drill into class-level detail | P1 | Admin | E3-F3-T1 | Not built — the class-filter text field narrows the list in place; no separate class-detail screen exists | None | S | Not built |
| E3-F3-T3 | ~~Correction (update/delete) action~~ — **superseded, do not build as originally scoped** | — | — | — | This task assumed Admin directly edits a locked record. `api_spec.md` §4.6/§12 #9 confirms attendance correction is real but modeled as a **separate request/approve/reject workflow** (`/api/attendance/corrections`), not an inline edit here. Replaced by **E3-F6** below, which is now also done | — | — | — |
| E3-F3-T4 | Wire real school-wide query | P1 | Admin | E3-F3-T1/T2, E0-F6 | **Done** — see T1 | None | M | Integration — built, **live click-through not yet done** |

### E3-F4 — Student: My Attendance `[DONE except month filter]` — built 2026-08-23, not yet live-verified
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E3-F4-T1 | History + summary % view, month filter | P1 | Student | E0-F5 | **Done except month filter** — built against `GET /api/attendance/me` (resolves own `Student._id`) + `GET /api/attendance/student/:studentId` (history + `summarize()` percentage breakdown), not the `/reports/student` aggregate endpoint originally scoped — the per-student endpoint already returns exactly this shape in one call and is confirmed self-authorized, so `/reports/student` (school-wide aggregates) wasn't needed here. No month filter UI yet — repository supports `month`/`year` params, screen doesn't expose them | None | M | Widget — done |
| E3-F4-T2 | Wire real query | P1 | Student | E3-F4-T1, E0-F6 | **Done** — see above | None | S | Integration — built, **live click-through not yet done** |

### E3-F5 — Parent: Child's Attendance `[DONE except month filter]` — built 2026-08-23, not yet live-verified
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E3-F5-T1 | History + month filter, child selector if >1 child | P1 | Parent | E0-F5, E2-F4 | **Done except month filter** — built against `GET /api/parents/me` (linked children, populated) + the same `GET /api/attendance/student/:studentId` Student uses (confirmed also authorized for a linked parent), not `/parents/child/:studentId/attendance` or `/attendance/my-child` — those return a differently-shaped payload than the Student screen's, and reusing the identical endpoint let both screens share one history+summary widget. Child selector built (chips, auto-select when exactly one child, explicit "pick a child" prompt otherwise) | None | M | Widget — done |
| E3-F5-T2 | Wire real query | P1 | Parent | E3-F5-T1, E0-F6 | **Done** — see above | None | S | Integration — built, **live click-through not yet done** |

### E3-F6 — Attendance Correction Workflow `[DONE except T1/T3-Teacher-half]` *(new in v0.2, replaces E3-F3-T3)*
*api_spec.md §4.6, §5, §12 #9 — confirmed real, modeled as request/approve/reject, not a direct edit*
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E3-F6-T1 | Teacher: request a correction for a locked attendance record | P2 | Teacher | E3-F1-T4 | Not built — P2, parked. Endpoint confirmed and modeled (`AttendanceCorrectionRepository`), but only wired for Admin's read/approve/reject side so far, not Teacher's submit side | None | M | Not built |
| E3-F6-T2 | Admin: review queue — approve/reject correction requests | P1 | Admin | E3-F3-T1 | **Done** — `AttendanceCorrectionsScreen`, pending-queue cards with Approve/Reject, backed by `PATCH /api/attendance/corrections/:id/approve`\|`/reject`. **Known display gap**: the backend never populates `student`/`attendanceSession` on any correction endpoint — the queue shows raw ids for those, not names, documented on the `AttendanceCorrection` model rather than worked around | None | M | Widget — done |
| E3-F6-T3 | Wire both to real endpoints | P1 | Teacher, Admin | E3-F6-T1, E3-F6-T2, E0-F6 | Admin half **done** (see T2); Teacher half **not built** (see T1) | None | M | Integration — Admin half built, **live click-through not yet done**; Teacher half not started |

- E3-F6-T1-S1 correction request form (old status pre-filled, new status picker, reason text) — C:S, Test:Widget — **not built**
- E3-F6-T2-S1 pending-requests list with approve/reject actions — C:M, Test:Widget — **done**

---

## E4 — Assignments `[DONE except delete]` — core scope built 2026-08-23/24, not yet live-verified
**Priority**: P0 · **Role**: Teacher/Student/Parent · **Dependencies**: E0, E1, E2-F3 · **Backend Dep**: mostly confirmed, ready to wire · **UI Dep**: None · **Complexity**: L · **Testing**: Widget + Unit + Manual QA

**Decision resolved 2026-08-23 — user confirmed System A** (`/api/assignments` — full lifecycle, submission, grading), matching this product doc's "Assignments" module. System B (`/api/teachers/assignments`) confirmed out of scope, not integrated against.

### E4-F1 — Teacher: Create/Edit Assignment `[DONE except delete]` — built 2026-08-23/24, not yet live-verified
*product_requirements.md §4.1 item 4*
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E4-F1-T1 | List (own class), skeleton/empty/error | P0 | Teacher | E0-F5 | **Done, wired for real** — one shared `AssignmentsListScreen` for all 4 roles, `GET /api/assignments` role-scopes server-side | None | M | Widget — done |
| E4-F1-T2 | Create/Edit form (title, description, due date, attachment picker) | P0 | Teacher | E4-F1-T1 | **Done, except attachment picker** — body posts `class`/`section` as plain-text names (not `sectionId`+ its assigned-teacher gate, which nothing in Phase B populates — see roadmap for why). Edit mode built too (class/section shown read-only, not re-editable). No attachment picker on the assignment itself (`Assignment.attachment`) — only the Student-submission side got a file picker; the create form's own attachment field wasn't built, parked alongside delete below | None | M | Widget — done |
| E4-F1-T3 | Delete action | P2 | Teacher | E4-F1-T1 | Not built — still parked, per this row's own original flag: `DELETE /:id` has no visible role check at the routing layer (api_spec.md §12 #7), and that ambiguity hasn't been resolved | None | S | Not built |
| E4-F1-T4 | Wire real CRUD + file upload | P0 | Teacher | E4-F1-T1..T2, E0-F6 | **Done except delete and the assignment-level attachment upload** — `POST /`, `GET /`, `GET /:id`, `PATCH /:id` all wired | None | L | Integration — built, **live click-through not yet done** |

### E4-F2 — Teacher: Assignment Submissions Review `[DONE]` — built 2026-08-24, not yet live-verified
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E4-F2-T1 | Per-student submission list, skeleton/empty | P1 | Teacher | E4-F1-T1 | **Done** — `GET /:assignmentId/submissions`, rendered inline on `AssignmentDetailScreen` (no separate list screen) | None | M | Widget — done |
| E4-F2-T2 | Submission detail view | P1 | Teacher | E4-F2-T1 | **Done** — each submission's text/attachment-count/grade state shown inline in its card, no separate detail screen needed | None | S | Widget — done |
| E4-F2-T3 | Grade submission action | P1 | Teacher | E4-F2-T2 | **Done** — numeric `marks` + text `remarks` dialog (`PATCH /submissions/:submissionId/grade`); Grade button hides once `gradedAt` is set, matching the backend's own lock | None | M | Widget — done |
| E4-F2-T4 | Wire real query + grading write | P1 | Teacher | E4-F2-T1..T3, E0-F6 | **Done** — see above | None | M | Integration — built, **live click-through not yet done** |

### E4-F3 — Student: View & Submit `[DONE]` — built 2026-08-24, not yet live-verified
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E4-F3-T1 | Assignments list w/ due date + status, skeleton/empty | P0 | Student | E0-F5 | **Done** — same shared list as E4-F1-T1; status shown as a lock icon once `status: closed` | None | M | Widget — done |
| E4-F3-T2 | Detail + submission form (attach + submit), preserved on failure | P0 | Student | E4-F3-T1 | **Done** — `POST /submit` with `file_picker` (reused from Students' bulk-import, up to 5 files), text field, inline on `AssignmentDetailScreen` | None | M | Widget — done |
| E4-F3-T3 | Wire real submit + late-submission handling | P0 | Student | E4-F3-T2, E0-F6 | **Done** — the three confirmed rules (blocked past due on first submit; resubmit allowed any time pre-grading; locked once graded) surface as backend error messages rather than being re-validated client-side — the backend is the single source of truth for all three, no client-side due-date math to keep in sync | None | L | Integration — built, **live click-through not yet done. Cloudinary creds are empty locally (`docs/local_backend_setup.md`) — the file-attachment path will fail server-side until configured; text-only submissions still work** |

### E4-F4 — Parent: Child's Assignments (read-only) `[DONE]` — built 2026-08-24, not yet live-verified
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E4-F4-T1 | Read-only list/detail (reuses Student's detail, no submit action) | P2 | Parent | E4-F3-T1/T2, E2-F4 | **Done** — no separate screen; the shared `AssignmentDetailScreen` renders no submission section for Parent (or Admin) since `getAssignmentSubmissions` is Teacher-only server-side | None | S | Widget — done |
| E4-F4-T2 | Wire real query | P2 | Parent | E4-F4-T1, E0-F6 | **Done** — `GET /` role-scopes to the union of all linked children's classes server-side | None | S | Integration — built, **live click-through not yet done** |

---

## E5 — Notices & Study Material `[DONE]` — built 2026-08-24, not yet live-verified
**Priority**: P1 · **Role**: Admin/Teacher/Student/Parent · **Dependencies**: E0, E1 · **Backend Dep**: split · **UI Dep**: None · **Complexity**: M · **Testing**: Widget + Manual QA

### E5-F1 — Notices List / Notice Detail (shared) `[DONE]` — built 2026-08-24, not yet live-verified; attachment affordance removed
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E5-F1-T1 | List (all roles), skeleton/empty/error | P1 | All | E0-F5 | **Done** — `NoticesListScreen` picks `GET /my` vs. `GET /` based on role, read inside the initState microtask (not captured synchronously) | None | M | Widget — done |
| E5-F1-T2 | Detail — **remove attachment tap, schema doesn't support it** | P1 | All | E5-F1-T1 | **Done, no attachment UI built** — matches the confirmed absence of an attachment field on `noticeSchema.js` | None | S | Widget — done |
| E5-F1-T3 | Edit/delete affordance for owning Admin | P2 | Admin | E5-F1-T2 | **Done for Admin** — row actions on the list screen (not the detail screen). Teacher half remains impossible, unchanged | None | M | Widget — done |
| E5-F1-T4 | Wire real list/detail query | P1 | All | E5-F1-T1/T2, E0-F6 | **Done** — see T1/T3 | None | M | Integration — built, **live click-through not yet done** |

### E5-F2 — Admin: Create Notice `[DONE except expiryDate UI]` — built 2026-08-24, not yet live-verified; attachment field removed
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E5-F2-T1 | Compose form: title, body, audience scope — **no attachment field** | P1 | Admin | E5-F1-T1 | **Done except `expiryDate`** — title/description/audience/`isImportant` all in the form; `expiryDate` is supported by the repository but not exposed in the UI yet, a small remaining gap | None | M | Widget — done |
| E5-F2-T2 | Wire real publish | P1 | Admin | E5-F2-T1, E0-F6 | **Done** — see T1 | None | M | Integration — built, **live click-through not yet done** |
| E5-F2-T3 | Publish triggers Notification fan-out | P1 | Admin | E5-F2-T2, E11-F1 | Confirmed real server-side (unchanged finding) — **not independently re-verified this pass**; checking it actually reached the seeded accounts is part of the live click-through still owed | None | M | Not independently verified |

### E5-F3 — Teacher: Create/Edit Notice (own class) `[BLOCKED — NO BACKEND SUPPORT]` *(re-tagged from CAN IMPLEMENT NOW in v0.1)*
*screens.md §D — this screen was added in a prior documentation pass to close a broken cross-reference; `api_spec.md` §4.7/§12 #6 now confirms there is nothing for it to call*
**`api_spec.md` §12 row 6 confirms: `noticeSchema.js`'s `createdByModel` enum is `Admin, User` only — Teacher is not a valid notice creator, and `noticeRoutes.js` grants create only to `protectAdmin`/`protectSuperAdmin`. There is no Teacher-facing notice-creation endpoint anywhere in this backend.** This is not a "wire it up once the backend is ready" blocker — it needs a product decision: either the backend team adds a Teacher-scoped create endpoint, or this screen (and the Teacher C/R grant in `feature_matrix.md`) gets rolled back for v1. Do not build UI against this until that decision is made.
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E5-F3-T1 | Compose form, own-class scope implicit | — | Teacher | — | **No backend support** — see epic note above | None | — | — |
| E5-F3-T2 | Wire real publish + confirm Teacher U/D rights | — | Teacher | — | **No backend support** — no endpoint exists to wire against at all | None | — | — |

---

## E6 — Exam & Academic Schedules
**Priority**: P1 · **Role**: Admin/Teacher/Student/Parent · **Dependencies**: E0, E1, E2-F1 · **Backend Dep**: split · **UI Dep**: None · **Complexity**: M · **Testing**: Widget + Manual QA

### E6-F1 — Admin: Create/Manage Schedule `[DONE except Edit]` — built 2026-08-24, not yet live-verified; scoped to Exam (see note)
**Note**: `api_spec.md` confirms `/api/exams` (exam scheduling — title, class/section, subjects with dates/times) but no separate generic "academic event" endpoint under this product doc's naming. A distinct `Timetable` module and a distinct `SchoolEvent` model also exist in the backend (api_spec.md §4.14, §5) but are undocumented back-office modules, not backlogged here — if "Academic Schedule" was meant to cover more than exams (e.g. general school events), that's the same product-scope decision flagged in `implementation_plan.md`'s Sequencing rationale, not something this Epic can resolve alone.
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E6-F1-T1 | Create/Edit form (title, date/time, class/subject scope, description) | P1 | Admin | E2-F1 | **Create done, Edit not wired** — dynamic add/remove subjects list (name/full marks/pass marks). `updateExam` exists in the repository, tested, but nothing calls it yet — editing a live exam's subject list needs more form complexity than this pass had room for | None | M | Widget — create done |
| E6-F1-T2 | Delete action | P2 | Admin | E6-F1-T1 | Not built this pass | None | S | Not built |
| E6-F1-T3 | Wire real CRUD + notification trigger | P1 | Admin | E6-F1-T1/T2, E0-F6, E11-F1 | **Create/list/delete done** — `POST /exams`, `GET /exams`, `DELETE /exams/:id`. `PUT /exams/:id` not wired (see T1) | None | M | Integration — built, **live click-through not yet done** |

### E6-F2 — Schedule List/Detail (shared, all roles) `[DONE]` — built 2026-08-24, not yet live-verified
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E6-F2-T1 | List + detail, skeleton/empty/error | P1 | All | E0-F5 | **Done, simpler than scoped** — `GET /exams` (Admin) / `GET /exams/my` (everyone else), role read inside the initState microtask. Detail is an inline `ExpansionTile` per row, not a separate screen — `examController` has no `GET /:id` for non-Admin roles, so there's nothing to re-fetch; the already-loaded list item is the detail. `GET /exams/my-result/:examId` **not used** — System A's read path, superseded by E6-F3's decision | None | M | Widget — done |
| E6-F2-T2 | Wire real query | P1 | All | E6-F2-T1, E0-F6 | **Done** — see T1 | None | S | Integration — built, **live click-through not yet done** |

### E6-F3 — Results: Publish, View, Report Card `[DONE except a dedicated report-card screen]` — built 2026-08-24, not yet live-verified
**Decision resolved 2026-08-24 — user confirmed System B, the separate `Result` collection** (`POST /api/results/publish` et al.), not System A (`Exam.results[]`, `POST /api/exams/publish-results`). Full finding recorded in `production_roadmap.md` Phase F — the short version: System B has rank calculation, a class grade-distribution summary, a printable report card, and a Parent child-results view that System A has none of. **Consequence**: Teacher's per-subject marks entry (`POST /api/exams/subject-marks`, `examController.submitSubjectMarks`) is **not built** — it only writes into `Exam.results[]` (System A's field), which System B's publish call never reads, so nothing in this app would ever consume it. Admin enters every student's marks directly when publishing instead.
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E6-F3-T1 | Admin: publish results — per-student, per-subject marks entry + remarks | P1 | Admin | E6-F1-T1, E2-F3 | **Done** — `POST /api/results/publish`. Roster sourced via `StudentRepository.getStudents(className:, section:)`; only students with at least one mark entered are included in the publish payload | None | L | Widget — done |
| E6-F3-T2 | Student: own result view + report card | P1 | Student | E6-F3-T1 | **Own result done** (`GET /api/results/my/:examId`, shown from the Exams list's "My Result" button) — **report card not wired to a screen**. `ReportCard` model + `getReportCard()` repository method are built and tested (`GET /api/results/report-card/:examId/:studentId`), but no dedicated printable screen calls it yet — parked, same treatment as every other P1 detail screen this session | None | M | Widget — own result done, report card repo-only |
| E6-F3-T3 | Parent: child's result view | P2 | Parent | E6-F3-T1, E2-F4 | **Done** — child picker (auto-select on exactly one child) + that child's result for the tapped exam, filtered client-side from `GET /api/results/child/:studentId`'s full history (no single-exam variant of that endpoint exists) | None | M | Widget — done |
| E6-F3-T4 | Wire real publish + read queries | P1 | Admin/Student/Parent | E6-F3-T1..T3, E0-F6 | **Done except report card** — see above | None | L | Integration — built, **live click-through not yet done** |

---

## E7 — Fee Management
**Priority**: P1 · **Role**: Admin/Student/Parent · **Dependencies**: E0, E1, E2-F1, E2-F3 · **Backend Dep**: confirmed, ready to wire · **UI Dep**: None · **Complexity**: L · **Testing**: Widget + Manual QA

**v0.2 correction — in-app payment is IN SCOPE, not out of scope.** `api_spec.md` §4.9/§12 #8 confirms `POST /api/payments/fee/submit` is a real, implemented endpoint. It is **not** a payment-gateway checkout — it's a manual-verification flow: the payer (Student or Parent) enters the phone number + transaction PIN their own eSewa/Khalti app or bank transfer shows after paying, and an Admin manually cross-checks and approves/rejects it. E7-F4/F5 below un-park this from the v0.1 "out of scope, not backlogged" note.

### E7-F1 — Admin: Fee Structure Setup `[CAN IMPLEMENT NOW]` — ready to wire
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E7-F1-T1 | Per-class fee item form (amount, due date, category) | P1 | Admin | E2-F1 | **Confirmed** — `POST /fees` (`protectAdmin`), body per `feeSchema.js`: `studentId, title, description, totalAmount, discountPercent/discountAmount, dueDate`, optional `isInstallment` + `installments[]` (api_spec.md §4.9, §5) | None | M | Widget |
| E7-F1-T2 | Wire real CRUD | P1 | Admin | E7-F1-T1, E0-F6 | **Confirmed** — `GET /fees` (`?status=`), `PUT/DELETE /fees/:id`, `GET /fees/export` (Excel) (api_spec.md §4.9) | None | M | Integration (live) |

### E7-F2 — Admin: Fee Collection / Pending-Payments Review `[CAN IMPLEMENT NOW]` — rescoped: Admin reviews submitted payments, doesn't directly record them
**Rescope note**: "record-payment action" originally assumed Admin directly marks a fee paid. The confirmed flow is: Student/Parent **submits** a payment claim (E7-F4 below), Admin **reviews and approves/rejects** it (this Feature). There is no confirmed endpoint for Admin to record a payment with no prior submission (e.g. walk-in cash with no app-side claim) — if that's needed, it's a separate `UNKNOWN — VERIFY` question, not assumed here.
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E7-F2-T1 | Paid/pending list, filter by class/status | P1 | Admin | E7-F1-T1, E2-F3 | **Confirmed** — `GET /fees` (`?status=`) for the fee-level view (api_spec.md §4.9) | None | M | Widget |
| E7-F2-T2 | Pending-payments review queue: approve/reject submitted claims | P1 | Admin | E7-F2-T1 | **Confirmed** — `GET /payments/fee/pending` (list), `POST /payments/fee/approve/:id`, `POST /payments/fee/reject/:id` (with rejection note) (api_spec.md §4.9, §5) | None | M | Widget |
| E7-F2-T3 | Wire real recording + status update | P1 | Admin | E7-F2-T1/T2, E0-F6 | **Confirmed** — see T2; also `GET /payments/history` for the full audit trail | None | M | Integration (live) |

### E7-F3 — Student/Parent: Fee Status/History (read-only) `[CAN IMPLEMENT NOW]` — ready to wire
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E7-F3-T1 | History list, filter by term/year | P1 | Student/Parent | E0-F5 | **Confirmed** — `GET /fees/:id`, `GET /fees/student/:studentId`, `GET /payments/my-payments` (api_spec.md §4.9) | None | M | Widget |
| E7-F3-T2 | Wire real query + PDF receipt | P1 | Student/Parent | E7-F3-T1, E0-F6 | **Confirmed** — `GET /fees/:feeId/receipt` (PDF via `pdfkit`) (api_spec.md §4.9, §10) | None | S | Integration (live) |

### E7-F4 — Student/Parent: Submit Fee Payment `[CAN IMPLEMENT NOW]` *(un-parked in v0.2 — was "out of scope" in v0.1, now confirmed real)*
*api_spec.md §4.9, §5, §12 #8 — manual phone+PIN verification, not a payment-gateway SDK*
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E7-F4-T1 | Payment submission form: fee/installment picker, payment method (esewa/khalti/bank_qr/cash), phone number, transaction PIN fields | P1 | Student/Parent | E7-F3-T1 | **Confirmed body shape** — `feeId, installmentId?, phoneNumber, transactionPin` (api_spec.md §5, `paymentSchema.js`) | Needs the school's static payment QR image (`GET /schools/payment-qr`, api_spec.md §4.13) displayed alongside the form so the payer knows where to send money before entering the confirmation PIN | M | Widget |
| E7-F4-T2 | Submission status view (pending/approved/rejected, rejection note if any) | P1 | Student/Parent | E7-F4-T1 | **Confirmed** — `Payment.status` enum `pending\|approved\|rejected`, `rejectionNote` field (api_spec.md §5) | None | S | Widget |
| E7-F4-T3 | Wire real submit | P1 | Student/Parent | E7-F4-T1/T2, E0-F6 | **Confirmed** — `POST /payments/fee/submit` (`protect`, student/parent) (api_spec.md §4.9) | None | M | Integration (live) |

- E7-F4-T1-S1 payment method selector (esewa/khalti/bank_qr/cash) — C:S, Test:Widget
- E7-F4-T1-S2 phone number + transaction PIN input fields with validation — C:S, Test:Widget

### E7-F5 — Admin: Pending Payments Review Queue *(merged into E7-F2 above — this heading intentionally left as a pointer)*
See **E7-F2** — the review/approve/reject queue is that Feature's T2/T3, kept together with the rest of Admin's fee-collection screen rather than split into a separate Feature, since it's one screen in practice.

---

## E8 — Teacher Salary / Payroll
**Priority**: P2 · **Role**: Admin/Teacher · **Dependencies**: E0, E1, E2-F2 · **Backend Dep**: split · **UI Dep**: None · **Complexity**: M · **Testing**: Widget + Manual QA

### E8-F1 — Admin: Teacher Salary Management `[CAN IMPLEMENT NOW]` — ready to wire, richer than originally scoped
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E8-F1-T1 | Per-teacher salary record list + history | P2 | Admin | E2-F2 | **Confirmed** — `GET /`, salary-config via `GET /salary-config` (api_spec.md §4.10) | None | M | Widget |
| E8-F1-T2 | Process/update payment action | P2 | Admin | E8-F1-T1 | **Confirmed** — `POST /generate`, `POST /generate-bulk`, `PUT/PATCH /:id/mark-paid` (3 aliases for the same action) (api_spec.md §4.10). Salary breakdown is richer than a single figure: basic + allowances (houseRent/transport/medical/other) + deductions (tax/PF/absence/loan/other), auto-calculated gross/net, attendance-based deduction via workingDays/presentDays/absentDays — size the form accordingly | None | M | Widget |
| E8-F1-T3 | Wire real CRUD + notification trigger | P2 | Admin | E8-F1-T1/T2, E0-F6, E11-F1 | **CRUD confirmed** — `GET/PUT/DELETE /:id`, `POST /salary-config` (api_spec.md §4.10). **Notification trigger `UNKNOWN — VERIFY`** — "payroll" is a valid `Notification.type` enum value (api_spec.md §5) but wasn't in §8's confirmed-trigger list; also note the salary-reminder cron (`startSalaryReminderCron`) is confirmed **disabled** in the committed backend (api_spec.md §8) — don't assume any automatic reminder fires | None | M | Integration (live) |

### E8-F2 — Teacher: Salary Notification Banner `[CAN IMPLEMENT NOW]` for T1 + data half of T2; push half re-tagged `[BLOCKED — NO BACKEND SUPPORT]`
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E8-F2-T1 | Dashboard banner UI (mock trigger) | P2 | Teacher | E0-F5 | None (mock) | None | S | Widget |
| E8-F2-T2 | Wire real data (poll) | P2 | Teacher | E8-F2-T1, E11-F1 | **Confirmed** — `GET /payroll/my`, `GET /payroll/slip/:id` (self-service payslip) (api_spec.md §4.10). Realistic delivery is polling `GET /api/notifications`, not a live banner update | None | S | Integration (live) |
| E8-F2-T3 | Push delivery *(split out of old T2)* | — | Teacher | E8-F2-T2 | **No backend support** — see E11-F4, there is no push provider integrated anywhere in this backend | None | — | — |

---

## E9 — Online Classes `[BLOCKED — NO BACKEND SUPPORT]` *(re-tagged in v0.2 — was split CAN-NOW/BLOCKED-pending-confirmation in v0.1)*
**Priority**: — (do not schedule) · **Role**: Teacher/Student · **Dependencies**: — · **Backend Dep**: **confirmed absent, not just unconfirmed** · **UI Dep**: — · **Complexity**: — · **Testing**: —

**`api_spec.md` §10/§12 #1 confirms: this entire module does not exist in the backend.** A full-repo grep for "meet"/"zoom"/"meeting link" returned zero matches — no route, no model field, no meeting-link concept anywhere. This is a categorically different blocker than the rest of v0.1's "BLOCKED BY BACKEND" items: those needed the backend to be *reviewed*; this needs the backend to be *built*, or a product decision to drop it from mobile v1. Do not build the UI shell "ahead of the backend" the way `architecture.md`'s mock-repository pattern normally allows for other modules — with zero confirmed data shape (not even a schema), any UI built now would likely need to be redesigned once/if a real implementation exists, rather than just re-pointed at a new endpoint. Both features below are held pending that decision.

### E9-F1 — Teacher: Share Online Class Link — **on hold**
*product_requirements.md §4.1 item 9 — link hand-off (e.g. Google Meet), not an embedded SDK*
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E9-F1-T1 | Form: URL input + validation, class picker, optional scheduled time | — | Teacher | — | **No backend support** — see epic note above | — | — | — |
| E9-F1-T2 | Wire real save + delivery mechanism | — | Teacher | — | **No backend support** | — | — | — |

### E9-F2 — Student: Join Online Class — **on hold**
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E9-F2-T1 | Active/upcoming link list + empty state | — | Student | — | **No backend support** | — | — | — |
| E9-F2-T2 | External link hand-off (deep link out to browser/Meet app) | — | Student | — | **No backend support** | — | — | — |
| E9-F2-T3 | Wire real query | — | Student | — | **No backend support** | — | — | — |
| E9-F2-T4 | Parent visibility (if confirmed in scope) | — | Parent | — | **No backend support** — moot until the module itself exists | — | — | — |

---

## E10 — Chat `[CAN IMPLEMENT NOW]` — fully rescoped in v0.2 from a 1:1 messaging model to the confirmed class/section group-chat model
**Priority**: P2 · **Role**: Teacher/Student only *(Parent and Admin removed — see note)* · **Dependencies**: E0, E1 · **Backend Dep**: confirmed, ready to wire · **UI Dep**: None · **Complexity**: L · **Testing**: Widget + Integration (live)

**Rescope note (`api_spec.md` §7, §12 #2)**: the real backend implements **class/section-scoped group chat created by a Teacher**, with Students as members — not the Teacher↔Student/Teacher↔Parent 1:1 model this epic was originally scoped around. **Parents have zero backend access** (no schema field for Parent participants, `senderRole` enum is `teacher|student` only, and Parent sockets are rejected outright at the auth layer) and **there is no Admin oversight endpoint of any kind**. Every task below is rescoped to the real model; Parent and Admin were removed from the Role column throughout this epic rather than left as "unresolved."

### E10-F1 — Group Conversation List & Thread UI `[CAN IMPLEMENT NOW]` — ready to wire (REST layer confirmed)
*product_requirements.md §4.1 item 10 (rescoped)*
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E10-F1-T1 | Group conversation list (class/section-scoped groups, not 1:1 threads), skeleton/empty/error | P2 | Teacher/Student | E0-F5 | **Confirmed** — `GET /api/group-chats/` (`protectAny`) (api_spec.md §4.11) | None | M | Widget |
| E10-F1-T2 | Group Thread UI: bubbles, compose bar, optimistic send state, member list | P2 | Teacher/Student | E10-F1-T1 | **Confirmed** — `GET /:id`, `GET /:conversationId/messages` (api_spec.md §4.11) | None | M | Widget |
| E10-F1-T3 | Failed-to-send indicator + retry | P2 | Teacher/Student | E10-F1-T2 | **Confirmed** — send is `POST /:conversationId/messages` (see F2-T2) | None | S | Widget |
| E10-F1-T4 | Teacher: create a group conversation *(new — was missing from v0.1, since the original 1:1 model had no "create" concept the same way)* | P2 | Teacher | E10-F1-T1 | **Confirmed** — `POST /` requires a Teacher actor; `GET /eligible-targets` and `GET /preview-roster` help pick the class/section and preview auto-enrolled Student members before creating (api_spec.md §4.11). Students cannot create a group, only Teachers | None | M | Widget |
| E10-F1-T5 | Teacher: manage group (members/archive/delete) | P2 | Teacher | E10-F1-T4 | **Confirmed** — `PATCH /:id/members`, `PATCH /:id/archive`, `DELETE /:id` (api_spec.md §4.11) | None | M | Widget |

### E10-F2 — Real-Time Transport Integration `[CAN IMPLEMENT NOW]` — protocol and events fully confirmed
*api_spec.md §7*
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E10-F2-T1 | Connection/auth handshake for real-time client | P2 | System | E10-F1, E0-F6-T4 | **Confirmed** — Socket.IO v4; JWT passed via the connection's `auth` handshake option (not header/cookie); server resolves the connecting account as either a `Teacher` or `Student` document — **Admin/Parent socket connections are rejected outright** by design (api_spec.md §7) | None | L | Integration (live) |
| E10-F2-T2 | Message send (REST) + live fan-out (socket), reconnection handling | P2 | Teacher/Student | E10-F2-T1 | **Confirmed, and the architecture is asymmetric**: sending a message is a REST call (`POST /:conversationId/messages`), not a socket emit — the server then fans it out live to other room members via socket event `group:new-message`. Design the client so failed socket delivery never blocks the send action itself, only live updates to others (api_spec.md §7) | None | L | Integration (live) |
| E10-F2-T3 | Typing indicator + read receipts | P2 | Teacher/Student | E10-F2-T1 | **Confirmed** — client emits `group:join` (with ack)/`group:leave`/`group:typing`/`group:read`; server rebroadcasts `group:typing` and `group:read-receipt` to the room (api_spec.md §7) | None | M | Integration (live) |
| E10-F2-T4 | Message history pagination | P2 | Teacher/Student | E10-F2-T1 | **Still `UNKNOWN — VERIFY`** — `api_spec.md` §7/§11 explicitly flags the exact pagination query params (page/limit/cursor) as not confirmed. Build the REST call generically and confirm the param names before finalizing | None | M | Integration (live) |

### E10-F3 — Group Chat Media Attachment `[CAN IMPLEMENT NOW]` *(un-parked in v0.2 — was flagged "not mentioned in source doc" in v0.1; api_spec.md confirms it's real)*
*api_spec.md §4.11, §6, §7 — image/video/voice via Cloudinary, one attachment per message*
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E10-F3-T1 | Attachment picker: image, video, or voice recording (one per message) | P2 | Teacher/Student | E10-F1-T2 | **Confirmed** — allowed types image (jpeg/png/webp/gif), video (mp4/mov/webm/3gpp), voice (webm/mp4/mpeg/ogg/wav); size caps image 15MB / video 100MB / voice 25MB (api_spec.md §6) | None | M | Widget |
| E10-F3-T2 | Wire real upload | P2 | Teacher/Student | E10-F3-T1, E0-F6 | **Confirmed** — `POST /:conversationId/messages` with `uploadChatMedia`+`enforceMediaSizeLimits`+`pushMediaToCloudinary` middleware chain; oversized files return a `413` with an explicit "max 100MB for video" message (api_spec.md §4.11, server.js error handler) | None | M | Integration (live) |

### E10-F4 — Admin Chat Oversight `[BLOCKED — NO BACKEND SUPPORT]` *(re-tagged from "flagged, unconfirmed" to "confirmed absent")*
`api_spec.md` §7/§12 #2 confirms there is **no Admin oversight endpoint of any kind**, and Admin sockets are explicitly rejected at the auth layer (`next(new Error("User is neither a teacher nor a student"))`). This is not a UI gap to fill in later — there is nothing on the backend for an Admin oversight screen to call. Drop this from scope rather than leaving it "pending confirmation."

---

## E11 — Notifications
**Priority**: P1 · **Role**: All · **Dependencies**: E0, E1 · **Backend Dep**: split · **UI Dep**: None · **Complexity**: L · **Testing**: Widget + Integration (live)

### E11-F1 — Notifications List UI `[CAN IMPLEMENT NOW]` — ready to wire
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E11-F1-T1 | Chronological feed, skeleton/empty/error | P1 | All | E0-F5 | **Confirmed** — `GET /api/notifications` (`protect`, own notifications) (api_spec.md §4.12). This is a **poll/pull endpoint**, not push-fed — refresh on screen open / pull-to-refresh, not a live subscription | None | M | Widget |
| E11-F1-T2 | Read/unread state, mark-as-read on open | P1 | All | E11-F1-T1 | **Confirmed** — `PATCH /:id/read`, `PATCH /read-all` (api_spec.md §4.12) | None | S | Widget |
| E11-F1-T3 | Unread badge on Dashboard/nav | P1 | All | E11-F1-T2, E0-F4 | Same endpoints as T1/T2; badge count derived client-side from the list response | None | S | Widget |

### E11-F2 — Notification Deep-Linking `[CAN IMPLEMENT NOW]` — ready to wire
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E11-F2-T1 | Route notification tap → source screen | P1 | All | E11-F1-T1, E0-F4-T1 | **Confirmed** — `Notification.refId`/`refModel` (polymorphic reference: `Fee\|Attendance\|AttendanceSession\|AttendanceRecord\|AttendanceCorrection\|Assignment\|Exam\|Result\|Subscription`, api_spec.md §5) gives the client what it needs to build a target-screen map from `refModel` | None | M | Widget |

### E11-F3 — Notifications List + Delivery `[CAN IMPLEMENT NOW]` for T1 (list wiring); T2 removed — no real-time channel exists
*Renamed from "Real-Time / List Delivery" — the real-time half doesn't exist for notifications, only for Chat*
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E11-F3-T1 | Wire real notifications list query + mark-read endpoint | P1 | All | E11-F1, E0-F6 | **Confirmed** — same endpoints as E11-F1 (api_spec.md §4.12) | None | M | Integration (live) |
| E11-F3-T2 | ~~Live in-app delivery (real-time channel)~~ — **remove, confirmed not to exist** | — | — | — | `api_spec.md` §8 confirms **no Socket.IO event exists for notifications** — the only real-time channel in the entire backend is the Chat socket namespace (E10-F2). Do not build a live-subscription notification feed; poll `GET /api/notifications` on screen focus / pull-to-refresh / app-resume instead | — | — | — |

### E11-F4 — Push Notification Wiring `[BLOCKED — NO BACKEND SUPPORT]` *(re-tagged from "provider unconfirmed" to "confirmed absent")*
*architecture.md §9 originally deferred this pending confirmation; product_requirements.md §7 item 6*
**`api_spec.md` §8/§12 #3 confirms: no push provider of any kind is integrated in this backend** — a full-repo grep for firebase/fcm/push-notification/apns/expo-server/onesignal returned zero matches. Delivery is in-app poll (E11-F1/F3) + Resend email only. This is a build decision for the backend team, not an integration task for the mobile app as this backend stands — do not implement FCM SDK wiring against a server that has nothing to register a device token with.
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E11-F4-T1 | FCM (or any) SDK integration + device token registration | — | All | — | **No backend support** — no registration endpoint exists to send a device token to | — | — | — |
| E11-F4-T2 | OS permission-request screen/flow | — | All | — | **No backend support** — moot without T1 | — | — | — |
| E11-F4-T3 | Notification-tap → deep link when app backgrounded/killed | — | All | — | **No backend support** — moot without T1; the poll-based in-app flow (E11-F2) still works normally while the app is foregrounded | — | — | — |

### E11-F5 — Notification Preferences / Mute — **Flagged, not built**
`gap_analysis.md` §1: feature existence unconfirmed anywhere in source material. No tasks defined.

---

## E12 — Reports (Admin) — core scope DONE (2026-08-25), not yet live-verified
**Priority**: P2 · **Role**: Admin · **Dependencies**: E0, E1, E3, E7 · **Backend Dep**: split · **UI Dep**: None · **Complexity**: M · **Testing**: Widget + Manual QA

See `production_roadmap.md` Phase J for the full build writeup, including the real System-report cross-tenant audit-log finding and the confirmed field-level payload shapes (read directly from `Reportcontroller.js`, since `api_spec.md` only confirmed the endpoints at the category level).

### E12-F1 — Reports Dashboard UI `[DONE]`
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E12-F1-T1 | Cards + breakdown bars over real aggregate data, date-range filter (Attendance only — no server-side class filter exists; confirmed absent) | P2 | Admin | E0-F5 | Real (see F2-T1) | None | M | Widget |

### E12-F2 — Real Aggregate Data & Export `[DONE]` for T1; T2 confirmed not supported
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E12-F2-T1 | Wire real aggregate queries | P2 | Admin | E12-F1-T1, E0-F6 | **Confirmed, field-level** — `GET /api/reports/*`: `academic`, `financial`, `attendance`, `system` (`protectAdmin`), full response shape read from `Reportcontroller.js` directly | None | M | Integration (live) — still owed, see `production_roadmap.md` Phase J |
| E12-F2-T2 | Export/print | P3 | Admin | E12-F2-T1 | **Resolved — not supported.** Confirmed by reading all four handlers directly: none produces an export/print output. No export button built | None | M | N/A — dropped, nothing to build against |

---

## E13 — Design System & Theming (cross-cutting)
**Priority**: P0 · **Role**: System · **Dependencies**: E0-F3 · **Backend Dep**: None · **UI Dep**: split · **Complexity**: M · **Testing**: Golden

### E13-F1 — Token Implementation `[CAN IMPLEMENT NOW]` — high confidence, real extracted values
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E13-F1-T1 | Color tokens (light/dark, `design_system.md` §1) | P0 | System | E0-F3-T1 | None | None | S | Golden |
| E13-F1-T2 | Radius scale tokens (`design_system.md` §4) | P0 | System | E0-F3-T1 | None | None | S | Golden |

### E13-F2 — Typography & Spacing `[CAN IMPLEMENT NOW]` — assumption-based, pending visual sign-off
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E13-F2-T1 | Type scale (Material 3 default per `design_system.md` §2) | P1 | System | E13-F1 | None | Needs visual verification | S | Golden |
| E13-F2-T2 | 8pt spacing grid (`design_system.md` §3) | P1 | System | E13-F1 | None | Needs visual verification | S | Golden |

### E13-F3 — Component Library `[CAN IMPLEMENT NOW]` — Material 3 defaults, pending sign-off
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E13-F3-T1 | Card, button, text field styles | P1 | System | E13-F1/F2 | None | Needs visual verification (`design_system.md` §5) | M | Golden |
| E13-F3-T2 | App bar + bottom navigation shell | P1 | System | E13-F3-T1, E0-F4-T1 | None | Nav item set/IA undecided (see E0-F4-T1 note) | M | Golden |
| E13-F3-T3 | Icon set (Material Symbols default) | P2 | System | E13-F3-T1 | None | `ASSUMPTION` — no custom icon set confirmed | S | Golden |

---

## E14 — QA, Accessibility & Release Prep
**Priority**: P1 · **Role**: System · **Dependencies**: all preceding epics per `implementation_plan.md` sequencing · **Backend Dep**: split · **UI Dep**: None · **Complexity**: L · **Testing**: mixed

### E14-F1 — Test Coverage (ongoing, parallel to each epic) `[CAN IMPLEMENT NOW]`
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E14-F1-T1 | Unit tests per provider/repository (mock-backed) | P1 | System | each feature's providers | None | None | M (recurring) | Unit |
| E14-F1-T2 | Widget tests per screen (loading/empty/error states) | P1 | System | each feature's screens | None | None | M (recurring) | Widget |

### E14-F2 — Visual & Accessibility QA `[CAN IMPLEMENT NOW]`
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E14-F2-T1 | Light/dark theme regression pass | P1 | System | E13 | None | None | M | Golden |
| E14-F2-T2 | Accessibility pass (contrast, tap targets, screen reader labels) | P1 | System | E13, E0-F4 | None | None | M | Manual QA |

### E14-F3 — Mock-Based End-to-End Flows (interim) `[CAN IMPLEMENT NOW]`
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E14-F3-T1 | Per-role E2E walk against mock repos, matching `user_flows.md` | P1 | All | all mock-backed features per role | None | None | L | Integration (mock) |

### E14-F4 — Live Integration QA `[CAN IMPLEMENT NOW]` — largely unblocked in v0.2 now that most module wiring is ready
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E14-F4-T1 | Per-role E2E against real backend | P1 | All | E14-F3-T1, every module's "ready to wire" tasks | Only genuinely blocked on E0-F6-T1 (production base URL, `UNKNOWN — VERIFY`) — nearly every module's endpoint contracts are now confirmed per this pass, so this is closer than v0.1's blanket "needs every module unblocked" framing | None | XL | Integration (live) |
| E14-F4-T2 | Server-side CRUD permission verification (not just UI-hidden) | P0 | System | E14-F4-T1 | **Specific, confirmed things to check, not a generic unknown**: `api_spec.md` §3 confirms `organizationRoutes.js` and `schoolRoutes.js`'s core CRUD have **no auth middleware applied at all**, and `POST /api/subscriptions/seed-plans` is similarly unauthenticated with an in-code "protect in production" comment; §4.5/§12 #7 confirms `DELETE /api/assignments/:id` has no visible role check at the routing layer. Verify all three specifically, not just spot-check generally | None | M | Integration (live) |

### E14-F5 — Release Prep `[CAN IMPLEMENT NOW]` (mostly independent)
| ID | Task | Priority | Role | Dependencies | Backend Dep | UI Dep | Complexity | Testing |
|---|---|---|---|---|---|---|---|---|
| E14-F5-T1 | App icons/splash from brand assets | P2 | System | E13-F1 | None | Final brand assets pending | S | Manual QA |
| E14-F5-T2 | Store listing prep | P2 | System | none | None | None | S | N/A |
| E14-F5-T3 | Release build config (flavors/env for staging vs. prod) | P1 | System | E0-F6-T1 | **Partially blocked** — needs real staging/prod base URLs | None | M | Manual QA |

---

## E15 — Parked / Unconfirmed Modules — **BLOCKED BY SCOPE CONFIRMATION**
*Transport, Leave, ID Card, Library, Certificate — `product_requirements.md` §4.2, `gap_analysis.md` §1*

These surfaced only as term-frequency signals in the live site's JS bundle; the product doc never describes them, and it is unknown whether they are real mobile-in-scope modules, admin-web-only features, or unused code. **No Epic breakdown is provided** — decomposing these into Features/Tasks would mean inventing functionality no source document describes.

**v0.2 update**: the backend review resolved the *existence* question for two of these — `api_spec.md` confirms **Leave** (`leaveRequestSchema.js`, `/api/attendance/leave`) and **ID Card** (`/api/id-cards`, PDF+QR generation) are real, fully-built backend modules; Certificate is likely covered by a generic `Document` model rather than its own module; Transport and Library remain unconfirmed either way. This still doesn't resolve the actual blocker — **whether any of these are mobile-in-scope is a product decision, not a technical one** — so this Epic still gets no breakdown. It also turned out much smaller than reality: the backend review found roughly 15 more fully-built modules with zero product-doc presence at all (SuperAdmin, Subscriptions/Plans, Leads/CRM, Complaints, a Receptionist role, Departments, Timetable, QR-code Attendance, Backup, Events, Student Follow-ups, plus admin Dashboard/Reports/Search) — see `implementation_plan.md`'s Sequencing rationale and `api_spec.md` §4.14/§12 #10/#5 for the full list. None of those are added to this Epic or given their own Epic in this pass, for the same "needs a product decision first" reason.

**v0.3 update, 2026-08-27**: the product decision landed — see `production_roadmap.md` §4 decisions #4/#5 and its new Phase L. Seven of this Epic's modules are now unparked into dedicated Epics **E16–E22** below (Timetable, Departments, Student Follow-ups, ID Cards, Backup, Excel export retrofit, Nepali/BS calendar). Everything else named in this Epic (SuperAdmin, Subscriptions/Plans, Audit Logs, Contacts, Organizations, Leads/CRM, Complaints, Receptionist, Search, Events, QR Attendance, Transport, Library, Online Classes) stays parked here — out of scope per the same decision, not merely undecided anymore.

---

## E16 — Timetable `[DONE]` — Phase L4, built 2026-08-27
**Backend, confirmed via targeted route read** (`timetableRoutes.js`/`timetableController.js`/`timetableSchema.js`) — three genuinely different response shapes per caller, not one shape reused three ways; weekday enum is full names `Monday`–`Saturday` (not the `Mon`–`Sat` shorthand originally guessed); `POST /api/timetable` (Admin) is an upsert, no separate edit route exists; `GET /my` (Student) never 404s; `GET /teacher` (Teacher) returns a flattened per-day list with unpopulated `teacherId`. Parent explicitly excluded — no Timetable route in Parent's web route list (`frontend_analysis.md` §2).

### E16-F1 — Admin: Manage Timetable `[DONE]`
| ID | Task | Priority | Role | Dependencies | Notes | Testing |
|---|---|---|---|---|---|---|
| E16-F1-T1 | Class+Section picker (reused `exam_form_dialog.dart`'s pattern) + per-weekday `ExpansionTile` editor, add/remove periods | P2 | Admin | E0-F6 | Nested day→periods UI shape, no direct precedent — built as an `ExpansionTile` list, not a grid | Widget — 3 tests |
| E16-F1-T2 | Wire real upsert/list/delete | P2 | Admin | E16-F1-T1 | `TimetableRepositoryHttp` — dual-shape `teacherId` parsing on read, bare id on write | Integration — 7 repository + 6 provider tests |

### E16-F2 — Teacher/Student: View Own Timetable `[DONE]`
| ID | Task | Priority | Role | Dependencies | Notes | Testing |
|---|---|---|---|---|---|---|
| E16-F2-T1 | Read-only schedule views | P2 | Teacher, Student | E16-F1-T2 | Two separate providers/screens (`TeacherTimetableProvider`/`StudentTimetableProvider`) — different endpoints and response shapes, no shared parameters, mirrors the `AttendanceProvider`/`SelfAttendanceProvider` split | Widget — 4+4 tests, provider — 2+2 tests |

`features/timetable/` — 5 models, 1 repository (3 read shapes + upsert + delete), 3 providers, 3 screens, wired into DI/`app.dart`/router for Admin (`/admin/timetable`), Teacher (`/teacher/timetable`), Student (`/student/timetable`). 27 new tests, 434 → 461 passing, `flutter analyze` clean.

---

## E17 — Departments `[DONE]` — Phase L2, built 2026-08-27
**Backend, confirmed via targeted route read** (`Departmentroutes.js`/`Departmentcontroller.js`): `GET/POST /api/admin/departments`, `GET/PUT/DELETE /api/admin/departments/:id`, all `protectAdmin`. List/by-id populate `headOfDepartmentId`; create/update return it as a bare id.

### E17-F1 — Admin: Manage Departments `[DONE]`
| ID | Task | Priority | Role | Dependencies | Notes | Testing |
|---|---|---|---|---|---|---|
| E17-F1-T1 | List/create/edit/delete, Teacher `Autocomplete` for head-of-department, `FilterChip` multi-select for classes | P2 | Admin | E0-F6 | Reused `ClassesListScreen`'s exact CRUD shape | Widget — 4 tests |
| E17-F1-T2 | Wire real CRUD | P2 | Admin | E17-F1-T1 | `DepartmentRepositoryHttp` — dual-shape `headOfDepartmentId` parsing (populated object vs. bare id), same pattern as `Student.parentId` | Integration — 7 repository + 9 provider tests |

---

## E18 — Student Follow-ups `[DONE]` — Phase L5, built 2026-08-27
**Backend, confirmed via targeted route read** (`Studentfollowuproutes.js`/`Studentfollowupcontroller.js`): `GET/POST /api/admin/student-followups`, `GET/PUT/DELETE /api/admin/student-followups/:id`, `GET /api/admin/student-followups/export` (own export, not shared with E19's Fees export — a separate endpoint with its own `status`/`faculty`/`search` filters). List supports `status`/`faculty`/`search`/`page`/`limit`; `limit: 100` used instead of building pagination UI.

### E18-F1 — Admin: Manage Follow-ups `[DONE]`
| ID | Task | Priority | Role | Dependencies | Notes | Testing |
|---|---|---|---|---|---|---|
| E18-F1-T1 | List (search + status filter)/create/edit/delete | P2 | Admin | E0-F6 | Search field + `ChoiceChip` filter (`AdminFeesScreen` pattern), CRUD dialog with a date picker (`exam_form_dialog.dart` pattern) | Widget — 6 tests |
| E18-F1-T2 | Wire real CRUD | P2 | Admin | E18-F1-T1 | `StudentFollowupRepositoryHttp` — dual-shape `createdBy` parsing, same pattern as `Department.headOfDepartmentId` | Integration — 7 repository + 8 provider tests |
| E18-F1-T3 | Excel export button | P2 | Admin | E18-F1-T2 | Own `GET /export` endpoint (not E19's) — reused L1's `saveBytesAsFile()` mechanism | Widget (covered in T1's suite) |

---

## E19 — Excel Export Retrofit `[DONE]` — Phase L3, built 2026-08-27
**Backend, confirmed via targeted route read** (`feeRoutes.js`/`feeController.js`'s `exportFeesToExcel`): `GET /api/fees/export`, `protectAdmin`, optional `?status=`. Raw `.xlsx` blob via `ExcelJS`, no JSON envelope.

**Correction, 2026-08-27**: building E20 (Backup) surfaced that the Students-export half of this Epic (`E19-F1-T2` in the original plan) was already done — `StudentRepository.exportStudents()` and a working export button in `students_list_screen.dart` were built during Phase B (`E2-F3`). That task was removed; this Epic became Fees-only.

### E19-F1 — Admin: Fees export `[DONE]`
| ID | Task | Priority | Role | Dependencies | Notes | Testing |
|---|---|---|---|---|---|---|
| E19-F1-T1 | Export button on `AdminFeesScreen`'s AppBar, wired to the screen's existing status filter | P2 | Admin | E0-F6, E20 | Reused `saveBytesAsFile()` (`shared/utils/file_download.dart`) — no new file-save code | Widget — 5 tests (2 repo, 2 provider, 1 widget) |

---

## E20 — Backup `[DONE]` — Phase L1, simplest, built first, 2026-08-27
**Backend, confirmed via targeted route read** (`cloud_lms_backend/src/routes/backupRoutes.js`, `src/controller/backupController.js`): `GET /api/backup/school`, `protectAdmin`, no request body/params (`schoolId` from `req.admin`). Response is `res.download()` of a server-generated zip, no JSON envelope. Matches the web app's exact call.

### E20-F1 — Admin: Download Backup `[DONE]`
| ID | Task | Priority | Role | Dependencies | Notes | Testing |
|---|---|---|---|---|---|---|
| E20-F1-T1 | One-button download, own "Backup & Data" screen off the Admin dashboard (`/admin/backup`) | P3 | Admin | E0-F6 | No Admin Settings screen exists yet to nest this in (dashboards are still Phase-0 placeholders) — own screen matches existing precedent instead | Integration — repository (2, incl. failure) + provider (2) + widget (3) tests, all passing |

`features/backup/` — `BackupRepository`/`BackupRepositoryHttp`, `BackupProvider`, `BackupScreen`, wired into `service_locator.dart`, `app.dart`, `app_router.dart`/`app_routes.dart`. 402 → 409 tests passing, `flutter analyze` clean.

---

## E21 — ID Cards `[DONE]` — Phase L6, built 2026-08-27
**Backend, confirmed via targeted route read** (`idCardRoutes.js`/`idCardController.js`) — two corrections to the original scoping notes: **no QR code** anywhere (`api_spec.md`'s "PDF+QR" was wrong, only `pdfkit` is used), and **no `Document`-model persistence** (each call streams a fresh PDF on demand, nothing stored). `GET /student/:id` (Admin), `GET /bulk?class=&section=` (Admin, not built — out of scope), `GET /my` (Student). School branding is baked server-side, no separate branding fetch needed.

### E21-F1 — Admin: Generate ID Card `[DONE]`
| ID | Task | Priority | Role | Dependencies | Notes | Testing |
|---|---|---|---|---|---|---|
| E21-F1-T1 | Student `Autocomplete` picker + generate action | P3 | Admin | E0-F6 | Same picker pattern as `fee_form_dialog.dart`; no branding fetch needed (server-side) | Widget — 2 tests |
| E21-F1-T2 | Wire real generate/download call | P3 | Admin | E21-F1-T1 | `IdCardRepositoryHttp` — no model needed, raw PDF bytes only | Integration — 4 repository + 5 provider tests |

### E21-F2 — Student: Download Own ID Card `[DONE]`
| ID | Task | Priority | Role | Dependencies | Notes | Testing |
|---|---|---|---|---|---|---|
| E21-F2-T1 | Download own card | P3 | Student | E21-F1-T2 | **Resolved**: Parent does *not* get this — `GET /my` only resolves via a `Student` profile lookup, which a Parent login can never satisfy; confirmed no Parent access exists at all | Widget — 3 tests |

**Testing note**: a 404 through a `ResponseType.bytes` call can't have its JSON error body decoded, so the app shows `ErrorMapper`'s generic default message instead of the backend's specific one — a pre-existing limitation across every bytes-typed export/download method in this app (E19/E20 included), not a new bug. See `production_roadmap.md` Phase L6 for detail.

---

## E22 — Nepali (BS) Calendar `[DONE]` — Phase L7, built 2026-08-27
**Backend**: none — frontend-only date-conversion, matching web's `DualCalendar` purpose (`frontend_analysis.md` §4), not its exact layout. Parent role only.

### E22-F1 — Parent: Dual AD/BS Calendar `[DONE]`
| ID | Task | Priority | Role | Dependencies | Notes | Testing |
|---|---|---|---|---|---|---|
| E22-F1-T1 | Research + pick a Dart BS-date-conversion package | P3 | System | — | `nepali_utils: ^3.0.8` — verified via WebSearch/WebFetch against pub.dev metrics (54 likes/160 pub points vs. single-digit alternatives), not guessed | — |
| E22-F1-T2 | Dual AD/BS calendar screen | P3 | Parent | E22-F1-T1 | Gregorian-paginated month grid, each cell's BS date stacked underneath — not a BS-native grid, to avoid a second variable-month-length layout algorithm for a P3 feature | Widget — 3 tests, incl. a conversion pair verified against the package directly before writing the test |

---

**Phase L is now fully complete** (E16–E22, all `[DONE]`) — see `production_roadmap.md`'s Phase L summary for the full total (97 new tests, 402 → 499, across all seven sub-phases).

## Appendix A — CAN IMPLEMENT NOW / READY TO WIRE (flat list, by ID) — v0.2, post-backend-verification

E0-F1 (all), E0-F2 (all), E0-F3 (all), E0-F4 (all), E0-F5 (all), E0-F6-T2/T3/T4 (ready to wire — auth header, error envelope, and realtime transport all confirmed) · E1-F1 (all), E1-F2-T1/T3/T4 (ready to wire), E1-F2-T2 (resolved, no work needed) · E2-F1-T1..T3 (UI; T4 still blocked, see Appendix B), E2-F2 (all — T5 ready to wire), E2-F3 (all — fully confirmed, best-documented module), E2-F4 (all — ready to wire) · E3-F1-T1..T4 (ready to wire), E3-F1-T5 (ready to wire as poll-based, not real-time), E3-F2 (all), E3-F3-T1/T2/T4 (ready to wire — T3 removed, superseded by E3-F6), E3-F4 (all), E3-F5 (all), E3-F6 (all — new, attendance correction workflow) · E4-F1-T1/T2/T4 (ready to wire — T3 still flagged, build behind a confirmation flag), E4-F2 (all — grading model resolved), E4-F3 (all — submission rules resolved), E4-F4 (all) · E5-F1-T1/T2/T4 (ready to wire, attachment removed), E5-F1-T3 (Admin only — Teacher half moved to Appendix C), E5-F2 (all — attachment field removed) · E6-F1 (all), E6-F2 (all) · E7-F1 (all), E7-F2 (all — rescoped to review-queue model), E7-F3 (all), E7-F4 (all — new, un-parked fee payment submission) · E8-F1 (all — CRUD confirmed, notification trigger sub-detail unknown), E8-F2-T1/T2 (data half ready to wire — T3 push moved to Appendix C) · E10-F1 (all — rescoped to group chat), E10-F2-T1/T2/T3 (confirmed — T4 pagination still unknown, see Appendix B), E10-F3 (all — new, media attachment un-parked) · E11-F1 (all), E11-F2 (all), E11-F3-T1 (ready to wire — T2 removed, no real-time channel exists) · E12-F1-T1, E12-F2-T1 (categories confirmed — T2 export still unknown) · E13 (all) · E14-F1, E14-F2, E14-F3, E14-F4 (both tasks — largely unblocked now), E14-F5-T1/T2 (T3 partial, see Appendix B) · E16 (all — Phase L4, done), E17 (all — Phase L2, done), E18 (all — Phase L5, done), E19 (all — Phase L3, done), E20 (all — Phase L1, done), E21 (all — Phase L6, done), E22 (all — Phase L7, done)

**Total addressable now**: essentially the entire visible app's UI plus, as of this pass, most of its real backend wiring too — the mock-repository-first approach in `architecture.md` was correct, but it's no longer the ceiling: most modules have a confirmed endpoint to swap in directly.

## Appendix B — BLOCKED BY BACKEND (genuinely `UNKNOWN — VERIFY` per `api_spec.md`, not "no support") — flat list, by ID

E0-F6-T1 (production base URL/host — deploy-specific, not in source) · E2-F1-T4 (Class/Section route paths confirmed to exist and mount, but not enumerated in `api_spec.md`'s endpoint inventory) · E2-F2-T5 (auto-email-on-creation for Teacher — confirmed for Admin, unconfirmed for Teacher/Student/Parent) · E4-F1-T3 (Assignment delete role-check — route exists, but no role guard visible at the routing layer; controller-level check untraced) · E8-F1-T3 (payroll notification trigger — CRUD confirmed, notification-on-processed call site untraced) · E10-F2-T4 (chat message-history pagination convention) · E12-F2-T2 (report export/print — category endpoints confirmed, export capability within them unconfirmed) · E14-F5-T3 (release build config — partially blocked on E0-F6-T1's base URL)
**These are the genuine remainder** — `api_spec.md` §11's own remaining-unknowns list. Each needs either a live instance, the `.env` file, or a direct question to the backend team; none of them are resolvable by more static code reading.

## Appendix C — BLOCKED — NO BACKEND SUPPORT (needs a product/backend decision, not more backend work) — *new bucket in v0.2*

- **E9 — Online Classes** (entire epic): zero backend presence — no route, model field, or grep match for "meet"/"zoom"/"meeting link" anywhere.
- **E5-F3 — Teacher: Create/Edit Notice**: `noticeSchema.js`'s creator enum excludes Teacher, and no Teacher-facing notice route exists at all.
- **E10-F4 — Admin Chat Oversight**: no oversight endpoint exists; Admin sockets are explicitly rejected at the auth layer.
- **E11-F4 — Push Notification Wiring** (entire feature, all 3 tasks): no push provider (FCM or otherwise) is integrated anywhere in the backend.
- **E8-F2-T3 — Push delivery for the Teacher salary banner**: same root cause as E11-F4, split out from the otherwise-buildable E8-F2.

Lumping any of these into Appendix B would misrepresent them as "waiting on the backend team to finish reviewing/building an existing feature" — they need a **decision** (build it, or drop it from mobile v1) before any engineering time is scheduled against them, unlike everything in Appendix B which just needs an answer to a specific, narrow question.
