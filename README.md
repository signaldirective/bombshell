# bombshell

A theme-aware Quickshell status bar for Omarchy, built to sit on top of the
existing Omarchy shell. It keeps Omarchy's services (notifications, night
light, idle, lock, media) running and replaces only the bar.

[github.com/signaldirective/bombshell](https://github.com/signaldirective/bombshell)

```
menu · workspaces        weather · date/time        cpu ram net bt vol · display · power · battery · tray
```

## What's in it

**Widgets** (each can move between the three islands)

| Widget | Click | Right click / wheel |
|---|---|---|
| Menu | opens the bombshell settings panel | right click opens the Omarchy menu |
| Workspaces | focus a workspace | right click cycles the display style |
| Weather | opens the forecast | right click refreshes |
| Date / time | opens the calendar | right click toggles 12 h / 24 h |
| CPU, RAM | opens a details panel | |
| Network | opens the network panel | right click opens `nmtui` |
| Bluetooth | opens the bluetooth panel | right click toggles the radio |
| Volume | opens the mixer | right click mutes, wheel changes volume |
| Display | opens the display panel | wheel changes brightness |
| Power | opens the power-profile panel | right click cycles the profile |
| Battery | opens the battery panel | |
| Tray | activates an item | middle click secondary-activates |

Hovering the **date/time** reveals Omarchy's status indicators: dictate, screen
recording, reminders, night light, silence notifications, and stay awake. They
light up when active and run the same `omarchy-*` commands as the stock bar.

**Menu** (the menu button) has:

- bar position (top / bottom)
- islands: split the bar into three pills (left, middle, right)
- **Edit bar**: drag widgets between islands (see below)
- **Bar contents**: switch bombshell's own widgets off, and pick the island for
  every Omarchy plugin widget (see below)
- reset layout
- bar foreground colour: any colour from the current theme's palette
- menu icon: bomb, Omarchy glyph, Arch, Hyprland, GitKraken (squid), Star Wars
  Rebel, cat, Rockstar, Mjölnir, Vault Boy (each tinted to the bar
  foreground), or an image file
- workspace style: `1–0`, `I–X`, `一–十`, or circles
- workspace range: `1–5`, `1–10`, or active workspaces only
- 12-hour clock, imperial units
- **Omarchy bar**: hand control back to the stock Omarchy bar
- quit bombshell

**Workspaces** (right-click the workspaces widget, or use the menu):

- **circles** — empty ring for an empty workspace, filled with the theme
  foreground when the workspace has windows, filled with the theme accent for
  the current workspace
- **numbers / roman / kanji** — `1..0`, `I..X`, `一..十`
- range 1–5, 1–10, or only active workspaces

**Islands and edit mode**

The bar is one surface by default. Turn on **islands** in the menu to split it
into three pills. Open **Edit bar** from the menu to drag widgets between the
islands; an island with no widgets disappears, and only reappears while you are
editing so you always have somewhere to drop things. Press **Esc** (or click
outside) to finish — the layout is saved and empty islands hide again.

**Omarchy plugin widgets**

The **Bar contents** submenu has two lists.

The first is bombshell's own widgets. Each one has a switch: turning it off
takes it off the bar but keeps its place, so switching it back on puts it where
it was. That is also how you stop a plugin from showing up twice — switch off
bombshell's clock before you switch on the Omarchy clock plugin.

The second is every Omarchy plugin that ships a bar widget, found by walking
the plugin manifests the same way the stock shell does. Each one has a four-way
choice — **off**, **L**, **C**, **R** — that says which island it lands in.
Plugins are off until you pick one, because bombshell already ships
equivalents for most of them. A green dot marks the plugins that are live in
the stock Omarchy bar as well, and the list has a filter field because most
installations have a lot of them.

Plugin widgets are dragged between islands in edit mode exactly like
bombshell's own.

**Theme awareness**

bombshell reads the active Omarchy theme's `colors.toml` live and re-colours
itself when the theme changes. The bar foreground can be any palette colour
(accent, color01–color07, foreground, muted).

## Requirements

- Quickshell 0.3+ (`qs`)
- The Omarchy shell (`omarchy-shell`) — bombshell uses its services and the
  `omarchy-*` helper commands
- Fonts: `JetBrainsMono Nerd Font`, `omarchy`, and `Noto Sans CJK JP` (for kanji
  workspaces; all are present on Omarchy by default)
- `qt6-5compat` — provides `Qt5Compat.GraphicalEffects`, used to paint the
  bundled menu-icon masks in the bar foreground colour
- Omarchy's Quickshell build (the one carrying `load_qtquick_611.patch`) — see
  [Why `import QtQuick` is pinned](#why-import-qtquick-is-pinned)

## Run

```
git clone https://github.com/signaldirective/bombshell.git ~/bombshell
~/bombshell/scripts/bombshell-start.sh
```

or, after installing the launcher:

```
~/bombshell/scripts/bombshell-install-plugin.sh   # once
bombshell
```

`bombshell` starts the bar and hides the stock Omarchy bar. To run bombshell
without touching the stock bar, use `qs -p ~/bombshell`.

To stop it: `quickshell kill -p ~/bombshell --any-display`, or the
**Quit bombshell** entry in the menu.

The scripts resolve their own location, so the checkout can live anywhere; set
`BOMBSHELL_DIR` to override.

### The `Ui` and `Commons` symlinks

Omarchy's plugin widgets import `qs.Ui` and `qs.Commons`, and Quickshell
resolves a qualified import against the directory the shell config lives in.
`scripts/bombshell-omarchy-modules.sh` symlinks the Omarchy shell's `Ui/` and
`Commons/` next to bombshell's `shell.qml` so those imports resolve. The
symlinks are created on every start, are ignored by git, and are only needed
for the plugin widgets — bombshell itself does not use them.

### Why `import QtQuick` is pinned

`shell.qml` starts with `//@ pragma OmarchyLoadPatch`. That pragma is understood
by the Quickshell build Omarchy ships, and it does two things: it rewrites
every unversioned `import QtQuick` to `import QtQuick 6.11`, and it makes
Quickshell scan plugin directories as they are loaded.

The rewrite matters because Qt 6.12 added a `Color` singleton to `QtQuick`,
which shadows the `Color` singleton in `qs.Commons`. Plugin widgets that write
`Color.popups.background` (vitals, mocchi, rain, ...) then read `undefined`
out of an unrelated type, and their popups render black.

On a Quickshell without that patch the pragma is ignored (with a warning) and
plugin popups may come up black again.

## Switching to the Omarchy bar and back

The menu's **Omarchy bar** entry shows the stock bar and hides bombshell
(bombshell keeps running, so switching back is instant).

`scripts/bombshell-install-plugin.sh` also installs a small widget into the
stock Omarchy bar (id `bombshell.switch`) that draws a bomb glyph (`\uf1e2`)
and switches back to bombshell when clicked. It:

1. writes `~/.local/bin/bombshell`
2. copies `omarchy-plugin/bombshell.switch/` into `~/.config/omarchy/plugins/`
3. asks the running Omarchy shell to put it at the start of the bar

If the Omarchy shell is not running when you install it, the script prints the
two commands to run once it is. The Omarchy shell compiles bar widgets once, so
after changing the widget source, restart it with `omarchy-restart-shell` to see
the change.

## Start at login

`~/.config/hypr/autostart.lua` starts bombshell a few seconds after the session
comes up:

```lua
o.launch_on_start("bash -lc 'sleep 3; bombshell'")
```

Remove that line to disable it.

## State

Settings and the widget layout are stored in `~/.cache/bombshell/state.json`.
Delete it to reset everything to defaults.

Alongside the layout the file keeps `hidden` (bombshell's widgets that are
switched off) and `prefs` (the island each widget was last on), so a widget
that is switched off comes back where it was.

## Layout

```
shell.qml              entry point, one Bar per screen, the panels
Theme.qml              palette, settings, telemetry, panels, IPC
Bar.qml                the bar surface, islands, registry, drag and drop
PanelSurface.qml       shared dropdown frame
ContentsPanel.qml      the bar contents submenu
EditOverlay.qml        the backdrop shown while the bar is edited
OmarchyPlugins.qml     the catalogue of Omarchy plugin bar widgets
PluginWidget.qml       hosts one Omarchy plugin widget
OmarchyBarShim.qml     the `bar` object a plugin widget expects
WidgetButton.qml       shared widget shell (hover, tooltip, click, wheel)
Ui*.qml                panel controls (button, slider, toggle, row, header, …)
*Widget.qml            the bar widgets
*Panel.qml             the dropdown panels
Palette.js, Icons.js   colour parsing and glyphs
assets/menu/           menu-icon masks (cat, rockstar, mjolnir, vaultboy)
scripts/               launcher, state toggles, telemetry, plugin scan
omarchy-plugin/        the stock-bar switch widget
```

## Scripting

The bar answers IPC on the `bombshell` target:

```
qs ipc -p ~/bombshell call -- bombshell panel contents   # open a panel
qs ipc -p ~/bombshell call -- bombshell edit              # start editing
qs ipc -p ~/bombshell call -- bombshell exitEdit          # finish editing
qs ipc -p ~/bombshell call -- bombshell move clock right  # move a widget
```

`move` takes a widget id — a bombshell widget (`clock`, `weather`, …) or a
plugin (`plugin:omarchy.clock`) — and an island (`left`, `center`, `right`).

## Notes

- Plugin widgets run **inside bombshell's own process**, not in the stock
  Omarchy shell. The widget is loaded from the plugin's entry point and handed
  the three things the stock bar hands every widget: a `bar` object, the plugin
  id, and the settings the shell keeps for it in `shell.json`.
- That `bar` object is a stand-in (`OmarchyBarShim.qml`): the colours, the
  geometry, the tooltip and popout bookkeeping, and `run()` all work, and
  `bar.shell` is a stub. A widget that needs one of the Omarchy shell's own
  plugin *services* — `bar.shell.serviceFor("…")` — gets nothing back and may
  show an error where it expected a value. All 54 plugin bar widgets on a
  stock install load under the shim; the handful that complain about it
  (`foamy.vitals`, `omadrives`, `davidjm.rain`) complain in the stock shell
  too.
- A plugin widget that opens a panel of its own opens it in bombshell, not in
  the stock shell.
- The tray renders each item's icon (Quickshell resolves it to an `image://`
  URL) and skips items that ask to stay passive. Left click activates, middle
  click secondary-activates, wheel scrolls. Right click opens a themed menu
  built from the item's DBusMenu model (`TrayMenuPanel.qml`), including nested
  submenus — Quickshell cannot show a *native* tray menu, so the stock bar and
  quickshell-dots draw the menu themselves the same way.
- The display panel sets brightness with `omarchy-brightness-display`, text size
  with `omarchy-display-text-size`, and scale/monitor state via
  `omarchy-hyprland-monitor-scaling` and `hyprctl`.
- Weather comes from `wttr.in` (the same source as the stock bar). The weather
  panel has a **Location** field: type a city and press Enter, or leave it blank
  to auto-detect from the IP. It writes Omarchy's own
  `~/.local/state/omarchy/settings/weather.json`, so the stock bar and bombshell
  stay in sync (the CLI is `omarchy-weather-location --set "<city>"`).
- The bundled menu icons are white alpha masks stored in `assets/menu/`. They
  are colourised with the bar foreground (`ColorOverlay`), so they follow the
  theme just like the font glyphs. The custom **Image** option is drawn as-is,
  which keeps multi-colour artwork intact.
