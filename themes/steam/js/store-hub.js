// ZeeShell for Steam: hub pages (a genre, a tag, Discounts & Events, a sale).
//
// Their tab bar marks the open tab only with a class whose name changes from
// one Steam build to the next, so the stylesheet cannot find it. This script
// finds it by shape (the open tab carries one class more than its neighbours)
// and marks it for store-hub.css. If there is no such tab bar, it does nothing.
(function () {
    "use strict";
    if (window.__zeeHub) return;
    window.__zeeHub = true;
    var root = document.documentElement, queued = 0;

    function mark() {
        queued = 0;
        var bars = document.querySelectorAll(".SaleSectionTabContainer"), found = false;
        for (var b = 0; b < bars.length; b++) {
            var tabs = bars[b].querySelectorAll('[id^="Tab_"]');
            if (tabs.length < 2) continue;
            var least = Infinity, i;
            for (i = 0; i < tabs.length; i++) least = Math.min(least, tabs[i].classList.length);
            var open = [];
            for (i = 0; i < tabs.length; i++) if (tabs[i].classList.length > least) open.push(tabs[i]);
            if (open.length !== 1) continue; // not the shape this was written for
            for (i = 0; i < tabs.length; i++) {
                if (tabs[i] === open[0]) { if (!tabs[i].hasAttribute("data-zee-on")) tabs[i].setAttribute("data-zee-on", ""); }
                else if (tabs[i].hasAttribute("data-zee-on")) tabs[i].removeAttribute("data-zee-on");
            }
            found = true;
        }
        root.classList.toggle("zee-hub-tabs", found);
    }
    function soon() { if (!queued) queued = setTimeout(mark, 60); }

    new MutationObserver(soon).observe(root, { subtree: true, childList: true, attributes: true, attributeFilter: ["class"] });
    soon();
})();
