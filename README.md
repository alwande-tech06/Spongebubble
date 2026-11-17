# SpongeBubble: front-end prototype (v0.1)

Mobile car wash marketplace for Durban & surrounds. One Flutter codebase, three apps:

| App | Folder | Platforms | Who uses it |
|---|---|---|---|
| Customer app | `apps/customer` | Android, iOS, web | People booking a wash |
| Partner app | `apps/partner` | Android, iOS | Washers and car wash businesses |
| Admin portal | `apps/admin` | Web | SpongeBubble staff |

Shared code lives in `packages/`:

- `packages/sb_core`: pure Dart. Models (Customer, Vehicle, Booking, ServiceProvider…), the **pricing and refund rules** (`pricing.dart`) and mock data. No Flutter, so the same rules can be unit-tested and later mirrored in the NestJS backend.
- `packages/sb_ui`: design system: logo colours, Plus Jakarta Sans, and shared widgets (cards, badges, price breakdown, milestone tracker, photo slots, map placeholder).

This is the **prototype phase** of the project plan. There is no backend yet. Every app runs on mock data and simulates the other side of a booking so each flow can be demoed end to end.

## Set up (once)

Needs Flutter 3.24 or newer (`flutter --version`).

```bash
# macOS / Linux
./tool/setup.sh
# Windows (PowerShell)
./tool/setup.ps1
```

The script runs `flutter create` in each app to add the `android/`, `ios/` and `web/` folders (they are not committed), then `flutter pub get`.

## Run

```bash
cd apps/customer && flutter run -d chrome     # or an Android emulator / iPhone simulator
cd apps/partner  && flutter run               # Android emulator or device
cd apps/admin    && flutter run -d chrome
```

Check the code: `flutter analyze` in each app, and `dart test` in `packages/sb_core` (pricing and refund rules).

## Demo scripts

**Customer:** Create an account → any 6-digit SMS code → Home. Tap *Wash now* → pick vehicle and service → *Now* → address, water and power → *Pay R25 booking fee*. The app then plays the washer's side by itself: finding a washer → accepted → travelling (ETA counts down) → arrived → washing (checklist fills) → *Check your car*. Approve → pay (card or cash, tip; cash is blocked from R500) → rate. Close and reopen the app: you are still signed in.

**Partner:** Become a provider → phone + any code → 7 onboarding steps → *Submit for review* → *Simulate approval*. On Home, switch **online**: a job offer pops up after about 4 seconds with a 60-second countdown. Accept → travel → before photos (tap each slot) → confirm service and resources → checklist → after photos → collect payment → job complete (earnings update).

**Admin:** Sign in → any 2FA code → Dashboard. Open a booking from the table. *Applications*: Approve is disabled until all documents are in; approving or rejecting updates the list. *Services & pricing* shows the live values from `Pricing`.

## Business rules and open decisions

All money rules are in `packages/sb_core/lib/src/pricing.dart`. Values marked **TBC** wait for the client:

| Rule | Prototype value |
|---|---|
| Booking fee (paid upfront, separate from the wash price) | R25 · TBC |
| Travel fee | R10 per km · TBC |
| Card required from | R500 |
| Provider commission | 20% of service price · TBC |
| Provider subscription | R60 per week · TBC |
| Cancel before washer travels / no washer found / washer cancels | 100% of booking fee back |
| Cancel while washer travelling | 50% (100% if washer > 15 min late) |
| Cancel after washer arrived | 0% |
| Scheduled booking cancelled < 12 h before | 50% · TBC |

## What is mocked (and what replaces it)

| Prototype | Backend phase |
|---|---|
| `MockData` + Riverpod notifiers | REST API (NestJS) through a repository layer |
| `_simulate()` in `apps/customer/lib/state.dart`, offer timer in the partner app | WebSocket events (status, ETA, offers, chat) |
| `MapPlaceholder` | `google_maps_flutter` + Places / Distance Matrix |
| Fake payment delay | PayFast/Peach/Paystack checkout with server-side confirmation |
| `shared_preferences` "signed in" flag | JWT access + refresh tokens in secure storage |
| Photo slots | Camera + upload to encrypted storage |

## Structure

```
spongebubble/
├── apps/
│   ├── customer/lib/   main, router, state, screens/ (auth, home_shell, vehicles, booking_flow, live_booking, bookings, account)
│   ├── partner/lib/    main, router, state, screens/ (onboarding, home, job)
│   └── admin/lib/      main, router, state, screens/ (auth, shell, pages)
├── packages/
│   ├── sb_core/        models, pricing, format, mock_data (+ tests)
│   └── sb_ui/          colors, theme, widgets, logo (+ assets/)
└── tool/               setup.sh, setup.ps1
```

## Matching the designs

Screens follow the wireframes (admin Figma file, partner and customer wireframe PDFs) and the clickable prototype. Admin pages not yet built in Flutter (allocation, finance, incidents, governance) open a placeholder page; they are next.
