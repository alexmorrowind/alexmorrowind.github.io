(function () {
  const apiBase = (window.B1_API_BASE_URL || '').replace(/\/$/, '');
  const params = new URLSearchParams(window.location.search);
  const bankId = params.get('id');
  const bankSlug = params.get('slug');
  const requestedService = params.get('service');
  let bankMap = null;

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

  function uniqueItems(bank) {
    return [...new Set([...(bank.products || []), ...(bank.services || [])].map(itemText).filter(Boolean))];
  }

  function hasKeyword(values, keywords) {
    return values.some(value => keywords.some(keyword => value.toLowerCase().includes(keyword)));
  }

  function safeUrl(url) {
    if (!url) return '';
    try {
      const parsed = new URL(url);
      return ['http:', 'https:'].includes(parsed.protocol) ? parsed.href : '';
    } catch (error) {
      return '';
    }
  }

  function setText(selector, value) {
    const node = document.querySelector(selector);
    if (node) node.textContent = value;
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
      ? `<img src="${escapeHtml(source)}" alt="" onerror="this.style.display='none';this.nextElementSibling.style.display='grid'">`
      : ''}<span style="display:${source ? 'none' : 'grid'};background:${color}">${fallback}</span>`;
  }

  function officialLink(bank, label) {
    const url = safeUrl(bank.website_url);
    if (!url) {
      return `<span class="bank-detail-button bank-detail-button-muted">${text('Rasmiy sayt kiritilmagan', 'Официальный сайт не указан')}</span>`;
    }
    return `<a class="bank-detail-button" href="${escapeHtml(url)}" target="_blank" rel="noopener noreferrer">${label} <span aria-hidden="true">↗</span></a>`;
  }

  function categoryCard(bank, id, icon, titleUz, titleRu, descriptionUz, descriptionRu, keywords, internalHref) {
    const values = uniqueItems(bank);
    const matched = values.filter(value => keywords.some(keyword => value.toLowerCase().includes(keyword)));
    const list = matched.length ? matched : [
      text('Bankning rasmiy saytida mavjud takliflarni tekshiring.', 'Проверьте доступные предложения на официальном сайте банка.')
    ];
    return `
      <article class="bank-product-card" id="${id}">
        <div class="bank-product-icon">${icon}</div>
        <div class="bank-product-content">
          <div class="bank-product-kicker">${text('Mahsulotlar bo‘limi', 'Раздел продуктов')}</div>
          <h3>${text(titleUz, titleRu)}</h3>
          <p>${text(descriptionUz, descriptionRu)}</p>
          <ul>${list.map(item => `<li>${escapeHtml(item)}</li>`).join('')}</ul>
          <div class="bank-product-actions">
            ${internalHref ? `<a class="bank-detail-button bank-detail-button-secondary" href="${escapeHtml(internalHref)}">${text('Bank kartalarini ko‘rish', 'Смотреть карты банка')} <span aria-hidden="true">→</span></a>` : ''}
            ${officialLink(bank, text('Rasmiy saytga o‘tish', 'Перейти на официальный сайт'))}
          </div>
        </div>
      </article>
    `;
  }

  function renderMap(bank) {
    const container = document.getElementById('bankDetailMap');
    if (!container || !window.L) return;
    if (bankMap) {
      bankMap.remove();
      bankMap = null;
    }
    const latitude = Number(bank.latitude);
    const longitude = Number(bank.longitude);
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      container.innerHTML = `<div class="bank-map-empty">${text('Bank koordinatalari hali kiritilmagan.', 'Координаты банка пока не указаны.')}</div>`;
      return;
    }

    bankMap = window.L.map(container).setView([latitude, longitude], 15);
    window.L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; OpenStreetMap contributors',
    }).addTo(bankMap);
    window.L.marker([latitude, longitude]).addTo(bankMap).bindPopup(`
      <strong>${escapeHtml(bank.name)}</strong><br>
      ${escapeHtml(bank.address || text('Manzil kiritilmagan', 'Адрес не указан'))}
    `).openPopup();
    window.setTimeout(() => bankMap && bankMap.invalidateSize(), 0);
  }

  function renderBank(bank) {
    const values = uniqueItems(bank);
    const description = language() === 'ru'
      ? (bank.description || text('Bank haqida ma’lumot rasmiy manbalar asosida jamlangan.', 'Профиль собран по официальным источникам банка.'))
      : (bank.description_uz || bank.description || 'Bank haqida ma’lumot rasmiy manbalar asosida jamlangan.');
    const website = safeUrl(bank.website_url);
    const sourceUrls = bank.officialSources || bank.source_urls || [];

    document.title = `${bank.name} — B1`;
    setText('#bankDetailName', bank.name);
    setText('#bankDetailAbbr', bank.name_uz || bank.name);
    setText('#bankDetailType', bank.type === 'digital'
      ? text('Raqamli bank', 'Цифровой банк')
      : bank.type === 'international'
        ? text('Xalqaro bank', 'Международный банк')
        : text("An'anaviy bank", 'Традиционный банк'));
    setText('#bankDetailDescription', description);
    setText('#bankDetailUpdated', bank.dataAsOf || bank.data_as_of || text('Tekshirilmoqda', 'Проверяется'));
    setText('#bankDetailProductCount', String(values.length));
    setText('#bankDetailAddress', bank.address || text('Manzil kiritilmagan', 'Адрес не указан'));
    setText('#bankDetailLicense', bank.license_number || text('Kiritilmagan', 'Не указана'));

    const logo = document.getElementById('bankDetailLogo');
    if (logo) {
      logo.style.background = bank.color || '#2563eb';
      logo.innerHTML = bankLogo(bank);
    }

    const primaryAction = document.getElementById('bankDetailPrimaryAction');
    if (primaryAction) {
      primaryAction.outerHTML = website
        ? `<a id="bankDetailPrimaryAction" class="btn-hero btn-hero-primary" href="${escapeHtml(website)}" target="_blank" rel="noopener noreferrer">${text('Rasmiy saytga o‘tish', 'Перейти на официальный сайт')} <span aria-hidden="true">↗</span></a>`
        : `<span id="bankDetailPrimaryAction" class="btn-hero btn-hero-ghost">${text('Rasmiy sayt kiritilmagan', 'Официальный сайт не указан')}</span>`;
    }

    const sections = document.getElementById('bankProductSections');
    if (sections) {
      sections.innerHTML = [
        categoryCard(bank, 'credits', '↗', 'Kreditlar', 'Кредиты', 'Iste’mol, mikro va boshqa kredit takliflarini bankning rasmiy sahifasida ko‘ring.', 'Потребительские, микрокредитные и другие предложения смотрите на официальной странице банка.', ['kredit', 'credit', 'qarz', 'loan']),
        categoryCard(bank, 'cards', '▣', 'Kartalar', 'Карты', 'Debet, kredit va boshqa kartalar bo‘yicha shartlarni taqqoslashga tayyorlaymiz.', 'Показываем условия по дебетовым, кредитным и другим картам.', ['karta', 'card', 'visa', 'mastercard', 'humo', 'uzcard'], `bank-cards.html?bank=${encodeURIComponent(bank.slug || bank.id)}`),
        categoryCard(bank, 'mortgage', '⌂', 'Ipoteka', 'Ипотека', 'Uy-joy moliyalashtirish va ipoteka yo‘nalishlarini tekshiring.', 'Проверьте ипотечные программы и финансирование жилья.', ['ipoteka', 'ипотек', 'mortgage']),
        categoryCard(bank, 'insurance', '◇', 'Sug‘urta', 'Страхование', 'Sug‘urta mahsulotlari va hamkorlik takliflari bank saytida tekshiriladi.', 'Страховые продукты и партнёрские предложения проверяются на сайте банка.', ['sug', 'страх', 'insurance']),
        categoryCard(bank, 'business', '◫', 'Biznes kreditlari', 'Бизнес-кредиты', 'Tadbirkorlar va kompaniyalar uchun moliyalashtirish yo‘nalishlari.', 'Финансирование для предпринимателей и компаний.', ['biznes', 'business', 'korpor', 'предпри', 'business']),
        categoryCard(bank, 'deposits', '◌', 'Depozitlar', 'Депозиты', 'Jamg‘arma va depozitlar bo‘yicha joriy shartlarni rasmiy manbada tekshiring.', 'Проверяйте актуальные условия накоплений и депозитов на официальном источнике.', ['depozit', 'deposit', 'omonat', 'вклад']),
      ].join('');
    }

    const sources = document.getElementById('bankSources');
    if (sources) {
      sources.innerHTML = sourceUrls.length
        ? sourceUrls.map(url => `<a href="${escapeHtml(url)}" target="_blank" rel="noopener noreferrer">${escapeHtml(url)}</a>`).join('')
        : `<span>${text('Rasmiy manbalar hali kiritilmagan.', 'Официальные источники пока не добавлены.')}</span>`;
    }

    renderMap(bank);
    if (requestedService) {
      window.setTimeout(() => {
        const target = document.getElementById(requestedService);
        if (!target) return;
        target.classList.add('is-requested');
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }, 80);
    }
    document.body.classList.remove('bank-detail-loading');
  }

  async function loadBank() {
    const state = document.getElementById('bankDetailState');
    if (!bankId && !bankSlug) {
      if (state) state.textContent = text('Bank topilmadi.', 'Банк не найден.');
      return;
    }

    try {
      if (!apiBase || !bankId) throw new Error('Public API is unavailable');
      const response = await fetch(`${apiBase}/banks/${encodeURIComponent(bankId)}/`, {
        headers: { Accept: 'application/json' },
      });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      renderBank(await response.json());
      if (state) state.remove();
    } catch (error) {
      console.warn('Bank detail API unavailable. Using the published fallback.', error);
      const fallback = (window.B1_PUBLIC_BANKS || []).find(bank =>
        String(bank.id) === String(bankId) || bank.slug === bankSlug || bank.abbr === bankSlug
      );
      if (fallback) {
        renderBank(fallback);
        if (state) state.remove();
      } else if (state) {
        state.textContent = text(
          'Bank profilini yuklab bo‘lmadi.',
          'Не удалось загрузить профиль банка.'
        );
      }
    }
  }

  document.addEventListener('DOMContentLoaded', loadBank);
  window.addEventListener('b1:languagechange', loadBank);
})();
