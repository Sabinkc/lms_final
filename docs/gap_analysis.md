# CloudsLMS — Gap Analysis

> Status: DRAFT v0.1 — cross-reference of the seven `docs/` artifacts (`product_requirements.md`, `feature_matrix.md`, `screens.md`, `user_flows.md`, `design_system.md`, `architecture.md`) plus `api_spec.md`, against each other and against the two original sources they were built from: `CloudsLMS_Documentation.docx` and the live site (https://www.cloudslms.com, read-only CSS/JS inspection only — no rendered-screen or browser-automation access was available in the session that produced these docs, and none was re-attempted for this pass). **No new facts are introduced here.** This document only surfaces gaps, conflicts, and assumptions that already exist latently across the doc set, and fixes a small number of self-referential inconsistencies using facts the docs already state elsewhere. Everything else is flagged for verification against the backend/GitHub repo, per the open questions already logged in `product_requirements.md` §7.

## 0. Method
Each of the seven documents was read in full and checked against the other six for: features present in one doc but absent from downstream docs that should reflect it (feature_matrix → screens → user_flows → architecture); screens referenced by name but never defined; CRUD permissions that disagree between `feature_matrix.md` and the screen/flow that implements them; and every `ASSUMPTION` / `UNKNOWN` / `DISCREPANCY` marker already in the docs, regrouped by theme so they can be resolved in one backend-review pass instead of six.

## 0.1 Superseded by backend verification (added after this document was written)
This entire document was produced **before** the backend repository was available — everything in it is inference from product documentation and live-site CSS/JS scanning, exactly as the doc-only limitations described throughout make clear. `docs/api_spec.md` has since been rewritten from a **read-only clone of the actual backend source** (`https://github.com/ArbindDas/SujalbackendForStudentmanagement`), and is now the authoritative source for anything it addresses. Specifically:
- **§6 (Information That Cannot Be Verified From the Live Website)** is superseded for every item `api_spec.md` resolved — auth mechanism, endpoint contracts, real-time protocol, file-upload mechanism, and most business logic are now `CONFIRMED`, not structurally unverifiable. What remains genuinely unverifiable (production URL, some pagination details, a few code paths not traced) is listed in `api_spec.md` §11, not here.
- **§7 (Features That Require Backend Information)** is superseded the same way — items 1–4 and 6 there are now answered in `api_spec.md` §1–§9; item 5 (Transport/Leave/ID Card/Library/Certificate scope) is partially answered (Leave and ID Card confirmed real, Certificate likely covered by a generic Document model, Transport and Library still unconfirmed) — see `product_requirements.md` §4.2.
- **`api_spec.md` §12 (Conflicts With Product Documentation) is now the authoritative conflicts list**, and is substantially larger than anything doc-only analysis could have found — it includes conflicts (the real 8-actor role model, the real group-chat architecture, Online Classes not existing anywhere in the backend, the real notice-creation rights, real in-app fee payment) that simply weren't discoverable without the backend source.
- This document's own §4 (Conflicting Requirements) predates that pass — see the addendum at the end of §4 below for which of its conflicts got resolved and how.

The rest of this document remains an accurate historical record of **what was knowable before backend access** and is left unchanged for that reason — it is not wrong, it is superseded where noted.

---

## 1. Missing Features

| Feature | Where it appears | Where it's missing | Notes |
|---|---|---|---|
| **Transport, Leave, ID Card, Library, Certificate** | `product_requirements.md` §4.2 (found in live-site JS bundle, not in the product doc) | `feature_matrix.md`, `screens.md`, `user_flows.md`, `architecture.md` (no feature folder), `api_spec.md` §3.13 (explicitly excluded) | Deliberately excluded pending confirmation these are real, mobile-in-scope modules — correct call, not a defect, but it means **the entire back half of the live-site bundle's feature surface is currently undocumented for mobile**. This is the single highest-leverage item to resolve in the backend review, since it could add up to 5 more feature areas. |
| **Notification preferences / mute settings** | Not mentioned in any doc | All | Products with automatic, high-frequency notifications (attendance, fees, salary, notices — `product_requirements.md` §4.1 item 11) commonly expose per-category opt-out. Not confirmed present or absent — flagged as unverifiable, not assumed missing. |
| **In-app fee payment (gateway)** | `user_flows.md` Flow 7 explicitly treats this as **out of scope** | Consistent everywhere else (feature_matrix, screens only show "view" actions for Parent/Student) | Correctly excluded, listed here only so it isn't silently re-added later without a source. |
| **Report export/print** | `screens.md` "Reports Dashboard" flags export as `UNKNOWN` | `feature_matrix.md` has no Reports column for this capability; `api_spec.md` §3.12 doesn't list an export operation | Minor — worth a single line item once the backend is reviewed. |
| **Profile photo / avatar upload** | `design_system.md` §5 assumes "avatar circles for users" as a component convention | Not a feature in `product_requirements.md`, `feature_matrix.md`, or `screens.md` (Profile screen only says "edit editable fields") | The design system is assuming a feature (photo upload) that no other document confirms exists. Flagged, not removed — `design_system.md` already marks it `ASSUMPTION`. |

---

## 2. Missing Screens

1. **Teacher — Create/Edit Notice.** `screens.md` §C ("Create Notice") says *"Teacher has a scoped variant, see §D"* — but §D (Teacher) has no such screen. `feature_matrix.md` confirms Teacher has `C R` (and `ASSUMPTION` on `U/D`) on Notices, scoped to their own class, and `product_requirements.md` §4.1 item 5 confirms "Admin **or Teacher** publishes." The screen was referenced but never written. **Fixed in this pass** — see §14 below.
2. **Admin — Notice Edit/Delete affordance.** `feature_matrix.md` grants Admin full `C R U D` on Notices, but neither "Create Notice" nor the shared "Notices List / Notice Detail" screen in `screens.md` lists an edit or delete action anywhere — only compose-and-publish and read. **Fixed in this pass** — see §14.
3. **Admin — Chat oversight screen.** `feature_matrix.md` gives Admin `R (oversight)` on Chat ("Admin oversees the entire chat system"), and `user_flows.md` Flow 11 explicitly calls this out as a distinct variant — but no such screen exists anywhere in `screens.md` §C. Not added here because it's genuinely unknown whether this is a real UI surface or backend-only visibility (`user_flows.md` line 102 already says so) — adding a full screen spec would be inventing UI that may not exist. Flagged for backend confirmation. `RESOLVED — CONFIRMED ABSENT`: `api_spec.md` §7/§12 row 2 confirms there is **no Admin oversight endpoint of any kind** for chat — the original caution not to invent this screen was correct; it should now be permanently dropped rather than merely deferred.
4. **Admin — Assignments oversight screen.** Same pattern: `feature_matrix.md` gives Admin `R (oversight) ASSUMPTION` on Assignments; no corresponding screen in `screens.md` §C. Same disposition as #3 — flag, don't invent.
5. **Admin — Online Class Links oversight screen.** Same pattern again (`feature_matrix.md`: Admin `R (oversight) ASSUMPTION`); no screen in §C. Same disposition.
6. **Push notification permission / opt-in screen.** Push is treated as core (`product_requirements.md` §6, `user_flows.md` Flow 12), but no screen in `screens.md` covers the OS-level permission request (iOS/Android) or an in-app notification-settings screen. Not added — genuinely unconfirmed whether the product distinguishes push categories at all (see §1).
7. **Standalone Change Password screen.** `screens.md` "Profile / Account Settings" mentions this only as "sub-screen or dialog," never resolved to one or the other. Low-severity structural ambiguity, left as-is since it's a Flutter implementation choice per the doc's own framing, not a documentation gap.

---

## 3. Missing User Flows

- **Admin CRUD on Teachers/Students/Parents** — covered only at a high level inside Flow 3 (Admin Setup, steps 6–7); no dedicated add/edit/delete/deactivate flow with success/failure states exists the way Flow 4 (Mark Attendance) or Flow 5 (Assignment Submission) do for other roles. Same screens exist (`screens.md` §C) but their step-by-step flow isn't spelled out.
- **Teacher Salary Management (Admin recording/processing a payment)** — has a screen (`screens.md` §C) and a feature_matrix row, but the only user_flows mention is a passing reference in Flow 12 (as a notification trigger). No flow describes the actual "Admin processes a salary payment" sequence.
- **Reports Dashboard usage** — screen exists, no flow.
- **Notice edit/delete** (once #2 above is resolved) — no flow currently, consistent with the screen gap.
- **Admin oversight of Chat/Assignments/Online Classes** — no flow, consistent with the screen gaps in §2 items 3–5.

---

## 4. Conflicting Requirements

| Conflict | Doc A says | Doc B says | Disposition |
|---|---|---|---|
| **Teacher delete rights on Assignments** | `feature_matrix.md`: Teacher has `C R U` only (no `D`) on Assignments | `screens.md` §D "Assignments List / Create-Edit Assignment": *"User actions: Create, edit, **delete** an assignment"* | Genuine disagreement, not resolved here (resolving it would mean guessing which is right). Flagged inline in both docs — see §14. Verify against backend permission model. |
| **Admin CRUD on Notices vs. available actions** | `feature_matrix.md`: Admin has `C R U D` | `screens.md`: "Create Notice" and "Notices List / Notice Detail" only expose create + read, no edit/delete action | Not a true contradiction (nothing says Admin *can't* edit/delete) but an omission that reads as inconsistent. Fixed in this pass — see §14. |
| **State management library** | An earlier session preference (per `architecture.md` line 3) specified **Riverpod** | `architecture.md` §3 uses **Provider** throughout, and explicitly notes: *"this supersedes the Riverpod preference stated earlier in this session"* | Self-flagged and resolved by `architecture.md` itself — listed here for visibility only. If the Riverpod preference was a hard requirement rather than a discussion-stage note, confirm before Phase 2 of `implementation_plan.md` starts. |
| **Design system navigation IA count** | `design_system.md` §5: *"bottom navigation bar for the **four** primary sections per role"* | Same line then lists **five** items: "Dashboard, [core module], Notices/Schedule, Chat, Profile" | Internal inconsistency within a single document (not cross-doc). Worth a one-line fix once the real per-role IA is confirmed — not fixed here since the correct item count isn't knowable from source material. |
| **"Attendance correction" capability vs. its screen** | `feature_matrix.md`: Admin gets `ASSUMPTION: U D for corrections` on Attendance | `screens.md` "Attendance Overview (school-wide)": user actions are only *"Filter by class/date, drill into a class"* — no correction/edit action listed | Same pattern as the Notices gap — a permission asserted in the matrix with no corresponding screen affordance. Flagged for backend confirmation; not fixed by inventing an edit UI, since it's unclear this correction capability is real. |
| **Reports folder in architecture** | `screens.md` §C includes a full "Reports Dashboard" screen | `architecture.md` §2's `features/` folder listing has no `reports/` folder (only `admin_management/` is listed for Admin-only screens) | Likely just folded into `admin_management/` implicitly, but not stated. Low-severity, noted for whoever scaffolds Phase 4/10 of `implementation_plan.md`. |

### §4 addendum — resolved against `api_spec.md` (added after backend verification)

Of the conflicts logged above, three now have a backend-confirmed answer:

- **Teacher delete rights on Assignments** — `PARTIALLY RESOLVED`. `api_spec.md` §12 row 7: `DELETE /api/assignments/:id` is a real route, gated only by `protect` (any authenticated user) with **no role check visible at the routing layer** — so a Teacher can at least reach the endpoint, leaning toward `screens.md`'s "delete" action being legitimate rather than `feature_matrix.md`'s stricter `C R U`-only reading. Not fully closed: the controller itself may still apply a role check that wasn't traced in that pass — genuinely `UNKNOWN — VERIFY` at the controller level, not just an unresolved doc disagreement anymore.
- **Admin CRUD on Notices vs. available actions** — `RESOLVED`. `api_spec.md` §4.7 confirms Admin has real `PUT /:id` and `DELETE /:id` notice endpoints server-side — the affordance this document flagged as merely asserted-but-unbuilt is a legitimate gap in `screens.md`, not a documentation error; the edit/delete UI should now be built. **However, a new, more severe conflict surfaced in the same pass**: `noticeSchema.js`'s `createdByModel` enum is `Admin, User` only — **Teacher has no notice-creation endpoint on the backend at all**, directly contradicting `product_requirements.md` §4.1 item 5 and the Teacher "Create/Edit Notice" screen this document itself added to `screens.md` §D in §14 below. See `api_spec.md` §12 row 6 — this needs a product decision (add the backend endpoint, or drop the mobile screen), not a doc fix.
- **"Attendance correction" capability vs. its screen** — `RESOLVED`. `api_spec.md` §5 (`AttendanceCorrection` model) and §12 row 9 confirm this is real and fully built, as a dedicated request/approve/reject workflow — not a direct edit on the attendance record, which is exactly the shape `feature_matrix.md`'s `ASSUMPTION` couldn't determine. This document previously recommended *not* building a correction UI until confirmed real; that condition is now met, and the correction request/review flow should be added to `screens.md`/`user_flows.md`.

For every other conflict — the real 8-actor role model, the real class/section group-chat architecture (not 1:1), Online Classes not existing anywhere in the backend, confirmed-absent push notifications, and real in-app fee payment (previously excluded as out of scope) — this document predates the backend clone and could not have found them. **`api_spec.md` §12 is the authoritative list**; treat it as the source of truth over this section going forward.

---

## 5. Assumption Inventory (grouped, not exhaustive line-by-line — see source docs for full markers)

- **Auth & session**: credential scheme, multi-tenant login mechanism, password-reset flow/existence, account lockout policy, token refresh, 401 response shape — all `UNKNOWN`, see `product_requirements.md` §2, §7; `api_spec.md` §2; `screens.md` "Forgot Password Screen."
- **Account provisioning**: whether Teacher/Student/Parent credentials are emailed automatically on creation (like Admin's are) or relayed manually by Admin — `user_flows.md` Flow 3.
- **Chat scope**: whether conversations are strictly scoped to Teacher↔Student/Teacher↔Parent-about-a-student, or free-form — `product_requirements.md` §4.1 item 10; `user_flows.md` Flow 11; `screens.md` "Chat — Conversation List."
- **Grading model**: whether assignment "checking" is a binary checked flag or a scored grade — `screens.md` "Assignment Submissions Review."
- **Late submissions**: blocked vs. flagged-late after due date; whether a student can resubmit before teacher review — `user_flows.md` Flow 5.
- **Notification triggers/channel**: full trigger list is stated (`product_requirements.md` §4.1 item 11) but delivery channel (push vs. in-app-only vs. both), provider (FCM assumed), and read-on-open semantics are `ASSUMPTION` — `user_flows.md` Flow 12.
- **Multi-child Parent UX**: child-switcher pattern assumed, not confirmed — `screens.md` "Parent Dashboard"; `user_flows.md` Flow 6.
- **Visual design**: colors' semantic role-mapping, typography scale, spacing scale, component styles (cards/buttons/fields), icon set, imagery — all `ASSUMPTION — verify visually` per `design_system.md` §1–5, since only compiled CSS/JS was inspected, not rendered UI.
- **Offline tolerance**: treated as a nice-to-have, not a requirement — `product_requirements.md` §6; `architecture.md` §7.

---

## 6. Information That Cannot Be Verified From the Live Website

The live site is a client-rendered React SPA; the only verification method available when these docs were produced was reading the compiled CSS/JS bundle via `curl` — no rendered screenshots, no browser automation, no authenticated session (the product requires a subscription/demo account to see anything past the marketing pages). As a result, the following categories are **structurally unverifiable from the website alone**, regardless of how much more bundle-scanning is done, and require either backend/repo access or authenticated screenshots:

- Any authenticated screen's actual layout, component styling, or content (Dashboards, forms, lists) — the bundle scan only recovered design *tokens* (colors, radii), not rendered composition.
- Business logic: validation rules, permission enforcement, notification trigger conditions, grading semantics, attendance correction rules.
- API contracts of any kind (paths, payloads, auth headers, error formats) — `api_spec.md` is 100% `UNKNOWN — VERIFY FROM BACKEND` for this reason.
- Whether the Transport/Leave/ID Card/Library/Certificate bundle terms (§1 above) correspond to real, shipped, mobile-relevant features or are dead/unused code paths, admin-web-only, or in development.
- Onboarding/demo-account behavior beyond what the product doc's prose describes (the 7-day demo flow itself was never observed live).

---

## 7. Features That Require Backend Information

Effectively the entire product beyond static screen layout. Concretely, nothing in Phase 2+ of `implementation_plan.md` can be built against real data until these are confirmed (per `api_spec.md` §6 prioritization):
1. Auth mechanism + multi-tenant identification (blocks everything).
2. Response/error envelope conventions (blocks every repository implementation).
3. Per-module endpoint paths and payload shapes (all 13 categories in `api_spec.md` §3).
4. Real-time protocol for Chat/Notifications (`api_spec.md` §5).
5. Whether Transport/Leave/ID Card/Library/Certificate are in mobile scope.
6. Pagination, file-upload mechanism, date/timezone handling (`api_spec.md` §4).

## 8. Features That Require Authentication

All screens except **Splash**, **Login**, and **Forgot Password** (`screens.md` §A) require an authenticated, role-resolved session. This includes every Dashboard and every module screen in §B–F. The route guard described in `architecture.md` §4 is the mechanism; it depends entirely on item 7.1 above (auth mechanism) being resolved first.

## 9. Features That May Require Real-Time Communication

- **Chat** (Conversation List + Thread) — `product_requirements.md` §5 confirms a "real-time messaging system"; mechanism `UNKNOWN` (Socket.io candidate, unconfirmed) per `api_spec.md` §5 and `architecture.md` §6.
- **Notifications** — live delivery for attendance/assignment/exam/fee/salary/notice events (`user_flows.md` Flow 12); may ride the same real-time channel as Chat or be push-only.
- **Attendance "instantly visible"** — `product_requirements.md` §4.1 item 3 and `user_flows.md` Flow 4 describe attendance as "instantly visible to Admin + concerned parent" once saved, which implies either a live push to those viewers or just fast polling on next screen load — mechanism unconfirmed.

## 10. Features That May Require Push Notifications

All items in `product_requirements.md` §4.1 item 11's trigger list: attendance updates, new assignments, new exam/academic schedules, fee payments/dues, salary updates, notices/announcements (`user_flows.md` Flow 12). Provider assumed to be FCM for a Flutter app but explicitly unconfirmed (`product_requirements.md` §7 item 6; `architecture.md` §9 defers this wiring entirely pending confirmation).

## 11. Features That May Require File Uploads

- **Assignment submission** (Student attaching work) — `screens.md` §E; accepted formats `UNKNOWN`.
- **Assignment creation attachment** (Teacher) — `screens.md` §D.
- **Notice attachment** (Admin/Teacher) — `screens.md` §B/§C.
- **Chat file attachment** — explicitly `UNKNOWN`, not mentioned in the source doc at all (`screens.md` "Chat Thread").
- **Profile photo** — assumed by `design_system.md` only, not confirmed elsewhere (see §1 above).
- Upload mechanism itself (multipart vs. upload-then-reference) is `UNKNOWN` — `api_spec.md` §4.

## 12. Features That May Require External Services

- **Google Meet (or similar)** — Online Class links are shared/external, not an embedded SDK (`product_requirements.md` §4.1 item 9; `user_flows.md` Flow 10) — a link hand-off to an external app/browser, not a service integration the app owns.
- **Push notification provider** — FCM assumed, unconfirmed (§10 above).
- **Real-time transport provider** — Socket.io assumed, unconfirmed (§9 above).
- **Transactional email** — Admin ID/password delivery "by email" after subscribing (`product_requirements.md` §2 step 5) implies an email service on the backend; not a mobile-app concern directly, but relevant if the app ever triggers "resend credentials" or password-reset emails.
- **Payment gateway** — explicitly *not* confirmed as in-app (`user_flows.md` Flow 7) — listed here only to flag that if in-app payment is ever confirmed in scope, it would need a gateway integration (Stripe/eSewa/Khalti-class service, common in Nepal-market products) not currently planned for anywhere in `architecture.md`.

---

## 13. Cross-Document Consistency Check (what's actually solid)

To balance the gap list above: the following are **consistent across all seven documents** and don't need further reconciliation:
- Exactly 4 roles (Admin/Teacher/Student/Parent), consistently named and scoped, across `product_requirements.md`, `feature_matrix.md`, `screens.md`, `user_flows.md`, `architecture.md`.
- The 9 core confirmed modules (`product_requirements.md` §4.1) each have a matching feature_matrix row, screen(s), and (mostly) a user flow.
- MERN stack assumption (Node/Express/MongoDB) is stated once in `product_requirements.md` §5 and correctly propagated into `architecture.md` (string IDs, dio/http client) and `api_spec.md` (REST + ObjectId expectation) without drift.
- Light/dark theme support is consistently referenced in `product_requirements.md` §6, `design_system.md` §1, and implied in `screens.md` "Profile / Account Settings."
- The Admin-setup dependency chain (classes → teachers/students/parents → fees, before other roles have usable data) is consistent between `user_flows.md` Flow 3 and `implementation_plan.md`'s Phase 4 sequencing rationale.

---

## 14. Documentation Updates Made In This Pass

1. **`screens.md` §D (Teacher)** — added a "Create/Edit Notice (own class)" screen entry, resolving the broken "see §D" reference in §C's "Create Notice" entry. Built entirely from facts already stated in `feature_matrix.md` (Teacher: `C R`, `ASSUMPTION` on `U/D`, own-class scope) and `product_requirements.md` §4.1 item 5 — no new information introduced.
2. **`screens.md` §B ("Notices List / Notice Detail")** — added a flagged note that Admin/Teacher edit/delete of an existing notice is asserted by `feature_matrix.md`'s CRUD columns but has no corresponding screen action yet; marked `ASSUMPTION`, not built out, pending confirmation this is a real requirement.
3. **`screens.md` §D ("Assignments List / Create-Edit Assignment")** — annotated the "delete an assignment" action as conflicting with `feature_matrix.md`'s `C R U`-only grant for Teacher on Assignments; flagged for backend verification rather than silently resolved either way.
4. **`feature_matrix.md`** — added a note under "Notes" cross-referencing this document for the two conflicts above (Assignment delete, Notice edit/delete affordance), so anyone reading the matrix in isolation knows to check here.

No other documents were altered — every other item in this analysis is a flag for the backend-verification pass already scheduled in `implementation_plan.md` Phase 1, not something resolvable from existing material.
