#!/bin/bash
# run this to check server status (every N minutes)
 
declare -a server_names=(
    "gather18"
    "publico1"
    )
 
server_dir="/home/tino/gathers/servers/"
 
for server_name in "${server_names[@]}"
do
    pid_file="$server_dir$server_name/logs/soldatserver.pid"
    stats_file="$server_dir$server_name/logs/gamestat.txt"
    exec_file="$server_dir$server_name/soldatserver -pid soldatserver.pid"
 
    # checking server PID
    if [ -f "$pid_file" ]; then
        pid=$(<"$pid_file")
 
        re='^[0-9]+$'
        if [[ $pid =~ $re ]] ; then
            # is it still running?
            if kill -0 $pid > /dev/null 2>&1
            then
                # checking for gamestat.txt modification time
                test_time=$(date -d 'now -1 minute' +%s)
                file_time=$(date -r "$stats_file" +%s)
 
                # is it *outdated*?
                if (( file_time > test_time )); then
                    echo "$server_name ($pid) is running fine"
 
                    continue
                else
                    # killing server process
                    echo "$server_name is about to be killed"
                    kill -9 $pid
                fi
            else
              echo "$server_name seems offline"
            fi
        fi
    fi
 
    # starting server process
    echo "$server_name is about to be (re)started"
    nohup $exec_file &>/dev/null &
done
 
exit
