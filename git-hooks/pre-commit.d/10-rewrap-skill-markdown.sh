#!/bin/bash
# Re-wraps the paragraphs a commit touches in every staged Markdown file that
# belongs to a skill, so their lines stay under 80 characters, and re-stages
# the result. Untouched paragraphs are left alone, so a one-line edit does not
# re-wrap the whole file. See shell_scripts/rewrap-markdown for the rules.
#
# Only skill files: a .md file belongs to a skill when its own folder, or a
# parent folder within the repo, contains a SKILL.md. That covers SKILL.md and
# its reference files in any repo, but not generated listings like INDEX.md,
# whose long one-line entries are meant to stay on one line.
#
# A file that also has unstaged changes is not touched, since re-wrapping and
# re-staging it would sweep those unstaged changes into the commit. Instead the
# commit is aborted with instructions, but only if the staged version actually
# needs re-wrapping.
set -e
repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$repo_root"

if ! command -v rewrap-markdown >/dev/null; then
    echo "note: rewrap-markdown is not on PATH; skill Markdown not re-wrapped" >&2
    exit 0
fi

blocked_paths=()
while IFS= read -r -d '' path; do
    directory="$(dirname "$path")"
    belongs_to_skill=false
    while :; do
        if [ -f "$directory/SKILL.md" ]; then
            belongs_to_skill=true
            break
        fi
        [ "$directory" = . ] && break
        directory="$(dirname "$directory")"
    done
    [ "$belongs_to_skill" = true ] || continue

    # Only re-wrap the paragraphs this commit touches, not the whole file. Each
    # diff hunk header `@@ -a,b +start,count @@` names the changed lines of the
    # staged version; a count of 0 is a pure deletion just after line `start`,
    # so mark the two lines that now meet there.
    changed_lines="$(git diff --cached -U0 --no-color --no-ext-diff -- "$path" | awk '
        /^@@/ {
            split(substr($3, 2), range, ",")
            start = range[1]
            count = (2 in range) ? range[2] : 1
            last = (count == 0) ? start + 1 : start + count - 1
            if (count == 0 && start == 0) start = 1
            printf "%s%d-%d", separator, start, last
            separator = ","
        }')"
    [ -n "$changed_lines" ] || continue

    staged="$(git show ":$path")"
    if [ "$(printf '%s\n' "$staged" | rewrap-markdown --lines "$changed_lines" - 2>/dev/null)" = "$staged" ]; then
        continue
    fi
    if ! git diff --quiet -- "$path"; then
        blocked_paths+=("$path")
        continue
    fi
    rewrap-markdown --lines "$changed_lines" "$path" >/dev/null
    git add -- "$path"
    # `git commit <paths>` commits from a temporary index, and has already
    # written what the real index will become to index.lock, which it renames
    # into place afterward. Stage there too, or the real index keeps the
    # unwrapped version and `git status` shows a spurious change.
    real_index_lock="$(git rev-parse --absolute-git-dir)/index.lock"
    if [[ "$GIT_INDEX_FILE" == */next-index-*.lock && -f "$real_index_lock" ]]; then
        GIT_INDEX_FILE="$real_index_lock" git add -- "$path"
    fi
    echo "Re-wrapped $path" >&2
done < <(git diff --cached --name-only --diff-filter=ACMR -z -- '*.md')

if [ ${#blocked_paths[@]} -gt 0 ]; then
    echo "error: these skill files need re-wrapping but also have unstaged changes:" >&2
    printf '    %s\n' "${blocked_paths[@]}" >&2
    echo "Stage or stash the unstaged changes, or run rewrap-markdown on them" >&2
    echo "yourself, then commit again." >&2
    exit 1
fi
