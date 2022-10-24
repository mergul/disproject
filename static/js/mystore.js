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
function myRoute(event) {
  const uparts = event.currentTarget.href.split("/");
  console.log("myRoute --> ", uparts);
  if (uparts[uparts.length - 2] === "auth") return;
  event.preventDefault();
  const makey = uparts[uparts.length - 1]
    .replace("newr", "new")
    .replace("adminr", "admin");
  window.history.pushState(
    {},
    "newUrl",
    event.currentTarget.href
      .replace("home", "")
      .replace("/postz/", "/posts/")
      .replace("/newr", "/new")
      .replace("/adminr", "/admin")
      .replace("/profiles", "/profile")
  );
  if (!mamap.has(makey)) {
    console.log("myRoute mamap has not --> ", uparts);
    var it = sessionStorage.getItem(makey);
    it !== null
      ? setHTML(parser.parseFromString(it, "text/html"), makey)
      : fetch(event.currentTarget.href)
          .then((data) => data.text())
          .then((html) => {
            // console.log(html);
            var doc = parser.parseFromString(html, "text/html");
            setHTML(doc, makey);
            sessionStorage.setItem(makey, html);
            console.log("myRoute fetch --> ", mamap);
          });
  } else {
    setHTML(mamap.get(makey));
    if (makey === "admin") recreateChart(bar);
  }
}
function setHTML(el, key = "") {
  document.querySelector("main.container").innerHTML =
    el.querySelector("main.container").innerHTML;
  console.log("link --> ", el.querySelector("link"));
  if (!!el.querySelector("link"))
    document
      .getElementsByTagName("head")[0]
      .appendChild(el.querySelector("link"));
  if (!!el.querySelector("script")) {
    var sList = el.getElementsByTagName("script");
    for (const asd of sList)
      getsScript(
        key + asd.src.substr(-5),
        1,
        asd.src,
        "script",
        "script",
        () => {
          console.log("sList");
        }
      );
    if (key === "admin") {
      _injectScript(
        "https://unpkg.com/boxicons@2.0.7/css/boxicons.min.css",
        "link",
        true
      );
      getsScript(
        "chart",
        1,
        "https://cdn.jsdelivr.net/npm/chart.js",
        "script",
        "javascript",
        function () {
          console.log("chart-sidebar");
          ensureFooIsSet().then(() => {
            mySubject.next(true);
            setTimeout(() => {
              recreateChart(bar);
            }, 30);
          });
        }
      );
    }
  }
  if (!!key) mamap.set(key, el);
}
window.addEventListener("popstate", function (event) {
  const uparts = document.location.href.split("/");
  const makey =
    uparts[uparts.length - 1] === "" ? "home" : uparts[uparts.length - 1];
  console.log(
    "uparts[uparts.length-1] __> ",
    uparts[uparts.length - 1],
    "popstate --> ",
    mamap
  );
  if (!mamap.has(makey)) {
    var it = sessionStorage.getItem(makey);
    if (it !== null) mamap.set(makey, parser.parseFromString(it, "text/html"));
  }
  setHTML(mamap.get(makey));
});
