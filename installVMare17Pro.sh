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

cd /tmp

# https://github.com/201853910/VMwareWorkstation/releases
wget https://github.com/201853910/VMwareWorkstation/releases/download/17.0/VMware-Workstation-Full-17.5.0-22583795.x86_64.bundle

apt install build-essential dkms

chmod +x VMware-Workstation-Full-17.5.0-22583795.x86_64.bundle

bash VMware-Workstation-Full-17.5.0-22583795.x86_64.bundle

# 金鑰
# https://gist.github.com/PurpleVibe32/30a802c3c8ec902e1487024cdea26251

# --checked
# MC60H-DWHD5-H80U9-6V85M-8280D < worked for me!
# 4A4RR-813DK-M81A9-4U35H-06KND
# --unchecked
# NZ4RR-FTK5H-H81C1-Q30QH-1V2LA
# JU090-6039P-08409-8J0QH-2YR7F
# 4Y09U-AJK97-089Z0-A3054-83KLA
# 4C21U-2KK9Q-M8130-4V2QH-CF810