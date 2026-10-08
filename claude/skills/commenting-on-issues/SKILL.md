---
name: commenting-on-issues
description: Load before drafting, posting, or editing a comment on a github issue
---

# Commenting on GitHub issues

Follow these rules whenever you draft, post, or edit a comment on a GitHub
issue.

## Get approval before making a post or edit

Show the user each comment draft (or edit draft) and wait for their approval
before posting, unless the user has already given you standing authority to
post without individual review — for example a workflow, a scheduled agent,
or an explicit statement along the lines of "{post comments / make updates}
{to github / on issues} {without asking / independently}".

## Sign every comment

End every comment with an HTML comment. GitHub does not render it in the
comment view, but anyone who presses Edit sees it in the raw source. Use this
form:

```
<!-- Written by Claude{qualifier} -->
```

Pick the `{qualifier}` that matches how the comment came to be:

- ` as part of {few-word description of the workflow or task that gave you
  the authority to post}, posted without human review` — when no human
  reviewed the exact text before it went up.
- `, approved by {user's name}` — when the user approved the exact draft before
  you posted it.
- `, relaying wording written by {user's name}` — when the human authored the
  substance and you only posted or formatted it.


## Write commit hashes bare

Write commit hashes with no backticks and no other markup, so github.com
turns each one into an automatic link to the commit. Backticked hashes render
as plain code and do not link.

## Report the URL

After you post or edit a comment, give the user the full comment URL,
including the `#issuecomment-{id}` fragment, so they can jump straight to it.
