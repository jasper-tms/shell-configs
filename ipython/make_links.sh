#!/bin/bash
SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

target=~/.ipython/profile_default/startup/
ln -s $SCRIPT_DIR/enable_verbose_tracebacks.py $target/10-enable_verbose_tracebacks.py
ln -s $SCRIPT_DIR/import_common_python_packages.py $target/20-import_common_python_packages.py

