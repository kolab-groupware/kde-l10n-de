#!/bin/bash

# Script to check out and update the source modules from which
# PO files in templates/messages/ are extracted.
#
# Usage:
#
#   cd $BRANCH/l10n-kde4
#   scripts/populate_source.sh [module_name...]
#
# When the scripts is invoked for the first time without arguments,
# the following file tree will be created in the working directory:
#
#   source/
#       repo/
#       link/
#       modules
#
# The source/repo/ directory contains the repository checkouts,
# arranged in a branch-specific directory organization.
# The source/link/ directory contains the symbolic links to checkouts
# organized in a uniform way corresponding to PO file directories.
# The modules file contains the list of module names, one per line.
#
# When the script is invoked subsequently, it will update existing checkouts,
# create new checkouts, and delete stale checkouts and links.
# If one or more module names are given as arguments,
# only those modules are checked out or updated.
#
# The links in source/link/ are created as follows.
# When the module name is of the form <name>_<subname>, the link is
# source/link/<poname>/<subname> -> ../repo/<name>_<subname>.
# When the module name is just <name>, the link is
# source/link/<poname>/<name> -> ../repo/<name>.
# <poname> and <name> are most of the time the same, but not always.

script=$0
modules="$@"

scriptdir=`dirname $script`
. $scriptdir/get_paths

svnroot=`LC_ALL=C svn info $scriptdir | grep '^Repository Root:' | sed 's/^[^:]*: *//'`
if test -z "$svnroot"; then
    echo "ERROR: Cannot extract Subversion repository root."
    exit 1
fi

svnclean=`which svn-clean-kde || which svn-clean`
if test -z "$svnclean"; then
    echo "ERROR: Cannot find 'svn-clean-kde' or 'svn-clean' command."
    exit 1
fi
if ! which revpath >/dev/null; then
    echo "ERROR: Cannot find 'revpath' command."
    exit 1
fi

sourcedir=source # relative to current working directory
if ! mkdir -p $sourcedir; then
    echo "ERROR: Cannot create directory '$sourcedir'."
    exit 1
fi
repodir=repo # relative to $sourcedir
if ! mkdir -p $sourcedir/$repodir; then
    echo "ERROR: Cannot create directory '$sourcedir/$repodir'."
    exit 1
fi
linkdir=link # relative to $sourcedir
if ! mkdir -p $sourcedir/$linkdir; then
    echo "ERROR: Cannot create directory $sourcedir/$linkdir."
    exit 1
fi

warnfile=module_warnings
: >$warnfile
teelog="tee -a $PWD/$warnfile"

if test -z "$modules"; then
    echo "===== Fetching module list..."
    modules=`list_modules $scriptdir`
    if test $? != 0 || test -z "$modules"; then
        echo "ERROR: Cannot list modules."
        exit 1
    fi

    # Special modules, not recorded in list on projects.kde.org.
    modules="$modules qt"

    echo $modules | sed 's/ \+/\n/g' > $sourcedir/modules
    check_stale=1
fi

if test -n "$check_stale"; then
    moddirlistfile=module_dirs
    : >$sourcedir/$repodir/$moddirlistfile
    modlinklistfile=module_links
    : >$sourcedir/$linkdir/$modlinklistfile
fi

