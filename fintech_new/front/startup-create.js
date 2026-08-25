(function () {
  const apiBase = (window.B1_API_BASE_URL || '').replace(/\/$/, '');

  function language() {
    return localStorage.getItem('bpay_lang') || 'uz';
  }

  function text(uz, ru) {
    return language() === 'ru' ? ru : uz;
  }

  function token() {
    return localStorage.getItem('accessToken') || localStorage.getItem('authToken') || '';
  }

  async function request(path, options) {
    if (!apiBase) throw new Error('API base is not configured');
    const response = await fetch(`${apiBase}${path}`, options);
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
      const error = new Error(payload.detail || 'Request failed');
      error.status = response.status;
      throw error;
    }
    return payload;
  }

  function showState(message) {
    const state = document.getElementById('startupCreateState');
    if (state) state.innerHTML = message;
  }

  function showForm(profile) {
    const form = document.getElementById('startupCreateForm');
    const company = document.getElementById('startupCreateCompany');
    if (company) company.textContent = profile.company_name || 'B1';
    if (form) form.hidden = false;
    const state = document.getElementById('startupCreateState');
    if (state) state.remove();
  }

  async function loadProfile() {
    if (!token()) {
      window.location.href = `login.html?next=${encodeURIComponent('startup-create.html')}`;
      return;
    }
    try {
      const profile = await request('/legal-entity/profile/', {
        headers: { Authorization: `Bearer ${token()}`, Accept: 'application/json' },
      });
      if (profile.status !== 'verified') {
        showState(`
          <strong>${text('Yuridik profil tekshiruvdan o‘tishi kerak.', 'Юридический профиль должен пройти проверку.')}</strong>
          <span>${text('Startapni nashr qilishdan oldin kompaniya ma’lumotlari tasdiqlangan bo‘lishi kerak.', 'Перед публикацией стартапа данные компании должны быть подтверждены.')}</span>
          <a href="index.html">${text('Kabinetga o‘tish', 'Перейти в кабинет')} →</a>
        `);
        return;
      }
      showForm(profile);
    } catch (error) {
      showState(`
        <strong>${text('Avval yuridik profil yarating.', 'Сначала создайте юридический профиль.')}</strong>
        <span>${text('Kompaniya ma’lumotlari va hujjatlar startapni katalogga chiqarishdan oldin tekshiriladi.', 'Данные компании и документы проверяются до публикации стартапа в каталоге.')}</span>
        <a href="index.html">${text('Kabinetga o‘tish', 'Перейти в кабинет')} →</a>
      `);
    }
  }

  async function submit(event) {
    event.preventDefault();
    const status = document.getElementById('startupCreateSubmitState');
    const payload = {
      name: document.getElementById('startupName').value.trim(),
      domain: document.getElementById('startupDomain').value,
      stage: document.getElementById('startupStage').value,
      funding_goal: Number(document.getElementById('startupGoal').value),
      min_investment: Number(document.getElementById('startupMinimum').value),
      roi: Number(document.getElementById('startupRoi').value),
      description: document.getElementById('startupDescription').value.trim(),
      contact_email: document.getElementById('startupContact').value.trim(),
    };
    if (!payload.name || !payload.description || !payload.contact_email || payload.funding_goal <= 0 || payload.min_investment <= 0) {
      if (status) status.textContent = text('Barcha majburiy maydonlarni to‘ldiring.', 'Заполните все обязательные поля.');
      return;
    }
    if (status) status.textContent = text('Startap profili yaratilmoqda...', 'Создаём профиль стартапа...');
    try {
      const startup = await request('/startups/', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token()}`, Accept: 'application/json', 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      window.location.href = `startup.html?id=${encodeURIComponent(startup.id)}`;
    } catch (error) {
      if (status) status.textContent = text(
        `Saqlab bo‘lmadi: ${error.message}`,
        `Не удалось сохранить: ${error.message}`
      );
    }
  }

  document.addEventListener('DOMContentLoaded', () => {
    loadProfile();
    document.getElementById('startupCreateForm')?.addEventListener('submit', submit);
  });
})();
