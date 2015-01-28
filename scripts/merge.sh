#!/bin/sh
# Merge .po file ($file) with .pot template ($template)
# Usage: $0 $file $template

file=$1
template=$2
test -f $file || exit 1
files="$files $file"
if msgmerge --previous -o $file $file $template; then
  ### TEMPORARY
  #exec python `dirname $0`/msgsplit $file
  true
else
  echo "Merging failed for file $file"
fi
