#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import xml.dom.minidom
import sys
import subprocess

# i18n_branch_to_process = "trunk";
i18n_branch_to_process = "stable";

def getText(node):
	rc = []
	for n in node.childNodes:
		if n.nodeType == n.TEXT_NODE:
			rc.append(n.data)
	return ''.join(rc)

def getChildNode(node, childNodeTagName, attributeName, attributeValue):
	for child in node.childNodes:
		if child.nodeType == child.ELEMENT_NODE:
			if child.tagName == childNodeTagName:
				if child.getAttribute(attributeName) == attributeValue:
					return child
	return None

def printRepos(nodes):
	for node in nodes:
		printRepo(node, False)
		
def printRepo(node, root):
	repo = getChildNode(node, "repo", "", "")
	if repo != None:
		active = getChildNode(repo, "active", "", "")
		url = getChildNode(repo, "url", "protocol", "ssh")
		activeText = getText(active)
		if getText(url) != "":
			branchNode = getChildNode(repo, "branch", "i18n", i18n_branch_to_process)
			branch = ""
			if (branchNode != None):
				branch = getText(branchNode)
			if (branch == ""):
				if (i18n_branch_to_process == "trunk"):
					branch = "master"
				elif (i18n_branch_to_process == "stable"):
					branch = "none"
			elif activeText == "false" and branch != "none":
				sys.stderr.write("Warning: '%s' is not active but has a defined i18n branch\n" % (getText(url)))
			if activeText == "true":
				if (module_to_parse != ""):
					if (project_to_parse != "kde"):
						moduleName = "%s-%s_%s" % (project_to_parse, module_to_parse, node.getAttribute("identifier"))
					else:
						if (root):
							moduleName = "%s" % (module_to_parse)
						else:
							moduleName = "%s_%s" % (module_to_parse, node.getAttribute("identifier"))
				else:
					if (root):
						moduleName = "%s" % (project_to_parse)
					else:
						moduleName = "%s_%s" % (project_to_parse, node.getAttribute("identifier"))
				get_paths_branch=subprocess.Popen(["bash", "-c", ". %s/get_paths ; get_branch %s" % (path_to_scripts_folder, moduleName)], stdout=subprocess.PIPE).communicate()[0].strip().decode("utf-8")
				if get_paths_branch == "get_branch_none":
					get_paths_branch = "none"
				if (get_paths_branch != branch):
					sys.stderr.write("Warning: '%s' has different branches in get_paths (%s) than in XML file (%s)\n" % (moduleName, get_paths_branch, branch))
				if get_paths_branch != "none":
					print(moduleName)

argc = len(sys.argv)
if (argc < 4 or argc > 5):
	print("Wrong usage, needs path_to_xml_file path_to_scripts_folder project_to_parse [module_to_parse]")
	sys.exit(1)

path_to_xml_file = sys.argv[1]
path_to_scripts_folder = sys.argv[2]
project_to_parse = sys.argv[3]
module_to_parse = ""
if argc == 5:
	module_to_parse = sys.argv[4]

dom = xml.dom.minidom.parse(path_to_xml_file)
root = dom.documentElement
component = getChildNode(root, "component", "identifier", project_to_parse)
projects = None
if component != None:
	if argc == 5:
		module = getChildNode(component, "module", "identifier", module_to_parse)
		if module != None:
		  printRepo(module, True)
		  projects = module.getElementsByTagName("project")
	else:
		printRepo(component, True)
		projects = component.getElementsByTagName("module")

if projects != None:
	printRepos(projects)
