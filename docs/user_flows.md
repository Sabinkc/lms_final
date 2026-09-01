# CloudsLMS — User Flows

> Status: DRAFT v0.2 — grounded in `CloudsLMS_Documentation.docx` where it describes process/sequence (Admin Setup is taken almost verbatim from the doc's "Getting Started" section); other flows are reconstructed from the doc's feature descriptions plus standard mobile-app UX patterns and marked `ASSUMPTION` where the doc doesn't specify sequencing or error handling. Screen names reference `screens.md`. **Cross-checked against `docs/api_spec.md`'s backend-verified findings** (source: read-only analysis of the real backend repository) — resolved `ASSUMPTION`/`UNKNOWN` markers are labeled **Resolved**/**Confirmed** inline, citing the relevant `api_spec.md` section; places where the backend contradicts what this document assumed are labeled **CONFLICT** or **CORRECTED**. Nothing below is invented beyond what `api_spec.md` states.

## 1. Login
1. User opens app → **Splash Screen** checks for a stored session.
2. No valid session → **Login Screen**.
3. User enters credentials — **Confirmed** (api_spec.md §2/§4.1): `email` + `password` only, `POST /api/auth/login`. No school-code/tenant field belongs on this screen — `schoolId` is resolved server-side from the account, not supplied by the client.
4. Success → app stores the access token (60m) **and** refresh token (30d — `POST /api/auth/refresh` is a real, callable endpoint, see architecture.md §7) + role, routes to the matching Dashboard (Admin/Teacher/Student/Parent).
5. Failure (bad credentials) → inline error on Login Screen, fields retained except password.
6. Failure (network) → banner with retry, form untouched.
- **Resolved** (api_spec.md §2): no account-lockout-after-N-failed-attempts mechanism exists in the backend — only OTP-retry-attempt counters (unrelated to login itself, they gate OTP verification attempts). Do not build a lockout UI for this screen.

## 2. Logout
1. User opens **Profile / Account Settings** from any Dashboard.
2. Taps "Logout" → confirmation dialog (`ASSUMPTION`, standard pattern to prevent accidental logout).
3. Confirms → local token/session cleared, in-flight requests cancelled, app routes to **Login Screen**.
- Edge case: logout triggered by a 401 from the API (expired token) — same end state, but silent (no confirmation dialog), possibly with a toast "Session expired, please log in again."

## 3. Admin Setup (from doc's "Getting Started," §2)
1. School visits www.cloudslms.com and starts a **7-day free demo** (web-only, not part of this Flutter app's flow, but relevant context: demo grants full Admin access up front).
2. School evaluates the system as Admin: creates classes, adds teachers/students/parents during the demo.
3. School selects a subscription plan sized to their student/teacher/staff count.
4. School receives **Admin ID + password by email**.
5. **In the Flutter app**: Admin logs in for the first time (see Flow 1) → **Admin Dashboard**.
6. Admin sets up the academic structure first (this is a hard dependency for everything else): **Manage Classes/Sections/Subjects** → create at least one class/section.
7. Admin adds staff and learners: **Manage Teachers** → add teacher(s); **Manage Students** → add student(s), assigning each to a class/section; **Manage Parents** → add parent(s), linking each to their child/children.
8. Admin configures fees: **Fee Structure Setup** → define fee items per class.
9. Setup complete — Teacher/Student/Parent accounts can now log in and see data (steps 6-8 are prerequisites for their dashboards to be non-empty).
- **Partially resolved** (api_spec.md §2, §12 row 14): **Confirmed for Admin** — Admin credentials, including the plaintext password, are auto-emailed via `adminWelcomeEmailTemplate`. **Still `UNKNOWN — VERIFY` for Teacher/Student/Parent specifically** — their creation flows were not traced for the same email-send call this pass; do not assume they get identical treatment until confirmed.

## 4. Teacher — Mark Attendance
1. Teacher logs in → **Teacher Dashboard**.
2. Taps into **Mark Attendance**.
3. App loads today's class roster.
4. Teacher marks each student present/absent/late.
5. Teacher submits.
6. Success → confirmation + navigates to/updates **Attendance History**. **Confirmed** (api_spec.md §4.6): submission **locks the record immediately** — the teacher cannot edit or unlock it themselves afterward; only Admin/Superadmin can unlock it (`PATCH /api/attendance/student/:id/unlock`). Any correction after locking goes through a separate, formal **Attendance Correction** request (`POST /api/attendance/corrections` — Teacher/HR/Staff can request; only Admin/Superadmin approve/reject), which is a real, distinct workflow and deserves its own screen/flow rather than being folded into this one.
   - **Corrected**: per doc, this is "instantly visible to the Admin and the concerned parent" — **api_spec.md §9 confirms this is NOT real-time**. It's a plain REST write; Admin and Parent see the new record only the next time their app calls the relevant GET endpoint, not via any live push (the only real-time transport anywhere in the backend is the Chat Socket.IO namespace — Flow 11 — which attendance does not use). If a parent notification fires at all for a new attendance entry, it's a separate poll/email event per Flow 12, not something triggered instantly by this save.
7. Failure (save error) → error banner, marked state preserved so the teacher doesn't have to re-mark from scratch, retry available.
- Edge case: roster is empty (no students assigned to the class yet) → Empty state per screens.md, teacher directed back to Admin for setup (out of teacher's control).
- **Resolved**: a teacher cannot edit attendance once submitted for that day/class — it locks on save, with no cutoff-window concept (it's immediate). Corrections require the formal request/approve workflow above (api_spec.md §4.6, §12 row 9).

## 5. Student — Assignment Submission
1. Student logs in → **Student Dashboard**.
2. Taps **Assignments** → **Assignments List**.
3. Opens an assignment → **Assignment Detail**.
4. Student attaches their work (`UNKNOWN` accepted formats) and taps submit.
5. Success → status updates to "Submitted," visible on both Assignment Detail and the list.
6. Failure (upload/save error) → error state with retry, composed submission not discarded.
- **Resolved** (api_spec.md §4.5): a **first** submission past the due date is **blocked** (400 response) — the student cannot submit late at all on their first attempt. **Resubmission is allowed any time before the teacher grades it** (no due-date restriction on resubmission itself); once graded (`gradedAt` set), the submission locks (409) and can no longer be edited.

## 6. Parent — Checking Attendance
1. Parent logs in → **Parent Dashboard** (selects child first if more than one — `ASSUMPTION`).
2. Taps **Attendance** → **Child's Attendance**.
3. App loads the child's attendance history/summary.
4. Parent optionally filters by month.
- This flow is read-only end-to-end per the doc — no write actions for Parent here.
- Related: Parent may arrive at this screen directly by tapping an in-app **Notification** about a new attendance entry (see Flow 12) rather than navigating manually — **not** a push notification; per Flow 12, notification delivery is in-app poll + email only, confirmed no push provider exists.

## 7. Fee Management (Admin-driven; in-app payment now **CONFIRMED real** — corrects prior out-of-scope framing)
**Admin side:**
1. Admin logs in → **Admin Dashboard** → **Fee Structure Setup**.
2. Admin defines fee items — amount, due date, optional installment plan (`isInstallment`) — per class (`POST /api/fees`, api_spec.md §4.9).
3. Payments arrive two ways: (a) an office-side payment Admin records directly, or (b) an in-app submission from the Parent/Student (see step 6 below) that lands in a review queue.
4. For in-app submissions, Admin reviews the pending queue (`GET /api/payments/fee/pending`) and **approves** (`POST /api/payments/fee/approve/:id`) or **rejects** (`POST /api/payments/fee/reject/:id`, with a rejection note) each one. Approving updates that student's paid/pending status; rejecting does not.

**Parent/Student side — CORRECTED, in-app payment IS in scope:**
5. Parent/Student logs in → Dashboard → **Fee Status/History**, views current dues and payment history.
6. To pay: Parent/Student pays externally first — via their own eSewa/Khalti app or a bank transfer, using a static payment QR code the school uploaded (`GET /schools/payment-qr`) — then **submits proof in-app**: `POST /api/payments/fee/submit` with `feeId`, optional `installmentId`, the `phoneNumber` used for the transfer, and the `transactionPin`/confirmation code their payment app displayed after paying. **This is a manual-verification flow, not an embedded payment-gateway checkout** — no card/UPI entry form renders inside the mobile app, and the backend never calls an eSewa/Khalti API itself (api_spec.md §4.9, §10, §12 row 8).
7. Submission shows as "Pending review" on Fee Status/History until Admin approves or rejects it (step 4).
8. A fee due, a payment approval, or a payment rejection may generate a notification to the parent — per Flow 12, this is an in-app-poll/email event, **not** a real-time push (api_spec.md §8–§9).
- This flow previously treated in-app payment as out of scope pending confirmation. It's now confirmed real, but as **manual phone+PIN verification reviewed by a human**, not a payment gateway integration — `implementation_backlog.md` E7-F4 (previously excluded as out-of-scope) should be un-excluded and rescoped to this shape.

## 8. Exam Schedule (Admin creates, others view)
1. Admin logs in → **Admin Dashboard** → **Create/Manage Exam Schedule**.
2. Admin fills in title, date/time, class/subject scope, description → saves.
3. Success → new entry appears in the shared **Exam/Academic Schedule List** for every role in scope (Teacher/Student/Parent see it as read-only).
4. Teacher/Student/Parent: Dashboard → **Schedule List** → **Schedule Detail** to view.
- **Partially resolved** (api_spec.md §4.8): **Confirmed** that **publishing a result** triggers a real notification (Resend email, `resultNotificationTemplate`). Whether creating/scheduling the exam itself (before any result exists) also triggers a notification was **not** specifically traced in the backend pass — still `UNKNOWN — VERIFY` for that particular moment; don't assume it fires without checking `examController`'s create-exam handler directly.

## 9. Notice Creation
1. Admin (or Superadmin, for platform-wide notices) logs in → Dashboard → **Create Notice**.
   - **CONFLICT** (api_spec.md §4.7, §12 row 6): the product doc says "Admin **or Teacher** publishes," and a Teacher "Create/Edit Notice" screen was added to `screens.md` in an earlier documentation pass — but **the real backend has no teacher-facing notice-creation endpoint at all**: `noticeSchema.js`'s `createdByModel` field only accepts `Admin`/`User`, and `noticeRoutes.js` only grants create to `protectAdmin`/`protectSuperAdmin`. Until this is resolved (either the backend adds a teacher endpoint, or the screen/flow is rolled back), a Teacher reaching "Create Notice" has nothing to call.
2. Author composes title, body, and selects audience scope — `students|teachers|parents|admins|all` (confirmed enum, api_spec.md §4.7) for Admin, or `schoolId: null` for Superadmin's platform-wide notices. **No per-class scoping field exists** — this flow previously assumed a Teacher-authored notice would scope to "own class," but that entire path has no backend support (see step 1).
   - **CONFLICT**: `noticeSchema.js` has **no attachment field at all** (api_spec.md §12 row 15) — drop "optional attachment" from this step, or treat it as blocked pending a schema change.
3. Publishes.
4. Success → appears in the **Notices List** for the audience in scope. **Confirmed** (api_spec.md §4.7): this triggers real notification fan-out — both an in-app `Notification` document and a Resend email per matching recipient in the audience.
5. Failure (publish error) → inline error, draft content preserved for retry.
- The prior open question ("can Teachers edit/delete their own notices") is moot given the finding above — Teachers have no notice-creation endpoint to have authored one from in the first place.

## 10. Online Class Joining — `BLOCKED — NO BACKEND SUPPORT`
> **api_spec.md §10/§12 row 1 confirms zero evidence of any meeting-link feature anywhere in the backend** — no route, no model field, no "meet"/"zoom"/"meeting link" match anywhere in the source tree. The steps below are kept for reference (this is what the product doc describes) but **there is currently nothing to build against**. Do not implement this flow until the backend team confirms whether it's genuinely unbuilt, planned in a different service, or should be dropped from scope — see `implementation_backlog.md` Epic E9.

1. Teacher logs in → **Share Online Class Link**, enters the meeting URL (e.g. Google Meet) and selects the class → shares.
2. Delivery mechanism to students `ASSUMPTION`: likely surfaces via the class's Dashboard card and/or a Notification, since the doc doesn't describe a dedicated "online class" list beyond "students can open their dashboard and join."
3. Student logs in → **Student Dashboard** → **Join Online Class** → taps the active link.
4. App opens the link externally (e.g. hands off to the Google Meet app/browser) — this is a link hand-off, not an embedded video call, per doc §9.
- Edge case: no link shared yet for today → Empty state ("No online classes scheduled right now").
- `ASSUMPTION`: whether Parents can also see/join (doc only mentions Students joining) — moot until the feature exists at all.

## 11. Chat — CORRECTED to match confirmed backend reality (class/section group chat, not 1:1)
1. **Teacher** logs in → **Chat — Conversation List**, sees the groups they created or belong to. **Only a Teacher can start a new conversation**: creating one (`POST /api/group-chats`) scopes it to a class + optional section and **auto-enrolls every Student in that class/section as a member** (api_spec.md §7). There is no free-form 1:1 start, and no way for a Student to initiate a group.
2. **Student** logs in → **Chat — Conversation List** shows only the groups they're already a member of via their class/section. Students can open and participate in an existing group thread but cannot create one.
3. **Parent has no chat access in any capacity — this is a confirmed backend design decision, not a UI gap.** `GroupConversation.members` only references `Student`; `GroupMessage.senderRole` is a 2-value enum (`teacher`, `student`) with no `parent` value; and the Socket.IO auth handshake explicitly rejects any account that isn't a Teacher or Student. **Do not build a Parent chat screen against this backend** — there is nothing for it to call, at either the REST or the real-time layer.
4. Opens an existing thread → **Chat Thread**. Sends a message (text and/or one media attachment — image/video/voice, api_spec.md §6) via `POST /api/group-chats/:conversationId/messages`; message appears optimistically, then confirms delivery (or shows a failed-to-send retry state).
5. **Real-time delivery — Confirmed Socket.IO.** The JWT is passed via the socket handshake's `auth` option (`socket.handshake.auth.token`), **not** a header or cookie — a different auth transport than the REST `Authorization` header used everywhere else in the app (see architecture.md §6 for the implication on `RealtimeService`'s connection setup). Confirmed socket events: `group:join`/`group:leave`, `group:typing` (broadcast to room), `group:read` → broadcasts `group:read-receipt`. New messages are emitted server-side from the REST send handler itself (`group:new-message`) — sending a message is REST, the socket only carries the live fan-out to other room members.
- **Removed**: the prior "Admin's variant... oversees the entire chat system" framing. **api_spec.md confirms no Admin oversight endpoint exists anywhere in the backend**, and an Admin account cannot even open a socket connection under the current auth code (`authenticateSocket.js` only accepts Teacher or Student accounts, rejecting everything else including Admin). If Admin visibility into chat is still a real product requirement, it needs to be built from scratch — there is no partial version of it to document here.

## 12. Notifications
1. A triggering event happens elsewhere in the system. **Confirmed trigger list** (api_spec.md §8, from the `Notification` schema's `type` enum plus the controllers observed calling `notificationService.notify(...)`): fee due/overdue, attendance, attendance-correction decision, assignment, general, subscription, payroll — plus notice publication and exam-result publication, which trigger real emails but **have no dedicated `type` value of their own in the schema** (a minor internal inconsistency — don't assume the mobile client can branch cleanly on `type` for every event category).
2. The affected user(s) — determined by role/scope (e.g. attendance → that student's parent; salary → that teacher) — receive a notification.
3. **Delivery channel — Confirmed, resolves the prior `ASSUMPTION`** (api_spec.md §8): (a) in-app, via `GET /api/notifications` — the client must **poll/pull**, nothing is pushed to it — and (b) email via Resend, for the specific events listed above. **No push notification provider is integrated anywhere in the backend** (zero FCM/APNs/OneSignal/Expo evidence found), and **there is no real-time delivery for notifications** — the only real-time channel in the whole backend is the Chat Socket.IO namespace (Flow 11), which notifications do not use. Plan the mobile client around poll-based refresh (app foreground, pull-to-refresh, or a timer) rather than a live push.
4. User taps a notification → deep-links to the relevant screen (e.g. a fee notification opens **Fee Status/History**).
5. Notification marked read on open (`ASSUMPTION` still open — `PATCH /api/notifications/:id/read` and `/read-all` exist and are callable, but whether the client should call them automatically on open vs. only on an explicit user action wasn't specified); unread count badge updates on Dashboard/nav.
- **Also confirmed** (api_spec.md §8): several scheduled/automatic jobs that would generate some of these notifications (fee-due reminders, subscription-expiry checks, payroll reminders) are wired in the backend but **commented out / disabled as committed**. As shipped, notifications only fire synchronously from direct user actions (e.g. an Admin publishing a notice), never on a recurring schedule.
