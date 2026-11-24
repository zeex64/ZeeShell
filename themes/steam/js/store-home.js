// ZeeShell for Steam: the store's front page opens on a spotlight.
//
// Steam's "Featured & Recommended" carousel is rebuilt as one wide stage: the
// featured game's artwork across the page, its logo, why it is being shown,
// its price, and a rail of the other featured games to step through. A sale
// banner, when Steam shows one, moves under it as a card of its own. Every
// word, picture and link comes from the carousel Steam already rendered; this
// script only arranges them. If the carousel is not there, or changes shape,
// nothing is built and the page stays as Steam made it.
(function () {
    "use strict";
    if (window.__zeeSpot) return;
    if (location.pathname !== "/" && location.pathname !== "") return;
    window.__zeeSpot = true;

    var CDN = "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/";
    var HOLD = 9000; // ms each game stays up
    var root = document.documentElement;

    function el(tag, cls, text) {
        var n = document.createElement(tag);
        if (cls) n.className = cls;
        if (text) n.textContent = text;
        return n;
    }
    function text(n) { return n ? n.textContent.replace(/\s+/g, " ").trim() : ""; }
    // Like text(), but keeps a space between pieces that sit in separate elements.
    function phrase(n) {
        if (!n) return "";
        var parts = [], walk = document.createTreeWalker(n, NodeFilter.SHOW_TEXT), t;
        while ((t = walk.nextNode())) { var s = t.nodeValue.replace(/\s+/g, " ").trim(); if (s) parts.push(s); }
        return parts.join(" ");
    }
    function bg(n) {
        if (!n) return "";
        if (n.dataset && n.dataset.backgroundImageUrl) return n.dataset.backgroundImageUrl;
        var m = /url\(["']?([^"')]+)["']?\)/.exec(n.style.backgroundImage || "");
        return m ? m[1] : "";
    }
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

    function read(cap) {
        var id = (cap.getAttribute("data-ds-appid") || "").split(",")[0];
        var block = cap.querySelector(".discount_block");
        var review = cap.querySelector(".game_review_summary");
        var tags = [];
        cap.querySelectorAll(".reason .tags span").forEach(function (t) { if (tags.length < 4 && text(t)) tags.push(text(t)); });
        var shots = [];
        cap.querySelectorAll(".screenshots > div").forEach(function (s) { var u = bg(s); if (u) shots.push(u); });
        var why = text(cap.querySelector(".reason .main strong")) || phrase(cap.querySelector(".reason .main"));
        return {
            id: /^\d+$/.test(id) ? id : "",
            href: cap.href,
            title: text(cap.querySelector(".app_name")),
            capsule: bg(cap.querySelector(".capsule")),
            shots: shots,
            review: text(review),
            mood: review ? (review.classList.contains("positive") ? "good" : review.classList.contains("mixed") ? "mixed" : review.classList.contains("negative") ? "bad" : "") : "",
            why: why.length > 60 ? "" : why,
            tags: tags,
            cut: block ? text(block.querySelector(".discount_pct")) : "",
            was: block ? text(block.querySelector(".discount_original_price")) : "",
            price: block ? text(block.querySelector(".discount_final_price")) : ""
        };
    }
    // A sale banner would sit above the spotlight as a second picture across
    // the whole page. It becomes a card of its own under the spotlight instead.
    // Banners with more than one link in them are left as Steam made them.
    function promo(after) {
        var page = document.querySelector(".home_page_body_ctn.has_takeover");
        if (!page) return;
        var holder = page.querySelector(".static_takeover_ctn .page_background_holder");
        var links = page.querySelectorAll(".home_page_takeover_link a[href]");
        var art = holder ? holder.style.backgroundImage : "";
        if (links.length !== 1 || art.indexOf("url(") < 0) return;
        var card = el("a", "zee-event");
        card.href = links[0].href;
        var label = links[0].getAttribute("aria-label");
        if (label) card.setAttribute("aria-label", label);
        card.style.backgroundImage = art;
        after.parentElement.insertBefore(card, after.nextSibling);
        root.classList.add("zee-event-on");
    }
    function big(shot) { return shot.replace(/\.\d+x\d+\.jpg/, ".1920x1080.jpg"); }

    function build() {
        if (document.querySelector(".zee-spot")) return true;
        var home = document.getElementById("home_maincap_v7");
        var caps = home ? home.querySelectorAll("a.store_main_capsule") : [];
        if (!home || caps.length < 2) return false;
        var games = [];
        caps.forEach(function (c) { var g = read(c); if (g.title && g.href) games.push(g); });
        if (games.length < 2) return false;

        var spot = el("section", "zee-spot");
        var layers = el("div", "zee-spot-art");
        var shade = el("div", "zee-spot-shade");
        var body = el("div", "zee-spot-body");
        var shots = el("div", "zee-spot-shots");
        // The other featured games sit in a tray of their own, under Steam's own
        // name for the row, so they are not mistaken for the screenshots above.
        var tray = el("div", "zee-spot-tray");
        var rail = el("div", "zee-spot-rail");
        var named = text(home.querySelector(".home_title"));
        if (named) tray.appendChild(el("span", "zee-spot-label", named));
        tray.appendChild(rail);
        spot.appendChild(layers); spot.appendChild(shade); spot.appendChild(body); spot.appendChild(shots); spot.appendChild(tray);

        var current = -1, timer = 0, paused = false, tiles = [];

        function art(src) {
            var img = picture("zee-spot-layer", src.slice());
            img.onload = function () {
                img.classList.add("on");
                var old = layers.querySelectorAll(".zee-spot-layer.on");
                for (var i = 0; i < old.length; i++) if (old[i] !== img) (function (o) { o.classList.remove("on"); setTimeout(function () { o.remove(); }, 900); })(old[i]);
            };
            layers.appendChild(img);
        }
        function sources(g) {
            var s = [];
            if (g.id) { s.push(CDN + g.id + "/library_hero_2x.jpg"); s.push(CDN + g.id + "/library_hero.jpg"); }
            if (g.shots[0]) s.push(big(g.shots[0]));
            if (g.capsule) s.push(g.capsule);
            return s;
        }

        function show(i) {
            i = (i + games.length) % games.length;
            if (i === current) return;
            current = i;
            var g = games[i];
            art(sources(g));

            var next = el("div", "zee-spot-copy");
            var link = el("a", "zee-spot-name");
            link.href = g.href;
            var title = el("h2", "zee-spot-title", g.title);
            if (g.id) link.appendChild(picture("zee-spot-logo", [CDN + g.id + "/logo_2x.png", CDN + g.id + "/logo.png"], function () { link.appendChild(title); }));
            else link.appendChild(title);
            link.setAttribute("aria-label", g.title);
            next.appendChild(link);

            var facts = el("div", "zee-spot-facts");
            if (g.why) facts.appendChild(el("span", "zee-spot-chip why", g.why));
            if (g.review) facts.appendChild(el("span", "zee-spot-chip " + g.mood, g.review));
            g.tags.forEach(function (t) { facts.appendChild(el("span", "zee-spot-chip", t)); });
            if (facts.children.length) next.appendChild(facts);

            var act = el("div", "zee-spot-actions");
            var go = el("a", "zee-spot-btn primary", "View game");
            go.href = g.href;
            act.appendChild(go);
            if (g.price) {
                var price = el("span", "zee-spot-price");
                if (g.cut) price.appendChild(el("span", "cut", g.cut));
                if (g.was) price.appendChild(el("span", "was", g.was));
                price.appendChild(el("span", "now", g.price));
                act.appendChild(price);
            }
            next.appendChild(act);

            // This game's screenshots, apart from the copy: hovering one puts it on the stage.
            shots.textContent = "";
            shots.onmouseleave = function () { art(sources(g)); };
            g.shots.slice(0, 4).forEach(function (s) {
                var t = el("button", "zee-spot-shot");
                t.type = "button";
                t.setAttribute("aria-label", "Show screenshot");
                t.style.backgroundImage = "url(\"" + s.replace(/\.\d+x\d+\.jpg/, ".600x338.jpg") + "\")";
                t.addEventListener("mouseenter", function () { art([big(s)]); });
                t.addEventListener("focus", function () { art([big(s)]); });
                t.addEventListener("click", function () { location.href = g.href; });
                shots.appendChild(t);
            });

            var old = body.querySelector(".zee-spot-copy");
            if (old) { old.classList.add("out"); setTimeout(function () { old.remove(); }, 380); }
            body.appendChild(next);

            tiles.forEach(function (t, k) { t.classList.toggle("on", k === i); });
            var on = tiles[i];
            if (on && on.scrollIntoView) { var r = on.getBoundingClientRect(), rr = rail.getBoundingClientRect(); if (r.left < rr.left || r.right > rr.right) rail.scrollLeft += r.left - rr.left - 40; }
            schedule();
        }
        function schedule() {
            clearTimeout(timer);
            if (!paused && !document.hidden) timer = setTimeout(function () { show(current + 1); }, HOLD);
        }

        games.forEach(function (g, i) {
            var t = el("button", "zee-spot-tile");
            t.type = "button";
            t.title = g.title;
            t.setAttribute("aria-label", g.title);
            if (g.capsule) t.style.backgroundImage = "url(\"" + g.capsule + "\")";
            t.appendChild(el("span", "zee-spot-tick"));
            t.addEventListener("click", function () { show(i); });
            rail.appendChild(t);
            tiles.push(t);
        });

        spot.addEventListener("mouseenter", function () { paused = true; spot.classList.add("held"); clearTimeout(timer); });
        spot.addEventListener("mouseleave", function () { paused = false; spot.classList.remove("held"); schedule(); });
        document.addEventListener("visibilitychange", schedule);
        spot.tabIndex = -1;
        spot.addEventListener("keydown", function (e) {
            if (e.key === "ArrowRight") show(current + 1);
            else if (e.key === "ArrowLeft") show(current - 1);
        });

        home.parentElement.insertBefore(spot, home);
        root.classList.add("zee-spot-on");
        try { promo(spot); } catch (e) { /* the banner stays where Steam put it */ }
        show(0);
        return true;
    }

    var tries = 0;
    (function attempt() {
        var done = false;
        try { done = build(); } catch (e) { done = true; /* leave Steam's page alone */ }
        if (!done && ++tries < 40) setTimeout(attempt, 350);
    })();
})();
