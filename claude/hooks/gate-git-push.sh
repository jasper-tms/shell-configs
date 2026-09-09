#!/usr/bin/env bash
# PreToolUse hook (Bash matcher): decide how `git push` commands are handled.
#
#   - push to a feature branch  ->  allow  (agent pushes on its own, no prompt),
#                                          even inside a compound command
#   - push to main/master/prod  ->  ask when a user is present; deny when headless
#   - forced push               ->  ask when a user is present; deny when headless
#   - push target unresolvable  ->  ask when a user is present; deny when headless
#   - not a git push at all      ->  stay silent, let the normal flow proceed
#
# "Headless" means a launcher exported CLAUDE_HEADLESS=1 (e.g. the tidy-repos
# cron run.sh): there is no user to answer an "ask", so a would-be ask becomes a
# hard deny rather than a tool call that hangs on an unanswerable prompt.
#
# A push with no refspec (bare `git push`, or `git push <remote>`) has an
# implicit target, so the hook asks git itself what would be pushed: it resolves
# the current branch AND its upstream in the repo the command runs against (the
# `cwd` the harness passes, or a `git -C <path>`), and treats the push as going
# to whichever it finds. Only when that cannot be resolved -- detached HEAD, a
# `cd` into a directory we can't predict, not a repo -- does it fall back to ask.
#
# Compound feature pushes are allowed because a hook "allow" cannot loosen past
# the settings deny rules or the auto-mode classifier -- both still fire per
# subcommand -- so a dangerous command riding along (rm, mv, git reset --hard,
# ...) is still caught. Verified empirically.
#
# Claude Code pipes the pending tool call to this script as JSON on stdin, and
# reads a JSON verdict from stdout.
#
# The command is parsed rather than pattern-matched, so variants all work:
#   git push -u origin b        git -C /repo push origin b
#   git -c k=v push origin b    git --git-dir=x --work-tree=y push origin b
#   FOO=bar git push origin b   a && git push origin b
# Refspec forms are understood too: origin main, HEAD:main, feat:main, :main,
# HEAD:refs/heads/main all count as pushing to main.
set -euo pipefail

input="$(cat)"

# Without jq we cannot read the command; stay silent rather than break pushing.
command -v jq >/dev/null 2>&1 || exit 0

command_string="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[ -n "$command_string" ] || exit 0

# Fast path: if the word "push" never appears, this cannot be a git push.
printf '%s' "$command_string" | grep -Eq '\bpush\b' || exit 0

# The directory the command runs in (for resolving an implicit push target), and
# whether the command contains a `cd` that could move it somewhere we can't
# predict.
CWD="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
[ -n "$CWD" ] || CWD="$PWD"
HAS_CD=0
printf '%s' "$command_string" | grep -Eq '(^|[;&|(]|[[:space:]])cd[[:space:]]' && HAS_CD=1

# Emit a decision and exit. $1 = allow|deny|ask, $2 = human-readable reason.
emit() {
    jq -n --arg d "$1" --arg r "$2" \
        '{hookSpecificOutput: {hookEventName: "PreToolUse",
                               permissionDecision: $d,
                               permissionDecisionReason: $r}}'
    exit 0
}

# The branch names agents may not push to. Add to this list to protect more.
branch_is_protected() {
    case "$1" in main | master | prod) return 0 ;; *) return 1 ;; esac
}

# True if a refspec token's destination is a protected branch. The destination
# is the part after the last colon (e.g. HEAD:main -> main), with any leading +
# stripped and any refs/heads/ prefix reduced to its basename.
destination_is_protected() {
    local spec="${1#+}"
    local dest="${spec##*:}"
    dest="${dest##*/}"
    branch_is_protected "$dest"
}

# Resolve where an implicit (refspec-less) push would go and classify it.
# Prints: protected (goes to a protected branch) | feature (elsewhere) | unknown.
# $1 = the push's `git -C <path>` argument, if any.
implicit_destination_status() {
    local dash_c="$1" dir
    if [ -n "$dash_c" ]; then
        # Resolve the -C path (the shell expands ~ before git sees it, so the
        # hook must too): absolute as-is, ~ and ~/ against HOME, else relative
        # to the command's working directory.
        case "$dash_c" in
            /*)    dir="$dash_c" ;;
            "~")   dir="$HOME" ;;
            "~/"*) dir="$HOME/${dash_c#"~/"}" ;;
            *)     dir="$CWD/$dash_c" ;;
        esac
    elif [ "$HAS_CD" = "1" ]; then
        echo unknown; return
    else
        dir="$CWD"
    fi

    local cur up upbranch
    cur="$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
    { [ -n "$cur" ] && [ "$cur" != "HEAD" ]; } || { echo unknown; return; }

    up="$(git -C "$dir" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || true)"
    upbranch="${up##*/}"

    if branch_is_protected "$cur" || branch_is_protected "$upbranch"; then
        echo protected
    else
        echo feature
    fi
}

