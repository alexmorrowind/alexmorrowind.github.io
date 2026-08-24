# cPanel backend setup for b1pay.uz

This project uses Django, so it must run through cPanel's Python App feature.
Static frontend files can stay in `public_html`.

## Target layout

- Site: `https://b1pay.uz`
- Backend API: `https://api.b1pay.uz/api`
- Admin: `https://api.b1pay.uz/admin/`
- Python app root: `/home/bpayuz/b1pay_backend`
- API subdomain document root: `/home/bpayuz/b1pay_backend/public`

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
3. Create a real subdomain for `api.b1pay.uz`, not an alias/parked domain:
   - Subdomain: `api`
   - Domain: `b1pay.uz`
   - Document root: `/home/bpayuz/b1pay_backend/public`
4. Create a new Python app:
   - Python version: 3.13 if available, otherwise 3.12.
   - Application root: `b1pay_backend`
   - Application URL: `api.b1pay.uz`
   - Application startup file: `passenger_wsgi.py`
   - Application entry point: `application`
5. Upload the backend folder contents into `/home/bpayuz/b1pay_backend`.
6. Add environment variables from `fintech_new/my_payment_project/.env.cpanel.example`.
7. Click `Run pip install`.
8. In `Run Python script`, run these one by one. Do not type `python` before them;
   cPanel already adds the Python interpreter:

```bash
manage.py collectstatic --no-input
manage.py migrate
manage.py ensure_superuser
```

If cPanel does not accept the relative path, use the full path:

```bash
/home/bpayuz/b1pay_backend/manage.py collectstatic --no-input
/home/bpayuz/b1pay_backend/manage.py migrate
/home/bpayuz/b1pay_backend/manage.py ensure_superuser
```

9. Restart the Python App.

The error `can't open file '/home/bpayuz/b1pay_backend/python'` means the command
was entered as `python manage.py ...`; enter only `manage.py ...`.

## News and landing page updates

News can be added from Django Admin under `Payments -> News articles`.
Published articles are available to both the website and Android app through:

```text
https://api.b1pay.uz/api/news/?lang=ru&limit=6
```

For automatic RSS/Atom imports, set `NEWS_FEEDS` in the Python app environment,
then create a cPanel Cron Job that runs hourly:

```bash
cd /home/bpayuz/b1pay_backend && /home/bpayuz/virtualenv/b1pay_backend/3.13/bin/python manage.py sync_news
```

The command imports articles as unpublished by default. Review them in Admin
and publish them. To publish automatically, use `sync_news --publish` only for
feeds that you have permission to republish.

## Frontend

Upload the files from `fintech_new/front` into `public_html`.
`config.js` is set to use `https://api.b1pay.uz/api` when opened from
`b1pay.uz` or `www.b1pay.uz`.

Keep the main domain free of Passenger directives. `public_html/.htaccess`
should only contain normal cPanel/static-site rules. Passenger belongs in
`/home/bpayuz/b1pay_backend/public/.htaccess`, so the API subdomain runs
Django while the main domain serves static HTML.

The Android app now also defaults to `https://api.b1pay.uz/api`.

## Automatic deployment

Production auto-deploy is configured on cPanel through cron. Every 5 minutes it
runs:

```text
/home/bpayuz/bin/deploy_b1pay_from_github.sh
```

The script pulls `main` from:

```text
https://github.com/alexmorrowind/alexmorrowind.github.io.git
```

When a new commit exists, it will:

```text
1. Upload frontend files to public_html
2. Upload backend files to b1pay_backend
3. Install/update Python dependencies
4. Run collectstatic
5. Run migrations
6. Ensure the admin superuser from environment variables
7. Touch tmp/restart.txt to restart Passenger
```

The deploy script preserves cPanel-managed files such as `public_html/.htaccess`,
`public_html/.well-known/`, and the API Passenger document root
`b1pay_backend/public/`.

To check the cron job:

```bash
crontab -l
```

To check the deploy log:

```bash
tail -100 /home/bpayuz/logs/b1pay_auto_deploy.log
```

GitHub Actions can also be added later, but the GitHub token must have
`workflow` scope before it can push `.github/workflows/*.yml`.

## Manual backend commands

If you upload backend files manually, run in cPanel:

```text
manage.py collectstatic --no-input
manage.py migrate
```

Then restart the Python App.

## Checks

Open these URLs after setup:

```text
https://api.b1pay.uz/api/integrations/status/
https://api.b1pay.uz/admin/
https://b1pay.uz/login.html
```
