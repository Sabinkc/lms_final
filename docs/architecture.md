# CloudsLMS Flutter — Proposed Architecture

> Status: DRAFT v0.2 — structural proposal only, still no code written. Built around the confirmed **MERN backend** (Node.js + Express + MongoDB, product_requirements.md §5), using **Provider** for state management, Repository pattern, an HTTP client layer, local storage, feature-based organization, role-based navigation, dependency injection, and error handling, as specified. Note this supersedes the Riverpod preference stated earlier in this session — flag if you'd rather revisit that. **Cross-checked against `docs/api_spec.md`'s backend-verified findings** (source: read-only analysis of the real backend repository) — several previously-open architectural questions (auth transport, refresh-token existence, real-time mechanism, response-envelope shape) are now answered and called out inline as **Confirmed**; nothing below is invented beyond what `api_spec.md` states.

## 1. Layering overview
```
Presentation (Widgets + Provider/ChangeNotifier)
        ↓ calls
Domain (feature services / use-case-style methods, optional thin layer)
        ↓ calls
Data (Repository interfaces → Http implementation | Mock implementation)
        ↓ calls
Core (HTTP client, local storage, DI, error/result types)
```
Each feature only depends on its own Repository interface, never directly on `dio`/`http` — this is what lets today's UI be built against mock data and swapped to real endpoints tomorrow without touching presentation code (see implementation_plan.md).

## 2. Feature-based folder organization
```
lib/
  main.dart                     # DI setup, MultiProvider, MaterialApp + role-based router
  core/
    network/
      api_client.dart           # http/dio wrapper: base URL, auth header injection, timeout, error mapping
      api_exception.dart        # typed exceptions (NetworkException, UnauthorizedException, ServerException, ...)
    storage/
      secure_storage_service.dart   # token, refresh token if any
      local_prefs_service.dart      # theme, non-sensitive cached prefs
    theme/
      app_theme.dart            # ThemeData light/dark, from design_system.md tokens
    router/
      app_router.dart           # route table + role-based guard/redirect logic
    di/
      service_locator.dart      # composition root: wires repositories + providers (see §5)
    result.dart                 # Result<T>/Either-style wrapper for uniform success/failure handling
  features/
    auth/
      data/
        auth_repository.dart          # abstract
        auth_repository_http.dart     # real impl (added once API is known)
        auth_repository_mock.dart     # today's impl
        models/user.dart, models/role.dart
      presentation/
        login_screen.dart, splash_screen.dart, forgot_password_screen.dart
      auth_provider.dart              # ChangeNotifier: session state, current user/role
    attendance/
      data/ (repository + mock, models: AttendanceRecord)
      presentation/ (mark_attendance_screen.dart, attendance_history_screen.dart, ...)
      attendance_provider.dart
    assignments/ ...
    exams_schedule/ ...
    fees/ ...
    payroll/ ...
    notices/ ...
    chat/ ...
    notifications/ ...
    online_classes/ ...
    admin_management/            # teachers/students/parents/classes CRUD — Admin-only feature group
    profile/
  shared/
    widgets/                     # reusable loading/empty/error widgets (see below), buttons, cards
    utils/
```
This mirrors `screens.md`'s module grouping 1:1 — one `features/<module>/` folder per module in `product_requirements.md` §4.1, so tomorrow's API integration work is scoped per-folder.

## 3. State management — Provider
- One `ChangeNotifier` per feature (e.g. `AttendanceProvider`, `AssignmentsProvider`), holding that feature's UI-relevant state (loading/data/error) and calling its Repository.
- `AuthProvider` is special: holds the current session/role and is read by the router for role-based guarding (§4) and by other providers that need the current user's ID/role for scoping requests.
- Providers exposed via `MultiProvider` in `main.dart`, constructed through the service locator (§5) so they receive their Repository dependency already wired.
- Screens consume state via `context.watch<XProvider>()` / `context.read<XProvider>()`, following standard Provider conventions — no additional state library layered on top.

## 4. Role-based navigation
- Single `MaterialApp` with a central route table (`app_router.dart`), not four separate app shells.
- After login, `AuthProvider` holds the resolved role (Admin/Teacher/Student/Parent per product_requirements.md §3).
- A route guard checks the current role against each route's allowed-roles list before allowing navigation — mirrors the CRUD/visibility boundaries in `feature_matrix.md` (e.g. `admin_management` routes are Admin-only, `mark_attendance` is Teacher-only).
- Each role's Dashboard screen (`screens.md` §C–F) is the guard's default landing route for that role, decided at login/session-restore time.
- Bottom navigation structure per role is a still-open design question — flagged as `ASSUMPTION` in `screens.md` §5, to firm up alongside the real screen count once the backend/API doc is in.

## 5. Dependency injection
- Recommend a lightweight composition root (`service_locator.dart`) rather than a full DI framework — construct repositories and providers explicitly in one place (or via `get_it` if the team prefers a registry, still a `Provider`-compatible approach).
- Today: `service_locator.dart` wires every feature's **mock** repository. Tomorrow: swap in the **http** repository implementation per feature as its endpoints are confirmed — this is the single point of change, no presentation-layer edits needed.
- `ApiClient` (the shared `dio`/`http` wrapper) is itself injected into each `*_repository_http.dart`, not instantiated ad hoc, so auth-header injection and error mapping stay centralized.

