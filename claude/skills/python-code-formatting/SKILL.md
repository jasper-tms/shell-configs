---
name: python-code-formatting
description: Load whenever writing or editing Python code file. Not needed for directly invoking python with inline commands.
---

# Skill: Python code formatting
Pay close attention to these rules when you write or edit a Python code file.

## Shebang
For documentation's sake, start every Python file with `#!/usr/bin/env python3`
(even if the file is not meant to be executed directly). Exception: if you're
working in a project that uses uv, see the `using-uv` skill and follow its
instructions for a uv shebang instead.


## Strings
- Use single quotes for all strings by default.
- Use double quoted strings when the string contains an apostrophe in order to
  avoid needing to escape the apostrophe.


## Full example including additional docstring formatting rules
```python
#!/usr/bin/env python3

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
