(function () {
  const params = new URLSearchParams(window.location.search);
  const state = {
    type: params.get('type') || 'auto',
    amount: Number(params.get('amount') || 25000000),
    term: Number(params.get('term') || 36),
    downPayment: Number(params.get('down') || 0),
    income: params.get('income') || 'any',
    sort: 'popular',
  };

  if (!['auto', 'micro', 'education', 'overdraft', 'consumer'].includes(state.type)) {
    state.type = 'consumer';
  }

  const typeLabels = {
    auto: { uz: 'Avtokredit', ru: 'Автокредит' },
    micro: { uz: 'Mikroqarz', ru: 'Микрозайм' },
    education: { uz: "Ta'lim krediti", ru: 'Кредит на образование' },
    overdraft: { uz: 'Overdraft', ru: 'Овердрафт' },
    consumer: { uz: "Iste'mol krediti", ru: 'Потребительский кредит' },
  };

  const offers = [
    { id: 'ipak-auto-premium', bank: 'ipak-yuli', type: 'auto', uz: 'Birlamchi bozor avtokrediti', ru: 'Автокредит на новый автомобиль', rate: 20.9, termMin: 12, termMax: 60, amountMin: 1000000, amountMax: 800000000, downPayment: 25, income: true, channel: 'bank', popularity: 98 },
    { id: 'hamkor-auto-kia', bank: 'hamkorbank', type: 'auto', uz: 'Auto KIA Sonet', ru: 'Авто KIA Sonet', rate: 18, rateTo: 22, termMin: 36, termMax: 60, amountMin: 20000000, amountMax: 350000000, downPayment: 20, income: true, channel: 'bank', popularity: 94 },
    { id: 'asaka-auto', bank: 'asakabank', type: 'auto', uz: 'Avtomobil uchun kredit', ru: 'Кредит на автомобиль', rate: 21.5, termMin: 12, termMax: 60, amountMin: 10000000, amountMax: 450000000, downPayment: 25, income: true, channel: 'bank', popularity: 90 },
    { id: 'sqb-auto', bank: 'sqb', type: 'auto', uz: 'SQB avtokredit', ru: 'Автокредит SQB', rate: 23, termMin: 12, termMax: 60, amountMin: 15000000, amountMax: 500000000, downPayment: 20, income: true, channel: 'bank', popularity: 86 },

    { id: 'uzum-micro-card', bank: 'uzum-bank', type: 'micro', uz: 'Uzum kartaga mikroqarz', ru: 'Микрозайм на карту Uzum', rate: 28, termMin: 3, termMax: 12, amountMin: 500000, amountMax: 25000000, downPayment: 0, income: false, channel: 'online', popularity: 97 },
    { id: 'anor-micro', bank: 'anorbank', type: 'micro', uz: 'Onlayn mikroqarz', ru: 'Онлайн-микрозайм', rate: 32, termMin: 3, termMax: 24, amountMin: 500000, amountMax: 50000000, downPayment: 0, income: false, channel: 'online', popularity: 91 },
    { id: 'open-micro', bank: 'openbank', type: 'micro', uz: 'Tezkor mikroqarz', ru: 'Быстрый микрозайм', rate: 30, termMin: 3, termMax: 18, amountMin: 500000, amountMax: 30000000, downPayment: 0, income: false, channel: 'online', popularity: 88 },
    { id: 'tbc-micro', bank: 'tbc-bank', type: 'micro', uz: 'Masofaviy mikroqarz', ru: 'Дистанционный микрозайм', rate: 31, termMin: 3, termMax: 24, amountMin: 1000000, amountMax: 50000000, downPayment: 0, income: false, channel: 'online', popularity: 87 },

    { id: 'xalq-education', bank: 'xalq-bank', type: 'education', uz: "Ta'lim uchun kredit", ru: 'Кредит на обучение', rate: 14, termMin: 12, termMax: 84, amountMin: 1000000, amountMax: 100000000, downPayment: 0, income: true, channel: 'bank', popularity: 85 },
    { id: 'nbu-education', bank: 'nbu', type: 'education', uz: 'Talabalar uchun ta’lim krediti', ru: 'Образовательный кредит студентам', rate: 15, termMin: 12, termMax: 84, amountMin: 1000000, amountMax: 120000000, downPayment: 0, income: true, channel: 'bank', popularity: 84 },
    { id: 'agro-education', bank: 'agrobank', type: 'education', uz: "O'qish xarajatlari uchun kredit", ru: 'Кредит на расходы обучения', rate: 16, termMin: 12, termMax: 60, amountMin: 1000000, amountMax: 80000000, downPayment: 0, income: true, channel: 'bank', popularity: 78 },

    { id: 'kapital-overdraft', bank: 'kapitalbank', type: 'overdraft', uz: 'Kartaga overdraft limiti', ru: 'Овердрафтный лимит на карту', rate: 27, termMin: 1, termMax: 12, amountMin: 500000, amountMax: 50000000, downPayment: 0, income: true, channel: 'bank', popularity: 86 },
    { id: 'octo-overdraft', bank: 'octobank', type: 'overdraft', uz: 'Raqamli overdraft', ru: 'Цифровой овердрафт', rate: 29, termMin: 1, termMax: 12, amountMin: 500000, amountMax: 30000000, downPayment: 0, income: false, channel: 'online', popularity: 82 },
    { id: 'trust-overdraft', bank: 'trustbank', type: 'overdraft', uz: 'Oylik tushumga overdraft', ru: 'Овердрафт под ежемесячный оборот', rate: 26, termMin: 1, termMax: 12, amountMin: 1000000, amountMax: 60000000, downPayment: 0, income: true, channel: 'bank', popularity: 76 },

    { id: 'nbu-consumer', bank: 'nbu', type: 'consumer', uz: "Iste'mol krediti", ru: 'Потребительский кредит', rate: 23, termMin: 6, termMax: 60, amountMin: 1000000, amountMax: 150000000, downPayment: 0, income: true, channel: 'bank', popularity: 92 },
    { id: 'universal-consumer', bank: 'universalbank', type: 'consumer', uz: "Universal iste'mol krediti", ru: 'Универсальный потребительский кредит', rate: 24, termMin: 6, termMax: 48, amountMin: 1000000, amountMax: 100000000, downPayment: 0, income: true, channel: 'bank', popularity: 81 },
    { id: 'apex-consumer', bank: 'apexbank', type: 'consumer', uz: 'Shaxsiy ehtiyojlar uchun kredit', ru: 'Кредит на личные нужды', rate: 25, termMin: 6, termMax: 48, amountMin: 1000000, amountMax: 90000000, downPayment: 0, income: true, channel: 'bank', popularity: 79 },
    { id: 'hayot-consumer', bank: 'hayot-bank', type: 'consumer', uz: 'Hayot iste’mol krediti', ru: 'Потребительский кредит Hayot', rate: 24.5, termMin: 6, termMax: 48, amountMin: 1000000, amountMax: 80000000, downPayment: 0, income: true, channel: 'bank', popularity: 77 },
    { id: 'tenge-consumer', bank: 'tenge-bank', type: 'consumer', uz: 'Tenge shaxsiy kredit', ru: 'Персональный кредит Tenge', rate: 25.5, termMin: 6, termMax: 60, amountMin: 1000000, amountMax: 120000000, downPayment: 0, income: true, channel: 'bank', popularity: 75 },
    { id: 'kdb-consumer', bank: 'kdb-bank', type: 'consumer', uz: 'KDB chakana kredit', ru: 'Розничный кредит KDB', rate: 24.9, termMin: 6, termMax: 48, amountMin: 1000000, amountMax: 100000000, downPayment: 0, income: true, channel: 'bank', popularity: 72 },
  ];

  function language() {
    return localStorage.getItem('bpay_lang') || localStorage.getItem('selectedLanguage') || 'uz';
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

  function banks() {
    return Array.isArray(window.B1_PUBLIC_BANKS) ? window.B1_PUBLIC_BANKS : [];
  }

  function bankBySlug(slug) {
    return banks().find(bank => bank.slug === slug || bank.id === slug || bank.abbr === slug) || {};
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
        try { sources = JSON.parse(img.dataset.logoSources || '[]'); } catch (error) { sources = []; }
        const nextIndex = Number(img.dataset.logoIndex || 0) + 1;
        if (sources[nextIndex]) {
          img.dataset.logoIndex = String(nextIndex);
          img.src = sources[nextIndex];
          return;
        }
        img.style.display = 'none';
        const fallback = img.nextElementSibling;
        if (fallback) fallback.style.display = 'grid';
      });
    });
  }

  function bankLogo(bank) {
    const sources = logoSources(bank);
    const source = sources[0] || '';
    const fallback = escapeHtml(bank.abbr || bank.name_uz || 'B1');
    const color = escapeHtml(bank.color || '#2563eb');
    return `${source ? `<img src="${escapeHtml(source)}" alt="${escapeHtml(bank.name || fallback)} logo" loading="lazy" data-logo-index="0" data-logo-sources="${escapeHtml(JSON.stringify(sources))}">` : ''}<span style="display:${source ? 'none' : 'grid'};background:${color}">${fallback}</span>`;
  }

  function formatMoney(value, compact = false) {
    const number = Math.max(0, Number(value) || 0);
    return `${new Intl.NumberFormat(language() === 'ru' ? 'ru-RU' : 'uz-UZ', {
      notation: compact ? 'compact' : 'standard',
      maximumFractionDigits: 0,
    }).format(Math.round(number))} ${text('so‘m', 'сум')}`;
  }

  function formatPercent(value) {
    return new Intl.NumberFormat(language() === 'ru' ? 'ru-RU' : 'uz-UZ', {
      maximumFractionDigits: 1,
    }).format(value);
  }

  function amountRange(offer) {
    if (offer.amountMin && offer.amountMax) return `${formatMoney(offer.amountMin, true)} – ${formatMoney(offer.amountMax, true)}`;
    return offer.amountMax ? `${formatMoney(offer.amountMax, true)}${text('gacha', 'до')}` : '—';
  }

  function termRange(offer) {
    if (offer.termMin === offer.termMax) return `${offer.termMax} ${text('oy', 'мес')}`;
    return `${offer.termMin}–${offer.termMax} ${text('oy', 'мес')}`;
  }

  function rateLabel(offer) {
    if (offer.rateTo) return `${formatPercent(offer.rate)}%–${formatPercent(offer.rateTo)}%`;
    return `${formatPercent(offer.rate)}% ${text('dan', 'от')}`;
  }

  function annuityPayment(amount, annualRate, months) {
    const principal = Math.max(0, Number(amount) || 0);
    const term = Math.max(1, Number(months) || 1);
    const monthlyRate = (Number(annualRate) || 0) / 100 / 12;
    if (!monthlyRate) return principal / term;
    return principal * monthlyRate / (1 - Math.pow(1 + monthlyRate, -term));
  }

  function offerPayment(offer) {
    const requestedAmount = state.amount || offer.amountMax || offer.amountMin;
    const amount = Math.min(Math.max(requestedAmount, offer.amountMin || 0), offer.amountMax || requestedAmount);
    const requestedTerm = state.term || offer.termMax;
    const term = Math.min(Math.max(requestedTerm, offer.termMin), offer.termMax);
    const financed = Math.max(0, amount * (1 - Math.max(state.downPayment, offer.downPayment || 0) / 100));
    return annuityPayment(financed, offer.rate, term);
  }

  function matchesOffer(offer) {
    if (offer.type !== state.type) return false;
    const amountOk = !state.amount || (state.amount >= offer.amountMin && state.amount <= offer.amountMax);
    const termOk = !state.term || (state.term >= offer.termMin && state.term <= offer.termMax);
    const downOk = state.downPayment === 0 || (offer.downPayment || 0) <= state.downPayment;
    const incomeOk = state.income === 'any' || (state.income === 'official' ? offer.income : true);
    return amountOk && termOk && downOk && incomeOk;
  }

  function filteredOffers() {
    const matched = offers.filter(matchesOffer);
    const fallback = offers.filter(offer => offer.type === state.type);
    const list = matched.length ? matched : fallback;
    return [...list].sort((a, b) => {
      if (state.sort === 'rate') return a.rate - b.rate;
      if (state.sort === 'amount') return b.amountMax - a.amountMax;
      if (state.sort === 'payment') return offerPayment(a) - offerPayment(b);
      return b.popularity - a.popularity;
    });
  }

  function currentTypeName() {
    const label = typeLabels[state.type] || typeLabels.auto;
    return text(label.uz, label.ru);
  }

  function offerName(offer) {
    return text(offer.uz, offer.ru);
  }

  function channelLabel(offer) {
    return offer.channel === 'online' ? text('Onlayn', 'Онлайн') : text('Bank', 'Банк');
  }

  function detailsUrl(offer, bank, monthly) {
    const query = new URLSearchParams({
      id: bank.id || offer.bank,
      slug: bank.slug || offer.bank,
      service: 'credits',
      credit: offer.id,
      credit_name: offerName(offer),
      credit_type: currentTypeName(),
      rate: String(offer.rate),
      term: termRange(offer),
      down: offer.downPayment ? `${offer.downPayment}%` : text('Talab qilinmaydi', 'Не требуется'),
      amount: amountRange(offer),
      channel: channelLabel(offer),
      monthly: formatMoney(monthly, true),
    });
    return `bank.html?${query.toString()}`;
  }

  function renderTabs() {
    const tabs = document.getElementById('creditTypeTabs');
    if (!tabs) return;
    tabs.innerHTML = Object.entries(typeLabels).map(([type, label]) => `
      <button type="button" class="credit-type-tab${type === state.type ? ' active' : ''}" data-credit-type="${type}" aria-pressed="${type === state.type ? 'true' : 'false'}">
        ${escapeHtml(text(label.uz, label.ru))}
      </button>
    `).join('');
  }

  function updateControls() {
    const amount = document.getElementById('creditAmount');
    const term = document.getElementById('creditTerm');
    const down = document.getElementById('creditDownPayment');
    const income = document.getElementById('creditIncome');
    const sort = document.getElementById('creditSort');
    if (amount) amount.value = String(state.amount);
    if (term) term.value = String(state.term);
    if (down) down.value = String(state.downPayment);
    if (income) income.value = state.income;
    if (sort) sort.value = state.sort;
  }

  function renderSummary(list) {
    const root = document.getElementById('creditSummary');
    if (!root) return;
    const best = list[0];
    if (!best) {
      root.innerHTML = '';
      return;
    }
    const monthly = offerPayment(best);
    root.innerHTML = `
      <div class="credit-summary-card">
        <span>${escapeHtml(currentTypeName())}</span>
        <strong>${formatMoney(monthly, true)}</strong>
        <p>${text('eng mos taklif bo‘yicha taxminiy oylik to‘lov', 'примерный ежемесячный платёж по лучшему предложению')}</p>
      </div>
      <div class="credit-summary-card">
        <span>${text('Topildi', 'Найдено')}</span>
        <strong>${list.length}</strong>
        <p>${text('bank taklifi va onlayn ariza yo‘nalishlari', 'банковских предложений и онлайн-направлений')}</p>
      </div>
      <div class="credit-summary-card">
        <span>${text('Limit', 'Лимит')}</span>
        <strong>${amountRange(best)}</strong>
        <p>${text('yakuniy limit bank qaroriga bog‘liq', 'финальный лимит зависит от решения банка')}</p>
      </div>
    `;
  }

  function renderOffers() {
    const root = document.getElementById('creditOffersRoot');
    const count = document.getElementById('creditOffersCount');
    if (!root) return;
    const list = filteredOffers();
    if (count) count.textContent = String(list.length);
    renderSummary(list);

    root.innerHTML = list.map(offer => {
      const bank = bankBySlug(offer.bank);
      const monthly = offerPayment(offer);
      return `
        <article class="credit-offer-card">
          <a class="credit-offer-bank credit-offer-bank-link" href="${escapeHtml(detailsUrl(offer, bank, monthly))}">
            <div class="credit-bank-logo" style="background:${escapeHtml(bank.color || '#2563eb')}">${bankLogo(bank)}</div>
            <div>
              <h3>${escapeHtml(bank.name_uz || bank.name || offer.bank)}</h3>
              <p>${escapeHtml(offerName(offer))}</p>
            </div>
          </a>
          <div class="credit-offer-cell">
            <span>${text('Foiz stavkasi', 'Ставка')}</span>
            <strong>${rateLabel(offer)}</strong>
          </div>
          <div class="credit-offer-cell">
            <span>${text('Muddat', 'Срок')}</span>
            <strong>${termRange(offer)}</strong>
          </div>
          <div class="credit-offer-cell">
            <span>${text('Boshlang‘ich', 'Первый взнос')}</span>
            <strong>${offer.downPayment ? `${offer.downPayment}%` : '0%'}</strong>
          </div>
          <div class="credit-offer-cell credit-offer-amount">
            <span>${text('Summa', 'Сумма')}</span>
            <strong>${amountRange(offer)}</strong>
            <small>${text('oyiga', 'в месяц')} ≈ ${formatMoney(monthly, true)}</small>
          </div>
          <div class="credit-offer-footer">
            <span class="credit-channel-badge">${channelLabel(offer)}</span>
            <a class="credit-details-button" href="${escapeHtml(detailsUrl(offer, bank, monthly))}">${text('Batafsil', 'Подробнее')}</a>
          </div>
        </article>
      `;
    }).join('');
    bindLogoFallbacks(root);
  }

  function syncUrl() {
    const url = new URL(window.location.href);
    url.searchParams.set('type', state.type);
    url.searchParams.set('amount', String(state.amount));
    url.searchParams.set('term', String(state.term));
    if (state.downPayment) url.searchParams.set('down', String(state.downPayment));
    else url.searchParams.delete('down');
    if (state.income !== 'any') url.searchParams.set('income', state.income);
    else url.searchParams.delete('income');
    window.history.replaceState({}, '', url);
  }

  function render() {
    renderTabs();
    updateControls();
    renderOffers();
    syncUrl();
  }

  function mount() {
    render();
    document.getElementById('creditTypeTabs')?.addEventListener('click', event => {
      const button = event.target.closest('[data-credit-type]');
      if (!button) return;
      state.type = button.dataset.creditType;
      render();
    });
    document.getElementById('creditSearchForm')?.addEventListener('submit', event => {
      event.preventDefault();
      state.amount = Number(document.getElementById('creditAmount')?.value || state.amount);
      state.term = Number(document.getElementById('creditTerm')?.value || state.term);
      state.downPayment = Number(document.getElementById('creditDownPayment')?.value || 0);
      state.income = document.getElementById('creditIncome')?.value || 'any';
      renderOffers();
      syncUrl();
    });
    ['creditAmount', 'creditTerm', 'creditDownPayment', 'creditIncome'].forEach(id => {
      document.getElementById(id)?.addEventListener('change', () => {
        state.amount = Number(document.getElementById('creditAmount')?.value || state.amount);
        state.term = Number(document.getElementById('creditTerm')?.value || state.term);
        state.downPayment = Number(document.getElementById('creditDownPayment')?.value || 0);
        state.income = document.getElementById('creditIncome')?.value || 'any';
        renderOffers();
        syncUrl();
      });
    });
    document.getElementById('creditSort')?.addEventListener('change', event => {
      state.sort = event.target.value;
      renderOffers();
    });
  }

  document.addEventListener('DOMContentLoaded', mount);
  window.addEventListener('b1:languagechange', render);
})();
