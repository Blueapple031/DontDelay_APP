async function getSettings() {
  const data = await chrome.storage.local.get(['port', 'token']);
  return {
    port: data.port || 17823,
    token: data.token || '',
  };
}

/** Chrome 웹 스토어: host_permissions에 :* 포트 와일드카드 불가 → 런타임 권한 요청 */
async function ensureHostPermission(port) {
  const origins = [
    `http://127.0.0.1:${port}/*`,
    `http://localhost:${port}/*`,
  ];
  const granted = await chrome.permissions.contains({ origins });
  if (granted) return true;
  return chrome.permissions.request({ origins });
}

function isSavableUrl(url) {
  const trimmed = (url || '').trim();
  if (!trimmed) return false;
  try {
    const parsed = new URL(trimmed);
    const blocked = ['javascript:', 'data:', 'blob:', 'vbscript:'];
    return !blocked.includes(parsed.protocol.toLowerCase());
  } catch (_) {
    return /^[a-z][a-z0-9+.-]*:/i.test(trimmed);
  }
}

async function saveUrlToDontDelay({ url, title, memo = '', source = 'extension' }) {
  const { port, token } = await getSettings();

  if (!token) {
    return { ok: false, message: '확장 설정에서 토큰을 입력해 주세요.' };
  }

  if (!isSavableUrl(url)) {
    return { ok: false, message: '저장할 수 없는 URL 형식입니다.' };
  }

  const permitted = await ensureHostPermission(port);
  if (!permitted) {
    return {
      ok: false,
      message: '로컬 DontDelay 연결 권한이 필요합니다. 확장 팝업에서 허용해 주세요.',
    };
  }

  try {
    const response = await fetch(`http://127.0.0.1:${port}/api/urls`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ url, title, memo, source }),
    });

    const body = await response.json().catch(() => ({}));

    if (response.status === 201) {
      await chrome.storage.local.set({
        lastSaved: { url, title, memo, at: new Date().toISOString() },
      });
      return { ok: true, message: 'URL이 저장되었습니다.' };
    }
    if (response.status === 409) {
      return { ok: false, message: '이미 저장된 URL입니다.' };
    }
    if (response.status === 401) {
      return { ok: false, message: '토큰이 올바르지 않습니다.' };
    }
    return { ok: false, message: body.message || `저장 실패 (${response.status})` };
  } catch (_) {
    return { ok: false, message: 'DontDelay 앱이 실행 중인지 확인해 주세요.' };
  }
}

function notify(title, message) {
  chrome.notifications.create({
    type: 'basic',
    iconUrl: 'icons/icon48.png',
    title,
    message,
  });
}

function setBadge(text, color) {
  chrome.action.setBadgeText({ text });
  chrome.action.setBadgeBackgroundColor({ color });
  setTimeout(() => chrome.action.setBadgeText({ text: '' }), 3000);
}

async function saveUrl(url, title, memo = '') {
  const result = await saveUrlToDontDelay({ url, title, memo });
  if (result.ok) {
    notify('DontDelay', result.message);
    setBadge('OK', '#059669');
  } else {
    notify('DontDelay', result.message);
    setBadge('!', result.message.includes('이미') ? '#F97316' : '#DC2626');
  }
  return result;
}

function openSaveMemoTab(url, title) {
  const params = new URLSearchParams({
    url,
    title: title || url,
  });
  chrome.tabs.create({
    url: `save_dialog/save_dialog.html?${params.toString()}`,
  });
}
