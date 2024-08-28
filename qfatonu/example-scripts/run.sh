#!/bin/bash
#
#
# Name    : rollout.sh
# Written : Shane Kelly
# Date    : 10/03/10
# Purpose : NETSim Rollout
#
#
# ********************************************************************
#
#       ERROR CODE DEFINITION
#
# ********************************************************************
# ERROR
# CODE  EXPLANATION
#

# ********************************************************************
#
#       Command Section
#
# ********************************************************************
ALL_COMMAND_ARGUMENTS=$@
AWK=/bin/awk
BASENAME=/bin/basename
CAT=/bin/cat
CHMOD=/usr/bin/chmod
CLEAR=/usr/bin/clear
CP=/bin/cp
CUT=/usr/bin/cut
DATE=/usr/bin/date
DIRNAME=/usr/bin/dirname
DOMAINNAME=/usr/bin/domainname
EGREP=/bin/egrep
EXPR=/usr/bin/expr
GETENT=/usr/bin/getent
GREP=/bin/grep
HEAD=/usr/bin/head
HOSTNAME=/bin/hostname
ID=/usr/bin/id
IFCONFIG=/sbin/ifconfig
LS=/bin/ls
MKDIR=/bin/mkdir
MORE=/usr/bin/more
MOUNT=/bin/mount
MV=/bin/mv
NAWK=/bin/awk
NSLOOKUP=/usr/sbin/nslookup
PING=/bin/ping
RM=/bin/rm
RCP=/usr/bin/rcp
RSH="/usr/bin/rsh -K"
SED=/usr/bin/sed
SLEEP=/bin/sleep
SORT=/usr/bin/sort
TAIL=/usr/bin/tail
TELNET=/usr/bin/telnet
TOUCH=/bin/touch
TR=/usr/bin/tr
UMOUNT=/bin/umount
UNAME=/bin/uname
UNIQ=/usr/bin/uniq
WC=/usr/bin/wc
SSH="/usr/bin/ssh  -o LogLevel=QUIET -oStrictHostKeyChecking=no "
SCP="/usr/bin/scp -o LogLevel=QUIET"
RNC35_DIR="/var/www/html/scripts/automation_wran/subscripts/RNC35"

# *************************************************
#	Some clean up due to wgets
#
## ekemark: Commenting out due to addition of -O - in wget
###rm -rf /var/www/html/scripts/automation_wran/Setup_rsh.php* /var/www/html/scripts/automation_wran/installnetsim.php*
#
# *************************************************

# ********************************************************************
#
#       Variable Definition
#
# ********************************************************************
SCRIPTHOST=atrclin3
SCRIPTDIR=/var/www/html/scripts/automation_wran
MOUNTPOINT=/mnt
CONFIGFILE=/var/www/html/scripts/automation_wran/config.cfg
FTPSERVER=ftp.athtem.eei.ericsson.se
FTPUSER=simguest
FTPPASSWD=simguest
NETSIMSHELL=/netsim/inst/netsim_shell
DATE=`date +\%d\%m\%y-%H.%M.%S`

# Parallel related variables
processes_remaining_last=999
parallel_pids=""
parallel_strings=()
parallel_logs=()

### Function: ctrl_c ###
#
#   Traps ctrl_c and exits
#
# Arguments:
#       none
# Return Values:
#       none
ctrl_c()
{
    echo -e "\nERROR: CTRL-C detected. Do you wish to exit (y/n)?"
    echo -e "INPUT: \c"
    read ANS
    if [ "$ANS" = "y" ]
    then
        echo "INFO: Script exiting due to CTRL-C"
        exit_routine 50
    fi
}

### Function: usage_msg ###
#
#   Print out the usage message
#
# Arguments:
#       none
# Return Values:
#       none
usage_msg()
{
    if [[ $ROLLOUT == "GRAN" ]]
    then
        echo "
        Usage: rollout.sh  [ -u USERID ] [ -a SECURITY ] [ -s oss_server_name | -n netsim_server_name ] [-d deployment] [ -c config file ] [ -z y_n_use_new_functions ] [ -f function ] [ -i interaction ]
        arne_delete         delete all xmls on oss server (Tracing is ON)
        arne_dump           Dump the CS once import is finished
        arne_import         import all xmls on oss server (Tracing is ON)
        arne_validate           validate all xmls on oss server
        check_installed_patches     checks netsim patches
        check_netsim_version        displays netsim version
        check_ssh_setup         Check ssh
        create_users_gran       Create users
        cstest_all          Show all imported nodes on OSS
        cstest_ftp          cstest retrieve list of ftp services
        cstest_me           cstest retrieve node info
        delete_sim          You can delete specific sims
        delete_users            Delete Users
        free_vips_gran          Show free VIP's
        generate_arne           generate arne V2 files
        get_sims_gran           Download Sims fro ftp server
        install_netsim          installs netsim
        install_patch           install a netsim patch
        lanswitch_acl           Special config for LANSWITCH's
        login_banner            sets up login banner on netsim
        make_destination        Create Default Destination
        make_ports_gran         Create Ports
        rename_all          Renames all types of nodes
        rename_BSC
        rename_FW
        rename_LANS
        rename_ML
        rename_MLPPP
        rename_MSC
        rename_MSCS_APG
        rename_MSCS_CP
        rename_MSCS_IS
        rename_MSCS_SPX
        rename_MSCS_TSC
        rename_PICO
        rename_RTS
        rename_SDN
        rename_SIU
        rename_SPNOVA
        restart_arne_mcs            Restarts the arne related mcs
        restart_netsim          restart netsim
        restart_relay           restart netsim relay
        set_cpus            Config netsim with CPU's
        set_ips_gran            Setups VIP's for nodes
        setup_bsc_gprs          Extra user cmd directories
        setup_msc_smia          Extra user cmd directories
        setup_msc_smo           Extra user cmd directories
        setup_rsh           Setup rsh on netsim
        ssh_connection          setup atrclin3 ssh key on chosen OSS server
        start_adjust_maf        Sync nodes to Seg_CS
        start_netsim            start netsim
        stop_netsim
        tgid_gran           RBS6000
        upload_arne         uplaod arne files
        upload_tgid_gran        RBS6000
        restart_arne_mcs        Restart MC's
        "

    else
        echo "
        Usage: rollout.sh  [ -u USERID ] [ -a SECURITY ] [ -s oss_server_name | -n netsim_server_name ] [-d deployment] [ -c config file ] [ -z y_n_use_new_functions ] [ -f function ] [ -i interaction ]

        -u : Ericsson User ID
        -c : config file (Optional, if not specified, script will use file $CONFIGFILE)

        -d : deployment eg -d cominf	  
        -a : security (eg NPT or cominf)

        -s : This is the hostname of the OSS server you wish to perform rollout for.
        -n : This is the hostname of the NETSim server you wish to perform rollout for.

        -f : This is if you wish to run 1 function of the script singly.
        -i : Delete sims y/n - No prompt for Keep simulations will be displayed if set - set to n
        -o : OFFSET - ip offset - Keep existing sims + use availbale subnets only
        eg -o 4 - rollout will ignore the first 4 subnets or 1000 ipaddress
        -g : Apply a filter to SIMLIST - eg -g RNC04 (just run against RNC04)
        -r : Network Type - GRAN if necessary
        -z : Use -z y to use the new parallel version of some functions which are faster

        Supported functions are:
        check_os_details
        rollout_preroll
        make_ports
        get_sims
        set_ips
        set_security
        deploy_amos_and_c
        start_all
        stop_all
        create_scanners
        delete_scanners
        setup_variables
        save_and_compress
        create_users
        copy_config_file_to_netsim
        generate_ip_map
        save_config
        login_banner       sets up login banner on netsim
        ######### Standalone Functions ##################
        arne_delete        delete all xmls on oss server (Tracing is ON)
        arne_dump          Dump the CS once import is finished
        arne_import        import all xmls on oss server (Tracing is ON)
        arne_validate      validate all xmls on oss server
        cello_ping         cello ping nodes directly from the oss
        check_installed_patches    checks netsim patches
        check_mims         retrieve mim list from OSS
        check_netsim_version   displays netsim version
        check_pm           Verifies that pm is setup correctly
        check_relay        Checks if the netsim relay is started or not
        check_security_level   Checks security level mo
        create_pem_files       create the .pem files needed for rollout
        cstest_all         Show all imported nodes on OSS
        cstest_ftp         cstest retrieve list of ftp services
        cstest_me          cstest retrieve node info
        delete_sim         You can delete specific sims
        disable_security       disable L2 security
        generate_arne      generate arne V2 files
        install_netsim     installs netsim
        install_patch      install a netsim patch
        pm_rollout         full pm rollout
        post_scripts       a few extra settings
        reboot_host     reboots the netsim machine
        restart_arne_mcs           Restarts the arne related mcs
        restart_netsim     restart netsim
        restart_relay      restart netsim relay
        set_security_level_2   sets various mos on netsim
        setup_rsh          Setup rsh on netsim
        show_started       Show started nodes
        show_subnets_wran      show all ipaddress on netsim
        sim_summary_wran       sim summary
        ssh_connection         setup atrclin3 ssh key on chosen OSS server
        start_adjust_maf       Sync nodes to Seg_CS
        start_netsim       start netsim
        upload_arne        uplaod arne files
        upload_ip_map      upload amos file

        ######### Security Related Functions ##################
        setup_external_ssh  Enables external ssh
        set_security_MO_sl1
        set_security_MO_sl2
        disable_chrooted
        upload_pems_sl2

        setup_sl3_phase1   Sets up internal ssh and enables chrooted environment
        - setup_internal_ssh Enables internal ssh
        - enable_chrooted    Enables chrooted environment

        setup_sl3_phase2   Uploads pems, sets security definitions / caas IP / sl3 mos.
        - upload_pems_sl3
        - set_security_definitions_sl3
        - set_caas_ip
        - set_security_MO_sl3
        - show_security_status
        "
    fi
}



### Function: check_args ###
#
#   Checks Arguments
#
# Arguments:
#       none
# Return Values:
#       none
check_args()
{
    #if [ -z "$SERVER" ] && [ -z "$NETSIMSERVER" ]
    if [ -z "$SERVER" ]
    then
        #Exception if -f history is run
        if [[ $FUNCTIONS == "history" ]]
        then
            history
            exit 1
        else

            echo "ERROR: You must specify either OSS Server -s or NETSim Server -n"
            usage_msg
            exit 1
        fi
    elif [ -n "$SERVER" ] && [ -z "$NETSIMSERVER"  ]
    then
        HOST=$SERVER
        echo "INFO: Server is $HOST"
    elif [ -z "$SERVER" ] && [ -n "$NETSIMSERVER"  ]
    then
        HOST=$NETSIMSERVER
        echo "INFO: Server is $HOST"
    elif [ -n "$SERVER" ] && [ -n "$NETSIMSERVER"  ]
    then
        HOST=$NETSIMSERVER
        echo "INFO: Server is $HOST"
    fi

    if [ -z "$SECURITY" ]
    then
        echo "WARNING: Security (-a) not set, Script might exit... "
        #SECURITY="Standard"
    else
        echo $SECURITY | $EGREP "^standard|^cominf$|^npt$|^atrc|^Akita|^aty|none" >> /dev/null
        TEST=`echo $?`
        if [ $TEST -ne 0 ]
        then
            echo "ERROR: You must specify a supported security -a cominf,  -a npt, -a atrcusXXX"
            usage_msg	
            exit 1
        else
            echo "INFO: Security is $SECURITY"
        fi
    fi

    if [ -z "$DEPLOYMENT" ]
    then
        echo "INFO: Standard deployment chosen"
        DEPLOYMENT="Standard"
    else
        echo $DEPLOYMENT | $EGREP -i "^cominf$" >> /dev/null
        TEST=`echo $?`
        if [ $TEST -ne 0 ]
        then
            echo "ERROR: You must specify a supported deployment -d cominf"
            usage_msg	
            exit 1
        else
            echo "INFO: Deployment is $DEPLOYMENT"
        fi
    fi

    #ejershe
    if [ -n "$INTERACTION" ]
    then
        echo "INFO: Interaction set to $INTERACTION "
        if [ -n "$NODEFILTER" ]
        then
            echo "ERROR: You cannot set -i and -g simultaneously"
            exit_routine 1
        fi
    else
        echo "INFO: Setting interaction to y"
        INTERACTION="y"
    fi


    echo "QUERY: Is the above configuration correct? (y/n)"
    if [[ $INTERACTION == "y" ]]
    then
        echo -e "INPUT: \c"
        read ANS
        if [ "$ANS" != "y" ]
        then
            echo "INFO: Script exiting, please run again with correct configuration"
            exit 5
        fi
    else
        echo "INFO: Interaction Set to NO, Default answer here is (y)"
    fi

    #ejershe - ip subnet OFFSET
    if [ -n "$OFFSET" ]
    then
        echo "INFO: IP OFFSET is set to $OFFSET"
    fi

    if [ -n "$USERID" ]
    then
        echo "INFO: USERID set to $USERID"
    else
        echo "ERROR: You must specify an Ericsson USER ID "
        exit 1

    fi

    #ekemark
    if [ "$NEWER_FUNCTIONS" == "y" ]
    then
        echo "INFO: Using newer function versions"
    fi

    if [[ $FUNCTIONS == "" ]]
    then
        if [[ $SECURITY == "" ]]
        then

            echo "ERROR: Security (-a) must be set when doing a FULL rollout... Exiting"
            exit_routine 1
        fi
    fi

    #############################################
    # ekemark, log output to logfile and to screen
    #############################################
    SCRIPT_LOGFILE=/var/www/html/scripts/automation_wran/logs/${USERID}_${SERVER}_${DATE}.log
    echo "INFO: Logging output to $SCRIPT_LOGFILE"
    npipe=/tmp/$$.tmp
    mknod $npipe p
    tee <$npipe $SCRIPT_LOGFILE &
    exec 1>&- 2>&-
    exec 1>$npipe 2>$npipe
    disown %-
    #############################################

    echo "Command Run: $0 $ALL_COMMAND_ARGUMENTS"
}


### Function: check_config_file ###
#
#   Perform Check config file
#
# Arguments:
#       none
# Return Values:
#       none
check_config_file()
{

    if [ -n "$CONFIGFILEARG" ]
    then
        echo "INFO: Using config file from argument $CONFIGFILEARG"
        CONFIGFILE=$CONFIGFILEARG
    fi

    echo "INFO: Check if config file exists"
    if [ -f $CONFIGFILE ]
    then
        echo "INFO: Config File $CONFIGFILE Found"
    else
        echo "ERROR: Cannot find Config File $CONFIGFILE. Please investigate. Exiting"
        exit_routine 5
    fi    
}

### Function: get_netsim_servers ###
#
#   Perform Get Netsim servers from config file
#
# Arguments:
#       none
# Return Values:
#       none
get_netsim_servers()
{
    if [ -z "$NETSIMSERVER" ]
    then
        echo "INFO: Getting list of NETSims for $HOST"
        NETSIMSERVERLIST=`$EGREP "^SERVERS=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        if [ -z "$NETSIMSERVERLIST" ]; then
            echo "ERROR: No Netsim Servers found in $CONFIGFILE. Exiting"
            exit 7
        else
            NETSIMSERVERCOUNT=0
            for host in `echo $NETSIMSERVERLIST`
            do
                NETSIMSERVERCOUNT=`expr $NETSIMSERVERCOUNT + 1`
                echo "INFO: Netsim Servers for $HOST is $host"
            done
            if [ $NETSIMSERVERCOUNT -gt 1 ]
            then
                echo "INFO: This script will run some functions sequentially for netsim servers $NETSIMSERVERLIST"
                echo "INFO: This will take much longer than running them simultaneously"
                for host in `echo $NETSIMSERVERLIST`
                do
                    echo "INFO: For example run.sh -n $host -a $SECURITY"
                done
                echo "QUERY: Do you wish to continue? (y/n)"
                echo -e "INPUT: USER INTERACTION DISABLED"
                #echo -e "INPUT: USER INTERACTION DISABLED\c"
                if [[ $INTERACTION == "y" ]]
                then
                    #read ANS
                    ANS="y"
                    if [ "$ANS" != "y" ]
                    then
                        echo "INFO: Script exiting, please run again with using netsim server as argument"
                        exit 8
                    fi

                else
                    echo "INFO: Interaction Set to NO, Default answer here is (y)"
                fi
            fi
        fi
    else
        LISTTEST=`$EGREP "^SERVERS=" $CONFIGFILE | $AWK -F\" '{print $2}'`
        if [ -n "$LISTTEST" ]
        then
            echo "INFO: Using $HOST as netsim list"
            NETSIMSERVERLIST=$NETSIMSERVER	
        else
            echo "ERROR: $NETSIMSERVER Not found in config file $CONFIGFILE" 
        fi
    fi

    DEPLOYMENT=`echo $DEPLOYMENT | $TR "[:upper:]" "[:lower:]"` 
    if [ "$DEPLOYMENT" = "cominf" ]
    then
        TEMPLIST="$NETSIMSERVERLIST"
        NETSIMSERVERLIST=""
        for host in `echo $TEMPLIST`
        do
            NETSIMSERVERLIST="$NETSIMSERVERLIST ${host}-inst"
        done
    fi
}

### Function: set_parallel_variables ###
#
#   Sets parallel variables and arrays per parallel process for use in parallel_status and parallel_wait functions
#
# Arguments:
#       none
# Return Values:
#       none

set_parallel_variables()
{
    last_pid="$!"
    parallel_pids="$parallel_pids $last_pid"
    parallel_strings[$last_pid]="$PARALLEL_STATUS_STRING"
    parallel_logs[$last_pid]="$LOG_FILE"
}

### Function: reset_parallel_variables ###
#
#   Resets parallel variables and arrays for use in parallel_status and parallel_wait functions
#
# Arguments:
#       none
# Return Values:
#       none

reset_parallel_variables ()
{
    processes_remaining_last=999
    parallel_pids=""
    parallel_strings=()
    parallel_logs=()
    LOG_FILE=""
    PARALLEL_STATUS_STRING=""
    SHOW_STATUS_UPDATES="YES"
    SHOW_OUTPUT_BORDERS="YES"
    PARALLEL_STATUS_HEADER=""
}
### Function: parallel_status ###
#
#   Used in proceses to check status of parallel proceses
#
# Arguments:
#       none
# Return Values:
#       none
parallel_status() {
    set $parallel_pids

    for pid in "$@"; do
        shift
        if kill -0 "$pid" 2>/dev/null; then
            set -- "$@" "$pid"
        fi
    done
    processes_remaining_now="$#"

    if [[ $processes_remaining_last -ne $processes_remaining_now ]]
    then

        output=$(
        set $parallel_pids

        echo "                                                                                            |"
        echo "                  |================================================================|        |"
        echo "                  | Parallel Status: $PARALLEL_STATUS_HEADER"
        echo "                  |----------------------------------------------------------------|        |"
        echo "                  |                                                                |        |"
        echo "                __|                                                                |________|"
        echo "               |"

        for pid in "$@"; do
            shift
            if kill -0 "$pid" 2>/dev/null; then
                echo "               | INFO:  ${parallel_strings[$pid]}: Running (Temp logfile ${parallel_logs[$pid]} )"
                set -- "$@" "$pid"
            else
                wait "$pid"
                EXIT_CODE="$?"
                if [[ $EXIT_CODE -eq 0 ]]
                then
                    echo "               | INFO:  ${parallel_strings[$pid]}: Completed"
                else
                    echo "               | ERROR: ${parallel_strings[$pid]}: Completed with exit code $EXIT_CODE, please check"
                fi
            fi
        done
        echo "               |__                                                                  ________"
        echo "                  |                                                                |        |"
        echo "                  |                                                                |        |"
        echo "                  |----------------------------------------------------------------|        |"
        echo "                  | Parallel Summary: Processes Remaining: $processes_remaining_now                       |        |"
        echo "                  |================================================================|        |"
        echo "                                                                                            |"
        )
        echo "$output"
    fi
    processes_remaining_last="$#"
}
### Function: parallel_finish ###
#
#   Used in functions to finish off a paralle process, output its logfile, retrieve its return code etc
#
# Arguments:
#       none
# Return Values:
#       none

parallel_finish()
{
    PARALLEL_EXIT_CODE="$?"

    output=$(
    if [[ "$SHOW_OUTPUT_BORDERS" != "NO" ]]
    then
        echo "                                                                                            |"
        echo "    |==============================================================================|        |"
        echo "    | Start Of Output For: $PARALLEL_STATUS_STRING"
        echo "    |------------------------------------------------------------------------------|        |"
        echo "    |                                                                              |        |"
        echo "____|                                                                              |________|"
        echo ""
    fi
    cat "$LOG_FILE"
    if [[ "$SHOW_OUTPUT_BORDERS" != "NO" ]]
    then
        echo "____                                                                                ________"
        echo "    |                                                                              |        |"
        echo "    |                                                                              |        |"
        echo "    |------------------------------------------------------------------------------|        |"
        echo "    | End Of Output For: $PARALLEL_STATUS_STRING"
        echo "    |==============================================================================|        |"
        echo "                                                                                            |"
    fi
    )
    echo "$output"
    rm $LOG_FILE
    exit "$PARALLEL_EXIT_CODE"
}

### Function: parallel_wait ###
#
#   Used in functions to wait for parallel processes to finish
#
# Arguments:
#       none
# Return Values:
#       none

