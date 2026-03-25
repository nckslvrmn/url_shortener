document.addEventListener('DOMContentLoaded', async () => {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  const currentUrlEl = document.getElementById('current-url');
  currentUrlEl.textContent = tab.url;

  document.getElementById('shorten-btn').addEventListener('click', () => {
    const permanent = document.getElementById('permanent-check').checked;
    const customId = document.getElementById('custom-id-input').value.trim() || null;
    shortenUrl(tab.url, { permanent, customId });
  });
});

async function shortenUrl(url, { permanent = false, customId = null } = {}) {
  const btn = document.getElementById('shorten-btn');
  const result = document.getElementById('result');
  const error = document.getElementById('error');

  btn.disabled = true;
  btn.textContent = 'Shortening…';
  result.classList.add('hidden');
  error.classList.add('hidden');

  try {
    const payload = { full_url: url };
    if (permanent) payload.permanent = true;
    if (customId) payload.custom_id = customId;

    const response = await fetch('https://s.slvr.io/store', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const errData = await response.json().catch(() => null);
      throw new Error(errData?.detail || `HTTP ${response.status}`);
    }

    const data = await response.json();
    const shortUrl = `https://s.slvr.io/${data.short_url_id}`;

    const shortUrlEl = document.getElementById('short-url');
    shortUrlEl.textContent = shortUrl;
    shortUrlEl.href = shortUrl;
    result.classList.remove('hidden');

    const copyBtn = document.getElementById('copy-btn');
    copyBtn.onclick = async () => {
      await navigator.clipboard.writeText(shortUrl);
      copyBtn.textContent = 'Copied!';
      copyBtn.classList.add('copied');
      setTimeout(() => {
        copyBtn.textContent = 'Copy';
        copyBtn.classList.remove('copied');
      }, 2000);
    };
  } catch (e) {
    error.textContent = e.message && !e.message.startsWith('HTTP')
      ? e.message
      : 'Failed to shorten URL. Please try again.';
    error.classList.remove('hidden');
  } finally {
    btn.disabled = false;
    btn.textContent = 'Shorten URL';
  }
}
