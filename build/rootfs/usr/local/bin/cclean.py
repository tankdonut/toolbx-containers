#!/usr/bin/env python

import os
from pathlib import Path

HOME = os.getenv("HOME", Path("~").expanduser())
