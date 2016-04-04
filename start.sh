#!/bin/bash
SCRIPT_DIR=$(dirname $(readlink -e $0))

#service sshd start
#/etc/init.d/ssh start
#nohup /usr/sbin/sshd -D > /var/log/sshd.log 2>&1

HDFS=${HADOOP_HOME}/bin/hdfs
ACTION_NAMENODE="namenode"
ACTION_DATANODE="datanode"
#ACTION_STOP="stop"
OPTION_CONFIG="--config"
NAMENODE_OPTION_FORMAT="--format"

APP_HOME=$SCRIPT_DIR
PID_DIR=$APP_HOME/logs/pid
PID_FILE=hdfs.pid

unset action
unset conf_dir
unset namenode_format
#LOGS_DIR
#LOG_FILE

function func_usage(){
    #echo "${BASH_ARGV[${#BASH_ARGV[@]}-1]} [OPTION] <ACTION>"
    echo "start.sh [OPTION] <ACTION>"
    echo ""
    echo "ACTION"
    echo " $ACTION_NAMENODE [$NAMENODE_OPTION_FORMAT]"
    echo " $ACTION_DATANODE"
    echo ""
    echo "OPTION"
    echo " $OPTION_CONFIG confdir"
#    echo " $ACTION_STOP"
    exit
}

function func_parse_args(){
   local argp=0
   local argv=("$@")
   local argn=${#argv[@]}
   local unset remained_args
   ((remained_args=argn-argp))

   while true; do
       ((remained_args=argn-argp))
       if [[ ${argv[argp]} == $ACTION_NAMENODE ]]; then
           if [ $remained_args -eq 2 ] && [[ ${argv[argp+1]} == $NAMENODE_OPTION_FORMAT ]]; then
               namenode_format=true
           elif [ ! $remained_args -eq 1 ]; then
               func_usage
           fi
           action=$ACTION_NAMENODE
           ((argp++))
           break
       elif [ $remained_args -eq 1 ] && [[ ${argv[argp]} == $ACTION_DATANODE ]]; then
           action=$ACTION_DATANODE
           ((argp++))
           break
       elif [[ ${argv[argp]} == $OPTION_CONFIG ]]; then
           conf_dir=${argv[argp+1]}
           ((argp=argp+2))
           continue
       else
           func_usage
       fi
       break
   done

   echo $action
}

#function func_check_process(){}

function func_init_log(){
    if [ ! -d $PID_DIR ]; then
         mkdir -p $PID_DIR
    fi

    if [ -f $PID_DIR/$PID_FILE ]; then
         rm $PID_DIR/$PID_FILE
    fi
}

function action_run_namenode(){
    local unset cmd
    if [ $namenode_format ]; then
        cmd="$HDFS namenode -format && "
    fi

    if [ -z $conf_dir ]; then
        cmd="$cmd $HDFS namenode"
    else
        cmd="$cmd $HDFS $OPTION_CONFIG $conf_dir namenode"
    fi
    eval $cmd
}

function action_run_datanode(){
     if [ -z $conf_dir ]; then
        eval $HDFS datanode
    else
        eval $HDFS $OPTION_CONFIG $conf_dir datanode
    fi
}


function func_run_action(){
    case "$action" in
        namenode)
            action_run_namenode
            ;;
        datanode)
            action_run_datanode
            ;;
        *)
            func_usage
            ;;
    esac
}

argv=($@)
echo $@
func_parse_args ${argv[@]}
url=$(func_resolve_service namenode)
func_set_namenode_url $url
#func_check_process
func_init_log
func_run_action
