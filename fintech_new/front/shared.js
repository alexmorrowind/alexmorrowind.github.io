// Lang switcher
function setLang(lang) {
  document.querySelectorAll('[data-uz],[data-ru]').forEach(el => {
    if (lang === 'ru' && el.dataset.ru) el.textContent = el.dataset.ru;
    else if (lang === 'uz' && el.dataset.uz) el.textContent = el.dataset.uz;
  });
  document.querySelectorAll('.lang-btn').forEach(b => b.classList.remove('active'));
  const btn = document.querySelector(`.lang-btn[onclick="setLang('${lang}')"]`);
  if (btn) btn.classList.add('active');
  localStorage.setItem('bpay_lang', lang);
}

document.addEventListener('DOMContentLoaded', () => {
  const saved = localStorage.getItem('bpay_lang');
  if (saved) setLang(saved);

  // Active nav link
  const path = location.pathname.split('/').pop() || 'landing.html';
  document.querySelectorAll('.nav-link').forEach(a => {
    const href = a.getAttribute('href') || '';
    if (href === path || href === '#' + path.replace('.html', '')) {
      a.classList.add('active');
    }
  });
});

// Словарь переводов для локализации
const translations = {
  'uz': {
    'nav-main': 'Asosiy',
    'nav-banks': 'Banklar',
    'nav-profile': 'Profil',
    'profile-title': 'Foydalanuvchi profili',
    'lbl-name': 'Ismingiz:',
    'lbl-phone': 'Telefon raqamingiz:',
    'lbl-lang': 'Tizim tili:',
    'btn-save': 'Saqlash',
    'balance-title': 'Sizning balansingiz',
    'currency': 'UZS'
  },
  'ru': {
    'nav-main': 'Главная',
    'nav-banks': 'Банки',
    'nav-profile': 'Профиль',
    'profile-title': 'Профиль пользователя',
    'lbl-name': 'Ваше имя:',
    'lbl-phone': 'Номер телефона:',
    'lbl-lang': 'Язык системы:',
    'btn-save': 'Сохранить',
    'balance-title': 'Ваш баланс',
    'currency': 'сум'
  }
};

// Функция для применения языка на странице
function applyLanguage(lang) {
  localStorage.setItem('selectedLanguage', lang);

  // Находим все элементы с атрибутом data-i18n и меняем текст
  document.querySelectorAll('[data-i18n]').forEach(element => {
    const key = element.getAttribute('data-i18n');
    if (translations[lang] && translations[lang][key]) {
      element.innerText = translations[lang][key];
    }
  });

  // Если на странице есть селектор выбора языка, устанавливаем его значение
  const langSelect = document.getElementById('language-select');
  if (langSelect) {
    langSelect.value = lang;
  }
}

// Вызывается автоматически при загрузке любой страницы
document.addEventListener('DOMContentLoaded', () => {
  const savedLang = localStorage.getItem('selectedLanguage') || 'uz';
  applyLanguage(savedLang);

  // Инициализируем данные пользователя, если их еще нет в базе браузера
  if (!localStorage.getItem('userName')) {
    localStorage.setItem('userName', 'Mehmon');
    localStorage.setItem('userPhone', '+998 (90) 123-45-67');
    localStorage.setItem('userBalance', '500000');
  }
});