parallel_wait() {
    if [[ "$SHOW_STATUS_UPDATES" != "NO" ]]
    then
        output=$(
        echo ""
        echo "  |==============================================================================================|"
        echo "  | Starting Parallel Processes: $PARALLEL_STATUS_HEADER"
        echo "  |----------------------------------------------------------------------------------------------|"
        echo "  |                                                                                              |"
        echo "__|                                                                                          ____|"
        echo "                                                                                            |"
        )
        echo "$output"
        parallel_status
    fi
    set $parallel_pids
    while :; do
        #echo "Processes remaining: $#"
        for pid in "$@"; do
            #       echo "Checking on $pid"
            shift
            if kill -0 "$pid" 2>/dev/null; then
                #         echo "$pid is still running"
                set -- "$@" "$pid"
            else
                # A process just finished, print out the parallel status
                if [[ "$SHOW_STATUS_UPDATES" != "NO" ]]
                then
                    parallel_status
                fi
            fi
        done
        if [[ "$#" == 0 ]]
        then
            break
        fi
        sleep 1
    done

    if [[ "$SHOW_STATUS_UPDATES" != "NO" ]]
    then
        output=$(
        echo "__                                                                                          |____"
        echo "  |                                                                                              |"
        echo "  |                                                                                              |"
        echo "  |----------------------------------------------------------------------------------------------|"
        echo "  | Completed Parallel Processes: $PARALLEL_STATUS_HEADER"
        echo "  |==============================================================================================|"
        echo ""
        echo ""
        )
        echo "$output"
    fi

    # Exit script if one of the processes had a non 0 return code

    set $parallel_pids
    while :; do
        for pid in "$@"; do
            #       echo "Checking on $pid"
            shift
            if kill -0 "$pid" 2>/dev/null; then
                #         echo "$pid is still running"
                set -- "$@" "$pid"
            else
                # A process just finished, print out the parallel status
                wait "$pid"
                EXIT_CODE="$?"
                if [[ $EXIT_CODE -ne 0 ]]
                then
                    echo "INFO: At least one of the parallel processes ended with non 0 exit code, exiting script"
                    exit_routine $EXIT_CODE
                fi
            fi
        done
        if [[ "$#" == 0 ]]
        then
            break
        fi
        sleep 1
    done
    reset_parallel_variables


}

### Function: mount_scripts_directory ###
#
#   check server is alive, can be rsh'ed to and mounts scripts directory
#
# Arguments:
#       none
# Return Values:
#       none
mount_scripts_directory()
{

    for netsimserver in `echo $NETSIMSERVERLIST`
    do
        echo "INFO: Pinging $netsimserver"
        $PING -c 2 $netsimserver >> /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "INFO: $netsimserver is alive"
            echo "INFO: Checking rsh to $netsimserver"
            RSHTEST=`$RSH $netsimserver "/bin/ls / | $GREP etc"`
            echo $RSHTEST | $GREP etc >> /dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo "INFO: Rsh not working to $netsimserver, trying to test and setup rsh for all netsims now"
                setup_rsh
            else
                echo "INFO: $netsimserver trusts me"
            fi 
        else
            echo "ERROR: $netsimserver is not alive. Exiting"
            exit 2
        fi

        echo "INFO: Checking if $netsimserver is Linux"
        OSTEST=`$RSH -n $netsimserver "$UNAME" | $GREP Linux`
        if [ "$OSTEST" != "Linux" ]
        then
            echo "ERROR: $netsimserver is not Linux. Exiting."
            exit_routine 13
        fi
        echo "INFO: $netsimserver is a Linux server"
        echo "INFO: Backing up /etc/exports on `hostname`"
        $CP /etc/exports /etc/exports.$DATE
        NETSIMSERVERIP=`$GETENT hosts $netsimserver | $AWK '{print $1}'`
        if [[ $NETSIMSERVERIP == "" ]]
        then
            echo "ERROR: $netsimserver does not appear to be in DNS"
            exit_routine 1
        fi

        echo "INFO: Adding $netsimserver to /etc/exports"
        echo "$SCRIPTDIR $NETSIMSERVERIP(no_root_squash,rw,sync)" >> /etc/exports

        #DEBUG for canada rollout ejershe
        #cat /etc/exports
    done

    echo "INFO: Pick up new shares `hostname`"
    exportfs -r > /dev/null

    for netsimserver in `echo $NETSIMSERVERLIST`
    do  
        echo "INFO: Checking mountpoints for $netsimserver"
        $RSH $netsimserver "$MOUNT -w $SCRIPTHOST:$SCRIPTDIR $MOUNTPOINT" > /dev/null
        RSHTEST=`$RSH $netsimserver "/bin/ls $MOUNTPOINT | $GREP config.cfg"`
        echo $RSHTEST | $GREP config.cfg >> /dev/null 2>&1
        if [ $? -eq 0 ];then
            echo "INFO: $netsimserver Found scripts on $SCRIPTHOST"
        else
            echo "ERROR: $netsimserver Cannot find scripts on $SCRIPTHOST..Exiting"
            exit_routine 4
        fi
        $RSH $netsimserver "/bin/touch $MOUNTPOINT/touchtest.$$" > /dev/null
        RSHTEST=`$RSH $netsimserver "/bin/ls $MOUNTPOINT | $GREP touchtest.$$"`
        echo $RSHTEST | $GREP touchtest.$$ >> /dev/null 2>&1
        if [ $? -eq 0 ];then
            echo "INFO: $netsimserver has write access to $MOUNTPOINT"
            $RSH $netsimserver "$RM $MOUNTPOINT/touchtest.$$" > /dev/null
        else
            echo "ERROR: $netsimserver cannot write to /mnt. Exiting"
            exit_routine 4
        fi
    done
}

### Function: check_os_details ###
#
#   Check if OS is SuSe and when it was installed  
#
# Arguments:
#       none
# Return Values:
#       none
check_os_details()
{
    for host in `echo $NETSIMSERVERLIST`
    do
        TESTHOSTNAME=`$RSH $host "$HOSTNAME" |$GREP -vi Display`
        if [ "$TESTHOSTNAME" != "$host" ]
        then
            if [ "${TESTHOSTNAME}-inst" != "$host" ]
            then
                echo "ERROR: System hostname $TESTHOSTNAME does not match config file hostname $host"
                #exit_routine 2
            fi
        fi
        TESTSUSE=`$RSH $host "$CAT /etc/issue | $GREP -i SUSE" |$GREP -vi Display`
        if [ -n "$TESTSUSE" ]
        then
            $RSH $host "/mnt/support/check_os_details.sh $host" | $GREP -vi Display
        else
            echo "ERROR: $host is not SUSE"
            exit_routine 2
        fi
    done
    #echo "QUERY: Does the above information satisfy requirements? (y/n)"
    #INTERACTION="n"
    #echo -e "INPUT: \c"

    #	if [[ $INTERACTION == "y" ]] 
    #	then
    #		read ANS
    #		if [ "$ANS" != "y" ]
    #		then
    #  			exit_routine 2	    
    #		fi
    #	else
    #		echo "INFO: Interaction Set to NO, Default answer here is (y)"	
    #	fi
    echo "INFO: OS requirements OK"
}

### Function: rollout_preroll ###
#
#   Perform Pre Rollount
#
# Arguments:
#       none
# Return Values:
#       none
rollout_preroll()
{
    if [[ "$NEWER_FUNCTIONS" == "y" ]]
    then
        rollout_preroll_v3
        return
    fi

    for host in `echo $NETSIMSERVERLIST`
    do

        BACKUPDIR="$MOUNTPOINT/savedconfigs/$host/$DATE/existingsims"
        #NUMBEROFVERSIONS=`$EGREP "^simulationName" $CONFIGFILE | $EGREP ":${host}:" | $AWK -F: '{print $3}' | $UNIQ|$WC -l`
        #if [ $NUMBEROFVERSIONS -ne 1 ]
        #then
        #echo "ERROR: More than one version of NETSim defined for NETSim $host. Exiting"
        #exit_routine 6
        #fi
        #NETSIMREQUIREDVERSION=`$EGREP "^simulationName" $CONFIGFILE | $EGREP ":${host}:" | $AWK -F: '{print $19}' | $UNIQ`
        #echo "INFO: Checking version of NETSim installed on $host"
        #NETSIMINSTALLED=`rsh $host "/mnt/support/check_version.sh $host $NETSIMREQUIREDVERSION| $GREP Script_Success_Yes"`
        #if [ "$NETSIMINSTALLED" = "Script_Success_Yes"  ]
        #then
        #echo "INFO: Correct version of NETSim installed on NETSim $host"
        #else
        #    echo "ERROR: NETSim Version problem on $host. Exiting."
        #exit_routine 6
        #fi


        echo "INFO: Checking what simulations are on $host"
        #echo "INFO: Command $RSH -l netsim $host \" ls /netsim/netsimdir | $GREP -v default | $GREP -v exported_items | $GREP -v indexlogfile | $GREP -v logfiles | $GREP -v mmlscripts | $GREP -v mmltest | $GREP -v tmp | $GREP -v user_cmds | $GREP -v .sh | $GREP -v mpfg\" | $GREP -E '(RNC|LTE)"
        SIMLIST=`$RSH -l netsim $host " ls /netsim/netsimdir | $GREP -v default | $GREP -v exported_items | $GREP -v indexlogfile | $GREP -v logfiles | $GREP -v mmlscripts | $GREP -v mmltest | $GREP -v tmp | $GREP -v user_cmds | $GREP -v .sh | $GREP -v mpfg" | $GREP -E '(RNC|LTE|DOG)'`	

        if [ -n "$SIMLIST" ]
        then

            for sim in `echo $SIMLIST`
            do
                echo "INFO: SIM $sim on $host exists"	
            done
            echo "QUERY: Would you like to KEEP any of the SIMS listed upper case Y states Y for all (y/Y/n)"
            echo -e "INPUT: \c"
            if [[ $INTERACTION == "y" ]]
            then

                read ANS
            else
                echo "INFO: Interaction Set to NO, Default answer here is (n)"
                ANS="n"
            fi
            if [ "$ANS" = "n" ]
            then
                for sim in `echo $SIMLIST`
                do
                    if [ -n "`echo $sim | $EGREP .zip$`" ]
                    then
                        echo "INFO: Deleting SIM $sim on $host"
                        $RSH -n -l netsim $host "echo ".delsim $sim force" | $NETSIMSHELL"
                    else
                        echo "INFO: Deleting SIM $sim on $host"
                        $RSH -n $host "/mnt/support/delete_users.sh $host $sim"
                        $RSH -n -l netsim $host "/netsim/inst/restart_gui;echo ".delsim $sim force" | $NETSIMSHELL"
                    fi
                done
            elif [ $ANS = "y" ] || [ $ANS = "Y" ]
            then
                for sim in `echo $SIMLIST`
                do
                    echo "QUERY: Do you wish to keep $sim on $host"
                    if [[ $ANS != "Y" ]]
                    then
                        echo -e "INPUT: \c"
                        read ANS
                    else
                        echo "INFO: Assuming Yes for all sims"
                        perl -e "select(undef, undef, undef, 0.1)"
                    fi
                    if [ "$ANS" = "n" ]
                    then
                        if [ -n "`echo $sim | $EGREP .zip$`" ]
                        then
                            echo "INFO: Deleting SIM $sim on $host"
                            $RSH -n -l netsim $host "/netsim/inst/restart_gui;echo ".delsim $sim force" | $NETSIMSHELL"
                        else
                            echo "INFO: Deleting SIM $sim on $host"

                            $RSH -n $host "/mnt/support/delete_users.sh $host $sim"
                            $RSH -n -l netsim $host "/netsim/inst/restart_gui;echo ".delsim $sim force" | $NETSIMSHELL"
                        fi
                    elif [ "$ANS" = "y" ]
                    then
                        if [ -n "`echo $sim | $EGREP .zip$`" ]
                        then	    	    
                            echo "INFO: Keeping $sim on $host"
                        else
                            echo "INFO: Keeping $sim on $host"
                        fi
                    fi
                done   
            fi

        else
            echo "INFO: There are no existing SIMS on $host"
        fi
    done
}

rollout_preroll_v2()
{

    for host in `echo $NETSIMSERVERLIST`
    do

        BACKUPDIR="$MOUNTPOINT/savedconfigs/$host/$DATE/existingsims"
        #NUMBEROFVERSIONS=`$EGREP "^simulationName" $CONFIGFILE | $EGREP ":${host}:" | $AWK -F: '{print $3}' | $UNIQ|$WC -l`
        #if [ $NUMBEROFVERSIONS -ne 1 ]
        #then
        #echo "ERROR: More than one version of NETSim defined for NETSim $host. Exiting"
        #exit_routine 6
        #fi
        #NETSIMREQUIREDVERSION=`$EGREP "^simulationName" $CONFIGFILE | $EGREP ":${host}:" | $AWK -F: '{print $19}' | $UNIQ`
        #echo "INFO: Checking version of NETSim installed on $host"
        #NETSIMINSTALLED=`rsh $host "/mnt/support/check_version.sh $host $NETSIMREQUIREDVERSION| $GREP Script_Success_Yes"`
        #if [ "$NETSIMINSTALLED" = "Script_Success_Yes"  ]
        #then
        #echo "INFO: Correct version of NETSim installed on NETSim $host"
        #else
        #    echo "ERROR: NETSim Version problem on $host. Exiting."
        #exit_routine 6
        #fi


        echo "INFO: Checking what simulations are on $host"
        #echo "INFO: Command $RSH -l netsim $host \" ls /netsim/netsimdir | $GREP -v default | $GREP -v exported_items | $GREP -v indexlogfile | $GREP -v logfiles | $GREP -v mmlscripts | $GREP -v mmltest | $GREP -v tmp | $GREP -v user_cmds | $GREP -v .sh | $GREP -v mpfg\" | $GREP -E '(RNC|LTE)"
        SIMLIST=`$RSH -l netsim $host " ls /netsim/netsimdir | $GREP -v default | $GREP -v exported_items | $GREP -v indexlogfile | $GREP -v logfiles | $GREP -v mmlscripts | $GREP -v mmltest | $GREP -v tmp | $GREP -v user_cmds | $GREP -v .sh | $GREP -v mpfg" | $GREP -E '(RNC|LTE|DOG)'`

        if [ -n "$SIMLIST" ]
        then

            for sim in `echo $SIMLIST`
            do
                echo "INFO: SIM $sim on $host exists"
            done
            echo "QUERY: Would you like to KEEP any of the SIMS listed upper case Y states Y for all (y/Y/n)"
            echo -e "INPUT: \c"
            if [[ $INTERACTION == "y" ]]
            then

                read ANS
            else
                echo "INFO: Interaction Set to NO, Default answer here is (n)"
                ANS="n"

            fi
            if [ "$ANS" = "n" ]
            then
                $RSH -n -l netsim $host "/netsim/inst/restart_gui"
                for sim in `echo $SIMLIST`
                do
                    ###################################
                    # Parallel variable initialization
                    ###################################
                    LOG_FILE=/tmp/${host}${sim}.$BASHPID.log
                    PARALLEL_STATUS_HEADER="Deleting Simulations on $host"
                    PARALLEL_STATUS_STRING="Deleting Simulation $sim on $host"
                    # SHOW_STATUS_UPDATES="NO"
                    SHOW_OUTPUT_BORDERS="NO"
                    ###################################
                    (
                    (
                    if [ -n "`echo $sim | $EGREP .zip$`" ]
                    then
                        echo "INFO: Deleting SIM $sim on $host"
                        output=`$RSH -n -l netsim $host "echo ".delsim $sim force" | $NETSIMSHELL"`
                    else
                        echo "INFO: Deleting SIM $sim on $host"
                        $RSH -n $host "/mnt/support/delete_users.sh $host $sim"
                        output=`$RSH -n -l netsim $host "echo ".delsim $sim force" | $NETSIMSHELL"`
                    fi
                    echo "INFO: SIM $sim is deleted"
                    ) > $LOG_FILE 2>&1;parallel_finish
                    ) & set_parallel_variables
                done
            elif [ $ANS = "y" ] || [ $ANS = "Y" ]
            then
                for sim in `echo $SIMLIST`
                do
                    echo "QUERY: Do you wish to keep $sim on $host"
                    if [[ $ANS != "Y" ]]
                    then
                        echo -e "INPUT: \c"
                        read ANS
                    else
                        echo "INFO: Assuming Yes for all sims"
                        perl -e "select(undef, undef, undef, 0.1)"
                    fi
                    if [ "$ANS" = "n" ]
                    then
                        if [ -n "`echo $sim | $EGREP .zip$`" ]
                        then
                            echo "INFO: Deleting SIM $sim on $host"
                            $RSH -n -l netsim $host "/netsim/inst/restart_gui;echo ".delsim $sim force" | $NETSIMSHELL"
                        else
                            echo "INFO: Deleting SIM $sim on $host"

                            $RSH -n $host "/mnt/support/delete_users.sh $host $sim"
                            $RSH -n -l netsim $host "/netsim/inst/restart_gui;echo ".delsim $sim force" | $NETSIMSHELL"
                        fi
                    elif [ "$ANS" = "y" ]
                    then
                        if [ -n "`echo $sim | $EGREP .zip$`" ]
                        then
                            echo "INFO: Keeping $sim on $host"
                        else
                            echo "INFO: Keeping $sim on $host"
                        fi
                    fi
                done
            fi

        else
            echo "INFO: There are no existing SIMS on $host"
        fi
    done
    parallel_wait
}

rollout_preroll_v3()
{

    # Get the list of sims on each netsim into a list

    SIMCOUNT=0

    for host in `echo $NETSIMSERVERLIST`
    do

        BACKUPDIR="$MOUNTPOINT/savedconfigs/$host/$DATE/existingsims"

        echo "INFO: Checking what simulations are on $host"
        eval ${host}_sims_list=`$RSH -l netsim $host " ls /netsim/netsimdir | $GREP -v default | $GREP -v exported_items | $GREP -v indexlogfile | $GREP -v logfiles | $GREP -v mmlscripts | $GREP -v mmltest | $GREP -v tmp | $GREP -v user_cmds | $GREP -v .sh | $GREP -v mpfg" | $GREP -E '(RNC|LTE|DOG)'`
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
            ###################################
            # Parallel variable initialization
            ###################################
            LOG_FILE=/tmp/${host}${sim}.$BASHPID.log
            PARALLEL_STATUS_HEADER="Deleting Simulations"
            PARALLEL_STATUS_STRING="Deleting Simulations on $host"
            # SHOW_STATUS_UPDATES="NO"
            # SHOW_OUTPUT_BORDERS="NO"
            ###################################
            (
            (


            # Delete the users
            if [[ "`eval echo \\$${host}_sim_delete_list`" != "" ]]
            then
                # Restart the netsim gui
                #$RSH -n -l netsim $host "/netsim/inst/restart_gui"

                # Delete the users
                for sim in `eval echo \\$${host}_sim_delete_list`
                do
                    if [[ ! -n "`echo $sim | $EGREP .zip$`" ]]
                    then
                        echo "INFO: Deleting users for $sim on $host"
                        $RSH -n $host "/mnt/support/delete_users.sh $host $sim"
                    fi
                done

                # Delete the sims
                list_formatted=`eval echo \\$${host}_sim_delete_list | sed 's/ /|/g'`
                $RSH -n -l netsim $host "echo \".delsim $list_formatted force\" | $NETSIMSHELL"
            else
                echo "Nothing to delete for $host"
            fi
            ) > $LOG_FILE 2>&1;parallel_finish
            ) & set_parallel_variables

        done
        parallel_wait
    fi

}
### Function: make_ports ###
#
#   Make NETsim Ports
#
# Arguments:
#       none
# Return Values:
#       none
make_ports()
{
    for host in `echo $NETSIMSERVERLIST`
    do
        echo "INFO: Setting NETSimPort on $host"
        $RSH -l netsim $host "/mnt/support/make_ports.sh | $NETSIMSHELL" | $GREP -v "DISPLAY"
        #echo "INFO: NETSim Port created on $host"
        PORT_CHECK=`$RSH -l netsim $host "/mnt/support/check_port.sh $NETSIMSHELL"`
        if [[ $PORT_CHECK == "ERROR" ]]
        then
            echo "ERROR: NetSimPort not created on $host"
            exit_routine 1
        else
            echo "INFO: Port creation on $host seems to be sucessfull"
        fi
    done
}

