# CloudsLMS Flutter — Implementation Plan

> Status: DRAFT v0.2 — phase sequencing based on `architecture.md`, `screens.md`, and the dependency chain in `user_flows.md` Flow 3 (Admin Setup, which everything else depends on). No code is written in this phase; this is the roadmap for after today. **Phase 1 is now complete** — the real backend (`https://github.com/ArbindDas/SujalbackendForStudentmanagement`) was cloned read-only and analyzed; `api_spec.md` was rewritten with verified facts, and `docs/implementation_backlog.md` was updated to reflect what's now confirmed buildable vs. what's confirmed to have no backend support at all. See `api_spec.md` §12 for the full conflict list this revealed.

## Phase 0 — Documentation (today, this phase)
- Deliverables: this `docs/` set — `product_requirements.md`, `feature_matrix.md`, `screens.md`, `user_flows.md`, `design_system.md`, `architecture.md`, `api_spec.md`, `implementation_plan.md`.
- Output: a shared, explicit understanding of scope and open questions before any code or API assumptions are made.

## Phase 1 — Backend verification — **DONE**
- The GitHub backend repo was reviewed read-only (routes, controllers, Mongoose schemas, middleware, Socket.IO handlers) and cross-checked against `api_spec.md`; nearly every `UNKNOWN — VERIFY FROM BACKEND` marker was replaced with a real, cited value. See `api_spec.md` (rewritten in full) for the spec and `api_spec.md` §12 for the conflicts this surfaced against the product docs.
- Open questions from `product_requirements.md` §7, resolved:
  1. Transport/Leave/ID Card/Library/Certificate in-scope? — **Leave and ID Card confirmed as real, built backend modules** (`leaveRequestSchema.js`, `/api/id-cards`); Transport/Library/Certificate not specifically found (Certificate is likely covered by the generic `Document` model, not a dedicated module) — still no explicit mobile-scope decision made, see Sequencing rationale below.
  2. Auth mechanism — **Resolved**: JWT bearer, 60m access / 30d refresh, both returned in the JSON body (not cookies).
  3. Real-time protocol — **Resolved**: Socket.IO, but scoped to chat only (see item 5).
  4. Student account creation flow — **Resolved**: Admin-created via `POST /api/students`, same pattern as Teacher/Parent — not self-registered.
  5. Chat scope — **Resolved, and different from assumed**: class/section-scoped group chat created by a Teacher (Students only as members); no Teacher↔Parent or 1:1 messaging exists in the backend at all.
  6. Push notification provider — **Resolved (negative)**: no push provider is integrated anywhere in the backend; delivery is in-app poll + email (Resend) only.
