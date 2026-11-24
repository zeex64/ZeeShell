// ZeeShell for Steam: the wishlist page as a list with a spotlight.
//
// Steam's own list stays what it is (its rows, its ranks, drag to reorder, its
// buttons); store-wishlist.css slims the rows down. This script adds the panel
// beside them: the game under the pointer, large, with its artwork, what the
// row already says about it, and a few screenshots. The description and the
// screenshots come from Steam's own app details for that game, asked for once
// per game. If the list is not there, or changes shape, nothing is built and
// the page stays as Steam made it.
(function () {
    "use strict";
    if (window.__zeeWish) return;
    if (!/^\/wishlist(\/|$)/.test(location.pathname)) return;
    window.__zeeWish = true;

    var CDN = "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/";
    var ROW = '[data-rfd-draggable-id^="WishlistItem"]';
    var root = document.documentElement;
    var details = {};   // appid -> { text, shots } once Steam has answered
    var asked = {};
    var spot = null, parts = null, shown = "", pending = 0;
    var mark = document.createElement("style");

    function el(tag, cls, text) {
        var n = document.createElement(tag);
        if (cls) n.className = cls;
        if (text) n.textContent = text;
        return n;
    }
    function text(n) { return n ? n.textContent.replace(/\s+/g, " ").trim() : ""; }
    // An image that tries each address in turn, then gives up quietly.
    function picture(cls, sources, onFail) {
        var img = el("img", cls);
        img.alt = "";
        img.decoding = "async";
        img.onerror = function () {
            var next = sources.shift();
            if (next) img.src = next; else { img.remove(); if (onFail) onFail(); }
        };
        img.src = sources.shift();
        return img;
    }

    // What a row says about its game. Cells are told apart by the grid area Steam gives them.
    function read(item) {
        var row = item.querySelector(':scope > [role="button"]') || item;
        var cells = {};
        for (var i = 0; i < row.children.length; i++) {
            var area = getComputedStyle(row.children[i]).gridArea.split("/")[0].trim();
            if (area && !cells[area]) cells[area] = row.children[i];
        }
        var link = row.querySelector('a[href*="/app/"]');
        var id = link ? (/\/app\/(\d+)/.exec(link.getAttribute("href")) || [])[1] : "";
        if (!id) return null;
        var img = cells.capsule ? cells.capsule.querySelector("img") : null;
        var facts = [];
        if (cells.lower && cells.lower.firstElementChild) {
            var pairs = cells.lower.firstElementChild.children;
            for (var p = 0; p < pairs.length; p++) {
                if (pairs[p].children.length !== 2) continue;
                var value = pairs[p].children[1], review = value.querySelector("span[title]");
                facts.push({ label: text(pairs[p].children[0]).replace(/:$/, ""), value: text(value), hint: review ? review.title : "" });
            }
        }
        var tags = [];
        if (cells.lower) cells.lower.querySelectorAll("button:not([role])").forEach(function (b) { if (tags.length < 6 && text(b)) tags.push(text(b)); });
        var badge = cells.lower && cells.lower.children[1] ? cells.lower.children[1].querySelector(":scope > div:not(:has(button)) > span") : null;
        var price = cells.purchase ? cells.purchase.querySelector('a[href*="/app/"]') : null;
        return {
            id: id,
            href: link.href,
            title: text(cells.title) || text(link),
            header: img ? img.currentSrc || img.src : "",
            facts: facts,
            tags: tags,
            badge: text(badge),
            price: text(price),
            added: cells.remove ? text(cells.remove.firstElementChild) : ""
        };
    }

    function art(sources) {
        var img = picture("zee-wl-layer", sources.slice());
        img.onload = function () {
            img.classList.add("on");
            var old = parts.art.querySelectorAll(".zee-wl-layer.on");
            for (var i = 0; i < old.length; i++) if (old[i] !== img) (function (o) { o.classList.remove("on"); setTimeout(function () { o.remove(); }, 700); })(old[i]);
        };
        parts.art.appendChild(img);
    }
    function sources(g) {
        var s = [CDN + g.id + "/library_hero_2x.jpg", CDN + g.id + "/library_hero.jpg"];
        var d = details[g.id];
        if (d && d.shots[0]) s.push(d.shots[0].full);
        if (g.header) s.push(g.header);
        return s;
    }

    // The part that needs Steam's app details: a sentence or two, and screenshots.
    function extras(g) {
        var d = details[g.id];
        parts.desc.textContent = d ? d.text : "";
        parts.shots.textContent = "";
        parts.shots.onmouseleave = function () { art(sources(g)); };
        if (!d) return;
        d.shots.slice(0, 4).forEach(function (s) {
            var t = el("button", "zee-wl-shot");
            t.type = "button";
            t.setAttribute("aria-label", "Show screenshot");
            t.style.backgroundImage = 'url("' + s.thumb + '")';
            t.addEventListener("mouseenter", function () { art([s.full]); });
            t.addEventListener("focus", function () { art([s.full]); });
            t.addEventListener("click", function () { location.href = g.href; });
            parts.shots.appendChild(t);
        });
    }
    function ask(g) {
        if (asked[g.id]) return;
        asked[g.id] = true;
        fetch("/api/appdetails?appids=" + g.id + "&filters=basic,screenshots", { credentials: "same-origin" })
            .then(function (r) { return r.ok ? r.json() : null; })
            .then(function (j) {
                var data = j && j[g.id] && j[g.id].success ? j[g.id].data : null;
                if (!data) return;
                var holder = el("div");
                holder.innerHTML = String(data.short_description || "").replace(/<[^>]*>/g, " ");
                details[g.id] = {
                    text: text(holder),
                    shots: (data.screenshots || []).map(function (s) { return { thumb: s.path_thumbnail, full: s.path_full }; }).filter(function (s) { return s.thumb && s.full; })
                };
                if (shown === g.id) extras(g);
            })
            .catch(function () { /* the panel does without them */ });
    }

    function show(g) {
        if (!g || !parts || g.id === shown) return;
        shown = g.id;
        // the row this panel is about, marked without touching Steam's own elements
        mark.textContent = 'html.zee-wl-on .zee-wl-list ' + ROW + ' > [role="button"]:has(a[href*="/app/' + g.id + '/"]) { background: var(--zee-accent-soft) !important; border-color: color-mix(in srgb, var(--zee-accent) 55%, transparent) !important; }';
        art(sources(g));

        var copy = el("div", "zee-wl-copy");
        var name = el("a", "zee-wl-name");
        name.href = g.href;
        name.setAttribute("aria-label", g.title);
        var title = el("h2", "zee-wl-title", g.title);
        name.appendChild(picture("zee-wl-logo", [CDN + g.id + "/logo_2x.png", CDN + g.id + "/logo.png"], function () { name.appendChild(title); }));
        copy.appendChild(name);
        var facts = el("div", "zee-wl-facts");
        if (g.badge) facts.appendChild(el("span", "zee-wl-chip why", g.badge));
        g.facts.forEach(function (f) {
            var chip = el("span", "zee-wl-chip");
            chip.appendChild(el("span", "k", f.label));
            chip.appendChild(el("span", "v", f.value));
            if (f.hint) chip.title = f.hint;
            facts.appendChild(chip);
        });
        if (facts.children.length) copy.appendChild(facts);
        if (g.tags.length) {
            var tags = el("div", "zee-wl-tags");
            g.tags.forEach(function (t) { tags.appendChild(el("span", "zee-wl-tag", t)); });
            copy.appendChild(tags);
        }
        var old = parts.stage.querySelector(".zee-wl-copy");
        if (old) old.remove();
        parts.stage.appendChild(copy);

        parts.added.textContent = g.added;
        parts.price.textContent = g.price;
        parts.price.hidden = !g.price;
        parts.go.href = g.href;
        extras(g);
        ask(g);
    }

    function build(col, list) {
        spot = el("aside", "zee-wl-spot");
        var stage = el("div", "zee-wl-stage");
        var layers = el("div", "zee-wl-art");
        stage.appendChild(layers);
        stage.appendChild(el("div", "zee-wl-shade"));
        var body = el("div", "zee-wl-body");
        var desc = el("p", "zee-wl-desc");
        var shots = el("div", "zee-wl-shots");
        var foot = el("div", "zee-wl-foot");
        var added = el("span", "zee-wl-added");
        var price = el("span", "zee-wl-price");
        var go = el("a", "zee-wl-btn", "View game");
        foot.appendChild(added); foot.appendChild(price); foot.appendChild(go);
        body.appendChild(desc); body.appendChild(shots); body.appendChild(foot);
        spot.appendChild(stage); spot.appendChild(body);
        parts = { stage: stage, art: layers, desc: desc, shots: shots, added: added, price: price, go: go };
        shown = "";
    }

    // Keep the page marked up: Steam redraws parts of it when the list is sorted or filtered.
    function tend() {
        var first = document.querySelector(ROW);
        var index = first ? first.closest("[data-index]") : null;
        var list = index && index.parentElement && index.parentElement.parentElement ? index.parentElement.parentElement.parentElement : null;
        var col = list ? list.parentElement : null;
        if (!col) return;
        if (!spot) build(col, list);
        if (!list.classList.contains("zee-wl-list")) list.classList.add("zee-wl-list");
        if (!col.classList.contains("zee-wl-col")) col.classList.add("zee-wl-col");
        if (spot.parentElement !== col || spot.previousElementSibling !== list) col.insertBefore(spot, list.nextSibling);
        if (!mark.isConnected) document.head.appendChild(mark);
        root.classList.add("zee-wl-on");
        if (!shown || !document.querySelector(ROW + ' a[href*="/app/' + shown + '/"]')) { shown = ""; show(read(first)); }
    }

    function over(e) {
        var item = e.target && e.target.closest ? e.target.closest(ROW) : null;
        if (!item || !spot) return;
        clearTimeout(pending);
        pending = setTimeout(function () { try { show(read(item)); } catch (err) { /* keep the last game up */ } }, 110);
    }
    document.addEventListener("mouseover", over);
    document.addEventListener("focusin", over);

    (function loop() {
        try { tend(); } catch (e) { /* leave Steam's page alone */ }
        setTimeout(loop, 900);
    })();
})();
