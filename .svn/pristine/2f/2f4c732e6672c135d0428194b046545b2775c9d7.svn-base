#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import os
import sys

from pology.catalog import Catalog
from pology.escape import escape_c


if len(sys.argv) != 3:
    print "Usage: %s POFILE PHPFILE" % (os.path.basename(sys.argv[0]))
    exit(1)

popath = sys.argv[1]
phppath = sys.argv[2]

cat = Catalog(popath, monitored=False)

linefmt = '$text["%s"] = "%s";'
lines = []
lines.append("<?php")
for msg in cat:
    if msg.translated and not msg.obsolete:
        line = linefmt % (escape_c(msg.msgid), escape_c(msg.msgstr[0]))
        lines.append(line)
lines.append("?>")
lines.append("\n")

ofh = file(phppath, "w")
ofh.write("\n".join(lines).encode("utf8"))
ofh.close()
