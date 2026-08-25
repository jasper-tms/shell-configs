Scores not run: this skill is intentionally left unregistered (not
symlinked into `~/.claude/skills/`) because it is niche, so subagents do
not discover it. These prompts are ground truth for validating the
description if it is ever registered.

## Should trigger
1. "When I move my mouse over my terminal window, weird text like `[<35;60;12M` keeps getting typed into the prompt. How do I fix it?"
2. "I lost my ssh connection to a box that was running a full-screen program, and now my local terminal spews garbage whenever the mouse moves over it."

## Should not trigger
1. "My terminal prompt has no colors over ssh and neovim prints stray characters like `+q4D73` on startup." (covered by terminal-colors-and-nvim-startup-text)
2. "How do I enable mouse support in tmux so I can click to select panes?"
