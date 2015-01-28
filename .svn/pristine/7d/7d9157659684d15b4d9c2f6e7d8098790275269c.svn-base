#!/bin/bash

podir=${podir:-$PWD/po}
metainfo_file_list=$(find . -name '*.appdata.xml*' -or -name '*.metainfo.xml*')

for metainfo_file in $metainfo_file_list; do

  # first, strip translation from project metadata file
  tmpxmlfile=$(mktemp)
  xmlstarlet ed -d "//*[@xml:lang]" $metainfo_file > $tmpxmlfile

  # get rid of the .xml extension and dirname
  metainfo_file_basename=$(basename $metainfo_file)
  dataname="${metainfo_file_basename%.xml*}"

  # create pot file foo.[appdata|metadata].xml -> foo.[appdata|metadata].pot
  itstool -i $ASMETAINFOITS -o $podir/$dataname.pot $tmpxmlfile
  esc_tmpxmlfile=$(echo $tmpxmlfile|sed -e 's/[]\/()$*.^|[]/\\&/g')
  sed -i "/^#:/s/$esc_tmpxmlfile/$metainfo_file_basename/" $podir/$dataname.pot

  tmpmofiles=""
  tmpdir=$(mktemp -d)
  # find po files in l10n module dir
  for pofile in $(ls $L10NDIR/*/messages/$SUBMODULE/$dataname.po 2> /dev/null); do
    # get language-id
    lang=${pofile#$L10NDIR}
    lang=$(echo $lang|cut -d/ -f2)

    # generate mo files (need to be named after their language)
    mofile="$tmpdir/$lang.mo"
    msgfmt $pofile -o $mofile

    tmpmofiles="$tmpmofiles $mofile"
  done

  if [ -n "$tmpmofiles" ]; then
    # recreate file, using the untranslated temporary data and the translation
    itstool -i $ASMETAINFOITS -j $tmpxmlfile -o $metainfo_file $tmpmofiles
  fi

  # cleanup
  rm -rf $tmpdir
  rm $tmpxmlfile
done
