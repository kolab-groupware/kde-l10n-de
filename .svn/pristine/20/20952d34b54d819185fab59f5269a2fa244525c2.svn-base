#!/bin/bash

NTHREADS=4

. scripts/find_meinproc
MEINPROC_COMMAND=`find_meinproc`
test -z "${MEINPROC_COMMAND}" && echo "No suitable version of meinproc was found. Exiting..." && exit 1

DOCBOOK_L10N_ALL="$kdelibsdir/kdoctools/customization/xsl/all-l10n.xml"
DOCBOOK_L10N_CUSTOM="$kdelibsdir/kdoctools/customization/xsl/kde-custom-l10n.xml"
if test -z "${DOCBOOK_L10N_ALL}" || test -z "${DOCBOOK_L10N_CUSTOM}"; then
  echo "No custom l10n files for DocBook XSLT were found. Exiting..."
  exit 1
fi

if [ ! -d scripts ]; then
  echo "You have to run the script from the parent directory of scripts/"
  exit 1
fi


if [ "x$DOOCBOOK_LOCATION" = "x" ]; then
  DOCBOOK_LOCATION=/usr/share/xml/docbook/schema/dtd/4.2/
fi

if [ "x$DOOCBOOKXSL_LOCATION" = "x" ]; then
  DOCBOOKXSL_LOCATION=/usr/share/xml/docbook/stylesheet/nwalsh/
fi

if [ ! -e $kdelibsdir/kdoctools/customization/dtd/kdex.dtd.cmake ]; then
  echo "Could not find kdex.dtd.cmake make sure \$kdelibsdir is defined properly"
  exit 1
fi

optimized=""
if test "$1" = "--optimized"; then
        optimized="true"
        shift
fi

sed s#@DOCBOOKXML_CURRENTDTD_DIR@#$DOCBOOK_LOCATION#g $kdelibsdir/kdoctools/customization/dtd/kdex.dtd.cmake > $kdelibsdir/kdoctools/customization/dtd/kdex.dtd
sed s#@DOCBOOKXSL_DIR@#$DOCBOOKXSL_LOCATION#g $kdelibsdir/kdoctools/customization/kde-include-common.xsl.cmake > $kdelibsdir/kdoctools/customization/kde-include-common.xsl
sed s#@DOCBOOKXSL_DIR@#$DOCBOOKXSL_LOCATION#g $kdelibsdir/kdoctools/customization/kde-include-man.xsl.cmake > $kdelibsdir/kdoctools/customization/kde-include-man.xsl
docbookl10nhelper $DOCBOOKXSL_LOCATION $kdelibsdir/kdoctools/customization/xsl/ $kdelibsdir/kdoctools/customization/xsl/

function wait_processes
{
  aux=0
  while [ $aux -lt $1 ]; do
    wait ${pids[$aux]}
    state=$?
    if [ "$state" != "0" ]; then
      echo ${file[$aux]} failed
      cat /tmp/kdecheckdocsaux$aux
    fi
    ((aux = aux + 1))
  done
}

for lang in `cat subdirs`; do
  if [ -d $lang/docs/ ]; then
    if [ x"$optimized" = x"true" ]; then
      files=""
      dirs=`find $lang/docs/ -name *.docbook -a \( -mtime 0 -o -mtime 1 -o -mtime 2 \) -exec dirname {} \; | sort | uniq`
      for d in $dirs; do
        files="$files `find $d -name index.docbook -o -name man-*.docbook`"
      done
    else
      files=`find $lang/docs/ -name index.docbook -o -name man-*.docbook`
    fi
    
    nthread=0
    for i in $files; do
      if [ $nthread -eq $NTHREADS ]; then
        wait_processes $NTHREADS
        nthread=0
      fi
      
      file[$nthread]=$i
      ionice -c 2 -n 7 nice -n 30 $MEINPROC_COMMAND $i > /dev/null 2> /tmp/kdecheckdocsaux$nthread &
      pids[$nthread]=$!
      ((nthread = nthread + 1))
    done
    
    wait_processes $nthread
  fi
done

while [ $nthread -lt $NTHREADS ]; do
  rm -f /tmp/kdecheckdocsaux$nthread
  ((nthread = nthread + 1))
done

rm -f $kdelibsdir/kdoctools/customization/dtd/kdex.dtd \
      $kdelibsdir/kdoctools/customization/kde-include-common.xsl \
      $kdelibsdir/kdoctools/customization/kde-include-man.xsl \
      $kdelibsdir/kdoctools/customization/xsl/all-l10n.xml \
      $kdelibsdir/kdoctools/customization/xsl/kde-custom-l10n.xml
