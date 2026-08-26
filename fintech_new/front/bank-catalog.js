(function () {
  const apiBase = (window.B1_API_BASE_URL || '').replace(/\/$/, '');
  let allBanks = [];
  let activeFilter = new URLSearchParams(window.location.search).get('service') || 'all';

  const filters = {
    all: { uz: 'Barchasi', ru: 'Все', keywords: [] },
    recommended: { uz: 'Top', ru: 'Топ', keywords: [] },
    digital: { uz: 'Raqamli', ru: 'Цифровые', keywords: [] },
    credits: { uz: 'Kreditlar', ru: 'Кредиты', keywords: ['kredit', 'credit', 'qarz', 'loan', 'mikro'] },
    cards: { uz: 'Kartalar', ru: 'Карты', keywords: ['karta', 'card', 'visa', 'mastercard', 'humo', 'uzcard'] },
    mortgage: { uz: 'Ipoteka', ru: 'Ипотека', keywords: ['ipoteka', 'ипотек', 'mortgage'] },
    business: { uz: 'Biznes', ru: 'Бизнес', keywords: ['biznes', 'business', 'korpor', 'предpri', 'агро'] },
    deposits: { uz: 'Depozitlar', ru: 'Депозиты', keywords: ['depozit', 'deposit', 'omonat', 'вклад'] },
    insurance: { uz: 'Sug‘urta', ru: 'Страхование', keywords: ['sug', 'insurance', 'страх'] },
  };

  function escapeHtml(value) {
    return String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function language() {
    return localStorage.getItem('bpay_lang') || 'uz';
  }

  function text(uz, ru) {
    return language() === 'ru' ? ru : uz;
  }

  function itemText(item) {
    return typeof item === 'object'
      ? (item.name || item.title || item.name_uz || item.name_ru || '')
      : String(item || '');
  }

  function safeUrl(value) {
    try {
      const url = new URL(value);
      return ['http:', 'https:'].includes(url.protocol) ? url.href : '';
    } catch (error) {
      return '';
    }
  }

  function hostFromUrl(value) {
    try {
      return new URL(value).hostname.replace(/^www\./, '');
    } catch (error) {
      return '';
    }
  }

  function logoSources(bank) {
    const website = safeUrl(bank.website_url);
    const host = hostFromUrl(website);
    return [
      bank.logo_url,
      bank.logoUrl,
      host ? `https://${host}/favicon.ico` : '',
      host ? `https://www.google.com/s2/favicons?domain=${encodeURIComponent(host)}&sz=128` : '',
    ].map(safeUrl).filter((value, index, list) => value && list.indexOf(value) === index);
  }

  function bindLogoFallbacks(root) {
    root.querySelectorAll('img[data-logo-sources]').forEach(img => {
      img.addEventListener('error', () => {
        let sources = [];
        try {
          sources = JSON.parse(img.dataset.logoSources || '[]');
        } catch (error) {
          sources = [];
        }
        const nextIndex = Number(img.dataset.logoIndex || 0) + 1;
        if (sources[nextIndex]) {
          img.dataset.logoIndex = String(nextIndex);
          img.src = sources[nextIndex];
          return;
        }
        img.style.display = 'none';
        if (img.nextElementSibling) img.nextElementSibling.style.display = 'grid';
      });
    });
  }

  function normalizeBank(bank) {
    return {
      ...bank,
      id: bank.id ?? bank.slug ?? bank.abbr,
      name: bank.name || bank.name_uz || bank.abbr || 'B1 Bank',
      name_uz: bank.name_uz || bank.name || bank.abbr || 'B1 Bank',
      abbr: bank.abbr || bank.logo || 'B1',
      type: bank.type || (bank.ownership_type === 'foreign' ? 'international' : 'traditional'),
      products: Array.isArray(bank.products) ? bank.products : [],
      services: Array.isArray(bank.services) ? bank.services : [],
      isRecommended: Boolean(bank.isRecommended || bank.is_recommended),
    };
  }

  function normalizeBanks(list) {
    return Array.isArray(list) ? list.map(normalizeBank) : [];
  }

  function bankValues(bank) {
    return [
      bank.name,
      bank.name_uz,
      bank.abbr,
      bank.type,
      bank.ownership_type,
      bank.description,
      bank.description_uz,
      ...(bank.products || []).map(itemText),
      ...(bank.services || []).map(itemText),
    ].filter(Boolean).join(' ').toLocaleLowerCase();
  }

  function bankType(bank) {
    if (bank.type === 'international') return text('Xalqaro bank', 'Международный банк');
    if (bank.type === 'digital') return text('Raqamli bank', 'Цифровой банк');
    return text("An'anaviy bank", 'Традиционный банк');
  }

  function bankLogo(bank) {
    const sources = logoSources(bank);
    const source = sources[0] || '';
    const fallback = escapeHtml(bank.logo || bank.abbr || 'B1');
    const color = escapeHtml(bank.color || '#2563eb');
    return `${source
      ? `<img src="${escapeHtml(source)}" alt="${escapeHtml(bank.name)} logo" loading="lazy" data-logo-index="0" data-logo-sources="${escapeHtml(JSON.stringify(sources))}">`
      : ''}<span style="display:${source ? 'none' : 'grid'};background:${color}">${fallback}</span>`;
  }

  function productTags(bank) {
    const items = [...(bank.products || []), ...(bank.services || [])]
      .map(itemText)
      .filter(Boolean)
      .slice(0, 3);
    return items.length
      ? `<div class="bank-tags">${items.map(item => `<span>${escapeHtml(item)}</span>`).join('')}</div>`
      : '';
  }

  function matchesFilter(bank, filter, query) {
    const normalized = bankValues(bank);
    if (query && !normalized.includes(query)) return false;
    if (filter === 'all') return true;
    if (filter === 'recommended') return Boolean(bank.isRecommended || bank.is_recommended);
    if (filter === 'digital') return bank.type === 'digital';
    return filters[filter]?.keywords.some(keyword => normalized.includes(keyword)) || false;
  }

  function currentBanks() {
    const query = String(document.getElementById('bankSearch')?.value || '').trim().toLocaleLowerCase();
    return allBanks.filter(bank => matchesFilter(bank, activeFilter, query));
  }

  function renderBanks() {
    const grid = document.querySelector('.banks-grid');
    const count = document.getElementById('bankCount');
    const total = document.getElementById('bankTotalCount');
    const empty = document.getElementById('bankCatalogEmpty');
    if (!grid) return;

    const banks = currentBanks();
    if (count) count.textContent = banks.length;
    if (total) total.textContent = allBanks.length;

    grid.innerHTML = banks.map(bank => {
      const query = new URLSearchParams({ id: bank.id, slug: bank.slug || bank.abbr || '' });
      if (activeFilter !== 'all' && activeFilter !== 'recommended' && activeFilter !== 'digital') {
        query.set('service', activeFilter);
      }
      return `
      <a class="bank-card" href="bank.html?${query.toString()}" aria-label="${escapeHtml(bank.name)}">
        <div class="bank-card-head">
          <div class="bank-logo" style="background:${escapeHtml(bank.color || '#2563eb')}">${bankLogo(bank)}</div>
          <span class="bank-catalog-type">${escapeHtml(bankType(bank))}</span>
        </div>
        <div class="bank-abbr">${escapeHtml(bank.name_uz || bank.abbr || bank.name)}</div>
        <div class="bank-name">${escapeHtml(bank.name)}</div>
        ${productTags(bank)}
        <span class="bank-catalog-more">${text("Profil va rasmiy sayt", 'Профиль и официальный сайт')} <span aria-hidden="true">→</span></span>
      </a>
    `;
    }).join('');
    bindLogoFallbacks(grid);

    if (empty) empty.hidden = Boolean(banks.length);
  }

  function updateFilterButtons() {
    document.querySelectorAll('[data-bank-filter]').forEach(button => {
      const active = button.dataset.bankFilter === activeFilter;
      button.classList.toggle('active', active);
      button.setAttribute('aria-pressed', active ? 'true' : 'false');
      const label = filters[button.dataset.bankFilter];
      if (label) button.textContent = label[language()];
    });
  }

  function setFilter(filter) {
    activeFilter = filters[filter] ? filter : 'all';
    const url = new URL(window.location.href);
    if (activeFilter === 'all') url.searchParams.delete('service');
    else url.searchParams.set('service', activeFilter);
    window.history.replaceState({}, '', url);
    updateFilterButtons();
    renderBanks();
  }

  async function loadBanks() {
    const grid = document.querySelector('.banks-grid');
    if (grid) grid.innerHTML = `<div class="bank-catalog-state">${text('Banklar yuklanmoqda...', 'Загрузка банков...')}</div>`;

    try {
      if (!apiBase) throw new Error('API base is not configured');
      const response = await fetch(`${apiBase}/banks/`, { headers: { Accept: 'application/json' } });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const banks = await response.json();
      if (!Array.isArray(banks) || !banks.length) throw new Error('Empty bank catalogue');
      allBanks = normalizeBanks(banks);
    } catch (error) {
      console.warn('Public bank catalog API unavailable. Using the published fallback.', error);
      allBanks = normalizeBanks(window.B1_PUBLIC_BANKS);
    }
    if (!allBanks.length) allBanks = normalizeBanks(window.B1_PUBLIC_BANKS);
    renderBanks();
  }

  function mount() {
    const search = document.getElementById('bankSearch');
    if (search) search.addEventListener('input', renderBanks);
    document.querySelectorAll('[data-bank-filter]').forEach(button => {
      button.addEventListener('click', () => setFilter(button.dataset.bankFilter));
    });
    updateFilterButtons();
    loadBanks();
  }

  document.addEventListener('DOMContentLoaded', mount);
  window.addEventListener('b1:languagechange', () => {
    const search = document.getElementById('bankSearch');
    if (search) {
      search.placeholder = language() === 'ru' ? 'Найти банк или услугу' : 'Bank yoki xizmatni qidiring';
    }
    updateFilterButtons();
    renderBanks();
  });
})();
