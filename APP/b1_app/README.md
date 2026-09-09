# B1 Fintech Super App

Native Flutter Android fintech super app for Uzbekistan with mockable MyID, card verification, startup investment, profile, bank, and admin modules.

## Current Build

- Flutter app: `lib/main.dart`
- Domain models: `lib/models.dart`
- Controllers/state: `lib/controllers.dart`
- Mockable integrations: `lib/integrations.dart`
- Local seed data: `lib/app_data_service.dart`
- Existing web prototype: `fintech app/`

The app now talks to the shared Django backend used by the website. Demo mode is
available only when explicitly enabled for local UI work; a missing production
MyID configuration never silently verifies a user.

## Architecture

The current MVP architecture is:

- Flutter mobile app for Android.
- Django REST API in `fintech_new/my_payment_project`.
- Shared database for website and Android app users, cards, orders, startups, and investments.
- JWT auth from `/api/auth/login/` and `/api/auth/register/`.
- Payme Merchant/Subscribe calls stay on Django; Flutter never stores Payme secrets.
- Production default API URL: `https://api.b1pay.uz/api`.

Run locally with the Android emulator:

```bash
flutter run --dart-define=B1_API_BASE_URL=http://10.0.2.2:8000/api
```

MyID production credentials are never compiled into the app. The backend
creates a short-lived mobile session and returns only the SDK configuration
needed by the MyID Flutter plugin (`session_id`, `client_hash`, and
`client_hash_id`). Configure the MyID client credentials on Django/Cloud Run
only (environment variables or the server-side API configuration).

For local UI work without a configured MyID backend, the demo path is explicit
and opt-in:

```bash
flutter run \
  --dart-define=B1_API_BASE_URL=http://10.0.2.2:8000/api \
  --dart-define=B1_MYID_ALLOW_DEMO=true
```

Do not enable `B1_MYID_ALLOW_DEMO` in release builds. The app accepts only
MyID `result_code=1` as a successful identification, handles cancellation,
camera denial, SDK/network errors, expired sessions, and requires the backend
to return a verified session with an access token before opening the app.

Run on a physical phone with your Mac LAN IP:

```bash
flutter run --dart-define=B1_API_BASE_URL=http://YOUR_MAC_IP:8000/api
```

## Database Schema

Firestore collections:

- `users/{userId}`: phone, accountType, verificationStatus, myIdStatus, identity fields, business questionnaire, createdAt.
- `users/{userId}/cards/{cardId}`: cardName, maskedNumber, bankName, expiryDate, ownerVerified, providerCardToken.
- `banks/{bankId}`: name, type, apy, fees, rating, features, active.
- `startups/{startupId}`: ownerUserId, name, category, logoUrl, description, investmentGoal, raisedAmount, businessModel, financialInfo, status.
- `investments/{investmentId}`: userId, startupId, amount, status, createdAt.
- `adminReviews/{reviewId}`: targetType, targetId, status, reviewerId, notes, createdAt.

Never store raw card numbers, OTPs, passport photos, or MyID secrets in Firestore.

## API Structure

Django REST endpoints:

- `POST /api/auth/register/`: creates a server user and JWT token pair.
- `POST /api/auth/login/`: returns JWT token pair.
- `GET /api/user/profile/`: loads profile shared with the website.
- `GET/POST /api/user/cards/`: loads and stores cards.
- `POST /api/payme/subscribe/cards/create/`: starts Payme card tokenization.
- `POST /api/payme/subscribe/cards/code/`: sends Payme verification code.
- `POST /api/payme/subscribe/cards/verify/`: verifies and stores a tokenized card.
- `GET /api/banks/`: returns shared bank offers.
- `GET/POST /api/startups/`: loads and creates startup listings.
- `GET/POST /api/investments/`: loads and creates investment orders.

## Deployment Guide

1. Start Django:
   - `cd fintech_new/my_payment_project`
   - `python3 manage.py runserver 0.0.0.0:8000`
2. Put Payme keys in Django Admin or backend environment variables.
3. Run Android:
   - production API: `flutter run`
   - local emulator API: `flutter run --dart-define=B1_API_BASE_URL=http://10.0.2.2:8000/api`
   - physical phone: `flutter run --dart-define=B1_API_BASE_URL=http://YOUR_MAC_IP:8000/api`
4. Build Android:
   - `flutter pub get`
   - `flutter analyze`
   - `flutter test`
   - `flutter build apk --release`

## Testing Guide

Local/staging mode:

- MyID production starts only from a short-lived backend session. Local mock/demo
  identity is opt-in with `B1_MYID_ALLOW_DEMO=true` and must not be enabled in a
  release build.
- Card OTP mock uses `111111`.
- Physical users can browse startups and invest.
- Legal users can create startup listings and view analytics-style details.
- Admin dashboard shows users, banks, startups, investments, and pending approvals.

Commands:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

## Security Notes

- MyID performs identity capture; the app must not ask for passport data, passport photos, or selfie.
- MyID's camera permission is requested by the SDK only when the user starts
  identification. If the user denies it, the app shows a retryable error; no
  passport/PINFL value is hardcoded or logged by the app.
- Payment integration must tokenize cards; never store raw PAN/CVV.
- Provider credentials belong on Cloud Run, not in Flutter.
- Firestore rules must enforce account type permissions: physical users invest, legal users create startups, admins approve/manage.
