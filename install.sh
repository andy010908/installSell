#!/bin/bash

whoami=`whoami`
isSudoer=`id $whoami |grep sudo`

username="gveda"
password="\$6\$1\$/oXqVUZ0eqjR.qgLeIx5sHnDVNp13xMQQGR4D.8pfzZlIDBWP.rDeSRWECJ.vNbOAm7kVFU14cm62CS05Q3Dm/"
# openssl passwd -6 -salt '1'
gvedaUser=`cut -d: -f1 /etc/passwd |grep $username`

docker=`which docker`
sshd=`which sshd`
dockerIsRunning=$(ps aux |grep docker|grep -v 'grep')
sshdIsRunnung=$(ps aux |grep sshd|grep -v 'grep')

dockerRepoName="harrison0925380621"
dockerImageName="gudphole"

isInstallDocker="Y"

function installDocker() {
    echo -e "\e[1;33;40mReady to install Docker... \e[0m"
    # https://docs.docker.com/engine/install/ubuntu/
    echo ""

    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

    # Add Docker's official GPG key:
    apt-get update
    apt-get install ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update

    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    docker=`which docker`
    dockerIsRunning=$(ps aux |grep docker|grep -v 'grep')
}

if [[ $whoami != "root" ]]; then
    if [[ $isSudoer == "" ]]; then
        echo -e "\e[1;31;47m!!! You Are not root or sudoer !!!\e[0m"
        echo ""
        exit 1;
    fi
fi

if [ ! $docker == "" ]; then
    echo -e "\e[1;34;40mDocker already install\e[0m"
    echo ""
else
    echo -e "\e[1;31;47m!!! Docker is not install !!!\e[0m"
    echo ""
    read -e -p $'\e[1;30;43mDo you want to isntall Docker ? \e[0m           [Y/n]:' -i "$isInstallDocker" isInstallDocker

    if [ "$isInstallDocker" == "Y" ]|| [ "$isInstallDocker" == 'y' ]; then
	    installDocker
    else    
        echo -e "\e[1;33;40mBye Bye ~\e[0m"
        echo ""
        exit 1;
    fi
fi

if [ ! $sshd == "" ]; then
    echo -e "\e[1;34;40msshd already install\e[0m"
    echo ""
else
    echo -e "\e[1;31;47m!!! sshd is not install !!!\e[0m"
    echo ""
    exit 1;
fi

if [[ ! $dockerIsRunning == "" ]]; then
    echo -e "\e[1;34;40mDocker is Running\e[0m"
    echo ""
else
    echo -e "\e[1;31;47m!!! Docker is close !!!\e[0m"
    echo ""
    exit 1;
fi

if [[ ! $sshdIsRunnung == "" ]]; then
    echo -e "\e[1;34;40msshd is Running\e[0m"
    echo ""
else
    echo -e "\e[1;31;47m!!! sshd is close !!!\e[0m"
    echo ""
    exit 1;
fi

if [[ $gvedaUser == "" ]]; then
    echo -e "\e[1;34;40mAdd user : $username\e[0m"
    echo ""
    adduser --gecos "" --disabled-password $username
    chpasswd -e <<<"$username:$password"
    usermod -aG docker $username
else
    echo -e "\e[1;33;40mUser  : $username is Exist !!\e[0m"
    echo ""
fi

#Start to Run Docker

 $docker container stop $dockerImageName > /dev/null 2>&1
 $docker rm -f $dockerImageName > /dev/null 2>&1
 $docker rmi -f $dockerRepoName/$dockerImageName > /dev/null 2>&1

 echo -e "\e[1;34;40mPull Docker Image from Docker Hub\e[0m"
 echo ""

 $docker pull $dockerRepoName/$dockerImageName
 echo -e "\e[1;34;40mRun Docker Container\e[0m"
 echo ""

 $docker run --name $dockerImageName -d -p 9595:9595 -p 4545:4545 $dockerRepoName/$dockerImageName

 echo -e "\e[1;33;40mDone.\e[0m"
