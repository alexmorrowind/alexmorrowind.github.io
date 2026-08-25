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

  async function loadSnapshot() {
    if (!apiBase) return;
    try {
      const [banksResponse, newsResponse] = await Promise.all([
        fetch(`${apiBase}/banks/`, { headers: { Accept: 'application/json' } }),
        fetch(`${apiBase}/news/?limit=30`, { headers: { Accept: 'application/json' } }),
      ]);
      if (!banksResponse.ok) throw new Error(`Banks request failed: ${banksResponse.status}`);
      const banks = await banksResponse.json();
      const news = newsResponse.ok ? await newsResponse.json() : [];
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
    } catch (error) {
      console.warn('B1 landing snapshot unavailable:', error);
    }
  }

  document.addEventListener('DOMContentLoaded', loadSnapshot);
})();
