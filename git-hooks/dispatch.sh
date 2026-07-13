# Shared body of every global git hook. Each hook file next to this one
# (post-checkout, post-commit, post-merge, pre-commit) is a one-line stub that
# sources this; the hook name is derived from $0, so the stubs are identical and
# adding a new hook type means adding another stub and nothing else.
#
# For a hook named <name>, in order:
#
#   1. Every executable script in <name>.d/, in sorted order. Each real concern
#      (uv-editables refresh, skills symlinking, ...) lives in its own file.
#   2. The repository's own .githooks/<name>, if it has one. This is the
#      convention that lets a repo ship a hook to everyone who clones it.
#   3. The repository's .git/hooks/<name>, if a tool like pre-commit or husky
#      installed one there, since core.hooksPath otherwise shadows it.
#
# Step 2 runs code that arrived in a clone, which is the thing git deliberately
# refuses to do: hooks live in .git/hooks, outside the tree and never cloned,
# precisely so that cloning a repo cannot make it execute code on your next
# commit. We reopen that door only for repos whose `origin` belongs to an
# account listed in `trusted-remotes` next to this file. Anything else is skipped
# with a note saying so, and can be opted into deliberately, per repo, with:
#
#     git config hooks.allowRepoHooks true
#
# (or opted out the same way with `false`, which wins even for a trusted remote).
#
# A failing script aborts the git command for a pre-* hook and is only a warning
# for a post-* one, which is not a policy choice so much as an observation: a
# post-* hook runs after the fact and has nothing left to stop.

hook_name="$(basename "$0")"
hook_home="$(cd "$(dirname "$0")" && pwd)"

case "$hook_name" in
    pre-*) is_pre_hook=true ;;
    *)     is_pre_hook=false ;;
esac

# The accounts whose repos may run their own checked-in hooks, one per line,
# comments and blanks stripped. See `trusted-remotes` for what belongs in it.
trusted_accounts() {
    trust_list="$hook_home/trusted-remotes"
    [ -f "$trust_list" ] || return 0
    sed -e 's/#.*//' -e 's/[[:space:]]//g' "$trust_list" | grep -v '^$'
}

# Is this repo's `origin` one of those accounts?
is_trusted_remote() {
    url="$(git remote get-url origin 2>/dev/null)" || return 1
    [ -n "$url" ] || return 1
    while IFS= read -r account; do
        [ -n "$account" ] || continue
        if printf '%s' "$url" | grep -qiE "github\.com[:/]${account}/"; then
            return 0
        fi
    done <<< "$(trusted_accounts)"
    return 1
}

# May we run this repo's checked-in hooks? An explicit `hooks.allowRepoHooks`
# decides it either way; otherwise the trust list does.
repo_hooks_allowed() {
    configured="$(git config --bool --get hooks.allowRepoHooks 2>/dev/null)"
    if [ -n "$configured" ]; then
        [ "$configured" = true ]
        return
    fi
    is_trusted_remote
}

# Run one hook script. On failure: abort a pre-* hook, warn from a post-* one.
run_hook_script() {
    script="$1"
    shift
    "$script" "$@" && return 0
    exit_code=$?
    if [ "$is_pre_hook" = true ]; then
        echo "error: $script failed (exit $exit_code); $hook_name aborted the command" >&2
        exit "$exit_code"
    fi
    echo "warning: $script failed (exit $exit_code)" >&2
}

# 1. The global scripts for this hook.
hook_dir="$hook_home/$hook_name.d"
if [ -d "$hook_dir" ]; then
    for script in "$hook_dir"/*; do
        [ -x "$script" ] || continue
        run_hook_script "$script" "$@"
    done
fi

# 2. The repository's own checked-in hook, if it is entitled to run.
repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"
repo_hook="$repo_root/.githooks/$hook_name"
if [ -n "$repo_root" ] && [ -x "$repo_hook" ]; then
    if repo_hooks_allowed; then
        run_hook_script "$repo_hook" "$@"
    else
        # Never skip this silently. A hook the repo went to the trouble of
        # checking in, quietly not running, is a worse outcome than either
        # running it or refusing loudly -- you would never think to look here.
        echo "note: not running $repo_hook" >&2
        echo "      (its origin is not in $hook_home/trusted-remotes, so this repo's" >&2
        echo "      checked-in hooks are not trusted to run). To allow them, either:" >&2
        echo "          git config hooks.allowRepoHooks true    # just this repo" >&2
        echo "      or add the account to trusted-remotes." >&2
    fi
fi

# 3. Anything a tool installed directly into .git/hooks, which core.hooksPath
# would otherwise shadow. Last, and exec'd, so its exit code becomes ours.
local_hook="$(git rev-parse --git-dir 2>/dev/null)/hooks/$hook_name"
if [ -x "$local_hook" ]; then
    exec "$local_hook" "$@"
fi