- **Not resolved by static code reading** (still open, see `api_spec.md` §11): production base URL/hosting, exact list-endpoint pagination convention, how an `"hr"`-role Admin account gets created, the purpose of the public self-registration + separate PIN-reset flows.
- `feature_matrix.md` was **not** updated in this pass by this fork — a parallel documentation pass in this same session is handling that file; do not assume it already reflects the backend findings without checking its own status line.
- **Phase 2+ is now unblocked on auth mechanism and response/error envelope** — both are answered in `api_spec.md` §2 (note the envelope is confirmed *inconsistent* across endpoints, not uniform — `ApiClient`'s error mapping in Phase 2 needs to handle that defensively, not assume one shape).

## Phase 2 — Core architecture setup
- Scaffold the folder structure from `architecture.md` §2.
- `ApiClient` (dio/http wrapper) with auth-header injection, timeout, and error mapping to the typed exceptions in `architecture.md` §8.
- `Result<T>` wrapper, shared `LoadingView`/`EmptyStateView`/`ErrorView` widgets.
- `AppTheme` from `design_system.md` (colors, radius scale, typography, light/dark).
- Secure storage + local prefs services.
- Service locator wiring (mock repositories initially, per `architecture.md` §5).
- Base `MaterialApp` + role-based router skeleton (no real screens yet, placeholder routes).

## Phase 3 — Auth & role-based navigation
- Splash, Login, Forgot Password (pending confirmation it exists — `product_requirements.md` §7 item 2/4), Logout (`user_flows.md` Flows 1–2).
- `AuthProvider`, session persistence/restore, route guarding by role.
- Four empty role Dashboards as navigation targets (real content comes in later phases).

## Phase 4 — Admin: setup & management
- Highest priority after auth, because per `user_flows.md` Flow 3 every other role's data is empty until Admin sets up classes/sections/subjects and adds users — building this first unblocks realistic testing of every later phase.
- Manage Classes/Sections/Subjects, Manage Teachers, Manage Students, Manage Parents (CRUD screens from `screens.md` §C).

## Phase 5 — Attendance
- Teacher: Mark Attendance, Attendance History (`screens.md` §D).
- Student/Parent: read-only attendance views (`screens.md` §E/F).
- Admin: Attendance Overview.
- Chosen early because it's the most-referenced module in both the doc and the live-site bundle (product_requirements.md §4.1/§4.2) — a good end-to-end proof of the write-then-fan-out-to-viewers pattern (Teacher marks → Admin + Parent see it) that several other modules repeat.

## Phase 6 — Assignments, Notices, Exam/Academic Schedule
- Teacher/Admin create; Student/Parent view (+ Student submit for Assignments).
- These three share the same "author creates → scoped audience views, possibly notified" shape, so building them together reuses the same list/detail/create patterns.

## Phase 7 — Fees & Payroll
- Admin: Fee Structure Setup, Fee Collection/Status List, Teacher Salary Management.
- Student/Parent: Fee Status/History (read-only).
- Sequenced after the core CRUD/viewing patterns are proven (Phases 4–6), since Fees is more form-heavy/admin-centric and lower-frequency for Student/Parent than Attendance.

## Phase 8 — Chat & Notifications
- **Real-time protocol is now confirmed** (Socket.IO, JWT via the handshake `auth` option — `api_spec.md` §7), so this phase is no longer blocked on transport uncertainty. What changed instead is the **feature shape**: Chat is confirmed to be **class/section-scoped group chat created by a Teacher** (Students only as members), not the Teacher↔Student/Teacher↔Parent 1:1 messaging this phase was originally scoped around — Parents have zero backend access to chat (rejected outright at the socket auth layer), and there is no Admin oversight endpoint. Scope this phase's Chat work as: Conversation List (groups, not threads), Group Thread (many participants), media attachment (image/video/voice — confirmed real via Cloudinary), Teacher-only group creation/member management. Do not build a Parent-facing chat screen or an Admin oversight screen — both are confirmed to have nothing to call.
- **Push notifications are confirmed to have no backend channel at all** — this is different from "pending confirmation." A full-repo grep found no FCM/APNs/push-provider integration anywhere. In-app notifications are real and endpoint-confirmed (`GET /api/notifications`, poll-based, plus email via Resend for a specific event list) — build that. Do not build FCM/push wiring against this backend as it stands; if push is still wanted for v1, it needs a backend change first, not a mobile-side integration task.
- `RealtimeService` abstraction (`architecture.md` §6) now has a real transport to bind to (Socket.IO, chat-only — notifications are not real-time).

## Phase 9 — Online Classes — **BLOCKED, confirmed absent from the backend**
- Teacher: Share Online Class Link. Student: Join Online Class (external link hand-off, per `user_flows.md` Flow 10).
- **This is not "unconfirmed" the way it was in v0.1 — it's confirmed absent.** A full-repo grep for "meet"/"zoom"/"meeting link" returned zero matches; no route, no model field, nothing (`api_spec.md` §12 #1). This phase cannot proceed as scoped: there is no backend to wire the mobile app against. Do not schedule engineering time against this phase until a product decision is made — either the backend team builds it, or it's dropped from mobile v1. Unlike every other phase in this plan, more backend *analysis* won't unblock this; it needs a backend *build* decision.

## Phase 10 — Admin Reports & polish
- Reports Dashboard (Admin).
- Cross-cutting polish: verify every screen's loading/empty/error states against `screens.md`, accessibility pass, light/dark theme QA against `design_system.md`, offline-tolerance decision revisit if requirements firm up.

## Phase 11 — QA & release prep
- End-to-end pass per role against `user_flows.md`.
- Verify `feature_matrix.md` CRUD boundaries are actually enforced (not just UI-hidden) — confirm server-side enforcement with the backend team.
- Store listing prep, app icons/splash from final brand assets, release build config.

## Sequencing rationale (why this order)
Phases 2–3 are a hard prerequisite for everything (nothing works pre-auth). Phase 4 (Admin setup) comes right after because, per the product's own onboarding flow, **no other role has any data to show until an Admin has set up classes and added users** — building Teacher/Student/Parent screens before this would mean testing against empty states only. Attendance (Phase 5) comes next as the highest-frequency, most-representative module to validate the write→notify→multi-role-view pattern once, before repeating it for Assignments/Notices/Schedules (Phase 6). Fees/Payroll (Phase 7) and Chat/Notifications (Phase 8) were originally pushed later because they were more form-heavy/lower-frequency or carried unresolved architectural risk (real-time transport) that Phase 1 needed to close out first — that risk is now resolved, but the phase order stands since the underlying reasons (form-heavy, lower per-role frequency) still apply.

**Backend scope turned out much larger than this plan's scope.** Phase 1's backend review (`api_spec.md` §4.14) found roughly 15 additional, fully-built backend modules with zero presence anywhere in the mobile product docs: SuperAdmin (platform-level tenant administration), Subscriptions & Plans (incl. the literal 7-day-demo endpoint), Leads/CRM, Complaints, a Receptionist role, Departments, Timetable (distinct from Exam Schedules), QR-code Attendance, Backup/Restore, school Events (distinct from both Exam and Notice), Student Follow-ups, plus admin-facing Dashboard/Reports/Search screens equivalent to what this plan calls Phase 10. None of these are added to this plan's phases — not because they're technically hard (most are straightforward CRUD, same shape as Phase 4-6's work), but because **no explicit product decision has been made that they're in mobile scope**. Treat them as a distinct, unscheduled backlog (`implementation_backlog.md` doesn't break them down either, for the same reason) pending that decision, rather than silently folding them into an existing phase.
