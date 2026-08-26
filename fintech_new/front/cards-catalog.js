(function () {
  const params = new URLSearchParams(window.location.search);

  function language() {
    return localStorage.getItem('bpay_lang') || 'uz';
  }

  function text(uz, ru) {
    return language() === 'ru' ? ru : uz;
  }

  function escapeHtml(value) {
    return String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function safeUrl(value) {
    try {
      const url = new URL(value);
      return ['http:', 'https:'].includes(url.protocol) ? url.href : '';
    } catch {
      return '';
    }
  }

  function hostFromUrl(value) {
    try {
      return new URL(value).hostname.replace(/^www\./, '');
    } catch {
      return '';
    }
  }

  function banks() {
    return Array.isArray(window.B1_PUBLIC_BANKS) ? window.B1_PUBLIC_BANKS : [];
  }

  function cards() {
    return Array.isArray(window.B1_PUBLIC_CARD_PRODUCTS) ? window.B1_PUBLIC_CARD_PRODUCTS : [];
  }

  function findBank(key) {
    return banks().find(bank =>
      String(bank.id) === String(key) ||
      String(bank.slug) === String(key) ||
      String(bank.abbr).toLowerCase() === String(key).toLowerCase()
    );
  }

  function findCard(key) {
    return cards().find(card => String(card.id) === String(key));
  }

  function faviconUrl(bank) {
    const website = safeUrl(bank?.website_url);
    if (!website) return '';
    const host = hostFromUrl(website);
    return host ? `https://www.google.com/s2/favicons?domain=${encodeURIComponent(host)}&sz=128` : '';
  }

  function logoSources(bank) {
    const website = safeUrl(bank?.website_url);
    const host = hostFromUrl(website);
    return [
      bank?.logo_url,
      bank?.logoUrl,
      host ? `https://${host}/favicon.ico` : '',
      faviconUrl(bank),
    ].map(safeUrl).filter((value, index, list) => value && list.indexOf(value) === index);
  }

  function bindLogoFallbacks(root) {
    if (!root) return;
    root.querySelectorAll('img[data-logo-sources]').forEach(img => {
      img.addEventListener('error', () => {
        let sources = [];
        try {
          sources = JSON.parse(img.dataset.logoSources || '[]');
        } catch {
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

  function logoMarkup(bank, className) {
    const sources = logoSources(bank);
    const source = sources[0] || '';
    const fallback = escapeHtml(bank?.logo || bank?.abbr || 'B1');
    const color = escapeHtml(bank?.color || '#2563eb');
    return `
      <span class="${className}" style="background:${color}">
        ${source ? `<img src="${escapeHtml(source)}" alt="${escapeHtml(bank?.name || 'Bank')} logo" loading="lazy" data-logo-index="0" data-logo-sources="${escapeHtml(JSON.stringify(sources))}">` : ''}
        <span style="display:${source ? 'none' : 'grid'}">${fallback}</span>
      </span>
    `;
  }

  function bankType(bank) {
    if (bank?.type === 'digital') return text('Raqamli bank', 'Цифровой банк');
    if (bank?.type === 'international') return text('Xalqaro bank', 'Международный банк');
    return text("An'anaviy bank", 'Традиционный банк');
  }

  function cardType(card) {
    const labels = {
      debit: ['Debet karta', 'Дебетовая карта'],
      credit: ['Kredit karta', 'Кредитная карта'],
      virtual: ['Virtual karta', 'Виртуальная карта'],
      installment: ['Muddatli to‘lov', 'Рассрочка'],
      international: ['Xalqaro karta', 'Международная карта'],
    };
    const label = labels[card?.type] || ['Karta', 'Карта'];
    return text(label[0], label[1]);
  }

  function localized(card, key) {
    if (language() === 'ru') return card?.[key] || card?.description || '';
    return card?.[`${key}_uz`] || card?.[key] || '';
  }

  function renderBankDirectory() {
    const root = document.getElementById('cardsBankGrid');
    if (!root) return;
    const search = String(document.getElementById('cardsBankSearch')?.value || '').trim().toLowerCase();
    const filter = document.querySelector('[data-card-filter].active')?.dataset.cardFilter || 'all';
    const list = banks().filter(bank => {
      const values = [bank.name, bank.name_uz, bank.abbr, bank.type, ...(bank.products || [])].join(' ').toLowerCase();
      if (search && !values.includes(search)) return false;
      if (filter === 'recommended') return Boolean(bank.isRecommended || bank.is_recommended);
      if (filter === 'digital') return bank.type === 'digital';
      return true;
    });

    root.innerHTML = list.length ? list.map(bank => {
      const bankCards = cards().filter(card => String(card.bankId) === String(bank.id));
      const href = `bank-cards.html?bank=${encodeURIComponent(bank.slug || bank.id)}`;
      return `
        <a class="cards-bank-card" href="${href}">
          <div class="cards-bank-card-head">
            ${logoMarkup(bank, 'cards-bank-logo')}
            <span class="cards-bank-type">${escapeHtml(bankType(bank))}</span>
          </div>
          <div class="cards-bank-name">${escapeHtml(bank.name_uz || bank.name)}</div>
          <div class="cards-bank-subtitle">${escapeHtml(bank.name)}</div>
          <div class="cards-bank-tags">
            <span class="cards-tag">${bankCards.length} ${text('karta mahsuloti', 'карточных продукта')}</span>
            ${(bank.products || []).slice(0, 2).map(item => `<span class="cards-tag">${escapeHtml(item)}</span>`).join('')}
          </div>
          <span class="cards-bank-link">${text('Bank kartalarini ko‘rish', 'Смотреть карты банка')} <span aria-hidden="true">→</span></span>
        </a>
      `;
    }).join('') : `<div class="cards-state">${text('Bank topilmadi.', 'Банк не найден.')}</div>`;
    bindLogoFallbacks(root);
  }

  function renderBankCardsPage() {
    const root = document.getElementById('bankCardsRoot');
    if (!root) return;
    const bank = findBank(params.get('bank'));
    if (!bank) {
      root.innerHTML = `<div class="cards-state">${text('Bank topilmadi.', 'Банк не найден.')}</div>`;
      return;
    }

    const bankCards = cards().filter(card => String(card.bankId) === String(bank.id));
    document.title = `${bank.name} — kartalar — B1`;
    const website = safeUrl(bank.website_url);
    document.getElementById('bankCardsTitle').textContent = text(`${bank.name_uz || bank.name} kartalari`, `${bank.name} — карты`);
    document.getElementById('bankCardsDescription').textContent = language() === 'ru'
      ? (bank.description || 'Карточные продукты банка собраны в одном каталоге.')
      : (bank.description_uz || bank.description || 'Bankning karta mahsulotlari bitta katalogda jamlandi.');
    document.getElementById('bankCardsBrand').innerHTML = logoMarkup(bank, 'cards-detail-bank-logo');
    bindLogoFallbacks(document.getElementById('bankCardsBrand'));
    const official = document.getElementById('bankCardsOfficial');
    if (official && website) {
      official.href = website;
      official.hidden = false;
    }

    root.innerHTML = bankCards.length ? bankCards.map(card => `
      <a class="cards-product-card" href="card-detail.html?id=${encodeURIComponent(card.id)}">
        <div class="cards-product-card-head">
          <span class="cards-product-type">${escapeHtml(card.network || 'B1')}</span>
          <span class="cards-tag">${escapeHtml(cardType(card))}</span>
        </div>
        <div class="cards-product-name">${escapeHtml(card.name)}</div>
        <div class="cards-product-description">${escapeHtml(localized(card, 'description'))}</div>
        <div class="cards-product-tags">
          ${(card.features || []).slice(0, 3).map(feature => `<span class="cards-tag">${escapeHtml(feature)}</span>`).join('')}
        </div>
        <span class="cards-product-link">${text('Batafsil ko‘rish', 'Подробнее')} <span aria-hidden="true">→</span></span>
      </a>
    `).join('') : `<div class="cards-state">${text('Bu bank uchun karta ma’lumoti hali kiritilmagan.', 'Для этого банка карточные продукты пока не добавлены.')}</div>`;
  }

  function renderCardDetailPage() {
    const root = document.getElementById('cardDetailRoot');
    if (!root) return;
    const card = findCard(params.get('id'));
    const bank = card && findBank(card.bankId);
    if (!card || !bank) {
      root.innerHTML = `<div class="cards-state">${text('Karta topilmadi.', 'Карта не найдена.')}</div>`;
      return;
    }

    const website = safeUrl(card.official_url || bank.website_url);
    document.title = `${card.name} — ${bank.name} — B1`;
    document.getElementById('cardDetailTitle').textContent = card.name;
    document.getElementById('cardDetailBankName').textContent = bank.name;
    document.getElementById('cardDetailType').textContent = cardType(card);
    document.getElementById('cardDetailNetwork').textContent = card.network || 'B1';
    document.getElementById('cardDetailAvailability').textContent = text('Bank bilan tekshiriladi', 'Уточняется у банка');
    document.getElementById('cardDetailDescription').textContent = localized(card, 'description');
    document.getElementById('cardDetailBankLogo').innerHTML = logoMarkup(bank, 'cards-detail-bank-logo');
    bindLogoFallbacks(document.getElementById('cardDetailBankLogo'));
    document.getElementById('cardDetailFeatures').innerHTML = (card.features || []).map(feature => `<li>${escapeHtml(feature)}</li>`).join('');
    const official = document.getElementById('cardDetailOfficial');
    if (official && website) {
      official.href = website;
      official.hidden = false;
    }
  }

  function mount() {
    renderBankDirectory();
    renderBankCardsPage();
    renderCardDetailPage();

    const search = document.getElementById('cardsBankSearch');
    if (search) search.addEventListener('input', renderBankDirectory);
    document.querySelectorAll('[data-card-filter]').forEach(button => {
      button.addEventListener('click', () => {
        document.querySelectorAll('[data-card-filter]').forEach(item => item.classList.remove('active'));
        button.classList.add('active');
        renderBankDirectory();
      });
    });
  }

  document.addEventListener('DOMContentLoaded', mount);
  window.addEventListener('b1:languagechange', () => {
    renderBankDirectory();
    renderBankCardsPage();
    renderCardDetailPage();
  });
})();
