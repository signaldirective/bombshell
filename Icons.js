.pragma library

// Icons.js — Nerd Font / Omarchy glyphs used by the bar.
//
// Every codepoint here was checked against JetBrainsMono Nerd Font. Material
// Design icons live above the BMP, so they are built with String.fromCodePoint
// rather than a \u escape.

var cp = String.fromCodePoint

var icons = {
    bomb: "\uf1e2",            // nf-fa-bomb — the bombshell mark
    menu: "\ue900",            // Omarchy font menu glyph
    workspaces: "\uf0c9",
    contents: "\uf0ae",         // nf-fa-tasks — the bar contents list
    close: "\uf00d",
    chevronDown: "\uf078",
    chevronUp: "\uf077",
    chevronRight: "\uf054",
    more: "\uf141",
    plus: "\uf067",
    check: "\uf00c",
    edit: "\uf047",            // nf-fa-arrows
    refresh: "\uf021",

    cpu: "\uf2db",             // nf-fa-microchip
    memory: cp(0xf08ae),       // nf-md-expansion_card

    volumeHigh: "\uf028",
    volumeLow: "\uf027",
    volumeMute: "\uf026",
    volumeOff: "\uf026",
    headphones: "\uf025",
    mic: "\uf130",

    batteryFull: "\uf240",
    batteryThreeQuarter: "\uf241",
    batteryHalf: "\uf242",
    batteryQuarter: "\uf243",
    batteryEmpty: "\uf244",
    charging: "\uf0e7",

    power: "\uf0e7",
    powerSaver: "\uf06c",      // nf-fa-leaf
    balanced: "\uf24e",
    performance: "\uf135",

    wifi: "\uf1eb",
    wifiOff: cp(0xf05aa),      // nf-md-wifi_off
    ethernet: "\ueb2f",
    globe: "\uf0ac",

    bluetooth: "\uf294",
    bluetoothConnected: cp(0xf00b0),
    bluetoothOff: cp(0xf00b1),

    display: cp(0xf00de),      // nf-md-brightness_6
    brightness: cp(0xf00de),
    textSize: "\uf031",
    scale: "\uf00a",

    tray: "\uf0c9",

    // status indicators
    dictation: "\uf130",       // microphone
    recording: "\uf111",       // circle
    reminder: "\uf017",        // clock
    nightlight: "\uf186",      // moon
    dnd: "\uf1f6",             // bell-slash
    stayAwake: "\uf0f4",       // coffee
    weather: "\ue33d"          // weather cloud
}

function icon(name) {
    return icons.hasOwnProperty(name) ? icons[name] : String(name || "")
}

// Menu-button glyphs, selectable from the menu. Each is looked up in
// JetBrainsMono Nerd Font except "omarchy", which uses the omarchy font.
// Image-based choices (cat, rockstar, mjolnir, vaultboy, custom file) are
// defined in Theme.qml instead.
var menuGlyphs = {
    bomb: "\uf1e2",
    omarchy: "\ue900",
    arch: "\uf303",
    hyprland: "\uf359",
    gitkraken: "\ue913",
    rebel: "\uf1d0"
}

function menuGlyph(id) {
    return menuGlyphs.hasOwnProperty(id) ? menuGlyphs[id] : menuGlyphs.bomb
}

// wttr.in WW weather code -> glyph, using the Nerd Fonts weather range.
function weatherGlyph(code) {
    var c = parseInt(code, 10) || 0
    if (c === 113) return "\ue30d"                              // clear / sunny
    if (c === 116) return "\ue302"                              // partly cloudy
    if (c === 119 || c === 122) return "\ue33d"                 // cloudy / overcast
    if (c === 143 || c === 248 || c === 260) return "\ue313"    // mist / fog
    if (c === 200 || c === 386 || c === 389 || c === 392 || c === 395)
        return "\ue315"                                         // thunder
    // sleet, snow, ice pellets, snow showers
    if ([179, 182, 227, 230, 317, 320, 323, 326, 329, 332, 335, 338,
         350, 362, 365, 368, 371, 374, 377].indexOf(c) >= 0)
        return "\uf2dc"
    // everything else is some form of rain or drizzle
    return "\ue319"
}
