const portInput = document.getElementById('port');
const tokenInput = document.getElementById('token');
const useMemo = document.getElementById('useMemo');
const memoEl = document.getElementById('memo');
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

useMemo.addEventListener('change', () => {
  memoEl.style.display = useMemo.checked ? 'block' : 'none';
});

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

  const memo = useMemo.checked ? memoEl.value.trim() : '';
  const result = await saveUrlToDontDelay({
    url: tab.url,
    title: tab.title || tab.url,
    memo,
  });

  showStatus(result.message, result.ok);
  if (result.ok) {
    lastSavedEl.style.display = 'block';
    lastSavedEl.textContent = `최근 저장: ${tab.title || tab.url}`;
    if (useMemo.checked) memoEl.value = '';
  }
});

loadSettings();
