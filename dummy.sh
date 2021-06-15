#!/bin/bash

mkdir -p /tmp/rom
cd /tmp/rom

# export sync start time
SYNC_START=$(date +"%s")


git config --global user.name GeoPD
git config --global user.email geoemmanuelpd2001@gmail.com


# Git cookies
echo "${GIT_COOKIES}" > ~/git_cookies.sh
bash ~/git_cookies.sh


# SSH
rclone copy brrbrr:ssh/ssh_ci /tmp
sudo chmod 0600 /tmp/ssh_ci
sudo mkdir ~/.ssh && sudo chmod 0700 ~/.ssh
eval `ssh-agent -s` && ssh-add /tmp/ssh_ci
ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

sleep 120m
