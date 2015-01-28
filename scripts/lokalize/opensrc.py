# -*- coding: utf-8 -*-
import os,sys
import Editor
import Lokalize
from opensrc_list import mapSrc

print Editor.currentFile()
editor=Editor
globals()['test']='sssss'
lll=['sss']

ourPath=([p for p in sys.path if p.endswith('/scripts/lokalize')]+[''])[0]

def srcFileOpenRequested(filename, line):
    try: Editor.setSrcFileOpenRequestAccepted(True)
    except: print 'your lokalize needs update ;)'

    if not editor.isValid() or editor.currentFile()=='': return

    import Kross
    forms = Kross.module("forms")
    print filename
    print globals()['test']
    print lll


    (path, pofilename)=os.path.split(Editor.currentFile())
    (package, ext)=os.path.splitext(pofilename)
    (upperPath, module)=os.path.split(path)
    if module.startswith('extragear-'):
        module=module.replace('extragear-','../extragear/')
    elif module.startswith('playground-'):
        module=module.replace('playground-','../playground/')
    elif module=='kdebase':
        trySubmodules=['workspace','apps','runtime']
        for s in trySubmodules:
            if os.path.exists(ourPath+'/../../../KDE/kdebase/'+s+'/'+package):
                module=module+'/'+s
                print module
                break
    if package.startswith('desktop_'):
        while 1:
            try: package=package[package.index('_')+1:]
            except: break
    KdeTrunkPath=os.path.normpath(ourPath+'/../../../')
    mapSrcSuggest = mapSrc.get(package, '---')
    tryList=[KdeTrunkPath+'/'+mapSrcSuggest+'/'+filename,
                mapSrcSuggest+'/'+filename, # for suggestions providing full path
                KdeTrunkPath+'/KDE/'+module+'/'+package+'/'+filename,
                KdeTrunkPath+'/KDE/'+module+'/'+package+'/src/'+filename,
                KdeTrunkPath+'/KDE/'+module+'/'+package+'/'+package+'/'+filename,
                path+'/'+filename]

    for i in range(len(tryList)): tryList[i]=os.path.normpath(tryList[i])

    srcFilePath=(filter(lambda p:os.path.exists(p),tryList)+[''])[0]
    if len(srcFilePath)==0:
        progress = forms.showProgressDialog("Searching source file on disk",'Searching source file on disk...')
        progress.setRange(0,2)

        import subprocess

        print 'using locate...'
        progress.addText("  ...using 'locate' commandline tool")
        progress.setValue(0)
        progress.setValue(1)
        process = subprocess.Popen(['locate', KdeTrunkPath+'/*/'+filename], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        srcFilePath = process.stdout.readline()
        try: srcFilePath=srcFilePath[:-1]
        except: print "nothing found by 'locate'"
        try:process.terminate()
        except: print 'seems like the old python version ;)'

        if not len(srcFilePath) or not os.path.exists(srcFilePath):
            progress.addText("  ...using 'find' commandline tool")
            progress.setValue(2)

            print 'using find...'
            process = subprocess.Popen(['find', KdeTrunkPath+'/KDE/'+module, '-path', filename, '-type','f'], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            srcFilePath = process.stdout.readline()
            try: srcFilePath=srcFilePath[:-1]
            except: print "nothing found by 'find'"
            try:process.terminate()
            except: print 'seems like the old python version ;)'
        progress.deleteLater()
    if len(srcFilePath):
        os.system('kate -u '+srcFilePath+(' --line %d &' % line))
        print 'kate -u '+srcFilePath+(' --line %d &' % line)
    else:
        print "couldn't find. searched in:",
        print tryList
        answer=forms.showMessageBox("QuestionYesNo", "Could not find source file", "Searched in:\n"+'\n'.join(tryList)+"""
Also searched using 'locate' command.

Would you like to initiate websearch (using lxr.kde.org)?
        """)
        if answer=='Yes':
            os.system("kfmclient openURL 'http://lxr.kde.org/search?filestring=%s&string='" % filename)

