async function checkUserProfile() {
    const token = localStorage.getItem('accessToken');

    if (!token) {
        // Если токена нет, выкидываем его обратно на страницу логина
        window.location.href = 'login.html';
        return;
    }

    try {
        const configuredApi = window.B1_API_BASE_URL ? window.B1_API_BASE_URL.replace(/\/$/, '') : '';
        const githubPagesApi = window.location.hostname === 'alexmorrowind.github.io'
            ? 'https://alexmorrowind-github-io.onrender.com/api'
            : '';
        const localApi = ['127.0.0.1', 'localhost', ''].includes(window.location.hostname)
            ? 'http://127.0.0.1:8000/api'
            : `${window.location.origin}/api`;
        const response = await fetch(`${configuredApi || githubPagesApi || localApi}/user/profile/`, {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${token}` // Передаем токен авторизации
            }
        });

        if (response.ok) {
            const userData = await response.json();
            console.log('Данные пользователя:', userData);
            // Тут ты можешь, например, отобразить почту юзера на экране:
            // document.getElementById('userEmailDisplay').innerText = userData.email;
        } else {
            // Если токен протух или неверный
            localStorage.removeItem('accessToken');
            window.location.href = 'login.html';
        }
    } catch (error) {
        console.error('Ошибка профиля:', error);
    }
}

// Запускаем проверку при загрузке страницы личного кабинета
if (window.location.pathname.includes('landing.html')) {
    checkUserProfile();
}
