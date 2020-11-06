#!/bin/bash
sudo cp autoget-agent.service /usr/lib/systemd/system/
sudo systemctl enable autoget-agent
sudo service autoget-agent start
sudo service autoget-agent status
echo "Installed"