### Function: get_sims ###
#
#   Get Simulations from FTP area uncompress and open
#
# Arguments:
#       none
# Return Values:
#       none
get_sims()
{
    if [[ "$NEWER_FUNCTIONS" == "y" ]]
    then
        get_sims_v2
        return
    fi
    for host in `echo $NETSIMSERVERLIST`
    do

        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        for SIMNAME in `echo $SIMLIST`
        do
            RNCSIM=""
            RNCSIM=`echo $SIMNAME | $EGREP "^RNC"`
            LTESIM=""
            LTESIM=`echo $SIMNAME | $EGREP "^LTE"`
            if [ -n "$RNCSIM" ]
            then
                SIMSTR=WRAN_SIMDIR 
            fi
            if [ -n "$LTESIM" ]
            then
                SIMSTR=LTE_SIMDIR 
            fi
            if [ -n "$LTESIM" ] && [ -n "$RNCSIM" ]
            then
                SIMSTR=SIMDIR
            fi
            SIMDIRTEST=`$EGREP "^$SIMSTR=" $CONFIGFILE | $AWK -F= '{print $2}'`
            if [ -z "$SIMDIRTEST" ]
            then
                echo "ERROR: SIMDIR $SIMSTR not defined in $CONFIGFILE. Exiting."
                exit_routine 10
            else
                SIMDIR=$SIMDIRTEST
            fi
            SIMSERVERTEST=`$EGREP "^SIMSERVER=" $CONFIGFILE | $AWK -F= '{print $2}'`
            if [ -z "$SIMSERVERTEST" ]
            then
                echo "ERROR: ftp SIMSERVER not defined in $CONFIGFILE. Exiting."
                exit_routine 10
            else
                SIMSERVER=$SIMSERVERTEST
            fi
            MIMTEST=`$EGREP "^${SIMNAME}_mimtype=" $CONFIGFILE | $AWK -F= '{print $2}'`
            if [ -z "$MIMTEST" ] 
            then
                MIMTEST=N
                echo "INFO: MIMTYPE is not set N or N_* so setting to \"N\""
                LTETEST=`echo $SIMNAME | grep LTE`
                if [ -n "$LTETEST" ]
                then
                    echo "INFO: SIM is LTE so setting to \".\""
                    MIMTYPE="."
                else
                    MIMTYPE=$MIMTEST
                fi
                #TDTEST=`echo $SIMNAME | $EGREP "^TD"`
                #if [ -n "$TDTEST" ]
                #then
                #	echo "INFO: SIM is TD so setting MIMTYPE to \".\""
                #	MIMTYPE="."
                #else
                #	MIMTYPE=$MIMTEST
                #fi
            else
                LTETEST=`echo $SIMNAME | grep LTE`
                if [ -n "$LTETEST" ]
                then
                    echo "INFO: SIM is TD so setting MIMTYPE to \".\""
                    MIMTYPE="."
                else
                    MIMTYPE=$MIMTEST
                fi
                #TDTEST=`echo $SIMNAME | $EGREP "^TD"`
                #if [ -n "$TDTEST" ]
                #then
                #	echo "INFO: SIM is TD so setting MIMTYPE to \".\""
                #	MIMTYPE="."
                #else
                #	MIMTYPE=$MIMTEST
                #fi
            fi
            echo "INFO: Getting Simulation $SIMNAME  - $MIMTYPE for $host from $SIMDIR/$MIMTYPE on $SIMSERVER"
            echo "INFO: Command /mnt/support/ftp_sims.sh $host $SIMNAME $MIMTYPE $SIMSERVER $SIMDIR"
            $RSH -l netsim $host "/mnt/support/ftp_sims.sh $host $SIMNAME $MIMTYPE $SIMSERVER $SIMDIR" | $GREP -v "Display"
            TEST=`$RSH -l netsim $host "ls /netsim/netsimdir | $EGREP $SIMNAME.zip" `
            if [ -z "$TEST" ]
            then
                echo "ERROR: SIM $SIMNAME not downloaded to $host. Exiting. Please investigate"
                exit_routine 10
            else
                echo "INFO: Uncompress and open $SIMNAME on $host"
                $RSH -l netsim $host "/mnt/support/uncompress_and_open.sh $host $SIMNAME | $NETSIMSHELL" | $GREP -vi Display
                echo "INFO: Uncompress and open $SIMNAME on $host complete"
            fi
        done  
    done
}

get_sims_v2()
{
    for host in `echo $NETSIMSERVERLIST`
    do

        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi



        ###################################
        # Parallel variable initialization
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Getting Simulations"
        PARALLEL_STATUS_STRING="Getting Simulations on $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (

        for SIMNAME in `echo $SIMLIST`
        do
            RNCSIM=""
            RNCSIM=`echo $SIMNAME | $EGREP "^RNC"`
            LTESIM=""
            LTESIM=`echo $SIMNAME | $EGREP "^LTE"`
            if [ -n "$RNCSIM" ]
            then
                SIMSTR=WRAN_SIMDIR
            fi
            if [ -n "$LTESIM" ]
            then
                SIMSTR=LTE_SIMDIR
            fi
            if [ -n "$LTESIM" ] && [ -n "$RNCSIM" ]
            then
                SIMSTR=SIMDIR
            fi
            SIMDIRTEST=`$EGREP "^$SIMSTR=" $CONFIGFILE | $AWK -F= '{print $2}'`
            if [ -z "$SIMDIRTEST" ]
            then
                echo "ERROR: SIMDIR $SIMSTR not defined in $CONFIGFILE. Exiting."
                exit 10
            else
                SIMDIR=$SIMDIRTEST
            fi
            SIMSERVERTEST=`$EGREP "^SIMSERVER=" $CONFIGFILE | $AWK -F= '{print $2}'`
            if [ -z "$SIMSERVERTEST" ]
            then
                echo "ERROR: ftp SIMSERVER not defined in $CONFIGFILE. Exiting."
                exit 10
            else
                SIMSERVER=$SIMSERVERTEST
            fi
            MIMTEST=`$EGREP "^${SIMNAME}_mimtype=" $CONFIGFILE | $AWK -F= '{print $2}'`
            if [ -z "$MIMTEST" ]
            then
                MIMTEST=N
                echo "INFO: MIMTYPE is not set N or N_* so setting to \"N\""
                LTETEST=`echo $SIMNAME | grep LTE`
                if [ -n "$LTETEST" ]
                then
                    echo "INFO: SIM is LTE so setting to \".\""
                    MIMTYPE="."
                else
                    MIMTYPE=$MIMTEST
                fi
                #TDTEST=`echo $SIMNAME | $EGREP "^TD"`
                #if [ -n "$TDTEST" ]
                #then
                #   echo "INFO: SIM is TD so setting MIMTYPE to \".\""
                #   MIMTYPE="."
                #else
                #   MIMTYPE=$MIMTEST
                #fi
            else
                LTETEST=`echo $SIMNAME | grep LTE`
                if [ -n "$LTETEST" ]
                then
                    echo "INFO: SIM is TD so setting MIMTYPE to \".\""
                    MIMTYPE="."
                else
                    MIMTYPE=$MIMTEST
                fi
                #TDTEST=`echo $SIMNAME | $EGREP "^TD"`
                #if [ -n "$TDTEST" ]
                #then
                #   echo "INFO: SIM is TD so setting MIMTYPE to \".\""
                #   MIMTYPE="."
                #else
                #   MIMTYPE=$MIMTEST
                #fi
            fi

            echo "INFO: Getting Simulation $SIMNAME  - $MIMTYPE for $host from $SIMDIR/$MIMTYPE on $SIMSERVER"
            echo "INFO: Command /mnt/support/ftp_sims.sh $host $SIMNAME $MIMTYPE $SIMSERVER $SIMDIR"
            $RSH -l netsim $host "/mnt/support/ftp_sims.sh $host $SIMNAME $MIMTYPE $SIMSERVER $SIMDIR" | $GREP -v "Display"
            TEST=`$RSH -l netsim $host "ls /netsim/netsimdir | $EGREP $SIMNAME.zip" `
            if [ -z "$TEST" ]
            then
                echo "ERROR: SIM $SIMNAME not downloaded to $host. Exiting. Please investigate"
                exit 10
            else
                echo "INFO: Uncompress and open $SIMNAME on $host"
                $RSH -l netsim $host "/mnt/support/uncompress_and_open.sh $host $SIMNAME | $NETSIMSHELL" | $GREP -vi Display
                echo "INFO: Uncompress and open $SIMNAME on $host complete"
            fi
        done
        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait
}

### Function: set_ips ###
#
#   Configure IP addresses on SIMS
#
# Arguments:
#       none
# Return Values:
#       none
set_ips()
{
    if [[ "$NEWER_FUNCTIONS" == "y" ]]
    then
        set_ips_v2
        return
    fi

    for host in `echo $NETSIMSERVERLIST`
    do
        TOTALIPS=`$RSH $host "$IFCONFIG -a | $GREP inet | $WC -l"`
        TOTALVIPS=`expr $TOTALIPS - 2`

        echo "INFO: Total IP address available on $host is $TOTALIPS"
        IPREQD=0

        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi



        for SIMNAME in `echo $SIMLIST`
        do	
            CELLTEST=`$EGREP "^${host}_type=" $CONFIGFILE | $AWK -F= '{print $2}'`
            if [ -z "$CELLTEST" ] 
            then
                echo "INFO: CELLTYPE is not set, so setting to \"C\""
                CELLTYPE="C"
            else
                CELLTYPE=$CELLTEST
            fi
            case "$CELLTYPE" in
                C) IPREQD=`expr $IPREQD + 250`
                    ;;
                F) IPREQD=`expr $IPREQD + 1000`
                    ;;
                \?) echo -e "ERROR: SIM $SIMNAME on $host is not supported Cell Type (C, F or LTE)"
                    exit_routine 11
                    ;;
            esac
        done

        echo "INFO: Total IPS needed to do rollout is $IPREQD before OFFSET is applied"

        #Now apply ip OFFSET to the check that was done above
        TMP_OFFSET=$OFFSET
        while [[ $TMP_OFFSET -gt 0 ]]
        do
            IPREQD=`expr $IPREQD + 250`
            TMP_OFFSET=`expr $TMP_OFFSET - 1`
        done
        echo "INFO: Total IPS needed to do rollout is $IPREQD after OFFSET is applied" 

        if [ $IPREQD -le $TOTALVIPS ]
        then
            echo "INFO: Sufficient VIPS on $host for SIMS"
        else
            echo "ERROR: Insufficient VIPS on $host for SIMS"
            exit_routine 11
        fi

        IPSUBS=`$RSH $host "/mnt/support/list_ip_subs.sh $host" | $GREP -vi Display`
        IPSUBSARRAY=()
        COUNT=1

        #If the OFFSET for ips is not set, default to 0
        if [[ -z $OFFSET ]]
        then
            OFFSET=0
        fi
        for ipsub in `echo $IPSUBS`
        do
            IPSUBSARRAY[$COUNT]=$ipsub
            COUNT=`expr $COUNT + 1`
            echo "INFO: Available Subnet is $ipsub" 
        done

        for SIMNAME in `echo $SIMLIST`
        do

            #POSITION=`echo $line | awk -F: '{print $20}'`
            IPCOUNT=1
            echo "INFO: Getting number of RNC in SIM $SIMNAME on $host"
            NOOFRNC=`$RSH -l netsim $host "/mnt/support/get_num_rnc.sh $host $SIMNAME" | $GREP -vi Display`
            echo "INFO: Getting number of RBS in SIM $SIMNAME on $host"
            NOOFRBS=`$RSH -l netsim $host "/mnt/support/get_num_rbs.sh $host $SIMNAME" | $GREP -vi Display`
            echo "INFO: Getting number of RXI in SIM $SIMNAME on $host"
            NOOFRXI=`$RSH -l netsim $host "/mnt/support/get_num_rxi.sh $host $SIMNAME" | $GREP -vi Display`
            echo "INFO: Getting number of LTE in SIM $SIMNAME on $host"
            NOOFLTE=`$RSH -l netsim $host "/mnt/support/get_num_lte.sh $host $SIMNAME" | $GREP -vi Display`
            echo "INFO: Getting number of TDRNC in SIM $SIMNAME on $host"
            NOOFTDRNC=`$RSH -l netsim $host "/mnt/support/get_num_tdrnc.sh $host $SIMNAME" | $GREP -vi Display`
            echo "INFO: Getting number of TDRBS in SIM $SIMNAME on $host"
            NOOFTDRBS=`$RSH -l netsim $host "/mnt/support/get_num_tdrbs.sh $host $SIMNAME" | $GREP -vi Display`
            echo "INFO: Getting number of TBRXI in SIM $SIMNAME on $host"
            NOOFTDRXI=`$RSH -l netsim $host "/mnt/support/get_num_tdrxi.sh $host $SIMNAME" | $GREP -vi Display`
            echo "INFO: $NOOFRNC RNCs in SIM $SIMNAME on $host"
            echo "INFO: $NOOFRBS RBSs in SIM $SIMNAME on $host"
            echo "INFO: $NOOFRXI RXIs in SIM $SIMNAME on $host"
            echo "INFO: $NOOFTDRNC TDRNCs in SIM $SIMNAME on $host"
            echo "INFO: $NOOFTDRBS TDRBSs in SIM $SIMNAME on $host"
            echo "INFO: $NOOFTDRXI TDRXIs in SIM $SIMNAME on $host"
            echo "INFO: $NOOFLTE LTEs in SIM $SIMNAME on $host"
            TOTALNODES=`expr $NOOFRNC + $NOOFRBS + $NOOFRXI + $NOOFLTE + $NOOFTDRNC + $NOOFTDRBS + $NOOFTDRXI`
            if [ $TOTALNODES -eq 0 ]
            then
                echo "ERROR: There are no nodes in SIM $SIMNAME on $host. Exiting"
                exit_routine 12
            fi
            echo "INFO: Setting up IP addresses on SIM $SIMNAME on $host"
            POSITION=`$RSH -l netsim $host "/mnt/support/get_position.sh $host $SIMNAME" | $GREP -vi Display`

            #Hack for sims already on the box and not part of rollout. ie the netsim box serves two OSS's
            #Only applied with NODEFILTER and OFFSET as arguments to run.sh
            if [[ $OFFSET != "" ]]
            then
                if [[ $NODEFILTER != "" ]]
                then
                    POSITION=`expr $OFFSET + 1`
                    echo "INFO: HACK for POSITION applied"
                    echo "INFO: Using SUBNET ${IPSUBSARRAY[$POSITION]}"	
                fi
            fi	

            $RSH -l netsim $host "/mnt/support/setup_ip.sh $host $SIMNAME $NOOFRBS $NOOFRNC $NOOFRXI $NOOFLTE $NOOFTDRNC $NOOFTDRBS $NOOFTDRXI ${IPSUBSARRAY[$POSITION]} $DATE" | $GREP -vi Display
        done
    done
}

### Function: set_security ###
#
#   Configure security on
#
# Arguments:
#       none
# Return Values:
#       none
set_security()
{
    if [[ "$NEWER_FUNCTIONS" == "y" ]]
    then
        set_security_v2
        return
    fi

    echo $SECURITY | $EGREP "^standard|^cominf$|^npt$|^atrc|^Akita|^aty" >> /dev/null
    TEST=`echo $?`
    if [ $TEST -ne 0 ]
    then
        echo "ERROR: You must specify a supported security -a cominf,  -a npt, -a atrcusXXX"
        exit 1
    else
        echo "INFO: Security is $SECURITY"
    fi

    for host in `echo $NETSIMSERVERLIST`
    do	


        #Check .pem files are not of size 0 bytes
        KEY_FILESIZE=$(stat -c%s "subscripts/security/${SECURITY}/key.pem")
        CERT_FILESIZE=$(stat -c%s "subscripts/security/${SECURITY}/certs.pem")
        CACERT_FILESIZE=$(stat -c%s "subscripts/security/${SECURITY}/cacerts.pem")
        if [[ $KEY_FILESIZE == "0" ]]
        then
            echo "ERROR: subscripts/security/${SECURITY}/key.pem is of size 0 bytes, exiting"
            exit_routine 1
        elif [[ $CERT_FILESIZE == "0" ]]
        then
            echo "ERROR: subscripts/security/${SECURITY}/certs.pem is of size 0 bytes, exiting"
            exit_routine 1

        elif [[ $CACERT_FILESIZE == "0" ]]
        then
            echo "ERROR: subscripts/security/${SECURITY}/cacerts.pem is of size 0 bytes, exiting"
            exit_routine 1

        fi



        echo "INFO: Copying pem files to $host"
        $RSH -l netsim $host "/mnt/support/copyfiles.sh $host $SECURITY"
        #LSTEST=`$RSH -l netsim $host "ls /netsim/netsim_security 2>&1 | $GREP key.pem"`
        KEYTEST=`$RSH $host "/mnt/support/check_file.sh $host blank key $SECURITY"`

        echo $KEYTEST | $GREP "OK" >> /dev/null
        if [ $? -ne 0 ]
        then
            echo "ERROR: NETSim pem files not copied"
            exit_routine 6
        fi

        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        for SIMNAME in `echo $SIMLIST`
        do
            echo "INFO: Setting Security on for SIM $SIMNAME on $host"
            $RSH -l netsim $host "/mnt/support/set_security.sh $host $SIMNAME $SECURITY | $NETSIMSHELL" | $GREP -vi Display
            echo "INFO: Security on for SIM $SIMNAME on $host"
        done    
    done
}

upload_pems_sl3 ()
{
    echo $SECURITY | $EGREP "^atrc|^Akita|^aty" >> /dev/null
    TEST=`echo $?`
    if [ $TEST -ne 0 ]
    then
        echo "ERROR: You must specify a supported security -a trcusXXX, -a atylXXX"
        exit 1
    else
        echo "INFO: Security is $SECURITY"
    fi

    for host in `echo $NETSIMSERVERLIST`
    do


        #Check .pem files are not of size 0 bytes
        KEY_FILESIZE=$(stat -c%s "subscripts/security/${SECURITY}/key.pem")
        CERT_FILESIZE=$(stat -c%s "subscripts/security/${SECURITY}/certs.pem")
        CACERT_FILESIZE=$(stat -c%s "subscripts/security/${SECURITY}/cacerts.pem")
        if [[ $KEY_FILESIZE == "0" ]]
        then
            echo "ERROR: subscripts/security/${SECURITY}/key.pem is of size 0 bytes, exiting"
            exit_routine 1
        elif [[ $CERT_FILESIZE == "0" ]]
        then
            echo "ERROR: subscripts/security/${SECURITY}/certs.pem is of size 0 bytes, exiting"
            exit_routine 1

        elif [[ $CACERT_FILESIZE == "0" ]]
        then
            echo "ERROR: subscripts/security/${SECURITY}/cacerts.pem is of size 0 bytes, exiting"
            exit_routine 1

        fi

        echo "INFO: Copying pem files to $host"
        $RSH -l netsim $host "/mnt/support/upload_pems_sl3.sh $host $SECURITY"

    done
}

upload_pems_sl2 ()
{
    echo $SECURITY | $EGREP "^standard|^cominf$|^npt$|^atrc|^Akita|^aty" >> /dev/null
    TEST=`echo $?`
    if [ $TEST -ne 0 ]
    then
        echo "ERROR: You must specify a supported security -a trcusXXX, -a atylXXX"
        exit 1
    else
        echo "INFO: Security is $SECURITY"
    fi

    for host in `echo $NETSIMSERVERLIST`
    do


        #Check .pem files are not of size 0 bytes
        KEY_FILESIZE=$(stat -c%s "subscripts/security/${SECURITY}/key.pem")
        CERT_FILESIZE=$(stat -c%s "subscripts/security/${SECURITY}/certs.pem")
        CACERT_FILESIZE=$(stat -c%s "subscripts/security/${SECURITY}/cacerts.pem")
        if [[ $KEY_FILESIZE == "0" ]]
        then
            echo "ERROR: subscripts/security/${SECURITY}/key.pem is of size 0 bytes, exiting"
            exit_routine 1
        elif [[ $CERT_FILESIZE == "0" ]]
        then
            echo "ERROR: subscripts/security/${SECURITY}/certs.pem is of size 0 bytes, exiting"
            exit_routine 1

        elif [[ $CACERT_FILESIZE == "0" ]]
        then
            echo "ERROR: subscripts/security/${SECURITY}/cacerts.pem is of size 0 bytes, exiting"
            exit_routine 1

        fi

        echo "INFO: Copying pem files to $host"
        $RSH -l netsim $host "/mnt/support/upload_pems_sl2.sh $host $SECURITY"

    done
}
### Function: set_security ###
#
#   Configure security on
#
# Arguments:
#       none
# Return Values:
#       none

set_security_v2()
{
    echo $SECURITY | $EGREP "^standard|^cominf$|^npt$|^atrc|^Akita|^aty" >> /dev/null
    TEST=`echo $?`
    if [ $TEST -ne 0 ]
    then
        echo "ERROR: You must specify a supported security -a cominf,  -a npt, -a atrcusXXX"
        exit 1
    else
        echo "INFO: Security is $SECURITY"
    fi

    #Check .pem files are not of size 0 bytes
    KEY_FILESIZE=$(stat -c%s "subscripts/security/${SECURITY}/key.pem")
    CERT_FILESIZE=$(stat -c%s "subscripts/security/${SECURITY}/certs.pem")
    CACERT_FILESIZE=$(stat -c%s "subscripts/security/${SECURITY}/cacerts.pem")
    if [[ $KEY_FILESIZE == "0" ]]
    then
        echo "ERROR: subscripts/security/${SECURITY}/key.pem is of size 0 bytes, exiting"
        exit 1
    elif [[ $CERT_FILESIZE == "0" ]]
    then
        echo "ERROR: subscripts/security/${SECURITY}/certs.pem is of size 0 bytes, exiting"
        exit 1

    elif [[ $CACERT_FILESIZE == "0" ]]
    then
        echo "ERROR: subscripts/security/${SECURITY}/cacerts.pem is of size 0 bytes, exiting"
        exit 1

    fi

    for host in `echo $NETSIMSERVERLIST`
    do

        echo "INFO: Copying pem files to $host"
        $RSH -l netsim $host "/mnt/support/copyfiles.sh $host $SECURITY"
        #LSTEST=`$RSH -l netsim $host "ls /netsim/netsim_security 2>&1 | $GREP key.pem"`
        KEYTEST=`$RSH $host "/mnt/support/check_file.sh $host blank key $SECURITY"`

        echo "$KEYTEST"
        echo $KEYTEST | $GREP "OK" >> /dev/null
        if [ $? -ne 0 ]
        then
            echo "ERROR: NETSim pem files not copied"
            exit 6
        fi

        #   Parallelized code below to start all in parallel
        ###################################
        # Parallel variable initialization
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Set Security"
        PARALLEL_STATUS_STRING="Set security on $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (

        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        for SIMNAME in `echo $SIMLIST`
        do
            echo "INFO: Setting Security on for SIM $SIMNAME on $host"
            $RSH -l netsim $host "/mnt/support/set_security_v2.sh $host $SIMNAME $SECURITY | $NETSIMSHELL" | $GREP -vi Display
            echo "INFO: Security on for SIM $SIMNAME on $host"
        done
        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait
}

