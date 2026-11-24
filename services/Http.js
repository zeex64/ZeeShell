.pragma library

// Minimal JSON GET. `headers` is optional.
function get(url, ok, fail, headers) {
    const x = new XMLHttpRequest();
    x.onreadystatechange = function () {
        if (x.readyState !== XMLHttpRequest.DONE) return;
        if (x.status >= 200 && x.status < 300) {
            let data;
            try { data = JSON.parse(x.responseText); } catch (e) { if (fail) fail("Bad response"); return; }
            ok(data);
        } else if (fail) {
            fail(x.status === 0 ? "No connection" : "HTTP " + x.status);
        }
    };
    x.open("GET", url);
    if (headers) for (const k in headers) x.setRequestHeader(k, headers[k]);
    x.send();
}
