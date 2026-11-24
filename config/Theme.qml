pragma Singleton

import Quickshell
import QtQuick

// Design tokens. Colours are derived from a single accent hue, which either
// comes from the config or is sampled from the current wallpaper.
Singleton {
    id: root

    readonly property bool dark: Config.appearance.dark
    readonly property string wallpaper: Config.wallpaper.path

    // ---- accent ---------------------------------------------------------
    property color sampled: Config.appearance.accent
    readonly property color seed: Config.appearance.dynamicColors && wallpaper !== "" ? sampled : Config.appearance.accent
    readonly property real hue: seed.hslHue < 0 ? 0.6 : seed.hslHue
    readonly property real chroma: seed.hslHue < 0 ? 0 : Math.min(1, seed.hslSaturation * 1.6)

    function pick(colors) {
        let best = null, bestScore = -1;
        for (let i = 0; i < colors.length; i++) {
            const c = colors[i];
            if (c.hslHue < 0) continue;
            const s = c.hslSaturation, l = c.hslLightness;
            const score = s * (1 - Math.abs(l - 0.55) * 1.4) * (1 - i / (colors.length * 2.5));
            if (score > bestScore) { bestScore = score; best = c; }
        }
        if (best && bestScore > 0.06) sampled = best;
        else if (colors.length) sampled = Qt.hsla(colors[0].hslHue < 0 ? 0.6 : colors[0].hslHue, 0.12, 0.6, 1);
    }

    ColorQuantizer {
        source: root.wallpaper !== "" && Config.appearance.dynamicColors ? "file://" + root.wallpaper : ""
        depth: 4
        rescaleSize: 96
        onColorsChanged: if (colors.length) root.pick(colors)
    }

    function tone(s, l, a) { return Qt.hsla(hue, s * (0.35 + chroma * 0.65), l, a === undefined ? 1 : a); }

    // ---- palette --------------------------------------------------------
    // Colours cross-fade between palettes. (Done by hand: `Behavior` inside a
    // singleton crashes Qt 6.12.)
    readonly property var target: dark ? {
        accent: Qt.hsla(hue, 0.25 + chroma * 0.6, 0.76, 1), accentInk: tone(0.5, 0.13),
        accentSoft: tone(0.42, 0.27), softInk: tone(0.6, 0.88),
        bg: tone(0.22, 0.065), surface: tone(0.2, 0.115), surfaceHi: tone(0.18, 0.165), surfaceTop: tone(0.16, 0.225),
        outline: tone(0.2, 0.75, 0.11), outlineHi: tone(0.2, 0.8, 0.2),
        text: tone(0.25, 0.94), textDim: tone(0.14, 0.74), textMute: tone(0.1, 0.52)
    } : {
        accent: Qt.hsla(hue, 0.28 + chroma * 0.36, 0.46, 1), accentInk: tone(0.3, 0.98),
        accentSoft: tone(0.6, 0.86), softInk: tone(0.5, 0.22),
        bg: tone(0.3, 0.955), surface: tone(0.3, 0.985), surfaceHi: tone(0.26, 0.925), surfaceTop: tone(0.24, 0.875),
        outline: tone(0.3, 0.2, 0.13), outlineHi: tone(0.3, 0.2, 0.24),
        text: tone(0.3, 0.12), textDim: tone(0.16, 0.34), textMute: tone(0.1, 0.54)
    }
    property var from: target
    property var to: target
    property real blend: 1

    onTargetChanged: {
        const snap = {};
        for (const k in to) snap[k] = mix(from[k], to[k], blend);
        fade.stop();
        from = snap;
        blend = 0;
        to = target;
        fade.start();
    }

    NumberAnimation {
        id: fade
        target: root
        property: "blend"
        from: 0
        to: 1
        duration: 650
        easing.type: Easing.OutCubic
    }

    readonly property color accent: mix(from.accent, to.accent, blend)
    readonly property color accentInk: mix(from.accentInk, to.accentInk, blend)
    readonly property color accentSoft: mix(from.accentSoft, to.accentSoft, blend)
    readonly property color softInk: mix(from.softInk, to.softInk, blend)
    readonly property color bg: mix(from.bg, to.bg, blend)
    readonly property color surface: mix(from.surface, to.surface, blend)
    readonly property color surfaceHi: mix(from.surfaceHi, to.surfaceHi, blend)
    readonly property color surfaceTop: mix(from.surfaceTop, to.surfaceTop, blend)
    readonly property color outline: mix(from.outline, to.outline, blend)
    readonly property color outlineHi: mix(from.outlineHi, to.outlineHi, blend)
    readonly property color text: mix(from.text, to.text, blend)
    readonly property color textDim: mix(from.textDim, to.textDim, blend)
    readonly property color textMute: mix(from.textMute, to.textMute, blend)

    readonly property color danger: dark ? "#ff8f8f" : "#c8323c"
    readonly property color warn: dark ? "#ffcf80" : "#a56a00"
    readonly property color ok: dark ? "#8fe3a8" : "#1f8a4c"
    readonly property color scrim: Qt.rgba(0, 0, 0, dark ? 0.42 : 0.24)
    readonly property color shadow: Qt.rgba(0, 0, 0, dark ? 0.5 : 0.22)

    // Translucent panel fill; opacity is user controlled.
    readonly property real panelAlpha: Config.appearance.blur ? Config.appearance.opacity : Math.max(0.9, Config.appearance.opacity)
    readonly property color panel: Qt.alpha(bg, panelAlpha)
    readonly property color layer: Qt.alpha(surfaceHi, dark ? 0.62 : 0.7)
    readonly property color layerHi: Qt.alpha(surfaceTop, dark ? 0.75 : 0.8)
    readonly property color border: Config.appearance.borders ? outline : "transparent"

    function alpha(c, a) { return Qt.alpha(c, a); }
    function mix(a, b, t) { if (t >= 1) return b; return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t); }

    // ---- shape & type ---------------------------------------------------
    readonly property real rounding: Config.appearance.rounding
    readonly property QtObject radius: QtObject {
        readonly property real xs: 6 * root.rounding
        readonly property real sm: 10 * root.rounding
        readonly property real md: 16 * root.rounding
        readonly property real lg: 22 * root.rounding
        readonly property real xl: 30 * root.rounding
        readonly property real full: root.rounding < 0.05 ? 0 : 999
    }

    readonly property string font: Config.appearance.font
    readonly property string mono: Config.appearance.monoFont
    function fs(px) { return Math.round(px * Config.appearance.fontScale); }

    // ---- motion ---------------------------------------------------------
    readonly property real speed: Math.max(0.1, Config.appearance.animSpeed)
    function dur(ms) { return Math.round(ms / speed); }

    readonly property QtObject curve: QtObject {
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> enter: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<real> exit: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property list<real> spring: [0.3, 1.38, 0.5, 1, 1, 1]
        readonly property list<real> springSoft: [0.25, 1.15, 0.45, 1, 1, 1]
    }
}
