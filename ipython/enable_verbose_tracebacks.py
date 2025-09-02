#!/usr/bin/env python3
"""
Enable verbose tracebacks in IPython.

Verbose tracebacks print the value of each variable relevant to an error,
including their types and values, which can be very helpful for debugging.

Example of each xmode setting, which determines the verbosity of tracebacks:
>>> In [1]: x = [1, 2, 3]

>>> In [2]: xmode
>>> Exception reporting mode: Minimal
>>> In [3]: x[5]
>>> IndexError: list index out of range


>>> In [4]: xmode
>>> Exception reporting mode: Docs
>>> In [5]: x[5]
>>> Traceback (most recent call last): Cell In[5], line 1
>>> ->  x[5]
>>> IndexError: list index out of range

>>> In [6]: xmode
>>> Exception reporting mode: Plain
>>> In [7]: x[5]
>>> Traceback (most recent call last):
>>>   Cell In[7], line 1
>>>     x[5]
>>> IndexError: list index out of range

>>> In [8]: xmode
>>> Exception reporting mode: Context
>>> In [9]: x[5]
>>> ---------------------------------------------------------------------------
>>> IndexError                                Traceback (most recent call last)
>>> Cell In[9], line 1
>>> ----> 1 x[5]
>>> IndexError: list index out of range

>>> In [10]: xmode
>>> Exception reporting mode: Verbose
>>> In [11]: x[5]
>>> ---------------------------------------------------------------------------
>>> IndexError                                Traceback (most recent call last)
>>> Cell In[11], line 1
>>> ----> 1 x[5]
>>>         x = [1, 2, 3]
>>> IndexError: list index out of range

To have this run automatically whenever you start an ipython session,
make a link to this file in ~/.ipython/profile_default/startup/, e.g.

    ln -s ~/repos/jasper-tms/shell-configs/ipython/enable_verbose_tracebacks.py \
        ~/.ipython/profile_default/startup/10-enable_verbose_tracebacks.py

(The number at the start of the link name determines the order that startup
files are run, so you can use that to control the order if needed.)
"""
get_ipython().run_line_magic('xmode', 'verbose')
