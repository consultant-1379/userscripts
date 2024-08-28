#!/bin/sh

# Created by  : Fatih ONUR
# Created in  : 29.09.09
##
### VERSION HISTORY
# Ver1        : Created for WRAN TERE O 10.0
# Purpose     : Convert CellCount proper UtranCell ID
# Description : 
# Date        : 29 Sep 2009
# Who         : Fatih ONUR

if [ "$#" -ne 1  ]
then
cat<<HELP

####################
# HELP
####################

Usage  : $0 <start>

Example: $0  start

Descrp : "cell_name2" function Convert CellCount proper UtranCell ID
 

HELP

exit 1
fi


# Add leading zeros
zero() { # number, length
    # Need to remove leading 0, might cause the value to be
    # interpreted as octal
    case "$1" in
        0)
            N="$1"
            ;;
        0*)
            N=`echo "$1"| cut -c2-`
            ;;
        *)
            N="$1"
            ;;
    esac
    case "$2" in
        2)
         printf "%.2d" "$N"
         ;;
        3)
         printf "%.3d" "$N"
         ;;
        *)
         printf "%d" "$N"
         ;;
    esac
}

rbs_name() # rncnumber rbsnumber
{
    echo "`rnc_name $1`RBS`zero $2 2`"
}
rxi_name() # rncnumber rxinumber
{
    echo "`rnc_name $1`RXI`zero $2 2`"
}
rnc_name() # rncnumber
{
    echo "RNC`zero $1 2`"
}

cell_name() # rncnumber rbsnumber cellnumber
{
    case  "$CELLNAME" in
        gsm)
           echo "`zero $1 2``zero $2 3`_$3"
           ;;

        *)
           echo "`rnc_name $1`-$2-$3"
           ;;
    esac
}

# function to Convert CellCount proper UtranCell ID
cell_name2()# rncnumber cellcount
{

RNCNUM=$1
TEMPCELLCOUNT=$2

_TOTALCELL_TYPE_C=795
_TOTALCELL_TYPE_F=2304

_3CELL=3
_6CELL=6
_3CELLRBS=109
_6CELLRBS=78

if [ "$RNCNUM" -le 32 ]
then

  CELLCOUNT=`expr $TEMPCELLCOUNT - \( \( $1 - 1 \) \* $_TOTALCELL_TYPE_C \)`

  LIMIT_3CELL=`expr $_3CELLRBS \* $_3CELL`
  #echo "LIMIT_3CELL="$LIMIT_3CELL

  if [ "$CELLCOUNT" -le "$LIMIT_3CELL" ]
  then
    MOD=`expr $CELLCOUNT % $_3CELL`
    if [ "$MOD" -eq 0 ]
    then 
      RBSCOUNT=`expr $CELLCOUNT / $_3CELL`
      CELLNUM=$_3CELL
    else 
      RBSCOUNT=`expr $CELLCOUNT / $_3CELL + 1`
      CELLNUM=`expr $CELLCOUNT % $_3CELL`
    fi
else
    NEWCELLCOUNT=`expr $CELLCOUNT - $LIMIT_3CELL`
    MOD=`expr $NEWCELLCOUNT % $_6CELL`
    if [ "$MOD" -eq 0 ]
    then
      RBSINCREASE=`expr $NEWCELLCOUNT / $_6CELL`
      RBSCOUNT=`expr $_3CELLRBS + $RBSINCREASE`
      CELLNUM=$_6CELL
    else
      RBSINCREASE=`expr $NEWCELLCOUNT / $_6CELL + 1`
      RBSCOUNT=`expr $_3CELLRBS + $RBSINCREASE`
      CELLNUM=`expr $NEWCELLCOUNT % $_6CELL`
    fi
  fi
else # first else of if/else

  CELLCOUNT=$TEMPCELLCOUNT
  MOD=`expr $CELLCOUNT % $_3CELL`
  if [ "$MOD" -eq 0 ]
  then
    RBSCOUNT=`expr $CELLCOUNT / $_3CELL`
    CELLNUM=$_3CELL
  else
    RBSCOUNT=`expr $CELLCOUNT / $_3CELL + 1`
    CELLNUM=`expr $CELLCOUNT % $_3CELL`
  fi

fi # first fi of if/else

#echo "RBSCOUNT="$RBSCOUNT 
#echo "CELLNUM="$CELLNUM

echo "`rnc_name $1`-$RBSCOUNT-$CELLNUM"

}

UTRANCELLID=`cell_name2 33 1591`
echo "UTRANCELLID="$UTRANCELLID
