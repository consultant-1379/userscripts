#!/bin/sh

# Created by  : Fatih ONUR
# Created in  : 30/08/2012
##
### VERSION HISTORY
##############################################
# Ver1        : CReate for WRAN deployment O13A
# Purpose     : Update missing External Utran Cells for WRAN_2 network
# Description : 
# Date        : 30.08.2012
# Who         : Fatih ONUR
##############################################


if [ "$#" -ne 1 ]
then
cat<<HELP

####################
# HELP
####################

Usage  : $0 <rnc num>

Example: $0 RNCL130-ST-RNC01 1

HELP

exit 1
fi

################################
# ENV VARIABLES
################################
# RNC Distribution
# [ TYPE=1, NUMOFRC=52, NUMOFRBS=75] ; [..] ; [..] ; [..]
RNCRBSARRAY="1,53,75;"\
"2,41,65;"\
"3,9,146;"\
"4,1,260;"\
"5,1,344;"\
"6,1,421;"

# RBS CELL Distribution
# TYPE1[ TOTALNUMOFCELLS,NUMOFRBS-CELLNUM,NUMOFRBS-CELLNUM,...] ; TYPE2[..] ; TYPE3[..] ; TYPE4[..]
RBSCELLARRAY="320,8-1,37-3,25-6,3-9,2-12;"\
"245,5-1,40-3,20-6,0-9,0-12;"\
"725,5-1,74-3,45-6,12-9,10-12;"\
"1450,10-1,110-3,80-6,30-9,30-12;"\
"2305,10-1,110-3,80-6,81-9,63-12;"\
"3021,21-1,100-3,100-6,100-9,100-12;"

#### IRATHOM ATTRIBUTES FOR WRAN TO WRAN
MCC=46
MNC=6
EXTMNC=7
MNCLENGTH=2


################################
# Functions
################################

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

#
## get total numb of cells for defined num of RBS
#
getTotalCells() # RNCCOUNT RNCRBSARRAY RBSCELLARRAY
{

RNCCOUNT=$1
RNCRBSARRAY=$2
RBSCELLARRAY=$3

NUMOFRNC=0
IFS=";"
for x in $RNCRBSARRAY
do
  NUMOFRNC=`expr $NUMOFRNC + $(echo $x | awk -F"," '{print $2}')`

  if [ "$RNCCOUNT" -le "$NUMOFRNC" ]
  then
    TYPE=$(echo $x | awk -F"," '{print $1}')
    TOTALCELLS=`echo $RBSCELLARRAY  | awk -F" " '{print $'\$TYPE'}' | awk -F"," '{print $1}'`
    NUMOFRBS=`echo $x | awk -F"," '{print $3}'`

    #echo "RNCCOUNT="$RNCCOUNT
    #echo "NUMOFRBS="$NUMOFRBS
    #echo "NUMOFRNC="$NUMOFRNC
    #echo "TYPE="$TYPE
    #echo "TOTALCELLS="$TOTALCELLS
    echo $TOTALCELLS
    break
  fi
done;
}

#
## get total cumulative num of cells up to specified cell count and rnc
#
getCumulativeTotalCells() # RNCCOUNT $COUNT RNCRBSARRAY RBSCELLARRAY
{
RNCCOUNT=$1
COUNT=$2
RNCRBSARRAY=$3
RBSCELLARRAY=$4

NUMOFRNC=0
CUM=0
IFS=";"

for x in $RNCRBSARRAY
do
  NUMOFRNC=`expr $NUMOFRNC + $(echo $x | awk -F"," '{print $2}')`
  #echo "NUMOFRNC="$NUMOFRNC

  TYPE=$(echo $x | awk -F"," '{print $1}')
  TOTALCELLS=`echo $RBSCELLARRAY  | awk -F" " '{print $'\$TYPE'}' | awk -F"," '{print $1}'`
  NUMOFRBS=`echo $x | awk -F"," '{print $3}'`
  CURRENT_NUMOFRNC=$(echo $x | awk -F"," '{print $2}')
  #echo "CURRENT_NUMOFRNC="$CURRENT_NUMOFRNC

  if [ "$RNCCOUNT" -le "$NUMOFRNC" ]
  then

    PRE_NUMOFRNC=`expr $NUMOFRNC - $(echo $x | awk -F"," '{print $2}')`
    DIFF=`expr $RNCCOUNT - $PRE_NUMOFRNC`
    CUM=`expr $CUM + $DIFF \* $TOTALCELLS`
    CUM=`expr $CUM - \( $TOTALCELLS - $COUNT \)`

    #echo "PRE_NUMOFRNC="$PRE_NUMOFRNC
    #echo "DIFF="$DIFF
    #echo "RNCCOUNT="$RNCCOUNT
    #echo "NUMOFRBS="$NUMOFRBS
    #echo "NUMOFRNC="$NUMOFRNC
    #echo "TYPE="$TYPE
    #echo "TOTALCELLS="$TOTALCELLS
    echo $CUM
    break
  else
    CUM=`expr $CUM + $CURRENT_NUMOFRNC \* $TOTALCELLS`
  fi

done;

}

