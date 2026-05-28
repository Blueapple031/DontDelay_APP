const MENU_PAGE = 'dontdelay-save-page';
const MENU_PAGE_MEMO = 'dontdelay-save-page-memo';
const MENU_LINK = 'dontdelay-save-link';
const MENU_LINK_MEMO = 'dontdelay-save-link-memo';

importScripts('save_api.js');

function setupContextMenus() {
  chrome.contextMenus.removeAll(() => {
    chrome.contextMenus.create({
      id: MENU_PAGE,
      title: 'DontDelay에 저장',
      contexts: ['page'],
    });
    chrome.contextMenus.create({
      id: MENU_PAGE_MEMO,
      title: 'DontDelay에 저장 (메모)',
      contexts: ['page'],
    });
    chrome.contextMenus.create({
      id: MENU_LINK,
      title: 'DontDelay에 저장 (링크)',
      contexts: ['link'],
    });
    chrome.contextMenus.create({
      id: MENU_LINK_MEMO,
      title: 'DontDelay에 저장 (링크·메모)',
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

  if (info.menuItemId === MENU_PAGE_MEMO) {
    const url = tab?.url;
    if (!url) return;
    openSaveMemoTab(url, tab.title || url);
    return;
  }

  if (info.menuItemId === MENU_LINK) {
    const url = info.linkUrl;
    if (!url) return;
    const title =
      info.linkText?.trim() || info.selectionText?.trim() || tab?.title || url;
    await saveUrl(url, title);
    return;
  }

  if (info.menuItemId === MENU_LINK_MEMO) {
    const url = info.linkUrl;
    if (!url) return;
    const title =
      info.linkText?.trim() || info.selectionText?.trim() || tab?.title || url;
    openSaveMemoTab(url, title);
  }
});

chrome.commands.onCommand.addListener(async (command) => {
  if (command !== 'save-url') return;
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (tab?.url) {
    await saveUrl(tab.url, tab.title || tab.url);
  }
});
