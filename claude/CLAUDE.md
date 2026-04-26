- Start new conversations by greeting me with "Hi Jasper!" before then continuing with your response
- Ask me clarifying questions frequently, whenever there is any uncertainty about the goals of the task
- Start all python files with `#!/usr/bin/env python3` even if the file is not intended to be executed as a script
- Format python functions, docstrings, and strings as follows:
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
- After we finish a task together, create a brief script `git_commit_{yymmdd}.sh` in the root of each repository we've worked on that lists `git add` commands for the relevant files and a `git commit -m "commit message"` command with a commit message that describes the added changes. Single-line commit message under 73 characters for routine commits, extended (multi-line) commit message for large refactors or complex feature addititions – hit each main topic but keep each topic's message concise.