#ejershe - Mos to be set for security level 2
set_security_level_2()
{
    for host in `echo $NETSIMSERVERLIST`
    do

        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        for SIMNAME in `echo $SIMLIST`
        do
            echo "INFO: Setting Security Level 2 mos  for SIM $SIMNAME on $host"
            $RSH -l netsim $host "/mnt/support/set_security_level_2_mos_v2.sh $host $SIMNAME | $NETSIMSHELL" | $GREP -vi Display
            echo "INFO: Security Level 2 mos for SIM $SIMNAME on $host are now SET"
        done
    done
}

set_caas_ip ()
{
    ssh_connection
    CAAS_IP=`$SSH root@${SERVER} "ldapclient list | grep NS_LDAP_SERVERS | awk '{print \\$2}"`
    while true
    do
        echo -n "Please enter the IP address of CAAS server ($CAAS_IP): "
        if [[ $INTERACTION == "y" ]]
        then
            read caas_input
            if [[ "$caas_input" == "" ]]
            then
                final_ip="$CAAS_IP"
            else
                final_ip="$caas_input"
            fi
        else
            echo ""
            echo "INFO: Interaction Set to NO, Default answer here is the IP obtained from the master"
            final_ip="$CAAS_IP"
        fi

        regex="\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"
        if [[ `echo "$final_ip" | $EGREP $regex` ]]
        then
            echo "CAAS IP is $final_ip"
            break
        else
            echo "INFO: $final_ip doesn't look like a valid IP address"
            if [[ $INTERACTION == "y" ]]
            then
                echo "INFO: Please retry to enter a valid IP address"
            else
                echo "ERROR: No valid caas IP was given"
                exit_routine 24
            fi
        fi
    done

    for host in `echo $NETSIMSERVERLIST`
    do
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        fi
        ###################################
        # Parallel variable initialization
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Setting caas IP"
        PARALLEL_STATUS_STRING="Setting caas IP on $host"
        #SHOW_STATUS_UPDATES="NO"
        #SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (
        for SIM in $SIMLIST
        do
            $RSH -l netsim $host "/mnt/support/set_caas_ip.sh $final_ip $SIM"
        done
        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait
}

set_security_MO ()
{
    sec_level=$1
    for host in `echo $NETSIMSERVERLIST`
    do
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        fi
        ###################################
        # Parallel variable initialization
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Setting Security MOs"
        PARALLEL_STATUS_STRING="Setting Security MOs on $host"
        #SHOW_STATUS_UPDATES="NO"
        #SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (
        for SIM in $SIMLIST
        do
            $RSH -l netsim $host "/mnt/support/set_security_MO.sh $sec_level $SIM"
        done
        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait
}
### Function: check_relay ###
#
#  Checks netsim relay on each netsim 
#
# Arguments:
#       none
# Return Values:
#       none
check_relay()
{
    echo "#####################################################"
    echo "INFO: Checking relays, please wait..."
    echo "#####################################################"
    for host in `echo $NETSIMSERVERLIST`
    do
        ###################################
        # Parallel variable initialization
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER=""
        PARALLEL_STATUS_STRING=""
        SHOW_STATUS_UPDATES="NO"
        SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (
        #echo "INFO: Checking relay on $host"
        RETURN_CODE=`$RSH -l netsim $host "/mnt/support/check_relay.sh > /dev/null 2>&1;echo \\$?"`
        if [[ "$RETURN_CODE" == "1" ]]
        then
            echo "WARNING: The relay isn't started on $host"
        else
            echo "INFO: The relay is started on $host"
        fi
        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait
    echo "#####################################################"
    echo "INFO: All relay check processes are completed."
    echo "#####################################################"
}

### Function: start_all ###
#
#   Start all SIMs
#
# Arguments:
#       none
# Return Values:
#       none
start_all()
{

    if [[ "$NEWER_FUNCTIONS" == "y" ]]
    then
        start_all_v2
        return
    fi

    for host in `echo $NETSIMSERVERLIST`
    do
        #check the relay is running
        RETURN_CODE=`$RSH -l netsim $host "/mnt/support/check_relay.sh > /dev/null 2>&1;echo \\$?"`
        if [[ "$RETURN_CODE" == "1" ]]
        then
            restart_relay
        fi

        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        for SIMNAME in `echo $SIMLIST`
        do
            echo "INFO: Starting SIM $SIMNAME on $host"
            $RSH -l netsim $host "/mnt/support/start_all.sh $host $SIMNAME | $NETSIMSHELL" 
            echo "INFO: SIM $SIMNAME started on $host"
        done
    done
}
start_all_v2()
{
    for host in `echo $NETSIMSERVERLIST`
    do
        #check the relay is running
        RETURN_CODE=`$RSH -l netsim $host "/mnt/support/check_relay.sh > /dev/null 2>&1;echo \\$?"`
        if [[ "$RETURN_CODE" == "1" ]]
        then
            restart_relay
        fi

        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        #   Parallelized code below to start all in parallel.a
        ###################################
        # Parallel variable initialization
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Starting SIMS"
        PARALLEL_STATUS_STRING="Starting SIMS on $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (

        for SIMNAME in `echo $SIMLIST`
        do
            echo "INFO: Starting SIM $SIMNAME on $host"
            $RSH -l netsim $host "/mnt/support/start_all_v2.sh $host $SIMNAME | $NETSIMSHELL"
            echo "INFO: SIM $SIMNAME started on $host"
        done

        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait
}



setup_internal_ssh()
{
    for host in `echo $NETSIMSERVERLIST`
    do

        #   Parallelized code below to start all in parallel.a
        ###################################
        # Parallel variable initialization
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Setting up internal ssh"
        PARALLEL_STATUS_STRING="Setting up internal ssh on $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (

        $RSH $host "/mnt/support/setup_internal_ssh.sh"

        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait
}

setup_external_ssh()
{
    for host in `echo $NETSIMSERVERLIST`
    do

        #   Parallelized code below to start all in parallel.a
        ###################################
        # Parallel variable initialization
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Setting up external ssh"
        PARALLEL_STATUS_STRING="Setting up external ssh on $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (

        $RSH $host "/mnt/support/setup_external_ssh.sh"

        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait
}


enable_chrooted()
{
    for host in `echo $NETSIMSERVERLIST`
    do

        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        #   Parallelized code below to start all in parallel.
        ###################################
        # Parallel variable initialization
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Enabling chrooted environments"
        PARALLEL_STATUS_STRING="Enabling chrooted environment on $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (


        for SIMNAME in `echo $SIMLIST`
        do
            $RSH -l netsim $host "/mnt/support/enable_chrooted.sh $SIMNAME"
        done
        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait

}



disable_chrooted()
{

    for host in `echo $NETSIMSERVERLIST`
    do

        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        #   Parallelized code below to start all in parallel.
        ###################################
        # Parallel variable initialization
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Disabling chrooted environments"
        PARALLEL_STATUS_STRING="Disabling chrooted environment on $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (


        for SIMNAME in `echo $SIMLIST`
        do
            $RSH -l netsim $host "/mnt/support/disable_chrooted.sh $SIMNAME"
        done
        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait

}

set_security_definitions_sl3()
{
    echo $SECURITY | $EGREP "^atrc|^Akita|^aty" >> /dev/null
    TEST=`echo $?`
    if [ $TEST -ne 0 ]
    then
        echo "ERROR: You must specify a supported security -a trcusXXX, -a atylXXX"
        exit 1
    else
        echo "INFO: Security is $SECURITY"
    fi

    echo -n "Do you want to enable CORBA Security (yes / no): "
    read answer
    if [[ "$answer" == "yes" ]]
    then
        corba_security="yes"
    else
        corba_security="no"
    fi

    for host in `echo $NETSIMSERVERLIST`
    do

        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        #   Parallelized code below to start all in parallel.
        ###################################
        # Parallel variable initialization
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Setting sl3 security definitions"
        PARALLEL_STATUS_STRING="Setting sl3 security definitions on $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (

        echo "INFO: Creating security definition"
        $RSH -l netsim $host "/mnt/support/create_security_definition_sl3.sh $SECURITY"
        for SIMNAME in `echo $SIMLIST`
        do
            $RSH -l netsim $host "/mnt/support/set_security_definitions_sl3.sh $SIMNAME $SECURITY $corba_security"
        done
        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait

}

### Function: set_ips ###
#
#   Configure IP addresses on SIMS
#
# Arguments:
#       none
# Return Values:
#       none
set_ips_v2()
{
    for host in `echo $NETSIMSERVERLIST`
    do
        TOTALIPS=`$RSH $host "$IFCONFIG -a | $GREP inet | $WC -l"`
        TOTALVIPS=`expr $TOTALIPS - 2`

        echo "INFO: Total IP address available on $host is $TOTALIPS"
        IPREQD=0

        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        #   Parallelized code below to start all in parallel.a
        ###################################
        # Parallel variable initialization
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Setting up IPs"
        PARALLEL_STATUS_STRING="Setting up IPs on $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (


        for SIMNAME in `echo $SIMLIST`
        do
            CELLTEST=`$EGREP "^${host}_type=" $CONFIGFILE | $AWK -F= '{print $2}'`
            if [ -z "$CELLTEST" ]
            then
                echo "INFO: CELLTYPE is not set, so setting to \"C\""
                CELLTYPE="C"
            else
                CELLTYPE=$CELLTEST
            fi
            case "$CELLTYPE" in
                C) IPREQD=`expr $IPREQD + 250`
                    ;;
                F) IPREQD=`expr $IPREQD + 1000`
                    ;;
                \?) echo -e "ERROR: SIM $SIMNAME on $host is not supported Cell Type (C, F or LTE)"
                    exit 11
                    ;;
            esac
        done

        echo "INFO: Total IPS needed to do rollout is $IPREQD before OFFSET is applied"

        #Now apply ip OFFSET to the check that was done above
        TMP_OFFSET=$OFFSET
        while [[ $TMP_OFFSET -gt 0 ]]
        do
            IPREQD=`expr $IPREQD + 250`

            TMP_OFFSET=`expr $TMP_OFFSET - 1`
        done
        echo "INFO: Total IPS needed to do rollout is $IPREQD after OFFSET is applied"

        if [ $IPREQD -le $TOTALVIPS ]
        then
            echo "INFO: Sufficient VIPS on $host for SIMS"
        else
            echo "ERROR: Insufficient VIPS on $host for SIMS"
            exit 11
        fi

        IPSUBS=`$RSH $host "/mnt/support/list_ip_subs.sh $host" | $GREP -vi Display`
        IPSUBSARRAY=()
        COUNT=1

        #If the OFFSET for ips is not set, default to 0
        if [[ -z $OFFSET ]]
        then
            OFFSET=0
        fi
        for ipsub in `echo $IPSUBS`
        do
            IPSUBSARRAY[$COUNT]=$ipsub
            COUNT=`expr $COUNT + 1`
            echo "INFO: Available Subnet is $ipsub"
        done

        for SIMNAME in `echo $SIMLIST`
        do

            #POSITION=`echo $line | awk -F: '{print $20}'`
            IPCOUNT=1
            echo "INFO: Getting number of RNC in SIM $SIMNAME on $host"
            NOOFRNC=`$RSH -l netsim $host "/mnt/support/get_num_rnc.sh $host $SIMNAME" | $GREP -vi Display`
            echo "INFO: Getting number of RBS in SIM $SIMNAME on $host"
            NOOFRBS=`$RSH -l netsim $host "/mnt/support/get_num_rbs.sh $host $SIMNAME" | $GREP -vi Display`
            echo "INFO: Getting number of RXI in SIM $SIMNAME on $host"
            NOOFRXI=`$RSH -l netsim $host "/mnt/support/get_num_rxi.sh $host $SIMNAME" | $GREP -vi Display`
            echo "INFO: Getting number of LTE in SIM $SIMNAME on $host"
            NOOFLTE=`$RSH -l netsim $host "/mnt/support/get_num_lte.sh $host $SIMNAME" | $GREP -vi Display`
            echo "INFO: Getting number of TDRNC in SIM $SIMNAME on $host"
            NOOFTDRNC=`$RSH -l netsim $host "/mnt/support/get_num_tdrnc.sh $host $SIMNAME" | $GREP -vi Display`
            echo "INFO: Getting number of TDRBS in SIM $SIMNAME on $host"
            NOOFTDRBS=`$RSH -l netsim $host "/mnt/support/get_num_tdrbs.sh $host $SIMNAME" | $GREP -vi Display`
            echo "INFO: Getting number of TBRXI in SIM $SIMNAME on $host"
            NOOFTDRXI=`$RSH -l netsim $host "/mnt/support/get_num_tdrxi.sh $host $SIMNAME" | $GREP -vi Display`
            echo "INFO: $NOOFRNC RNCs in SIM $SIMNAME on $host"
            echo "INFO: $NOOFRBS RBSs in SIM $SIMNAME on $host"
            echo "INFO: $NOOFRXI RXIs in SIM $SIMNAME on $host"
            echo "INFO: $NOOFTDRNC TDRNCs in SIM $SIMNAME on $host"
            echo "INFO: $NOOFTDRBS TDRBSs in SIM $SIMNAME on $host"
            echo "INFO: $NOOFTDRXI TDRXIs in SIM $SIMNAME on $host"
            echo "INFO: $NOOFLTE LTEs in SIM $SIMNAME on $host"
            TOTALNODES=`expr $NOOFRNC + $NOOFRBS + $NOOFRXI + $NOOFLTE + $NOOFTDRNC + $NOOFTDRBS + $NOOFTDRXI`
            if [ $TOTALNODES -eq 0 ]
            then
                echo "ERROR: There are no nodes in SIM $SIMNAME on $host. Exiting"
                exit 12
            fi
            echo "INFO: Setting up IP addresses on SIM $SIMNAME on $host"
            POSITION=`$RSH -l netsim $host "/mnt/support/get_position.sh $host $SIMNAME" | $GREP -vi Display`

            #Hack for sims already on the box and not part of rollout. ie the netsim box serves two OSS's
            #Only applied with NODEFILTER and OFFSET as arguments to run.sh
            if [[ $OFFSET != "" ]]
            then
                if [[ $NODEFILTER != "" ]]
                then
                    POSITION=`expr $OFFSET + 1`
                    echo "INFO: HACK for POSITION applied"
                    echo "INFO: Using SUBNET ${IPSUBSARRAY[$POSITION]}"
                fi
            fi

            $RSH -l netsim $host "/mnt/support/setup_ip.sh $host $SIMNAME $NOOFRBS $NOOFRNC $NOOFRXI $NOOFLTE $NOOFTDRNC $NOOFTDRBS $NOOFTDRXI ${IPSUBSARRAY[$POSITION]} $DATE" | $GREP -vi Display
        done
        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait
}
setup_sl3_phase1 ()
{
    setup_internal_ssh
    enable_chrooted
}
setup_sl3_phase2 ()
{
    echo -n "Has initial enrollment been completed yet for at least one node and pems stored on atrclin3? (y/n): "
    if [[ "$INTERACTION" == "y" ]]
    then
        read answer
    else
        answer="y"
        echo "INFO: Interaction Set to NO, Default answer here is (y)"
    fi
    if [[ "$answer" == "n" ]]
    then
        echo "INFO: Exiting because initial enrollment hasn't been completed yet"
        exit_routine 34
    fi

    upload_pems_sl3
    set_security_definitions_sl3
    set_caas_ip
    set_security_MO_sl3
    show_security_status
}
set_security_MO_sl1()
{
    set_security_MO 1
}
set_security_MO_sl2()
{
    set_security_MO 2
}
set_security_MO_sl3()
{
    set_security_MO 3
}

