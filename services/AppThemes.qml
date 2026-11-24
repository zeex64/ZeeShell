pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Keeps other apps in step with the shell's colours:
//   - a KDE colour scheme, so Dolphin and other KDE/Qt apps match
//   - a Vesktop (Discord) theme
//   - kitty and foot terminal themes
// All are rewritten whenever the palette changes (new wallpaper, dark/light,
// a different accent). Each has a switch in Settings -> Personalisation -> Appearance.
Singleton {
    id: root

    readonly property bool dry: !!Quickshell.env("ZEE_DRY")
    readonly property string dataDir: Quickshell.env("XDG_DATA_HOME") || Config.home + "/.local/share"
    readonly property string configDir: Quickshell.env("XDG_CONFIG_HOME") || Config.home + "/.config"
    readonly property var p: Theme.target
    property bool flip: false // which of the two scheme files is live

    function rgb(c) { return Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255); }
    function hex(c) {
        const h = n => Math.round(Math.max(0, Math.min(1, n)) * 255).toString(16).padStart(2, "0");
        return "#" + h(c.r) + h(c.g) + h(c.b);
    }

    // ---- KDE colour scheme -------------------------------------------------
    function kdeGroup(name, bg, alt, fg) {
        return [
            "[Colors:" + name + "]",
            "BackgroundAlternate=" + rgb(alt),
            "BackgroundNormal=" + rgb(bg),
            "DecorationFocus=" + rgb(p.accent),
            "DecorationHover=" + rgb(p.accent),
            "ForegroundActive=" + rgb(p.accent),
            "ForegroundInactive=" + rgb(p.textMute),
            "ForegroundLink=" + rgb(p.accent),
            "ForegroundNegative=" + rgb(Theme.danger),
            "ForegroundNeutral=" + rgb(Theme.warn),
            "ForegroundNormal=" + rgb(fg),
            "ForegroundPositive=" + rgb(Theme.ok),
            "ForegroundVisited=" + rgb(Theme.mix(p.accent, p.textDim, 0.5)),
            ""
        ];
    }

    readonly property string kdeText: [
        "# Written by ZeeShell to match the desktop. Edits are overwritten.",
        "[General]",
        "ColorScheme=ZeeShell",
        "Name=ZeeShell",
        "shadeSortColumn=true",
        "",
        "[KDE]",
        "contrast=4",
        "",
        "[ColorEffects:Disabled]",
        "Color=" + rgb(p.surface),
        "ColorAmount=0",
        "ColorEffect=0",
        "ContrastAmount=0.65",
        "ContrastEffect=1",
        "IntensityAmount=0.1",
        "IntensityEffect=2",
        "",
        "[ColorEffects:Inactive]",
        "ChangeSelectionColor=false",
        "Color=" + rgb(p.surfaceTop),
        "ColorAmount=0.025",
        "ColorEffect=2",
        "ContrastAmount=0.1",
        "ContrastEffect=2",
        "Enable=false",
        "IntensityAmount=0",
        "IntensityEffect=0",
        ""
    ].concat(
        kdeGroup("View", p.bg, p.surface, p.text),
        kdeGroup("Window", p.surface, p.surfaceHi, p.text),
        kdeGroup("Button", p.surfaceHi, p.surfaceTop, p.text),
        kdeGroup("Header", p.surface, p.surfaceHi, p.text),
        kdeGroup("Tooltip", p.surfaceTop, p.surfaceHi, p.text),
        kdeGroup("Complementary", p.bg, p.surface, p.text),
        kdeGroup("Selection", p.accent, Theme.mix(p.accent, p.bg, 0.25), p.accentInk),
        [
            "[WM]",
            "activeBackground=" + rgb(p.surface),
            "activeBlend=" + rgb(p.text),
            "activeForeground=" + rgb(p.text),
            "inactiveBackground=" + rgb(p.bg),
            "inactiveBlend=" + rgb(p.textMute),
            "inactiveForeground=" + rgb(p.textMute),
            ""
        ]
    ).join("\n")

    // ---- Vesktop theme -----------------------------------------------------
    // The same look as Settings and Files: one sheet of glass for the window,
    // a lighter strip for the navigation, cards with a thin outline, the
    // shell's radii, and the accent for whatever is selected.
    //
    // The window can only be see-through when Vesktop itself allows it (its
    // "window transparency" switch, which needs a restart), so the shell reads
    // that switch and writes a solid version of the theme while it is off.
    property bool vesktopFound: false
    property bool vesktopClear: false // Vesktop's own window transparency is on
    readonly property bool vesktopGlass: Config.apps.vesktopGlass && vesktopClear

    function rgba(c, a) { return "rgba(" + rgb(c) + ", " + Math.round(a * 100) / 100 + ")"; }

    readonly property string cssText: {
        const dark = Config.appearance.dark;
        const glass = vesktopGlass ? rgba(p.bg, Theme.panelAlpha) : hex(p.bg);
        const r = Theme.radius;
        const px = n => Math.round(n) + "px";
        return [
            '/**',
            ' * @name ZeeShell',
            ' * @description The ZeeShell desktop\'s look for Discord: glass, cards and the accent from your wallpaper. Written by the shell; edits are overwritten.',
            ' * @author ZeeShell',
            ' * @version 2',
            ' */',
            '',
            ':root, .theme-dark, .theme-light, .visual-refresh, .visual-refresh.theme-dark, .visual-refresh.theme-light, .visual-refresh .theme-dark, .visual-refresh .theme-light {',
            '  /* the shell\'s palette */',
            '  --zee-glass: ' + glass + ';',
            '  --zee-bg: ' + hex(p.bg) + ';',
            '  --zee-surface: ' + hex(p.surface) + ';',
            '  --zee-surface-hi: ' + hex(p.surfaceHi) + ';',
            '  --zee-surface-top: ' + hex(p.surfaceTop) + ';',
            '  --zee-rail: ' + rgba(p.surfaceHi, 0.35) + ';',
            '  --zee-tint: ' + rgba(p.surfaceHi, 0.28) + ';',
            '  --zee-card: ' + rgba(p.surfaceHi, dark ? 0.62 : 0.7) + ';',
            '  --zee-card-hi: ' + rgba(p.surfaceTop, dark ? 0.75 : 0.8) + ';',
            '  --zee-line: ' + (Config.appearance.borders ? rgba(p.outline, p.outline.a) : 'transparent') + ';',
            '  --zee-text: ' + hex(p.text) + ';',
            '  --zee-text-dim: ' + hex(p.textDim) + ';',
            '  --zee-text-mute: ' + hex(p.textMute) + ';',
            '  --zee-accent: ' + hex(p.accent) + ';',
            '  --zee-accent-ink: ' + hex(p.accentInk) + ';',
            '  --zee-accent-soft: ' + hex(p.accentSoft) + ';',
            '  --zee-soft-ink: ' + hex(p.softInk) + ';',
            '  --zee-danger: ' + hex(Theme.danger) + ';',
            '  --zee-radius-xs: ' + px(r.xs) + ';',
            '  --zee-radius-sm: ' + px(r.sm) + ';',
            '  --zee-radius: ' + px(r.md) + ';',
            '  --zee-radius-lg: ' + px(r.lg) + ';',
            '  --zee-pill: ' + px(Math.min(r.full, 22)) + ';',
            '',
            '  /* Discord\'s surfaces. The lowest ones are what the window itself is',
            '     painted with, several times over, so they stay clear and the glass',
            '     is painted once, on the body below. */',
            '  --background-base-lowest: transparent;',
            '  --background-base-lower: transparent;',
            '  --background-base-low: var(--zee-tint);',
            '  --background-surface-high: var(--zee-card);',
            '  --background-surface-higher: var(--zee-card-hi);',
            '  --background-surface-highest: var(--zee-card-hi);',
            '  --background-primary: transparent;',
            '  --background-secondary: transparent;',
            '  --background-secondary-alt: var(--zee-tint);',
            '  --background-tertiary: transparent;',
            '  --background-floating: var(--zee-card-hi);',
            '  --background-accent: var(--zee-card-hi);',
            '  --background-nested-floating: var(--zee-card);',
            '  --background-mobile-primary: transparent;',
            '  --background-mobile-secondary: transparent;',
            '  --bg-overlay-app-frame: transparent;',
            '  --bg-overlay-chat: transparent;',
            '  --bg-overlay-floating: var(--zee-card-hi);',
            '  --background-modifier-hover: color-mix(in srgb, var(--zee-text) 7%, transparent);',
            '  --background-modifier-active: color-mix(in srgb, var(--zee-text) 11%, transparent);',
            '  --background-modifier-selected: var(--zee-accent-soft);',
            '  --background-modifier-accent: color-mix(in srgb, var(--zee-text) 10%, transparent);',
            '  --background-message-hover: color-mix(in srgb, var(--zee-text) 4%, transparent);',
            '  --background-mentioned: color-mix(in srgb, var(--zee-accent) 12%, transparent);',
            '  --background-mentioned-hover: color-mix(in srgb, var(--zee-accent) 17%, transparent);',
            '  --channeltextarea-background: var(--zee-card-hi);',
            '  --input-background: var(--zee-card-hi);',
            '  --modal-background: var(--zee-surface);',
            '  --modal-footer-background: var(--zee-bg);',
            '  --card-primary-bg: var(--zee-card);',
            '  --card-secondary-bg: var(--zee-card);',
            '  --activity-card-background: var(--zee-card);',
            '  --scrollbar-auto-thumb: color-mix(in srgb, var(--zee-text) 22%, transparent);',
            '  --scrollbar-auto-track: transparent;',
            '  --scrollbar-thin-thumb: color-mix(in srgb, var(--zee-text) 22%, transparent);',
            '  --scrollbar-thin-track: transparent;',
            '',
            '  /* text */',
            '  --text-default: var(--zee-text);',
            '  --text-normal: var(--zee-text);',
            '  --text-primary: var(--zee-text);',
            '  --text-secondary: var(--zee-text-dim);',
            '  --text-muted: var(--zee-text-mute);',
            '  --text-tertiary: var(--zee-text-mute);',
            '  --text-link: var(--zee-accent);',
            '  --text-brand: var(--zee-accent);',
            '  --header-primary: var(--zee-text);',
            '  --header-secondary: var(--zee-text-dim);',
            '  --header-muted: var(--zee-text-mute);',
            '  --interactive-normal: var(--zee-text-dim);',
            '  --interactive-hover: var(--zee-text);',
            '  --interactive-active: var(--zee-text);',
            '  --interactive-muted: color-mix(in srgb, var(--zee-text-mute) 60%, transparent);',
            '  --channels-default: var(--zee-text-dim);',
            '  --channel-icon: var(--zee-text-dim);',
            '  --icon-primary: var(--zee-text);',
            '  --icon-secondary: var(--zee-text-dim);',
            '  --icon-muted: var(--zee-text-mute);',
            '  --font-primary: "' + Theme.font + '", "gg sans", "Noto Sans", "Helvetica Neue", Helvetica, Arial, sans-serif;',
            '  --font-display: "' + Theme.font + '", "gg sans", "Noto Sans", "Helvetica Neue", Helvetica, Arial, sans-serif;',
            '',
            '  /* lines */',
            '  --border-subtle: var(--zee-line);',
            '  --border-normal: var(--zee-line);',
            '  --border-strong: color-mix(in srgb, var(--zee-text) 22%, transparent);',
            '  --border-faint: color-mix(in srgb, var(--zee-text) 6%, transparent);',
            '',
            '  /* shape: the shell\'s corner sizes */',
            '  --radius-xs: var(--zee-radius-xs);',
            '  --radius-sm: var(--zee-radius-sm);',
            '  --radius-md: var(--zee-radius);',
            '  --radius-lg: var(--zee-radius-lg);',
            '',
            '  /* accent */',
            '  --brand-experiment: var(--zee-accent);',
            '  --brand-260: var(--zee-accent);',
            '  --brand-360: var(--zee-accent);',
            '  --brand-500: var(--zee-accent);',
            '  --brand-560: color-mix(in srgb, var(--zee-accent) 88%, black);',
            '  --brand-600: color-mix(in srgb, var(--zee-accent) 78%, black);',
            '  --bg-brand: var(--zee-accent);',
            '  --control-brand-foreground: var(--zee-accent);',
            '  --control-brand-foreground-new: var(--zee-accent);',
            '  --button-filled-brand-background: var(--zee-accent);',
            '  --button-filled-brand-background-hover: color-mix(in srgb, var(--zee-accent) 88%, white);',
            '  --button-filled-brand-background-active: color-mix(in srgb, var(--zee-accent) 80%, black);',
            '  --button-filled-brand-text: var(--zee-accent-ink);',
            '  --mention-background: color-mix(in srgb, var(--zee-accent) 22%, transparent);',
            '  --mention-foreground: var(--zee-accent);',
            '  --status-danger: var(--zee-danger);',
            '}',
            '',
            '/* Menus, popouts, pickers and dialogs float above the window, so they',
            '   get solid surfaces: text over text would be unreadable. */',
            '[class*="layerContainer_"], [class*="layerContainer_"] .theme-dark, [class*="layerContainer_"] .theme-light {',
            '  --background-base-lowest: var(--zee-bg);',
            '  --background-base-lower: var(--zee-surface);',
            '  --background-base-low: var(--zee-surface);',
            '  --background-surface-high: var(--zee-surface-hi);',
            '  --background-surface-higher: var(--zee-surface-top);',
            '  --background-surface-highest: var(--zee-surface-top);',
            '  --background-primary: var(--zee-surface);',
            '  --background-secondary: var(--zee-bg);',
            '  --background-secondary-alt: var(--zee-bg);',
            '  --background-tertiary: var(--zee-bg);',
            '  --background-floating: var(--zee-surface-hi);',
            '  --background-nested-floating: var(--zee-surface-hi);',
            '  --bg-overlay-floating: var(--zee-surface-hi);',
            '  --card-primary-bg: var(--zee-surface-hi);',
            '  --card-secondary-bg: var(--zee-surface-hi);',
            '  --input-background: var(--zee-surface-top);',
            '  --channeltextarea-background: var(--zee-surface-top);',
            '}',
            '',
            '/* ---- the window: one sheet of glass ---- */',
            'html { background: transparent !important; }',
            'body { background: var(--zee-glass) !important; }',
            '#app-mount, [class*="appMount_"], [class^="app_"], [class^="bg_"], [class*=" bg_"] { background: transparent !important; }',
            '',
            '/* ---- navigation: the lighter strip Settings and Files have ---- */',
            '[class*="sidebar_"] { background: var(--zee-rail) !important; border-right: 1px solid var(--zee-line); }',
            '[class*="sidebar_"] [class*="guilds_"], [class*="sidebar_"] [class*="sidebarList_"] { background: transparent !important; }',
            '[class*="membersWrap_"], [class*="members_"] { background: transparent !important; }',
            '[class*="membersWrap_"] { background: var(--zee-rail) !important; border-left: 1px solid var(--zee-line); }',
            '',
            '/* the account panel: a card */',
            '[class*="sidebar_"] [class*="panels_"] {',
            '  background: var(--zee-card-hi) !important;',
            '  border: 1px solid var(--zee-line) !important;',
            '  border-radius: var(--zee-radius) !important;',
            '  overflow: hidden;',
            '}',
            '',
            '/* rows in the lists: rounded, and the accent when selected */',
            '[class*="containerDefault_"] [class*="link_"], [class*="channel_"] [class*="interactive_"], [class*="member_"] [class*="layout_"] { border-radius: var(--zee-radius-sm) !important; }',
            '[class*="modeSelected_"] [class*="link_"], [class*="interactiveSelected_"] { background: var(--zee-accent-soft) !important; }',
            '[class*="modeSelected_"] [class*="name_"], [class*="modeSelected_"] [class*="icon_"], [class*="interactiveSelected_"] [class*="name_"] { color: var(--zee-soft-ink) !important; }',
            '',
            '/* the conversation gets a slightly deeper tint, so text stays easy to read */',
            'main[class*="chatContent_"] { background: color-mix(in srgb, var(--zee-bg) 26%, transparent) !important; }',
            '',
            '/* ---- writing: the message box is a field, like the shell\'s ---- */',
            '[class*="channelTextArea_"] > [class*="scrollableContainer_"], [class*="channelTextArea_"] [class*="themedBackground_"] {',
            '  background: var(--zee-card-hi) !important;',
            '  border: 1px solid var(--zee-line) !important;',
            '  border-radius: var(--zee-pill) !important;',
            '}',
            '[class*="searchBar_"], [class*="searchBarComponent_"] { border-radius: var(--zee-pill) !important; background: var(--zee-card-hi) !important; }',
            '',
            '/* things inside messages keep a box of their own */',
            '[class*="embedFull_"], [class*="wrapper_"][class*="embed"], [class*="attachment_"], [class*="repliedMessage_"] + [class*="contents_"] [class*="container_"][class*="embed"] { background: var(--zee-card) !important; border-color: var(--zee-line) !important; border-radius: var(--zee-radius-sm) !important; }',
            'code, pre, .hljs, [class*="codeContainer_"] { background: color-mix(in srgb, var(--zee-bg) 55%, transparent) !important; border-color: var(--zee-line) !important; border-radius: var(--zee-radius-xs) !important; }',
            '',
            '/* ---- floating things: solid, outlined, rounded like the shell\'s popups ---- */',
            '[class*="menu_"], [class*="autocomplete_"], [class*="messagesPopoutWrap_"], [class*="popout_"], [role="dialog"][class*="root_"] {',
            '  border: 1px solid var(--zee-line) !important;',
            '  border-radius: var(--zee-radius) !important;',
            '}',
            '[class*="menu_"] [class*="item_"] { border-radius: var(--zee-radius-xs) !important; }',
            '[class*="menu_"] [class*="item_"][class*="focused_"] { background: var(--zee-accent) !important; color: var(--zee-accent-ink) !important; }',
            '[class*="tooltip_"] { border-radius: var(--zee-radius-sm) !important; }',
            '',
            '/* full-page views (user and server settings) sit on the same glass */',
            '[class*="standardSidebarView_"], [class*="contentRegion_"], [class*="contentRegionScroller_"], [class*="sidebarRegion_"], [class*="sidebarRegionScroller_"] { background: transparent !important; }',
            '[class*="sidebarRegion_"] { background: var(--zee-rail) !important; border-right: 1px solid var(--zee-line); }',
            '',
            '/* small things */',
            '[class*="numberBadge_"], [class*="unreadMentionsBar_"], [class*="newMessagesBar_"] { background: var(--zee-accent) !important; color: var(--zee-accent-ink) !important; }',
            '::selection { background: var(--zee-accent-soft); color: var(--zee-soft-ink); }',
            '::-webkit-scrollbar-thumb { border-radius: 999px; }',
            ''
        ].join("\n");
    }

    // Vesktop keeps that switch in Vencord's settings file.
    FileView {
        id: vencord
        path: Config.ready ? root.configDir + "/vesktop/settings/settings.json" : ""
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            root.vesktopFound = true;
            try { root.vesktopClear = JSON.parse(text()).transparent === true; } catch (e) {}
        }
        onLoadFailed: { root.vesktopFound = false; root.vesktopClear = false; }
    }

    // Turn Vesktop's window transparency on. Vesktop only reads the switch
    // when it starts and writes its settings back as it quits, so it is closed
    // first, the one value is changed, and it is started again.
    property bool vesktopBusy: false
    function makeVesktopClear() {
        if (dry || vesktopBusy) return;
        vesktopBusy = true;
        clearProc.running = true;
    }

    Process {
        id: clearProc
        command: ["sh", "-c", "f=\"$1/vesktop/settings/settings.json\"; [ -f \"$f\" ] || exit 3\n"
            + "run=0; pgrep -x vesktop >/dev/null 2>&1 && run=1\n"
            + "if [ \"$run\" = 1 ]; then pkill -TERM -x vesktop; i=0; while pgrep -x vesktop >/dev/null 2>&1 && [ \"$i\" -lt 25 ]; do sleep 0.2; i=$((i + 1)); done; fi\n"
            + "if grep -q '\"transparent\"' \"$f\"; then sed -i 's/\"transparent\"[[:space:]]*:[[:space:]]*false/\"transparent\": true/' \"$f\"; else sed -i '0,/{/s//{\\n    \"transparent\": true,/' \"$f\"; fi\n"
            + "[ \"$run\" = 1 ] && { setsid -f vesktop >/dev/null 2>&1 || (vesktop >/dev/null 2>&1 &); }\n"
            + "exit 0",
            "sh", root.configDir]
        onExited: { root.vesktopBusy = false; vencord.reload(); }
    }

    // ---- Steam theme (Millennium) -----------------------------------------------
    // The theme itself is a folder of stylesheets in themes/steam. The shell
    // copies it into Millennium's themes folder and keeps one file of it,
    // colors.css, in step with the desktop. Steam's windows cannot be
    // see-through, so the glass tones are mixed down to solid colours here.
    readonly property string steamThemes: dataDir + "/Steam/millennium/themes"
    readonly property string steamColors: {
        const dark = Config.appearance.dark, r = Theme.radius, px = n => Math.round(n) + "px";
        const over = (c, a) => hex(Theme.mix(p.bg, c, a));
        return [
            "/* Written by ZeeShell to match the desktop. Edits are overwritten. */",
            ":root {",
            "    --zee-bg: " + hex(p.bg) + ";",
            "    --zee-surface: " + hex(p.surface) + ";",
            "    --zee-surface-hi: " + hex(p.surfaceHi) + ";",
            "    --zee-surface-top: " + hex(p.surfaceTop) + ";",
            "    --zee-rail: " + over(p.surfaceHi, 0.35) + ";",
            "    --zee-card: " + over(p.surfaceHi, dark ? 0.62 : 0.7) + ";",
            "    --zee-card-hi: " + over(p.surfaceTop, dark ? 0.75 : 0.8) + ";",
            "    --zee-line: " + hex(Theme.mix(p.surfaceHi, Qt.rgba(p.outline.r, p.outline.g, p.outline.b, 1), Config.appearance.borders ? p.outline.a : 0)) + ";",
            "    --zee-text: " + hex(p.text) + ";",
            "    --zee-text-dim: " + hex(p.textDim) + ";",
            "    --zee-text-mute: " + hex(p.textMute) + ";",
            "    --zee-accent: " + hex(p.accent) + ";",
            "    --zee-accent-ink: " + hex(p.accentInk) + ";",
            "    --zee-accent-soft: " + hex(p.accentSoft) + ";",
            "    --zee-soft-ink: " + hex(p.softInk) + ";",
            "    --zee-danger: " + hex(Theme.danger) + ";",
            "    --zee-ok: " + hex(Theme.ok) + ";",
            "    --zee-warn: " + hex(Theme.warn) + ";",
            "    --zee-radius-xs: " + px(r.xs) + ";",
            "    --zee-radius-sm: " + px(r.sm) + ";",
            "    --zee-radius: " + px(r.md) + ";",
            "    --zee-radius-lg: " + px(r.lg) + ";",
            "    --zee-pill: " + px(Math.min(r.full, 22)) + ";",
            "    --zee-font: \"" + Theme.font + "\", \"Inter\", \"Motiva Sans\", \"Noto Sans\", Arial, sans-serif;",
            "    color-scheme: " + (dark ? "dark" : "light") + ";",
            "}",
            // The wallpaper, copied next to this file, is what the glass shows.
            steamBackdrop !== "" ? "body.DesktopUI::before, body.ModalDialogBody::before, body:has(.friendlist)::before { background-image: url(\"./" + steamBackdrop + "\"); }" : "",
            ""
        ].join("\n");
    }
    readonly property string steamBackdrop: {
        const w = Config.wallpaper.path, m = /\.([A-Za-z0-9]+)$/.exec(w);
        return w !== "" && m ? "backdrop." + m[1].toLowerCase() : "";
    }

    function applySteam() {
        if (dry || !Config.ready || !Config.apps.steam) return;
        steamWrite.command = ["sh", "-c",
            "[ -d \"$1\" ] || exit 0; mkdir -p \"$1/ZeeShell\" && cp -rf \"$2/.\" \"$1/ZeeShell/\" && printf '%s' \"$3\" > \"$1/ZeeShell/colors.css\"\n"
            + "rm -f \"$1/ZeeShell\"/backdrop.*; [ -n \"$5\" ] && [ -f \"$4\" ] && cp -f \"$4\" \"$1/ZeeShell/$5\"; true",
            "sh", steamThemes, Quickshell.shellPath("themes/steam"), steamColors, Config.wallpaper.path, steamBackdrop];
        steamWrite.running = true;
    }

    onSteamColorsChanged: steamTimer.restart()
    Timer { id: steamTimer; interval: 900; onTriggered: root.applySteam() }
    Process { id: steamWrite }

    // ---- terminals ------------------------------------------------------------
    // Sixteen terminal colours: fixed hues (red stays red) pulled a little
    // toward the accent, on the shell's own background and text.
    function ansi(hue, bright) {
        const dark = Config.appearance.dark;
        const c = Qt.hsla(hue, dark ? 0.62 : 0.6, dark ? (bright ? 0.8 : 0.71) : (bright ? 0.36 : 0.43), 1);
        return Theme.mix(c, p.accent, 0.1);
    }

    readonly property var term: {
        const dark = Config.appearance.dark;
        const c = [
            dark ? p.surfaceHi : p.text, ansi(0.98, false), ansi(0.37, false), ansi(0.12, false), ansi(0.6, false), ansi(0.83, false), ansi(0.5, false), dark ? p.textDim : p.surfaceTop,
            dark ? p.textMute : p.textDim, ansi(0.98, true), ansi(0.37, true), ansi(0.12, true), ansi(0.6, true), ansi(0.83, true), ansi(0.5, true), dark ? p.text : p.surface
        ];
        return { colors: c.map(hex), opacity: Math.round(Math.max(0.78, Math.min(1, Config.appearance.opacity + 0.12)) * 100) / 100 };
    }

    readonly property string kittyText: [
        "# Written by ZeeShell to match the desktop. Edits are overwritten.",
        "# Turn it off in Settings -> Personalisation -> Appearance -> Other apps.",
        "foreground " + hex(p.text),
        "background " + hex(p.bg),
        "background_opacity " + term.opacity,
        "selection_foreground " + hex(p.softInk),
        "selection_background " + hex(p.accentSoft),
        "cursor " + hex(p.accent),
        "cursor_text_color " + hex(p.accentInk),
        "url_color " + hex(p.accent),
        "active_border_color " + hex(p.accent),
        "inactive_border_color " + hex(p.surfaceTop),
        "active_tab_foreground " + hex(p.accentInk),
        "active_tab_background " + hex(p.accent),
        "inactive_tab_foreground " + hex(p.textDim),
        "inactive_tab_background " + hex(p.surfaceHi),
        "tab_bar_background " + hex(p.bg),
        "window_padding_width 12"
    ].concat(term.colors.map((c, i) => "color" + i + " " + c)).join("\n") + "\n"

    function footColors(name) {
        const bare = c => String(c).slice(1), out = ["[" + name + "]", "alpha=" + term.opacity, "background=" + bare(hex(p.bg)), "foreground=" + bare(hex(p.text)), "cursor=" + bare(hex(p.accentInk)) + " " + bare(hex(p.accent))];
        for (let i = 0; i < 8; i++) out.push("regular" + i + "=" + bare(term.colors[i]));
        for (let i = 0; i < 8; i++) out.push("bright" + i + "=" + bare(term.colors[i + 8]));
        out.push("selection-foreground=" + bare(hex(p.softInk)), "selection-background=" + bare(hex(p.accentSoft)), "urls=" + bare(hex(p.accent)), "");
        return out;
    }

    // [colors-light] must stay last: put-foot-theme.sh cuts from there for old foot.
    readonly property string footText: [
        "# Written by ZeeShell to match the desktop. Edits are overwritten.",
        "# Turn it off in Settings -> Personalisation -> Appearance -> Other apps.",
        "[main]",
        "pad=12x12",
        ""
    ].concat(footColors("colors-dark"), footColors("colors-light")).join("\n")

    // The greeter (`zeeshell fetch`) reads its colours from here.
    readonly property string paletteText: "accent=" + hex(p.accent).slice(1) + "\nink=" + hex(p.accentInk).slice(1) + "\ntext=" + hex(p.text).slice(1)
        + "\ndim=" + hex(p.textDim).slice(1) + "\nmute=" + hex(p.textMute).slice(1) + "\n"

    function applyTerminals() {
        if (dry || !Config.ready) return;
        // Only where the terminal is set up; kitty reloads its config on SIGUSR1.
        const script = "printf '%s' \"$1\" > \"$4/palette\"; [ \"$5\" = on ] || exit 0;"
            + " if [ -d \"$3/kitty\" ]; then printf '%s' \"$1\" >/dev/null; printf '%s' \"$6\" > \"$3/kitty/zeeshell.conf\"; pkill -USR1 -x kitty 2>/dev/null; fi;"
            + " if [ -d \"$3/foot\" ]; then printf '%s' \"$2\" > \"$3/foot/zeeshell.ini.new\" && \"$7\" \"$3/foot/zeeshell.ini\" \"$3/foot/zeeshell.ini.new\"; fi; true";
        termWrite.command = ["sh", "-c", script, "sh", paletteText, footText, configDir, Config.cacheDir, Config.apps.terminal ? "on" : "off", kittyText, Quickshell.shellPath("scripts/put-foot-theme.sh")];
        termWrite.running = true;
    }

    onKittyTextChanged: termTimer.restart()
    onFootTextChanged: termTimer.restart()

    Timer { id: termTimer; interval: 900; onTriggered: root.applyTerminals() }
    Process { id: termWrite }

    // ---- writing ------------------------------------------------------------
    // KDE only re-reads a scheme when its name changes, so two identical files
    // take turns being the active one.
    function applyKde() {
        if (dry || !Config.ready || !Config.apps.kde) return;
        flip = !flip;
        const name = flip ? "ZeeShell" : "ZeeShellAlt";
        kdeWrite.command = ["sh", "-c",
            "mkdir -p \"$1\" && printf '%s' \"$3\" > \"$1/$2.colors\" && { command -v plasma-apply-colorscheme >/dev/null && plasma-apply-colorscheme \"$2\" >/dev/null 2>&1; true; }",
            "sh", dataDir + "/color-schemes", name, kdeText.replace("ColorScheme=ZeeShell", "ColorScheme=" + name)];
        kdeWrite.running = true;
    }

    function applyVesktop() {
        if (dry || !Config.ready || !Config.apps.vesktop) return;
        cssWrite.command = ["sh", "-c",
            "[ -d \"$1\" ] || exit 0; mkdir -p \"$1/themes\" && printf '%s' \"$2\" > \"$1/themes/zeeshell.theme.css\"",
            "sh", configDir + "/vesktop", cssText];
        cssWrite.running = true;
    }

    // Remember what KDE used before, so turning this off can put it back.
    function kdeToggled() {
        if (dry || !Config.ready) return;
        if (Config.apps.kde) {
            remember.running = true;
        } else if (Config.apps.kdePrevious !== "") {
            Quickshell.execDetached(["plasma-apply-colorscheme", Config.apps.kdePrevious]);
        }
    }

    onKdeTextChanged: kdeTimer.restart()
    onCssTextChanged: cssTimer.restart()

    Connections {
        target: Config
        function onReadyChanged() { kdeTimer.restart(); cssTimer.restart(); termTimer.restart(); steamTimer.restart(); }
    }

    Connections {
        target: Config.apps
        function onKdeChanged() { root.kdeToggled(); }
        function onVesktopChanged() { cssTimer.restart(); }
        function onSteamChanged() { steamTimer.restart(); }
        function onTerminalChanged() { termTimer.restart(); }
    }

    Timer { id: kdeTimer; interval: 900; onTriggered: root.applyKde() }
    Timer { id: cssTimer; interval: 900; onTriggered: root.applyVesktop() }

    Process { id: kdeWrite }
    Process { id: cssWrite }

    Process {
        id: remember
        command: ["sh", "-c", "kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const name = text.trim();
                if (name !== "" && name.indexOf("ZeeShell") !== 0) Config.apps.kdePrevious = name;
                kdeTimer.restart();
            }
        }
    }
}
