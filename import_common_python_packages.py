#!/usr/bin/env python3

# To run this automatically whenever you start an ipython session,
# make a link to this file in ~/.ipython/profile_default/startup/, e.g.
#   cd ~/.ipython/profile_default/startup/
#   ln -s ~/repos/jasper-tms/shell-configs/import_common_python_packages.py

import sys
import os
import json
from importlib import reload
from pathlib import Path

from datetime import datetime, timezone
now = datetime.now(timezone.utc)

try:
    import numpy as np
    np.set_printoptions(suppress=True)
except ImportError:
    pass

try:
    import pandas as pd
    pd.set_option('display.max_rows', 200)
except ImportError:
    pass

try:
    import lazy_import
except ImportError:
    print("INFO: lazy_import not found, so not lazy-importing some packages.")
    lazy_import = None

if lazy_import:
    npimage = lazy_import.lazy_module('npimage')
    plt = lazy_import.lazy_module('matplotlib.pyplot')

env_name = os.environ.get('VIRTUAL_ENV', '').split('/')[-1]
if 'fanc' in env_name:
    import logging
    logging.basicConfig(level=logging.ERROR)
    import fanc
    client = fanc.get_caveclient()
    print('import fanc; client = fanc.get_caveclient()')
if 'the-banc' in env_name:
    import logging
    logging.basicConfig(level=logging.ERROR)
    import banc
    client = banc.get_caveclient()
    print('import banc; client = banc.get_caveclient()')
if 'scape' in env_name:
    if lazy_import:
        scapeio = lazy_import.lazy_module('scapeio')
        scapepp = lazy_import.lazy_module('scapepp')