show_security_status()
{
    for host in `echo $NETSIMSERVERLIST`
    do
        ###################################
        # Parallel variable initialization
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER=""
        PARALLEL_STATUS_STRING=""
        SHOW_STATUS_UPDATES="NO"
        SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (
        echo "INFO: Security Status On $host"
        $RSH -l netsim $host "/mnt/support/show_secStatus.sh -summary" | $GREP -vi Display | grep -v default
        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait
}

### Function: stop_all ###
#
#   Stop all SIMs
#
# Arguments:
#       none
# Return Values:
#       none
stop_all()
{
    if [[ "$NEWER_FUNCTIONS" == "y" ]]
    then
        stop_all_v2
        return
    fi

    for host in `echo $NETSIMSERVERLIST`
    do

        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        for SIMNAME in `echo $SIMLIST`
        do
            echo "DEBUG: Sim name is $SIMNAME"
            echo "INFO: Stopping SIM $SIMNAME on $host"
            $RSH -l netsim $host "/mnt/support/stop_all.sh $host $SIMNAME | $NETSIMSHELL" | $GREP -vi Display
            echo "INFO: SIM $SIMNAME stopped on $host"
        done
    done
}

stop_all_v2()
{
    for host in `echo $NETSIMSERVERLIST`
    do

        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        ###################################
        # Parallel variable initialization
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Stopping SIMS"
        PARALLEL_STATUS_STRING="Stopping SIMS on $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (
        for SIMNAME in `echo $SIMLIST`
        do
            echo "INFO: Stopping SIM $SIMNAME on $host"
            $RSH -l netsim $host "/mnt/support/stop_all.sh $host $SIMNAME | $NETSIMSHELL" | $GREP -vi Display
            echo "INFO: SIM $SIMNAME stopped on $host"
        done
        echo "INFO: Please wait for other processes to finish.."
        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait
}

restart_netsim()
{
    if [[ "$NEWER_FUNCTIONS" == "y" ]]
    then
        restart_netsim_v2
        return
    fi

    for host in `echo $NETSIMSERVERLIST`
    do


        echo "DEBUG: ReStarting netsim on $host"
        $RSH -l netsim $host "/netsim/inst/restart_netsim" | $GREP -vi Display


    done
}

restart_netsim_v2()
{
    for host in `echo $NETSIMSERVERLIST`
    do
        echo "DEBUG: ReStarting netsim on $host"

        ###################################
        # Parallel variable initialization
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Restarting netsim"
        PARALLEL_STATUS_STRING="Restart netsim on $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (
        $RSH -l netsim $host "/netsim/inst/restart_netsim" | $GREP -vi Display
        echo "INFO: Netsim restarted on $host"
        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait
}
start_netsim()
{
    if [[ "$NEWER_FUNCTIONS" == "y" ]]
    then
        start_netsim_v2
        return
    fi
    for host in `echo $NETSIMSERVERLIST`
    do


        echo "DEBUG: Starting netsim on $host"
        $RSH -l netsim $host "/netsim/inst/start_netsim" | $GREP -vi Display


    done
}
start_netsim_v2()
{
    for host in `echo $NETSIMSERVERLIST`
    do
        echo "DEBUG: Starting netsim on $host"

        # Parallelized version below
        ###################################
        # Parallel variable initialization
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Starting netsim"
        PARALLEL_STATUS_STRING="Starting netsim on $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (
        $RSH -l netsim $host "/netsim/inst/start_netsim" | $GREP -vi Display
        echo "INFO: Netsim started on $host"
        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait
}

reboot_host()
{
    if [[ "$NEWER_FUNCTIONS" == "y" ]]
    then
        reboot_host_v2
        return
    fi

    for host in `echo $NETSIMSERVERLIST`
    do


        echo "DEBUG: Rebooting $host"
        $RSH -l root $host "bash;/sbin/shutdown -r now "
    done
}


reboot_host_v2()
{
    for host in `echo $NETSIMSERVERLIST`
    do
        echo "DEBUG: Rebooting $host"
        #$RSH -l root $host "bash;/sbin/shutdown -r now "

        # Parallelized version below
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Rebooting netsims"
        PARALLEL_STATUS_STRING="Rebooting $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (
        $RSH -l root $host "bash;/sbin/shutdown -r now"
        echo "INFO: $host is rebooting"
        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait
}


### Function: create_scanners ###
#
#   Create scanners
#
# Arguments:
#       none
# Return Values:
#       none

create_scanners()
{
    if [[ "$NEWER_FUNCTIONS" == "y" ]]
    then
        create_scanners_v2
        return
    fi

    for host in `echo $NETSIMSERVERLIST`
    do
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        for SIMNAME in `echo $SIMLIST`
        do
            echo "INFO: Creating Scanners for SIM $SIMNAME on $host"
            $RSH -l netsim $host "/mnt/support/create_scanners.sh $host $SIMNAME" | $GREP -vi Display
            echo "INFO: Scanners for SIM $SIMNAME created on $host"
        done
    done
}

create_scanners_v2()
{
    for host in `echo $NETSIMSERVERLIST`
    do
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        echo "INFO: Creating Scanners for SIMS on $host"

        # Parallelized code below
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Creating scanners"
        PARALLEL_STATUS_STRING="Creating scanners on $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (
        for SIMNAME in `echo $SIMLIST`
        do
            echo "INFO: Creating Scanners for SIM $SIMNAME on $host"

            $RSH -l netsim $host "/mnt/support/create_scanners.sh $host $SIMNAME" | $GREP -vi Display
            echo "INFO: Scanners for SIM $SIMNAME created on $host"
        done
        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait
}
### Function: delete_scanners ###
#
#   Delete scanners
#
# Arguments:
#       none
# Return Values:
#       none

delete_scanners()
{
    if [[ "$NEWER_FUNCTIONS" == "y" ]]
    then
        delete_scanners_v2
        return
    fi

    for host in `echo $NETSIMSERVERLIST`
    do
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        for SIMNAME in `echo $SIMLIST`
        do
            echo "INFO: Deleting Scanners for SIM $SIMNAME on $host"
            $RSH -l netsim $host "/mnt/support/delete_scanners.sh $host $SIMNAME" | $GREP -vi Display
            echo "INFO: Scanners for SIM $SIMNAME deleted on $host"
        done
    done
}

delete_scanners_v2()
{
    for host in `echo $NETSIMSERVERLIST`
    do
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        echo "INFO: Deleting Scanners for SIMS on $host"

        # Parallelized code below
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Deleting scanners"
        PARALLEL_STATUS_STRING="Deleting scanners on $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (
        for SIMNAME in `echo $SIMLIST`
        do
            echo "INFO: Deleting Scanners for SIM $SIMNAME on $host"

            $RSH -l netsim $host "/mnt/support/delete_scanners.sh $host $SIMNAME" | $GREP -vi Display
            echo "INFO: Scanners for SIM $SIMNAME deleted on $host"
        done
        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait
}

### Function: create_scanners ###
#
#   Create scanners
#
# Arguments:
#       none
# Return Values:
#       none
copy_config_file_to_netsim_orig()
{
    #pm_rollout uses this ONLY
    for host in `echo $NETSIMSERVERLIST`
    do
        echo "INFO: Copy config file $CONFIGFILE to $host"
        $RCP $CONFIGFILE $host:/netsim/netsim_cfg
        $RSH -l root $host "/bin/chown netsim:netsim /netsim/netsim_cfg"
        echo "INFO: config file $CONFIGFILE copied to $host"
    done
}
copy_config_file_to_netsim()
{

    for host in `echo $NETSIMSERVERLIST`
    do
        echo "INFO: Copy config file $CONFIGFILE to $host"
        $RCP $CONFIGFILE $host:/netsim/netsim_cfg
        $RSH -l root $host "/bin/chown netsim:netsim /netsim/netsim_cfg"
        echo "INFO: config file $CONFIGFILE copied to $host"
    done

    #Edit the netsim_cfg file is the -g option is set
    if [[ $NODEFILTER != "" ]]
    then
        echo "INFO: NODEFILTER applied for PM Rollout..."
        echo "INFO: /mnt/support/netsim_cfg_filter.sh $host $NODEFILTER"
        $RSH -l root $host "/mnt/support/netsim_cfg_filter.sh $host $NODEFILTER"	

    fi

}


### Function: setup_variables ###
#
#   Setup Variables
#
# Arguments:
#       none
# Return Values:
#       none
setup_variables()
{
    if [[ "$NEWER_FUNCTIONS" == "y" ]]
    then
        setup_variables_v2
        return
    fi

    for host in `echo $NETSIMSERVERLIST`
    do

        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        for SIMNAME in `echo $SIMLIST`
        do
            echo "INFO: Variables for SIM $SIMNAME on $host"
            $RSH -l netsim $host "/mnt/support/setup_variables.sh $host $SIMNAME" | $GREP -vi Display
            echo "INFO: Variables for SIM $SIMNAME setup on $host"
        done
    done
}

setup_variables_v2()
{
    for host in `echo $NETSIMSERVERLIST`
    do

        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        echo "INFO: Setting up variables for SIMS on $host"
        # Parallelized code below
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Setting up variables"
        PARALLEL_STATUS_STRING="Setting up variables on $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (
        for SIMNAME in `echo $SIMLIST`
        do
            echo "INFO: Variables for SIM $SIMNAME on $host"

            $RSH -l netsim $host "/mnt/support/setup_variables.sh $host $SIMNAME" | $GREP -vi Display
            echo "INFO: Variables for SIM $SIMNAME setup on $host"
        done
        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait
}



### Function: save_and_compress ###
#
#   Setup Variables
#
# Arguments:
#       none
# Return Values:
#       none
save_and_compress()
{
    for host in `echo $NETSIMSERVERLIST`
    do
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        for SIMNAME in `echo $SIMLIST`
        do
            echo "INFO: Saving and compressing SIM $SIMNAME on $host"
            $RSH -l netsim $host "/mnt/support/save_and_compress.sh $host $SIMNAME" | $GREP -vi Display
            echo "INFO: SIM $SIMNAME saved and compressed on $host"
        done    
    done
}

### Function: create_users ###
#
#   Create Users
#
# Arguments:
#       none
# Return Values:
#       none
create_users()
{
    if [[ "$NEWER_FUNCTIONS" == "y" ]]
    then
        create_users_v2
        return
    fi

    for host in `echo $NETSIMSERVERLIST`
    do
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        for SIMNAME in `echo $SIMLIST`
        do
            echo "INFO: Creating users for SIM $SIMNAME on $host"
            $RSH $host "/mnt/support/create_users.sh $host $SIMNAME" | $GREP -vi Display
            echo "INFO: Users created for SIM $SIMNAME on $host"
        done
    done
}

create_users_v2()
{
    for host in `echo $NETSIMSERVERLIST`
    do
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        echo "INFO: Creating users for SIMS on $host"

        # Parallelized code below
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Creating users"
        PARALLEL_STATUS_STRING="Creating users on $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (
        for SIMNAME in `echo $SIMLIST`
        do
            echo "INFO: Creating users for SIM $SIMNAME on $host"

            $RSH $host "/mnt/support/create_users.sh $host $SIMNAME" | $GREP -vi Display
            echo "INFO: Users created for SIM $SIMNAME on $host"
        done
        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait
}

### Function: disable_security ###
#
#   Disable Security
#
# Arguments:
#       none
# Return Values:
#       none
disable_security()
{
    stop_all
    for host in `echo $NETSIMSERVERLIST`
    do
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        for SIMNAME in `echo $SIMLIST`
        do
            echo "INFO: Disabling security for SIM $SIMNAME on $host"
            $RSH -l netsim $host "/mnt/support/disable_security.sh $host $SIMNAME $SERVER | $NETSIMSHELL" | $GREP -vi Display
            echo "INFO: Security disabled for SIM $SIMNAME on $host"
        done
    done
    start_all
}

### Function: save_config ###
#
#   Saving Config
#
# Arguments:
#       none
# Return Values:
#       none
save_config()
{
    for host in `echo $NETSIMSERVERLIST`
    do
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        for SIMNAME in `echo $SIMLIST`
        do

            BACKUPDIR="$SCRIPTDIR/savedconfigs/$host/$DATE"

            if [ ! -d $BACKUPDIR ]
            then
                echo "INFO: Creating Backup dir $BACKUPDIR on $host"
                $MKDIR -p "$BACKUPDIR/config" 
                echo "INFO: Backup dir $BACKUPDIR on $host created"
            fi
            echo "INFO: Backup dir $BACKUPDIR exists"
            echo "INFO: Copying config file for $host"
            if [ ! -d $BACKUPDIR/config/$SIMNAME ]
            then
                $MKDIR -p $BACKUPDIR/config/$SIMNAME
            fi
            $CP $CONFIGFILE $BACKUPDIR/config
            echo "INFO: Saving config for $SIMNAME on $host"
            echo "SIMNAME=$SIMNAME" > $BACKUPDIR/config/${SIMNAME}/${SIMNAME}.cfg
            echo "NETSIMSERVER=$LINENETSIMSERVER" >> $BACKUPDIR/config/${SIMNAME}/${SIMNAME}.cfg
            echo "OSSSERVER=$LINEOSSSERVER" >> $BACKUPDIR/config/${SIMNAME}/${SIMNAME}.cfg
            echo "Chosen Deployment=$DEPLOYMENT" >> $BACKUPDIR/config/${SIMNAME}/${SIMNAME}.cfg
            echo "Chosen Security=$SECURITY" >> $BACKUPDIR/config/${SIMNAME}/${SIMNAME}.cfg
            #echo "INFO: Backing up rolled out sim $SIMNAME from $host"
            #$RSH -n $host "/mnt/support/save_file.sh $host $SIMNAME $MOUNTPOINT/savedconfigs/$host/$DATE/rolledoutsims NEWSIM"
            #echo "INFO: Sim $SIMNAME backed up from $host"
            $RSH -n $host "/mnt/support/save_file.sh $host $SIMNAME $MOUNTPOINT/savedconfigs/$host/$DATE/config/${SIMNAME} IPFILES"
            echo "INFO: Sim $SIMNAME IP info backed up from $host"
            $RSH -n $host "/mnt/support/save_file.sh $host $SIMNAME $MOUNTPOINT/savedconfigs/$host/$DATE/config/${SIMNAME} USERS"
            echo "INFO: Sim $SIMNAME create_users scripts backed up from $host"

        done    
    done
}

### Function: deploy_amos_and_c ###
#
#   Deploy AMOS
#
# Arguments:
#       none
# Return Values:
#       none
deploy_amos_and_c()
{

    if [[ "$NEWER_FUNCTIONS" == "y" ]]
    then
        deploy_amos_and_c_v2
        return
    fi

    echo "INFO: Deploying AMOS and C"
    for host in `echo $NETSIMSERVERLIST`
    do
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        echo "INFO: Deploying C on $host"
        $RSH $host "/mnt/support/deploy_c.sh $host" | $GREP -vi Display
        CTEST=`$RSH $host "/mnt/support/check_file.sh $host blank C"`
        echo $CTEST | $GREP "OK" > /dev/null
        if [ $? -ne 0 ]
        then
            echo "ERROR: C not deployed correctly"
            exit_routine 15
        else
            echo "INFO: C deployed on $host"    
        fi

        for SIMNAME in `echo $SIMLIST`
        do
            echo "INFO: Deploying AMOS for  SIM $SIMNAME on $host"
            $RSH -l netsim $host "/mnt/support/deploy_amos.sh $host $SIMNAME" | $GREP -vi Display
            AMOSTEST=`$RSH $host "/mnt/support/check_file.sh $host $SIMNAME AMOS"`
            echo $AMOSTEST | $GREP "OK" > /dev/null
            if [ $? -ne 0 ]
            then
                echo "ERROR: AMOS not deployed correctly"
                exit 15
            else
                echo "INFO: AMOS for $SIMNAME deployed on $host"    
            fi	
        done    
    done
}

deploy_amos_and_c_v2()
{
    echo "INFO: Deploying AMOS and C"
    for host in `echo $NETSIMSERVERLIST`
    do
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        #   Parallelized code below to start all in parallel.a
        ###################################
        # Parallel variable initialization
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Deploying amos and c"
        PARALLEL_STATUS_STRING="Deploying amos and c on $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (

        echo "INFO: Deploying C on $host"
        $RSH $host "/mnt/support/deploy_c.sh $host" | $GREP -vi Display
        CTEST=`$RSH $host "/mnt/support/check_file.sh $host blank C"`
        echo $CTEST | $GREP "OK" > /dev/null
        if [ $? -ne 0 ]
        then
            echo "ERROR: C not deployed correctly"
            exit 15
        else
            echo "INFO: C deployed on $host"
        fi

        for SIMNAME in `echo $SIMLIST`
        do
            echo "INFO: Deploying AMOS for  SIM $SIMNAME on $host"
            $RSH -l netsim $host "/mnt/support/deploy_amos.sh $host $SIMNAME" | $GREP -vi Display
            AMOSTEST=`$RSH $host "/mnt/support/check_file.sh $host $SIMNAME AMOS"`
            echo $AMOSTEST | $GREP "OK" > /dev/null
            if [ $? -ne 0 ]
            then
                echo "ERROR: AMOS not deployed correctly"
                exit 15
            else
                echo "INFO: AMOS for $SIMNAME deployed on $host"
            fi
        done
        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables

    done
    parallel_wait
}



### Function: generate_ip_map ###
#
#   Generate IP map for AMOS
#
# Arguments:
#       none
# Return Values:
#       none
generate_ip_map()
{
    echo "INFO: Generating IP Map for AMOS"
    for host in `echo $NETSIMSERVERLIST`
    do
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        for SIMNAME in `echo $SIMLIST`
        do
            BACKUPDIR="$SCRIPTDIR/savedconfigs/$host/$DATE"

            if [ ! -d $BACKUPDIR/config ]
            then
                echo "INFO: Creating Backup dir $BACKUPDIR on $host"
                $MKDIR -p "$BACKUPDIR/config"
                echo "INFO: Backup dir $BACKUPDIR on $host created"
            fi
            echo "INFO: Backup dir $BACKUPDIR exists"
            $RSH $host "/mnt/support/generate_ip_map.sh $host $SIMNAME" >> ./savedconfigs/$host/$DATE/config/ip_map.txt
        done
    done
}
upload_ip_map()
{
    ssh_connection
    if [[ ${SERVER} == "" ]]
    then
        echo "ERROR: Please include [ -s oss_server_name ] option"
        exit_routine 0

    fi

    #ejershe - Aug 2010
    #Upload ip_map.txt file to oss server - Called only as a -f option
    rm -rf /tmp/ip_map_${SERVER}.txt

    echo "INFO: Uploading IP Map for AMOS"
    for host in `echo $NETSIMSERVERLIST`
    do
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi


        #ejershe- This could be run anytime so we want to take the latest configuration that was rolled out
        saved_date_dir=`ls -rt ./savedconfigs/$host/ | tail -n 1`


        upload="scp ./savedconfigs/$host/${saved_date_dir}/config/ip_map.txt root@${SERVER}:/home/nmsadm/${host}_ip_map.txt"

        cat ./savedconfigs/$host/${saved_date_dir}/config/ip_map.txt >> /tmp/ip_map_${SERVER}.txt

    done
    echo "INPUT: Do you require RNC35? (y/n)"
    read RNC35_INPUT

    if [[ $RNC35_INPUT == "y" ]]
    then
        #Append RNC 35 to the ip_map_${SERVER}.txt
        echo "INFO: Appending RNC35 DEAD NODES to /tmp/ip_map_${SERVER}.txt"

        subscripts/RNC35/create_ip_map.sh $RNC35_DIR
        if [[ $? == "1" ]]
        then
            echo "ERROR: Exiting..."
            exit_routine 1
        fi
        cat $RNC35_DIR/ip_map_RNC35.txt >> /tmp/ip_map_${SERVER}.txt

    else
        echo "INFO: RNC35 NOT appended to /tmp/ip_map_${SERVER}.txt"
    fi



    scp /tmp/ip_map_${SERVER}.txt root@${SERVER}:/home/nmsadm/tep/ip_map_${SERVER}.txt
    echo "INFO: ip_map_${SERVER}.txt is located on ${SERVER} in /home/nmsadm/tep"
    UPDATEBANNER="ip_map_${SERVER}.txt is located in /home/nmsadm/tep"
}

upload_arne()
{

    #ejershe - Aug 2010
    #Upload ARNE v2  file to oss server - Called only as a -f option

    if [[ ${SERVER} == "" ]]
    then
        echo "ERROR: Please include [ -s oss_server_name ] option"
        exit_routine 0

    fi
    ssh_connection
    echo "INFO: Uploading ARNE v2 files $host"
    echo "INFO: Enter the root password for ${SERVER} when prompted"
    echo "INFO: Checking /home/nmsadm/tep Directory on ${SERVER} exists"
    $SSH root@${SERVER} 'if [ ! -d /home/nmsadm/tep ];then echo "INFO: Creating /home/nmsadm/tep"; mkdir /home/nmsadm/tep;chown nmsadm /home/nmsadm/tep;fi'

    files_to_upload=""
    for host in `echo $NETSIMSERVERLIST`
    do
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi


        #ejershe- This could be run anytime so we want to take the latest configuration that was rolled out
        saved_date_dir=`ls -rt ./savedconfigs/$host/ | tail -n 1`


        upload="scp ./savedconfigs/$host/${saved_date_dir}/arnefiles/import-v2*xml nmsadm@${SERVER}:/home/nmsadm/tep"
        #scp ./savedconfigs/$host/${saved_date_dir}/arnefiles/import-v2*xml root@${SERVER}:/home/nmsadm/tep

        #Create a list so you will only be prompted for the oss password once
        files_to_upload="${files_to_upload} ./savedconfigs/$host/${saved_date_dir}/arnefiles/import-v2*create*xml ./savedconfigs/$host/${saved_date_dir}/arnefiles/import-v2*delete*xml "
    done

    #RNC 35 only for WRAN
    RNC35_SIM_CHECK=`echo $files_to_upload | grep RNC`
    if [[ $RNC35_SIM_CHECK != "" ]]
    then

        printf "INPUT: Upload RNC35 import file? (y/n):"
        read UPLOAD_RNC35
        if [[ $UPLOAD_RNC35 == "y" ]]
        then
            echo "INFO: Appending RNC35 to the upload list"
            echo "INFO: RNC35 Delete File uploaded also"

            files_to_upload="${files_to_upload} $RNC35_DIR/import-v2-RNC35_create.xml $RNC35_DIR/import-v2-RNC35_delete.xml"
        else
            echo "INFO: NOT ading RNC35 to the upload list"
        fi
    fi

    scp $files_to_upload root@${SERVER}:/home/nmsadm/tep
    #chown nmsadm on all xml + folder

    echo "INFO: Changing ownership of xml files to nmsadm"
    $SSH root@${SERVER} 'chown nmsadm /home/nmsadm/tep;chown nmsadm /home/nmsadm/tep/*' 
    UPDATEBANNER="ARNE files are located in /home/nmsadm/tep on ${SERVER}"
}

generate_arne()
{
    if [[ "$NEWER_FUNCTIONS" == "y" ]]
    then
        generate_arne_v2
        return
    fi

    #ejershe - Aug 2010
    #Generate ARNE - new procedure
    #Refer to /mnt/support/create_arne.sh for the exact coded needed to generate ARNE files v2

    echo "INFO: Generating ARNE xml files"
    BACKUPDIR="$MOUNTPOINT/savedconfigs/$host/"


    printf "INPUT: PLEASE ENTER SMRS SLAVE NAME (Enter none for no smrs setup):" 
    read SMRSSLAVE

    while [[ $SMRSSLAVE == "" ]]
    do
        printf "INPUT: PLEASE ENTER SMRS SLAVE NAME (Enter none for no smrs setup):"
        read SMRSSLAVE

    done

    #New code needed for this problem SubNetwork=ONRM_RootMo,FtpServer=SMRSSLAVE-WRAN-rcxb1232,FtpService=w-back-atrcxb1232
    if [[ $SMRSSLAVE != "none" ]]
    then
        printf "INPUT: Was the FtpServer hostname name shortened? eg SubNetwork=ONRM_RootMo,FtpServer=SMRSSLAVE-WRAN-rcxb1232,FtpService=w-back-atrcxb1232 (y/n):"
        read SHORTENED_ANS
    fi

    if [[ $SHORTENED_ANS == "y" ]]
    then
        printf "INPUT: PLEASE ENTER THE SHORTENED SMRS SLAVE NAME (eg rcxb1232 for):"
        read SHORT_SERVER_NAME
        echo "INFO: Short hostname set to $SHORT_SERVER_NAME"
    else
        #Set short name to long name
        echo "INFO: Ignoring short hostname..."
        SHORT_SERVER_NAME=$SMRSSLAVE
    fi

    if [[ $SMRSSLAVE != "none" ]]
    then
        # Get the smrs details to add to /etc/hosts on the netsim boxes
        SMRS_OUTPUT=`$GETENT hosts $SHORT_SERVER_NAME`
        if [[ "$SMRS_OUTPUT" == "" ]]
        then
            echo "ERROR: Couldn't get the IP / hostname of $SHORT_SERVER_NAME, check if its in dns"
            exit_routine 0;
        else
            SMRS_SERVER_IP=`echo "$SMRS_OUTPUT" | $AWK '{print $1}'`
            SMRS_FULL_NAME=`echo "$SMRS_OUTPUT" | $AWK '{print $2}'`
            ETC_HOSTS_STRING="$SMRS_SERVER_IP $SHORT_SERVER_NAME $SMRS_FULL_NAME"
        fi
    fi
    # End of getting smrs details

    printf "INPUT: <Create> or <Modify> type xml:(c/m):"
    read XMLTYPE

    if [[ $XMLTYPE == "c" ]] 
    then
        echo "INFO: Setting tag to <Create>"

    elif [[ $XMLTYPE == "m" ]] 
    then
        echo "INFO: Setting tag to <Modify> "
    else
        echo "ERROR: You must specify c/m"
        exit_routine 0;
    fi

    for host in `echo $NETSIMSERVERLIST`
    do

        BACKUPDIR="$MOUNTPOINT/savedconfigs/$host/"

        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi
        if [[ $SMRSSLAVE != "none" ]]
        then
            # Add smrs slave to /etc/hosts on the netsim
            echo "INFO: Adding the SMRS Slave to /etc/hosts"
            $RSH $host "if [[ \`grep ^$SMRS_SERVER_IP /etc/hosts\` ]]; then echo INFO: Already exists; else echo $ETC_HOSTS_STRING >> /etc/hosts; fi"
        fi
        for SIMNAME in `echo $SIMLIST`
        do
            echo "INFO: Generating ARNE xml file for $SIMNAME"
            $RSH $host "/mnt/support/create_arne.sh $host $SIMNAME $BACKUPDIR $SMRSSLAVE $SHORT_SERVER_NAME" 

        done

        #Manipulate ARNE files with post steps
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #ejershe- This could be run anytime so we want to take the latest configuration that was rolled out
        saved_date_dir=`ls -rt ./savedconfigs/$host/ | tail -n 1`

        echo "INFO: Post manipulation of ARNE"


        #Manipulate arne create files before upload
        ls ./savedconfigs/$host/${saved_date_dir}/arnefiles/import-v2*create*xml  | grep -v post | while read ARNEFILE
    do
        echo "INFO: Applying post manipulation on $ARNEFILE"
        TMP_ARNE_FILE=`echo $ARNEFILE | awk -F/ '{print $NF}'| awk -F. '{print $1}'`

        support/manipulate_arne_post.pl $ARNEFILE $XMLTYPE > ./savedconfigs/$host/${saved_date_dir}/arnefiles/${TMP_ARNE_FILE}_post.xml
        mv ./savedconfigs/$host/${saved_date_dir}/arnefiles/${TMP_ARNE_FILE}_post.xml $ARNEFILE 
    done

    #Manipulate the arne delete files to remove ftpServices
    ls ./savedconfigs/$host/${saved_date_dir}/arnefiles/import-v2*delete*xml  | grep -v post | while read ARNEFILE
do
    echo "INFO: Applying post manipulation on $ARNEFILE"
    TMP_ARNE_FILE=`echo $ARNEFILE | awk -F/ '{print $NF}'| awk -F. '{print $1}'`

    support/manipulate_arne_delete_post.pl $ARNEFILE $XMLTYPE > ./savedconfigs/$host/${saved_date_dir}/arnefiles/${TMP_ARNE_FILE}_post.xml
    mv ./savedconfigs/$host/${saved_date_dir}/arnefiles/${TMP_ARNE_FILE}_post.xml $ARNEFILE 
done

done

}

generate_arne_v2()
{
    #ejershe - Aug 2010
    #Generate ARNE - new procedure
    #Refer to /mnt/support/create_arne.sh for the exact coded needed to generate ARNE files v2

    echo "INFO: Generating ARNE xml files"
    BACKUPDIR="$MOUNTPOINT/savedconfigs/$host/"


    printf "INPUT: PLEASE ENTER SMRS SLAVE NAME (Enter none for no smrs setup):"
    read SMRSSLAVE

    while [[ $SMRSSLAVE == "" ]]
    do
        printf "INPUT: PLEASE ENTER SMRS SLAVE NAME (Enter none for no smrs setup):"
        read SMRSSLAVE

    done

    #New code needed for this problem SubNetwork=ONRM_RootMo,FtpServer=SMRSSLAVE-WRAN-rcxb1232,FtpService=w-back-atrcxb1232
    if [[ $SMRSSLAVE != "none" ]]
    then
        printf "INPUT: Was the FtpServer hostname name shortened? eg SubNetwork=ONRM_RootMo,FtpServer=SMRSSLAVE-WRAN-rcxb1232,FtpService=w-back-atrcxb1232 (y/n):"
        read SHORTENED_ANS
    fi

    if [[ $SHORTENED_ANS == "y" ]]
    then
        printf "INPUT: PLEASE ENTER THE SHORTENED SMRS SLAVE NAME (eg rcxb1232 for):"
        read SHORT_SERVER_NAME
        echo "INFO: Short hostname set to $SHORT_SERVER_NAME"
    else
        #Set short name to long name
        echo "INFO: Ignoring short hostname..."
        SHORT_SERVER_NAME=$SMRSSLAVE
    fi

    if [[ $SMRSSLAVE != "none" ]]
    then
        # Get the smrs details to add to /etc/hosts on the netsim boxes
        SMRS_OUTPUT=`$GETENT hosts $SHORT_SERVER_NAME`
        if [[ "$SMRS_OUTPUT" == "" ]]
        then
            echo "ERROR: Couldn't get the IP / hostname of $SHORT_SERVER_NAME, check if its in dns"
            exit_routine 0;
        else
            SMRS_SERVER_IP=`echo "$SMRS_OUTPUT" | $AWK '{print $1}'`
            SMRS_FULL_NAME=`echo "$SMRS_OUTPUT" | $AWK '{print $2}'`
            ETC_HOSTS_STRING="$SMRS_SERVER_IP $SHORT_SERVER_NAME $SMRS_FULL_NAME"
        fi
        # End of getting smrs details
    fi

    printf "INPUT: <Create> or <Modify> type xml:(c/m):"
    read XMLTYPE

    if [[ $XMLTYPE == "c" ]]
    then
        echo "INFO: Setting tag to <Create>"

    elif [[ $XMLTYPE == "m" ]]
    then
        echo "INFO: Setting tag to <Modify> "
    else
        echo "ERROR: You must specify c/m"
        exit_routine 0;
    fi

    for host in `echo $NETSIMSERVERLIST`
    do

        #   Parallelized code below to start all in parallel.a
        ###################################
        # Parallel variable initialization
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Generating ARNE XMLs"
        PARALLEL_STATUS_STRING="Generating ARNE XMLs on $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (

        BACKUPDIR="$MOUNTPOINT/savedconfigs/$host/"

        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        if [[ $SMRSSLAVE != "none" ]]
        then
            # Add smrs slave to /etc/hosts on the netsim
            echo "INFO: Adding the SMRS Slave to /etc/hosts"
            $RSH $host "if [[ \`grep ^$SMRS_SERVER_IP /etc/hosts\` ]]; then echo INFO: Already exists; else echo $ETC_HOSTS_STRING >> /etc/hosts; fi"
        fi

        for SIMNAME in `echo $SIMLIST`
        do
            echo "INFO: Generating ARNE xml file for $SIMNAME"
            $RSH $host "/mnt/support/create_arne.sh $host $SIMNAME $BACKUPDIR $SMRSSLAVE $SHORT_SERVER_NAME"

        done

        #Manipulate ARNE files with post steps
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #ejershe- This could be run anytime so we want to take the latest configuration that was rolled out
        saved_date_dir=`ls -rt ./savedconfigs/$host/ | tail -n 1`


        echo "INFO: Post manipulation of ARNE"


        #Manipulate arne create files before upload
        ls ./savedconfigs/$host/${saved_date_dir}/arnefiles/import-v2*create*xml  | grep -v post | while read ARNEFILE
    do
        echo "INFO: Applying post manipulation on $ARNEFILE"
        TMP_ARNE_FILE=`echo $ARNEFILE | awk -F/ '{print $NF}'| awk -F. '{print $1}'`

        support/manipulate_arne_post.pl $ARNEFILE $XMLTYPE > ./savedconfigs/$host/${saved_date_dir}/arnefiles/${TMP_ARNE_FILE}_post.xml
        mv ./savedconfigs/$host/${saved_date_dir}/arnefiles/${TMP_ARNE_FILE}_post.xml $ARNEFILE
    done

    #Manipulate the arne delete files to remove ftpServices
    ls ./savedconfigs/$host/${saved_date_dir}/arnefiles/import-v2*delete*xml  | grep -v post | while read ARNEFILE
do
    echo "INFO: Applying post manipulation on $ARNEFILE"
    TMP_ARNE_FILE=`echo $ARNEFILE | awk -F/ '{print $NF}'| awk -F. '{print $1}'`

    support/manipulate_arne_delete_post.pl $ARNEFILE $XMLTYPE > ./savedconfigs/$host/${saved_date_dir}/arnefiles/${TMP_ARNE_FILE}_post.xml
    mv ./savedconfigs/$host/${saved_date_dir}/arnefiles/${TMP_ARNE_FILE}_post.xml $ARNEFILE
done

) > $LOG_FILE 2>&1;parallel_finish
) & set_parallel_variables

