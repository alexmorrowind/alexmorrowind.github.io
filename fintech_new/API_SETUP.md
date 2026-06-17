# MyID and Payme setup

This project has safe demo fallbacks: if real credentials are not set, MyID returns
`demo_verified` and Payme Subscribe returns demo card/SMS responses. This lets the
registration and card UI be tested locally without sending real data.

Copy `my_payment_project/.env.example` to `my_payment_project/.env`, then fill the
values you have. Do not commit `.env` to GitHub.

## MyID

Docs: https://docs.myid.uz/#/ru/embedded

Set these environment variables on the Django server:

```bash
MYID_BASE_URL=https://your-myid-api-host
MYID_CLIENT_ID=your_client_id
MYID_USERNAME=your_username
MYID_PASSWORD=your_password
```

Registration flow:

1. Frontend sends user name, email, phone and consent to `/api/auth/myid/start/`.
2. In demo mode, backend returns `demo_verified`.
3. With real MyID, set `MYID_HOSTED_URL` or use inline MyID credentials when they
   are issued by MyID.
4. Backend sends an SMS code to the registration phone via `/api/auth/phone-code/`.
5. Frontend verifies SMS via `/api/auth/phone-verify/`.
6. `/api/auth/register/` accepts registration only after MyID and SMS are verified.

For now SMS is demo mode with code `666666`. Connect a real SMS provider later via
`SMS_PROVIDER_URL` and `SMS_PROVIDER_TOKEN`.

## Payme Subscribe

Docs:

- https://developer.help.paycom.uz/protokol-subscribe-api
- https://developer.help.paycom.uz/metody-subscribe-api/

Set these environment variables on the Django server:

```bash
PAYME_SUBSCRIBE_BASE_URL=https://checkout.test.paycom.uz/api
PAYME_SUBSCRIBE_ID=your_cashier_id
PAYME_SUBSCRIBE_KEY=your_cashier_password
```

Card flow:

1. Frontend posts card number and expiry to `/api/payme/subscribe/cards/create/`.
2. Backend calls Payme `cards.create`.
3. Frontend asks for SMS with `/api/payme/subscribe/cards/code/`.
4. Frontend submits SMS code to `/api/payme/subscribe/cards/verify/`.
5. Backend stores only the Payme token, masked card number, expiry, and status.

In Payme test mode, use the test cards from Payme docs and SMS code `666666`.

## Payme Merchant checkout

For checkout/investment orders, set:

```bash
PAYME_MERCHANT_ID=your_merchant_id
PAYME_MERCHANT_KEY=your_merchant_key
PAYME_CHECKOUT_URL=https://checkout.test.paycom.uz
PAYME_CALLBACK_URL=https://your-public-site.example/index.html
```

From the Payme cabinet:

- `Ключ` is the production key. Use it only when the real site is ready.
- `Тестовый ключ` is the test key. Put it into `PAYME_MERCHANT_KEY` while testing.
- `Endpoint URL` must point to the backend Payme webhook, not only to GitHub Pages,
  if Payme asks for the server callback endpoint. Use:

```text
https://your-backend-domain.example/api/payme/
```

Payme must be able to reach the backend webhook:

```text
POST /api/payme/
```

If Payme cabinet asks for a user return/callback page after checkout, use the
frontend page:

```text
https://your-frontend-domain.example/index.html
```

## Public test server

For real MyID camera and Payme callbacks, use HTTPS.

Fast test option:

- Run Django and frontend locally.
- Expose them with ngrok or cloudflared.
- Put the public HTTPS frontend URL into `PAYME_CALLBACK_URL`.
- Add the public backend/frontend origins to Django CORS/allowed hosts.

Cleaner cloud option:

- Deploy Django to Render, Railway, Fly.io, or a VPS.
- Use PostgreSQL instead of local SQLite.
- Serve the frontend over HTTPS.
- If frontend is on GitHub Pages and backend is on Render/Railway, set
  `window.B1_API_BASE_URL = 'https://your-backend.example/api'` in
  `front/config.js`.
- Set `DEBUG=False`, real `ALLOWED_HOSTS`, and exact `CORS_ALLOWED_ORIGINS`.
- Store all API keys as server environment variables, never in frontend JS.
