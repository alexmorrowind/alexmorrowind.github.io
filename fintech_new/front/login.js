(function () {
  let currentLang = localStorage.getItem('b1_lang') || 'uz';
  let currentSessionId = '';
  let pollTimer = null;
  let authFlow = 'login';

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

  function setWebAuthStatus(message, isError = false) {
    const status = document.getElementById('webAuthStatus');
    if (!status) return;
    status.textContent = message || '';
    status.style.color = isError ? '#b91c1c' : 'var(--muted)';
  }

  function setAuthFlow(flow) {
    authFlow = flow === 'register' ? 'register' : 'login';
    document.getElementById('loginTab')?.classList.toggle('active', authFlow === 'login');
    document.getElementById('registerTab')?.classList.toggle('active', authFlow === 'register');
    const loginForm = document.getElementById('myIdLoginForm');
    const registerForm = document.getElementById('myIdRegisterForm');
    if (loginForm) loginForm.hidden = authFlow !== 'login';
    if (registerForm) registerForm.hidden = authFlow !== 'register';
    setWebAuthStatus('');
  }

  function cleanMyIdCallbackQuery() {
    const url = new URL(window.location.href);
    ['myid_status', 'myid_session', 'reason_code', 'message'].forEach((key) => url.searchParams.delete(key));
    window.history.replaceState({}, document.title, url.toString());
  }

  async function completeMyIdWebFlow() {
    const params = new URLSearchParams(window.location.search);
    const status = params.get('myid_status');
    const sessionId = params.get('myid_session') || localStorage.getItem('pendingMyIdWebSession') || '';
    if (!status && !sessionId) return false;

    if (status !== 'verified') {
      setWebAuthStatus(params.get('message') || (currentLang === 'uz'
        ? 'MyID tekshiruvi tugallanmagan. Qayta urinib ko‘ring.'
        : 'Проверка MyID не завершена. Попробуйте ещё раз.'), true);
      localStorage.removeItem('pendingMyIdWebSession');
      cleanMyIdCallbackQuery();
      return true;
    }

    if (!sessionId) {
      setWebAuthStatus(currentLang === 'uz' ? 'MyID sessiyasi topilmadi.' : 'Сессия MyID не найдена.', true);
      cleanMyIdCallbackQuery();
      return true;
    }

    setWebAuthStatus(currentLang === 'uz' ? 'MyID tasdiqlovi yakunlanmoqda...' : 'Завершаем подтверждение MyID...');
    try {
      const data = await apiRequest('/auth/myid/redirect/complete/', {
        method: 'POST',
        body: JSON.stringify({ session_id: sessionId }),
      });
      storeTokens(data.tokens, data.profile || {});
      localStorage.removeItem('pendingMyIdWebSession');
      cleanMyIdCallbackQuery();
      setWebAuthStatus(currentLang === 'uz' ? 'Tasdiqlandi. Kabinet ochilmoqda...' : 'Подтверждено. Открываем кабинет...');
      window.setTimeout(goToDashboard, 500);
    } catch (error) {
      setWebAuthStatus(currentLang === 'uz'
        ? `Tasdiqlash xatosi: ${error.message}`
        : `Ошибка подтверждения: ${error.message}`, true);
      cleanMyIdCallbackQuery();
    }
    return true;
  }

  async function startMyIdWebFlow(event) {
    event.preventDefault();
    const payload = { flow: authFlow, account_type: 'physical' };
    if (authFlow === 'login') {
      const identifier = document.getElementById('loginIdentifier')?.value.trim() || '';
      if (!identifier) {
        setWebAuthStatus(currentLang === 'uz' ? 'Telefon yoki emailni kiriting.' : 'Введите телефон или email.', true);
        return;
      }
      if (identifier.includes('@')) payload.email = identifier;
      else payload.phone = identifier;
    } else {
      payload.first_name = document.getElementById('registerFirstName')?.value.trim() || '';
      payload.last_name = document.getElementById('registerLastName')?.value.trim() || '';
      payload.email = document.getElementById('registerEmail')?.value.trim() || '';
      payload.phone = document.getElementById('registerPhone')?.value.trim() || '';
      payload.password = document.getElementById('registerPassword')?.value || '';
      payload.agreed_on_terms = document.getElementById('registerConsent')?.checked === true;
    }

    const button = event.submitter;
    if (button) button.disabled = true;
    setWebAuthStatus(currentLang === 'uz'
      ? 'MyID oynasi tayyorlanmoqda...'
      : 'Готовим окно MyID...');
    try {
      const data = await apiRequest('/auth/myid/redirect/start/', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
      localStorage.setItem('pendingMyIdWebSession', data.session_id || '');
      window.location.assign(data.redirect_url);
    } catch (error) {
      setWebAuthStatus(currentLang === 'uz'
        ? `MyID ishga tushmadi: ${error.message}`
        : `Не удалось открыть MyID: ${error.message}`, true);
      if (button) button.disabled = false;
    }
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
    const loginTab = document.getElementById('loginTab');
    const registerTab = document.getElementById('registerTab');
    const loginForm = document.getElementById('myIdLoginForm');
    const registerForm = document.getElementById('myIdRegisterForm');

    if (refreshBtn) refreshBtn.addEventListener('click', startQrSession);
    if (copyBtn) copyBtn.addEventListener('click', pollQrStatus);
    if (loginTab) loginTab.addEventListener('click', () => setAuthFlow('login'));
    if (registerTab) registerTab.addEventListener('click', () => setAuthFlow('register'));
    if (loginForm) loginForm.addEventListener('submit', startMyIdWebFlow);
    if (registerForm) registerForm.addEventListener('submit', startMyIdWebFlow);
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
      completeMyIdWebFlow().then((callbackHandled) => {
        if (!callbackHandled) startQrSession();
      });
    }
  });
})();
