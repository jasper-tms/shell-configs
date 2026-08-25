---
name: fix-mouse-movements-appearing-as-text-in-terminal
description: Moving the mouse over a terminal window injects junk like `[<35;60;12M` into the prompt. Fix stuck xterm mouse reporting (common after an ssh/TUI connection drop). `reset` does not fix it on macOS.
---

# Skill: Fix mouse movements appearing as text in the terminal

## Symptom

Just moving the mouse over the terminal window (no click needed) types
garbage into the prompt, e.g. fragments like `[<35;60;12M` or `[M ...`.

## Cause

A full-screen program (vim, `less`, `tmux`, `htop`, Claude Code, etc.)
turned on xterm mouse reporting, then exited or died without sending the
matching disable sequence. The terminal emulator keeps translating every
mouse event into an escape sequence and feeding it to the shell as
keystrokes.

The classic trigger is an ssh session into a remote TUI that drops
(`Connection reset by peer`): ssh dies instantly, so the remote program
never gets to send its disable sequence, and the local terminal is left
with mouse mode latched on.

Movement (not just clicks) generating text means any-event tracking
(DECSET mode `1003`) is the one stuck on.

This state lives in the terminal emulator's private mode flags, not the
kernel tty, so `stty` looks clean and a process query shows a healthy,
idle shell. Nothing is actually broken.

## Fix

Run this **in the affected terminal**:

```sh
printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?1015l'
```

Those are the DECRST codes that turn off each mouse-reporting mode.

## Why `reset` does not work (on macOS)

`reset` is `tset`, which only replays the terminal's terminfo reset
strings (`rs1`/`rs2`/`rs3`, `is1`/`is2`/`is3`). Those do not include the
mouse-mode-disable sequences, so `reset` has no path to turn mouse
reporting off. Use the `printf` above instead. (`reset` still fixes other
stuck states that terminfo does cover: a non-echoing prompt,
alternate-screen leftovers, garbled character sets.)

The same targeted approach clears other stuck private modes, e.g.
bracketed paste with `printf '\e[?2004l'`.
