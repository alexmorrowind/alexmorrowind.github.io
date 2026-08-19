# cPanel backend setup for b1pay.uz

This project uses Django, so it must run through cPanel's Python App feature.
Static frontend files can stay in `public_html`.

## Target layout

- Site: `https://b1pay.uz`
- Backend API: `https://api.b1pay.uz/api`
- Admin: `https://api.b1pay.uz/admin/`
- Python app root: `/home/bpayuz/b1pay_backend`

## DNS

Create or verify these records:

```text
@     A      37.153.159.11
www   CNAME  b1pay.uz
api   A      37.153.159.11
```

## cPanel Python App

1. Open cPanel.
2. Search for `Setup Python App` or `Python Application`.
3. Create a new app:
   - Python version: 3.13 if available, otherwise 3.12.
   - Application root: `b1pay_backend`
   - Application URL: `api.b1pay.uz`
   - Application startup file: `passenger_wsgi.py`
   - Application entry point: `application`
4. Upload the backend folder contents into `/home/bpayuz/b1pay_backend`.
5. Add environment variables from `fintech_new/my_payment_project/.env.cpanel.example`.
6. Run:

```bash
pip install -r requirements.txt
python manage.py collectstatic --no-input
python manage.py migrate
python manage.py ensure_superuser
```

7. Restart the Python App.

## Frontend

Upload the files from `fintech_new/front` into `public_html`.
`config.js` is set to use `https://api.b1pay.uz/api` when opened from
`b1pay.uz` or `www.b1pay.uz`.

## Checks

Open these URLs after setup:

```text
https://api.b1pay.uz/api/integrations/status/
https://api.b1pay.uz/admin/
https://b1pay.uz/login.html
```
