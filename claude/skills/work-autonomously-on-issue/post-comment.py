#!/usr/bin/env python3
"""
Post a comment on a GitHub issue on behalf of the autonomous issue workflow,
then hand the issue off by swapping its workflow labels.

The header and footer are added here, never by the caller, so every post
from the workflow looks the same and carries the hidden session ID marker
that later resumes rely on. Finally, the orchestrator's claim comment for
this session (if any) is deleted.

Agents must also pass the snapshot of the issue thread they saved when they
started working. If the thread changed since (new, edited, or deleted
comments, or an edited title or body), nothing is posted: the changes are
printed and the script exits with code 3, so the agent can decide whether
they affect the work before trying again with a fresh snapshot.

Usage:
    post-comment.py <issue-url> --save-snapshot <snapshot-file>
    post-comment.py <issue-url> <message-file> --snapshot <snapshot-file>
        [--author agent|orchestrator] [--final-label <label>|none]
        [--session-id <uuid>]

`--final-label none` removes every workflow label, for the final comment on
a closed issue.

The session ID defaults to $AUTONOMOUS_ISSUE_SESSION_ID and the device name
to $AUTONOMOUS_ISSUE_DEVICE_NAME, both set by the orchestrator when it
launches a session.
"""
import argparse
import json
import os
import re
import socket
import subprocess
import sys
from pathlib import Path

WORKFLOW_LABELS = ['claude', 'claude-working', 'ready-for-review',
                   'claude-failed']
HEADERS = {
    'agent': 'A claude agent running on `{device}` worked on this for you and '
             'says:',
    'orchestrator': 'The claude orchestrator running on `{device}` says:',
}
THREAD_CHANGED_EXIT_CODE = 3


def gh(*args: str, input: str | None = None) -> str:
    return subprocess.run(['gh', *args], input=input, capture_output=True,
                          text=True, check=True).stdout


def fetch_thread(repository: str, number: str) -> dict:
    """
    Return the issue's title, body, and comments keyed by comment ID. Claim
    comments are left out, since orchestrators add and remove them.
    """
    issue = json.loads(gh('api', f'repos/{repository}/issues/{number}'))
    comment_lines = gh(
        'api', f'repos/{repository}/issues/{number}/comments', '--paginate',
        '--jq', '.[] | select(.body | contains("<!-- claude-claim: ") | not)'
                ' | {id, user: .user.login, author_association, updated_at,'
                ' body} | @json').splitlines()
    comments = {str(comment['id']): comment
                for comment in map(json.loads, comment_lines)}
    return {'title': issue['title'], 'body': issue['body'] or '',
            'comments': comments}


def describe_changes(old: dict, new: dict) -> list[str]:
    changes = []
    for field in ['title', 'body']:
        if old[field] != new[field]:
            changes.append(f'The issue {field} was edited. It now reads:\n'
                           f'{new[field]}')
    for comment_id, comment in new['comments'].items():
        previous = old['comments'].get(comment_id)
        if previous is None:
            kind = 'New comment'
        elif previous['updated_at'] != comment['updated_at']:
            kind = 'Edited comment'
        else:
            continue
        changes.append(f'{kind} {comment_id} by {comment["user"]} '
                       f'({comment["author_association"]}):\n'
                       f'{comment["body"]}')
    for comment_id, comment in old['comments'].items():
        if comment_id not in new['comments']:
            changes.append(f'Comment {comment_id} by {comment["user"]} was '
                           'deleted.')
    return changes


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    parser.add_argument('issue_url')
    parser.add_argument('message_file', type=Path, nargs='?')
    parser.add_argument('--save-snapshot', type=Path)
    parser.add_argument('--snapshot', type=Path)
    parser.add_argument('--author', choices=HEADERS, default='agent')
    parser.add_argument('--final-label', default='ready-for-review',
                        choices=[*WORKFLOW_LABELS, 'none'])
    parser.add_argument('--session-id',
                        default=os.environ.get('AUTONOMOUS_ISSUE_SESSION_ID'))
    arguments = parser.parse_args()

    match = re.fullmatch(r'https://github\.com/([^/]+/[^/]+)/issues/(\d+)/?',
                         arguments.issue_url)
    if not match:
        sys.exit(f'Not a GitHub issue URL: {arguments.issue_url}')
    repository, number = match.groups()

    if arguments.save_snapshot:
        arguments.save_snapshot.write_text(
            json.dumps(fetch_thread(repository, number), indent=2) + '\n')
        print(f'Saved a snapshot of the issue thread to '
              f'{arguments.save_snapshot}')
        return

    if arguments.message_file is None:
        parser.error('a message file is required unless --save-snapshot is '
                     'given')
    if not arguments.session_id:
        sys.exit('No session ID: pass --session-id or set '
                 'AUTONOMOUS_ISSUE_SESSION_ID')
    if arguments.author == 'agent' and not arguments.snapshot:
        sys.exit('Agents must pass --snapshot with the snapshot saved (with '
                 '--save-snapshot) when they started working')
    if arguments.snapshot:
        changes = describe_changes(
            json.loads(arguments.snapshot.read_text()),
            fetch_thread(repository, number))
        if changes:
            print('Nothing was posted: the issue thread changed since the '
                  'snapshot was saved.\n')
            print('\n\n'.join(changes))
            print('\nIf any of this affects the task, save a fresh snapshot, '
                  'address it, and try again. Otherwise save a fresh snapshot '
                  'and post again.')
            sys.exit(THREAD_CHANGED_EXIT_CODE)

    device = (os.environ.get('AUTONOMOUS_ISSUE_DEVICE_NAME')
              or socket.gethostname().split('.')[0].lower())
    message = arguments.message_file.read_text().strip()
    # The blank line before `---` keeps Markdown from turning the header
    # into a heading instead of drawing a horizontal rule.
    body = (f'{HEADERS[arguments.author].format(device=device)}\n\n'
            f'---\n'
            f'{message}\n\n'
            f'<!-- claude-session-id: {arguments.session_id} -->\n'
            f'<!-- Written by Claude as part of the autonomous issue '
            f'workflow, posted without human review -->\n')
    comment_url = gh('issue', 'comment', number, '--repo', repository,
                     '--body-file', '-', input=body).strip()

    label_arguments = []
    for label in WORKFLOW_LABELS:
        if label != arguments.final_label:
            label_arguments += ['--remove-label', label]
    if arguments.final_label != 'none':
        label_arguments += ['--add-label', arguments.final_label]
    gh('issue', 'edit', number, '--repo', repository, *label_arguments)

    # Remove the claim comment the orchestrator posted for this session
    # when it started (see `claim_issue()` in the orchestrator's poll.py).
    claim_marker = f'<!-- claude-claim: {arguments.session_id} -->'
    claim_ids = gh('api', f'repos/{repository}/issues/{number}/comments',
                   '--paginate', '--jq',
                   f'.[] | select(.body | contains("{claim_marker}")) '
                   f'| .id').split()
    for claim_id in claim_ids:
        gh('api', '--method', 'DELETE',
           f'repos/{repository}/issues/comments/{claim_id}')
    print(comment_url)


if __name__ == '__main__':
    main()