# 
# calculates  group 
#   eg. COUNT=5 NUMOFELM=3; GROUP-1= 1,2,3  GROUP-2= 4,5,6... so 5 is under group-2
# 
getGroup() # COUNT NUMOFELM
{ 
COUNT=$1
NUMOFELM=$2
    
MOD=`expr $COUNT % $NUMOFELM`
DIV=`expr $COUNT / $NUMOFELM` 
    
if [ "$MOD" -eq 0 ]
then
  GROUP=$DIV
else
  GROUP=`expr $DIV + 1`
fi  
    
echo $GROUP
} 

#
## get total numb of cells for defined num of RBS
#
getNumOfRBS() # RNCCOUNT RNCRBSARRAY RBSCELLARRAY
{

RNCCOUNT=$1
RNCRBSARRAY=$2
RBSCELLARRAY=$3

NUMOFRNC=0
IFS=";"
for x in $RNCRBSARRAY
do
  NUMOFRNC=`expr $NUMOFRNC + $(echo $x | awk -F"," '{print $2}')`

  if [ "$RNCCOUNT" -le "$NUMOFRNC" ]
  then
    TYPE=$(echo $x | awk -F"," '{print $1}')
    TOTALCELLS=`echo $RBSCELLARRAY  | awk -F" " '{print $'\$TYPE'}' | awk -F"," '{print $1}'`
    NUMOFRBS=`echo $x | awk -F"," '{print $3}'`

    #echo "RNCCOUNT="$RNCCOUNT
    #echo "NUMOFRBS="$NUMOFRBS
    echo $NUMOFRBS
    #echo "NUMOFRNC="$NUMOFRNC
    #echo "TYPE="$TYPE
    #echo "TOTALCELLS="$TOTALCELLS
    #echo $TOTALCELLS
    break
  fi
done;
}

################################
# SETUP and PRECHECKS
################################

RNCID=$1

if [ "$RNCID" -le 9 ]
then
  RNCNAME="RNC0"$RNCID
  RNCCOUNT="0"$RNCID
else
  RNCNAME="RNC"$RNCID
  RNCCOUNT=$RNCID
fi


PWD=`pwd`
NOW=`date +"%Y_%m_%d_%T:%N"`

# to get rid of extra prefix when we run the command on remote server
if [ ! -f $PWD/$0 ]
then
  PWD=""
fi

max1=1000000
RANDOM1=$((`cat /dev/urandom|od -N1 -An -i` % $max1))

MOSCRIPT=$0${NOW}:$RNCNAME:${RANDOM1}:$$".mo"
MMLSCRIPT=$0${NOW}:$RNCNAME:${RANDOM1}:$$".mml"


if [ -f $PWD/$MOSCRIPT ]
then
  rm -r  $PWD/$MOSCRIPT
  echo "old "$PWD/$MOSCRIPT " removed"
fi

if [ -f $PWD/$MMLSCRIPT ]
then
  rm -r  $PWD/$MMLSCRIPT
  echo "old "$PWD/$MMLSCRIPT " removed"
fi

