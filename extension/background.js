const MENU_PAGE = 'dontdelay-save-page';
const MENU_LINK = 'dontdelay-save-link';

function setupContextMenus() {
  chrome.contextMenus.removeAll(() => {
    chrome.contextMenus.create({
      id: MENU_PAGE,
      title: 'DontDelay에 저장 (이 페이지)',
      contexts: ['page'],
    });
    chrome.contextMenus.create({
      id: MENU_LINK,
      title: 'DontDelay에 저장 (이 링크)',
      contexts: ['link'],
    });
  });
}

chrome.runtime.onInstalled.addListener(() => {
  setupContextMenus();
});

chrome.runtime.onStartup.addListener(() => {
  setupContextMenus();
});

setupContextMenus();

chrome.contextMenus.onClicked.addListener(async (info, tab) => {
  if (info.menuItemId === MENU_PAGE) {
    const url = tab?.url;
    if (!url) return;
    await saveUrl(url, tab.title || url);
    return;
  }

  if (info.menuItemId === MENU_LINK) {
    const url = info.linkUrl;
    if (!url) return;
    const title =
      info.linkText?.trim() || info.selectionText?.trim() || tab?.title || url;
    await saveUrl(url, title);
  }
});

chrome.commands.onCommand.addListener(async (command) => {
  if (command !== 'save-url') return;
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (tab?.url) {
    await saveUrl(tab.url, tab.title || tab.url);
  }
});

async function getSettings() {
  const data = await chrome.storage.local.get(['port', 'token']);
  return {
    port: data.port || 17823,
    token: data.token || '',
  };
}

async function saveUrl(url, title) {
  const { port, token } = await getSettings();

  if (!token) {
    notify('DontDelay', '확장 설정에서 토큰을 입력해 주세요.');
    setBadge('!', '#DC2626');
    return;
  }

  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    notify('DontDelay', 'http/https URL만 저장할 수 있습니다.');
    setBadge('!', '#DC2626');
    return;
  }

  try {
    const response = await fetch(`http://127.0.0.1:${port}/api/urls`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ url, title, source: 'extension' }),
    });

    const body = await response.json().catch(() => ({}));

    if (response.status === 201) {
      notify('DontDelay', 'URL이 저장되었습니다.');
      setBadge('OK', '#059669');
      await chrome.storage.local.set({
        lastSaved: { url, title, at: new Date().toISOString() },
      });
      return;
    }

    if (response.status === 409) {
      notify('DontDelay', '이미 저장된 URL입니다.');
      setBadge('!', '#F97316');
      return;
    }

    if (response.status === 401) {
      notify('DontDelay', '토큰이 올바르지 않습니다. 앱에서 토큰을 확인하세요.');
      setBadge('!', '#DC2626');
      return;
    }

    notify('DontDelay', body.message || `저장 실패 (${response.status})`);
    setBadge('!', '#DC2626');
  } catch (_) {
    notify(
      'DontDelay',
      'DontDelay 앱이 실행 중인지 확인해 주세요.',
    );
    setBadge('!', '#DC2626');
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