done
parallel_wait
}

post_scripts()
{

    if [[ "$NEWER_FUNCTIONS" == "y" ]]
    then
        post_scripts_v2 
        return
    fi

    for host in `echo $NETSIMSERVERLIST`
    do
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        for SIMNAME in `echo $SIMLIST`
        do
            SIM_CHECK=`echo $SIMNAME | grep LTE`
            if [[ $SIM_CHECK == "" ]]
            then
                echo "INFO: Running Create CV sw_install_variables.sh RNC Nodes"
                $RSH -l netsim $host "cp $MOUNTPOINT/support/sw_install* /netsim;chmod 755 /netsim/sw_install*;cd /netsim;./sw_install_variables.sh | /netsim/inst/netsim_shell"

            else

                echo "INFO: Running Create CV sw_install_variables_lte.sh LTE Nodes"
                $RSH -l netsim $host "cp $MOUNTPOINT/support/sw_install* /netsim;chmod 755 /netsim/sw_install*;cd /netsim;./sw_install_variables_lte.sh | /netsim/inst/netsim_shell;"

            fi

        done
    done
}

post_scripts_v2()
{
    for host in `echo $NETSIMSERVERLIST`
    do
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        # Parallelized code below
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Running Post Scripts"
        PARALLEL_STATUS_STRING="Running Post Scripts on $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (

        for SIMNAME in `echo $SIMLIST`
        do
            SIM_CHECK=`echo $SIMNAME | grep LTE`
            if [[ $SIM_CHECK == "" ]]
            then
                echo "INFO: Running Create CV sw_install_variables.sh RNC Nodes"
                $RSH -l netsim $host "cp $MOUNTPOINT/support/sw_install* /netsim;chmod 755 /netsim/sw_install*;cd /netsim;./sw_install_variables.sh | /netsim/inst/netsim_shell"

            else

                echo "INFO: Running Create CV sw_install_variables_lte.sh LTE Nodes"
                $RSH -l netsim $host "cp $MOUNTPOINT/support/sw_install* /netsim;chmod 755 /netsim/sw_install*;cd /netsim;./sw_install_variables_lte.sh | /netsim/inst/netsim_shell;"

            fi

        done

        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait
}

#Handy for just checking that netsim is running
check_netsim_version()
{
    echo "#####################################################"
    for host in `echo $NETSIMSERVERLIST`
    do
        NETSIMVERSION=`rsh $host "/mnt/support/check_netsim_version.sh $host "`	
        echo "INFO: $NETSIMVERSION is running on $host"
    done

    echo "#####################################################"

}

#each netsim will have its own personalised login message
login_banner()
{

    for host in `echo $NETSIMSERVERLIST`
    do
        echo "INFO: Setting up login Banner on $host"
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        for SIMNAME in `echo $SIMLIST`
        do
            SIM_KEY=`$EGREP "^${host}_key=" $CONFIGFILE  | grep $SIMNAME | $AWK -F\" '{print $2}' | $AWK '{print $2}'`
            #GRAN ONLY -Pass through all the sim keys to the login banner 
            SIM_KEYS="$SIM_KEYS $SIM_KEY"
        done
        SIM_KEYS_FORMATTED=`echo $SIM_KEYS | sed "s/ /-/g"`
        SIMLIST_FORMATTED=`echo $SIMLIST | sed "s/ /\//g"`
        `rsh $host "/mnt/support/login_banner.sh $host "$SIMLIST_FORMATTED" "$USERID" $SERVER $SIM_KEYS_FORMATTED"`
    done


}
update_login_banner()
{
    #update the login banner if a function is run post rollout 
    #This function will run only when you pass through a function using -f option
    #In order then for the banner to update, you must have the variable USERBANNER="Text" in a function
    #Also then you must have an if loop below to cover that function - upload_ip_map is an example

    if [[ $FUNCTIONS == "upload_ip_map" ]]
    then

        for host in `echo $NETSIMSERVERLIST`
        do
            echo "INFO: Updating login Banner on $host"
            UPDATEBANNER_FORMATTED=`echo $UPDATEBANNER | sed "s/ /-/g"`
            rsh $host "/mnt/support/update_login_banner.sh $UPDATEBANNER_FORMATTED $USERID"
        done

    elif [[ $FUNCTIONS == "pm_rollout" ]]
    then

        for host in `echo $NETSIMSERVERLIST`
        do
            echo "INFO: Updating login Banner on $host"
            UPDATEBANNER_FORMATTED=`echo $UPDATEBANNER | sed "s/ /-/g"`
            rsh $host "/mnt/support/update_login_banner.sh $UPDATEBANNER_FORMATTED $USERID"
        done
    elif [[ $FUNCTIONS == "install_patch" ]]
    then

        for host in `echo $NETSIMSERVERLIST`
        do
            echo "INFO: Updating login Banner on $host"
            UPDATEBANNER_FORMATTED=`echo $UPDATEBANNER | sed "s/ /-/g"`
            rsh $host "/mnt/support/update_login_banner.sh $UPDATEBANNER_FORMATTED $USERID"
        done
    elif [[ $FUNCTIONS == "upload_arne" ]] 
    then
        for host in `echo $NETSIMSERVERLIST`
        do
            echo "INFO: Updating login Banner on $host"
            UPDATEBANNER_FORMATTED=`echo $UPDATEBANNER | sed "s/ /-/g"`
            rsh $host "/mnt/support/update_login_banner.sh $UPDATEBANNER_FORMATTED $USERID"
        done

    elif [[ $FUNCTIONS == "install_netsim" ]]
    then
        for host in `echo $NETSIMSERVERLIST`
        do

            echo "INFO: Updating login Banner on $host"
            UPDATEBANNER_FORMATTED=`echo $UPDATEBANNER | sed "s/ /-/g"`
            rsh $host "/mnt/support/update_login_banner.sh $UPDATEBANNER_FORMATTED $USERID"
        done



    elif [[ $FUNCTIONS == "arne_dump" ]]
    then
        for host in `echo $NETSIMSERVERLIST`
        do

            echo "INFO: Updating login Banner on $host"
            UPDATEBANNER_FORMATTED=`echo $UPDATEBANNER | sed "s/ /-/g"`
            rsh $host "/mnt/support/update_login_banner.sh $UPDATEBANNER_FORMATTED $USERID"
        done
        #######################
        # GRAN function updates
        #######################
    elif [[ $FUNCTIONS == "setup_msc_smo" ]]
    then
        for host in `echo $NETSIMSERVERLIST`
        do

            echo "INFO: Updating login Banner on $host"
            UPDATEBANNER_FORMATTED=`echo $UPDATEBANNER | sed "s/ /-/g"`
            rsh $host "/mnt/support/update_login_banner.sh $UPDATEBANNER_FORMATTED $USERID"
        done
    elif [[ $FUNCTIONS == "setup_msc_smia" ]]
    then
        for host in `echo $NETSIMSERVERLIST`
        do

            echo "INFO: Updating login Banner on $host"
            UPDATEBANNER_FORMATTED=`echo $UPDATEBANNER | sed "s/ /-/g"`
            rsh $host "/mnt/support/update_login_banner.sh $UPDATEBANNER_FORMATTED $USERID"
        done
    elif [[ $FUNCTIONS == "setup_bsc_gprs" ]]
    then
        for host in `echo $NETSIMSERVERLIST`
        do

            echo "INFO: Updating login Banner on $host"
            UPDATEBANNER_FORMATTED=`echo $UPDATEBANNER | sed "s/ /-/g"`
            rsh $host "/mnt/support/update_login_banner.sh $UPDATEBANNER_FORMATTED $USERID"
        done

    fi



}

### Function: restart_relay ###
#
#  Restarts the netsim relay on each netsim
#
# Arguments:
#       none
# Return Values:
#       none
restart_relay()
{
    for host in `echo $NETSIMSERVERLIST`
    do
        echo "INFO: ReStarting relay on $host"
        $RSH -l root $host "/netsim/inst/bin/relay stop;/netsim/inst/bin/relay start" | $GREP -vi Display
    done
}

#ejershe
pm_rollout()
{
    if [[ "$NEWER_FUNCTIONS" == "y" ]]
    then
        pm_rollout_v2
        return
    fi

    #Copy over the config file again just in case
    echo "INFO: Copying $CONFIGFILE to $host again"
    copy_config_file_to_netsim

    #echo $NETSIMSERVERLIST
    for host in `echo $NETSIMSERVERLIST`
    do

        echo "INFO: Rolling out PM on $host"
        echo "INFO: Moving necessary files from atrclin3 to $host"
        LOCALDIR=`pwd`

        CONFIGFILE_FULLPATH="${LOCALDIR}/${CONFIGFILEARG}"
        /var/www/html/scripts/automation_wran/netsim_pm_setup/pm_move_files.sh $host $CONFIGFILE_FULLPATH

        if [ $? -eq 99 ]
        then
            echo "ERROR: pm_move_files.sh exited with an error"
            exit_routine
        fi

        echo "INFO: Configuring PM on $host"
        #/var/www/html/scripts/automation_wran/netsim_pm_setup/pm_setup_on_site.sh $host $CONFIGFILEARG
        /var/www/html/scripts/automation_wran/netsim_pm_setup/pm_setup_on_site.sh $host $CONFIGFILE_FULLPATH
        echo "INFO: Completed PM rollout on $host"
        UPDATEBANNER="PM Rollout"
        echo "INFO: Copying back orignal netsim_cfg file to $host"
        copy_config_file_to_netsim_orig

    done



}
pm_rollout_v2()
{
    #Copy over the config file again just in case
    #echo "INFO: Copying $CONFIGFILE to $host again"
    #copy_config_file_to_netsim

    #echo $NETSIMSERVERLIST
    for host in `echo $NETSIMSERVERLIST`
    do

        echo "INFO: Rolling out PM on $host"
        echo "INFO: Moving necessary files from atrclin3 to $host"
        LOCALDIR=`pwd`

        CONFIGFILE_FULLPATH="${LOCALDIR}/${CONFIGFILEARG}"
        /var/www/html/scripts/automation_wran/netsim_pm_setup/pm_move_files.sh $host $CONFIGFILE_FULLPATH

        if [ $? -eq 99 ]
        then
            echo "ERROR: pm_move_files.sh exited with an error"
            exit 123
        fi

        #/var/www/html/scripts/automation_wran/netsim_pm_setup/pm_setup_on_site.sh $host $CONFIGFILEARG
        UPDATEBANNER="PM Rollout"

        # Parallelized code below
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="PM Rollouts"
        PARALLEL_STATUS_STRING="PM Rollout on $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (
        /var/www/html/scripts/automation_wran/netsim_pm_setup/pm_setup_on_site.sh $host $CONFIGFILE_FULLPATH
        echo "INFO: Completed PM rollout on $host.."
        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables
    done
    parallel_wait
    #echo "INFO: Copying back orignal netsim_cfg file to $host"
    copy_config_file_to_netsim_orig

}
install_patch()
{
    for host in `echo $NETSIMSERVERLIST`
    do
        echo "INFO: Checking netsim version on $host"
        NETSIMVERSION=`rsh $host "/mnt/support/check_netsim_version.sh $host "`
        echo "INFO: $NETSIMVERSION is running on $host"
        echo "INFO: Retrieving list of patches for $NETSIMVERSION"

        #R22 is 6.2 and R23 is 6.3 - Could change in the future
        if [[ `echo "$NETSIMVERSION" | grep "R24"` != "" ]]
        then
            #R23*
            GENERATION="6.4"
        elif [[ `echo "$NETSIMVERSION" | grep "R23"` != "" ]]
        then
            #R23*
            GENERATION="6.3"

        elif [[ `echo "$NETSIMVERSION" | grep "R22"` != "" ]] 
        then
            #R22*
            GENERATION="6.2"
        fi

        echo "INFO: Netsim Generation is $GENERATION"
        #This came for a script on atrclin2 which is part of netsim install page. It retrieves a list of patches from the netsim Respository

        #Get the patch list
        PATCHLIST=`/usr/bin/wget -q -O - --no-proxy http://netsim.lmera.ericsson.se/tssweb/netsim${GENERATION}/released/NETSim_UMTS.${NETSIMVERSION}/Patches/index.html | /bin/grep -e P*\.zip\< -e P*tar\.Z\< | awk -F\" '{print $2 " "}' | tr -d '\n'`

        #Get the patch description list
        `/usr/bin/wget -q -O - --no-proxy http://netsim.lmera.ericsson.se/tssweb/netsim${GENERATION}/released/NETSim_UMTS.${NETSIMVERSION}/Patches/index.html | grep -e "lmera.ericsson.se" | awk -F".html\">" '{print $2}' | awk -F "<" '{print $1}'> .description.$host.delete`

        #Get patch create date
        `/usr/bin/wget -q -O - --no-proxy http://netsim.lmera.ericsson.se/tssweb/netsim${GENERATION}/released/NETSim_UMTS.${NETSIMVERSION}/Patches/index.html | egrep  '^<td>([0-9].*)</td>' | awk -F"td>" '{print $2}' | awk -F"</" '{print $1}' > .date.$host.delete`


        #Print out patch name and patch description
        count_patch=1
        echo "INFO: Available patches for $NETSIMVERSION"
        if [[ $PATCHLIST == "" ]]
        then
            echo "ERROR: Unable to retrieve patch list"
            exit_routine 1	
        fi 
        for patch in $PATCHLIST
        do
            count_description=1
            count_date=1
            DESCRITION_TO_USE=""
            DATE_TO_USE=""
            while read line	
            do	
                if [[ $count_description == $count_patch ]]
                then
                    DESCRITION_TO_USE=`sed -n ${count_description}p ".description.$host.delete"`
                    DATE_TO_USE=`sed -n ${count_date}p ".date.$host.delete"`
                else
                    count_description=`expr $count_description + 1`
                    count_date=`expr $count_date + 1`
                fi

            done<.description.$host.delete
            printf  "$patch      $DATE_TO_USE\t $DESCRITION_TO_USE\n"	

            count_patch=`expr $count_patch + 1`		
        done
        rm -rf .description.$host.delete
        rm -rf .date.$host.delete

        echo "INPUT: Please specify which patch you wish to install (example P01499_UMTS_R23D.zip ):"
        read PATCHINSTALL

        #Retrieve and install patch from netsim eth website
        PATCHLOCATION="$SCRIPTDIR/patches"

        if [[ ! -f $PATCHLOCATION/${PATCHINSTALL} ]]
        then
            echo "INFO: Downloading $PATCH"
            /usr/bin/wget --no-proxy -O "$PATCHLOCATION/${PATCHINSTALL}" "http://netsim.lmera.ericsson.se/tssweb/netsim${GENERATION}/released/NETSim_UMTS.${NETSIMVERSION}/Patches/$PATCHINSTALL"
            echo "http://www.netsim.eth.ericsson.se/tssweb/netsim${GENERATION}/released/NETSim_UMTS.${NETSIMVERSION}/Patches/$PATCHINSTALL"

            if [[ $? -ne 0 ]]
            then
                echo "ERROR: Error downloading $PATCHINSTALL"
                exit_routine 0
            fi
        else
            echo "INFO: $PATCHINSTALL already exists on atrclin3, not downloading"
        fi

        echo "INFO: Transfering $PATCHINSTALL to $host"
        $RCP $PATCHLOCATION/$PATCHINSTALL root@${host}:/netsim	

        if [[ $? -ne 0 ]]
        then
            echo "ERROR: Error Transfering  patch to $host"
            exit_routine 0
        fi

        #Check patch is not of size 0 bytes
        PATCH_FILESIZE=$(stat -c%s "$PATCHLOCATION/$PATCHINSTALL")
        if [[ $PATCH_FILESIZE == "0" ]]
        then
            echo "ERROR: Patch is of size 0 bytes, exiting"
            #remove bogus file
            rm -rf $PATCHLOCATION/$PATCHINSTALL
            exit_routine 0		
        fi

        echo "INFO: Installing $PATCHINSTALL on $host..."
        $RSH -l netsim  -n $host "echo \".install patch /netsim/$PATCHINSTALL force\" | /netsim/inst/netsim_shell"
        UPDATEBANNER="Patch Installed $PATCHINSTALL"

    done

}
check_installed_patches()
{
    echo "#####################################################"
    echo "INFO: Checking installed patches "	
    for host in `echo $NETSIMSERVERLIST`
    do

        $RSH -l netsim  -n $host "echo \".show installation\" | /netsim/inst/netsim_shell" > .show_patches.$host
        RETURNED_ERROR=`cat .show_patches.$host | grep -i ERROR | grep -v logtool`
        INSTALLEDPATCHES=`cat .show_patches.$host | egrep "^P"`

        echo "---------------------------------------------------------"
        echo "$host"
        if [[ $INSTALLEDPATCHES == "" ]]
        then
            if [[ "$RETURNED_ERROR" != "" ]]
            then
                echo "DEBUG: An error may have occured retrieving patches, see below output from netsim"
                cat .show_patches.$host
            else
                echo "INFO: No patches installed"
            fi
        else 
            cat .show_patches.$host | egrep ^P
        fi

        rm -rf .show_patches.$host
    done
    echo "#####################################################"
}