SIMNAME=`ls /netsim/netsimdir | egrep ${RNCNAME} | grep ST | grep -m1 -v zip`
SUCCESS=$?
#echo "SUCCESS="$SUCCESS

if [ $SUCCESS -eq 1 ]
then
  echo "no simulation found!"
  echo "exiting..."
  echo ""
  exit
fi


################################
# MAIN
################################

echo "...$SIMNAME:$0 script started running at "`date`
echo ""

NUMOFRBS=`getNumOfRBS $RNCCOUNT $RNCRBSARRAY $RBSCELLARRAY`

echo ""
echo "MAKING MO SCRIPT"
echo ""

##############################################################
#
# UtranNetwork :046 Internal:06 (mnc), External:07 (mnc)
#
##############################################################

# deleted 

##############################################################
#
# IurLink mcc =046 , mnc =06 (internal)
#
##############################################################

# deleted 

##############################################################
#
# IurLink mcc = 046, mnc = 07 (external)
#
##############################################################


START_TARGETRNCCOUNT=$RNCCOUNT
STOP_TARGETRNCCOUNT=$RNCCOUNT

IURCOUNT=` expr $START_TARGETRNCCOUNT + 0`
IURSTOP=`expr $STOP_TARGETRNCCOUNT + 0`

#echo "IURSTOPi="$IURSTOP

echo ""
echo $RNCNAME" has the following external iurLinks"

if [ "$RNCCOUNT" -le 81 ]
then

  if [ "$RNCCOUNT" -ge 66 ] && [ "$RNCCOUNT" -le 71 ]
  then
    IURCOUNT=1
    IURSTOP=`expr $IURCOUNT + 2`
    #echo "IURSTOP=a"$IURSTOP
  fi

  if [ "$RNCCOUNT" -ge 72 ] && [ "$RNCCOUNT" -le 73 ]
  then
    IURCOUNT=4
    IURSTOP=`expr $IURCOUNT + 2`
    #echo "IURSTOP=a"$IURSTOP
  fi

  if [ "$RNCCOUNT" -ge 74 ] && [ "$RNCCOUNT" -le 75 ]
  then
    IURCOUNT=7
    IURSTOP=`expr $IURCOUNT + 2`
    #echo "IURSTOP=a"$IURSTOP
  fi

  if [ "$RNCCOUNT" -ge 76 ] && [ "$RNCCOUNT" -le 77 ]
  then
    IURCOUNT=10
    IURSTOP=`expr $IURCOUNT + 0`
    #echo "IURSTOP=a"$IURSTOP
  fi

  if [ "$RNCCOUNT" -ge 78 ] 
  then
    IURCOUNT=11
    IURSTOP=`expr $IURCOUNT + 4`
    #echo "IURSTOP=a"$IURSTOP
  fi

  if [ "$RNCCOUNT" -ge 79 ] 
  then
    IURCOUNT=16
    IURSTOP=`expr $IURCOUNT + 4`
    #echo "IURSTOP=a"$IURSTOP
  fi

  if [ "$RNCCOUNT" -ge 80 ] 
  then
    IURCOUNT=21
    IURSTOP=`expr $IURCOUNT + 4`
    #echo "IURSTOP=a"$IURSTOP
  fi

  if [ "$RNCCOUNT" -ge 81 ] 
  then
    IURCOUNT=26
    IURSTOP=`expr $IURCOUNT + 4`
    #echo "IURSTOP=a"$IURSTOP
  fi

  echo "IURSTOP="$IURSTOP
 
  while [ "$IURCOUNT" -le "$IURSTOP" ]
  do

      IURCOUNT=$(($IURCOUNT + 0)) # to get rid of leading zeros
      #echo "IURCOUNT=$IURCOUNT"
      RNCIDEXT="RNC-"$EXTMNC"-"
      if [  $IURCOUNT -le 9 ]
      then
        IDENTITY=${RNCIDEXT}"0"${IURCOUNT}
      else
        IDENTITY=${RNCIDEXT}${IURCOUNT}
      fi

      echo -n  " :: iurLink="$IDENTITY

      echo 'CREATE' >> $MOSCRIPT
      echo '(' >> $MOSCRIPT
      echo '  parent "ManagedElement=1,RncFunction=1"' >> $MOSCRIPT
      echo '   identity '$IDENTITY >> $MOSCRIPT
      echo '   moType IurLink' >> $MOSCRIPT
      echo '   exception none' >> $MOSCRIPT
      echo '   nrOfAttributes 2' >> $MOSCRIPT
      echo '   rncId Integer' $IURCOUNT >> $MOSCRIPT
      echo "   utranNetworkRef Ref \"ManagedElement=1,RncFunction=1,UtranNetwork="$EXTMNC"\"" >> $MOSCRIPT
      echo ')' >> $MOSCRIPT

    IURCOUNT=`expr $IURCOUNT + 1`
  done
    echo " "
      echo  "   >> has utranNetworkRef=ManagedElement=1,RncFunction=1,UtranNetwork="$EXTMNC
