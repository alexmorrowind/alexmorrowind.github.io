# API setup for B1 fintech app

This project is configured so API keys stay on the backend only. The frontend
calls Django endpoints under `/api/...` and never stores Payme keys.

## Where to put API keys

You have two safe options.

1. Local or cloud environment file:

```text
fintech_new/my_payment_project/.env
```

2. Django Admin:

```text
http://127.0.0.1:8000/admin/
Payments -> API Configurations
```

Django Admin values override `.env` values when `is_active=True`.

Check current integration state here:

```text
http://127.0.0.1:8000/api/integrations/status/
```

Secrets are masked in that endpoint.

## Payme Merchant

Used for registration redirect, card connect redirect, orders, investments,
reports, and Payme webhook callbacks.

In `.env`:

```bash
PAYME_MERCHANT_ID=your_payme_merchant_or_cashbox_id
PAYME_MERCHANT_KEY=paste_test_key_here
PAYME_CHECKOUT_URL=https://test.paycom.uz
PAYME_CALLBACK_URL=http://127.0.0.1:8765/index.html
PAYME_ACCOUNT_KEY=Bpay
```

From your Payme cabinet:

- `Тестовый ключ` -> `PAYME_MERCHANT_KEY` while testing.
- `Ключ` -> `PAYME_MERCHANT_KEY` only when production is ready.
- Cashbox/Merchant ID -> `PAYME_MERCHANT_ID`.
- Account field from Payme sandbox, for your current cashbox it is `Bpay` ->
  `PAYME_ACCOUNT_KEY=Bpay`.

Payme server webhook endpoint:

```text
https://your-backend-domain.example/api/payme/
```

For local sandbox tests in the browser, use:

```text
http://127.0.0.1:8000/api/payme/
```

Do not use `/api/integrations/status/` as Payme endpoint. That URL is only for
checking whether keys are configured.

User return page after checkout:

```text
https://your-frontend-domain.example/index.html
```

Merchant checkout URLs:

- Test checkout page: `https://test.paycom.uz`
- Production checkout page: `https://checkout.paycom.uz`
- Subscribe API test endpoint stays separate: `https://checkout.test.paycom.uz/api`

## Payme Subscribe

Used for tokenized card linking by card number + SMS code. This is optional if
you only want redirect-based checkout, but keep it ready for real card token
flows.

```bash
PAYME_SUBSCRIBE_BASE_URL=https://checkout.test.paycom.uz/api
PAYME_SUBSCRIBE_ID=your_payme_subscribe_id
PAYME_SUBSCRIBE_KEY=your_payme_subscribe_key_or_password
```

## Registration

Registration is currently Payme-first:

1. User enters name, email, phone and password.
2. Frontend calls `/api/auth/register/` with `payme_connect=true`.
3. Backend creates a Payme `card_order` and returns `payme_checkout_url`.
4. Frontend redirects to Payme.
5. Payme calls backend webhook `/api/payme/`.

MyID/camera is not used for registration anymore.

## SMS and MyID

SMS and MyID keys are still available for future flows, but registration does not
depend on them now.

```bash
SMS_DEMO_MODE=true
SMS_DEMO_CODE=666666
SMS_PROVIDER_URL=
SMS_PROVIDER_TOKEN=

MYID_BASE_URL=
MYID_CLIENT_ID=
MYID_USERNAME=
MYID_PASSWORD=
MYID_HOSTED_URL=
```

## Public deployment

If frontend is on GitHub Pages and backend is on Render/Railway/Fly/VPS:

```js
// fintech_new/front/config.js
window.B1_API_BASE_URL = 'https://your-backend-domain.example/api';
```

Backend `.env` for public testing:

```bash
DJANGO_DEBUG=false
DJANGO_ALLOWED_HOSTS=your-backend-domain.example
CORS_ALLOW_ALL_ORIGINS=false
CORS_ALLOWED_ORIGINS=https://your-github-pages-domain.example
PAYME_CALLBACK_URL=https://your-github-pages-domain.example/index.html
```

Do not commit `.env`, `db.sqlite3`, or real API keys to GitHub.
