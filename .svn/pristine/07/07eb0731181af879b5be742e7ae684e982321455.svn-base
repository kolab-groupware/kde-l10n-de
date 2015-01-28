#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Copyright 2014  Burkhard Lück <lueck@hube-lueck.de>

Permission to use, copy, modify, and distribute this software
and its documentation for any purpose and without fee is hereby
granted, provided that the above copyright notice appear in all
copies and that both that the copyright notice and this
permission notice and warranty disclaimer appear in supporting
documentation, and that the name of the author not be used in
advertising or publicity pertaining to distribution of the
software without specific, written prior permission.

The author disclaim all warranties with regard to this
software, including all implied warranties of merchantability
and fitness.  In no event shall the author be liable for any
special, indirect or consequential damages or any damages
whatsoever resulting from loss of use, data or profits, whether
in an action of contract, negligence or other tortious action,
arising out of or in connection with the use or performance of
this software.
"""

import sys, os, glob, re, codecs
import polib

if len(sys.argv) != 5:
  print '\nUsage: python %s path/to/xmlfile path/to/l10ndir/ l10nmodulename pofilename.po' %os.path.basename(sys.argv[0])
else:
  xmlfilepath, xmlfilename, l10ndirpath, l10nmodulename, pofilename = sys.argv[1], sys.argv[1].split("/")[-1], sys.argv[2], sys.argv[3], sys.argv[4]
  begincommenttag = "<comment>"
  endcommenttag = "</comment>"
  begincommentlangtag = '<comment xml:lang='

  xmllines=codecs.open(xmlfilepath,"rb","utf8").readlines()
  xmlwithtranslation = ''
  xmlpofilelist = glob.glob("%s/*/messages/%s/%s" %(l10ndirpath, l10nmodulename, pofilename))

  pofiledict = {}
  if not l10ndirpath.endswith("/"):
    l10ndirpath+="/"
  for pofile in xmlpofilelist:
    langcode = pofile.split(l10ndirpath)[1].split("/")[0]
    if langcode != "x-test":
      po = polib.pofile(pofile)
      pofiledict[langcode] = po
  for line in xmllines:
    if begincommenttag in line:
      indentwidth = line.split(begincommenttag)[0]
      xmlwithtranslation += line
      msgid=line.split(begincommenttag)[1].split(endcommenttag)[0]
      for lang, po in sorted(pofiledict.iteritems()):
        msgstr = ''
        for entry in pofiledict[lang].translated_entries():
          if entry.msgid == msgid:
            msgstr = entry.msgstr
            break
        if msgstr != '':
          transline = '%s%s"%s">%s%s\n' %(indentwidth, begincommentlangtag, lang, msgstr, endcommenttag)
          xmlwithtranslation += transline
    elif begincommentlangtag in line:
      pass
    else:
      xmlwithtranslation += line
      
  modifiedxml = codecs.open("%s" %xmlfilepath,"w","utf8")
  modifiedxml.write(xmlwithtranslation)
  modifiedxml.close()
