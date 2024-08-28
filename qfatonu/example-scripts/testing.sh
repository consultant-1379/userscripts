#!/bin/bash

INTERACTION="y"

NETSIMSERVERLIST="netsimlin123 netsimlin234 netsimlin456"

# Get the list of sims on each netsim into a list

SIMCOUNT=0

for host in `echo $NETSIMSERVERLIST`
do

    if [[ "$host" == "netsimlin123" ]]
    then
        eval ${host}_sims_list=\"sim1 sim2 sim3\"
    elif [[ "$host" == "netsimlin234" ]]
    then
        eval ${host}_sims_list=\"sim4 sim5 sim6\"
    fi
    #BACKUPDIR="$MOUNTPOINT/savedconfigs/$host/$DATE/existingsims"

    #echo "INFO: Checking what simulations are on $host"
    #eval ${host}_sims_list=`$RSH -l netsim $host " ls /netsim/netsimdir | $GREP -v default | $GREP -v exported_items | $GREP -v indexlogfile | $GREP -v logfiles | $GREP -v mmlscripts | $GREP -v mmltest | $GREP -v tmp | $GREP -v user_cmds | $GREP -v .sh | $GREP -v mpfg" | $GREP -E '(RNC|LTE|DOG)'`
    SIMLIST=`eval echo \\$${host}_sims_list`

    if [ -n "$SIMLIST" ]
    then
        echo "**************************************"
        echo "SIMS on $host are as follows"
        echo "**************************************"
        for sim in `echo $SIMLIST`
        do
            echo "$sim"
            SIMCOUNT=`expr $SIMCOUNT + 1`
        done
        echo "**************************************"
    fi
done

# Now loop through each sim and ask questions if necesary to build up list of sims per netsim to delete

if [[ $SIMCOUNT -gt 0 ]]
then
    echo "QUERY: Would you like to KEEP any of the $SIMCOUNT SIMS from all of the netsims above, upper case Y states yes to keep all, y means yes you want to keep some, n means no to keep any (y/Y/n)"
    echo -e "INPUT: \c"
    if [[ $INTERACTION == "y" ]]
    then
        read ANS_ALL
    else
        echo "INFO: Interaction Set to NO, Default answer here is (n)"
        ANS="n"
    fi

    for host in `echo $NETSIMSERVERLIST`
    do

        NETSIM_DELETE_LIST=${host}_sim_delete_list

        SIMLIST=`eval echo \\$${host}_sims_list`

        if [ -n "$SIMLIST" ]
        then

            if [[ "$ANS_ALL" == "Y" ]]
            then
                ANS="Y"
            elif [[ "$ANS_ALL" == "n" ]]
            then
                ANS="n"
            else
                echo "--------------------------------------"
                echo "SIMS on $host are as follows"
                echo "--------------------------------------"
                for sim in `echo $SIMLIST`
                do
                    echo "$sim"
                done
                echo "--------------------------------------"

                echo "QUERY: Would you like to KEEP any of the SIMS listed above for $host, upper case Y states Y for all, y means yes you want to keep some, n means no to keep any (y/Y/n)"
                echo -e "INPUT: \c"   
                read ANS
            fi

            if [ "$ANS" = "n" ]
            then
                eval $NETSIM_DELETE_LIST=\"$SIMLIST\"
            else
                if [[ $ANS != "Y" ]]
                then
                    for sim in `echo $SIMLIST`
                    do
                        echo "QUERY: Do you wish to keep $sim on $host"
                        echo -e "INPUT: \c"
                        read ANS

                        if [ "$ANS" = "n" ]
                        then
                            eval $NETSIM_DELETE_LIST=\"\$$NETSIM_DELETE_LIST $sim\"
                        fi
                    done
                fi
            fi
        fi

    done

    # Now delete the sims
    for host in `echo $NETSIMSERVERLIST`
    do
        #eval echo "SIMs to be deleted on $host are \$${host}_sim_delete_list"
        for sim in `eval echo \\$${host}_sim_delete_list`
        do
            echo "Deleting sim $sim on $host in parallel"
        done
    done
else
    echo "INFO: No sims to delete"
fi
