// Public frontend config. Do not put API keys or secrets here.
// Local frontend uses http://127.0.0.1:8000/api automatically from script.js.
// GitHub Pages needs the public Render backend URL.
(function () {
  const productionApiUrl = 'https://b1-fintech-backend.onrender.com/api';
  const host = window.location.hostname;

  if (host === 'alexmorrowind.github.io') {
    window.B1_API_BASE_URL = productionApiUrl;
    return;
  }

  window.B1_API_BASE_URL = window.B1_API_BASE_URL || '';
})();
