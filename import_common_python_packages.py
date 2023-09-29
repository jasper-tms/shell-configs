#!/usr/bin/env python3

# To run this automatically whenever you start an ipython session,
# make a link to this file in ~/.ipython/profile_default/startup/, e.g.
#   cd ~/.ipython/profile_default/startup/
#   ln -s ~/repos/jasper-tms/shell-configs/import_common_python_packages.py

import sys
import os
import json

from datetime import datetime, timezone
now = datetime.now(timezone.utc)

#try: from importlib import reload
#except: pass

try:
    import numpy as np
    np.set_printoptions(suppress=True)
except: pass

try: import pandas as pd
except: pass

try: import npimage
except: pass
