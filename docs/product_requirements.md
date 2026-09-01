# CloudsLMS — Product Requirements

> Status: DRAFT v0.3 — built from `CloudsLMS_Documentation.docx` (provided) and live-site technical analysis (https://www.cloudslms.com, read-only CSS/JS inspection), **now cross-checked against `docs/api_spec.md`**, which was rewritten from a read-only clone of the actual backend source (`https://github.com/ArbindDas/SujalbackendForStudentmanagement`). Marked `ASSUMPTION` where neither source confirms a detail; marked `DISCREPANCY` where the doc and the live site's bundle disagree; marked `RESOLVED` where `api_spec.md` has since settled the question (with a pointer to the resolving section); marked `CONFLICT — BACKEND` where the backend actively contradicts this document rather than merely leaving it unconfirmed. `api_spec.md` §12 is the authoritative, full conflicts list — this document only annotates its own claims inline.

## 1. What CloudsLMS is
CloudsLMS is a **web-based School & College Management System**, built by **Clouds Nepal Web**, that centralizes a school/college's daily academic and administrative work: students, teachers, parents, attendance, fees, exams, assignments, notices, and online classes — replacing paper registers and scattered tools. This Flutter app is a mobile client for the same product.

## 2. Business model / onboarding (confirmed from doc)
CloudsLMS is **multi-tenant** — each subscribing school/college is its own tenant with its own Admin account:
1. School visits www.cloudslms.com.
2. Starts a **7-day free demo** with full Admin access (no commitment).
3. Explores the system as Admin: creates classes, adds teachers/students/parents.
4. Chooses a **subscription plan** sized to their student/teacher/staff count.
5. Receives **Admin ID + password by email** after subscribing.
6. Admin sets up classes/sections, adds teachers/students, configures fees.
7. All four roles log in to their own dashboard for daily use.

`RESOLVED` (was `ASSUMPTION`): confirmed via `api_spec.md` §2 — there is no school-code/subdomain field anywhere in the login request. Login is exactly `{ email, password }`; `schoolId` is already stored on the account and resolved server-side after JWT verification. **No tenant-entry step belongs on the mobile Login screen.**

## 3. Roles (per product documentation — 4 core roles; **backend confirms additional actor types, see note below**)
| Role | Created by | Core capabilities (per doc) |
|---|---|---|
| **Admin** | Self (via subscription) | Add/manage teachers, students, parents; create classes/sections/subjects; monitor attendance school-wide; create exam & academic schedules; manage assignments & notices; handle student fees and teacher salaries; oversee the chat system; send notifications; view attendance/fee/academic reports |
| **Teacher** | Admin | Mark daily attendance for their class; create & check assignments; share notices/study material; chat with students & parents; view exam/academic schedules; receive salary notifications; share online-class links |
| **Student** | Admin (via parent/school setup — exact flow `ASSUMPTION`) | Check attendance; view & submit assignments; view exam/academic schedules; read notices; chat with teachers; join online classes |
| **Parent** | Admin (linked to child) | View child's attendance, fees (payments + dues), assignments/academic updates, exam schedules, notices; chat with teachers; receive automatic notifications on any new activity for their child |

`PRODUCT-DECISION NEEDED` (not resolvable from the backend alone): `api_spec.md` §3 confirms the backend actually implements **8 distinct actor types**, not 4 — the 4 above are a subset of what's supported server-side. The 4 additional actor types found in code:
- `superadmin` — a platform-level operator tier above per-school Admin, managing all schools/tenants.
- `hr` — an `Admin`-collection role recognized in attendance/leave/staff modules; how an account actually gets this role is `UNKNOWN — VERIFY`.
- `staff` — non-teaching employees (accountant, librarian, driver, cleaner, security guard, IT, office staff).
- `receptionist` — a front-desk role with its own separate auth track and read-mostly permission flags (view students/teachers/parents/attendance).

Whether HR, Staff, Receptionist, or SuperAdmin workflows belong in **this mobile app's scope** is a product decision, not something the backend's mere support for the capability can answer — the backend supporting a role doesn't mean the school-facing mobile client should expose it. Flagged for the product owner; see `api_spec.md` §3 and §12 row 5.

## 4. Modules
### 4.1 Confirmed by product documentation
1. **User Management** — Admin creates/manages Teacher, Student, Parent accounts.
2. **Academic Structure** — Classes, Sections, Subjects (Admin-configured).
3. **Attendance** — Teacher marks daily per class; instantly visible to Admin + concerned parent.
4. **Assignments** — Teacher uploads/checks; Student views & submits.
5. **Notices / Study Material** — Admin or Teacher publishes; visible to Students/Parents.
6. **Exam & Academic Schedules** — Admin creates; visible read-only to Teacher/Student/Parent.
7. **Fee Management** — Admin sets fee structure per class, tracks paid/pending; Student/Parent view history & dues.
8. **Teacher Salary Management** — Admin manages/records; Teacher gets notified on processing/updates.
9. **Online Classes (E-Classroom)** — Teacher shares a class link (doc's example: **Google Meet** link, not a native SDK integration); Student joins from dashboard. `CONFLICT — BACKEND` (`api_spec.md` §10, §12 row 1): **this feature does not exist anywhere in the backend as committed** — no route, no model field, no meeting-link concept, zero grep matches for "meet"/"zoom"/"meeting link" in the entire source tree. This is no longer an implementation detail to fill in; it's a scope question — decide with the backend team whether this is genuinely unbuilt, planned elsewhere, or should be dropped from the mobile app's v1.
10. **Chat** — as originally described in the product doc: in-app messaging, Teacher↔Student, Teacher↔Parent (re: a specific student), Admin oversees the whole system. `CONFLICT — BACKEND` (`api_spec.md` §7, §12 row 2): the real implementation is **class/section-scoped group chat created by a Teacher**, with **Student members only** — Parents have no schema field, no send permission, and are explicitly rejected at the Socket.IO auth layer; there is no 1:1 Teacher↔Student or Teacher↔Parent conversation model, and no Admin oversight endpoint. The description above is retained for historical record but should not be built against.
11. **Notifications** — Automatic, for: attendance updates, new assignments/exam schedules, fee payments/dues, salary updates, notices/announcements. `RESOLVED` (`api_spec.md` §8, §12 row 3): delivery is confirmed **in-app poll (`GET /api/notifications`) + Resend email only** — no push notification provider of any kind is integrated server-side (zero grep matches for firebase/fcm/push/apns/expo/onesignal). Also confirmed: the scheduled/automatic cron jobs behind fee-due reminders, subscription-expiry checks, etc. are wired but **commented out** in the committed `server.js` — as shipped, notifications only fire synchronously from direct user actions, not on a schedule.
12. **Reports** — Admin views overall attendance/fee/academic reports.

### 4.2 Signals from the live site's code bundle NOT mentioned in the doc — now partially resolved against the backend
These appeared with meaningful frequency when the shipped JS bundle was scanned for domain keywords; the backend pass in `api_spec.md` resolved most of them:
- **Transport** (32 occurrences) — `UNKNOWN — VERIFY`, still unresolved. No targeted grep for a Transport-named route/model was performed in the backend pass (`api_spec.md` §11) — genuinely not yet confirmed either way.
- **Leave** (46 occurrences) — `RESOLVED — CONFIRMED REAL`. A dedicated `LeaveRequest` model + `/api/attendance/leave` routes exist: Student/Teacher/Staff can apply, Admin/Superadmin approve/reject (`api_spec.md` §4.6, §5).
- **ID Card** (4 occurrences) — `RESOLVED — CONFIRMED REAL`. A dedicated `/api/id-cards` module generates PDF+QR ID cards (`pdfkit`+`qrcode`) (`api_spec.md` §4.14).
- **Library** (1 occurrence) — `UNKNOWN — VERIFY`, still unresolved. No targeted grep performed; low original signal.
- **Certificate** (2 occurrences) — `LIKELY RESOLVED`, not a dedicated module: the generic `Document` model's `documentType` enum includes `certificate`, `academic_certificate`, `experience_letter`, etc. (`api_spec.md` §5) — almost certainly the real backing store, but not a standalone "Certificate module" the way ID Cards is.
- **Payroll** as a distinct bundle term (40 occurrences) — `RESOLVED — CONFIRMED`, exactly as guessed: it's the code-level name for "Teacher Salary Management" (§4.1 item 8), backed by a `Payroll` + `StaffSalary` model pair, considerably richer than this doc's one-line description (`api_spec.md` §4.10).

**Beyond this original list**, the backend pass found roughly **15 more fully-built modules with zero presence anywhere in this document or any other mobile doc**: SuperAdmin platform administration, Subscriptions & Plans (including the literal 7-day-demo endpoint), Organizations, full multi-tenant School management, Leads/CRM, Complaints, Receptionist role, Departments, Timetable, QR-code attendance, Backup/Restore, Events (separate from Exam Schedules), Student Follow-ups, admin Dashboard/Reports/Search, and a public Contacts form. See `api_spec.md` §4.14 for the full inventory — this document's original 5-term bundle scan substantially undercounted the real gap between the marketing doc and the actual product.

## 5. Technology (confirmed from doc, now cross-checked against the real backend — `api_spec.md`)
- **Stack: MERN** — React.js frontend (the live site), **Node.js + Express.js backend**, **MongoDB** database. `RESOLVED — CONFIRMED`: the real backend is Express 5 + Mongoose, exactly as the doc described (`api_spec.md` §1).
- **Chat & Notifications**: "real-time messaging system." `RESOLVED — PARTIALLY CONFIRMED`: Socket.IO is confirmed, but it's **scoped to Chat only** — Notifications have no real-time channel at all, they're poll + email (`api_spec.md` §7–§9). The doc's framing of one "real-time messaging system" covering both was an overstatement of what actually exists.
- **Online Classes**: shared meeting links (e.g. Google Meet) rather than an embedded video SDK — teachers just paste/share a link. `CONFLICT — BACKEND`: no longer treat this as confirmed. `api_spec.md` §10/§12 row 1 found **zero backend support for this feature at all** — no route, no model field, no meeting-link concept anywhere in the source tree. This line describes what the product doc claims, not what exists server-side today.
- Implication for the API: expect a **Node/Express REST API** with **MongoDB ObjectId-style string IDs** (not integers). `RESOLVED — CONFIRMED` (`api_spec.md` §1, §5) — though unlike a typical assumption there is **no `/v1` version prefix**; the base path is flat `/api/...`.

## 6. Non-functional expectations (draft)
- Role-based access: each user "only sees the information and tools relevant to them" (confirmed intent from doc) — must be enforced in-app via route guards at minimum, alongside server-side enforcement. **Caution**: `api_spec.md` §3 found that `organizationRoutes.js` and `schoolRoutes.js`'s core CRUD have **no auth middleware applied server-side at all** — "server-side enforcement" cannot simply be assumed to exist for every route; verify per-endpoint before relying on it.
- Light + dark theme support — confirmed on the live site (theme persisted in `localStorage`, respects `prefers-color-scheme`); replicate in Flutter.
- Push/real-time notifications are core to the product (§4.1 item 11). `RESOLVED` (was `ASSUMPTION`) — **confirmed NOT built**: no push notification provider (FCM or otherwise) is integrated anywhere in the backend (`api_spec.md` §8). The mobile app has exactly two real channels available today: poll `GET /api/notifications`, or rely on the Resend transactional emails the backend already sends for some events. Push is a **future backend addition**, not a mobile-side integration decision.
- Offline tolerance for read-heavy screens (attendance history, schedules) — not mentioned in doc, `ASSUMPTION`, nice-to-have rather than confirmed requirement. Still unresolved — nothing in the backend pass speaks to this either way, since it's purely a mobile-client concern.

## 7. Open questions
Items 1–6 from the original list are now resolved against `api_spec.md`:
1. ~~Are Transport, Leave, ID Card, Library, Certificate real, mobile-in-scope modules?~~ **Partially resolved** — Leave and ID Card confirmed real; Certificate likely covered by the generic `Document` model; Transport and Library remain genuinely unconfirmed. See §4.2 above.
2. ~~Exact auth mechanism and multi-tenant login flow.~~ **Resolved** — JWT bearer (60m access + 30d refresh token), no tenant field at login. `api_spec.md` §2.
3. ~~Real-time protocol for chat/notifications.~~ **Resolved** — Socket.IO, but scoped to Chat only; Notifications are poll-based, not real-time. `api_spec.md` §7–§9.
4. ~~Whether Student accounts are created directly by Admin or self-registered/linked via Parent.~~ **Resolved** — Admin creates Student accounts directly via `POST /api/students`. `api_spec.md` §4.2.
5. ~~Whether "chat" supports Student↔Parent or Admin-initiated conversations.~~ **Resolved** — no, and more restrictively than assumed: it's Teacher-created class/section group chat, Student members only; Parents have zero access. `api_spec.md` §7.
6. ~~Push notification provider.~~ **Resolved** — none integrated; no push provider of any kind exists in the backend. `api_spec.md` §8.

**New open questions raised by the backend pass** (genuinely unresolved — need a product decision or further backend investigation, not answerable from `api_spec.md` alone):
1. Is Online Classes genuinely unbuilt, planned in a different service, or should it be dropped from mobile v1 scope? (`api_spec.md` §12 row 1) — blocks `implementation_backlog.md` Epic E9 entirely.
2. Should Notice creation be added to the backend for Teachers, or should the mobile Teacher "Create/Edit Notice" screen be dropped? The doc's "Admin or Teacher publishes" claim conflicts with the real `noticeSchema.js`'s `createdByModel` enum (`Admin`, `User` only — no `Teacher`). (`api_spec.md` §4.7, §12 row 6)
3. Are HR, Staff, Receptionist, or SuperAdmin workflows meant to be in this mobile app's scope at all? The backend supports all four; whether the school-facing app should expose them is a product call. (§3 above, `api_spec.md` §12 row 5)
4. Should in-app fee payment (confirmed real — manual phone+PIN verification reviewed by an Admin) be added back into mobile scope? It was previously excluded by `user_flows.md` Flow 7 on the assumption it didn't exist. (`api_spec.md` §4.9, §12 row 8)
5. How does an `"hr"`-role Admin account actually get created? No controller path sets this role anywhere in the code reviewed. (`api_spec.md` §11)
6. What is the real purpose of the public self-registration path (`POST /api/auth/register`, creates a generic `role:"user"` account) and the separate PIN-reset flow (distinct from password reset)? Neither maps to anything in this product doc. (`api_spec.md` §2, §11)
7. Should Notice attachments be added to the backend schema (currently absent entirely) or dropped from the mobile Notice screens' attachment UI? (`api_spec.md` §12 row 15)
8. Production base URL / hosting provider — needed before any environment/deploy-config work can start. (`api_spec.md` §11)
