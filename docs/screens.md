# CloudsLMS — Flutter Screen Inventory

> Status: DRAFT v0.2 — derived from `product_requirements.md` and `feature_matrix.md`, now cross-checked against the backend-verified `api_spec.md` (source: `https://github.com/ArbindDas/SujalbackendForStudentmanagement`, cloned read-only). Screen breakdown (e.g. whether "Add" and "Edit" are one screen or two, whether a "Detail" screen is separate from its "List") is a Flutter-implementation judgment call, not something the source doc specifies — treat structure as `ASSUMPTION`, content/data as grounded in the doc where noted. Required-data field names are illustrative, not final. Screens now confirmed to have **no backend endpoint to call** are marked `BLOCKED — NO BACKEND` at the top of their entry and kept in this document rather than deleted, since they document a real product-doc-vs-backend conflict — see `api_spec.md` §12 for each one's full writeup.

Loading/Empty/Error conventions used throughout unless noted otherwise:
- **Loading**: skeleton placeholders matching the final layout (list rows / cards), not a blocking spinner.
- **Empty**: centered illustration + short message + primary action if one exists (e.g. "No notices yet").
- **Error**: inline banner or full-screen state with the error message and a **Retry** button; network errors distinguished from server errors where the API allows it.

---

## A. Auth & Common

#### Splash Screen
- Role(s): All (pre-auth)
- Purpose: Brand loading screen; checks stored session/token and routes to Login or the correct role dashboard.
- Entry point: App cold start.
- Navigates to: Login Screen, or the role-appropriate Dashboard if a valid session exists.
- Required data: Locally stored auth token + role.
- User actions: None (auto-navigates).
- Loading state: Logo + progress indicator while session check runs.
- Empty state: N/A.
- Error state: On corrupt/expired session, falls back to Login silently.

