(function () {
  const apiBase = (window.B1_API_BASE_URL || '').replace(/\/$/, '');

  function setValue(id, value) {
    const node = document.getElementById(id);
    if (node) node.textContent = value;
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
    } catch (error) {
      console.warn('B1 landing snapshot unavailable:', error);
      renderSnapshot(fallbackBanks(), fallbackNews());
    }
  }

  document.addEventListener('DOMContentLoaded', loadSnapshot);
})();
