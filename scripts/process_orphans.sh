#! /usr/bin/env bash

# This script automatizes the moving and deleting of translations with
# the help of the rule file process_orphans.txt

rules_file="./scripts/process_orphans.txt"
if test -n "$KDE_PROCESS_ORPHAN_RULES"; then 
  echo "Using $KDE_PROCESS_ORPHAN_RULES as rule file."
  rules_file="$KDE_PROCESS_ORPHAN_RULES"
fi

if test ! -s "$rules_file"; then
    echo "ERROR: could not find the process_orphans.txt rule file! Aborting!"
    exit 1
fi

# Script is not tested, so force verbose mode:
VERBOSE=yes

if test -f ./inst-apps; then
    subdirs=`cat ./inst-apps`
else
    subdirs=`cat ./subdirs`
fi

cat "$rules_file" | while read line; do
    # echo "DEBUG: $line"
    if test -z "$line"; then
        continue # empty line
    elif test `echo "$line"|cut -b1 -` = "#"; then
        continue # comment
    fi
    command=`echo "$line"|cut -d" " -f1 -`
    orig=`echo "$line"|cut -d" " -f2 -`
    if test -f ./templates/${orig}t -a $command != "copy" -a $command != "mergekeep"; then
        echo "ERROR: there is a rule for $orig but there is still a template! Skipping!"
        continue
    elif test ! -d `dirname ./templates/$orig`; then
        ### TODO: this could be an old directory or one not in stable. So it should not be skipped
        echo "ERROR: unknown origin directory for path: $orig Skipping!"
        continue
    fi
    # Careful: $dest is not valid if the $command is "delete"
    dest=`echo "$line"|cut -d" " -f3 -`
    test -z "$VERBOSE" || echo "Processing rule: $command $orig $dest"
    if test -z "$command"; then
        echo "ERROR: rule without command. Skipping!"
        continue
    elif test "$command" != "delete" -a "$command" != "merge" -a ! -d `dirname ./templates/$dest`; then
        echo "ERROR: unknown destination directory for path: $dest Skipping!"
        continue
    fi
    for lang in $subdirs; do
        poorig=./$lang/$orig
        podest=./$lang/$dest
        podestdir=`dirname $podest`

        # Does the rule need to be done manually?
        manual=
        if test -f $poorig; then
            test -z "$VERBOSE" || echo "Checking $poorig..."
            if test -f $poorig -a ! -s $poorig; then
                test -z "$VERBOSE" || echo "$poorig is an empty file. Removing."
                svn remove $poorig
            elif test $command = "delete"; then
                test -z "$VERBOSE" || echo "$poorig matches a delete rule. Removing."
                svn remove $poorig
            elif test $command = "move" -a ! -e $podest; then
                test -z "$VERBOSE" || echo "$poorig matches a move rule and $podest does not exist. Moving."
                if test ! -d $podestdir; then
                    svn mkdir $podestdir
                fi
                svn move $poorig $podest
            elif test $command = "copy" -a ! -e $podest; then
                test -z "$VERBOSE" || echo "$poorig matches a copy rule and $podest does not exist. Copying."
                if test ! -d $podestdir; then
                    svn mkdir $podestdir
                fi
                svn copy $poorig $podest
            elif test $command = "move" -a -f $podest; then
                if test -n "`LC_ALL=C msgfmt -o /dev/null --statistic $poorig 2>&1 |egrep "^0 translated messages"`"; then
                    test -z "$VERBOSE" || echo "$poorig matches a move rule and is untranslated. Removing."
                    svn remove $poorig
                else
                    msgfmtnew="`LC_ALL=C msgfmt -o /dev/null --statistic $podest 2>&1`"
                    if test -n "`echo "$msgfmtnew"|fgrep -v "fuzzy"|fgrep -v "untranslated"`"; then
                        test -z "$VERBOSE" || echo "$poorig matches a move rule and $podest is fully translated. Removing $poorig."
                        svn remove $poorig
                    elif test -n "`echo "$msgfmtnew"|egrep "^0 translated messages"`"; then
                        test -z "$VERBOSE" || echo "$poorig matches a move rule and $podest is untranslated. Moving."
                        # As svn cannot do a remove followed by a move/cop, we have to do it with mv(1)
                        mv $poorig $podest && svn remove $poorig
                    else
                        manual=yes
                    fi
                fi
            elif test $command = "copy" -a -f $podest; then
                if test -n "`LC_ALL=C msgfmt -o /dev/null --statistic $poorig 2>&1 |egrep "^0 translated messages"`"; then
                    test -z "$VERBOSE" || echo "$poorig matches a copy rule and is untranslated. Doing nothing."
                else
                    msgfmtnew=`LC_ALL=C msgfmt -o /dev/null --statistic $podest 2>&1`
                    if test -n "`echo "$msgfmtnew"|fgrep -v "fuzzy"|fgrep -v "untranslated"`"; then
                        test -z "$VERBOSE" || echo "$poorig matches a copy rule and $podest is fully translated. Doing nothing."
                    elif test -n "`echo "$msgfmtnew"|egrep "^0 translated messages"`"; then
                        test -z "$VERBOSE" || echo "$poorig matches a copy rule and $podest is untranslated. Copying."
                        # As svn cannot do a remove followed by a copy, we have to do it with cp(1)
                        cp $poorig $podest
                    else
                        manual=yes
                    fi
                fi
            elif test $command = "merge" -a -f $poorig; then
                # without dest it's a move
                potfile="templates/$dest"t
                if ! test -f "$podest"; then
                    svn mv --parents $poorig $podest
                    msgmerge --previous -o $podest $podest $potfile
                else
                    msgmerge --previous -C $poorig -o $podest $podest $potfile && svn remove $poorig
                fi
            elif test $command = "mergekeep" -a -f $poorig; then
                potfile="templates/$dest"t
                if ! test -f "$podest"; then
                    msgmerge --previous -o $podest $poorig $potfile
                else
                    msgmerge --previous -C $poorig -o $podest $podest $potfile
                fi
            else
                manual=yes
            fi

            if test -n "$manual"; then
                echo "Warning: $command rule for file $poorig cannot be applied automatically. Skipping."
            fi
        fi
    done
done
