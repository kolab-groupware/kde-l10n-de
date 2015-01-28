#!/bin/bash
# Author: Albert Astals Cid <aacid@kde.org>
# License: WTFPL 2 - http://sam.zoy.org/wtfpl/

function git_download
{
	if [ -z "$3" ]; then
		oldmd5=$4
		newmd5=`mktemp`
	fi
	timeout 1h git archive --remote=$1 $2 | tar -x
	res=$?
	if [ -z "$3" ]; then
		md5deep -rl . > $newmd5
		if [ -n "$oldmd5" ]; then
			differences=`diff -ub $oldmd5 $newmd5 | grep ^[+-] | grep -v ^+++ | grep -v ^--- | cut -d " " -f 3 | uniq`
		else
			differences=`ls`
		fi
		if [ -z "$differences" ]; then
			echo "No differences"
		else
			echo "New/changed/removed files:"
			echo $differences
		fi
		rm -f $oldmd5 $newmd5
	fi
	return $res
}

if [ ! -d scripts ]; then
	echo "You have to run the script from the parent directory of scripts/"
	exit
fi

mkdir -p documentation
cd documentation

ignorenonemptylines=0
lastmodule=""
lastlineempty=1
onlyonemodule=""
sawroot=0
sawentry=0
lastupdate=0

silentflag=""
if test "$1" = "--silent"; then
	silentflag="-q"
	shift
fi

if [ -n "$1" ]; then
	onlyonemodule=$1
fi

while read line; do
	if [ -z "$line" ]; then
		lastlineempty=1
		lastmodule=""
		ignorenonemptylines=0
	else
		if [[ $line = \#* ]]; then
			continue
		fi
		
		if [ $ignorenonemptylines -eq 1 ]; then
			continue
		fi
		
		IFS=' ' read -ra tokens <<< $line
		ntokens=${#tokens[@]}
		if [ $lastlineempty -eq 1 ]; then
			lastlineempty=0	
			if [ $ntokens -eq 2 ]; then
				if [ "${tokens[0]}" = "module" ]; then
					if [ -n "$onlyonemodule" ]; then
						if [ "$onlyonemodule" != "${tokens[1]}" ]; then
							ignorenonemptylines=1
							continue
						fi
					fi
					
					mkdir -p ${tokens[1]}
					lastmodule=${tokens[1]}
					sawroot=0
					sawentry=0
				else
					echo "The first token after a empty line has to be module - $line"
				fi
			else
				echo "The number of tokens after a empty line has to be 2 - $line"
			fi
		else
			if [ -z "$lastmodule" ]; then
				echo "Last module is empty, error when processing $line"
			else
				if [ $ntokens -lt 2 ]; then
					echo "The number of tokens is not valid - $line"
				else
					if [ "${tokens[0]}" = "root" ]; then
						if [ $sawroot -eq 0 ]; then
							if [ $sawentry -eq 0 ]; then
								if [[ ${tokens[1]} = svn://* ]]; then
									if [ $ntokens -eq 2 ]; then
										if [ -z "$silentflag" ]; then
											echo "Updating $lastmodule root documentation"
										fi
										svn $silentflag co ${tokens[1]} $lastmodule
										lastupdate=$?
										sawroot=1
									else
										echo "Wrong number of tokens for a root svn line - $line"
									fi
								elif [[ ${tokens[1]} = git://* ]]; then
									if [ $ntokens -eq 3 ]; then
										if [ -z "$silentflag" ]; then
											echo "Updating $lastmodule root documentation"
										fi
										oldmd5=""
										if [ -d $lastmodule ]; then
											if [ -z "$silentflag" ]; then
												oldmd5=`mktemp`
												cd $lastmodule
												md5deep -rl . > $oldmd5
												cd ..
											fi
											rm -rf $lastmodule/*
										fi
										cd $lastmodule
										git_download ${tokens[1]} ${tokens[2]} "$silentflag" $oldmd5
										lastupdate=$?
										cd ..
										sawroot=1
									else
										echo "Wrong number of tokens for a root git line - $line"
									fi
								else
									echo "Unknown scm download line - $line"
								fi
							else
								echo "$lastmodule has entry lines before the root line, that is not supported - $line"
							fi
						else
							echo "$lastmodule has more than one root lines, that is not supported - $line"
						fi
					elif [ "${tokens[0]}" = "entry" ]; then
						if [ $ntokens -lt 3 ]; then
							echo "The number of tokens is not valid - $line"
						else
							if [[ ${tokens[2]} = svn://* ]]; then
								if [ $ntokens -eq 3 ]; then
									if [ -z "$silentflag" ]; then
										echo "Updating $lastmodule/${tokens[1]} documentation"
									fi
								
									cd $lastmodule
									svn $silentflag co ${tokens[2]} ${tokens[1]}
									lastupdate=$?
									cd ..
									sawentry=1
								else
									echo "Wrong number of tokens for a entry svn line - $line"
								fi
							elif [[ ${tokens[2]} = git://* ]]; then
								if [ $ntokens -eq 4 ]; then
									if [ -z "$silentflag" ]; then
										echo "Updating $lastmodule/${tokens[1]} documentation"
									fi
									savepwd=$PWD
									cd $lastmodule
									oldmd5=""
									if [ -d ${tokens[1]} ]; then
										if [ -z "$silentflag" ]; then
											oldmd5=`mktemp`
											(
											cd ${tokens[1]}
											md5deep -rl . > $oldmd5
											)
										fi
										rm -rf ${tokens[1]}
									fi
									mkdir -p ${tokens[1]}
									cd ${tokens[1]}
									git_download ${tokens[2]} ${tokens[3]} "$silentflag" $oldmd5
									lastupdate=$?
									cd $savepwd
									sawentry=1
								else
									echo "Wrong number of tokens for a entry git line - $line"
								fi
							else
								echo "Unknown scm download line - $line"
							fi
						fi
					else
						echo "Invalid line - $line"
					fi
				fi
			fi
		fi
	fi
	if [ "x$lastupdate" != "x0" ]; then
		echo "There was an error updating the sources"
		exit 1
	fi
done < "../scripts/documentation_paths"

cd ..

