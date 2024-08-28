#!/bin/bash
#  Replace all instances of OLD_ with NEW_*
#+ in files with a ".txt" filename suffix.
#  Also insert a new line

NOW_LINE='NOW=`date +"%Y_%m_%d_%T:%N"`'
PWD_LINE='PWD=`pwd`'

OLD_MO='MOSCRIPT=$0".mo"'
OLD_MMML='MMLSCRIPT=$0".mml"'

NEW_MO='MOSCRIPT=$0${NOW}".mo"'
NEW_MML='MMLSCRIPT=$0${NOW}".mml"'

PWD=`pwd`

if [ -f $PWD/$0.log ]
then
  rm -r  $PWD/$0.log
  echo "WARNING! OLD: "$PWD/$0.log " file is removed"
fi

scrript_name=`echo $0 | sed 's/^..//'`
#echo "scrript_name:"$scrript_name

#for file in $(ls *.txtx)
for file in $(ls [1-9]*.sh)
do
  # -------------------------------------
  if [ "$file" != "$scrript_name" ]
  then
    echo "file:"$file >> $0.log

    sed -i 's/'"$OLD_MO"'/'"$NEW_MO"'/g' $file
    sed -i 's/'"$OLD_MMML"'/'"$NEW_MML"'/g' $file
    sed  '/^'"$NOW_LINE"'/d' $file > /tmp/tmp.sh
    mv /tmp/tmp.sh $file
    chmod +x $file
    sed  -i '/^'"$PWD_LINE"'/ a\'"$NOW_LINE"'' $file
  fi
  #
  #
  # -------------------------------------
done

