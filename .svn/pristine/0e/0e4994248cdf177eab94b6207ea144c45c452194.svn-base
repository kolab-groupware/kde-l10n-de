# Some description here could be useful...

NTHREADS=4

# Return 0 if no parent dir of the given file path contains ignore-file
noignore() {
    pardir=$1
    while test $pardir != "."; do
        # Next three lines replace pardir=`dirname $pardir`, way too slow.
        pardir_p=$pardir
        pardir=${pardir%/*}
        test $pardir != $pardir_p || pardir=.

        test -f $pardir/no-auto-merge && return 1
    done
    return 0
}

function wait_processes
{
  aux=0
  while [ $aux -lt $1 ]; do
    wait ${pids[$aux]}
    state=$?
    if [ "$state" != "0" ]; then
      echo "ERROR: msgmerge failed for ${filearray[$aux]}"
    fi
    ((aux = aux + 1))
  done
}

if test -n "$FULLLIST"; then
  list=
  for i in $FULLLIST; do 
    list="$list `echo $i | sed -e 's#^templates/\(.*\)\.pot$#\1#'`"
  done 
  # echo $list
elif test -z "$LIST"; then 
  list=`find templates -name '*.pot' | sed -e 's#^templates/\(.*\)\.pot$#\1#'`
else 
  list=
  for i in $LIST; do 
    list="$list `find templates -name $i | sed -e 's#^templates/\(.*\)\.pot$#\1#'`"
  done 
  echo $list
fi
languages=
for i in *; do 
	if test -d $i/messages -o -d $i/docmessages; then
		languages="$languages $i"
	fi
done
for temp in $list; do 
  test -n "$VERBOSE" && echo merging $temp
  nthread=0
  for subdir in $languages; do 
    if [ $nthread -eq $NTHREADS ]; then
      wait_processes $NTHREADS
      nthread=0
    fi

    file=$subdir/$temp.po
    test -f $file || continue
    noignore $file || continue
    if test ! -s $file; then
      echo "ERROR: $file is empty!"
    else
      filearray[$nthread]=$file
      ionice -c 2 -n 7 nice -n 30 msgmerge --previous -q -o $file $file templates/$temp.pot &
      pids[$nthread]=$!
      ((nthread = nthread + 1))
    fi
  done
  wait_processes $nthread
done
