#!/bin/bash

LANG=C
LC_ALL=C
LC_MESSAGES=C
CDPATH=

hput () {
  key=`echo $1 | sed -e "s#/#_#g" | sed -e "s#\.#_#g"`
  eval hash"$key"='$2'
}

hget () {
  key=`echo $1 | sed -e "s#/#_#g" | sed -e "s#\.#_#g"`
  eval echo '${hash'"$key"'#hash}'
}

commit=no
if test "$1" = "--commit"; then
  commit=yes
  shift
fi

check=no
if test "$1" = "--check"; then
  . scripts/find_meinproc
  MEINPROC_COMMAND=`find_meinproc`
  DOCBOOK_L10N_ALL="$BASEDIR/`get_path kdelibs`/kdoctools/customization/xsl/all-l10n.xml"
  DOCBOOK_L10N_CUSTOM="$BASEDIR/`get_path kdelibs`/kdoctools/customization/xsl/kde-custom-l10n.xml"
  test -z "${MEINPROC_COMMAND}" && echo "No suitable version of meinproc was found. Exiting..." && exit 1
  if test -z "${DOCBOOK_L10N_ALL}" || test -z "${DOCBOOK_L10N_CUSTOM}"; then
    echo "No custom l10n files for DocBook XSLT were found. Exiting..."
    exit 1
  fi
  check=yes
  shift
fi

if test "$1" = "--autosvnadd"; then
  AUTOSVNADD=yes
  shift
fi

if [ $# -eq 0 ]; then
  rm -rf documentation
  bash ./scripts/populate_documentation.sh --silent
  populateresult=$?
  modules=`find documentation/ -maxdepth 1 -type d -follow -printf '%f\n' | grep -v svn | grep -v documentation`
elif [ $# -eq 1 ]; then
  rm -rf documentation/$1
  bash ./scripts/populate_documentation.sh --silent $1
  populateresult=$?
  modules=$1
else
  echo 'wrong number of parameters'
  echo 'createdoctemplates.sh [--commit] [--check] [--autosvnadd] [module]'
  exit 1
fi

if [ "x$populateresult" != "x0" ]; then
  echo 'populate_documentation.sh failed, bailing out'
  exit 1
fi

all_files=""

if ! type -p xml2pot >/dev/null; then
  echo 'xml2pot needs to be in your PATH. See kdesdk/poxml'
  exit 1
fi

for m in $modules; do
  echo $m
  files_in_module=""
  files=`( cd documentation/ && find $m -follow -name "*.docbook")`
  all_files="$all_files $files"
  ### FIXME: we would need to create the svn directory instead
  mkdir -p templates/docmessages/$m
  for i in $files; do
    case $i in
      *_original.docbook)
        continue
        ;;
    esac
    j=`echo $i | sed -e "s#$m/##" | sed -e 's#.docbook$##' | sed -e 's#/index$##' | sed -e "s#/#_#g"`
    test -n "$VERBOSE" && echo "xml2pot $i > $j.pot" || echo -e ."\c"
    if [ $check = "yes" ]; then
      filetocheck=""
      case $i in
        */index.docbook|*/man-*.docbook)
          filetocheck=$i
          ;;
        *)
          filetocheck=`dirname $i`/index.docbook
          ;;
      esac
      alreadyprocessed=x`hget $filetocheck`
      if [ $alreadyprocessed = "x" ]; then
        if ! $MEINPROC_COMMAND documentation/$filetocheck > /dev/null; then
          hput $filetocheck fails
          continue
        else
          hput $filetocheck works
        fi
      elif [ $alreadyprocessed = "x"fails ]; then
        continue
      fi
    fi
    xml2pot documentation/$i > templates/docmessages/$m/$j.pot.new
    if test ! -s templates/docmessages/$m/$j.pot.new; then
        test -n "$VERBOSE" && echo "Generating $j.pot has failed!"
        continue
    fi
    splitstatus=`python ./scripts/msgsplit templates/docmessages/$m/$j.pot.new`
    if [ -n "$splitstatus" ]; then
	    echo "Problem in msgsplit of templates/docmessages/$m/$j.pot.new"
	    echo $splitstatus
	    exit 1
    fi
    if test -s templates/docmessages/$m/$j.pot.new; then
      if test ! -f templates/docmessages/$m/$j.pot; then
        test -n "$VERBOSE" && echo "$j.pot is new!"
        mv templates/docmessages/$m/$j.pot.new templates/docmessages/$m/$j.pot
        test -n "$AUTOSVNADD" && svn add --parents templates/docmessages/$m/$j.pot
      elif ! diff -q -I^\"POT-Creation-Date: templates/docmessages/$m/$j.pot.new templates/docmessages/$m/$j.pot > /dev/null; then
        mv templates/docmessages/$m/$j.pot.new templates/docmessages/$m/$j.pot
      else
        rm templates/docmessages/$m/$j.pot.new
      fi
      files_in_module="$files_in_module $j.pot ";
    fi
  done

  for one_file in `ls templates/docmessages/$m`; do
    ex=`echo " $files_in_module " | sed -n "/ $one_file /p"`
    if test "$ex" != " $files_in_module "; then
      delete_file="$m/$one_file";
      echo
      echo "This file seems to be obsolete: $delete_file";
      svn del templates/docmessages/$delete_file
    fi
  done
  echo
done

if [ $commit = yes ]; then
  cd templates && svn commit -m "SVN_SILENT made docmessages"
fi

