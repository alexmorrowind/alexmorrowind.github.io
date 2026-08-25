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

  function articleCard(article, compact) {
    const title = escapeHtml(article.display_title || article.title);
    const excerpt = escapeHtml(article.display_excerpt || article.excerpt);
    const image = article.image_url
      ? `<img src="${escapeHtml(article.image_url)}" alt="" loading="lazy" onerror="this.parentElement.classList.add('news-media-empty');this.remove()">`
      : '';
    const source = escapeHtml(article.source_name || 'B1');
    const href = article.source_url ? escapeHtml(article.source_url) : '#';
    const action = article.source_url
      ? `<a class="news-card-link" href="${href}" target="_blank" rel="noopener noreferrer">${language() === 'ru' ? 'Читать источник' : "Manbani o'qish"} <span aria-hidden="true">↗</span></a>`
      : '';

    return `
      <article class="news-card${compact ? ' news-card-compact' : ''}">
        <a class="news-card-media${image ? '' : ' news-media-empty'}" href="${href}" ${article.source_url ? 'target="_blank" rel="noopener noreferrer"' : ''}>
          ${image || '<span class="news-media-mark">B1</span>'}
        </a>
        <div class="news-card-body">
          <div class="news-card-meta">
            <span>${escapeHtml(article.category_label || (language() === 'ru' ? 'Новости' : 'Yangiliklar'))}</span>
            <time datetime="${escapeHtml(article.published_at || '')}">${formatDate(article.published_at)}</time>
          </div>
          <h3>${title}</h3>
          ${excerpt ? `<p>${excerpt}</p>` : ''}
          <div class="news-card-footer">
            <span class="news-source">${source}</span>
            ${action}
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
        renderEmpty(container, page);
        return;
      }
      container.innerHTML = articles.map(article => articleCard(article, !page)).join('');
    } catch (error) {
      console.warn('B1 news unavailable:', error);
      renderEmpty(container, page);
    }
  }

  function mount() {
    const landing = document.getElementById('landingNewsGrid');
    const page = document.getElementById('newsList');
    if (landing) renderNews(landing, 3, false);
    if (page) renderNews(page, 12, true);
  }

  document.addEventListener('DOMContentLoaded', mount);
  window.addEventListener('b1:languagechange', mount);
})();
