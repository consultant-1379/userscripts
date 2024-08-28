#!/bin/sh

if [ "$#" -ne 1 ]
then
cat << HELP

Usage    : $0 <folder name to delete CVS folder from inside>
Examplae : $0 FT (to delete all CVS folder under it)
Note     : It assumes that your current folder under /netsim/simgen3/

HELP
 exit 1
fi

#find /netsim/simgen3/$1 -name 'CVS' -ok rm -f {} \

delcnt=0
for folder  in `find /netsim/simgen3/$1 -name 'CVS' -print`
do
   echo $folder "Deleted"
   rm -rf $folder
   delcnt=$(($delcnt + 1))
done

echo "deleted $delcnt folders"
