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
    readonly property string cssText: [
        "/**",
        " * @name ZeeShell",
        " * @description Matches the ZeeShell desktop: same surfaces, text and accent. Written by the shell; edits are overwritten.",
        " * @author ZeeShell",
        " * @version 1",
        " */",
        "",
        ":root, .theme-dark, .theme-light, .visual-refresh.theme-dark, .visual-refresh.theme-light, .visual-refresh .theme-dark, .visual-refresh .theme-light {",
        "  --zee-bg: " + hex(p.bg) + ";",
        "  --zee-surface: " + hex(p.surface) + ";",
        "  --zee-surface-hi: " + hex(p.surfaceHi) + ";",
        "  --zee-surface-top: " + hex(p.surfaceTop) + ";",
        "  --zee-text: " + hex(p.text) + ";",
        "  --zee-text-dim: " + hex(p.textDim) + ";",
        "  --zee-text-mute: " + hex(p.textMute) + ";",
        "  --zee-accent: " + hex(p.accent) + ";",
        "  --zee-accent-ink: " + hex(p.accentInk) + ";",
        "  --zee-accent-soft: " + hex(p.accentSoft) + ";",
        "  --zee-soft-ink: " + hex(p.softInk) + ";",
        "  --zee-danger: " + hex(Theme.danger) + ";",
        "  --zee-radius: " + Math.round(Theme.radius.md) + "px;",
        "",
        "  /* surfaces: current Discord names */",
        "  --background-base-lowest: var(--zee-bg);",
        "  --background-base-lower: var(--zee-bg);",
        "  --background-base-low: var(--zee-surface);",
        "  --background-surface-high: var(--zee-surface-hi);",
        "  --background-surface-higher: var(--zee-surface-top);",
        "  --background-surface-highest: var(--zee-surface-top);",
        "  /* surfaces: older names that are still used in places */",
        "  --background-primary: var(--zee-surface);",
        "  --background-secondary: var(--zee-bg);",
        "  --background-secondary-alt: var(--zee-bg);",
        "  --background-tertiary: var(--zee-bg);",
        "  --background-floating: var(--zee-surface-hi);",
        "  --background-accent: var(--zee-surface-top);",
        "  --background-nested-floating: var(--zee-surface-hi);",
        "  --background-mobile-primary: var(--zee-surface);",
        "  --background-mobile-secondary: var(--zee-bg);",
        "  --background-modifier-hover: color-mix(in srgb, var(--zee-text) 7%, transparent);",
        "  --background-modifier-active: color-mix(in srgb, var(--zee-text) 11%, transparent);",
        "  --background-modifier-selected: color-mix(in srgb, var(--zee-accent) 18%, transparent);",
        "  --background-modifier-accent: color-mix(in srgb, var(--zee-text) 10%, transparent);",
        "  --background-message-hover: color-mix(in srgb, var(--zee-text) 4%, transparent);",
        "  --bg-overlay-chat: var(--zee-surface);",
        "  --bg-overlay-floating: var(--zee-surface-hi);",
        "  --channeltextarea-background: var(--zee-surface-hi);",
        "  --input-background: var(--zee-surface-hi);",
        "  --modal-background: var(--zee-surface);",
        "  --modal-footer-background: var(--zee-bg);",
        "  --card-primary-bg: var(--zee-surface-hi);",
        "  --card-secondary-bg: var(--zee-surface-hi);",
        "  --activity-card-background: var(--zee-surface-hi);",
        "  --scrollbar-auto-thumb: var(--zee-surface-top);",
        "  --scrollbar-auto-track: transparent;",
        "  --scrollbar-thin-thumb: var(--zee-surface-top);",
        "  --scrollbar-thin-track: transparent;",
        "",
        "  /* text */",
        "  --text-default: var(--zee-text);",
        "  --text-normal: var(--zee-text);",
        "  --text-primary: var(--zee-text);",
        "  --text-secondary: var(--zee-text-dim);",
        "  --text-muted: var(--zee-text-mute);",
        "  --text-tertiary: var(--zee-text-mute);",
        "  --text-link: var(--zee-accent);",
        "  --text-brand: var(--zee-accent);",
        "  --header-primary: var(--zee-text);",
        "  --header-secondary: var(--zee-text-dim);",
        "  --header-muted: var(--zee-text-mute);",
        "  --interactive-normal: var(--zee-text-dim);",
        "  --interactive-hover: var(--zee-text);",
        "  --interactive-active: var(--zee-text);",
        "  --interactive-muted: color-mix(in srgb, var(--zee-text-mute) 60%, transparent);",
        "  --channels-default: var(--zee-text-dim);",
        "  --channel-icon: var(--zee-text-dim);",
        "  --icon-primary: var(--zee-text);",
        "  --icon-secondary: var(--zee-text-dim);",
        "  --icon-muted: var(--zee-text-mute);",
        "",
        "  /* lines */",
        "  --border-subtle: color-mix(in srgb, var(--zee-text) 8%, transparent);",
        "  --border-normal: color-mix(in srgb, var(--zee-text) 12%, transparent);",
        "  --border-strong: color-mix(in srgb, var(--zee-text) 20%, transparent);",
        "  --border-faint: color-mix(in srgb, var(--zee-text) 5%, transparent);",
        "",
        "  /* accent */",
        "  --brand-experiment: var(--zee-accent);",
        "  --brand-260: var(--zee-accent);",
        "  --brand-360: var(--zee-accent);",
        "  --brand-500: var(--zee-accent);",
        "  --brand-560: color-mix(in srgb, var(--zee-accent) 88%, black);",
        "  --brand-600: color-mix(in srgb, var(--zee-accent) 78%, black);",
        "  --bg-brand: var(--zee-accent);",
        "  --control-brand-foreground: var(--zee-accent);",
        "  --control-brand-foreground-new: var(--zee-accent);",
        "  --button-filled-brand-background: var(--zee-accent);",
        "  --button-filled-brand-background-hover: color-mix(in srgb, var(--zee-accent) 88%, white);",
        "  --button-filled-brand-background-active: color-mix(in srgb, var(--zee-accent) 80%, black);",
        "  --button-filled-brand-text: var(--zee-accent-ink);",
        "  --mention-background: color-mix(in srgb, var(--zee-accent) 22%, transparent);",
        "  --mention-foreground: var(--zee-accent);",
        "  --status-danger: var(--zee-danger);",
        "}",
        "",
        "/* A little of the shell's shape. */",
        "[class*=\"channelTextArea\"] > [class*=\"scrollableContainer\"] { border-radius: var(--zee-radius); }",
        "[class*=\"messagesPopoutWrap\"], [class*=\"menu_\"], [class*=\"autocomplete_\"] { border-radius: var(--zee-radius); }",
        "::selection { background: var(--zee-accent-soft); color: var(--zee-soft-ink); }",
        ""
    ].join("\n")

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
        function onReadyChanged() { kdeTimer.restart(); cssTimer.restart(); termTimer.restart(); }
    }

    Connections {
        target: Config.apps
        function onKdeChanged() { root.kdeToggled(); }
        function onVesktopChanged() { cssTimer.restart(); }
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
