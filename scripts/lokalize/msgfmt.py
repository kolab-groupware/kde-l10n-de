# -*- coding: utf-8 -*-
import os,sys
import Editor
import Project

def doCompile():
    if not Editor.isValid() or Editor.currentFile=='': return
    lang=Project.targetLangCode()

    (path, pofilename)=os.path.split(Editor.currentFile())
    (package, ext)=os.path.splitext(pofilename)
    if os.system('touch `kde4-config --localprefix`/share/locale/%s/LC_MESSAGES' % lang)!=0:
        os.system('mkdir `kde4-config --localprefix`/share')
        os.system('mkdir `kde4-config --localprefix`/share/locale')
        os.system('mkdir `kde4-config --localprefix`/share/locale/%s'  % lang)
        os.system('mkdir `kde4-config --localprefix`/share/locale/%s/LC_MESSAGES'  % lang)

    os.system('msgfmt -o `kde4-config --localprefix`/share/locale/%s/LC_MESSAGES/%s.mo %s' % (lang, package, Editor.currentFile()))

doCompile()
