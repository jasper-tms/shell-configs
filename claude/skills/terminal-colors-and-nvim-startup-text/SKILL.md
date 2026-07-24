---
name: terminal-colors-and-nvim-startup-text
description: Terminal color problems (monochrome or missing colors, uncolored prompt, especially over ssh) and stray characters like `+q4D73` or `ppppp$qm` drawn when neovim starts. Explains why TERM is nsterm here.
---

# Skill: Terminal colors and stray text during neovim startup

Jasper connects from macOS Terminal.app, which declares itself as `nsterm`
(Terminal.app > Settings > Profiles > Advanced > "Declare terminal as").
ssh forwards `TERM`, so every machine he connects to sees `TERM=nsterm`.
That choice is deliberate, and several settings in this repo exist only to
compensate for it. Do not "fix" a color complaint by telling him to switch
back to `xterm-256color` without reading this first.

## Why TERM is nsterm

Neovim 0.10 and later probe the terminal at startup. Terminal.app
implements neither XTGETTCAP (`DCS + q <hex> ST`) nor CSI sequences with a
`$` intermediate byte. Instead of answering, it draws the payload as
literal text over the buffer:

| Artifact on screen | What it really is |
| --- | --- |
| `+q4D73` | OSC 52 clipboard probe (`4D73` = hex for `Ms`) |
| `+q5463;524742;...` | truecolor probe (`Tc`, `RGB`, `setrgbf`, `setrgbb`) |
| `ppppp$qm` | five DECRQM mode queries (`ESC[?69$p`, `?2026`, `?2027`, `?2031`, `?2048`), each losing its final `p`, plus DECRQSS `ESC P $qm ESC\` |

The `+q4D73` one persists on screen; the others flash and are cleared by
neovim's first redraw. Three separate settings are needed to silence all
of them, and no `TERM` value or `g:termfeatures` key covers everything:

| TERM | NVIM_NOTTYFAST | Artifacts |
| --- | --- | --- |
| `xterm-256color` | unset | `+q4D73`, `ppppp`, `$qm` |
| `xterm-256color` | `1` | `ppppp$qm` |
| `nsterm` | unset | `+q…`, `$qm` |
| `nsterm` | `1` | none |

`NVIM_NOTTYFAST` is the only environment knob neovim has (confirm with
`strings $(which nvim) | grep '^NVIM_'`). It must be an environment
variable: the startup probes run before any config file loads, so
`:set nottyfast` in `nvim-init.vim` is too late. Its only cost is
`'termguicolors'` autodetection, which is free here because Terminal.app
has no 24-bit color anyway. Background detection via OSC 11 is retained.

## The compensating settings, all in this repo

- `shell_misc.sh` — `export NVIM_NOTTYFAST=1` (skips the truecolor probes)
- `shell_misc.sh` — `case "$TERM" in nsterm*) export TERM_PROGRAM=...`
- `shell_misc.sh` — both PS1 `case` patterns include `nsterm*`
- `ls_colors.txt` — a `TERM nsterm*` line (Linux only; macOS uses the
  `CLICOLOR`/`LSCOLORS` branch instead)
- `neovim/nvim-init.vim` — `g:termfeatures` with `osc52` false, which is
  the only key that variable supports

## The class of bug to expect from nsterm

Tools split into two groups. Ones that read terminfo are fine, because
`nsterm` correctly advertises 256 colors and mouse support: neovim, the
prompt, `ls`, `git`, `grep`. Ones that pattern-match `TERM` by name break,
because `nsterm` matches none of their hardcoded lists. Node is the known
case, and Claude Code goes monochrome without the fix:

| Environment | `node -p 'process.stdout.getColorDepth()'` |
| --- | --- |
| `TERM=nsterm` | 1 (monochrome) |
| `TERM=nsterm-256color` | 4 (16 colors) |
| `TERM=nsterm` + `TERM_PROGRAM=Apple_Terminal` | 8 (256 colors) |
| `TERM=xterm-256color` | 8 (256 colors) |

Terminal.app sets `TERM_PROGRAM` natively but ssh does not forward it, so
`shell_misc.sh` re-derives it. That is accurate rather than a guess:
Terminal.app is the only terminal that declares itself `nsterm`. Inside
screen or tmux `TERM` becomes `screen*`/`tmux*`, so the rule does not fire.

Do NOT reach for `COLORTERM=truecolor` to restore color. It silences the
neovim probe and satisfies Node, but it is a lie: Terminal.app has no
24-bit color, so applications would emit sequences it cannot render.
Likewise avoid a global `FORCE_COLOR`, which forces color even when output
is piped and so corrupts anything parsing that output.

## Diagnosing a new instance

Capture what a program actually emits by running it under a pty. `script`
records the byte stream; the terminal never answers, which is fine because
you only care about what was sent:

```bash
script -qec "env TERM=nsterm nvim -c q somefile.txt" out.raw
cat -v out.raw | grep -o 'P+q[0-9A-F;]*'          # XTGETTCAP probes
python3 -c "print(bytes.fromhex('4D73').decode())" # decode a capability
```

For a tool that lost its colors, first find out which group it is in:

```bash
tput colors                    # what terminfo says (256 under nsterm)
node -p 'process.stdout.getColorDepth()'   # what a TERM-matcher decides
```

If terminfo is right but the tool disagrees, it is matching `TERM` by
name, and the fix is to give it the signal it looks for (as we did with
`TERM_PROGRAM`) rather than to change `TERM`.

## Escape hatch

Setting the Terminal.app dropdown back to `xterm-256color` reverts all of
this from the client side, with nothing to undo on any server. The cost is
the `ppppp$qm` flash returning at every neovim startup.
