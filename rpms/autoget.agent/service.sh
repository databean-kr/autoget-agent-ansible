#!/bin/bash

PID=""

function get_pid {
   PID=`cat pid.txt`
}

function stop {
   get_pid
   if [ -z $PID ]; then
      echo "agent is not running."
      exit 1
   else
      echo -n "Stopping agent.."
      kill -9 $PID
      rm pid.txt
      sleep 1
      echo ".. Done."
   fi
}


function start {
   get_pid
   if [ -z $PID ]; then
      echo  "Starting agent.."
      ./start.sh
      get_pid
      echo "Done. PID=$PID"
   else
      echo "agent is already running, PID=$PID"
   fi
}

function restart {
   echo  "Restarting agent.."
   get_pid
   if [ -z $PID ]; then
      start
   else
      stop
      sleep 5
      start
   fi
}


function status {
   get_pid
   if [ -z  $PID ]; then
      echo "agent is not running."
      exit 1
   else
      echo "agent is running, PID=$PID"
   fi
}

case "$1" in
   start)
      start
   ;;
   stop)
      stop
   ;;
   restart)
      restart
   ;;
   status)
      status
   ;;
   *)
      echo "Usage: $0 {start|stop|restart|status}"
esac
