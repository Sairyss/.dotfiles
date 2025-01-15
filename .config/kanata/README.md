# Kanata config

[Kanata](https://github.com/jtroo/kanata) is a software keyboard remapper that allows you to create complex key behaviour,
like key chords, tap-hold, layers, macros, and so on.

## Motivation

I mainly use keyboard to trigger certain actions and control different apps, and most
of the hotkeys usually involve modifier keys like `ctrl`, `alt`, `meta`, etc. It works,
but I've noticed that my fingers get strained quickly reaching those keys and
putting my hand in awkward positions to press some shortcuts.
After spending some years coding in Vim, I really got used to it's layer-based
approach. You press `<leader>` which puts you in a new layer. From there you can
execute actions by just pressing one key, or move into other layers.

This config is an attempt to bring that layer-based approach into my operating system.

## Vim-like motions and layers

I used default keys in my DE for quite some time:

- `alt+f4` to quit the window.
- `alt-tab` to switch to the previous window.
- `ctrl+w` to close the tab in some apps (like browsers)
- `ctrl+t` to create a new tab
- `ctrl+right` to go to the next word when typing
- and so on

With Kanata, I mapped those keys to vim-like layers so I don't have to
move my hands away from the home row.

Below is (non-exhaustive) list of key maps I use.
For full list check the config: [kanata.kdb](./kanata.kbd)

> [!NOTE]
> This config is tested in KDE plasma. Might need some adjustments for
> other DEs since it heavily utilizes default shortcuts to map certain actions.

### Leader layer

`<leader>` key is mapped to `j+k` chord to toggle the layer (press `esc` to exit),
or is toggled while holding `return`/`enter` key (I use a split keyboard so this key
is on my right thumb, you'll have to change it to your liking).

Pressing/holding key assigned to `<leader>` takes you to the leader layer.
This layer allows you to execute certain actions or move to
other layers (same as Vim):

- `<leader>w` - enter window layer
- `<leader>n` - enter normal mode layer
- `<leader>f` - open/focus Firefox
- `<leader>q` - open/focus email client
- `<leader>space` - open launcher ([rofi](https://github.com/lbonn/rofi) in my case)
- and so on. I have all of my most frequently used apps in leader layer.

Pressing `esc` or `'` exits from any layer.

### Window layer

Window layer lets you control window-related actions.

- `<leader>w` puts you into the "Window layer"
- `<leader>wq` quits focused window
- `<leader>we` switches to the previous window
- `<leader>wd` closes the tab
- `<leader>wt` creates a new tab
- `<leader>wf` toggle maximize window
- `<leader>wm` minimize window
- `<leader>w(h/j/k/l)` switch windows left/below/above/right

### Normal mode layer

Entering normal mode replicates Vim normal mode in your DE.
At the time of writing entering normal mode is triggered by `<leader>n` or `n+m` chord.
While in normal mode you can do things like:

- `hjkl` to move cursor
- `gg` and `G` (`Shift+g`) to go to the beginning/end of the document
- `diw` to delete a word and copy it (`ciw` to cut and go to insert mode)
- `dd` to delete the line (and copy it)
- `$` (`Shift+4`) and `^` (`Shift+6`) to go to the beginning/end of the line
- `r` to replace letter under cursor
- `y` and `p` to copy and paste (`yy` will copy the line)
- `v` for Visual Mode (holds shift under the hood to replicate this)
- etc.

This functionality is achieved by creating macros that execute KDE's
hotkeys for text manipulations (see config for examples). If you use a different
DE and/or default shortcuts you may need to modify the config to your needs.

Not all functionality is possible/easy to replicate outside of Vim,
but I've managed to replicate some commonly used basic things. It still
is a work in progress, I will try to add more features as time goes.

### CTRL layer

Kanata has `tap-hold` functionality to trigger certain actions when the key is held.
For example, when I hold a `f` key, `CTRL` layer is triggered (similar to [home row mods](#home-row-mods), see below).
When key is released, layer is exited (unlike a regular tap which puts you into some layer until `esc` is pressed).
This makes it easy to navigate in some apps like Neovim, since I can:

- hold `f` and press `u` or `d` to go up/down in Neovim instead of holding `ctrl`
- move between open windows using `f+(h/j/k/l)` instead of `ctrl+(h/j/k/l)`
- etc.

Instead of holding `ctrl` with my pinky, I hold `f` with my index finger, which doesn't strain my fingers as much.

You can map any layer to any key this way.

### Input Chords

For some most frequent apps/actions it might be faster to just press `key1+key2` than going to a layer.
For these I use [Input chords](https://github.com/jtroo/kanata/blob/v1.7.0/docs/config.adoc#input-chords--combos-v2). This allows executing actions by pressing any two (or more) keys at the same time.
For example you can press `1+2`, `1+2+3`, or `a+b`, etc. I use it to switch between specific windows or layers:

- `d+f` focuses my terminal that runs Neovim
- `c+v` focuses my regular terminal
- `f+g` focuses Firefox
- `j+k` enters leader layer
- etc.

It's more convenient than `mod+key` combinations that I previously used for this.

## Apps and plugins

Below are some apps and plugins that support vim motions.

- [Vimium](https://addons.mozilla.org/en-US/firefox/addon/vimium-ff/) - Firefox extension for vim motions
- [zsh-vi-mode](https://github.com/jeffreytse/zsh-vi-mode) - vim mode in your terminal
- [yazi](https://github.com/sxyazi/yazi) - file manager that supports vim motions
- [kanata-tray](https://github.com/rszyma/kanata-tray) - kanata tray icon (can show custom icons on layer change)

## Other

### Launching/focusing apps from kanata

For this to work you have 2 options:

- Map your apps to any shortcuts in your DE (in my case it's `meta+(1-4)` and `meta+(q-r)` for apps, `meta+esc` for terminal, and `ctrl+space` for launcher). After that you can map those shortcuts to whatever layers you want with Kanata.
- Alternatively you can run binaries directly with Kanata [cmd](https://github.com/jtroo/kanata/blob/main/docs/config.adoc#cmd) feature, but it's a bit harder to setup and is generally not recommended.

### Config examples

- [Kanata configuration](https://github.com/jtroo/kanata/blob/v1.7.0/docs/config.adoc) - check docs to find out about other kanata features.
- Kanata config showcase thread: <https://github.com/jtroo/kanata/discussions/518>
- You can also have per-app layer switching with plugins (like [qanata](https://github.com/veyxov/qanata) or [nata](https://github.com/mdSlash/nata))

### Home row mods

Home row mods is an approach to map your modifier keys (`ctrl`, `alt`, `shift`, `meta`) into the home row (`hjkl` and `sdfg`) when the button is held.
Read more about home row mods here: <https://precondition.github.io/home-row-mods>

Example configs for Kanata to enable home row mods:

1. <https://github.com/dreamsofcode-io/home-row-mods/blob/main/kanata/linux/kanata.kbd>
2. <https://github.com/jtroo/kanata/discussions/1455>

> [!WARNING]
> Home row mods are not for everyone, fast typists will have issues like having to
> wait a bit longer when holding a mod key for it to trigger, which can disrupt the flow,
> or accidentally trigger modifier keys during typing.
> If that's the case for you, consider mapping only some most used key combinations
> instead of remapping all the keys, using kanata [input chords](https://github.com/jtroo/kanata/blob/v1.7.0/docs/config.adoc#input-chords--combos-v2),
> or use layers for some actions (like [CTRL Layer](#ctrl-layer) described above).

### Alternatives

- [Hyprland](https://hyprland.org/) has similar functionality called [submaps](https://wiki.hyprland.org/Configuring/Binds/#submaps) and it works pretty great (though I still prefer kanata since it has more features, works with any DE and is cross-platform).
- [kmonad](https://github.com/kmonad/kmonad) - keyboard remapper similar to kanata
