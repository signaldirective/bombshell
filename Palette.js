.pragma library

// Palette.js — parse an Omarchy theme colors.toml into the bar's colour slots.
//
// Omarchy keeps the active theme palette at
//   ~/.local/state/omarchy/current/theme/colors.toml
// with keys like background, foreground, accent, color0..color15 and the
// semantic names (red, green, blue, ...). We map the values we care about onto
// fixed slots so the rest of the shell never has to know the key names.

var WANTED = {
    paper:     ["background", "bg"],
    ink:       ["foreground", "fg"],
    sumi:      ["color8", "muted", "dark_fg"],
    color01:   ["color1", "red"],
    color02:   ["color2", "green"],
    color03:   ["color3", "yellow"],
    color04:   ["color4", "blue"],
    color05:   ["color5", "magenta"],
    color06:   ["color6", "cyan"],
    color07:   ["color7", "bright_fg", "light_fg"],
    accentHint: ["accent"]
}

var LINE = /^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"([^"]*)"/

// Every key/value in the file, verbatim.
function parseAll(text) {
    var out = ({})
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
        var m = lines[i].match(LINE)
        if (m) out[m[1]] = m[2]
    }
    return out
}

function validColor(v) {
    return /^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$/.test(String(v || ""))
}

// Raw keys -> semantic slots, using the first WANTED key that is present.
function mapKeys(raw) {
    var out = ({})
    for (var slot in WANTED) {
        var keys = WANTED[slot]
        for (var i = 0; i < keys.length; i++) {
            if (validColor(raw[keys[i]])) {
                out[slot] = raw[keys[i]]
                break
            }
        }
    }
    // color0/color15 alias background/foreground when the short form is absent.
    if (!out.paper && validColor(raw.color0)) out.paper = raw.color0
    if (!out.ink && validColor(raw.color15)) out.ink = raw.color15
    return out
}

function parse(text) {
    return mapKeys(parseAll(text))
}

function setColor(theme, key, value) {
    if (validColor(value)) theme[key] = value
}

// Write a parsed palette onto the live Theme object. Missing slots are left
// untouched so a partial palette cannot blank the bar.
function apply(theme, palette) {
    for (var key in palette) setColor(theme, key, palette[key])
}
