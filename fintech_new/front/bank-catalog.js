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

  function bankValues(bank) {
    return [
      bank.name,
      bank.name_uz,
      bank.abbr,
      bank.type,
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
    let favicon = '';
    try {
      const website = new URL(bank.website_url);
      favicon = `https://www.google.com/s2/favicons?domain=${encodeURIComponent(website.hostname)}&sz=128`;
    } catch (error) {
      favicon = '';
    }
    const source = bank.logo_url || favicon;
    const fallback = escapeHtml(bank.logo || bank.abbr || 'B1');
    const color = escapeHtml(bank.color || '#2563eb');
    return `${source
      ? `<img src="${escapeHtml(source)}" alt="" loading="lazy" onerror="this.style.display='none';this.nextElementSibling.style.display='grid'">`
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
      allBanks = banks;
    } catch (error) {
      console.warn('Public bank catalog API unavailable. Using the published fallback.', error);
      allBanks = Array.isArray(window.B1_PUBLIC_BANKS) ? window.B1_PUBLIC_BANKS : [];
    }
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
