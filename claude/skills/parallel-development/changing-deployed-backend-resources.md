# Changing deployed backend resources

Some things a branch changes are live for everyone once deployed, such as
database security rules or cloud functions: every online and local deployment
of every branch uses the one deployed copy. If testing a feature branch means
deploying such a resource, first check whether any other worktree has changed
it, committed or not:

```bash
git worktree list
git diff --stat <source-branch>...<other-branch> -- <resource paths>   # its commits
git -C <other-worktree> status --short -- <resource paths>             # uncommitted
```

(The three dots compare with where the branch left the source branch. A plain
`diff <source-branch>` would also show every change made to the source branch
since, which looks like a conflict but isn't one.)

If one has, don't deploy over it: coordinate with the agent working there, or
discuss it with the user, so that branches don't keep replacing each other's
deployed version without anyone noticing.
