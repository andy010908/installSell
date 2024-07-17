#!/bin/bash
# 參考：
# https://systemweakness.com/guide-to-installing-vmware-workstation-pro-on-ubuntu-22-04-in-2023-76bb5e2a242a

whoami=`whoami`
isSudoer=`id $whoami |grep sudo`

if [[ $whoami != "root" ]]; then
    if [[ $isSudoer == "" ]]; then
        echo -e "\e[1;31;47m!!! You Are not root or sudoer !!!\e[0m"
        echo ""
        exit 1;
    fi
fi

wget https://download.virtualbox.org/virtualbox/7.0.18/virtualbox-7.0_7.0.18-162988~Ubuntu~jammy_amd64.deb

apt install ./virtualbox-7.0_7.0.18-162988~Ubuntu~jammy_amd64.deb