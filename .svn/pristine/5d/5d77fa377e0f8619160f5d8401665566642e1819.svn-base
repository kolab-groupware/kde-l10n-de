#!/bin/bash
# License: GNU LGPL 2.0+

checkDir()
{
	for lsIt in `ls $2/$1`; do
		if [ -d $2/$1/$lsIt ]; then
			checkDir $1/$lsIt $2
		fi
		if [ -f $2/$1/$lsIt ]; then
			file=$1/$lsIt
			lastThreeLetters=${file:(-3)}
			if [ $lastThreeLetters = .po ]; then
				template="templates/"$file"t"
				if [ -e $template ]; then
					echo exists &> /dev/null
				else
					echo $2/$file is a .po without .pot
				fi
			fi
		fi
	done
}

processLanguage()
{
	if [ -d $1 ]; then
		if [ $verbose -eq 1 ]; then
			echo "Testing files of $1..."
		fi
		if [ -d $1/messages ]; then
			checkDir messages $1
		fi
		if [ -d $1/docmessages ]; then
			checkDir docmessages $1
		fi
	else
		echo $1 does not exist
	fi
}

verbose=1
if test "$1" = "--silent"; then
	verbose=0
	shift
fi

if [ -n "$1" ]; then
	processLanguage $1
else
	for languageIt in `cat subdirs`; do
		processLanguage $languageIt
	done
fi
