#!/bin/bash

sudo service autoget-agent stop
sudo rm /usr/lib/systemd/system/autoget-agent.service
echo "Uninstalled"
