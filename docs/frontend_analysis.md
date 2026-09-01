# CloudsLMS — Web Frontend Analysis

> Status: NEW v0.1 — read-only analysis of `cloud_lms_frontend` (React 19 + TypeScript + Vite + Tailwind v4), the real production web frontend for CloudsLMS. Source: local clone at `/Users/sabinkc/Desktop/ClaudeMS/cloud_lms_frontend`, commit `bc924bced0f4d3eab97165dd4308960065cd608d` (2026-08-13 19:00:36 +0545). The repo was **not modified** — every claim below is either **CONFIRMED** (read directly from source, file cited) or `ASSUMPTION`/`UNKNOWN — VERIFY` where genuinely not determinable from static source. `.env` was checked only for what key it defines (`VITE_API_URL`) — its value was never read or is not reproduced here. This document exists specifically to supply evidence for `production_roadmap.md` §4 decisions #4 and #5 — see §5 below for the direct answer-evidence section. It does **not** make the final call on either decision; that's the user's.

---

## 1. App structure

- **Routing**: `react-router-dom` v7, all routes defined in one file, `src/App.tsx` — a flat `<Routes>` tree, one `<Route path="/{role}/*">` subtree per role, each wrapped in `ProtectedRoute allowedRoles={[...]}`. No lazy-loading/code-splitting observed (all pages statically imported at the top of `App.tsx`).
- **Auth**: `src/auth/useAuth.tsx` (React Context) + `src/auth/Protectedroute.tsx` (route guard) + `src/auth/PublicRoute.tsx` (redirects an already-authenticated user away from `/`/`/login`) + `src/auth/getDashboardPath.ts` (role string → dashboard path lookup). Login is a **single shared modal** (`src/components/LandingPage/LoginModal.tsx`) mounted on the landing page — there is no per-role login screen; the backend's login response includes a `role` field and the frontend branches purely on that string post-login. Tokens: `src/api/tokenManager.ts` (access token) + refresh token, consistent with `api_spec.md` §2's JWT bearer + refresh-token model.
- **API layer**: `src/api/` (axiosInstance, tokenManager, feeapi, attendanceapi, notice, exam, Studentapi, studentservice, notification) + `src/services/` (Feeapi, parentApi, notificationApi, nepaliDate, Paymentapi, Attendanceservice, Teacherservice, Studentservice) — a mix of both directories doing similar jobs (some duplication/inconsistent organization between `api/` and `services/`, not itself a functional problem but worth noting for anyone using this as an API-contract reference). All confirmed calls use `axiosInstance` (`baseURL: import.meta.env.VITE_API_URL`) or a locally-aliased `api` import of the same instance.
- **Layouts**: `src/Layouts/` — one per role: `AdminstratorLayout`, `TeacherLayout`, `StudentLayout`, `ParentLayout`, `ReceptionistLayout`, `SuperAdminLayout`. Each wraps a persistent sidebar + navbar shell (component pairs under `src/components/{Role}/`) around an `<Outlet>` for that role's nested routes.
- **Real-time**: `socket.io-client`, wired in `src/components/Chat/GroupChatWindow.tsx` (shared by both Teacher's and Student's group-chat pages), connecting to `VITE_SOCKET_URL` (falls back to `VITE_API_URL`) — matches `api_spec.md` §7's Socket.IO chat architecture exactly (class/section group chat, not 1:1).
- Note: a `src/components/Student copy/` directory (literal space in the name) holds the live, routed Student-role components — not a stray backup folder, `App.tsx` imports directly from it. Cosmetic oddity, not a functional issue, but worth knowing if greping for "Student" components.

---

## 2. Role & route inventory (from `App.tsx`, CONFIRMED)

**Six roles have real, routed logins and dashboards** — not four:

