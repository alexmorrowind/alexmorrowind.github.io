# B1Pay × Octo — архитектура и схема потоков

## 1. Целевая логика

```text
Web / Flutter
     │
     ├── каталог, расчёт, заявка, consent
     ├── QR web-session ↔ MyID mobile confirmation
     │
     ▼
B1Pay API + Integration Gateway
     │       │
     │       ├── MyID (KYC session/status)
     │       ├── Octo / licensed bank (merchant/acquiring/e-commerce; P2P separate)
     │       ├── Bank/MFO (credit application/status)
     │       └── Insurer (policy quote/status)
     │
     ├── audit/event log + consent ledger
     ├── reconciliation + webhook processor
     ├── risk/AML case queue
     └── admin/partner portal
```

Редактируемая SVG-версия этой схемы находится в `assets/platform_architecture.svg`.

## 2. Системные контуры

### Client layer

- `Web`: каталог, SEO, QR login, application tracker, privacy/consent.
- `Flutter Android`: MyID flow, QR scan/approval, secure session, notifications, investment UI.

### B1Pay control plane

- Auth/session service.
- Catalog and content service.
- Application/lead service.
- Consent ledger.
- Partner routing and adapter layer.
- Payment state machine and idempotency store.
- Reconciliation and reporting.
- Admin/partner portal.

### Provider layer

- MyID for identity verification.
- Octo/partner bank for permitted merchant/acquiring/e-commerce operations. P2P/card-to-card/payment-service is a separate legal workstream.
- Banks and MFOs for credit decisions.
- Insurers for insurance underwriting.
- Separate investment provider/structure after legal approval.

## 3. Data classification

| Data | Example | Storage rule |
|---|---|---|
| Public | product name, rate, official source, update date | catalog; moderation; cache |
| Account | email/phone, account ID, consent status | encrypted at rest; RBAC |
| KYC result | provider session ID, status, masked identity reference | minimum necessary; no raw biometrics |
| Payment reference | partner transaction ID, token, masked card | tokenized; no raw PAN/CVV |
| Secrets | API keys, HMAC secret, client secret | secret manager; never frontend/logs |
| Audit | actor, event, timestamp, correlation ID | append-only access controlled |

## 4. P2P sequence

```text
User → App/Web: choose transfer and recipient/amount
App → B1Pay API: authenticated request + consent + idempotency key
B1Pay → Risk/AML: pre-check, limit, device/session risk
B1Pay → Octo/Bank: signed request for an approved operation
Octo/Bank → B1Pay: pending/success/failed + provider transaction ID
Octo/Bank → B1Pay: signed webhook for final state
B1Pay → Reconciliation: match ledger and provider statement
B1Pay → User: status, receipt/next step
```

`pending` is not success. The client cannot set final status locally. Every retry reuses the same idempotency key.

## 5. MyID + QR sequence

```text
Web → B1Pay: create web auth session (TTL + nonce)
Web ← B1Pay: QR contains short-lived session reference
Mobile → MyID: start KYC/auth session
MyID → B1Pay: result/status callback or polling
Mobile → B1Pay: approve QR session after verified user action
B1Pay → Web: signed one-time completion result
Web: opens authenticated session without receiving biometrics
```

Required controls: origin/domain allowlist, nonce binding, replay prevention, app attestation where available, rate limits, audit trail, clear user display of the requested action.

## 6. Credit/loan sequence

```text
Catalog → User: compare offers and calculator
User → B1Pay: start application + partner consent
B1Pay → Partner: lead/application payload (minimum fields)
Partner → B1Pay: application ID + pending/approved/rejected
B1Pay → User: status and partner hand-off
Partner: owns credit decision, agreement, disbursement and collection
```

## 7. Security baseline

- TLS 1.2+; HSTS; secure cookies; CSRF protection for web.
- Server-side secrets only; environment/secret manager; rotation and least privilege.
- HMAC/signature verification on webhooks; timestamp/nonce to prevent replay.
- JWT access tokens short-lived; refresh token rotation; session revocation.
- RBAC for operations/admin; MFA for staff and partner users.
- PII redaction in logs; no KYC images or card secrets in analytics.
- SAST/dependency scanning, DAST on staging, penetration test before money movement.
- Backups, RPO/RTO, incident response, disaster recovery exercise.

## 8. Integration contract checklist

### From Octo/partner

- separate documentation for merchant/acquiring/e-commerce APIs versus P2P/card-to-card/payment-service APIs;
- sandbox base URL and credentials;
- API auth/signature version;
- request/response schemas;
- idempotency support;
- webhook event list, signature and retry policy;
- error code catalog;
- limits, tariffs and settlement;
- refund/reversal/dispute contract;
- daily reconciliation format;
- security questionnaire, IP/cert requirements;
- SLA and escalation contacts.

### From B1Pay

- legal entity and authorized signatory;
- verified domains and redirect URLs;
- partner approval of UX/disclaimers;
- data protection and retention policy;
- AML/KYC RACI and support process;
- monitoring dashboard and incident runbook;
- test users and pilot cohort;
- release/change-management process.
