const params = new URLSearchParams(location.search);
const pageUrl = params.get('url') || '';
const pageTitle = params.get('title') || pageUrl;

document.getElementById('title').textContent = pageTitle;
document.getElementById('url').textContent = pageUrl;

const memoEl = document.getElementById('memo');
const saveBtn = document.getElementById('saveBtn');
const cancelBtn = document.getElementById('cancelBtn');
const statusEl = document.getElementById('status');

memoEl.focus();

cancelBtn.addEventListener('click', () => window.close());

saveBtn.addEventListener('click', async () => {
  saveBtn.disabled = true;
  const result = await saveUrlToDontDelay({
    url: pageUrl,
    title: pageTitle,
    memo: memoEl.value.trim(),
  });

  statusEl.textContent = result.message;
  statusEl.className = result.ok ? 'ok' : 'err';

  if (result.ok) {
    notify('DontDelay', result.message);
    setBadge('OK', '#059669');
    setTimeout(() => window.close(), 800);
  } else {
    saveBtn.disabled = false;
  }
});