| Role (route prefix) | Layout | Routed screens |
|---|---|---|
| `/teacher` | `TeacherLayout` | dashboard, students, students/:classId, sections, sections/:id/students, attendance, attendance/:classId, my-sections, assignments, salary, profile, timetable, exams, notices, settings, group-chat (14 screens) |
| `/parent` | `ParentLayout` | dashboard, attendance, fees, reports, notices, profile, settings, events, DualCalendar (9 screens) |
| `/student` | `StudentLayout` | dashboard, home, profile, attendance, section, assignments, fees, exams, notices, settings, timetable, chat (12 screens) |
| `/reception` | `ReceptionistLayout` | dashboard, visitors, appointments, deliveries, phone-directory, documents, profile, settings (8 screens) |
| `/superadmin` | `SuperAdminLayout` | dashboard, users, Subscriptions, School, billing, roles, profile, settings, Plans, Messages, Notice, RenewSubscriptions, audit-logs (13 screens) |
| `/admin` | `AdminstratorLayout` | dashboard, student, teacher, department, class-management, attendance, fee-payment, exam, notice, reports, settings, parent, timetable, BillingPayroll, profile, change-password, follow-ups, id-cards (18 screens) |

**Total: 74 routed screens across 6 roles**, vs. `screens.md`'s ~30 entries across 4 roles. `feature_matrix.md`'s "Cross-Document Consistency Check" (`gap_analysis.md` §13) states *"Exactly 4 roles ... consistently named and scoped"* across all of that doc set — that's now **superseded** by this real source: the live web product has 6 roles with full UI, not 4.