# Analyze one command segment. Prints "push <force> <protected> <unresolved>" if
# the segment is a `git push`, otherwise "nopush". protected=1 -> deny;
# unresolved=1 -> ask (implicit target we could not pin down).
analyze_segment() {
    local seg
    seg="$(printf '%s' "$1" | tr '(){}' '    ')"  # drop grouping punctuation
    local -a t
    read -r -a t <<< "$seg"
    local n=${#t[@]} i=0

    # Skip leading `NAME=value` environment assignments and an optional `env`.
    while [ "$i" -lt "$n" ]; do
        case "${t[$i]}" in
            env) i=$((i + 1)) ;;
            *=*) printf '%s' "${t[$i]}" | grep -Eq '^[A-Za-z_][A-Za-z0-9_]*=' || break; i=$((i + 1)) ;;
            *) break ;;
        esac
    done

    # Expect the git executable (git, or a path ending in /git).
    [ "$i" -lt "$n" ] || { echo nopush; return; }
    case "${t[$i]}" in git | */git) ;; *) echo nopush; return ;; esac
    i=$((i + 1))

    # Skip git's global options; several take a separate argument. Capture -C.
    local dash_c=""
    while [ "$i" -lt "$n" ]; do
        case "${t[$i]}" in
            -C) dash_c="${t[$((i + 1))]:-}"; i=$((i + 2)) ;;
            -c | --git-dir | --work-tree | --namespace | --super-prefix | --exec-path | --config-env) i=$((i + 2)) ;;
            --git-dir=* | --work-tree=* | --namespace=* | --exec-path=* | --super-prefix=* | --config-env=*) i=$((i + 1)) ;;
            -*) i=$((i + 1)) ;;
            *) break ;;
        esac
    done

    # The subcommand must be `push`.
    { [ "$i" -lt "$n" ] && [ "${t[$i]}" = "push" ]; } || { echo nopush; return; }
    i=$((i + 1))

    # Walk the push's own arguments: flags vs positionals (remote, then refspecs).
    local force=0
    local -a positionals=()
    while [ "$i" -lt "$n" ]; do
        case "${t[$i]}" in
            -f | --force | --force-with-lease | --force-with-lease=* | --force-if-includes) force=1 ;;
            --) i=$((i + 1)); while [ "$i" -lt "$n" ]; do positionals+=("${t[$i]}"); i=$((i + 1)); done; break ;;
            -*) : ;;
            *) positionals+=("${t[$i]}") ;;
        esac
        i=$((i + 1))
    done

    # No refspec -> implicit target; ask git where it would go.
    if [ "${#positionals[@]}" -lt 2 ]; then
        case "$(implicit_destination_status "$dash_c")" in
            protected) echo "push $force 1 0" ;;
            feature)   echo "push $force 0 0" ;;
            *)         echo "push $force 0 1" ;;
        esac
        return
    fi

    # Explicit refspecs: deny if any destination is main/master.
    local protected=0 ri=1
    while [ "$ri" -lt "${#positionals[@]}" ]; do
        destination_is_protected "${positionals[$ri]}" && protected=1
        ri=$((ri + 1))
    done
    echo "push $force $protected 0"
}

# Split the command into segments on shell control operators, then analyze each.
segments="$(printf '%s' "$command_string" | sed -E 's/(\&\&|\|\||;|\|)/\n/g')"

any_push=0 any_protected=0 any_forced=0 any_unresolved=0
while IFS= read -r segment; do
    [ -n "${segment// /}" ] || continue
    read -r kind force protected unresolved <<< "$(analyze_segment "$segment")"
    [ "$kind" = "push" ] || continue
    any_push=1
    [ "$protected" = "1" ] && any_protected=1
    [ "$force" = "1" ] && any_forced=1
    [ "$unresolved" = "1" ] && any_unresolved=1
done <<< "$segments"

# No git push anywhere -> stay silent, let the normal flow proceed.
[ "$any_push" = "1" ] || exit 0

# Headless runs (a launcher exports CLAUDE_HEADLESS=1, e.g. the tidy-repos cron
# run.sh) have no user to answer an "ask", so downgrade every would-be ask to a
# hard "deny". When a user is present, keep the "ask" so a deliberate push to
# main just prompts.
ask_or_deny() {  # $1 = ask reason (shown to the user), $2 = deny reason (shown to the agent)
    if [ "${CLAUDE_HEADLESS:-}" = "1" ]; then emit deny "$2"; else emit ask "$1"; fi
}

# Push to main/master/prod, in any refspec form, compound or not.
[ "$any_protected" = "1" ] && ask_or_deny \
    "Push to a protected branch (main/master/prod); confirm this is intended." \
    "Pushing to main/master/prod is blocked in headless runs; skip it, and if it needs pushing, ask the user to do it."

# Forced push (history overwrite) and unresolvable-target pushes: not
# auto-allowed either -- confirm with the user, or block when headless.
[ "$any_forced" = "1" ] && ask_or_deny \
    "Force push; confirm before overwriting history." \
    "Force push (history overwrite) is blocked in headless runs; skip it, and ask the user if it is needed."
[ "$any_unresolved" = "1" ] && ask_or_deny \
    "Could not determine the push target branch; confirm it is not main/master/prod." \
    "Could not determine the push target branch; blocked in headless runs to avoid an unconfirmed push to main/master/prod."

emit allow "Push to a feature branch."
