#!/bin/bash
nohup ./main.pl 1>/dev/null 2>&1 &
echo $! > pid.txt
