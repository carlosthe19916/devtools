#!/bin/bash

# Unpack the PyCharm debugger egg so pydevd's native attach_*.so files exist as
# real files on disk (a zipped .egg on sys.path fails to load them).
if [ -f /tmp/pydevd-pycharm.egg ]; then
    rm -rf /opt/pydevd
    python3 -c "import zipfile; zipfile.ZipFile('/opt/pydevd-pycharm.egg').extractall('/opt/pydevd')"
    echo "pydevd egg unpacked to /opt/pydevd"
fi