fi

TOTALCELLS=`getTotalCells $RNCCOUNT $RNCRBSARRAY $RBSCELLARRAY`
echo "TOTALCELLS="$TOTALCELLS

##############################################################
#
# ExternalUtranCell (UtranCells managed by same OSS)
#
##############################################################

# deleted



#########################################################################################################
#
# ExternalUtranCells for External UtranRelations ( Master ExternalUtrancells in Region ) (WRAN_2)
#
##########################################################################################################

EXECUTE="YES"
if [ "$EXECUTE" == "YES" ]
then

echo ""
echo $RNCNAME" has the following ExternalUtanCells (UtranCells managed by other OSS)"

TOTALCELLS_FOR_W2=200

if [ "$RNCCOUNT" -le 81 ] 
then

  #### Check WtoW13A worksheet from workingOnWRAN.xls for more details....
 
  IURCOUNT=$RNCCOUNT
  IURSTOP=$RNCCOUNT
  
  if [ "$RNCCOUNT" -ge 66 ] && [ "$RNCCOUNT" -le 71 ]
  then
    IURCOUNT=1
IURSTOP=3
  fi

  if [ "$RNCCOUNT" -ge 72 ] && [ "$RNCCOUNT" -le 73 ]
  then
    IURCOUNT=4
    IURSTOP=6
  fi


  if [ "$RNCCOUNT" -ge 74 ] && [ "$RNCCOUNT" -le 75 ]
  then
    IURCOUNT=7
    IURSTOP=9
  fi

  if [ "$RNCCOUNT" -ge 76 ] && [ "$RNCCOUNT" -le 77 ]
  then
    IURCOUNT=10
    IURSTOP=10
  fi

  if [ "$RNCCOUNT" -eq 78 ] 
  then
    IURCOUNT=11
    IURSTOP=15
  fi

  if [ "$RNCCOUNT" -eq 79 ] 
  then
    IURCOUNT=16
    IURSTOP=20
  fi

  if [ "$RNCCOUNT" -eq 80 ] 
  then
    IURCOUNT=21
    IURSTOP=25
  fi

  if [ "$RNCCOUNT" -eq 81 ] 
  then
    IURCOUNT=26
    IURSTOP=30
  fi

  ####################
  # COUNTERS
  ###################

  COUNT=1
  RBSCOUNT=1
  CELLCOUNT=1

  while [ "$COUNT" -le "$TOTALCELLS_FOR_W2" ]
  do

    NUMOFCELL=5
    CELLSTOP=`expr $NUMOFCELL + 1`

    if [ "$CELLCOUNT" -eq "$CELLSTOP" ]
    then
      CELLCOUNT=1
      RBSCOUNT=`expr $RBSCOUNT + 1`
    fi



