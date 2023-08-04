---
# the default layout is 'page'
icon: fas fa-info-circle
order: 2
---

The `neoman` project can be used to install, initialize, configure, and manage

| **Neoman**                           | **Managed**                                | **Project**                                    | **Configs**                                    |
| ------------------------------------ | ------------------------------------------ | ---------------------------------------------- | ---------------------------------------------- |
| [Asciiville](#asciiville-management) | [MirrorCommand](#mirrorcommand-management) | [MusicPlayerPlus](#musicplayerplus-management) | [RoonCommandLine](#rooncommandline-management) |
| [neovim](#neovim-management)         | [neomutt](#neomutt-management)             | [newsboat](#newsboat-management)               | [btop++](#btop-management)                     |
| [kitty](#kitty-management)           | [neofetch](#neofetch-management)           | [w3m](#w3m-management)                         | [tmux](#tmux-management)                       |

These are powerful, configurable, extensible, character-based programs. Neoman
automates the installation, initialization, configuration, and management of
these tools using a command line and character menu interface.

## Asciiville management

See [https://asciiville.dev](https://asciiville.dev)

## MirrorCommand management

See [https://mirrorcommand.dev](https://mirrorcommand.dev)

## MusicPlayerPlus management

See [https://musicplayerplus.dev](https://musicplayerplus.dev)

## RoonCommandLine management

See [https://rooncommand.dev](https://rooncommand.dev)

## Neovim management

Neoman uses the
[Lazyman Neovim Configuration Manager](https://lazyman.dev)
to install [Neovim](https://neovim.io/), tools, and dependencies as well as
multiple Neovim configurations, and the
[Bob](https://github.com/MordechaiHadad/bob) Neovim version manager.

<div align="center">
<p float="center">
  <img src="https://raw.githubusercontent.com/wiki/doctorfree/nvim-lazyman/screenshots/lazymenu-transparent.png" alt="Lazyman Neovim Configuration Menu" style="width:900px;height:600px;">
</p>
</div>

## NeoMutt management

Neoman installs the versatile and highly configurable
[NeoMutt](https://github.com/neomutt/neomutt#readme)
command line mail reader (based on Mutt) if not already present
and installs a rich user NeoMutt configuration. The Neoman
NeoMutt configuration can be managed via the `neoman` menu system.

## Newsboat management

The [Newsboat](https://newsboat.org) RSS/Atom feed reader is installed by
Neoman and a rich `newsboat` configuration can be installed using `neoman`.

## Btop management

The [Btop++](https://github.com/doctorfree/btop#readme) system resource monitor
shows usage and stats for processor, memory, disks, network, and processes.
Neoman installs a precompiled `btop` in native package format and provides
a themed `btop` user configuration.

## Kitty management

The fast, feature-rich, GPU based [Kitty](https://sw.kovidgoyal.net/kitty)
terminal emulator is installed and an extensive Kitty configuration made
available by Neoman.

## Neofetch management

The [Neofetch](https://github.com/dylanaraps/neofetch) system information tool is managed
through the `neoman` menu interface.

Many [Neofetch themes](share/neofetch-themes/README.md) are included
in `neoman` thanks primarily to the excellent work of Github user
[Chick2D](https://github.com/Chick2D/neofetch-themes).

## W3m management

[w3m](https://w3m.sourceforge.net) is a text-based web browser as well as a
pager like `more` or `less`. With `w3m` you can browse web pages through a
terminal emulator window (e.g. `kitty`). Moreover, `w3m` can be used as a text
formatting tool which typesets HTML into plain text.

Neoman installs `w3m` and provides an extensive `w3m` configuration which
includes a `mailcap` tailored for use with a character browser.

## Tmux management

[tmux](https://github.com/tmux/tmux/wiki) is a terminal multiplexer. It enables
multiple terminals to be created, accessed, and controlled from a single screen.
Neoman installs `tmux` if not already present and provides an extensive user
`tmux` configuration.
