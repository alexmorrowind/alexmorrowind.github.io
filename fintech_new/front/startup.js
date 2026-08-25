(function () {
  const apiBase = (window.B1_API_BASE_URL || '').replace(/\/$/, '');
  const params = new URLSearchParams(window.location.search);
  let startups = [];
  let activeFilter = 'all';

  const stages = {
    idea: { uz: 'G‘oya', ru: 'Идея' },
    mvp: { uz: 'MVP', ru: 'MVP' },
    growth: { uz: 'O‘sish', ru: 'Рост' },
    scale: { uz: 'Masshtab', ru: 'Масштабирование' },
  };

  const domains = {
    fintech: { uz: 'Fintech', ru: 'Финтех' },
    commerce: { uz: 'Savdo', ru: 'Торговля' },
    education: { uz: 'Ta’lim', ru: 'Образование' },
    analytics: { uz: 'Tahlil', ru: 'Аналитика' },
    startup: { uz: 'Startap', ru: 'Стартап' },
  };

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

  function formatMoney(value) {
    const amount = Number(value || 0);
    try {
      return new Intl.NumberFormat(language() === 'ru' ? 'ru-RU' : 'uz-UZ', {
        maximumFractionDigits: 0,
      }).format(amount);
    } catch (error) {
      return String(amount);
    }
  }

  function money(value) {
    return `${formatMoney(value)} ${text('so‘m', 'сум')}`;
  }

  function stageName(stage) {
    return (stages[stage] || stages.mvp)[language()];
  }

  function domainName(domain) {
    return (domains[domain] || domains.startup)[language()];
  }

  function progress(startup) {
    const target = Number(startup.funding_goal || 0);
    const raised = Number(startup.amount_raised || 0);
    if (!target) return 0;
    return Math.max(0, Math.min(100, Math.round((raised / target) * 100)));
  }

  function apiHeaders(auth) {
    const headers = { Accept: 'application/json' };
    const token = localStorage.getItem('accessToken') || localStorage.getItem('authToken');
    if (auth && token) headers.Authorization = `Bearer ${token}`;
    return headers;
  }

  async function apiRequest(path, options) {
    if (!apiBase) throw new Error('API base is not configured');
    const response = await fetch(`${apiBase}${path}`, options);
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
      const error = new Error(payload.detail || payload.amount || `HTTP ${response.status}`);
      error.status = response.status;
      throw error;
    }
    return payload;
  }

  function projectCard(startup) {
    const percent = progress(startup);
    return `
      <article class="startup-card">
        <div class="startup-card-top">
          <span class="startup-stage">${escapeHtml(stageName(startup.stage))}</span>
          <span class="startup-domain">${escapeHtml(domainName(startup.domain))}</span>
        </div>
        <h2>${escapeHtml(startup.name)}</h2>
        <div class="startup-company">${escapeHtml(startup.company_name || 'B1 Startup')}</div>
        <p>${escapeHtml(startup.description || '')}</p>
        <div class="startup-progress-meta">
          <span>${text('Yig‘ilgan', 'Собрано')}</span>
          <strong>${percent}%</strong>
        </div>
        <div class="startup-progress"><span style="width:${percent}%"></span></div>
        <div class="startup-facts">
          <div><span>${text('Maqsad', 'Цель')}</span><strong>${money(startup.funding_goal)}</strong></div>
          <div><span>${text('Min. ishtirok', 'Мин. участие')}</span><strong>${money(startup.min_investment)}</strong></div>
          <div><span>${text('Maqsadli ROI', 'Целевой ROI')}</span><strong>${escapeHtml(startup.roi)}%</strong></div>
        </div>
        <a class="startup-card-link" href="startup.html?id=${encodeURIComponent(startup.id)}">${text('Loyiha sahifasi', 'Страница проекта')} <span aria-hidden="true">→</span></a>
      </article>
    `;
  }

  function renderStats(items) {
    const count = document.getElementById('startupCount');
    const goal = document.getElementById('startupGoal');
    const raised = document.getElementById('startupRaised');
    const projects = items.length;
    const totalGoal = items.reduce((sum, item) => sum + Number(item.funding_goal || 0), 0);
    const totalRaised = items.reduce((sum, item) => sum + Number(item.amount_raised || 0), 0);
    if (count) count.textContent = projects;
    if (goal) goal.textContent = money(totalGoal);
    if (raised) raised.textContent = money(totalRaised);
  }

  function filteredStartups() {
    if (activeFilter === 'all') return startups;
    return startups.filter(startup => startup.stage === activeFilter || startup.domain === activeFilter);
  }

  function renderCatalogue() {
    const grid = document.getElementById('startupGrid');
    const empty = document.getElementById('startupEmpty');
    if (!grid) return;
    const items = filteredStartups();
    grid.innerHTML = items.map(projectCard).join('');
    if (empty) empty.hidden = Boolean(items.length);
  }

  function updateFilters() {
    document.querySelectorAll('[data-startup-filter]').forEach(button => {
      const active = button.dataset.startupFilter === activeFilter;
      button.classList.toggle('active', active);
      button.setAttribute('aria-pressed', active ? 'true' : 'false');
    });
  }

  async function loadCatalogue() {
    const grid = document.getElementById('startupGrid');
    if (!grid) return;
    grid.innerHTML = `<div class="startup-state">${text('Loyihalar yuklanmoqda...', 'Загрузка проектов...')}</div>`;
    try {
      const response = await apiRequest('/startups/', { headers: apiHeaders(false) });
      startups = Array.isArray(response) ? response : [];
    } catch (error) {
      console.warn('B1 Startups unavailable.', error);
      startups = [];
    }
    renderStats(startups);
    renderCatalogue();
  }

  function detailLayout(startup) {
    const percent = progress(startup);
    const container = document.getElementById('startupDetail');
    const state = document.getElementById('startupDetailState');
    if (!container) return;
    document.title = `${startup.name} — B1 Startups`;
    container.innerHTML = `
      <a class="startup-back" href="startups.html">← ${text('B1 Startups katalogi', 'Каталог B1 Startups')}</a>
      <section class="startup-detail-hero">
        <div>
          <div class="startup-card-top">
            <span class="startup-stage">${escapeHtml(stageName(startup.stage))}</span>
            <span class="startup-domain">${escapeHtml(domainName(startup.domain))}</span>
          </div>
          <h1>${escapeHtml(startup.name)}</h1>
          <div class="startup-company">${escapeHtml(startup.company_name || 'B1 Startup')}</div>
          <p>${escapeHtml(startup.description || '')}</p>
        </div>
        <div class="startup-round">
          <span>${text('Joriy raund', 'Текущий раунд')}</span>
          <strong>${money(startup.funding_goal)}</strong>
          <div class="startup-progress-meta"><span>${text('Yig‘ilgan', 'Собрано')}</span><strong>${percent}%</strong></div>
          <div class="startup-progress"><span style="width:${percent}%"></span></div>
          <small>${money(startup.amount_raised)} ${text('yig‘ilgan', 'собрано')}</small>
        </div>
      </section>
      <section class="startup-detail-grid">
        <article class="startup-panel">
          <div class="section-label">${text('Loyiha haqida', 'О проекте')}</div>
          <h2>${text('Nima uchun bu loyiha', 'О чём этот проект')}</h2>
          <p>${escapeHtml(startup.description || '')}</p>
          <div class="startup-disclosure">
            ${text(
              'Investitsiya daromadi kafolatlanmaydi. Qaror qabul qilishdan oldin loyiha hujjatlari, risklar va rasmiy shartlarni tekshiring.',
              'Доходность инвестиций не гарантируется. Перед решением проверьте документы проекта, риски и официальные условия.'
            )}
          </div>
        </article>
        <aside class="startup-panel startup-invest-panel">
          <div class="section-label">${text('Ishtirok etish', 'Участие')}</div>
          <h2>${text('Investitsiya so‘rovi', 'Заявка на инвестицию')}</h2>
          <div class="startup-facts startup-detail-facts">
            <div><span>${text('Min. ishtirok', 'Мин. участие')}</span><strong>${money(startup.min_investment)}</strong></div>
            <div><span>${text('Maqsadli ROI', 'Целевой ROI')}</span><strong>${escapeHtml(startup.roi)}%</strong></div>
          </div>
          <form id="startupInvestmentForm" class="startup-invest-form">
            <label for="startupInvestmentAmount">${text('Miqdor, so‘m', 'Сумма, сум')}</label>
            <input id="startupInvestmentAmount" type="number" min="${escapeHtml(startup.min_investment)}" step="1000" value="${escapeHtml(startup.min_investment)}" required>
            <button class="btn-hero btn-hero-primary" type="submit">${text('Investitsiya arizasini boshlash', 'Начать заявку на инвестицию')}</button>
          </form>
          <div id="startupInvestmentStatus" class="startup-invest-status" aria-live="polite"></div>
        </aside>
      </section>
    `;
    if (state) state.remove();

    document.getElementById('startupInvestmentForm')?.addEventListener('submit', event => {
      event.preventDefault();
      submitInvestment(startup);
    });
  }

  async function submitInvestment(startup) {
    const amountInput = document.getElementById('startupInvestmentAmount');
    const status = document.getElementById('startupInvestmentStatus');
    const token = localStorage.getItem('accessToken') || localStorage.getItem('authToken');
    const amount = Number(amountInput?.value || 0);

    if (!token) {
      window.location.href = `login.html?next=${encodeURIComponent(`startup.html?id=${startup.id}`)}`;
      return;
    }
    if (!Number.isFinite(amount) || amount < Number(startup.min_investment)) {
      if (status) status.textContent = text(
        `Minimal miqdor: ${money(startup.min_investment)}.`,
        `Минимальная сумма: ${money(startup.min_investment)}.`
      );
      return;
    }

    if (status) status.textContent = text('To‘lov sahifasi tayyorlanmoqda...', 'Готовим страницу оплаты...');
    try {
      const investment = await apiRequest('/investments/', {
        method: 'POST',
        headers: { ...apiHeaders(true), 'Content-Type': 'application/json' },
        body: JSON.stringify({ startup: startup.id, amount }),
      });
      if (investment.checkout_url) {
        window.location.assign(investment.checkout_url);
        return;
      }
      if (status) status.textContent = text('Ariza qabul qilindi.', 'Заявка принята.');
    } catch (error) {
      if (status) {
        status.textContent = error.status === 503
          ? text('To‘lov integratsiyasi hali sozlanmagan. Loyiha arizasi keyingi bosqichda yoqiladi.', 'Платёжная интеграция ещё не настроена. Заявка будет доступна после подключения.')
          : text(`Arizani yuborib bo‘lmadi: ${error.message}`, `Не удалось отправить заявку: ${error.message}`);
      }
    }
  }

  async function loadDetail() {
    const container = document.getElementById('startupDetail');
    const state = document.getElementById('startupDetailState');
    if (!container) return;
    const id = params.get('id');
    if (!id) {
      if (state) state.textContent = text('Loyiha topilmadi.', 'Проект не найден.');
      return;
    }
    try {
      const startup = await apiRequest(`/startups/${encodeURIComponent(id)}/`, { headers: apiHeaders(false) });
      detailLayout(startup);
    } catch (error) {
      if (state) {
        state.textContent = text(
          'Loyihani yuklab bo‘lmadi. U hali tekshiruvda yoki mavjud emas.',
          'Не удалось загрузить проект. Возможно, он ещё на проверке или не существует.'
        );
      }
    }
  }

  function mount() {
    document.querySelectorAll('[data-startup-filter]').forEach(button => {
      button.addEventListener('click', () => {
        activeFilter = button.dataset.startupFilter || 'all';
        updateFilters();
        renderCatalogue();
      });
    });
    updateFilters();
    loadCatalogue();
    loadDetail();
  }

  document.addEventListener('DOMContentLoaded', mount);
  window.addEventListener('b1:languagechange', () => {
    updateFilters();
    renderCatalogue();
  });
})();