###########################
# CONDITIONS
###########################

    NUMOFCELL_ONE_PROXY=$TOTALCELLS_FOR_W2
    NUMOFCELL_ZERO_PROXY=`expr $TOTALCELLS_FOR_W2 - \( $NUMOFCELL_ONE_PROXY \)`

    ONE_PROXY_START=`expr $TOTALCELLS_FOR_W2 - $NUMOFCELL_ONE_PROXY + 1`
    ONE_PROXY_END=$TOTALCELLS_FOR_W2

    ZERO_PROXY_START=`expr $ONE_PROXY_START - $NUMOFCELL_ZERO_PROXY`
    ZERO_PROXY_END=`expr $ONE_PROXY_START - 1`


    ##############################################################################################################################
    #
    # Zero proxy up to the specified cell
    #
    #############################################################################################################################

    if [ "$COUNT" -le "$ZERO_PROXY_END" ]
    then
      echo " :: "$COUNT" Zero proxy"
    else

      ##############################################################################################################################
      #
      # Creates proxies under total (NUMOFELMOF_RNCGROUP-1) number of iurLinks within network between RNC01 to ...
      #
      #############################################################################################################################

      if [ "$COUNT" -ge "$ONE_PROXY_START" ] && [ "$COUNT" -le "$ONE_PROXY_END" ]
      then
        NUMOFELMOF_RNCGROUP=`expr $IURSTOP - $IURCOUNT + 1` # modified by Fatih to create ExternalUtanCells for only one RNC
      fi


