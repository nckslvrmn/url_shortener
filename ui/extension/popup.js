document.getElementById("shorten").addEventListener("click", getURL);

function getURL() {
  chrome.tabs.query({active: true, currentWindow: true}, tabs => {
      url = tabs[0].url;
      storeURL(url);
  });
}

function storeURL(url) {
  div = document.getElementById("url");
  fetch('https://s.slvr.io/store', {
      method: 'post',
      body: JSON.stringify({
        full_url: url
      })
    })
    .then((resp) => resp.json())
    .then(function(data) {
      var short_url = `https://s.slvr.io/${data.short_url_id}`;
      var respHTML = `<br /><div class="text-center mw-100" id="response"><button class="btn btn-secondary mx-2" id="copy"><i class="fas fa-solid fa-copy"></i></button><a id="short_url" href="${short_url}" target="_blank">${short_url}</a></div>`;
      div.innerHTML = respHTML;
      document.getElementById("copy").addEventListener("click", copyURL);
    })
    .catch((error) => {
      var respHTML = `<br /><div class="alert alert-danger" role="alert">There was an error storing the shortened URL</div>`;
      div.innerHTML = respHTML;
  });
}

function copyURL(url) {
  link = document.getElementById("short_url");
  response = document.getElementById("response");
  navigator.clipboard.writeText(link.textContent);
  response.innerHTML += "<br />link copied!";
}
