(function () {
  let currentLang = localStorage.getItem('b1_lang') || 'uz';
  let currentSessionId = '';
  let pollTimer = null;

  function getApiBaseUrl() {
    if (window.B1_API_BASE_URL) return window.B1_API_BASE_URL.replace(/\/$/, '');
    const host = window.location.hostname;
    if (host === 'alexmorrowind.github.io') return 'https://alexmorrowind-github-io.onrender.com/api';
    if (host === '127.0.0.1' || host === 'localhost' || host === '') return 'http://127.0.0.1:8000/api';
    return `${window.location.origin}/api`;
  }

  const API_URL = getApiBaseUrl();

  async function apiRequest(path, options = {}) {
    const response = await fetch(`${API_URL}${path}`, {
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        ...(options.headers || {}),
      },
      ...options,
    });
    const text = await response.text();
    const body = text ? JSON.parse(text) : {};
    if (!response.ok) {
      const message = body.detail || body.message || body.error || `HTTP ${response.status}`;
      const error = new Error(message);
      error.body = body;
      error.status = response.status;
      throw error;
    }
    return body;
  }

  function setTextByLang() {
    document.documentElement.lang = currentLang;
    document.querySelectorAll('[data-uz]').forEach((el) => {
      const value = el.getAttribute(`data-${currentLang}`);
      if (!value) return;
      if (el.tagName === 'INPUT') {
        el.placeholder = value;
      } else {
        el.textContent = value;
      }
    });
    document.querySelectorAll('.lang-switch button').forEach((button) => {
      const active = button.textContent.trim().toUpperCase() === currentLang.toUpperCase();
      button.classList.toggle('active', active);
    });
  }

  function setLang(lang) {
    currentLang = lang === 'ru' ? 'ru' : 'uz';
    localStorage.setItem('b1_lang', currentLang);
    setTextByLang();
    if (currentSessionId) {
      updateStatus(currentLang === 'uz'
        ? 'QR sessiyasi tayyor. Telefoningizdan skanerlang.'
        : 'QR-сессия готова. Отсканируйте ее с телефона.');
    }
  }

  function updateStatus(message) {
    const status = document.getElementById('qrStatus');
    if (status) status.textContent = message;
  }

  function setLoading(loading) {
    const img = document.getElementById('qrImage');
    const loadingEl = document.getElementById('qrLoading');
    if (img) img.style.display = loading ? 'none' : 'block';
    if (loadingEl) loadingEl.style.display = loading ? 'block' : 'none';
  }

  function stopPolling() {
    if (pollTimer) {
      clearInterval(pollTimer);
      pollTimer = null;
    }
  }

  function storeTokens(tokens, profile = {}) {
    if (!tokens) return;
    if (tokens.access) localStorage.setItem('accessToken', tokens.access);
    if (tokens.refresh) localStorage.setItem('refreshToken', tokens.refresh);
    if (profile.phone) localStorage.setItem('userPhone', profile.phone);
    if (profile.first_name) localStorage.setItem('userFirstName', profile.first_name);
    if (profile.last_name) localStorage.setItem('userLastName', profile.last_name);
    if (profile.email) localStorage.setItem('userEmail', profile.email);
  }

  function goToDashboard() {
    window.location.href = 'index.html';
  }

  async function pollQrStatus() {
    if (!currentSessionId) return;
    try {
      const data = await apiRequest('/auth/qr/status/', {
        method: 'POST',
        body: JSON.stringify({ session_id: currentSessionId }),
      });

      if (data.status === 'verified' && data.tokens) {
        stopPolling();
        storeTokens(data.tokens, data.profile || {});
        updateStatus(currentLang === 'uz'
          ? 'Tasdiqlandi. Sahifa ochilmoqda...'
          : 'Подтверждено. Открываем страницу...');
        setTimeout(goToDashboard, 900);
        return;
      }

      if (data.status === 'expired') {
        stopPolling();
        updateStatus(currentLang === 'uz'
          ? 'QR muddati tugadi. Yangisini yarating.'
          : 'Срок QR истек. Создайте новый код.');
      }
    } catch (error) {
      updateStatus(currentLang === 'uz'
        ? `Holat tekshirish xatosi: ${error.message}`
        : `Ошибка проверки статуса: ${error.message}`);
    }
  }

  async function startQrSession() {
    stopPolling();
    setLoading(true);
    updateStatus(currentLang === 'uz'
      ? 'QR sessiyasi yaratilmoqda...'
      : 'Создаем QR-сессию...');

    try {
      const data = await apiRequest('/auth/qr/start/', {
        method: 'POST',
        body: JSON.stringify({}),
      });

      currentSessionId = data.session_id || '';
      const img = document.getElementById('qrImage');
      if (img && data.qr_image) {
        img.src = data.qr_image;
      }
      setLoading(false);
      updateStatus(currentLang === 'uz'
        ? 'Telefoningizdagi B1 ilovasida MyID ni tugating va shu QR ni skanerlang.'
        : 'Завершите MyID в приложении B1 и отсканируйте этот QR на телефоне.');

      if (data.status === 'verified' && data.tokens) {
        storeTokens(data.tokens, data.profile || {});
        goToDashboard();
        return;
      }

      pollQrStatus();
      pollTimer = window.setInterval(pollQrStatus, 2200);
    } catch (error) {
      setLoading(false);
      updateStatus(currentLang === 'uz'
        ? `QR yaratib bo'lmadi: ${error.message}`
        : `Не удалось создать QR: ${error.message}`);
    }
  }

  async function checkUserProfile() {
    const token = localStorage.getItem('accessToken');
    if (!token) {
      window.location.href = 'login.html';
      return;
    }

    try {
      const response = await fetch(`${API_URL}/user/profile/`, {
        method: 'GET',
        headers: { Authorization: `Bearer ${token}` },
      });

      if (!response.ok) {
        localStorage.removeItem('accessToken');
        localStorage.removeItem('refreshToken');
        window.location.href = 'login.html';
      }
    } catch (error) {
      console.error('Ошибка профиля:', error);
    }
  }

  function wireEvents() {
    const refreshBtn = document.getElementById('refreshBtn');
    const copyBtn = document.getElementById('copyBtn');

    if (refreshBtn) refreshBtn.addEventListener('click', startQrSession);
    if (copyBtn) copyBtn.addEventListener('click', pollQrStatus);
  }

  window.setLang = setLang;

  document.addEventListener('DOMContentLoaded', () => {
    setTextByLang();
    wireEvents();

    if (window.location.pathname.includes('landing.html')) {
      checkUserProfile();
      return;
    }

    if (window.location.pathname.includes('login.html')) {
      startQrSession();
    }
  });
})();
