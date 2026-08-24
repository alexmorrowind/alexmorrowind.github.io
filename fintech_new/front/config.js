(function () {
  const host = window.location.hostname;

  if (host === 'b1pay.uz' || host === 'www.b1pay.uz') {
    window.B1_API_BASE_URL = 'https://api.b1pay.uz/api';
    return;
  }

  if (host === 'alexmorrowind.github.io') {
    window.B1_API_BASE_URL = 'https://alexmorrowind-github-io.onrender.com/api';
    return;
  }

  if (host === 'localhost' || host === '127.0.0.1') {
    window.B1_API_BASE_URL = 'http://127.0.0.1:8000/api';
    return;
  }

  window.B1_API_BASE_URL = window.B1_API_BASE_URL || '';
})();
