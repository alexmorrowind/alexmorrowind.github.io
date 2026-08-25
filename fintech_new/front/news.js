(function () {
  function apiBaseUrl() {
    if (window.B1_API_BASE_URL) return window.B1_API_BASE_URL.replace(/\/$/, '');
    const host = window.location.hostname;
    if (host === '127.0.0.1' || host === 'localhost' || host === '') {
      return 'http://127.0.0.1:8000/api';
    }
    return `${window.location.origin}/api`;
  }

  function language() {
    return localStorage.getItem('bpay_lang') || localStorage.getItem('selectedLanguage') || 'uz';
  }

  function escapeHtml(value) {
    return String(value || '').replace(/[&<>"']/g, char => ({
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#039;',
    }[char]));
  }

  function formatDate(value) {
    if (!value) return '';
    try {
      return new Intl.DateTimeFormat(language() === 'ru' ? 'ru-RU' : 'uz-UZ', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
      }).format(new Date(value));
    } catch (error) {
      return '';
    }
  }

  function articleHref(article) {
    return article.slug ? `news-article.html?slug=${encodeURIComponent(article.slug)}` : 'blog.html';
  }

  function sourceHref(article) {
    const value = String(article.source_url || '').trim();
    if (!value) return '';
    if (value.startsWith('/') || value.endsWith('.html') || value.includes('.html#')) return value;
    try {
      const parsed = new URL(value, window.location.href);
      return ['http:', 'https:'].includes(parsed.protocol) ? parsed.href : '';
    } catch (error) {
      return '';
    }
  }

  function sourceAction(article) {
    const href = sourceHref(article);
    if (!href) return '';
    const external = /^https?:\/\//i.test(href);
    return `<a class="news-card-link" href="${escapeHtml(href)}"${external ? ' target="_blank" rel="noopener noreferrer"' : ''}>${language() === 'ru' ? 'Источник' : 'Manba'} <span aria-hidden="true">${external ? '↗' : '→'}</span></a>`;
  }

  function articleCard(article, compact) {
    const title = escapeHtml(article.display_title || article.title);
    const excerpt = escapeHtml(article.display_excerpt || article.excerpt);
    const image = article.image_url
      ? `<img src="${escapeHtml(article.image_url)}" alt="" loading="lazy" onerror="this.parentElement.classList.add('news-media-empty');this.remove()">`
      : '';
    const source = escapeHtml(article.source_name || 'B1');
    const href = articleHref(article);

    return `
      <article class="news-card${compact ? ' news-card-compact' : ''}">
        <a class="news-card-media${image ? '' : ' news-media-empty'}" href="${href}" aria-label="${title}">
          ${image || '<span class="news-media-mark">B1</span>'}
        </a>
        <div class="news-card-body">
          <div class="news-card-meta">
            <span>${escapeHtml(article.category_label || (language() === 'ru' ? 'Новости' : 'Yangiliklar'))}</span>
            <time datetime="${escapeHtml(article.published_at || '')}">${formatDate(article.published_at)}</time>
          </div>
          <h3><a href="${href}">${title}</a></h3>
          ${excerpt ? `<p>${excerpt}</p>` : ''}
          <div class="news-card-footer">
            <span class="news-source">${source}</span>
            <span class="news-card-actions">
              <a class="news-card-link" href="${href}">${language() === 'ru' ? 'Подробнее' : 'Batafsil'} <span aria-hidden="true">→</span></a>
              ${sourceAction(article)}
            </span>
          </div>
        </div>
      </article>
    `;
  }

  async function loadNews(limit) {
    const response = await fetch(`${apiBaseUrl()}/news/?lang=${encodeURIComponent(language())}&limit=${limit}`, {
      headers: { Accept: 'application/json' },
    });
    if (!response.ok) throw new Error(`News request failed: ${response.status}`);
    return response.json();
  }

  async function loadArticle(slug) {
    const response = await fetch(`${apiBaseUrl()}/news/${encodeURIComponent(slug)}/?lang=${encodeURIComponent(language())}`, {
      headers: { Accept: 'application/json' },
    });
    if (!response.ok) throw new Error(`Article request failed: ${response.status}`);
    return response.json();
  }

  function fallbackNews(limit) {
    return Array.isArray(window.B1_PUBLIC_NEWS) ? window.B1_PUBLIC_NEWS.slice(0, limit) : [];
  }

  function renderEmpty(container, page) {
    container.innerHTML = `
      <div class="news-empty">
        <strong>${language() === 'ru' ? 'Новости скоро появятся' : 'Yangiliklar tez orada chiqadi'}</strong>
        <span>${page
          ? (language() === 'ru' ? 'Публикуем проверенные материалы и официальные обновления.' : 'Tekshirilgan materiallar va rasmiy yangilanishlar e’lon qilinadi.')
          : (language() === 'ru' ? 'Следите за обновлениями B1.' : 'B1 yangiliklarini kuzatib boring.')}</span>
        <span>
          ${language() === 'ru' ? 'Пока можно открыть официальные ленты:' : 'Hozircha rasmiy manbalarni ochishingiz mumkin:'}
          <a href="https://cbu.uz/ru/press_center/news/" target="_blank" rel="noopener noreferrer">Центральный банк</a>
          ·
          <a href="https://www.spot.uz/ru/" target="_blank" rel="noopener noreferrer">Spot</a>
        </span>
      </div>
    `;
  }

  async function renderNews(container, limit, page) {
    if (!container) return;
    container.innerHTML = '<div class="news-loading">Loading...</div>';
    try {
      const articles = await loadNews(limit);
      if (!Array.isArray(articles) || !articles.length) {
        const fallback = fallbackNews(limit);
        if (fallback.length) {
          container.innerHTML = fallback.map(article => articleCard(article, !page)).join('');
        } else {
          renderEmpty(container, page);
        }
        return;
      }
      container.innerHTML = articles.map(article => articleCard(article, !page)).join('');
    } catch (error) {
      console.warn('B1 news unavailable:', error);
      const fallback = fallbackNews(limit);
      if (fallback.length) {
        container.innerHTML = fallback.map(article => articleCard(article, !page)).join('');
      } else {
        renderEmpty(container, page);
      }
    }
  }

  function renderArticle(article) {
    const container = document.getElementById('newsArticle');
    const state = document.getElementById('newsArticleState');
    if (!container) return;

    const title = escapeHtml(article.display_title || article.title);
    const excerpt = escapeHtml(article.display_excerpt || article.excerpt);
    const sourceIsInternal = String(article.source_name || '').toLocaleLowerCase().startsWith('b1')
      || !/^https?:\/\//i.test(String(article.source_url || ''));
    const readerText = sourceIsInternal
      ? (article.display_content || article.content || article.display_excerpt || article.excerpt)
      : (article.display_excerpt || article.excerpt);
    const content = escapeHtml(readerText);
    const image = article.image_url
      ? `<img class="news-article-image" src="${escapeHtml(article.image_url)}" alt="" onerror="this.remove()">`
      : '<div class="news-article-fallback">B1</div>';
    const href = sourceHref(article);
    const external = /^https?:\/\//i.test(href);

    document.title = `${article.display_title || article.title} — B1`;
    container.innerHTML = `
      <a class="news-article-back" href="blog.html">← ${language() === 'ru' ? 'Все новости' : 'Barcha yangiliklar'}</a>
      <article class="news-article-card">
        <div class="news-article-meta">
          <span>${escapeHtml(article.category_label || (language() === 'ru' ? 'Новости' : 'Yangiliklar'))}</span>
          <time datetime="${escapeHtml(article.published_at || '')}">${formatDate(article.published_at)}</time>
          <span>${escapeHtml(article.source_name || 'B1')}</span>
        </div>
        <h1>${title}</h1>
        ${excerpt ? `<p class="news-article-lead">${excerpt}</p>` : ''}
        ${image}
        <div class="news-article-content">${content}</div>
        <div class="news-article-source">
          <span>${language() === 'ru' ? 'Источник материала:' : 'Material manbasi:'}</span>
          ${href
            ? `<a href="${escapeHtml(href)}"${external ? ' target="_blank" rel="noopener noreferrer"' : ''}>${escapeHtml(article.source_name || (language() === 'ru' ? 'Открыть источник' : 'Manbani ochish'))} <span aria-hidden="true">${external ? '↗' : '→'}</span></a>`
            : `<span>${language() === 'ru' ? 'B1 редакция' : 'B1 tahririyati'}</span>`}
        </div>
      </article>
    `;
    if (state) state.remove();
  }

  async function renderArticlePage() {
    const container = document.getElementById('newsArticle');
    const state = document.getElementById('newsArticleState');
    if (!container) return;

    const slug = new URLSearchParams(window.location.search).get('slug');
    if (!slug) {
      if (state) state.textContent = language() === 'ru' ? 'Новость не найдена.' : 'Yangilik topilmadi.';
      return;
    }

    try {
      renderArticle(await loadArticle(slug));
    } catch (error) {
      const article = (window.B1_PUBLIC_NEWS || []).find(item => item.slug === slug);
      if (article) {
        renderArticle(article);
      } else if (state) {
        state.textContent = language() === 'ru'
          ? 'Не удалось загрузить материал. Вернитесь к списку новостей.'
          : 'Materialni yuklab bo‘lmadi. Yangiliklar ro‘yxatiga qayting.';
      }
    }
  }

  function mount() {
    const landing = document.getElementById('landingNewsGrid');
    const page = document.getElementById('newsList');
    if (landing) renderNews(landing, 3, false);
    if (page) renderNews(page, 12, true);
    renderArticlePage();
  }

  document.addEventListener('DOMContentLoaded', mount);
  window.addEventListener('b1:languagechange', mount);
})();
