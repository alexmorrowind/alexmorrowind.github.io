(function () {
  const profile = {
    score: 742,
    activeLoans: 2,
    totalDebt: 38200000,
    monthlyPayment: 3400000,
    onTime: 96,
    investments: 12600000,
    expenses: 8900000,
    loans: [
      { bank: 'Kapitalbank', productUz: 'Iste’mol krediti', productRu: 'Потребительский кредит', balance: 18200000, monthly: 1800000, statusUz: 'O‘z vaqtida', statusRu: 'В срок' },
      { bank: 'TBC Bank', productUz: 'Muddatli to‘lov', productRu: 'Рассрочка', balance: 20000000, monthly: 1600000, statusUz: 'O‘z vaqtida', statusRu: 'В срок' },
    ],
    timeline: [
      { icon: '+', titleUz: 'Yangi to‘lov qayd etildi', titleRu: 'Платёж зафиксирован', textUz: 'Kapitalbank krediti bo‘yicha navbatdagi to‘lov o‘z vaqtida yopildi.', textRu: 'Очередной платёж по кредиту Kapitalbank закрыт вовремя.' },
      { icon: '✓', titleUz: 'Qarz yuklamasi barqaror', titleRu: 'Нагрузка стабильная', textUz: 'Oylik kredit to‘lovlari taxminiy daromadning xavfsiz chegarasida.', textRu: 'Ежемесячные платежи остаются в безопасной зоне дохода.' },
      { icon: 'i', titleUz: 'Rasmiy integratsiya kerak', titleRu: 'Нужна официальная интеграция', textUz: 'Real kredit tarixi uchun rozilik va bank/kredit byurosi API kerak bo‘ladi.', textRu: 'Для реальной истории нужны согласие и API банка/кредитного бюро.' },
    ],
  };

  function language() {
    return localStorage.getItem('bpay_lang') || localStorage.getItem('selectedLanguage') || 'uz';
  }

  function text(uz, ru) {
    return language() === 'ru' ? ru : uz;
  }

  function formatMoney(value, compact) {
    return new Intl.NumberFormat(language() === 'ru' ? 'ru-RU' : 'uz-UZ', {
      notation: compact ? 'compact' : 'standard',
      maximumFractionDigits: 0,
    }).format(Math.round(value)) + ' UZS';
  }

  function renderMetrics() {
    const root = document.getElementById('historyMetrics');
    if (!root) return;
    const metrics = [
      [text('Faol kreditlar', 'Активные кредиты'), profile.activeLoans, text('Hozir ochiq majburiyatlar', 'Открытые обязательства')],
      [text('Qarz qoldig‘i', 'Остаток долга'), formatMoney(profile.totalDebt, true), text('Barcha faol kreditlar bo‘yicha', 'По всем активным кредитам')],
      [text('Oylik to‘lov', 'Платёж в месяц'), formatMoney(profile.monthlyPayment, true), text('Taxminiy kredit yuklamasi', 'Ориентировочная нагрузка')],
      [text('To‘lov intizomi', 'Платёжная дисциплина'), `${profile.onTime}%`, text('O‘z vaqtida yopilgan to‘lovlar', 'Платежи, закрытые вовремя')],
      [text('Investitsiya', 'Инвестировано'), formatMoney(profile.investments, true), text('Startap va fondlar bo‘yicha demo', 'Демо по стартапам и фондам')],
      [text('Xarajatlar', 'Расходы'), formatMoney(profile.expenses, true), text('So‘nggi oy bo‘yicha demo', 'Демо за последний месяц')],
      [text('Kredit bali', 'Кредитный балл'), profile.score, text('B1 ichki demo bahosi', 'Внутренняя демо-оценка B1')],
      [text('Holat', 'Статус'), text('Yaxshi', 'Хорошо'), text('Ariza topshirishga tayyor', 'Готов к заявке')],
    ];

    root.innerHTML = metrics.map(([label, value, caption]) => `
      <article class="history-card">
        <div class="history-card-label">${label}</div>
        <strong>${value}</strong>
        <span>${caption}</span>
      </article>
    `).join('');
  }

  function renderLoans() {
    const root = document.getElementById('historyLoans');
    if (!root) return;
    root.innerHTML = `
      <table class="history-table">
        <thead>
          <tr>
            <th>${text('Bank', 'Банк')}</th>
            <th>${text('Mahsulot', 'Продукт')}</th>
            <th>${text('Qoldiq', 'Остаток')}</th>
            <th>${text('Holat', 'Статус')}</th>
          </tr>
        </thead>
        <tbody>
          ${profile.loans.map(loan => `
            <tr>
              <td>${loan.bank}</td>
              <td>${text(loan.productUz, loan.productRu)}</td>
              <td>${formatMoney(loan.balance, true)}</td>
              <td><span class="history-pill">${text(loan.statusUz, loan.statusRu)}</span></td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;
  }

  function renderTimeline() {
    const root = document.getElementById('historyTimeline');
    if (!root) return;
    root.innerHTML = profile.timeline.map(event => `
      <div class="history-event">
        <div class="history-event-dot">${event.icon}</div>
        <div>
          <strong>${text(event.titleUz, event.titleRu)}</strong>
          <span>${text(event.textUz, event.textRu)}</span>
        </div>
      </div>
    `).join('');
  }

  function renderHero() {
    const title = document.getElementById('historyScoreTitle');
    const description = document.getElementById('historyScoreText');
    if (title) title.textContent = text('Yaxshi kredit profili', 'Хороший кредитный профиль');
    if (description) {
      description.textContent = text(
        'To‘lov intizomi yaxshi, qarz yuklamasi nazoratda. Real ma’lumot uchun foydalanuvchi roziligi va rasmiy integratsiya kerak.',
        'Платёжная дисциплина хорошая, долговая нагрузка под контролем. Для реальных данных нужны согласие пользователя и официальная интеграция.'
      );
    }
  }

  function mount() {
    renderHero();
    renderMetrics();
    renderLoans();
    renderTimeline();
  }

  document.addEventListener('DOMContentLoaded', mount);
  window.addEventListener('b1:languagechange', mount);
})();