install_netsim()
{
    if [[ "$NEWER_FUNCTIONS" == "y" ]]
    then
        install_netsim_v2
        return
    fi

    echo "INPUT: Installing netsim"
    printf "INPUT:Enter Version of netsim you wish to install (example R23H):"
    read INSTALLVERSION
    TYPE=ST
    PROJECT=R7
    for host in `echo $NETSIMSERVERLIST`
    do

        echo "INFO: Installing Netsim $INSTALLVERSION on $host , please wait..."
        echo "INFO: Installing in BACKGROUND...WAIT 10 MINUTES"
        UPDATEBANNER="TEP Installed $INSTALLVERSION"
        NETSIMSERVERIP=`$GETENT hosts $host | $AWK '{print $1}'`

        wget --no-proxy -O - "http://atrclin2.athtem.eei.ericsson.se/TCM3/NetsimSite/Include/installnetsim.php?machine=${NETSIMSERVERIP}&userid=${USERID}&p=${PROJECT}&v=${INSTALLVERSION}&t=${TYPE}&e=${USERID}" > /dev/null 2>&1 &

        #There seems to be rouge files getting created as a result of wget - Clean up this is
        ## ekemark: Cleaned up need for rm-rf below with -O - in wget
        ##   rm -rf "installnetsim.php*"

    done

}


install_netsim_v2()
{
    echo "INPUT: Installing netsim"
    printf "INPUT:Enter Version of netsim you wish to install (example R23H):"
    read INSTALLVERSION
    TYPE=ST
    PROJECT=R7
    for host in `echo $NETSIMSERVERLIST`
    do

        echo "INFO: Installing Netsim $INSTALLVERSION on $host"
        #echo "INFO: Installing in BACKGROUND...WAIT 10 MINUTES"
        UPDATEBANNER="TEP Installed $INSTALLVERSION"
        NETSIMSERVERIP=`$GETENT hosts $host | $AWK '{print $1}'`

        # Parallelized code below
        ###################################
        LOG_FILE=/tmp/${host}.$BASHPID.log
        PARALLEL_STATUS_HEADER="Installing netsim $INSTALLVERSION"
        PARALLEL_STATUS_STRING="Installing netsim $INSTALLVERSION on $host"
        # SHOW_STATUS_UPDATES="NO"
        # SHOW_OUTPUT_BORDERS="NO"
        ###################################
        (
        (
        wget --no-proxy -q -O - "http://atrclin2.athtem.eei.ericsson.se/TCM3/NetsimSite/Include/installnetsim.php?machine=${NETSIMSERVERIP}&userid=${USERID}&p=${PROJECT}&v=${INSTALLVERSION}&t=${TYPE}&e=${USERID}" > /dev/null 2>&1
        echo "INFO: Netsim installation on $host completed"
        ) > $LOG_FILE 2>&1;parallel_finish
        ) & set_parallel_variables

    done 
    parallel_wait
}
setup_rsh()
{
    NETSIMSERVERLIST=`$EGREP "^SERVERS=" $CONFIGFILE | $AWK -F\" '{print $2}'`
    if [ -n "$NETSIMSERVER"  ]
    then
        NETSIMSERVERLIST=$NETSIMSERVER
    fi
    for host in `echo $NETSIMSERVERLIST`
    do

        echo "INFO: Setting up rsh on $host"
        NETSIMSERVERIP=`$GETENT hosts $host | $AWK '{print $1}'`
        echo "INFO: $host IP address is $NETSIMSERVERIP"
        if [[ $NETSIMSERVERIP == "" ]]
        then
            echo "ERROR: nslookup for $host failed. Exiting..."
            exit 1
        fi
        RSHTEST=`$RSH $host "/bin/ls / | $GREP etc"`
        echo $RSHTEST | $GREP etc >> /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "INFO: First rsh test failed on $host, attempting to setup rsh using shroot as password"
            PASSWORD=shroot
            wget --no-proxy -O - "http://atrclin2.athtem.eei.ericsson.se/TCM3/NetsimSite/Include/Setup_rsh.php?password=${PASSWORD}&machine=${NETSIMSERVERIP}" > /dev/null 2>&1 & 

            RSHTEST=`$RSH $host "/bin/ls / | $GREP etc"`
            echo $RSHTEST | $GREP etc >> /dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo "INFO: Second rsh test failed on $host using shroot, please enter its password"
                echo "INPUT: Enter $host root password:"
                read PASSWORD

                wget --no-proxy -O - "http://atrclin2.athtem.eei.ericsson.se/TCM3/NetsimSite/Include/Setup_rsh.php?password=${PASSWORD}&machine=${NETSIMSERVERIP}" > /dev/null 2>&1 &
                RSHTEST=`$RSH $host "/bin/ls / | $GREP etc"`
                echo $RSHTEST | $GREP etc >> /dev/null 2>&1
                if [ $? -ne 0 ]; then
                    echo "ERROR: $host does not trust me. Exiting. Check if its contactable and hasn't got a full root disk."
                    exit 3
                else
                    echo "INFO: RSH setup looks ok now on $host"
                fi
            else
                echo "INFO: RSH setup looks ok now on $host"
            fi
        else
            echo "INFO: RSH setup looks ok already on $host"
        fi
    done
}


show_subnets_wran()
{
    for host in `echo $NETSIMSERVERLIST`
    do
        TOTALIPS=`$RSH $host "$IFCONFIG -a | $GREP inet | $WC -l"`
        TOTALVIPS=`expr $TOTALIPS - 2`

        echo "INFO: Total IP address available on $host is $TOTALIPS"
        IPREQD=0


        IPSUBS=`$RSH $host "/mnt/support/list_ip_subs.sh $host" | $GREP -vi Display`
        IPSUBSARRAY=()
        COUNT=1

        for ipsub in `echo $IPSUBS`
        do
            IPSUBSARRAY[$COUNT]=$ipsub
            COUNT=`expr $COUNT + 1`
            echo "INFO: ipsub is $ipsub" 
        done
    done

}

ssh_connection()
{
    if [ -z "$SERVER" ] 
    then
        echo "ERROR: You must specify either OSS Server -s or NETSim Server -n"
        exit_routine 1
    fi

    #A check to cater for removing entry from /root/.ssh/known_hosts
    #SSHCONNECTION_known_hosts=`ssh -o BatchMode=yes -o LogLevel=QUIET -oStrictHostKeyChecking=no root@${SERVER} 'ls' | tail -n 1`
    #   if [[ "$SSH_CONNECTION_known_hosts" != "" ]]
    #   then
    #       echo "WARNING: Removing entry from /root/.ssh/known_hosts on atrclin3"
    #       cat /root/.ssh/known_hosts | grep -v ${SERVER} > /tmp/known_hosts
    #       cat /tmp/known_hosts > /root/.ssh/known_hosts
    #fi

    #Or run this ssh-keygen -R
    ssh-keygen -R "$SERVER" > /dev/null 2>/dev/null

    #This is a special case for ssh so dont put in $SSH
    SSHCONNECTION_root=`ssh -o BatchMode=yes -o LogLevel=QUIET -oStrictHostKeyChecking=no root@${SERVER} 'hostname ; echo $? ' | tail -n 1`

    #root account
    if [[ $SSHCONNECTION_root == "0" ]]
    then
        echo "INFO: root SSH Is PASSWORDLESS"
    else
        echo "WARNING: root SSH is not PASSWORDLESS - Will I set it up(y/n)"
        read SSHSETUP
        echo "INFO: You will be prompted for $SERVER root password"
        perl -e "select(undef, undef, undef, 0.2)"

        if [[ $SSHSETUP == "y" ]]
        then
            echo "INFO: Adding atrclin3 trusted key to .ssh/authorized_keys for root"
            $SSH root@${SERVER} 'echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA1NtUQ3n0nvDsYwJIm0XueKeu9ePh5Y5Z4Rt1k6N/LV+Lxl4c9a3sXvaSE3o3bCE1QZRBkbcwHRn84pAN5n6yAapo6crP/4zethvOSsvzvnSb4Cu4vyp1tRf3rAXTEEpUTOySsnAMFq6r/EzbmOWdnqKmTd+SkP+tAO4qitQRTzn8jQTiYR/IqToyw/5KYvs6+w2xw6eVXVW/4aACz9/4K6kCUXcrZTtZ5j+qcvNfnyrOLMR/Jtxhd71X3P1kli+/KESPuZtfYczbBlX+QssVzpwTxF5ZoYXa9G17lFR4F28kZg1ah5C+vHXHp5rzcB/Wrdxbmtrqlg51ekYf1X6o4w== root@atrclin3" >> .ssh/authorized_keys'

            #atrclin2 entry
            echo "INFO: Adding atrclin2 trusted key to .ssh/authorized_keys for root"
            $SSH root@${SERVER} 'echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq4GeO+KFCsV0mcy3/A6RL7TBHIhirS5FppE+Boz6/Yu6/mSSCVEMb21ekYlKmOCqVebPQRBpprD3dO5zEvWROXL0SRFFGEmSyTt9NlCI0S7W6N/uNv3DGjxj+ukx4O65twhJUqXomike8ILo8OR6g9z5+Qj5HNi3RenP8+IP1MjuXEjGAzs8ZfN/RvyzxnDwlT/Lp8mw5QSBvcytAnCYLIlnlcFYxAaUhcg+rqFcT4OgSJEbWjnVSm8uDsZGMCJ1EvTwl6ny2KvzbmTjbFTyva6uKthMeHxvA2dS1mKO08PJZHqYf/5NSrD/ygU36b0qkw3RQQ15EEV7ET3p1Y1BbQ== root@atrclin2.athtem.eei.ericsson.se" >> .ssh/authorized_keys'

        else
            echo "INFO: Not setting up passwordless ssh on $SERVER"
        fi
    fi

    #nmsadm account
    SSHCONNECTION_nmsadm=`ssh -o BatchMode=yes -o LogLevel=QUIET -oStrictHostKeyChecking=no nmsadm@${SERVER} 'hostname ; echo $? ' | tail -n 1`
    if [[ $SSHCONNECTION_nmsadm == "0" ]]	
    then
        echo "INFO: nmsadm SSH Is PASSWORDLESS"	
    else
        echo "WARNING: nmsadm SSH is not PASSWORDLESS - Will I set it up(y/n)"
        read SSHSETUP
        echo "INFO: You will be prompted for $SERVER root password"
        perl -e "select(undef, undef, undef, 0.2)"

        if [[ $SSHSETUP == "y" ]]
        then

            #check is .ssh dir exists
            $SSH root@${SERVER} 'if [ ! -d /home/nmsadm/.ssh ];then echo "INFO: Creating /home/nmsadm/.ssh"; mkdir /home/nmsadm/.ssh;chown nmsadm /home/nmsadm/.ssh;fi'
            echo "INFO: Unlocking nmadm account"
            $SSH root@${SERVER} 'passwd -u nmsadm'

            echo "INFO: Adding trusted key to .ssh/authorized_keys for nmsadm"
            echo "INFO: chown and chmod 700  .ssh/authorized_keys for nmsadm"
            $SSH root@${SERVER} 'echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA1NtUQ3n0nvDsYwJIm0XueKeu9ePh5Y5Z4Rt1k6N/LV+Lxl4c9a3sXvaSE3o3bCE1QZRBkbcwHRn84pAN5n6yAapo6crP/4zethvOSsvzvnSb4Cu4vyp1tRf3rAXTEEpUTOySsnAMFq6r/EzbmOWdnqKmTd+SkP+tAO4qitQRTzn8jQTiYR/IqToyw/5KYvs6+w2xw6eVXVW/4aACz9/4K6kCUXcrZTtZ5j+qcvNfnyrOLMR/Jtxhd71X3P1kli+/KESPuZtfYczbBlX+QssVzpwTxF5ZoYXa9G17lFR4F28kZg1ah5C+vHXHp5rzcB/Wrdxbmtrqlg51ekYf1X6o4w== root@atrclin3" >> /home/nmsadm/.ssh/authorized_keys;chown nmsadm /home/nmsadm/.ssh/authorized_keys;chmod 700 /home/nmsadm/.ssh/authorized_keys'

        else
            echo "INFO: Not setting up passwordless ssh on $SERVER"
        fi
    fi


}

