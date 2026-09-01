# Local Backend — Setup Record

> Written 2026-08-23. Records what was actually done to stand up the backend locally, per `production_roadmap.md` §2 — read that file for the *why* and the general steps; this file is the concrete record of *what exists right now* (location, credentials, how to restart).

## Location & install

- Cloned into `/Users/sabinkc/Desktop/ClaudeMS/cloud_lms_backend` (sibling to `cloud_lms`, not inside it — matches the roadmap's recommendation).
- `npm install` run there. Node v22.17.1 / npm 11.4.2 confirmed working (7 pre-existing vulnerabilities reported by `npm audit`, all in the backend's own deps — not investigated, not this project's code).
- MongoDB installed via Homebrew (no Docker available on this machine): `brew tap mongodb/brew && brew install mongodb-community`, running as a `brew services` daemon (survives terminal close, not necessarily machine reboot — check `brew services list` after a reboot).

## `.env`

Lives at `cloud_lms_backend/.env` (gitignored, confirmed). All variables from `production_roadmap.md` §2 step 4 are set except:
- `CLOUDINARY_CLOUD_NAME` / `CLOUDINARY_API_KEY` / `CLOUDINARY_API_SECRET` — empty. **File uploads will fail** until a real free-tier Cloudinary account is created and these are filled in.
- `RESEND_API_KEY` / `EMAIL_USER` — empty. **No email actually sends** (OTP, welcome-credentials emails, notice/notification emails) — this backend degrades gracefully when email fails (logs the error, doesn't block the request), which is why account creation below worked without it. This is *why* every seeded account below was created with a manually-chosen password via the admin-facing `password` field rather than relying on the auto-generated-and-emailed one.
- `ESEWA_*` — dummy placeholder values (display-only per `api_spec.md` §10, not a live gateway call).

## Running / stopping

- **MongoDB**: `brew services start mongodb/brew/mongodb-community` (already running as a service — persists across terminal sessions).
- **Backend server**: not a service — was started manually with `cd cloud_lms_backend && node server.js` in the background. If the machine restarts or the process dies, restart it the same way (or `npm run dev` for nodemon auto-reload during active backend work). Health check: `curl http://localhost:4000/health` → `{"status":"OK",...}`.
- **Flutter app**: `flutter run -t lib/main_dev.dart --dart-define=BASE_URL=http://localhost:4000` (simulator/desktop). On a physical device or Android emulator, `localhost` won't resolve to this machine — use the LAN IP or `10.0.2.2` (Android emulator only).

## Seed data (created via the real onboarding flow, not fixtures)

Walked `user_flows.md` Flow 3 for real, through the actual API — SuperAdmin → School+Admin → Class/Section → Teacher/Student/Parent, confirming each account can actually log in (`POST /api/auth/login`) before calling this step done.

| Role | Email | Password | Notes |
|---|---|---|---|
| superadmin | `super@school.com` | `super123` | seeded by `seedSuperAdmin.js`, matches its hardcoded values |
| admin | `admin@greenwood-demo.test` | `Admin@123` | school: **Greenwood Demo School**, `schoolId` `6a8af7862ab6815963c01bd4`, on the **premium** plan (no seat limits — chosen deliberately so plan-limit gating doesn't get in the way of further seeding), subscription active for 12 months |
| teacher | `jane.teacher@greenwood-demo.test` | `Teacher@123` | `employeeId` `EMP001`, department Science, subjects Physics/Math |
| student | `sam.student@greenwood-demo.test` | `Student@123` | `admissionNumber` `ADM001`, Class 10 / Section A |
| parent | `pat.parent@greenwood-demo.test` | `Parent@123` | linked to Sam Student (both directions: `Parent.students[]` and `Student.parentId` both set, confirmed in the creation response) |

Class **"Class 10"** and Section **"A"** exist under Greenwood Demo School — this is the roster every feature phase in `production_roadmap.md` §3 should build and test against, per that doc's step 7 instruction.

Plans were seeded via `POST /api/subscriptions/seed-plans` (public, dev-only endpoint, confirmed unauthenticated in `api_spec.md` §3) — `basic`/`standard`/`premium`/`demo` all exist in the `Plan` collection now.

## What this confirms/extends beyond `api_spec.md`

Classes/Sections were flagged in `production_roadmap.md` Phase B as "not deep-dived yet." Now confirmed by reading `classRoutes.js`/`sectionRoutes.js`/`Classcontroller.js`/`Sectioncontroller.js` directly:
- `POST /api/classes` (`protectAdmin`) — body `{ name*, description }`, unique per school.
- `POST /api/classes/:classId/sections` (`protectAdmin`) — body `{ name* }`, unique per class+school. (Section CRUD/assignment beyond creation lives at `/api/sections/:id`, a separate router.)
- `GET /api/classes/:classId/sections` — list.

Also confirmed empirically: `POST /api/schools/manual-create` (`protectSuperAdmin`) is the most direct path to stand up a new tenant for seeding/testing — creates School + active Subscription + first Admin in one transactional-ish call (rolls back School/Subscription if Admin creation fails), given `{ name, address, phone, email, planId, months, adminFullName, adminEmail, adminPassword, adminPhone }`. This is a more controllable alternative to `POST /api/subscriptions/demo` (the real product-facing "7-day free demo" flow) for local dev seeding specifically *because* it takes the admin password directly in the body instead of only emailing it — useful to know for any future reseed.
