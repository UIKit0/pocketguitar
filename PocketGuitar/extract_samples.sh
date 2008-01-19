#!/bin/sh

MPG123=/Applications/PocketGuitar.app/mpg123
cd /var/root/Media/PocketGuitar

for FILE in `find . -name '*.mp3'`; do
  OUTFILE=`echo $FILE | sed 's/\.mp3/\.raw/'` 
  echo "$FILE -> $OUTFILE"
  mkdir -p `dirname $OUTFILE`
  $MPG123 -s $FILE > $OUTFILE
done
