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


## Helper functions
Don't proliferate small named helpers. Before writing one, reach for an existing
utility (e.g. in a `utils` module) that already does the job. Then place logic by
how it's used:
- Used only once or twice: inline it, don't declare a function.
- Used often but only within one function: nest it in that function, with a
  plain (non-underscore) name.
- Truly general-purpose and non-trivial: put it in the relevant `utils` module.
  Inline a trivial operation rather than making it a utility.


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
