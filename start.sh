#!/bin/bash
TRUE="true"
FALSE="false"
SCRIPT_DIR=$(dirname $(readlink -e $0))

. ${SCRIPT_DIR}/tools.sh

echo "DOCKER_BRIDGE_IP=$DOCKER_BRIDGE_IP"

#service sshd start
#/etc/init.d/ssh start
#nohup /usr/sbin/sshd -D > /var/log/sshd.log 2>&1

SRV_HDFS_NAMENODE="hdfs_nn"
HADOOP_CONF_CORE=$HADOOP_CONF_DIR/core-site.xml
HADOOP_CONF_HDFS=$HADOOP_CONF_DIR/hdfs-sit.xml

HDFS=${HADOOP_HOME}/bin/hdfs
ACTION_NAMENODE="namenode"
ACTION_DATANODE="datanode"
#ACTION_STOP="stop"
OPTION_CONFIG="--config"
NAMENODE_OPTION_FORMAT="--format"

SRV_RESOLVER=/opt/srv_resolver.sh

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

function func_check_hdfs_formatted(){
    local ls_tmp=$(ls /tmp | grep hadoop | awk '{print $1}')
    if [ -z $ls_tmp ]; then
        echo $FALSE
    else
        echo $TRUE
    fi
}

function func_configure_hdfs(){
    local unset hdfs_nn_ip
    while true; do
        hdfs_nn_ip=$($SRV_RESOLVER -i $SRV_HDFS_NAMENODE | awk '{print $1}')
#        hdfs_nn_ip=192.168.1.188
        if [ ! -z $hdfs_nn_ip ]; then
            echo "$SRV_HDFS_NAMENODE is resolved as $hdfs_nn_ip"
            if [ ! -z $hdfs_nn_ip ]; then
                sed -i 's/HDFS_NAMENODE/'"$hdfs_nn_ip"'/g' $HADOOP_CONF_CORE
            fi
            break
        else
            echo "CANNOT resolve service, $SRV_HDFS_NAMENODE"
            sleep 1
        fi

    done
}

function func_configure(){
    tool_template_fill_in_in_place $HDFS_CONF_CORE "NAMENODE_SERVICE_NAME" $NAMENODE_SERVICE_NAME
    tool_template_fill_in_in_place $HDFS_CONF_HDFS "SECONDARY_NAMENODE_SERVICE_NAME" $SECONDARY_NAMENODE_SERVICE_NAME
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
#    sed -i 's/HDFS_NAMENODE/localhost/g' $HADOOP_CONF_CORE
    local unset cmd
    local is_formatted=$(func_check_hdfs_formatted)
    if [ $namenode_format ] && [[ $is_formatted == $FALSE ]]; then
        cmd="$HDFS namenode -format && "
    fi

    if [ -z $conf_dir ]; then
        cmd="$cmd $HDFS namenode"
    else
        cmd="$cmd $HDFS $OPTION_CONFIG $conf_dir namenode"
    fi
    echo "run $cmd"
    eval $cmd
}

function action_run_secondary_namenode(){
    if [ -z $conf_dir ]; then
        eval $HDFS secondarynamenode
    else
        eval $HDFS $OPTION_CONFIG $conf_dir secondarynamenode
    fi
}

function action_run_datanode(){
#    func_configure_hdfs
     if [ -z $conf_dir ]; then
        eval $HDFS datanode
    else
        eval $HDFS $OPTION_CONFIG $conf_dir datanode
    fi
}


function func_run_action(){
    case "$action" in
        namenode)
            func_configure
            action_run_namenode
            ;;
        secondarynamenode)
            func_configure
            action_run_secondary_namenode
            ;;
        datanode)
            func_configure
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
#func_check_process
func_init_log
func_run_action