#### Login Screen
- Role(s): All
- Purpose: Authenticate and route to the correct role's dashboard.
- Entry point: Splash Screen (no session) or after Logout.
- Navigates to: Admin/Teacher/Student/Parent Dashboard.
- Required data: Credential fields — exact scheme `UNKNOWN` (email/username + password assumed from doc's "Admin ID and Password"); possible school/tenant identifier (`ASSUMPTION`, see product_requirements.md §2).
- User actions: Enter credentials, submit, tap "Forgot password."
- Loading state: Submit button shows spinner, fields disabled.
- Empty state: N/A.
- Error state: Inline error under the form for invalid credentials; banner for network failure.

#### Forgot Password Screen — `ASSUMPTION`
- Role(s): All
- Purpose: Request a password reset. Not mentioned in the source doc; included because Admin/Teacher/Student/Parent credentials are all issued/managed by others (Admin), so a recovery path is very likely required. **Confirm this exists in the backend before building.**
- Entry point: Login Screen.
- Navigates to: Back to Login (post-reset) or a confirmation screen.
- Required data: Email or phone identifier.
- User actions: Submit identifier, confirm reset (flow depends on backend — OTP vs. email link, `UNKNOWN`).
- Loading state: Submit button spinner.
- Empty state: N/A.
- Error state: Inline error for unknown identifier / network failure.

---

## B. Shared Across Roles

#### Notifications List
- Role(s): Admin, Teacher, Student, Parent
- Purpose: Chronological feed of system-generated notifications (attendance, assignments/exams, fees, salary, notices — per product_requirements.md §4.1 item 11).
- Entry point: Bottom nav / app bar bell icon from any Dashboard.
- Navigates to: The relevant detail screen for each notification (e.g. tapping a fee notification opens Fee Status).
- Required data: List of notifications with type, message, timestamp, read/unread, deep-link target.
- User actions: Tap to open source item, mark as read, pull-to-refresh.
- Loading state: Skeleton rows.
- Empty state: "No notifications yet."
- Error state: Retry banner.

#### Chat — Conversation List
- Role(s): **Teacher, Student only** — `CONFLICT RESOLVED`: `api_spec.md` §7/§12 #2 confirms **Parent has zero chat access** (no schema field for Parent participants, rejected outright at the Socket.IO auth layer) and **Admin has no oversight endpoint of any kind** — both removed from this screen's role list; this is not a UI gap, there is nothing on the backend for either role to call.
- Purpose: List of active **class/section group conversations**, not 1:1 threads. `api_spec.md` §7 confirms a `GroupConversation` belongs to one class (+ optional section); a Teacher creates it (`createdBy: Teacher`, required) and it auto-scopes to that class/section's Students as members — there is no counterpart-based 1:1 model anywhere in the backend.
- Entry point: Bottom nav "Chat."
- Navigates to: Chat Thread Screen.
- Required data: Conversation list — group name, class/section, member count, last message preview, unread count.
- User actions: Open a group; **only Teachers can create a new conversation** (`CONFIRMED`, `POST /api/group-chats` requires a Teacher actor) — Students can only view/participate in groups they're already enrolled in as a member, they cannot start one.
- Loading state: Skeleton rows.
- Empty state: "No conversations yet." (for a Teacher with no groups created; for a Student, "no class group yet" points back to a Teacher needing to create one).
- Error state: Retry banner.

#### Chat Thread
- Role(s): **Teacher, Student only** — see role note above; Parent removed, Admin was never in scope here.
- Purpose: Send/receive messages within a class/section group (many participants, not one counterpart).
- Entry point: Chat Conversation List.
- Navigates to: Back to list; group member list (Teacher can manage members/archive/delete the group per `api_spec.md` §4.11's `PATCH :id/members`, `PATCH :id/archive`, `DELETE :id` — Student cannot).
- Required data: Message history (paginated — exact pagination convention `UNKNOWN — VERIFY`, per `api_spec.md` §7), sender + role, timestamp, `readBy` (array of users who've read the message — `CONFIRMED`, not a simple delivered/read boolean).
- User actions: Type & send message, scroll for history, attach **one** media file — `CONFIRMED` real (image/video/voice only, via `api_spec.md` §4.11/§6 — image 15MB, video 100MB, voice 25MB), typing indicator (`group:typing` socket event, `CONFIRMED`), mark read (`group:read` → `group:read-receipt`, `CONFIRMED`).
- Loading state: Skeleton bubbles on open; inline spinner on pagination.
- Empty state: "Say hello" prompt for a brand-new group.
- Error state: Failed-to-send indicator per message with retry. Real-time delivery is Socket.IO (`CONFIRMED`, `api_spec.md` §7) — sending itself is a REST call, only the live fan-out to other members rides the socket, so a dropped socket connection shouldn't block sending, only live updates from others.

#### Notices List / Notice Detail
- Role(s): All (Create is Admin/Teacher only — see their sections)
- Purpose: View published notices/announcements/study material.
- Entry point: Bottom nav or Dashboard card.
- Navigates to: Notice Detail from the list.
- Required data: Title, body, author, audience/class scope, timestamp, attachments.
- User actions: Read, tap attachment. `ASSUMPTION`: Admin/Teacher edit and delete of their own already-published notices is implied by feature_matrix.md's CRUD columns (Admin `C R U D`, Teacher `C R`+`ASSUMPTION U/D`) but no edit/delete action is defined on this screen or on "Create Notice" — flagged, not built out, pending confirmation. See gap_analysis.md §4.
- Loading state: Skeleton cards.
- Empty state: "No notices yet."
- Error state: Retry banner.

#### Exam / Academic Schedule List / Detail
- Role(s): All (Create is Admin only — see Admin section)
- Purpose: View upcoming exams and academic events.
- Entry point: Bottom nav or Dashboard card.
- Navigates to: Schedule Detail from the list.
- Required data: Title, date/time, class/subject scope, description.
- User actions: Read; (Student/Parent) — none beyond viewing per doc.
- Loading state: Skeleton list.
- Empty state: "No upcoming schedules."
- Error state: Retry banner.

#### Profile / Account Settings
- Role(s): All
- Purpose: View/edit own profile, change password, toggle theme (light/dark — confirmed supported on the live site), logout.
- Entry point: Dashboard app bar / bottom nav.
- Navigates to: Change Password (sub-screen or dialog), Login (after logout).
- Required data: User's own profile fields; theme preference.
- User actions: Edit editable fields, toggle theme, logout.
- Loading state: Skeleton profile card.
- Empty state: N/A.
- Error state: Inline error on save failure.

---

## C. Admin

#### Admin Dashboard
- Role(s): Admin
- Purpose: Landing summary — counts of students/teachers, today's attendance snapshot, pending fee alerts, recent notices.
- Entry point: Post-login.
- Navigates to: Every Admin management screen below via cards/menu.
- Required data: Aggregate stats (`ASSUMPTION` on exact metrics — doc only says Admin can "view overall reports").
- User actions: Tap into any module.
- Loading state: Skeleton stat cards.
- Empty state: N/A (always has some content once school is set up).
- Error state: Retry banner per widget/section.

#### Manage Teachers — List / Add-Edit / Detail
- Role(s): Admin
- Purpose: Create and manage teacher accounts (doc: "Adding and managing teachers").
- Entry point: Admin Dashboard.
- Navigates to: Add/Edit form from list; Detail from a row.
- Required data: Teacher list (name, subject, class assignment, status); form fields for create/edit (`UNKNOWN` exact fields).
- User actions: Add, edit, deactivate/delete, search/filter.
- Loading state: Skeleton list / form shimmer.
- Empty state: "No teachers added yet" + "Add Teacher" CTA.
- Error state: Retry banner; inline form validation errors.

#### Manage Students — List / Add-Edit / Detail
- Role(s): Admin
- Purpose: Create and manage student accounts, class/section assignment.
- Entry point: Admin Dashboard.
- Navigates to: Add/Edit form; Detail from a row.
- Required data: Student list (name, class/section, parent link, status); form fields for create/edit.
- User actions: Add, edit, deactivate/delete, search/filter by class.
- Loading state: Skeleton list.
- Empty state: "No students added yet" + CTA.
- Error state: Retry banner; inline validation.

#### Manage Parents — List / Add-Edit
- Role(s): Admin
- Purpose: Create parent accounts and link them to one or more children.
- Entry point: Admin Dashboard, or from a Student Detail screen ("Add parent").
- Navigates to: Add/Edit form.
- Required data: Parent list; linked child/children.
- User actions: Add, edit, link/unlink child, delete.
- Loading state: Skeleton list.
- Empty state: "No parents added yet."
- Error state: Retry banner; inline validation.

#### Manage Classes / Sections / Subjects
- Role(s): Admin
- Purpose: Set up the academic structure (doc: "Creating classes, sections, and subjects").
- Entry point: Admin Dashboard.
- Navigates to: Add/Edit forms for each entity.
- Required data: Existing classes/sections/subjects list.
- User actions: Add, edit, delete/archive.
- Loading state: Skeleton list.
- Empty state: "No classes set up yet" + CTA (critical first-run state, since setup must happen before anything else works per onboarding flow).
- Error state: Retry banner; inline validation.

#### Attendance Overview (school-wide)
- Role(s): Admin
- Purpose: Monitor attendance across all classes (doc: "Marking and monitoring attendance across the school"). `CONFIRMED` (`api_spec.md` §4.6): Admin does **not** directly edit a locked attendance record — attendance locks immediately once a Teacher submits it. The prior `ASSUMPTION` about a direct correction action is resolved: correction is a **separate request/approve/reject workflow** (`/api/attendance/corrections`), not an inline edit here.
- Entry point: Admin Dashboard.
- Navigates to: Class-level attendance detail; **a Correction Requests queue (needs its own screen entry — flagged, not specified in this pass)** where Admin/Superadmin can `PATCH :id/approve` or `:id/reject` a correction request submitted by a Teacher/HR/Staff. This is now confirmed real and should get a proper screen spec in the next pass rather than being folded into this one without a defined layout.
- Required data: Per-class/per-day attendance summary; separately, a list of pending correction requests (requester, target record, old→new status, reason).
- User actions: Filter by class/date, drill into a class; navigate to the correction-requests queue (approve/reject actions live on that queue's own screen, not here).
- Loading state: Skeleton table/list.
- Empty state: "No attendance marked for this date yet."
- Error state: Retry banner.

#### Create / Manage Exam Schedule
- Role(s): Admin
- Purpose: Create exam and academic schedules visible to all roles.
- Entry point: Admin Dashboard.
- Navigates to: Schedule List (shared screen, §B) with edit affordances for Admin.
- Required data: Form fields (title, date, class/subject scope, description).
- User actions: Create, edit, delete a schedule entry.
- Loading state: Form shimmer / save spinner.
- Empty state: N/A (form).
- Error state: Inline validation; save-failure banner.

#### Create Notice
- Role(s): Admin (Teacher has a scoped variant, see §D)
- Purpose: Publish a notice/announcement to students/parents (school-wide or scoped).
- Entry point: Admin Dashboard or Notices List.
- Navigates to: Back to Notices List on publish.
- Required data: Title, body, audience scope (school-wide vs. class), optional attachment.
- User actions: Compose, attach file, select audience, publish.
- Loading state: Publish button spinner.
- Empty state: N/A (form).
- Error state: Inline validation; publish-failure banner.

#### Fee Structure Setup
- Role(s): Admin
- Purpose: Define fee structures per class (doc: "set up fee structures for different classes").
- Entry point: Admin Dashboard.
- Navigates to: Fee Collection / Student Fee Status.
- Required data: Fee items per class (amount, due date, category).
- User actions: Create/edit fee structure line items.
- Loading state: Form shimmer.
- Empty state: "No fee structure set up for this class yet."
- Error state: Inline validation; save-failure banner.

#### Fee Collection / Student Fee Status List
- Role(s): Admin
- Purpose: Track which students have paid vs. pending (doc: "track which students have paid and which are pending").
- Entry point: Admin Dashboard.
- Navigates to: Individual student's fee detail/history; record-payment action.
- Required data: Per-student paid/pending status, amounts, due dates.
- User actions: Filter (paid/pending/class), record a payment, view a student's fee history.
- Loading state: Skeleton list.
- Empty state: "No fee records yet" (pre fee-structure setup).
- Error state: Retry banner.

#### Teacher Salary Management
- Role(s): Admin
- Purpose: Manage and record teacher salaries (doc §8).
- Entry point: Admin Dashboard.
- Navigates to: Individual teacher's salary history.
- Required data: Per-teacher salary records, payment status.
- User actions: Process/update a salary payment, view history.
- Loading state: Skeleton list.
- Empty state: "No salary records yet."
- Error state: Retry banner; inline validation on save.

#### Reports Dashboard
- Role(s): Admin
- Purpose: Overall attendance/fee/academic reports (doc §3.1 last bullet).
- Entry point: Admin Dashboard.
- Navigates to: N/A (terminal screen, possibly with export — `UNKNOWN` if export/print is supported).
- Required data: Aggregated report data, `UNKNOWN` exact metrics/format.
- User actions: Filter by date range/class, (maybe) export.
- Loading state: Skeleton charts/cards.
- Empty state: "Not enough data yet."
- Error state: Retry banner.

---

## D. Teacher

#### Teacher Dashboard
- Role(s): Teacher
- Purpose: Landing summary — today's classes, pending assignments to check, recent notices, salary notification banner.
- Entry point: Post-login.
- Navigates to: Mark Attendance, Assignments, Notices, Chat, Schedule.
- Required data: Own class/section assignment, today's schedule snapshot.
- User actions: Tap into any module.
- Loading state: Skeleton stat cards.
- Empty state: N/A.
- Error state: Retry banner per section.

#### Mark Attendance
- Role(s): Teacher
- Purpose: Mark daily attendance for their class (doc §4 — instantly visible to Admin + parent once saved).
- Entry point: Teacher Dashboard.
- Navigates to: Attendance History on save.
- Required data: Class roster for today.
- User actions: Mark each student present/absent/late, submit.
- Loading state: Skeleton roster list.
- Empty state: "No students in this class yet" (blocks marking — edge case, points back to Admin setup).
- Error state: Save-failure banner with retry (important: don't lose marked state on failure).

#### Attendance History (own class)
- Role(s): Teacher
- Purpose: Review past attendance entries for their class.
- Entry point: Teacher Dashboard / Mark Attendance.
- Navigates to: N/A.
- Required data: Date-range attendance records.
- User actions: Filter by date/student.
- Loading state: Skeleton list.
- Empty state: "No attendance history yet."
- Error state: Retry banner.

#### Assignments List (own class) / Create-Edit Assignment
- Role(s): Teacher
- Purpose: Upload and manage assignments for their class (doc §5).
- Entry point: Teacher Dashboard.
- Navigates to: Assignment Submissions Review.
- Required data: Assignment list (title, due date, submission count); create form (title, description, due date, attachment).
- User actions: Create, edit, delete an assignment. `CONFLICT`: feature_matrix.md grants Teacher only `C R U` (no `D`) on Assignments — this delete action is not corroborated there. Not removed since it's unclear which document is wrong; flagged for backend verification. See gap_analysis.md §4.
- Loading state: Skeleton list / form shimmer.
- Empty state: "No assignments yet" + CTA.
- Error state: Retry banner; inline validation.

#### Assignment Submissions Review
- Role(s): Teacher
- Purpose: "Check assignments" per doc — review what students submitted.
- Entry point: Assignments List.
- Navigates to: Individual submission detail.
- Required data: Per-student submission status + content.
- User actions: Open a submission, mark as checked/graded (`UNKNOWN` if grading has a score or just a checked flag).
- Loading state: Skeleton list.
- Empty state: "No submissions yet."
- Error state: Retry banner.

#### Create/Edit Notice (own class) — `BLOCKED — NO BACKEND ENDPOINT`
**Do not build.** `api_spec.md` §4.7/§12 #6 confirms `noticeRoutes.js` only grants notice creation to `protectAdmin` and `protectSuperAdmin` — `noticeSchema.js`'s `createdByModel` enum is `Admin, User` only, Teacher is not a valid creator anywhere in the backend as committed. This screen was added in an earlier gap-analysis pass to resolve a broken cross-reference from the Admin "Create Notice" screen (§C), on the reasonable-at-the-time assumption that the product doc's "Admin or Teacher publishes" claim would hold up against the backend. It didn't. Kept here (not deleted) to document the conflict — do not implement until either the backend adds a teacher-facing notice-creation endpoint, or the product doc's claim is formally walked back.
- Role(s): Teacher
- Purpose: Publish a notice/announcement scoped to the teacher's own class (doc: "Admin or Teacher publishes," product_requirements.md §4.1 item 5; feature_matrix.md gives Teacher `C R`, `ASSUMPTION` on `U/D`, own-class scope only). This entry resolves a broken cross-reference — the Admin "Create Notice" screen in §C previously pointed to "see §D" for this variant, but it had never been written up. See gap_analysis.md §14.
- Entry point: Teacher Dashboard or Notices List.
- Navigates to: Back to Notices List on publish.
- Required data: Title, body, own class scope (implicit, not selectable — `ASSUMPTION`), optional attachment.
- User actions: Compose, attach file, publish. Edit/delete of an already-published notice is asserted by feature_matrix.md's CRUD columns but not confirmed as a real UI affordance — see gap_analysis.md §4.
- Loading state: Publish button spinner.
- Empty state: N/A (form).
- Error state: Inline validation; publish-failure banner.

#### Share Online Class Link — `BLOCKED — NO BACKEND SUPPORT`
**Do not build.** `api_spec.md` §10/§12 #1 confirms **zero** support for this feature anywhere in the backend — no route, no model field, no meeting-link concept; a full-repo grep for "meet"/"zoom"/"meeting link" returned no matches. Kept here to document the conflict, not as a build-ready spec. Needs a product decision: is this genuinely unbuilt server-side, planned elsewhere, or was it never real?
- Role(s): Teacher
- Purpose: Share a meeting link (e.g. Google Meet, per doc §9) for their class's online session.
- Entry point: Teacher Dashboard.
- Navigates to: N/A (posts to class feed/notice — `ASSUMPTION` on exact delivery mechanism).
- Required data: Link URL, class/section, optional scheduled time.
- User actions: Paste/enter link, select class, share.
- Loading state: Share button spinner.
- Empty state: N/A (form).
- Error state: Inline validation (invalid URL), share-failure banner.

---

## E. Student

#### Student Dashboard
- Role(s): Student
- Purpose: Landing summary — today's schedule, pending assignments, recent notices, unread chat/notification badges.
- Entry point: Post-login.
- Navigates to: My Attendance, Assignments, Schedule, Notices, Chat, Online Class.
- Required data: Own enrollment (class/section), summary counts.
- User actions: Tap into any module.
- Loading state: Skeleton cards.
- Empty state: N/A.
- Error state: Retry banner per section.

#### My Attendance
- Role(s): Student
- Purpose: Check own attendance record (doc §3.3).
- Entry point: Student Dashboard.
- Navigates to: N/A.
- Required data: Date-range attendance history, summary percentage.
- User actions: Filter by month.
- Loading state: Skeleton list/calendar.
- Empty state: "No attendance recorded yet."
- Error state: Retry banner.

#### Assignments List / Assignment Detail & Submit
- Role(s): Student
- Purpose: View and submit assignments (doc §3.3, §5).
- Entry point: Student Dashboard.
- Navigates to: Assignment Detail from list.
- Required data: Assignment list with due dates + submission status; detail with description/attachment; submission form.
- User actions: Open assignment, attach/submit work, view own submission status.
- Loading state: Skeleton list; submit button spinner.
- Empty state: "No assignments yet."
- Error state: Retry banner; submit-failure with retry (don't lose composed submission).

#### Join Online Class — `BLOCKED — NO BACKEND SUPPORT`
**Do not build.** Same finding as the Teacher's "Share Online Class Link" screen — `api_spec.md` §10/§12 #1 confirms this feature has no backend of any kind. Kept here to document the conflict, not as a build-ready spec.
- Role(s): Student
- Purpose: Join an online session via the link the teacher shared (doc §9).
- Entry point: Student Dashboard, or a notice/notification.
- Navigates to: External app/browser (e.g. Google Meet) via deep link.
- Required data: Active/upcoming class link(s) with time and subject.
- User actions: Tap to join (opens external link).
- Loading state: Skeleton card while link list loads.
- Empty state: "No online classes scheduled right now."
- Error state: Retry banner; "link unavailable" state if the teacher hasn't shared one yet.

---

## F. Parent

#### Parent Dashboard
- Role(s): Parent
- Purpose: Landing summary for their child (or a child selector if multiple children — `ASSUMPTION`, not addressed in doc).
- Entry point: Post-login.
- Navigates to: Child's Attendance, Fee Status, Assignments, Schedule, Notices, Chat.
- Required data: Linked child/children profile(s).
- User actions: Switch child (if >1), tap into any module.
- Loading state: Skeleton cards.
- Empty state: "No child linked to this account yet" (edge case — points back to Admin setup).
- Error state: Retry banner per section.

#### Child's Attendance
- Role(s): Parent
- Purpose: View child's attendance (doc §3.4, §4).
- Entry point: Parent Dashboard.
- Navigates to: N/A.
- Required data: Child's date-range attendance history.
- User actions: Filter by month.
- Loading state: Skeleton list/calendar.
- Empty state: "No attendance recorded yet."
- Error state: Retry banner.

#### Child's Fee Status / History
- Role(s): Parent
- Purpose: View payments made and dues remaining (doc §3.4, §7).
- Entry point: Parent Dashboard.
- Navigates to: A payment-submission form. **`CONFIRMED`** (`api_spec.md` §4.9, §12 #8) — in-app payment submission is real: `POST /api/payments/fee/submit` (body: `feeId`, `installmentId?`, `phoneNumber`, `transactionPin`). This is a **manual-verification** flow, not a payment gateway — the payer enters the phone number + transaction PIN their own eSewa/Khalti app shows after transferring against the school's static QR code (`GET /schools/payment-qr`), and an Admin reviews/approves/rejects it. Previously marked `UNKNOWN` and assumed view-only.
- Required data: Fee line items, paid/due amounts, due dates; for the payment form: the school's payment QR image, a phone-number field, a transaction-PIN field.
- User actions: View history; filter by term/year; **submit a payment** (enter phone number + transaction PIN against a specific fee/installment) — new action, confirmed real.
- Loading state: Skeleton list; submit-button spinner on the payment form.
- Empty state: "No fee records yet."
- Error state: Retry banner; inline validation + submit-failure banner on the payment form. Submitted payments show a `pending` status until Admin approves/rejects — surface that status distinctly from "paid."

#### My Fee Status / History — *added this pass, Student equivalent of the Parent screen above*
- Role(s): Student
- Purpose: View own fee payments/dues and submit a payment, mirroring the Parent screen. **`CONFIRMED`** (`api_spec.md` §4.9): `GET /fees/student/:studentId` and `POST /api/payments/fee/submit` are both reachable by a Student's own `protect`-guarded session, not Parent-only. This screen did not previously exist in this document — `screens.md` had a fee screen for Parent but none for Student, despite `feature_matrix.md` granting Student `R`+`C` fee access; added here rather than left as a silent gap, using only the fields already confirmed in `api_spec.md`.
- Entry point: Student Dashboard.
- Navigates to: A payment-submission form (same shape as the Parent screen's).
- Required data: Own fee line items, paid/due amounts, due dates; PDF receipt link (`GET /fees/:feeId/receipt`, `CONFIRMED`); school payment QR image.
- User actions: View history; filter by term/year; submit a payment (phone number + transaction PIN).
- Loading state: Skeleton list; submit-button spinner on the payment form.
- Empty state: "No fee records yet."
- Error state: Retry banner; inline validation + submit-failure banner on the payment form.

#### Child's Assignments (read-only)
- Role(s): Parent
- Purpose: View child's assignments/academic updates (doc §3.4).
- Entry point: Parent Dashboard.
- Navigates to: Assignment Detail (read-only, no submit action).
- Required data: Same as Student's Assignments List, but read-only.
- User actions: View only.
- Loading state: Skeleton list.
- Empty state: "No assignments yet."
- Error state: Retry banner.
