# B1 Fintech API and Schema Notes

## MyID Integration

`MyIdVerificationGateway` is the Flutter-side abstraction. In production it should call the Cloud Run API to create a verification session and wait for backend-completed status. The app should only collect phone/password and account type. MyID owns passport, selfie, and identity capture.

The Android flow uses `POST /api/auth/myid/mobile/start/` to receive a
short-lived `session_id`, `client_hash`, and `client_hash_id`, then starts the
MyID Flutter SDK. After the SDK returns `result_code=1`, the app calls
`POST /api/auth/myid/mobile/complete/`. The backend must accept only that
success code and return a verified profile plus JWT access token. SDK errors
(`101` cancellation, `102` camera denied, `103` SDK/network failure, `122`
blocked user) are retryable UI states and must not create an authenticated
session.

Never place `client_secret`, MyID username/password, PINFL, passport photos, or
raw SDK payloads in the Flutter project or logs. MyID provider credentials stay
on the backend.

## Payment Integration

`PaymentGateway` is the Flutter-side abstraction for card ownership verification. Production should call backend endpoints that communicate with Payme or another licensed payment provider. The app sends card number only to the backend over TLS for OTP initiation; the backend stores only tokenized or masked data.

## Shared Django API

The Android app and website share the Django backend in
`fintech_new/my_payment_project`.

```text
GET  /api/integrations/status/
GET  /api/banks/
POST /api/auth/register/
POST /api/auth/login/
GET  /api/user/profile/
GET  /api/user/cards/
POST /api/payme/subscribe/cards/create/
POST /api/payme/subscribe/cards/code/
POST /api/payme/subscribe/cards/verify/
GET  /api/startups/
POST /api/startups/
POST /api/investments/
```

Use `--dart-define=B1_API_BASE_URL=https://your-backend.example/api` for
staging/production Android builds. Provider secrets stay on Django.

## Account Permissions

Physical person:

- Browse startups.
- Search/filter startups.
- Invest.
- Track investment history.
- Cannot create startups.

Legal entity:

- Complete business questionnaire at registration.
- Create startup listings.
- Upload logo and startup information.
- Monitor investors/statistics.
- Receive investments after approval.

Admin:

- Manage users.
- Manage startups.
- Manage investments.
- Manage banks.
- Approve startup listings.
- View analytics.
