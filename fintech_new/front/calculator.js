(function () {
  const bankRates = {
    nbu: 23,
    agrobank: 24,
    sqb: 22,
    asakabank: 23.5,
    'xalq-bank': 24,
    kapitalbank: 25,
    'ipoteka-bank': 21,
    hamkorbank: 24.5,
    'tbc-bank': 26,
    anorbank: 27,
  };

  const mfiPresets = [
    { id: 'mfi-standard', name: 'MFI Standard', abbr: 'MFI', rate: 42 },
    { id: 'mfi-fast', name: 'Tez mikroqarz', abbr: 'FAST', rate: 48 },
    { id: 'mfi-soft', name: 'Pastroq stavka', abbr: 'SOFT', rate: 36 },
  ];

  const state = {
    kind: 'bank',
    method: 'annuity',
    termUnit: 'months',
    selectedBank: null,
  };

  function language() {
    return localStorage.getItem('bpay_lang') || localStorage.getItem('selectedLanguage') || 'uz';
  }

  function text(uz, ru) {
    return language() === 'ru' ? ru : uz;
  }

  function parseMoney(value) {
    const parsed = Number(String(value || '').replace(/[^\d.]/g, ''));
    return Number.isFinite(parsed) ? parsed : 0;
  }

  function formatMoney(value, compact) {
    return new Intl.NumberFormat(language() === 'ru' ? 'ru-RU' : 'uz-UZ', {
      notation: compact ? 'compact' : 'standard',
      maximumFractionDigits: 0,
    }).format(Math.max(0, Math.round(value))) + ' UZS';
  }

  function formatPercent(value) {
    return new Intl.NumberFormat(language() === 'ru' ? 'ru-RU' : 'uz-UZ', {
      maximumFractionDigits: 1,
    }).format(value) + '%';
  }

  function banks() {
    return Array.isArray(window.B1_PUBLIC_BANKS) ? window.B1_PUBLIC_BANKS : [];
  }

  function optionsForKind() {
    if (state.kind === 'mfi') return mfiPresets;
    return banks().map(bank => ({
      id: bank.slug || bank.id,
      name: bank.name_uz || bank.name,
      abbr: bank.abbr || bank.name_uz || bank.name,
      rate: bankRates[bank.slug || bank.id] || 24,
    }));
  }

  function getFormNodes() {
    return {
      form: document.getElementById('loanCalculatorForm'),
      bank: document.getElementById('loanBank'),
      amount: document.getElementById('loanAmount'),
      rate: document.getElementById('loanRate'),
      term: document.getElementById('loanTerm'),
      results: document.getElementById('calculatorResults'),
      rateList: document.getElementById('bankRateList'),
    };
  }

  function populateSelect() {
    const { bank, rate } = getFormNodes();
    if (!bank) return;
    const options = optionsForKind();
    bank.innerHTML = options.map(item =>
      `<option value="${item.id}">${item.name} — ${formatPercent(item.rate)}</option>`
    ).join('');
    const requested = new URLSearchParams(window.location.search).get('bank');
    const selected = options.find(item => item.id === requested) || options[0];
    if (selected) {
      bank.value = selected.id;
      state.selectedBank = selected.id;
      if (rate) rate.value = selected.rate;
    }
  }

  function populateRateChips() {
    const { rateList } = getFormNodes();
    if (!rateList) return;
    const options = optionsForKind();
    rateList.innerHTML = options.map(item => `
      <button type="button" class="bank-rate-chip${item.id === state.selectedBank ? ' active' : ''}" data-rate-bank="${item.id}">
        <strong>${item.abbr}</strong>
        <span>${item.name}</span><br>
        <span>${formatPercent(item.rate)}</span>
      </button>
    `).join('');
  }

  function calculateSchedule(principal, annualRate, months, method) {
    const monthlyRate = annualRate / 100 / 12;
    const rows = [];
    let balance = principal;
    let total = 0;
    const annuityPayment = monthlyRate === 0
      ? principal / months
      : principal * monthlyRate / (1 - Math.pow(1 + monthlyRate, -months));
    const fixedPrincipal = principal / months;

    for (let month = 1; month <= months; month += 1) {
      const interest = balance * monthlyRate;
      let principalPart;
      let payment;

      if (method === 'differentiated') {
        principalPart = Math.min(fixedPrincipal, balance);
        payment = principalPart + interest;
      } else {
        payment = month === months ? balance + interest : annuityPayment;
        principalPart = payment - interest;
      }

      balance = Math.max(0, balance - principalPart);
      total += payment;
      rows.push({ month, payment, principal: principalPart, interest, balance });
    }

    return {
      rows,
      monthlyPayment: method === 'differentiated' ? rows[0].payment : annuityPayment,
      total,
      overpayment: Math.max(0, total - principal),
    };
  }

  function readInput() {
    const { amount, rate, term } = getFormNodes();
    const principal = parseMoney(amount.value);
    const annualRate = Number(rate.value || 0);
    const rawTerm = Math.max(1, Number(term.value || 1));
    const months = state.termUnit === 'years' ? rawTerm * 12 : rawTerm;
    return { principal, annualRate, months };
  }

  function renderResults() {
    const { results } = getFormNodes();
    if (!results) return;
    const { principal, annualRate, months } = readInput();

    if (principal <= 0 || annualRate < 0 || months <= 0) {
      results.innerHTML = `
        <div class="result-empty">
          <div>
            <div class="result-empty-icon">!</div>
            <h2>${text("Ma'lumotlarni tekshiring", 'Проверьте данные')}</h2>
            <p>${text('Kredit summasi, stavka va muddat to‘g‘ri kiritilishi kerak.', 'Сумма, ставка и срок должны быть заполнены корректно.')}</p>
          </div>
        </div>
      `;
      return;
    }

    const result = calculateSchedule(principal, annualRate, months, state.method);
    const recommendedIncome = result.monthlyPayment / (state.kind === 'mfi' ? 0.35 : 0.45);
    const maxPayment = Math.max(...result.rows.slice(0, 6).map(row => row.payment), 1);
    const selectedName = optionsForKind().find(item => item.id === state.selectedBank)?.name || text('Tanlangan bank', 'Выбранный банк');

    results.innerHTML = `
      <div class="result-grid">
        <div class="result-metric">
          <strong>${formatMoney(result.monthlyPayment, true)}</strong>
          <span>${state.method === 'differentiated' ? text('Birinchi to‘lov', 'Первый платёж') : text('Oylik to‘lov', 'Ежемесячный платёж')}</span>
        </div>
        <div class="result-metric">
          <strong>${formatMoney(result.total, true)}</strong>
          <span>${text('Jami to‘lov', 'Всего к оплате')}</span>
        </div>
        <div class="result-metric">
          <strong>${formatMoney(result.overpayment, true)}</strong>
          <span>${text('Ortiqcha to‘lov', 'Переплата')}</span>
        </div>
      </div>
      <div class="income-note">
        <strong>${selectedName}</strong> ${text('uchun taxminiy hisob.', 'ориентировочный расчёт.')}
        ${text('Qulay yuklama uchun oyiga kamida', 'Для комфортной нагрузки желательно иметь доход от')}
        <strong>${formatMoney(recommendedIncome, false)}</strong>.
      </div>
      <div class="schedule-bars">
        ${result.rows.slice(0, 6).map(row => `
          <div class="schedule-bar">
            <div class="schedule-bar-fill" style="height:${Math.max(18, row.payment / maxPayment * 118)}px"></div>
            <span>${row.month}</span>
          </div>
        `).join('')}
      </div>
      <table class="schedule-table">
        <thead>
          <tr>
            <th>${text('Oy', 'Месяц')}</th>
            <th>${text('To‘lov', 'Платёж')}</th>
            <th>${text('Foiz', 'Процент')}</th>
            <th>${text('Qoldiq', 'Остаток')}</th>
          </tr>
        </thead>
        <tbody>
          ${result.rows.slice(0, 8).map(row => `
            <tr>
              <td>${row.month}</td>
              <td>${formatMoney(row.payment, false)}</td>
              <td>${formatMoney(row.interest, false)}</td>
              <td>${formatMoney(row.balance, false)}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;
  }

  function setKind(kind) {
    state.kind = kind;
    document.querySelectorAll('[data-loan-kind]').forEach(button => {
      button.classList.toggle('active', button.dataset.loanKind === kind);
    });
    const { amount, term } = getFormNodes();
    if (kind === 'mfi') {
      if (amount) amount.value = '3000000';
      if (term) term.value = '6';
      state.termUnit = 'months';
    } else {
      if (amount) amount.value = '10000000';
      if (term) term.value = '12';
    }
    document.querySelectorAll('[data-term-unit]').forEach(button => {
      button.classList.toggle('active', button.dataset.termUnit === state.termUnit);
    });
    populateSelect();
    populateRateChips();
    renderResults();
  }

  function mount() {
    const nodes = getFormNodes();
    if (!nodes.form) return;
    const initialParams = new URLSearchParams(window.location.search);
    if (initialParams.get('type') === 'mfi') {
      state.kind = 'mfi';
      if (nodes.amount) nodes.amount.value = '3000000';
      if (nodes.term) nodes.term.value = '6';
    }
    document.querySelectorAll('[data-loan-kind]').forEach(button => {
      button.classList.toggle('active', button.dataset.loanKind === state.kind);
    });
    populateSelect();
    populateRateChips();

    document.querySelectorAll('[data-loan-kind]').forEach(button => {
      button.addEventListener('click', () => setKind(button.dataset.loanKind));
    });
    document.querySelectorAll('[data-term-unit]').forEach(button => {
      button.addEventListener('click', () => {
        state.termUnit = button.dataset.termUnit;
        document.querySelectorAll('[data-term-unit]').forEach(item => item.classList.toggle('active', item === button));
        renderResults();
      });
    });
    document.querySelectorAll('[data-method]').forEach(button => {
      button.addEventListener('click', () => {
        state.method = button.dataset.method;
        document.querySelectorAll('[data-method]').forEach(item => item.classList.toggle('active', item === button));
        renderResults();
      });
    });
    nodes.bank.addEventListener('change', () => {
      const selected = optionsForKind().find(item => item.id === nodes.bank.value);
      state.selectedBank = nodes.bank.value;
      if (selected) nodes.rate.value = selected.rate;
      populateRateChips();
      renderResults();
    });
    nodes.rateList.addEventListener('click', event => {
      const chip = event.target.closest('[data-rate-bank]');
      if (!chip) return;
      nodes.bank.value = chip.dataset.rateBank;
      nodes.bank.dispatchEvent(new Event('change'));
    });
    ['input', 'change'].forEach(eventName => {
      [nodes.amount, nodes.rate, nodes.term].forEach(node => node.addEventListener(eventName, renderResults));
    });
    nodes.form.addEventListener('submit', event => {
      event.preventDefault();
      renderResults();
    });
    renderResults();
  }

  document.addEventListener('DOMContentLoaded', mount);
  window.addEventListener('b1:languagechange', () => {
    populateSelect();
    populateRateChips();
    renderResults();
  });
})();
