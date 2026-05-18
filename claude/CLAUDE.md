- Start new conversations by greeting me with "Hi Jasper!" before then continuing with your response
- Ask me clarifying questions frequently, whenever there is any uncertainty about the goals of the task
- Start all python files with `#!/usr/bin/env python3` even if the file is not intended to be executed as a script
- Format python functions, docstrings, and strings as follows:
```python
def function(arg: Literal['x', 'y'],
             next_arg: Union[int, str]) -> None:
    """
    We generally follow the numpy style guide, except:

    Docstrings start on the line following the triple double quotes, not
    continuing on the same line.

    When a docstring refers to a variable like `arg` or a function like
    `module.other_function()`, use single backticks (not double backticks).

    Parameters
    ----------
    arg : 'x' or 'y'
        Description of the argument. Note the single quotes for literal values.

    Returns
    -------
    None
    """
    print('In code, use single quotes for all strings, like this.')
    hello_arg = 'Hello ' + arg
    print("But if there's an apostrophe in the string, use double quotes to avoid escaping")
    return
```
- All image and video file handling in python should be done through our package npimage (github.com/jasper-tms/npimage, cloned at ~/repos/jasper-tms/npimage, pypi name "numpyimage"): npimage.load and npimage.save for image I/O, npimage.load_video for loading full videos into memory, npimage.lazy_load_video for a generator yielding frames in order, `with npimage.VideoStreamer(args) as stream: frame = stream[frame_idx]` for lazily loaded random frame access, and npimage.save_video for saving full video files already in memory or `with npimage.VideoWriter(args) as writer: writer.write(array)` for frame-by-frame writing. Do not use opencv or pillow directly when writing new code.
- After we've finished a task together and the updated behavior is confirmed to be correct (either I tell you it is or you verify it yourself), create a script `git_commit_{yymmdd}{ABC...}_{one-or-two-word-description}.sh` (e.g. `git_commit_260130A_button_behavior.sh`) in the root of each repository we've worked on that lists `git add` commands for the relevant files and a `git commit -m "commit message"` command with a commit message that describes the added changes. If there are uncommitted changes unrelated to our task but in the same file(s) that we worked on, warn me about this and proceed with care so that we don't accidentally stage unrelated changes - put a `git apply --cached` command in the commit script to stage simple changes, otherwise ask the user to `git add -p` the mixed file themselves. Commit message must be under 73 characters and start with a verb. Only add an extended (multi-line) commit message concisely describing key changes for above average complexity commits, so ~50% of the time. `chmod +x` the file so I can run it. If an "A" script already exists for that day, use "B" in the filename, and so on. If I ask you for further changes before I commit, update the same script as needed. End the script with `rm -- "$0"` (after `set -e` at the top) so it deletes itself on a successful commit and doesn't linger to confuse future sessions.