## 6. HTTP client & data layer
- One shared `ApiClient` wrapping `dio` (preferred over raw `http` for interceptors — auth header injection, logging, timeout, unified error mapping) — package choice `ASSUMPTION`, either is fine given no constraint from the backend.
- Base URL and any environment config (staging vs. prod) via `--dart-define`, not hardcoded — placeholder value only until the API is confirmed.
- **Auth-header injection — Confirmed** (api_spec.md §2): `Authorization: Bearer <token>`, not a cookie. `ApiClient` should also implement the confirmed `?token=` query-param fallback the backend supports for download-style GET requests that can't set headers (ID cards, some file/document links, via the backend's `tokenFromQuery` middleware) — build this in from the start as a real, used pattern, not a hypothetical one.
- Given the confirmed MongoDB backend, expect **string IDs** (ObjectId-style) throughout data models, not integers — worth encoding as a `String id` convention across all feature models now so tomorrow's real models don't require an ID-type refactor.
- **Real-time — Confirmed Socket.IO** (`socket_io_client` is the right package choice, api_spec.md §7/§9), needing its own client separate from the REST `ApiClient`. Two things this changes from the original plan: (1) the JWT is passed via the socket handshake's `auth` option (`socket.handshake.auth.token`), not a header — `RealtimeService`'s connection setup needs to attach the token there specifically, not reuse `ApiClient`'s header-injection interceptor; (2) **real-time is scoped to Chat only** — there is no real-time channel for Notifications or any other module (confirmed by a full-repo grep for Socket.IO usage outside the chat socket handlers). Don't design `RealtimeService` to carry notification events; Notifications stays a plain polled REST resource (see §9).

## 7. Local storage
- **Secure storage** (`flutter_secure_storage`) for **both** the access token and the refresh token — **Confirmed a refresh token exists** (api_spec.md §2): a separate 30-day JWT, returned alongside the 60-minute access token in the login/refresh JSON response body (`{ token, refreshToken, ... }`). Store both; the prior "if any" hedge on the refresh token is resolved.
- **Token refresh is a real, callable endpoint** — `POST /api/auth/refresh` (body: `{ refreshToken }`), returning a fresh token pair. This can be implemented for real now (e.g. on a 401 with a still-valid refresh token, or proactively before the 60-minute access token expires), not just scaffolded as a placeholder.
- **Non-sensitive local prefs** (`shared_preferences`) for theme mode and any lightweight cached UI state (e.g. last-selected child for a multi-child Parent account, per user_flows.md Flow 6).
- No offline data cache/database (e.g. `drift`/`hive`) proposed for v1 — product_requirements.md marks offline tolerance as a nice-to-have, not a confirmed requirement; revisit if the product doc/backend says otherwise.

## 8. Error handling
- `ApiClient` maps all failures to a small typed set of exceptions (`NetworkException`, `UnauthorizedException`, `ValidationException`, `ServerException`, `UnknownException`) rather than letting raw `DioException`/`SocketException` leak into feature code.
- **Correction, not just a resolved assumption** (api_spec.md §2): the backend's response/error envelope is **not uniform across endpoints**. Most return `{ success, message, data }`, but a large minority return a bare `{ message }` with no `success` field, and at least one debug endpoint returns `{ error }` instead of `message`. `api_exception.dart`'s mapping logic — when it's actually written, not now — needs to check defensively for `data`/`message` presence rather than assuming one envelope shape holds everywhere; branching only on `success` will misclassify the endpoints that omit it.
- **Also confirmed**: the 401 error shape differs by which middleware rejected the request. `authMiddleware.protect` returns `{ message, code }` where `code` is `NO_TOKEN`/`TOKEN_EXPIRED`/`TOKEN_INVALID`; `adminAuthMiddleware.protectAdmin` returns only `{ message }`, with **no `code` field at all**. The silent-logout-on-401 logic (`user_flows.md` Flow 2) can't universally branch on `code` to distinguish "token expired, try a refresh" from "not authorized" — it needs a fallback path for `protectAdmin`-guarded routes where `code` is simply absent.
- Repository methods return a `Result<T>` (success/failure) rather than throwing across layers, so every provider handles failure uniformly and every screen can render the loading/empty/error states defined per-screen in `screens.md` without bespoke try/catch logic each time.
- `UnauthorizedException` (401) is handled once, centrally — triggers the silent-logout path described in `user_flows.md` Flow 2 (or, now that refresh is confirmed real per §7, a token-refresh attempt first where `code: "TOKEN_EXPIRED"` is present), rather than being handled per-feature.
- Shared `shared/widgets/` includes generic `LoadingView`, `EmptyStateView`, and `ErrorView` widgets (retry callback) reused across all features, keeping the loading/empty/error convention in `screens.md` consistent instead of re-implemented per screen.

## 9. What's deliberately deferred
- Exact package versions/pubspec additions — implementation detail, not today's scope per your instructions.
- **Push notification wiring — no longer "pending confirmation," now confirmed blocked on the backend, not on information.** api_spec.md §8 confirms there is no push provider integrated anywhere in the backend (zero FCM/APNs/OneSignal/Expo evidence) and no device-token field on any user-facing model. There is nothing for the mobile app to wire FCM *against* yet — this isn't an open question the backend team can just answer, it's a feature that doesn't exist server-side. v1 should plan around poll-based in-app notifications (`GET /api/notifications`) plus whatever the user separately sees via the confirmed Resend email channel, and push gets revisited only once/if the backend team adds a provider.
- Any code generation choice (freezed/json_serializable vs. plain classes) — a reasonable default to decide once real API response shapes are known, so models aren't drafted twice.
