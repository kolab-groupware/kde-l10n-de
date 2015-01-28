# -*- coding: utf-8 -*-
import os
import time
try: import dbus
except: print "please, install python-dbus package"

# see l10n-kde4/nn for usage example

class MultiTarget:
    def __init__(self,lokalize,thisProject,syncProject):
        self.lokalize=lokalize
        self.thisProject=thisProject
        self.syncProject=syncProject
        self.thisProjectPath=self.lokalize.currentProject()
        self.syncProjectPath=self.thisProjectPath.replace(thisProject,syncProject)

        thisInstance=self.lokalize.dbusName()
        self.bus = dbus.SessionBus()        
        lokalize_dbus_instances=lambda:filter(lambda name: name.startswith('org.kde.lokalize') and name!=thisInstance,self.bus.list_names())

        self.syncInstanceName=''
        for name in lokalize_dbus_instances():
            lmw_project_path_method=self.bus.get_object(name,'/ThisIsWhatYouWant').get_dbus_method('currentProject','org.kde.Lokalize.MainWindow')
            thatProjectPath=lmw_project_path_method()
            if thatProjectPath==self.syncProjectPath:
                self.syncInstanceName=name

        if self.syncInstanceName=='':
            os.system('lokalize --project '+self.syncProjectPath+' &')

            for counter in range(10):
                time.sleep(1)
                for name in lokalize_dbus_instances():
                    print 'querying2 '+name+'...'
                    thatProjectPathMethod=self.bus.get_object(name,'/ThisIsWhatYouWant').get_dbus_method('currentProject','org.kde.Lokalize.MainWindow')
                    thatProjectPath=thatProjectPathMethod()
                    if thatProjectPath==self.syncProjectPath:
                        self.syncInstanceName=name
                print 'next iteration'
                if self.syncInstanceName!='': break

        self.syncLMW=self.bus.get_object(self.syncInstanceName,'/ThisIsWhatYouWant')

        self.editors=[]
        self.addEditor()

    def editorActivated(self):
        #print "editorActivated"
        editor=self.lokalize.activeEditor()
        if not editor in self.editors:
            self.addEditor()
        self.reflectEntryDisplay()


    def reflectEntryDisplay(self):
        #print "reflectEntry"
        editor=self.lokalize.activeEditor()
        if editor and editor.currentFile()=='': return
        thatOpenFileInEditorMethod=self.syncLMW.get_dbus_method('openFileInEditor','org.kde.Lokalize.MainWindow')
        thatOpenFileInEditorMethod(editor.currentFile().replace(self.thisProject,self.syncProject))

        editorIndexForFileMethod=self.syncLMW.get_dbus_method('editorIndexForFile','org.kde.Lokalize.MainWindow')
        num=editorIndexForFileMethod(editor.currentFile().replace(self.thisProject,self.syncProject))
        if num==-1: return
        syncE=self.bus.get_object(self.syncInstanceName,'/ThisIsWhatYouWant/Editor/%d' % num)
        thatGotoEntryMethod=syncE.get_dbus_method('gotoEntry','org.kde.Lokalize.Editor')
        thatGotoEntryMethod(editor.currentEntry())

    def reflectFileClose(self,path):
        editorIndexForFileMethod=self.syncLMW.get_dbus_method('editorIndexForFile','org.kde.Lokalize.MainWindow')
        num=editorIndexForFileMethod(path.replace(self.thisProject,self.syncProject))
        if num==-1: return
        syncE=self.bus.get_object(self.syncInstanceName,'/ThisIsWhatYouWant/Editor/%d' % num)
        closeMethod=syncE.get_dbus_method('close','org.kde.Lokalize.Editor')
        closeMethod()

    def addEditor(self):
        print "addEditor"
        editor=self.lokalize.activeEditor()
        if not editor: return
        editor.connect("entryDisplayed()",self.reflectEntryDisplay)
        editor.connect("fileOpened()",self.reflectEntryDisplay)
        editor.connect("fileClosed(QString)",self.reflectFileClose)
        self.editors.append(editor)
        self.reflectEntryDisplay()


# TODO if file doesnt exist in uk...

