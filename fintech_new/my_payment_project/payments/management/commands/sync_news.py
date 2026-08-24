import hashlib
import html
import json
import os
import re
from datetime import datetime, timezone as dt_timezone
from email.utils import parsedate_to_datetime
from urllib.parse import urljoin
from urllib.request import Request, urlopen
from xml.etree import ElementTree

from django.core.management.base import BaseCommand
from django.utils.text import slugify
from django.utils.timezone import now

from payments.models import NewsArticle


TAG_RE = re.compile(r'<[^>]+>')


def clean_text(value):
    value = html.unescape(str(value or ''))
    value = TAG_RE.sub(' ', value)
    return re.sub(r'\s+', ' ', value).strip()


def parse_date(value):
    if not value:
        return now()
    try:
        parsed = parsedate_to_datetime(value)
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=dt_timezone.utc)
        return parsed
    except (TypeError, ValueError, OverflowError):
        try:
            parsed = datetime.fromisoformat(value.replace('Z', '+00:00'))
            return parsed if parsed.tzinfo else parsed.replace(tzinfo=dt_timezone.utc)
        except ValueError:
            return now()


def local_name(tag):
    return tag.rsplit('}', 1)[-1].lower()


def first_text(element, names):
    for child in element.iter():
        if local_name(child.tag) in names and child.text:
            return clean_text(child.text)
    return ''


def first_link(element):
    for child in element.iter():
        if local_name(child.tag) != 'link':
            continue
        href = child.attrib.get('href') or (child.text or '')
        if href.strip():
            return href.strip()
    return ''


def first_image(element, article_url):
    for child in element.iter():
        name = local_name(child.tag)
        if name in {'thumbnail', 'content', 'enclosure'}:
            url = child.attrib.get('url') or child.attrib.get('href')
            if url:
                return urljoin(article_url, url)
    return ''


def parse_feed(raw, source_name):
    root = ElementTree.fromstring(raw)
    entries = []
    for item in root.iter():
        if local_name(item.tag) not in {'item', 'entry'}:
            continue
        title = first_text(item, {'title'})
        link = first_link(item)
        if not title or not link:
            continue
        summary = first_text(item, {'description', 'summary', 'encoded', 'content'})
        published = first_text(item, {'pubdate', 'published', 'updated', 'issued'})
        entries.append({
            'title': title,
            'link': link,
            'summary': summary[:1000],
            'published_at': parse_date(published),
            'image_url': first_image(item, link),
            'source_name': source_name,
        })
    return entries


def feed_config():
    raw = os.environ.get('NEWS_FEEDS', '').strip()
    if not raw:
        return []
    if raw.startswith('['):
        try:
            parsed = json.loads(raw)
            return [
                (str(item.get('name') or 'Источник').strip(), str(item.get('url') or '').strip())
                for item in parsed
                if isinstance(item, dict) and item.get('url')
            ]
        except json.JSONDecodeError:
            return []

    result = []
    for chunk in raw.split(','):
        name, separator, url = chunk.partition('|')
        if separator and url.strip():
            result.append((name.strip() or 'Источник', url.strip()))
    return result


class Command(BaseCommand):
    help = 'Import articles from configured RSS/Atom feeds as unpublished news.'

    def add_arguments(self, parser):
        parser.add_argument('--publish', action='store_true', help='Publish imported items immediately.')

    def handle(self, *args, **options):
        feeds = feed_config()
        if not feeds:
            self.stdout.write('NEWS_FEEDS is empty; nothing to sync.')
            return

        imported = 0
        for source_name, feed_url in feeds:
            try:
                request = Request(
                    feed_url,
                    headers={'User-Agent': os.environ.get('NEWS_SYNC_USER_AGENT', 'B1-NewsBot/1.0')},
                )
                with urlopen(request, timeout=20) as response:
                    entries = parse_feed(response.read(), source_name)
            except Exception as error:
                self.stderr.write(self.style.WARNING(f'{source_name}: {error}'))
                continue

            for entry in entries[:30]:
                external_id = hashlib.sha256(entry['link'].encode('utf-8')).hexdigest()
                base_slug = slugify(entry['title'])[:220] or f'news-{external_id[:12]}'
                slug = base_slug
                counter = 2
                while NewsArticle.objects.filter(slug=slug).exclude(external_id=external_id).exists():
                    slug = f'{base_slug[:250 - len(str(counter))]}-{counter}'
                    counter += 1

                existing = NewsArticle.objects.filter(external_id=external_id).first()
                defaults = {
                    'title': entry['title'],
                    'slug': slug,
                    'excerpt': entry['summary'],
                    'image_url': entry['image_url'],
                    'source_name': entry['source_name'],
                    'source_url': entry['link'],
                    'published_at': entry['published_at'],
                }
                if existing is None:
                    defaults['is_published'] = bool(options['publish'])
                    NewsArticle.objects.create(external_id=external_id, **defaults)
                else:
                    if options['publish']:
                        defaults['is_published'] = True
                    for field, value in defaults.items():
                        setattr(existing, field, value)
                    existing.save()
                imported += 1

        self.stdout.write(self.style.SUCCESS(f'Sync complete. Processed {imported} articles.'))
