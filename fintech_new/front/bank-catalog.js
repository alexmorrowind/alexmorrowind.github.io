(function () {
  const apiBase = (window.B1_API_BASE_URL || '').replace(/\/$/, '');
  const mapCenter = [41.3111, 69.2797];
  let bankMap = null;
  let bankMarkers = null;

  function escapeHtml(value) {
    return String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function label(value, uz, ru) {
    return localStorage.getItem('bpay_lang') === 'ru' ? ru : uz;
  }

  function bankType(bank) {
    if (bank.type === 'international') return label('', 'Xalqaro bank', 'Международный банк');
    if (bank.type === 'digital') return label('', 'Raqamli bank', 'Цифровой банк');
    return label('', "An'anaviy bank", 'Традиционный банк');
  }

  function itemText(item) {
    return typeof item === 'object' ? (item.name || item.title || item.name_uz || '') : item;
  }

  function hasCoordinates(bank) {
    return Number.isFinite(Number(bank.latitude)) && Number.isFinite(Number(bank.longitude));
  }

  function mapText(uz, ru) {
    return localStorage.getItem('bpay_lang') === 'ru' ? ru : uz;
  }

  function fitAllBanks() {
    if (!bankMap || !bankMarkers) return;
    const layers = bankMarkers.getLayers();
    if (layers.length > 1) {
      const bounds = window.L.featureGroup(layers).getBounds();
      bankMap.fitBounds(bounds, { padding: [28, 28], maxZoom: 13 });
    } else {
      bankMap.setView(mapCenter, 11);
    }
  }

  function renderBankMap(banks) {
    const container = document.getElementById('bankMap');
    if (!container) return;
    if (!window.L) {
      container.innerHTML = `<div class="bank-map-empty">${mapText(
        'Xarita yuklanmadi.',
        'Карта не загрузилась.'
      )}</div>`;
      return;
    }

    if (!bankMap) {
      bankMap = window.L.map(container).setView(mapCenter, 11);
      window.L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '&copy; OpenStreetMap contributors',
      }).addTo(bankMap);
      bankMarkers = window.L.layerGroup().addTo(bankMap);
      document.getElementById('fitBankMap')?.addEventListener('click', fitAllBanks);
    } else {
      bankMarkers.clearLayers();
    }

    const mappedBanks = banks.filter(hasCoordinates);
    if (!mappedBanks.length) {
      container.innerHTML = `<div class="bank-map-empty">${mapText(
        'Koordinatalar hozircha mavjud emas.',
        'Координаты банков пока не указаны.'
      )}</div>`;
      return;
    }

    mappedBanks.forEach(bank => {
      const marker = window.L.marker([Number(bank.latitude), Number(bank.longitude)]);
      marker.bindPopup(`
        <div class="bank-map-popup-name">${escapeHtml(bank.name)}</div>
        <div class="bank-map-popup-address">${escapeHtml(bank.address || mapText("Manzil ko'rsatilmagan", 'Адрес не указан'))}</div>
      `);
      marker.addTo(bankMarkers);
    });
    fitAllBanks();
    window.setTimeout(() => bankMap.invalidateSize(), 0);
  }

  function openDetails(bank) {
    const products = (bank.products || []).concat(bank.services || []);
    const sources = bank.officialSources || bank.source_urls || [];
    const modal = document.createElement('div');
    modal.className = 'bank-catalog-modal';
    modal.innerHTML = `
      <div class="bank-catalog-dialog" role="dialog" aria-modal="true">
        <button class="bank-catalog-close" type="button" aria-label="Close">×</button>
        <div class="bank-catalog-dialog-head">
          <div class="bank-logo" style="background:${escapeHtml(bank.color || '#2563eb')}">${escapeHtml(bank.logo || bank.abbr)}</div>
          <div>
            <h2>${escapeHtml(bank.name)}</h2>
            <div class="bank-catalog-muted">${escapeHtml(bankType(bank))}</div>
          </div>
        </div>
        <p class="bank-catalog-description">${escapeHtml(
          localStorage.getItem('bpay_lang') === 'ru'
            ? (bank.description || '')
            : (bank.description_uz || bank.description || '')
        )}</p>
        <div class="bank-catalog-facts">
          <div><span>${label('', 'Litsenziya', 'Лицензия')}</span><strong>${escapeHtml(bank.license_number || '—')}</strong></div>
          <div><span>${label('', 'Mulkchilik turi', 'Форма собственности')}</span><strong>${escapeHtml(bank.ownership_type || '—')}</strong></div>
          <div><span>${label('', 'Manzil', 'Адрес')}</span><strong>${escapeHtml(bank.address || '—')}</strong></div>
          <div><span>${label('', 'Maʼlumot sanasi', 'Дата проверки')}</span><strong>${escapeHtml(bank.dataAsOf || bank.data_as_of || '—')}</strong></div>
        </div>
        <h3>${label('', 'Mahsulotlar va xizmatlar', 'Продукты и сервисы')}</h3>
        <div class="bank-catalog-tags">${products.map(item => `<span>${escapeHtml(itemText(item))}</span>`).join('') || '<span>—</span>'}</div>
        <h3>${label('', 'Rasmiy manbalar', 'Официальные источники')}</h3>
        <div class="bank-catalog-sources">${sources.map(url => `<a href="${escapeHtml(url)}" target="_blank" rel="noopener noreferrer">${escapeHtml(url)}</a>`).join('') || '<span>—</span>'}</div>
        <div class="bank-catalog-actions">
          ${bank.website_url ? `<a class="bank-catalog-primary" href="${escapeHtml(bank.website_url)}" target="_blank" rel="noopener noreferrer">${label('', 'Rasmiy sayt', 'Официальный сайт')}</a>` : ''}
          <button class="bank-catalog-secondary" type="button">${label('', 'Yopish', 'Закрыть')}</button>
        </div>
      </div>
    `;
    const close = () => modal.remove();
    modal.addEventListener('click', event => {
      if (event.target === modal || event.target.closest('.bank-catalog-close') || event.target.closest('.bank-catalog-secondary')) close();
    });
    document.body.appendChild(modal);
  }

  function renderBanks(banks) {
    const grid = document.querySelector('.banks-grid');
    if (!grid) return;
    grid.innerHTML = banks.map(bank => `
      <article class="bank-card" tabindex="0" data-bank-id="${escapeHtml(bank.id)}">
        <div class="bank-logo" style="background:${escapeHtml(bank.color || '#2563eb')}">${escapeHtml(bank.logo || bank.abbr)}</div>
        <div class="bank-abbr">${escapeHtml(bank.name_uz || bank.name)}</div>
        <div class="bank-name">${escapeHtml(bank.name)}</div>
        <div class="bank-catalog-type">${escapeHtml(bankType(bank))}</div>
        <button type="button" class="bank-catalog-more">${label('', 'Batafsil', 'Подробнее')}</button>
      </article>
    `).join('');
    grid.querySelectorAll('[data-bank-id]').forEach(card => {
      const bank = banks.find(item => String(item.id) === card.dataset.bankId);
      const open = () => bank && openDetails(bank);
      card.addEventListener('click', open);
      card.addEventListener('keydown', event => {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          open();
        }
      });
    });
  }

  async function loadBanks() {
    const grid = document.querySelector('.banks-grid');
    if (grid) {
      grid.innerHTML = `<div style="grid-column:1/-1;padding:28px;text-align:center;color:#64748b">Загрузка банков...</div>`;
    }
    if (!apiBase) return;
    try {
      const response = await fetch(`${apiBase}/banks/`);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const banks = await response.json();
      if (Array.isArray(banks) && banks.length) {
        renderBankMap(banks);
        renderBanks(banks);
      }
    } catch (error) {
      console.warn('Public bank catalog API unavailable.', error);
      renderBankMap([]);
      if (grid) {
        grid.innerHTML = `<div style="grid-column:1/-1;padding:28px;text-align:center;color:#64748b">Каталог временно недоступен</div>`;
      }
    }
  }

  document.addEventListener('DOMContentLoaded', loadBanks);
  window.addEventListener('b1:languagechange', loadBanks);
})();
