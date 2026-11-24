// ZeeShell for Steam: the library's layout.
//
// 1. The game list is a slim rail that slides open under the pointer. This
//    script only adds the pin that keeps it open, and remembers the choice.
// 2. The library home opens on a stage: a large panel for the game you
//    played last and tiles for the ones before it, built from what Steam
//    already lists in "Recent Games". Artwork and logos come from Steam's own
//    image servers, Play starts a game, and a click anywhere else opens its
//    page.
//
// Everything here is additive. If Steam changes underneath it, the banner and
// the pin simply do not appear and the library works as Steam made it.
(function () {
    "use strict";
    if (window.__zeeLibrary) return;
    window.__zeeLibrary = true;

    var PIN = "zee-rail-pinned";
    var root = document.documentElement;
    var CDN = "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/";

    function stored() { try { return localStorage.getItem(PIN) === "1"; } catch (e) { return false; } }
    function store(on) { try { localStorage.setItem(PIN, on ? "1" : "0"); } catch (e) { /* not remembered */ } }
    root.classList.toggle(PIN, stored());

    function el(tag, cls, text) {
        var n = document.createElement(tag);
        if (cls) n.className = cls;
        if (text) n.textContent = text;
        return n;
    }

    // ---- the pin ----
    function ensurePin() {
        var head = document.querySelector(".GameListHomeAndSearch");
        if (!head || head.querySelector(".zee-pin")) return;
        var pin = el("button", "zee-pin");
        pin.type = "button";
        function label() {
            var on = root.classList.contains(PIN);
            pin.setAttribute("aria-pressed", on ? "true" : "false");
            pin.title = on ? "Let the game list tuck away" : "Keep the game list open";
            pin.setAttribute("aria-label", pin.title);
        }
        pin.addEventListener("click", function (e) {
            e.stopPropagation();
            var on = !root.classList.contains(PIN);
            root.classList.toggle(PIN, on);
            store(on);
            label();
            // Steam measures the list when the window changes size
            window.dispatchEvent(new Event("resize"));
        });
        label();
        head.appendChild(pin);
    }

    // ---- the stage ----
    // The games in "Recent Games" that have Steam artwork, newest first.
    function recent(limit) {
        var boxes = document.querySelectorAll(".LibraryHome .RecentGames .LibraryItemBox"), out = [], seen = {};
        for (var i = 0; i < boxes.length && out.length < limit; i++) {
            var img = boxes[i].querySelector("img");
            var m = img && /\/assets\/(\d+)\//.exec(img.src);
            if (!m || seen[m[1]]) continue;
            seen[m[1]] = true;
            var group = boxes[i].closest(".RecentGame"), when = group && group.querySelector(".AddedDate");
            out.push({ id: m[1], cover: img.src, when: when ? when.textContent.trim() : "" });
        }
        return out;
    }
    function boxOf(id) {
        var boxes = document.querySelectorAll(".LibraryHome .RecentGames .LibraryItemBox");
        for (var i = 0; i < boxes.length; i++) {
            var img = boxes[i].querySelector("img");
            if (img && img.src.indexOf("/assets/" + id + "/") >= 0) return boxes[i];
        }
        return null;
    }
    function openPage(id) { var box = boxOf(id); if (box) box.click(); }

    function run(id) {
        try { window.SteamClient.Apps.RunGame(String(id), "", -1, 100); return; } catch (e) { /* older or newer client */ }
        try { window.SteamClient.URL.ExecuteSteamURL("steam://rungameid/" + id); return; } catch (e2) { /* fall through */ }
        window.location.href = "steam://rungameid/" + id;
    }

    // An image that tries each address in turn, then removes itself.
    function picture(cls, sources) {
        var img = el("img", cls);
        img.alt = "";
        img.decoding = "async";
        img.onerror = function () { var next = sources.shift(); if (next) img.src = next; else img.remove(); };
        img.src = sources.shift();
        return img;
    }
    function playIcon() { return el("span", "zee-ico play"); }

    function ensureStage() {
        var home = document.querySelector(".LibraryHome");
        var scroller = home && home.parentElement;
        var old = document.querySelector(".zee-stage");
        if (!home || !scroller) { if (old) old.remove(); return; }
        var games = recent(5);
        if (!games.length) return; // the shelf has not loaded yet, or is switched off
        var key = games.map(function (g) { return g.id; }).join(",");
        if (old && old.dataset.games === key && old.parentElement === scroller) return;
        if (old) old.remove();

        var lead = games[0], rest = games.slice(1);
        var stage = el("section", "zee-stage" + (rest.length ? "" : " solo"));
        stage.dataset.games = key;

        var main = el("div", "zee-stage-main");
        main.appendChild(picture("zee-stage-art", [CDN + lead.id + "/library_hero_2x.jpg", CDN + lead.id + "/library_hero.jpg", lead.cover]));
        main.appendChild(el("div", "zee-stage-shade"));
        var body = el("div", "zee-stage-body");
        var id = el("div", "zee-stage-id");
        id.appendChild(picture("zee-stage-logo", [CDN + lead.id + "/logo_2x.png", CDN + lead.id + "/logo.png"]));
        if (lead.when) id.appendChild(el("span", "zee-stage-when", lead.when));
        body.appendChild(id);
        var actions = el("div", "zee-stage-actions");
        var open = el("button", "zee-lib-btn", "Open page");
        open.type = "button";
        actions.appendChild(open);
        var play = el("button", "zee-lib-btn primary");
        play.type = "button";
        play.appendChild(playIcon());
        play.appendChild(el("span", "", "Play"));
        play.addEventListener("click", function (e) { e.stopPropagation(); run(lead.id); });
        actions.appendChild(play);
        body.appendChild(actions);
        main.appendChild(body);
        main.addEventListener("click", function () { openPage(lead.id); });
        stage.appendChild(main);

        if (rest.length) {
            var next = el("div", "zee-stage-next" + (rest.length < 3 ? " few" : ""));
            rest.forEach(function (g) {
                var tile = el("div", "zee-tile");
                tile.tabIndex = 0;
                tile.setAttribute("role", "link");
                tile.appendChild(picture("", [CDN + g.id + "/capsule_616x353.jpg", CDN + g.id + "/header.jpg", g.cover]));
                if (g.when) tile.appendChild(el("span", "zee-tile-when", g.when));
                var go = el("button", "zee-tile-play");
                go.type = "button";
                go.title = "Play";
                go.setAttribute("aria-label", "Play");
                go.appendChild(playIcon());
                go.addEventListener("click", function (e) { e.stopPropagation(); run(g.id); });
                tile.appendChild(go);
                tile.addEventListener("click", function () { openPage(g.id); });
                tile.addEventListener("keydown", function (e) { if (e.key === "Enter") openPage(g.id); });
                next.appendChild(tile);
            });
            stage.appendChild(next);
        }
        scroller.appendChild(stage);
    }

    // ---- keep the list open while its dropdown is ----
    // Steam draws the "Games and Software" dropdown outside the list, so the
    // pointer leaves the rail to reach it. While one is open over the list's
    // corner, the rail holds.
    function ensureHold() {
        var open = false, menus = document.querySelectorAll(".contextMenu.DropDown.visible");
        for (var i = 0; i < menus.length; i++) {
            var r = menus[i].getBoundingClientRect();
            if (r.width > 0 && r.left < 440 && r.top < 320) open = true;
        }
        root.classList.toggle("zee-rail-hold", open);
    }

    var timer = 0;
    function tick() {
        clearTimeout(timer);
        timer = setTimeout(function () {
            try { ensurePin(); ensureHold(); ensureStage(); } catch (e) { /* leave Steam's library alone */ }
        }, 90);
    }
    new MutationObserver(tick).observe(document.body, { childList: true, subtree: true });
    tick();
})();
