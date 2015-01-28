#!/usr/bin/env python
# -*- coding: UTF-8 -*-

# Documentation docbooks may state which PO catalogs contain the user-interface
# labels (those used in <guilabel>, <guibutton>, etc.)
# This information is encoded as a comment, starting with ui-catalogs: keyword,
# followed by whitespace-separated list of UI catalogs:
#
#   <!-- ui-catalogs: catalog1 catalog2 ... -->
#
# The UI catalogs are given only by name, without any path or .po extension.
# Catalogs should be ordered by decreasing priority, same as that for the
# application which is being documented.
#
# The scripts takes docbook file names, parses each for these references,
# and writes to standard output the union of all found catalog names as
# whitespace separated list. The list is ordered by the appearance order
# of catalog names during parsing.

import sys
import xml.parsers.expat

# Union of extracted catalog names.
catnames = []

# Comment handler.
def handler_comment (data):
    p = data.find(":")
    if p >= 0 and data[:p].strip().lower() == "ui-catalogs":
        for cname in data[p+1:].split():
            if cname not in catnames:
                catnames.append(cname)

# Prepare XML parser.
p = xml.parsers.expat.ParserCreate()
p.UseForeignDTD() # not to barf on non-default XML entities
p.CommentHandler = handler_comment

# Go through all docbooks collecting catalog references.
for fname in sys.argv[1:]:
    try:
        file = open(fname, "r")
        p.ParseFile(file)
        file.close()
    except xml.parsers.expat.ExpatError, inst:
        print >>sys.stderr,  "%s: parse error: %s" % (fname, inst)

# Output collected catalogs.
print " ".join(catnames)
