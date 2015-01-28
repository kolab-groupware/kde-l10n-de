#! /bin/bash
# kate: space-indent on; indent-width 2; replace-tabs on;
langfile=`tempfile`
KDEDIR=`tempfile`
logfile=`tempfile`
if test -f $KDEDIR; then rm -f $KDEDIR; mkdir $KDEDIR; fi
export KDEDIR;
lists=`ls -1 all_files_*`
: > $logfile ;
languages=`cat subdirs`; 
for listfile in $lists; do 
  mod=`echo $listfile | sed -e "s,all_files_,,"`
  : > $langfile ;
  for lang in $languages; do 
    file=`find $lang/messages -name "desktop_$mod.po"`
    if test -z "$file"; then 
      continue
    fi
    charsetline=`egrep "^\"Content-Type: .*/.*;? charset=.*\n\"" $file`
    if test -z "$charsetline"; then 
      echo "ERROR: file $file contains no correct charset declaration!"
      fgrep -i "Content-Type" $file
      echo "--"
      continue
    else
      charset=`echo $charsetline | sed -e "s#^.*charset=\(.*\)..\"#\1#"`
      # The Gettext tools are strict about the spelling of UTF-8
      if test "$charset" != "utf-8" -a "$charset" != "UTF-8"; then
        echo "ERROR: file $file has non-UTF-8 charset: $charset"
        continue
      fi
    fi
    mkdir -p $KDEDIR/share/locale/abc/LC_MESSAGES
    if ! msgfmt $file -o $KDEDIR/share/locale/abc/LC_MESSAGES/apply_$lang.mo; then 
            echo "ERROR: file $file could not be processed by msgfmt!"
            continue
    fi
    echo $lang >> $langfile
  done
  filelanguages=`sort -u $langfile`
  list=`cat $listfile` 
  for i in $list; do 
    if ./apply $i $filelanguages >> $logfile 2>&1; then
      if cmp -s $i $i.new; then
        rm $i.new
      else
        chmod --reference=$i $i.new
        mv -f $i.new $i
      fi
    else
      echo "ERROR: ./apply failed for file $i"
    fi
  done
done
sort $logfile
rm -f $logfile $langfile
rm -rf $KDEDIR