**No dedicated HR role exists in the UI.** `src/components/constant/roles.tsx`'s `UserRole` type is `user | student | teacher | parent | admin | superadmin` — no `reception`, no `hr`. `reception` *is* real and routed in `App.tsx` (just missing from that one constants file — an internal inconsistency in the repo itself, not evidence HR/reception aren't real). `hr` is referenced only defensively in one file's comments (`src/pages/Dashboard/TeacherDashboard/Attendance.tsx` lines 29–62): a code comment explains the backend's attendance-RBAC actor resolver includes an `"hr"` role, and the Teacher attendance-manager view was **widened to also treat `hr` as a manager actor** so an HR user landing there (presumably via generic `admin`-branch login, since there's no `/hr/*` route) doesn't fall through to the wrong view. This is a defensive compatibility patch, not evidence of a first-class HR login/dashboard — **HR has no dedicated route, layout, sidebar, or dashboard anywhere in this repo.**

---

## 3. Screen/role parity vs. the Flutter docs (`screens.md`, `feature_matrix.md`)

**Where the Flutter docs already match**: the 4 original roles' core modules line up well — Attendance, Assignments (System A, `/api/assignments` — confirmed via `pages/Dashboard/TeacherDashboard/Assignments.tsx` and `StudentAssignments.tsx`, matching `production_roadmap.md` decision #3's resolution), Notices (Admin-only create, matching decision #2's resolution — no Teacher notice-creation call exists in this frontend either, consistent with the backend's real absence of that endpoint), Fees (including the manual-verification in-app payment flow `feature_matrix.md` already confirmed), Exams, Chat (Teacher/Student only, group-based, Parent genuinely absent — matches `feature_matrix.md` exactly), Payroll/Salary (Teacher: `GET /api/payroll/my` — read-only, matches "R, notification only").

**Where the web app has screens the mobile docs don't cover at all** (beyond the 2 new roles, which is its own section below):
- **Timetable** — Admin (`AdminTimetable`, wired to `GET/POST /api/timetable`) and Teacher/Student both have timetable screens. Not in `screens.md` at all.
- **Departments** — Admin `AdminDepartment`, wired to `/api/admin/departments` (+ a `/performance` sub-endpoint). Not in `screens.md`.
- **Student Follow-ups** — Admin `Studentfollowuppage`, wired to `/api/admin/student-followups`, including its Excel export. Not in `screens.md`.
- **ID Cards** — Admin `AdminIdCardPage`, wired to `/api/schools/me`, `/api/students`, and `/api/schools/me/branding` (school logo for the card template). Not in `screens.md`.
- **DualCalendar** (Parent only) — AD/BS (Nepali) side-by-side calendar, genuinely wired to real date-conversion logic (see §4). Not in `screens.md` at all, and not something the product doc ever mentioned.
- **Events** (Parent only) — routed, but **no backend call found** (`src/pages/Dashboard/ParentDashboard/Events.tsx` has no `axios`/`api` import at all — appears to be static/mock content, not yet wired to the real `/api/events` module `api_spec.md` §4.14 confirms exists server-side).
- **Backup** — not a separate screen, but a "Run Backup" button inside Admin Settings' "System & Backups" tab, wired to `GET /api/backup/school` (downloads a zip). Not in `screens.md`.
- **Reports** — Admin has a real Reports screen (`AdminReports`); the mobile `screens.md` "Reports Dashboard" entry already exists but flags export as `UNKNOWN` — see §4 below on the export-endpoint distinction, which resolves that flag.

**Where the mobile docs describe something the web app doesn't have (or has differently)**:
- **Online Class Links** — confirmed absent everywhere, consistent with `api_spec.md`'s backend finding. No trace in the frontend either.
- **Multi-child Parent UX** (`screens.md`'s flagged `ASSUMPTION`) — not specifically re-verified this pass; not ruled out either.
- **QR-based attendance self-check-in** — the mobile docs never described this, but it's worth flagging here because the web repo contains real, working QR-scanning code (`html5-qrcode`) that **is not wired into any route** — see §4, this is a "dead feature," not a shipped one on web either.

---

## 4. Module-scope findings (answers decision #5's evidence)

Of the ~15 backend modules `api_spec.md` §4.14 found with no counterpart in the original product docs, here's what has **real, backend-wired UI** in this web frontend vs. what's stubbed/static vs. what's entirely absent:

| Module | Web UI status |
|---|---|
| **SuperAdmin** (platform admin) | **Real, fully wired.** All 14 SuperAdmin page files import `axiosInstance` and call real endpoints: `/api/audit-logs`, `/api/superadmin/users`, `/api/superadmin/admins`, `/api/auth/users`, `/api/schools`, `/api/organizations` (full CRUD), `/api/subscriptions/all`, `/api/subscriptions/cancel/:id`, etc. |
| **Schools** (multi-tenancy) | **Real, wired** — `SuperAdminSchools.tsx` (1320 lines) manages school/tenant records; also touched by Admin's own `/api/schools/me` (ID card branding) and by ID-card generation. |
| **Subscriptions & Plans** | **Real, wired** — `Superadminsubscriptions.tsx` (915 lines), `Superadminplans.tsx` (697 lines), `RenewSubscriptions.tsx` (567 lines), plus a public `PlanSubscriptionPage` reachable from the landing page. |
| **Audit Logs** | **Real, wired** — `AuditLogs.tsx` calls `GET /api/audit-logs`. |
| **Contacts** (marketing-site inquiries) | **Real, wired** — `SuperAdminContacts.tsx` calls `GET /api/contacts`, `GET /api/contacts/:id`, `POST /api/contacts/:id/reply`. |
| **Receptionist** | **UI exists (8 screens, 2037 lines total: Dashboard, Visitors, Appointments, Deliveries, PhoneDirectory, Documents, Profile, Settings) but is entirely mock/static** — zero `axios`/`api` calls found anywhere in any Receptionist page or its layout. The role has a real login, route guard, sidebar and full navigation, but none of its screens talk to the backend's real `/api/receptionist` module. This is a materially different situation from every other role in this table. |
| **Departments** | **Real, wired** — see §3. |
| **Timetable** | **Real, wired** — see §3 (Admin creates/manages; Teacher/Student have their own timetable views, not independently verified as wired this pass but routed and present). |
| **Student Follow-ups** | **Real, wired**, including its Excel export endpoint. |
| **ID Cards** | **Real, wired** — see §3. |
| **Backup** | **Real, wired** — one button in Admin Settings, real `GET /api/backup/school` blob download. Not a full "Backup/Restore" management screen — just a one-way "download a backup" action, not restore, not scheduling. |
| **Events** | **Routed but not wired** — see §3, appears static/mock. |
| **Search** (global search) | **Not found.** No `/api/search` call anywhere in the frontend; no obvious global-search UI element found either (not exhaustively checked for a search bar component specifically). |
| **Leads / CRM** | **Not found.** No `/api/leads` call anywhere, no dedicated Leads UI. Possibly folded conceptually into Student Follow-ups (which `api_spec.md` itself describes as "CRM-style prospective/enrolled-student visit log") but that's speculation, not confirmed — the two are separate backend modules and only one has frontend UI. |
| **Complaints** | **Not found.** No `/api/complaints` call anywhere, no grievance/ticket UI of any kind. |
| **Organizations** | Has SuperAdmin UI (see above) but this is platform-internal (multi-org/reseller structure), not a school-level feature — almost certainly irrelevant to a school-facing mobile app regardless of the decision #5 outcome. |

### QR Attendance — genuinely surprising finding, flag this specifically

`html5-qrcode` is a real dependency, and there **is** a fully-built, working QR scanner component: `src/components/Student copy/Qrscannermodal.tsx` (110 lines — camera permission handling, `Html5Qrcode` lifecycle, error states, the works; its own header comment says it hands a decoded token to `attendanceApi.scanQR`). **But it is not imported or referenced anywhere else in the codebase** — not in `StudentAttendance.tsx`, not in any route, not in any button. It's dead code. Corroborating evidence: `src/api/attendanceapi.ts`'s own header comment says *"Types below mirror the controller's actual response shape, not the old QR-based one"* — i.e., the team built QR self-check-in, then the backend/product moved to teacher-marks-attendance-directly instead, and this component was left orphaned rather than deleted. **Conclusion: QR Attendance is not a shipped web feature today, despite the package and a working component existing.** This matters for decision #5 — "QR Attendance" as a roadmap line item should probably be understood as *possible, prototyped once, currently unused* rather than *live in production*.

### Nepali calendar — genuinely surprising finding, flag this specifically

`nepali-date-converter` is not just a stray dependency — it's genuinely wired into a real feature: `src/services/nepaliDate.ts` wraps it (`adToBs()`, Bikram Sambat month names, day abbreviations) and `src/pages/Dashboard/ParentDashboard/DualCalendar.tsx` (routed at `/parent/DualCalendar`) uses it to show an AD/BS side-by-side calendar. **This was never mentioned anywhere in the original product documentation, `product_requirements.md`, `screens.md`, or any prior CloudsLMS doc** — it's a real requirement the web product has that the entire doc set (built purely from backend capability, per this project's stated build history) had no way of discovering. If v2 parity is pursued, Nepali/BS calendar display is a genuinely new, previously-undocumented requirement, not an assumption — worth its own line item rather than folding it silently into "Reports" or "Dashboard" work.

### Excel export — precise distinction for the Flutter-side finding

`gap_analysis.md` §1 flagged "Report export/print" as `UNKNOWN` because `api_spec.md` didn't find an export operation on the **Reports** module specifically. That's still accurate — no `/api/reports/export` was found in this pass either. But **export absolutely exists elsewhere in the backend**, and the web frontend uses it exactly as documented in `api_spec.md`: `GET /api/fees/export/excel` (Fees), `GET /api/students/export` (Students, per `api_spec.md` §4.2), and `GET /api/admin/student-followups/export` (Student Follow-ups) are all real backend-generated `.xlsx` blobs downloaded via `responseType: "blob"` + `URL.createObjectURL` — **not** client-side spreadsheet generation from raw JSON. The `xlsx` npm package's only confirmed frontend-side use in this codebase is generating a static **import template** file for bulk student upload (`AdminStudentProfilePage.tsx`, `student_import_template.xlsx`), not exporting real data. So: **export exists and is real, but only for Fees/Students/Follow-ups, not Reports** — the original gap flag about Reports specifically still stands unresolved.

---

## 5. Answers to open decisions #4 and #5 — evidence only, no recommendation

### Decision #4 — role scope beyond Admin/Teacher/Student/Parent

- The web app has **6 real, routed roles with full logins and dashboards**: the original 4, plus **Receptionist** and **Super Admin**. Both have dedicated layouts, sidebars, navbars, and multiple screens (Receptionist: 8 screens; Super Admin: 13 screens).
- **Super Admin's UI is fully backend-wired** — real CRUD against `/api/superadmin/*`, `/api/schools`, `/api/subscriptions/*`, `/api/organizations`, `/api/audit-logs`, `/api/contacts`. This is a functioning platform-admin console in production, not a stub.
- **Receptionist's UI is a route/layout/navigation shell with mock content** — real login and route guard, but none of its 8 screens make a single backend call. Whether this reflects "not built yet" or "was built, then decided against, UI left in place" is `UNKNOWN — VERIFY` — nothing in the code indicates which.
- **HR/Staff has no dedicated UI at all** — only a defensive code comment acknowledging the backend has an `"hr"` actor role, with no route, layout, or dashboard for it. If HR accounts log in today, it's `UNKNOWN — VERIFY` which role branch they fall into (there's no `/hr/*` route to fall into).

### Decision #5 — which of the ~15 undocumented backend modules are in scope

- **Fully real and wired on web**: SuperAdmin, Schools, Subscriptions & Plans, Audit Logs, Contacts, Departments, Timetable, Student Follow-ups, ID Cards, Backup (partial — download only).
- **Routed but not wired (mock/static)**: Events, and the entire Receptionist module's screen set.
- **No web UI found at all**: Search, Leads/CRM, Complaints, Organizations (platform-internal, likely irrelevant to a school-facing app either way).
- **QR Attendance**: package + component exist, wired to nothing — effectively unshipped/abandoned on web, not a live feature.
- **Nepali (BS) calendar**: real, wired, Parent-only today — not a backend module in `api_spec.md`'s §4.14 list at all (it's a frontend-only date-formatting concern, not a backend concept), but it's a genuinely new requirement no CloudsLMS doc previously captured.

---

## 6. Design/UX patterns worth noting for parity (supplementary to `design_system.md`)

- **Navigation shape**: persistent left sidebar + top navbar per role, not bottom-tab navigation — expected for a desktop-oriented admin product, but confirms `design_system.md` v0.2's "4-item bottom nav" framing had no real evidence behind it (see `design_system.md` §5 for the full writeup).
- **Density**: real usage strongly favors small text (`text-xs`/`text-sm` are ~70% of all text-size utility usage) and heavy font weights (`font-bold`/`font-semibold`/`font-medium` dominate over `font-normal` by roughly 250:1) — a dense, table-and-badge-heavy admin aesthetic, not a spacious consumer-app one.
- **Brand color conflict**: this repo's real, repeatedly-used primary color is **emerald green** (Tailwind `emerald-500`/`600`), confirmed across the login modal and hundreds of component usages — this does not match the previously-assumed teal `#00BB7F`/purple `#625FFF` palette from the earlier live-site CSS scan (`design_system.md` v0.2). See `design_system.md` §1 for the full `CONFLICT` writeup; this needs the user's attention since it could mean the deployed site runs different code than this clone.
- **Icon language**: `lucide-react` (thin-stroke line icons) is the dominant icon set (~91 files) over `react-icons` (~38 files) — a real, verified answer to a previously-unrecoverable `ASSUMPTION` in `design_system.md` v0.2.
- **Payment UX**: the fee-payment flow's UI shape (phone number + transaction PIN form, shown alongside the school's static payment QR code image) is consistent with `api_spec.md`'s "manual-verification, not gateway" finding — worth matching this exact shape (QR-to-pay + manual reference entry) in the Flutter fee-payment screen rather than assuming a checkout-style gateway flow.

---

## 7. Re-verification

Re-run this analysis against a fresh `git log -1` in `cloud_lms_frontend` if significant time has passed or the repo has been updated — commit `bc924bced0f4d3eab97165dd4308960065cd608d` (2026-08-13) is the exact snapshot this document reflects.
