const portInput = document.getElementById('port');
const tokenInput = document.getElementById('token');
const saveBtn = document.getElementById('saveBtn');
const testBtn = document.getElementById('testBtn');
const statusEl = document.getElementById('status');
const lastSavedEl = document.getElementById('lastSaved');

async function loadSettings() {
  const data = await chrome.storage.local.get(['port', 'token', 'lastSaved']);
  if (data.port) portInput.value = data.port;
  if (data.token) tokenInput.value = data.token;
  if (data.lastSaved) {
    lastSavedEl.style.display = 'block';
    lastSavedEl.textContent = `최근 저장: ${data.lastSaved.title}`;
  }
}

async function saveSettings() {
  await chrome.storage.local.set({
    port: Number(portInput.value) || 17823,
    token: tokenInput.value.trim(),
  });
}

function showStatus(message, ok) {
  statusEl.textContent = message;
  statusEl.className = ok ? 'ok' : 'err';
}

portInput.addEventListener('change', saveSettings);
tokenInput.addEventListener('change', saveSettings);

testBtn.addEventListener('click', async () => {
  await saveSettings();
  const port = Number(portInput.value) || 17823;
  try {
    const response = await fetch(`http://127.0.0.1:${port}/api/health`);
    if (response.ok) {
      const data = await response.json();
      showStatus(`연결됨 — ${data.app} v${data.version}`, true);
    } else {
      showStatus(`연결 실패 (${response.status})`, false);
    }
  } catch (_) {
    showStatus('DontDelay 앱이 실행 중인지 확인해 주세요.', false);
  }
});

saveBtn.addEventListener('click', async () => {
  await saveSettings();
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (!tab?.url) {
    showStatus('현재 탭 URL을 가져올 수 없습니다.', false);
    return;
  }

  const port = Number(portInput.value) || 17823;
  const token = tokenInput.value.trim();

  if (!token) {
    showStatus('토큰을 입력해 주세요.', false);
    return;
  }

  try {
    const response = await fetch(`http://127.0.0.1:${port}/api/urls`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        url: tab.url,
        title: tab.title || tab.url,
        source: 'extension',
      }),
    });

    const body = await response.json().catch(() => ({}));

    if (response.status === 201) {
      showStatus('URL이 저장되었습니다.', true);
      await chrome.storage.local.set({
        lastSaved: {
          url: tab.url,
          title: tab.title || tab.url,
          at: new Date().toISOString(),
        },
      });
      lastSavedEl.style.display = 'block';
      lastSavedEl.textContent = `최근 저장: ${tab.title || tab.url}`;
      return;
    }

    if (response.status === 409) {
      showStatus('이미 저장된 URL입니다.', false);
      return;
    }

    if (response.status === 401) {
      showStatus('토큰이 올바르지 않습니다.', false);
      return;
    }

    showStatus(body.message || `저장 실패 (${response.status})`, false);
  } catch (_) {
    showStatus('DontDelay 앱이 실행 중인지 확인해 주세요.', false);
  }
});

loadSettings();