create_pem_files()
{
    #check can you ssh to OSS server
    ssh_connection
    SSHCONNECTION=`ssh -o BatchMode=yes -o LogLevel=QUIET -oStrictHostKeyChecking=no root@${SERVER} 'hostname ; echo $? '`
    if [[ $? != "0" ]]
    then
        echo "ERROR: Cannot ssh to $SERVER exiting..."
        exit_routine 1
    fi		

    #SCP over the createpem.* files

    #First check to see if the /home/nmsadm/tep dir exists, if not create it
    $SSH root@${SERVER} 'if [ ! -d /home/nmsadm/tep ];then echo "INFO: Creating /home/nmsadm/tep"; mkdir /home/nmsadm/tep;chown nmsadm /home/nmsadm/tep;fi' 

    echo "INFO: Copying over support/createpem.* to $SERVER"   
    $SCP support/createpem.* root@${SERVER}:/home/nmsadm/tep      

    echo "INFO: Verifying that the ossrc.p12 exists in /ericsson/config"
    VERIFYOSSRC_P12=`$SSH root@${SERVER} 'ls /ericsson/config/ossrc.p12 > /dev/null 2>&1;echo $? '`
    if [[ $VERIFYOSSRC_P12 != "0" ]]
    then
        echo "ERROR: Cannot find the /ericsson/config/ossrc.p12 file  exiting..."
        exit_routine 1
    else
        echo "INFO: Found /ericsson/config/ossrc.p12"
    fi 

    echo "INFO: Running createpem.sh on $SERVER"
    $SSH root@${SERVER} 'cd /home/nmsadm/tep;chmod 755 createpem.*;./createpem.sh /ericsson/config/ossrc.p12'

    #New perl script to parse total.pem
    $SSH root@${SERVER} 'cd /home/nmsadm/tep;rm -rf key.pem certs.pem cacerts.pem;./createpem.pl -certfile total.pem -certdir .'

    echo "INFO: Retrieving remote .pem files"
    echo "INFO: Verify subscripts/security/${SERVER} exists on atrclin3"
    if [ ! -d subscripts/security/${SERVER} ]
    then 
        echo "INFO: Creating subscripts/security/${SERVER}"; 
        mkdir subscripts/security/${SERVER}
    else
        echo "INFO: subscripts/security/${SERVER} exists on atrclin3"
    fi
    $SCP root@${SERVER}:/home/nmsadm/tep/*pem subscripts/security/${SERVER}
    echo "INFO: Pem file created - Specify -a ${SERVER} as part of rollout"


    #New perl script to parse total.pem
    ############### back up createpem.pl code ##################

    #KEY_FILESIZE=$(stat -c%s "subscripts/security/${SERVER}/key.pem")
    #if [[ $KEY_FILESIZE == "0" ]]
    #then
    #    echo "INFO: subscripts/security/${SERVER}/key.pem is of size 0 bytes"
    #    echo "INFO: Applying createpem.pl" 

    #    support/createpem.pl -certfile subscripts/security/${SERVER}/total.pem -certdir=subscripts/security/${SECURITY}/
    #fi
    ############### back up createpem.pl code ##################

}
cello_ping()
{
    #Always check you can ssh without a password
    ssh_connection

    for host in `echo $NETSIMSERVERLIST`
    do

        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        fi

        #check is tep dir created	
        $SSH root@${SERVER} 'if [ ! -d /home/nmsadm/tep ];then echo "INFO: Creating /home/nmsadm/tep"; mkdir /home/nmsadm/tep;chown nmsadm /home/nmsadm/tep;fi'

        #Retrieve the SubNetwork name from the CS
        echo "INFO: Retrieving the SubNetwork name from the CS"			
        $SCP support/subnetwork.sh  root@${SERVER}:/home/nmsadm/tep > /dev/null  2>&1		
        SubNetwork=`$SSH root@${SERVER} "chmod 755 /home/nmsadm/tep/subnetwork.sh; /home/nmsadm/tep/subnetwork.sh"`


        echo "INFO: SubNetwork is $SubNetwork"

        for SIMNAME in `echo $SIMLIST`
        do
            echo "####################################################"



            #LTE check as no LTE node is called LTE01
            #LTE nodes have no SubNetwork= eg. SubNetwork=ONRM_RootMo_R,MeContext=LTE01ERBS00001 ipAddress
            NODETYPE=`echo $SIMNAME  | grep LTE`

            if [[ $NODETYPE != "" ]]
            then
                #LTE
                SIMNAME="${SIMNAME}ERBS00001"
                echo "INFO: Retrieving ${SIMNAME}'s ipAddress from $SERVER"
                NODEIPADDRESS=`$SSH root@${SERVER} "/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s Seg_masterservice_CS la SubNetwork=${SubNetwork},MeContext=${SIMNAME} ipAddress" | awk -F\" '{print $2}'`
                echo "INFO: Command /opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s Seg_masterservice_CS la SubNetwork=${SubNetwork},MeContext=${SIMNAME} ipAddress"

            else
                #WRAN
                echo "INFO: Retrieving ${SIMNAME}'s ipAddress from $SERVER"
                NODEIPADDRESS=`$SSH root@${SERVER} "/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s Seg_masterservice_CS la SubNetwork=${SubNetwork},SubNetwork=${SIMNAME},MeContext=${SIMNAME} ipAddress" | awk -F\" '{print $2}'`
                echo "INFO: Command /opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s Seg_masterservice_CS la SubNetwork=${SubNetwork},SubNetwork=${SIMNAME},MeContext=${SIMNAME} ipAddress"
                #NODEIPADDRESS="192.18.9.188"

            fi


            CHECKIP=`echo $NODEIPADDRESS | egrep ^[0-9]`
            if [[ $CHECKIP == "" ]]
            then
                echo "WARNING: Could not retrieve $SIMNAME ipAddress"
                echo "WARNING: Skipping $SIMNAME"

            else


                echo "INFO: $SIMNAME--> $NODEIPADDRESS"
                $SCP support/celloping.sh  root@${SERVER}:/home/nmsadm/tep > /dev/null  2>&1
                echo "INFO: Cello ping results for $SIMNAME,$host Please wait..."

                $SSH root@${SERVER} "chmod 755 /home/nmsadm/tep/celloping.sh; /home/nmsadm/tep/celloping.sh ${NODEIPADDRESS}"
            fi

        done

    done
}

show_started()
{
    for host in `echo $NETSIMSERVERLIST`
    do
        $RSH -l netsim $host "/mnt/support/started_nodes.sh $host"	

    done
}
cstest_me()
{

    #Always check you can ssh without a password
    ssh_connection

    for host in `echo $NETSIMSERVERLIST`
    do

        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        echo "INFO: Checking node filter"
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        else
            echo "INFO: Filter not applied"
        fi

        for SIMNAME in `echo $SIMLIST`
        do
            echo "####################################################"
            echo "INFO: cstest for ${SIMNAME}'s ManagedElement"
            $SSH root@${SERVER} "/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s ONRM_CS lt ManagedElement  | grep  ${SIMNAME}"


        done

    done
}
cstest_all()
{

    #Always check you can ssh without a password
    ssh_connection

    echo "####################################################"
    echo "INFO: cstest for all  ManagedElement"
    $SSH root@${SERVER} "/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s ONRM_CS lt ManagedElement  "


}

check_mims()
{
    ssh_connection
    if [ -z "$SERVER" ]
    then
        echo "ERROR: You must specify either OSS Server -s or NETSim Server -n"
        exit_routine 1
    fi
    echo "INFO: Copying across support/sort_mim_versions.sh to ${SERVER}"
    $SSH root@${SERVER} 'if [ ! -d /home/nmsadm/tep ];then echo "INFO: Creating /home/nmsadm/tep"; mkdir /home/nmsadm/tep;chown nmsadm /home/nmsadm/tep;fi'
    $SCP support/sort_mim_versions.sh root@${SERVER}:/home/nmsadm/tep

    echo "INFO: Running sort_mim_versions.sh on ${SERVER}"
    $SSH root@${SERVER} "chmod 755 /home/nmsadm/tep/sort_mim_versions.sh;/home/nmsadm/tep/sort_mim_versions.sh"

}

cstest_ftp()
{
    #Always check you can ssh without a password
    ssh_connection

    echo "INFO: cstest retrieving FtpServices from ${SERVER}"
    echo "INFO: Command used /opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s ONRM_CS lt  FtpService"
    $SSH root@${SERVER} "/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s ONRM_CS lt  FtpService"




}

arne_validate()
{
    ssh_connection
    echo "INFO: Uploading arne_validate.sh to /home/nmsadm/tep"
    $SCP support/arne_validate.sh  nmsadm@${SERVER}:/home/nmsadm/tep > /dev/null  2>&1

    echo "INFO: Attempting to validate the ARNE xml files on $SERVER"
    if [ -n "$ROLLOUT" ] && [ -n "$NODEFILTER" ]
    then
        $SSH nmsadm@${SERVER} "chmod 755 /home/nmsadm/tep/arne_validate.sh; /home/nmsadm/tep/arne_validate.sh -r $ROLLOUT -g $NODEFILTER"
    elif [ -n "$NODEFILTER" ]
    then
        $SSH nmsadm@${SERVER} "chmod 755 /home/nmsadm/tep/arne_validate.sh; /home/nmsadm/tep/arne_validate.sh -g $NODEFILTER"
    elif [ -n "$ROLLOUT" ]
    then

        $SSH nmsadm@${SERVER} "chmod 755 /home/nmsadm/tep/arne_validate.sh; /home/nmsadm/tep/arne_validate.sh -r $ROLLOUT"
    else

        $SSH nmsadm@${SERVER} "chmod 755 /home/nmsadm/tep/arne_validate.sh; /home/nmsadm/tep/arne_validate.sh "

    fi



}

arne_import()
{
    ssh_connection
    echo "INFO: Uploading arne_import.sh to /home/nmsadm/tep"
    $SCP support/arne_import.sh  nmsadm@${SERVER}:/home/nmsadm/tep > /dev/null  2>&1


    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Turn on tracing
    # Comment in arne_tracing if ARNE IMPORT GIVS Errors
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


    arne_tracing

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    echo "INFO: Attempting to import the ARNE xml files on $SERVER"
    echo "INFO: Tracing is on"	

    if [ -n "$ROLLOUT" ] && [ -n "$NODEFILTER" ]
    then

        $SSH nmsadm@${SERVER} "chmod 755 /home/nmsadm/tep/arne_import.sh ; /home/nmsadm/tep/arne_import.sh -g $NODEFILTER -r $ROLLOUT"

    elif [ -n "$ROLLOUT" ]
    then

        $SSH nmsadm@${SERVER} "chmod 755 /home/nmsadm/tep/arne_import.sh ; /home/nmsadm/tep/arne_import.sh -r $ROLLOUT"
    elif [[ -n "$NODEFILTER" ]]
    then
        $SSH nmsadm@${SERVER} "chmod 755 /home/nmsadm/tep/arne_import.sh ; /home/nmsadm/tep/arne_import.sh -g $NODEFILTER "

    else

        $SSH nmsadm@${SERVER} "chmod 755 /home/nmsadm/tep/arne_import.sh ; /home/nmsadm/tep/arne_import.sh "

    fi


    echo "NOTICE: If import was sucessful please run -f arne_dump"
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Running startAdjust and online MAF if arne_tracing is commented in
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    #start_adjust_maf

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Stop arne tracing
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    arne_tracing_stop

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

}

arne_delete()
{
    ssh_connection
    echo "INFO: Uploading arne_delete.sh to /home/nmsadm/tep"
    $SCP support/arne_delete.sh  nmsadm@${SERVER}:/home/nmsadm/tep > /dev/null  2>&1

    #turn on tracing
    #arne_tracing

    echo "INFO: Attempting to perform an ARNE delete on $SERVER"
    echo "INFO: Tracing is on"
    $SSH nmsadm@${SERVER} "chmod 755 /home/nmsadm/tep/arne_delete.sh ; /home/nmsadm/tep/arne_delete.sh $NODEFILTER"

    #Running startAdjust and online MAF
    #start_adjust_maf
}

arne_tracing()
{
    ssh_connection
    echo "INFO: Setting on tracing on $SERVER"
    $SCP support/arne_tracing.sh  nmsadm@${SERVER}:/home/nmsadm/tep > /dev/null  2>&1
    $SCP support/arne_tracing_backup.sh  nmsadm@${SERVER}:/home/nmsadm/tep > /dev/null  2>&1

    $SSH nmsadm@${SERVER} "chmod 755 /home/nmsadm/tep/arne_tracing.sh; /home/nmsadm/tep/arne_tracing.sh "

}

arne_tracing_stop()
{
    ssh_connection
    echo "INFO: Stopping arne tracing on $SERVER"
    $SCP support/arne_tracing_stop.sh  nmsadm@${SERVER}:/home/nmsadm/tep > /dev/null  2>&1

    $SSH nmsadm@${SERVER} "chmod 755 /home/nmsadm/tep/arne_tracing.sh; /home/nmsadm/tep/arne_tracing_stop.sh "


}

start_adjust_maf()
{
    ssh_connection
    echo "INFO: Running startAdjust.sh on $SERVER"
    $SCP support/start_adjust_maf.sh  nmsadm@${SERVER}:/home/nmsadm/tep > /dev/null  2>&1

    $SSH nmsadm@${SERVER} "chmod 755 /home/nmsadm/tep/start_adjust_maf.sh; /home/nmsadm/tep/start_adjust_maf.sh "
    if [ $? -ne 0 ]; 
    then
        exit_routine;
    fi
    echo "INFO: StartAdjust completed..."
    echo "INFO: Verifying if MAF adjust ran successfully"
    MAF_ADJUST=`$SSH nmsadm@${SERVER} "/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s Seg_masterservice_CS lt ManagedElement | egrep -i '(rnc|lte)' | wc -l"`
    ONRM_CONTENTS=`$SSH nmsadm@${SERVER} "/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s ONRM_CS lt ManagedElement  | egrep -i '(rnc|lte)' | wc -l"`
    if [[ $MAF_ADJUST == "0" ]]
    then
        echo "WARNING: startAdjust seems to have been unsucessfull"
    else
        echo "INFO: Number of RNC|RXI|RBS|ERBS nodes synced in MAF is $MAF_ADJUST"
        echo "INFO: Number of RNC|RXI|RBS|ERBS nodes in ONRM is       $ONRM_CONTENTS"
    fi


}
verify_MAF()
{
    ssh_connection


    echo "INFO: Verifying ONRM and SEG_CS"
    MAF_ADJUST=`$SSH nmsadm@${SERVER} "/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s Seg_masterservice_CS lt ManagedElement | egrep -i '(rnc|lte)' | wc -l"`
    ONRM_CONTENTS=`$SSH nmsadm@${SERVER} "/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s ONRM_CS lt ManagedElement  | egrep -i '(rnc|lte)' | wc -l"`
    if [[ $MAF_ADJUST == "0" ]]
    then
        echo "WARNING: startAdjust seems to have been Unsucessfull"
    else
        echo "INFO: Number of RNC|RXI|RBS|ERBS nodes synced in MAF is $MAF_ADJUST"
        echo "INFO: Number of RNC|RXI|RBS|ERBS nodes in ONRM is       $ONRM_CONTENTS"
    fi


}
arne_dump()
{
    date=`date`
    formated_date=`echo $date  | awk '{print $2 "_" $3 "_" $NF}'`

    ssh_connection
    echo "INFO: Dumping the CS on $SERVER"
    $SCP support/arne_dump.sh  nmsadm@${SERVER}:/home/nmsadm/tep > /dev/null  2>&1

    $SSH nmsadm@${SERVER} "chmod 755 /home/nmsadm/tep/arne_dump.sh; /home/nmsadm/tep/arne_dump.sh "
    UPDATEBANNER="The CS dump is located in /home/nmsadm/tep/CS_dump_${formated_date}.log"

}


check_pm()
{
    for host in `echo $NETSIMSERVERLIST`
    do
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`

        #Apply filter to SIMLIST
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        fi

        for SIM in $SIMLIST
        do

            #Retrieve netsim MO 	
            echo "INFO: Running pm check for $SIM"
            performanceDataPath=`$RSH -l netsim $host "/mnt/support/check_pm.sh $SIM $host" | grep performanceDataPath= | grep netsim_users`

            #Check if performanceDataPath is poing to netsim_users
            if [[ $performanceDataPath == "" ]]
            then
                echo "WARNING: PM for $SIM on $host does not appear to be setup correctly"
            else
                echo "INFO: PM for $SIM on $host appears to be setup correctly"
            fi
        done
    done


}




delete_sim()
{
    for host in `echo $NETSIMSERVERLIST`
    do

        SIMLIST=`$RSH -l netsim $host " ls /netsim/netsimdir | $GREP -v default | $GREP -v exported_items | $GREP -v indexlogfile | $GREP -v logfiles | $GREP -v mmlscripts | $GREP -v mmltest | $GREP -v tmp | $GREP -v user_cmds | $GREP -v .sh | $GREP -v mpfg" | $GREP -E '(RNC|LTE|DOG)'`	
        echo "################################################################"
        printf "INFO: Sims on $host  \n$SIMLIST \n"
        echo "################################################################"
        printf "INFO: Enter the sim(s) you wish to delete (Multiple? Seperated by a space):"

        read DELETE_SIM


        for SIM in $DELETE_SIM
        do
            if [ -n "`echo $SIM | $EGREP .zip$`" ]
            then
                echo "INFO: Deleting $SIM on $host"
                $RSH -n -l netsim $host "echo ".delsim $SIM force" | $NETSIMSHELL"
            else
                echo "INFO: Deleting $sim on $host"
                $RSH -n $host "/mnt/support/delete_users.sh $host $SIM"
                $RSH -n -l netsim $host "/netsim/inst/restart_gui;echo ".delsim $SIM force" | $NETSIMSHELL"
            fi

        done
    done


}

sim_patch()
{
    printf "INFO: Enter sim_patch location on atrclin3 (eg patches/011.1/LTE)"
    read SIM_PATCH_LOCATION


    for host in `echo $NETSIMSERVERLIST`
    do

        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`



        for SIM in $SIMLIST
        do

            echo "INFO: Moving sim_patches to $host"
            echo "INFO: Making /netsim/${SIM_PATCH_LOCATION} on $host"
            $RSH -n -l netsim $host "if [ ! -d /netsim/${SIM_PATCH_LOCATION} ];then echo "INFO: Creating /netsim/${SIM_PATCH_LOCATION}"; mkdir -p /netsim/${SIM_PATCH_LOCATION};fi"


            echo "INFO: Moving across files to /netsim/${SIM_PATCH_LOCATION}"
            $RCP ${SIM_PATCH_LOCATION}/* root@${host}:/netsim/${SIM_PATCH_LOCATION}

            echo "INFO: Changing permissions..."
            $RSH -n -l root $host "chown netsim /netsim/${SIM_PATCH_LOCATION}/*;chmod 777 /netsim/${SIM_PATCH_LOCATION}/*"
            $RSH -n -l netsim $host "/mnt/support/sim_patch.sh $SIM /netsim/${SIM_PATCH_LOCATION}"


        done
    done


}

### Function: restart_arne_mcs ###
#
#   Cold Restarts the arne related mcs
#
# Arguments:
#       none
# Return Values:
#       none
restart_arne_mcs()
{

    ARNE_MCS="ARNE MAF ONRM"
    RESTART_COMMAND="/opt/ericsson/nms_cif_sm/bin/smtool -coldrestart $ARNE_MCS -reason=other -reasontext='For ARNE Import';/opt/ericsson/nms_cif_sm/bin/smtool prog"

    ssh_connection
    echo "INFO: Cold Restarting the arne related MC's, $ARNE_MCS"
    echo "INFO: Command $RESTART_COMMAND"

    $SSH nmsadm@${SERVER} "$RESTART_COMMAND"

    echo "INFO: Cold Restart completed"
}

sim_summary_wran()
{
    #Summary of sims

    for host in `echo $NETSIMSERVERLIST`
    do
        SIMLIST=`$EGREP "^${host}_list=" $CONFIGFILE | $AWK -F\" '{print $2}'`
        saved_date_dir=`ls -rt ./savedconfigs/$host/ | tail -n 1`


        ################ Node filter #################
        #Apply filter to SIMLIST
        if [[ $NODEFILTER != "" ]]
        then
            echo "INFO: Applying filter - $NODEFILTER "
            echo "INFO: SIMLIST before filter $SIMLIST"
            for NODE in $SIMLIST
            do
                if [[ $NODEFILTER == "$NODE" ]]
                then
                    SIMLIST=$NODE
                fi
            done
            echo "INFO: SIMLIST after filter $SIMLIST"
        fi
        #echo "INFO: SIMLIST: $SIMLIST"
        ############## Available Subnets  ##############

        TOTALIPS=`$RSH $host "$IFCONFIG -a | $GREP inet | $WC -l"`
        TOTALVIPS=`expr $TOTALIPS - 2`

        #echo "INFO: Total IP address available on $host is $TOTALIPS"
        IPREQD=0


        IPSUBS=`$RSH $host "/mnt/support/list_ip_subs.sh $host" | $GREP -vi Display`
        IPSUBSARRAY=()
        COUNT=1

        for ipsub in `echo $IPSUBS`
        do
            IPSUBSARRAY[$COUNT]=$ipsub



            for SIM in $SIMLIST
            do
                ARNE_FILE=`ls ./savedconfigs/$host/${saved_date_dir}/arnefiles/import-v2*create*xml | grep "$SIM"`

                if [[ $ARNE_FILE != "" ]]
                then

                    SUBNET_CHECK=`cat $ARNE_FILE | $GREP "<ipAddress ip"  | grep $ipsub`
                    MIM_VERSION=`cat $ARNE_FILE | $GREP "<neMIMVersion" | $AWK -F"\"v" '{print $2}' | $AWK -F"\"" '{print $1}' | head -n 1`
                    if [[ $SUBNET_CHECK != "" ]]
                    then
                        echo "INFO: $SIM --> MimType $MIM_VERSION Subnet${COUNT}: $ipsub $host "
                    fi
                else
                    echo "WARNING: No Arne file found for $SIM..bypassing"	
                fi




            done

            COUNT=`expr $COUNT + 1`
        done




    done
}


last_run_command()
{

    # ********************************************************************
    # Log commands that are run
    # ********************************************************************

    date=`date`
    formated_date=`echo $date  | awk '{print $2 "_" $3 "_" $NF}'`
    time_now=`echo $date | awk '{print $4}'`
    logging_dir="/home/rollout/logs/${USERID}"
    if [ ! -d $logging_dir ]
    then
        $MKDIR -p $logging_dir
        chown rollout $logging_dir
    fi
    if [[ $USERID == "" ]]
    then
        echo "WARNING: Problem logging run.sh arguments"
    else

        LAST_COMMAND_RUN="$0 $ALL_COMMAND_ARGUMENTS"
        echo "$time_now    $LAST_COMMAND_RUN">>${logging_dir}/${formated_date}.log
        #echo "INFO: Last Command Logged to ${logging_dir}/${formated_date}.log $LAST_COMMAND_RUN"
    fi

    # ********************************************************************

}
history()
{

    # ********************************************************************
    # commands that were run
    # ********************************************************************

    date=`date`
    formated_date=`echo $date  | awk '{print $2 "_" $3 "_" $NF}'`
    time_now=`echo $date | awk '{print $4}'`
    logging_dir="/home/rollout/logs/${USERID}"
    if [[ $USERID == "" ]]
    then
        echo "ERROR: USERID required -u "
        exit 1
    else


        echo "INFO: History for $USERID (limt 10 log files)"
        $LS -rt ${logging_dir}/* | tail -n 10 | while read line
    do
        echo "FILE: $line"
        $CAT $line
    done

fi

# ********************************************************************

}

### Function: exit_routine ###
#
#   Perform exiting routine
#
# Arguments:
#       none
# Return Values:
#       none
exit_routine()
{
    #You dont need to umount if cello_ping is the function

    if [[ $FUNCTIONS != "cello_ping" ]]
    then

        for netsimserver in $NETSIMSERVERLIST
        do
            echo "INFO: Exiting script"
            echo "INFO: Cleaning up on $netsimserver"    
            RSHTEST=`$RSH $netsimserver "/bin/ls $MOUNTPOINT | $GREP config.cfg"`
            echo $RSHTEST | $GREP config.cfg >> /dev/null 2>&1
            echo "INFO: Restoring /etc/exports on `hostname`"
            NETSIMSERVERIP=`$GETENT hosts $netsimserver | $AWK '{print $1}'`
            $EGREP -v "$SCRIPTDIR $NETSIMSERVERIP\(no_root_squash,rw,sync\)" /etc/exports > /tmp/exports.$DATE
            if [ -f /tmp/exports.lock ]
            then
                echo -e "INFO: /etc/exports lock file exists, will try again.\c"
                while [ -f /tmp/exports.lock ]
                do
                    $SLEEP 1
                    echo -e ".\c"
                done
                echo -e "INFO: Lock file removed"
            fi
            $TOUCH /tmp/exports.lock
            $CP /tmp/exports.$DATE /etc/exports
            exportfs -r > /dev/null
            $RM /tmp/exports.lock
            if [ $? -eq 0 ];then
                echo "INFO: Unmounting $MOUNTPOINT on $netsimserver"
                $RSH $netsimserver $UMOUNT -f $MOUNTPOINT > /dev/null
            fi
            RSHTEST=`$RSH $netsimserver "/bin/ls $MOUNTPOINT | $GREP config.cfg"`
            echo $RSHTEST | $GREP config.cfg >> /dev/null 2>&1
            if [ $? -eq 0 ];then
                echo "ERROR: $netsimserver Cannot unmount $MOUNTPOINT on $netsimserver. Please investigate."
            else
                echo "INFO: $netsimserver Cleanup complete."
            fi
        done
    else

        echo "INFO: Functions set to $FUNCTIONS"
        echo "INFO: No need for umount"
    fi

    exit $1
}

cleanup_pipe()
{
    # Remove the temporary named pipe used to log output to file
    rm $npipe > /dev/null 2>&1
}

#######
#MAIN##
#######
#Source gran functions
. /var/www/html/scripts/automation_wran/gran.sh
trap ctrl_c INT
trap cleanup_pipe EXIT TERM

while getopts "f:s:n:a:d:c:i:o:u:g:r:z:" arg
do
    case $arg in
        d) DEPLOYMENT="$OPTARG"
            ;;
        s) SERVER="$OPTARG"    
            ;;
        n) NETSIMSERVER="$OPTARG"    
            ;;
        a) SECURITY="$OPTARG"
            ;;
        c) CONFIGFILEARG="$OPTARG"
            ;;
        f) FUNCTIONS="$OPTARG"
            ;;
        i) INTERACTION="$OPTARG"
            ;;
        o) OFFSET="$OPTARG"
            ;;
        u) USERID="$OPTARG"
            ;;
        g) NODEFILTER="$OPTARG"
            ;;
        r) ROLLOUT="$OPTARG"
            ;;
        z) NEWER_FUNCTIONS="$OPTARG"
            ;;
        \?) usage_msg
            exit 1
            ;;
    esac
done


#List of functions that dont need to run mount_scripts_directory function"
if [[ $FUNCTIONS != "history" ]]
then
    last_run_command
fi

FUNCTION_NO_MOUNT="create_pem_files cstest_ftp cstest_me cello_ping ssh_connection arne_validate arne_import cstest_all check_mims arne_delete restart_arne_mcs"
if [[ $FUNCTIONS != "" ]]
then
    echo "INFO: Checking FUNCTION_CHECKER"
    FUNCTION_CHECKER=`echo $FUNCTION_NO_MOUNT | grep $FUNCTIONS` 
fi

if [[ $FUNCTION_CHECKER != "" ]]
then
    check_args
    check_config_file
    get_netsim_servers
    $FUNCTIONS
    update_login_banner
elif [[ $FUNCTIONS == "setup_rsh" ]]
then
    check_args
    check_config_file
    setup_rsh
elif [[ $ROLLOUT == "GRAN" ]] # -r option makes it a GRAN rollout
then
    echo "INFO: GRAN Rollout"
    if [[ $FUNCTIONS == "" ]]
    then
        check_args
        check_config_file
        get_netsim_servers
        mount_scripts_directory
        check_os_details
        ssh_connection
        rollout_preroll
        get_sims_gran
        make_ports_gran
        make_destination
        rename_all
        set_ips_gran
        set_cpus
        #enable_internal_ssh
        start_all
        lanswitch_acl
        check_ssh_setup
        create_users_gran
        login_banner
        exit_routine 0
    else
        check_args
        check_config_file
        get_netsim_servers
        mount_scripts_directory
        check_os_details
        ssh_connection
        $FUNCTIONS
        update_login_banner
        exit_routine 0

    fi

elif [ -n "$FUNCTIONS" ]
then
    check_args
    check_config_file
    get_netsim_servers
    mount_scripts_directory
    $FUNCTIONS
    update_login_banner
    exit_routine 0

else
    check_args
    check_config_file
    get_netsim_servers
    mount_scripts_directory
    check_os_details
    ssh_connection
    rollout_preroll
    make_ports
    get_sims
    set_ips
    set_security
    deploy_amos_and_c
    start_all
    delete_scanners
    create_scanners
    setup_variables
    #save_and_compress
    create_users
    copy_config_file_to_netsim
    generate_ip_map
    post_scripts
    login_banner
    save_config
    exit_routine 0
fi
