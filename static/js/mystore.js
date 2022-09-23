function _cacheScript(url) {
  return new Promise(function (resolve, reject) {
    const xhr = new XMLHttpRequest();
    xhr.open("GET", url);
    xhr.onload = function () {
      return 200 == xhr.status
        ? resolve(xhr.responseText)
        : reject(xhr.statusText + url);
    };
    xhr.onerror = function () {
      return reject(xhr.statusText + url);
    };
    xhr.send();
  });
}
function _injectScript(content, tag, isCss) {
  return new Promise(function (resolve, reject) {
    const t = document.createElement(tag);
    t.onload = function () {
      resolve(tag);
    };
    t.onerror = function () {
      reject(tag);
    };
    if (tag == "link") {
      t.rel = "stylesheet";
      t.href = isCss
        ? content
        : "data:text/css;charset=UTF-8," + encodeURIComponent(content);
    } else {
      t.type = "text/javascript";
      t.src = "data:text/javascript," + encodeURIComponent(content);
    }
    document.getElementsByTagName("head")[0].appendChild(t);
  });
}
function getsScript(name, version, url, tag, type, callback) {
  var c = null;
  try {
    (c = localStorage.getItem(name)), con;
  } catch (err) {}

  if (c != null) {
    con = JSON.parse(c);
    if (con.version == version) {
      _injectScript(con.content, tag, false).then(function (tag) {
        callback();
      });
    } else localStorage.removeItem(name);
  }
  if ((c != null && con.version != version) || c == null)
    _cacheScript(url)
      .then(function (data) {
        localStorage.setItem(
          name,
          JSON.stringify({ content: data, version: version })
        );
        _injectScript(data, tag, false).then(function (tag) {
          callback();
        });
      })
      .catch(function (err) {});
}
function ensureFooIsSet() {
  return new Promise(function (resolve, reject) {
    (function waitForFoo() {
      if (typeof rxjs !== "undefined") return resolve();
      setTimeout(waitForFoo, 10);
    })();
  });
}
