(function () {
  const apiBase = (window.B1_API_BASE_URL || '').replace(/\/$/, '');

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

  function bankType(bank) {
    if (bank.type === 'international') return text('Xalqaro bank', 'Международный банк');
    if (bank.type === 'digital') return text('Raqamli bank', 'Цифровой банк');
    return text("An'anaviy bank", 'Традиционный банк');
  }

  function bankLogo(bank) {
    if (bank.logo_url) {
      return `<img src="${escapeHtml(bank.logo_url)}" alt="" loading="lazy" onerror="this.parentElement.classList.add('bank-logo-fallback');this.remove()">`;
    }
    return escapeHtml(bank.logo || bank.abbr || 'B1');
  }

  function renderBanks(banks) {
    const grid = document.querySelector('.banks-grid');
    const count = document.getElementById('bankCount');
    if (!grid) return;

    if (count) count.textContent = banks.length;
    grid.innerHTML = banks.map(bank => `
      <a class="bank-card" href="bank.html?id=${encodeURIComponent(bank.id)}" aria-label="${escapeHtml(bank.name)}">
        <div class="bank-logo" style="background:${escapeHtml(bank.color || '#2563eb')}">${bankLogo(bank)}</div>
        <div class="bank-abbr">${escapeHtml(bank.name_uz || bank.name)}</div>
        <div class="bank-name">${escapeHtml(bank.name)}</div>
        <div class="bank-catalog-type">${escapeHtml(bankType(bank))}</div>
        <span class="bank-catalog-more">${text("Profilni ochish", 'Открыть профиль')} <span aria-hidden="true">→</span></span>
      </a>
    `).join('');
  }

  async function loadBanks() {
    const grid = document.querySelector('.banks-grid');
    if (grid) {
      grid.innerHTML = `<div class="bank-catalog-state">${text('Banklar yuklanmoqda...', 'Загрузка банков...')}</div>`;
    }
    if (!apiBase) return;

    try {
      const response = await fetch(`${apiBase}/banks/`, { headers: { Accept: 'application/json' } });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const banks = await response.json();
      if (Array.isArray(banks) && banks.length) {
        renderBanks(banks);
      } else if (grid) {
        grid.innerHTML = `<div class="bank-catalog-state">${text('Banklar topilmadi.', 'Банки пока не найдены.')}</div>`;
      }
    } catch (error) {
      console.warn('Public bank catalog API unavailable.', error);
      if (grid) {
        grid.innerHTML = `<div class="bank-catalog-state">${text(
          'Katalog vaqtincha mavjud emas.',
          'Каталог временно недоступен.'
        )}</div>`;
      }
    }
  }

  document.addEventListener('DOMContentLoaded', loadBanks);
  window.addEventListener('b1:languagechange', loadBanks);
})();
