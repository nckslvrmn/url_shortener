document.addEventListener('DOMContentLoaded', async () => {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  const currentUrlEl = document.getElementById('current-url');
  currentUrlEl.textContent = tab.url;

  document.getElementById('shorten-btn').addEventListener('click', () => shortenUrl(tab.url));
});

async function shortenUrl(url) {
  const btn = document.getElementById('shorten-btn');
  const result = document.getElementById('result');
  const error = document.getElementById('error');

  btn.disabled = true;
  btn.textContent = 'Shortening…';
  result.classList.add('hidden');
  error.classList.add('hidden');

  try {
    const response = await fetch('https://s.slvr.io/store', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ full_url: url }),
    });

    if (!response.ok) throw new Error(`HTTP ${response.status}`);

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
    error.textContent = 'Failed to shorten URL. Please try again.';
    error.classList.remove('hidden');
  } finally {
    btn.disabled = false;
    btn.textContent = 'Shorten URL';
  }
}
