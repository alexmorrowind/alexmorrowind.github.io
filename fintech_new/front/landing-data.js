(function () {
  const apiBase = (window.B1_API_BASE_URL || '').replace(/\/$/, '');

  function setValue(id, value) {
    const node = document.getElementById(id);
    if (node) node.textContent = value;
  }

  function escapeHtml(value) {
    return String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function itemText(item) {
    return typeof item === 'object'
      ? (item.name || item.title || item.name_uz || item.name_ru || '')
      : String(item || '');
  }

  async function loadJson(path) {
    if (!apiBase) return null;
    const response = await fetch(`${apiBase}${path}`, { headers: { Accept: 'application/json' } });
    if (!response.ok) throw new Error(`${path} request failed: ${response.status}`);
    return response.json();
  }

  function fallbackBanks() {
    return Array.isArray(window.B1_PUBLIC_BANKS) ? window.B1_PUBLIC_BANKS : [];
  }

  function fallbackNews() {
    return Array.isArray(window.B1_PUBLIC_NEWS) ? window.B1_PUBLIC_NEWS : [];
  }

  function renderSnapshot(banks, news) {
    const values = new Set();
    let mapped = 0;
    banks.forEach(bank => {
      [...(bank.products || []), ...(bank.services || [])].forEach(item => {
        const value = itemText(item);
        if (value) values.add(value);
      });
      if (Number.isFinite(Number(bank.latitude)) && Number.isFinite(Number(bank.longitude))) mapped += 1;
    });
    setValue('landingBankCount', banks.length);
    setValue('landingProductCount', `${values.size}+`);
    setValue('landingMappedCount', mapped);
    setValue('landingNewsCount', Array.isArray(news) ? news.length : 0);
    setValue('analysisBankCount', banks.length || '—');
    setValue('analysisProductCount', values.size ? `${values.size}+` : '—');
    setValue('analysisMappedCount', mapped || '—');
    setValue('analysisNewsCount', Array.isArray(news) && news.length ? news.length : '—');
  }

  function bankType(bank) {
    if (bank?.type === 'digital') return 'Digital bank';
    if (bank?.type === 'international') return 'International';
    return 'Traditional bank';
  }

  function renderPopularBanks(banks) {
    const root = document.getElementById('popularBankGrid');
    if (!root) return;
    const list = [...banks]
      .sort((a, b) => Number(Boolean(b.isRecommended || b.is_recommended)) - Number(Boolean(a.isRecommended || a.is_recommended)))
      .slice(0, 4);
    if (!list.length) return;
    root.innerHTML = list.map(bank => {
      const name = bank.name_uz || bank.name || bank.abbr || 'Bank';
      const slug = bank.slug || bank.id || bank.abbr || '';
      const tags = [...(bank.products || []), ...(bank.services || [])].slice(0, 3);
      return `<a class="popular-bank-card" href="bank.html?slug=${encodeURIComponent(slug)}">
        <div class="popular-bank-head">
          <span class="popular-bank-logo" style="background:${escapeHtml(bank.color || '#2563eb')}">${escapeHtml(bank.abbr || name.slice(0, 3))}</span>
          <div><div class="popular-bank-name">${escapeHtml(name)}</div><div class="popular-bank-type">${escapeHtml(bankType(bank))}</div></div>
        </div>
        <div class="popular-bank-tags">${tags.map(item => `<span>${escapeHtml(itemText(item))}</span>`).join('')}</div>
      </a>`;
    }).join('');
  }

  function formatRate(value) {
    const number = Number(value);
    return Number.isFinite(number)
      ? new Intl.NumberFormat('ru-RU', { maximumFractionDigits: 2 }).format(number)
      : '—';
  }

  async function loadRates() {
    try {
      const response = await fetch('https://cbu.uz/uz/arkhiv-kursov-valyut/json/', { cache: 'no-cache' });
      if (!response.ok) throw new Error(`CBU request failed: ${response.status}`);
      const data = await response.json();
      const rates = {};
      data.forEach(item => {
        const nominal = Number(item.Nominal) || 1;
        const rate = Number.parseFloat(item.Rate);
        if (item.Ccy && Number.isFinite(rate)) rates[item.Ccy] = rate / nominal;
      });
      ['USD', 'EUR', 'RUB', 'GBP'].forEach(code => setValue(`rate${code}`, formatRate(rates[code])));
      ['USD', 'EUR', 'RUB', 'GBP'].forEach(code => setValue(`rate${code}Delta`, 'CBU · live'));
    } catch (error) {
      console.warn('B1 currency board unavailable:', error);
      ['USD', 'EUR', 'RUB', 'GBP'].forEach(code => setValue(`rate${code}Delta`, 'CBU · unavailable'));
    }
  }

  async function loadSnapshot() {
    try {
      const [banksResponse, newsResponse] = await Promise.all([
        loadJson('/banks/'),
        loadJson('/news/?limit=30'),
      ]);
      const banks = Array.isArray(banksResponse) && banksResponse.length ? banksResponse : fallbackBanks();
      const news = Array.isArray(newsResponse) && newsResponse.length ? newsResponse : fallbackNews();
      renderSnapshot(banks, news);
      renderPopularBanks(banks);
    } catch (error) {
      console.warn('B1 landing snapshot unavailable:', error);
      const banks = fallbackBanks();
      const news = fallbackNews();
      renderSnapshot(banks, news);
      renderPopularBanks(banks);
    }
  }

  document.addEventListener('DOMContentLoaded', () => {
    loadSnapshot();
    loadRates();
  });
})();