#############################################################
# IMPLEMANTATION OF PROXIES
#############################################################

      MOD=`expr $IURCOUNT % $NUMOFELMOF_RNCGROUP`
      DIV=`expr $IURCOUNT / $NUMOFELMOF_RNCGROUP`

      if [ "$MOD" -eq 0 ]
      then
        RNCGROUP=$DIV
      else
        RNCGROUP=`expr $DIV + 1`
      fi

      ##################################################################################################################
      #
      # Start of each Target RNC Group
      #  Ex: Say each group conist of 6 RNC (NUMOFELMOF_RNCGROUP), you look for 2nd group (RNCGROUP) start target rncId
      #          START_TARGETRNCCOUNT = 6 * 2 (6 -1) = 7
      #          STOP_TARGETRNCCOUNT = 7 + 6 - 1 = 12
      #
      ##################################################################################################################
      START_TARGETRNCCOUNT=`expr $NUMOFELMOF_RNCGROUP \* $RNCGROUP - \( $NUMOFELMOF_RNCGROUP - 1 \)`
      STOP_TARGETRNCCOUNT=`expr $START_TARGETRNCCOUNT + $NUMOFELMOF_RNCGROUP - 1`

      #echo "START_TARGETRNCCOUNT="$START_TARGETRNCCOUNT
      #echo "STOP_TARGETRNCCOUNT="$STOP_TARGETRNCCOUNT

       

      TARGETRNCCOUNT=$START_TARGETRNCCOUNT

      while [ "$TARGETRNCCOUNT" -le "$STOP_TARGETRNCCOUNT" ]
      do


        ######################################################################
        #
        # Creates External UtranCells according to portion stated on conditions above.
        #
        #######################################################################

        LA=$TARGETRNCCOUNT
        RA=$TARGETRNCCOUNT

        RNCIDEXT="RNC-"$EXTMNC"-"
         if [ "$TARGETRNCCOUNT" -ge 10 ]
         then
           IDENTITY=${RNCIDEXT}$TARGETRNCCOUNT
         else
           IDENTITY=${RNCIDEXT}"0"$TARGETRNCCOUNT
         fi


        TARGETCELLCOUNT=`expr $COUNT +  \( \( $TARGETRNCCOUNT - 1 \)  \* $TOTALCELLS_FOR_W2 \)`
        UTRANCELLID=`cell_name $TARGETRNCCOUNT $RBSCOUNT $CELLCOUNT`

        UARFCNDL=`expr \( \( $TARGETRNCCOUNT \* 1 \) + 0 \) % 16384`
        UARFCNUL=12
        PRIMSCRCODE=`expr $COUNT % 512`
        PRIMARYCPICHPOWER=300
        QRXLEVMIN=-115
        QQUALMIN=-24
        MAXTXPOWERUL=30


        #echo " :: ExternalUtranCell="$TARGETCELLCOUNT" ->  iurLink="$TARGETRNCCOUNT" ; RA="${RA}" LA="${LA}" UARFCNDL="$UARFCNDL" PRIMSCRCODE="$PRIMSCRCODE
        ###echo -e " :: ExternalUtranCell="$UTRANCELLID" ; cId="$TARGETCELLCOUNT" ->  iurLink="$IDENTITY" ; RA="${RA}" LA="${LA}" UARFCNDL="$UARFCNDL
        #echo "  PRIMSCRCODE="$PRIMSCRCODE" PRIMARYCPICHPOWER="$PRIMARYCPICHPOWER" QRXLEVMIN="$QRXLEVMIN" QQUALMIN="$QQUALMIN" MAXTXPOWERUL="$MAXTXPOWERUL

        #echo " :: EXTERNALUTRANCELLID="$UTRANCELLID" RNCID="$TARGETRNCCOUNT", CID="$TARGETCELLCOUNT" USERLABEL="$UTRANCELLID" UARFCNDL="$UARFCNDL" UARFCNUL="$UARFCNUL
        #echo -n "    PRIMSCRCODE="$PRIMSCRCODE" PRIMARYCPICHPOWER="$PRIMARYCPICHPOWER" QQUALMIN="$QQUALMIN" LAC="$LA" QRXLEVMIN="$QRXLEVMIN
        ##echo    " RAC="$RA "MAXTXPOWERUL="$MAXTXPOWERUL" IURLINK="$IDENTITY 
        ##echo ""


        echo 'CREATE' >> $MOSCRIPT
        echo '(' >> $MOSCRIPT
        echo '  parent "ManagedElement=1,RncFunction=1,IurLink='$IDENTITY'"' >> $MOSCRIPT
        echo ' identity '$UTRANCELLID >> $MOSCRIPT
        echo ' moType ExternalUtranCell' >> $MOSCRIPT
        echo ' exception none' >> $MOSCRIPT
        echo ' nrOfAttributes 11' >> $MOSCRIPT
        echo ' lac Integer '$LA >> $MOSCRIPT
        echo ' rac Integer '$RA >> $MOSCRIPT
        echo ' userLabel String ExternalUtranCell='$UTRANCELLID >> $MOSCRIPT
        echo ' cId Integer '$TARGETCELLCOUNT >> $MOSCRIPT
        echo ' uarfcnDl Integer '$UARFCNDL >> $MOSCRIPT
        echo ' uarfcnUl Integer '$UARFCNUL >> $MOSCRIPT
        echo ' qRxLevMin Integer '$QRXLEVMIN >> $MOSCRIPT
        echo ' qQualMin Integer '$QQUALMIN >> $MOSCRIPT
        echo ' primaryScramblingCode Integer '$PRIMSCRCODE >> $MOSCRIPT
        echo ' primaryCpichPower Integer '$PRIMARYCPICHPOWER>> $MOSCRIPT
        echo ' maxTxPowerUl Integer '$MAXTXPOWERUL >> $MOSCRIPT
        echo ')' >> $MOSCRIPT

        TARGETRNCCOUNT=`expr $TARGETRNCCOUNT + 1`
      done
    fi

    CELLCOUNT=`expr $CELLCOUNT + 1`
    COUNT=`expr $COUNT + 1`
  done
else
  echo "....no externalutrancells exist for $RNCNAME"
  echo " "
  echo "$SIMNAME:$0: MAKING MO SCRIPT ended at "`date`
  exit
fi

fi # EXECUTE END

echo ""
echo "$SIMNAME:$0: MAKING MO SCRIPT ended at "`date`

#exit

#########################################
#
# Make MML Script
#
#########################################

echo ""
echo "MAKING MML SCRIPT"
echo ""

echo '.open '$SIMNAME >> $MMLSCRIPT
echo '.select '$RNCNAME >> $MMLSCRIPT
echo '.start ' >> $MMLSCRIPT
echo 'useattributecharacteristics:switch="off";' >> $MMLSCRIPT
echo 'kertayle:file="'$PWD'/'$MOSCRIPT'",commit_freq=operation;' >> $MMLSCRIPT


/netsim/inst/netsim_shell < $MMLSCRIPT 


rm $PWD/$MOSCRIPT
rm $PWD/$MMLSCRIPT

echo "...$SIMNAME:$0 script ended at "`date`
echo ""

