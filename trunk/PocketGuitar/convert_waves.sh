#!/bin/sh

mkdir -p build/Release/Media

for FILE in `find waves -name '*.wav'`; do
#  OUTFILE=`echo $FILE | sed 's/waves\/\(.*\)\.wav/build\/Release\/Media\/\1\.raw/'` 
  OUTFILE=`echo $FILE | sed 's/waves\/\(.*\)\.wav/build\/Release\/Media\/\1\.mp3/'` 
  echo "$FILE -> $OUTFILE"
  mkdir -p `dirname $OUTFILE`
#  sox $FILE -t raw -r 44100 -s -w $OUTFILE
  lame $FILE $OUTFILE
done

