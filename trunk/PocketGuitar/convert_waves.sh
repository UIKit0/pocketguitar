#!/bin/sh

for FILE in `find waves -name *.wav`; do
  OUTFILE=`echo $FILE | sed 's/waves\/\(.*\)\.wav/rawwaves\/\1\.raw/'` 
  echo "$FILE -> $OUTFILE"
  mkdir -p `dirname $OUTFILE`
  sox $FILE -t raw -r 44100 -s -w $OUTFILE
done

