// ZeeShell for Steam: a game's store page opens on a full-width hero built
// from what the page already has: the game's wide artwork and logo, its short
// description, review summary and price, and the page's own buy and wishlist
// buttons (this script only presses them). If anything it needs is missing,
// it leaves the page exactly as Steam made it.
(function () {
    "use strict";
    if (window.__zeeHero) return;
    var match = location.pathname.match(/^\/app\/(\d+)/);
    if (!match) return;
    window.__zeeHero = true;

    var id = match[1];
    var assets = "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/" + id + "/";

    function el(tag, cls, text) {
        var n = document.createElement(tag);
        if (cls) n.className = cls;
        if (text) n.textContent = text;
        return n;
    }
    function find(sel) { return document.querySelector(sel); }
    function textOf(sel) { var n = find(sel); return n ? n.textContent.replace(/\s+/g, " ").trim() : ""; }

    // Steam serves trailers as adaptive streams. Where the browser can play
    // the stream itself, the hero gets its own copy at full quality; where it
    // cannot, the hero mirrors the trailer the page's own player is showing.
    function firstTrailer() {
        try {
            var props = JSON.parse(find(".gamehighlight_desktopcarousel").getAttribute("data-props"));
            return props.trailers && props.trailers[0];
        } catch (e) { return null; }
    }
    function mirror(film, tries) {
        var own = find(".gamehighlight_desktopcarousel video");
        if (own && own.captureStream && own.readyState >= 2) {
            try { film.srcObject = own.captureStream(); film.play().catch(function () {}); return; } catch (e) { /* fall through */ }
        }
        if (tries > 0) setTimeout(function () { mirror(film, tries - 1); }, 700);
    }
    function startFilm(film) {
        var trailer = firstTrailer();
        if (!trailer) return;
        var direct = trailer.hlsManifest && film.canPlayType("application/vnd.apple.mpegurl");
        if (direct) {
            film.addEventListener("error", function () { film.removeAttribute("src"); mirror(film, 12); }, { once: true });
            film.src = trailer.hlsManifest;
            film.play().catch(function () {});
            // some builds say "maybe" and then never start
            setTimeout(function () { if (film.readyState < 2) { film.removeAttribute("src"); film.load(); mirror(film, 12); } }, 4000);
        } else {
            mirror(film, 14);
        }
    }

    function build() {
        var host = find(".responsive_page_template_content");
        var title = textOf(".apphub_AppName");
        if (!host || !title || find(".zee-hero") || find(".agegate_birthday_selector, #app_agegate")) return;

        var hero = el("section", "zee-hero");

        // artwork: the wide library image, else the first screenshot, else the header
        var art = el("img", "zee-hero-art");
        var shot = find("a.highlight_screenshot_link"), header = find(".game_header_image_full");
        var fallbacks = [shot && shot.href, header && header.src].filter(Boolean);
        art.alt = "";
        art.onerror = function () {
            var next = fallbacks.shift();
            if (next) art.src = next; else art.remove();
        };
        fallbacks.unshift(assets + "library_hero.jpg");
        art.src = assets + "library_hero_2x.jpg"; // the sharp one, when the game has it
        hero.appendChild(art);

        // the game's first trailer plays over the artwork, silently
        var film = el("video", "zee-hero-film");
        film.muted = true;
        film.loop = true;
        film.autoplay = true;
        film.playsInline = true;
        film.setAttribute("muted", "");
        film.addEventListener("playing", function () { hero.classList.add("has-film"); });
        hero.appendChild(film);
        startFilm(film);

        hero.appendChild(el("div", "zee-hero-shade"));

        var body = el("div", "zee-hero-body");

        // the logo, or the name in type when there is no logo
        var logo = el("img", "zee-hero-logo");
        logo.alt = title;
        logo.onerror = function () { logo.replaceWith(el("h1", "zee-hero-title", title)); };
        logo.src = assets + "logo.png";
        body.appendChild(logo);

        var blurb = textOf(".game_description_snippet");
        if (blurb) body.appendChild(el("p", "zee-hero-blurb", blurb));

        // facts: reviews, release date, price
        var facts = el("div", "zee-hero-facts");
        var review = find(".user_reviews_summary_row .game_review_summary");
        if (review) {
            var chip = el("span", "zee-chip", review.textContent.trim());
            if (review.classList.contains("positive")) chip.classList.add("good");
            else if (review.classList.contains("mixed")) chip.classList.add("mixed");
            else if (review.classList.contains("negative")) chip.classList.add("bad");
            facts.appendChild(chip);
        }
        var date = textOf(".release_date .date");
        if (date) facts.appendChild(el("span", "zee-chip", date));
        var box = find(".game_area_purchase_game:not(.demo_above_purchase)");
        var cut = box && box.querySelector(".discount_pct");
        var price = box && (box.querySelector(".discount_final_price") || box.querySelector(".game_purchase_price"));
        if (cut && cut.textContent.trim()) facts.appendChild(el("span", "zee-chip good", cut.textContent.trim()));
        if (price && price.textContent.trim()) facts.appendChild(el("span", "zee-chip strong", price.textContent.trim()));
        if (facts.children.length) body.appendChild(facts);

        // actions: these press the page's own buttons
        var actions = el("div", "zee-hero-actions");
        var owned = find(".game_area_already_owned");
        var buy = box && box.querySelector(".btn_addtocart a, .btn_addtocart .btn_green_steamui, a.btn_green_steamui");
        var main = el("a", "zee-btn primary");
        if (owned) {
            main.textContent = "Play";
            main.href = "steam://run/" + id;
        } else if (buy) {
            main.textContent = buy.textContent.replace(/\s+/g, " ").trim() || "Add to Cart";
            main.href = "#";
            main.addEventListener("click", function (e) { e.preventDefault(); buy.click(); });
        } else {
            main.textContent = "See options";
            main.href = "#game_area_purchase";
        }
        actions.appendChild(main);

        var media = find("#game_highlights");
        if (media) {
            var watch = el("a", "zee-btn", "Media");
            watch.href = "#";
            watch.addEventListener("click", function (e) { e.preventDefault(); media.scrollIntoView({ behavior: "smooth", block: "center" }); });
            actions.appendChild(watch);
        }

        var wish = find("#add_to_wishlist_area a"), wished = find("#add_to_wishlist_area_success");
        if (wish && !owned) {
            var heart = el("a", "zee-btn round", "♡");
            heart.href = "#";
            heart.title = wish.textContent.replace(/\s+/g, " ").trim();
            var on = wished && wished.style.display !== "none";
            if (on) { heart.textContent = "♥"; heart.classList.add("on"); }
            heart.addEventListener("click", function (e) {
                e.preventDefault();
                if (heart.classList.contains("on")) return;
                wish.click();
                heart.textContent = "♥";
                heart.classList.add("on");
            });
            actions.appendChild(heart);
        }
        body.appendChild(actions);
        hero.appendChild(body);

        host.insertBefore(hero, host.firstChild);
        document.documentElement.classList.add("zee-has-hero");
    }

    function start() { try { build(); } catch (e) { /* leave Steam's page alone */ } }
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", start);
    else start();
    // the page fills in parts of itself late
    setTimeout(start, 600);
    setTimeout(start, 2000);
})();
