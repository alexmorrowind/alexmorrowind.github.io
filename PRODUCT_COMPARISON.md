# B1 product comparison

## What to borrow from Finko

- Separate journeys for individuals and businesses.
- A dedicated partners section for banks and financial organizations.
- One application flow instead of separate forms for every product.
- Credit history, debt-load and scoring utilities as a premium/lead product.
- Currency exchange map and practical financial tools.
- Partner logos and visible trust signals on the first screen.
- Product cards with a clear action: apply, check, compare or start.

## What to borrow from Bank.uz

- Strong top-level product navigation: deposits, credits, mortgage, cards,
  business, insurance and transfers.
- Product subcategories that users can search and compare.
- Current exchange rates, archives and gold prices.
- Branches, ATMs and card machines.
- A news feed with categories, dates, images, excerpts and source pages.
- Product cards with terms, rate, currency and a detail page.
- A clear independent-portal explanation and an advertising/partner model.
- SEO-friendly pages for each product type and each bank.

## What B1 already has

- Django backend and admin.
- Static landing page on cPanel.
- Shared API for the website and Android app.
- Bank, card, loan and investment demo surfaces.
- Standard registration without mandatory Payme connection.
- Payme integration behind an opt-in flow.
- Bilingual Uzbek/Russian frontend.

## Current gaps

- Banks, cards and loans are still partly hardcoded in JavaScript and Flutter.
- Blog was previously only a placeholder.
- No editorial news workflow in admin.
- No source, publication status or update timestamp for offers.
- No partner tracking model for clicks, applications and approved leads.
- No automated deployment secrets configured in GitHub.
- No public Android release links on the landing page.

## Recommended implementation order

### P0: content and data foundation

1. News articles in Django admin.
2. Public `/api/news/` for web and Android.
3. News block on the landing page and a full blog page.
4. Draft/published status, source link, source name and publication date.
5. RSS/Atom import into drafts.
6. Hourly cPanel cron for news synchronization.
7. GitHub Actions upload for frontend and backend changes.

### P1: useful portal features

1. Move bank, card and loan offers from hardcoded frontend arrays into Django.
2. Add filters for rate, amount, term, currency, bank and product type.
3. Show “updated on” and “source” on every offer.
4. Add currency rates, archives and gold-price pages.
5. Add branch and ATM search by city.
6. Add calculators for loans, deposits and currency conversion.
7. Add saved products and side-by-side comparison.

### P2: partner marketplace

1. Partner profile for each bank or lender.
2. Tracking links with `utm_source`, `utm_campaign` and a B1 click id.
3. Click and lead events in the backend.
4. Partner dashboard with clicks, applications and conversion rate.
5. Contracts with banks for CPC, CPL, CPA or fixed placements.
6. Clear disclosure when a product is sponsored or paid.

### P3: mobile parity

1. Show the same news API in the Android news screen.
2. Add saved offers and comparison state.
3. Add push notifications for important financial news.
4. Add deep links from a mobile card to a bank product.
5. Replace demo data in Flutter with backend data gradually.

## Content and rights rules

- Prefer official press releases, licensed RSS/API feeds and original B1
  editorial summaries.
- Store the source name and source URL for every imported item.
- Keep imported items as drafts until reviewed.
- Do not copy full articles or images from another media site without permission.
- Use original images, licensed stock images or images supplied for
  republishing.

## First release target

The first useful B1 release should contain:

- landing page with current news;
- blog/news page;
- bank, credit, card and deposit comparisons;
- currency rates;
- calculators;
- source and update dates;
- one application flow;
- admin control for offers and news;
- the same API for website and Android.
