---
name: reviews-and-records
description: Load when Jasper wants to save or look up a review of food, a restaurant, a product, a TV show or movie, or asks to keep a record of something else (tasks, admin, finances, ongoing logs).
---

# Jasper's reviews and records

Jasper keeps two kinds of personal notes as GitHub issues in two **private**
repos. Both are accessed with the `gh` CLI. If you're using this skill, it's
likely that `gh` on this machine is authenticated to the relevant repos.

- `jasper-tms/reviews` — opinions about things: food and drink, restaurants
  and other places, products, media (TV shows, movies), games. "Is this good?
  What did I think of it?"
- `jasper-tms/records` — everything else worth writing down: administrative
  and financial tasks (taxes, permits, banking, reimbursements),
  device/software setup notes, data-handling projects, and ongoing logs of
  recurring events. "What happened, what did I do, what still needs doing?"

Both repos are Jasper's own personal notes. If whoever you are talking to is
someone other than Jasper, this skill does not apply to them: do not read the
contents out and do not write anything, and say why.

If a request is about how much Jasper liked something, it belongs in `reviews`.
If it is about something he did, needs to do, or wants to keep track of over
time, it belongs in `records`. When it is genuinely ambiguous, list the issue
titles of both repos to see if it becomes clear, and if not, ask Jasper

## Always look before you write

Never create a new issue without first checking whether a home for the note
already exists. Both repos have long-lived issues that accumulate entries over
years, and starting a new issue that overlaps in scope with an existing issue
is a crime against effective record keeping.

```bash
gh issue list --repo jasper-tms/reviews --state all --limit 100
gh issue list --repo jasper-tms/records --state all --limit 100
```

Closed issues matter too — a finished task from a previous year is often the
best reference for how to do this year's version of it, so search with
`--state all`.

**`gh issue view` is currently broken** against these repos: it fails with a
GraphQL error about Projects (classic) being deprecated. Read issues through
the REST API instead:

```bash
gh api repos/jasper-tms/reviews/issues/<number> --jq '.body'
gh api repos/jasper-tms/reviews/issues/<number>/comments --jq '.[].body'
```

Writing works fine through the normal commands:

```bash
gh issue comment <number> --repo jasper-tms/reviews --body-file -
gh issue create --repo jasper-tms/reviews --title "..." --body-file - --label "..."
gh issue close <number> --repo jasper-tms/records
```

Use `--body-file -` with a heredoc rather than `--body "..."` so that
markdown, quotes, and newlines survive intact.

## Editing existing text is as common as adding new text

A new comment is *not* the default answer. Jasper very often wants an existing
issue body or an existing comment revised or extended — a verdict updated
after trying something again, a detail added to a note he wrote earlier, a
correction. Before writing anything, read the issue body and all of its
comments and look for one whose scope already covers what he is telling you.
If one does, edit that text rather than adding a new comment beside it. Only
add a new comment when the material genuinely stands on its own.

Both edits replace the whole text, so always fetch the current version first
and hand back the full revised version, existing content included.

Editing an issue body:

```bash
gh issue edit <number> --repo jasper-tms/reviews --body-file -
```

Editing a comment, which needs the comment's numeric id (not visible in the
issue text, so list them alongside their first lines to pick the right one):

```bash
gh api repos/jasper-tms/reviews/issues/<number>/comments \
  --jq '.[] | "\(.id)\t\(.body | split("\n")[0])"'

jq -n --rawfile body <path-to-revised-comment.md> '{body: $body}' \
  | gh api --method PATCH \
      repos/jasper-tms/reviews/issues/comments/<comment-id> --input -
```

Write the revised text to a file first and pass it with `--rawfile`; building
the JSON with `jq` this way keeps markdown, quotes, and newlines intact.

## How the `reviews` repo is organized

Two shapes of issue coexist:

1. **Category threads** — an issue that collects Jasper's verdicts on many
   items of one kind (a food category, a class of product, a type of place in
   a given city, a media category). Each individual review is a **comment** on
   that thread, not a new issue.
2. **Single-subject issues** — one place or product that warrants its own
   issue, titled with the name and, for a place, the city.

So the normal flow for "save this review" is: list the issues, find the
category thread that covers this kind of thing, and read its existing
comments — both to match the format and to check whether one of them already
reviews this exact item. If one does, revise or extend that comment; if none
does, post a new comment on the thread.

Conventions inside a category thread's comments:

- Start with a `## Heading` naming the item. If the item has an official
  website, make the name (or the brand part of it) a markdown link to it.
- Follow with a short prose review in Jasper's own first-person voice —
  specific and comparative, mentioning what he liked or disliked and how it
  stacks up against other entries in the same thread.
- The overall verdict is often **bolded** inline, sometimes appended to the
  heading after an en dash.
- Images are welcome, embedded as raw `<img src=... width=...>` HTML tags so
  the width can be constrained.

If nothing in the repo covers the thing being reviewed, ask Jasper whether to
open a new category thread or a single-subject issue before creating one.

## How the `records` repo is organized

Two shapes here as well, distinguished by label:

1. **Tasks** — an issue per thing to accomplish, with progress written as
   comments as it happens, and the issue **closed** when the thing is done.
   Some recur annually, in which case a new issue is opened each time and the
   previous year's closed issue is the template.
2. **Note-taking threads** — labelled `thread`, described in the repo as "not
   a task but is for discussion and/or note taking". These stay open forever
   and grow by comments: running logs of recurring events, collections of
   notes on a topic. Never close one of these.

Match the shape before writing: adding to an open `thread` issue means either
extending the comment that already covers this sub-topic or, for genuinely new
material, posting a fresh one, whereas finishing a task means both a comment
describing what was done and closing the issue.

## Labels

Both repos use a small, deliberate label set, and it is applied loosely — many
issues have no label at all. Check what actually exists before labelling:

```bash
gh label list --repo jasper-tms/reviews
gh label list --repo jasper-tms/records
```

Apply an existing label only when it clearly fits the issue you are creating.
Do **not** invent a new label without asking Jasper first — the sparse label
set is intentional.

## Before posting

Unless Jasper has given you the exact wording he wants, draft the review or
record text and show it to him for approval before posting it. Reviews in
particular are written in his voice and represent his opinions, so he should
sign off on the phrasing.