for module in $modules; do

    echo "===== Updating module '$module'..."
    while popd >/dev/null 2>/dev/null; do true; done

    if ! pushd $sourcedir/$repodir >/dev/null; then
        echo "ERROR: Cannot enter directory '$sourcedir/$repodir'."
        exit 1
    fi

    vcs=`get_vcs $module`
    if test $? != 0; then
        echo "WARNING: Cannot get VCS for '$module'." | $teelog
        continue
    fi

    moddir=`get_path $module`
    if test $? != 0; then
        echo "WARNING: Cannot get path for '$module'." | $teelog
        continue
    fi
    if test -n "$check_stale"; then
        echo $moddir >> $moddirlistfile
    fi

    case "$vcs" in
    svn)
        if test ! -d $moddir/.svn; then
            mkdir -p $moddir
            svn checkout $svnroot/$moddir $moddir \
            || echo "WARNING: Cannot check out into '$sourcedir/$repodir/$moddir'." | $teelog
        fi
        ;;
    git)
        if test ! -d $moddir/.git; then
            git clone -v --no-checkout `get_url $module` $moddir \
            || echo "WARNING: Cannot clone into '$sourcedir/$repodir/$moddir'." | $teelog
        fi
        ;;
    *)
        echo "WARNING: Unexpected VCS type '$vcs'." | $teelog
        continue
        ;;
    esac

    if ! pushd $moddir >/dev/null; then
        echo "WARNING: Cannot enter directory '$sourcedir/$repodir/$moddir'." | $teelog
        continue
    fi

    if test "$vcs" = "git"; then
        git remote prune origin \
        || echo "WARNING: Cannot prune in '$sourcedir/$repodir/$moddir'." | $teelog
        git fetch \
        || echo "WARNING: Cannot fetch in '$sourcedir/$repodir/$moddir'." | $teelog
    fi

    case "$vcs" in
    svn)
        svn cleanup .
        LC_ALL=C $svnclean -f | grep -v "Subversion working directory\|^F"
        svn revert -R .
        ;;
    git)
        git clean -dxf
        ;;
    *)
        echo "WARNING: Unexpected VCS type '$vcs'." | $teelog
        continue
        ;;
    esac

    case "$vcs" in
    svn)
        svn update \
        || echo "WARNING: Cannot update '$sourcedir/$repodir/$moddir'." | $teelog
        ;;
    git)
        branch=`get_branch $module`
        #if ! git reset --hard origin/$branch; then
        if ! (git checkout -q $branch  && git pull --rebase); then
            echo "WARNING: Cannot switch to branch '$branch' in '$module'." | $teelog
        fi
        ;;
    *)
        echo "WARNING: Unexpected VCS type '$vcs'." | $teelog
        continue
        ;;
    esac

    popd >/dev/null
    popd >/dev/null

    if ! pushd $sourcedir/$linkdir >/dev/null; then
        echo "ERROR: Cannot enter directory '$sourcedir/$linkdir'."
        exit 1
    fi

    podir=`get_po_path $module`
    if test $? != 0; then
        echo "WARNING: Cannot get PO path for '$module'." | $teelog
        continue
    fi
    if ! mkdir -p $podir; then
        echo "WARNING: Cannot create directory '$sourcedir/$linkdir/$podir'." | $teelog
        continue
    fi

    linkfile=$podir/`echo $module | sed 's/^[^_]*_//'`
    linkdest=`revpath $linkdir/$podir`/$repodir/$moddir
    if ! (rm -f $linkfile && ln -s $linkdest $linkfile); then
        echo "WARNING: Cannot create link '$sourcedir/$linkdir/$linkfile'." | $teelog
    fi
    if test -n "$check_stale"; then
        echo $linkfile >> $modlinklistfile
    fi

    popd >/dev/null
done
while popd >/dev/null 2>/dev/null; do true; done

if test -n "$check_stale"; then

    echo "===== Looking for stale checkouts..."
    pushd $sourcedir/$repodir >/dev/null
    alldirlistfile=all_dirs
    find -mindepth 1 -type d | sed 's:^\./::' >$alldirlistfile
    for moddir in `cat $moddirlistfile`; do
        grep -v "^$moddir" $alldirlistfile > tmp; mv tmp $alldirlistfile
        while test $moddir != .; do # remove all parents to this module
            grep -v "^$moddir$" $alldirlistfile > tmp; mv tmp $alldirlistfile
            moddir=`dirname $moddir`
        done
    done
    if test `cat $alldirlistfile | LC_ALL=C wc -l` != 0; then
        echo "===== Deleting stale checkouts..."
        for moddir in `cat $alldirlistfile`; do
            echo $moddir
            rm -rf $moddir \
            || echo "WARNING: Cannot remove stale directory '$moddir'" | $teelog
        done
    fi
    rm -f $alldirlistfile
    popd >/dev/null

    echo "===== Looking for stale links..."
    pushd $sourcedir/$linkdir >/dev/null
    alllinklistfile=all_links
    find -mindepth 2 -maxdepth 2 -type l | sed 's:^\./::' >$alllinklistfile
    for linkfile in `cat $modlinklistfile`; do
        grep -v "^$linkfile" $alllinklistfile > tmp; mv tmp $alllinklistfile
    done
    if test `cat $alllinklistfile | LC_ALL=C wc -l` != 0; then
        echo "===== Deleting stale links..."
        for linkfile in `cat $alllinklistfile`; do
            echo $linkfile
            rm -rf $linkfile \
            || echo "WARNING: Cannot remove stale link '$linkfile'" | $teelog
        done
        for podir in `find -mindepth 1 -maxdepth 1 -type d`; do
            if test `ls $podir | LC_ALL=C wc -l` = 0; then
                rmdir $podir \
                || echo "WARNING: Cannot remove empty directory '$sourcedir/$linkdir/$podir'." | $teelog
            fi
        done
    fi
    rm -f $alllinklistfile
    popd >/dev/null

    if test    `cat $sourcedir/$repodir/$moddirlistfile | wc -l` \
            != `cat $sourcedir/$linkdir/$modlinklistfile | wc -l`; then
        echo "WARNING: Numbers of checkouts and links are different." \
             "Examine lists in files '$sourcedir/$repodir/$moddirlistfile'" \
             "and '$sourcedir/$linkdir/$modlinklistfile'." || $teelog
    else
        rm -f $sourcedir/$repodir/$moddirlistfile
        rm -f $sourcedir/$linkdir/$modlinklistfile
    fi
fi

if test `cat $warnfile | LC_ALL=C wc -l` != 0; then
    echo "===== All warnings written to '$warnfile'."
else
    rm -f $warnfile
fi

