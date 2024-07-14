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
isInstallContainerToolkit="Y"

function installDocker() {
    echo -e "\e[1;33;40mReady to install Docker... \e[0m"
    # https://docs.docker.com/engine/install/ubuntu/
    echo ""

    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

    # Add Docker's official GPG key:
    apt-get update > /dev/null 2>&1
    apt-get install ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update > /dev/null 2>&1

    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    docker=`which docker`
    dockerIsRunning=$(ps aux |grep docker|grep -v 'grep')
}

function installNvidiaContainerToolkit(){
    echo -e "\e[1;33;40mReady to installing the NVIDIA Container Toolkit... \e[0m"
    # https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
    echo ""

    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    sed -i -e '/experimental/ s/^#//g' /etc/apt/sources.list.d/nvidia-container-toolkit.list
    apt-get update > /dev/null 2>&1

    apt-get install -y nvidia-container-toolkit
    nvidia-ctk runtime configure --runtime=docker

    systemctl restart docker

    echo -e "\e[1;33;40mCheck the NVIDIA Container Toolkit is OK\e[0m"
    echo ""
    $docker  run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi
}

function runDockerContainer() {
    $docker container stop $dockerImageName > /dev/null 2>&1
    $docker rm -f $dockerImageName > /dev/null 2>&1
    $docker rmi -f $dockerRepoName/$dockerImageName > /dev/null 2>&1

    echo -e "\e[1;34;40mPull Docker Image from Docker Hub\e[0m"
    echo ""

    $docker pull $dockerRepoName/$dockerImageName
    echo -e "\e[1;34;40mRun Docker Container\e[0m"
    echo ""

    $docker run --name $dockerImageName -d -p 9595:9595 -p 4545:4545 $dockerRepoName/$dockerImageName
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
    echo ""

    if [ "$isInstallDocker" == "Y" ]|| [ "$isInstallDocker" == 'y' ]; then
	    installDocker
    else    
        echo -e "\e[1;33;40mBye Bye ~\e[0m"
        echo ""
        exit 1;
    fi
fi

if [[ -f '/etc/apt/sources.list.d/nvidia-container-toolkit.list' ]]; then
    echo -e "\e[1;34;40mNVIDIA Container Toolkit already install\e[0m"
    echo ""
else
    echo -e "\e[1;31;47m!!! NVIDIA Container Toolkit is not install !!!\e[0m"
    echo ""
    read -e -p $'\e[1;30;43mDo you want to isntall NVIDIA Container Toolkit ? \e[0m           [Y/n]:' -i "$isInstallContainerToolkit" isInstallContainerToolkit
    echo ""

    if [ "$isInstallContainerToolkit" == "Y" ]|| [ "$isInstallContainerToolkit" == 'y' ]; then
	    installNvidiaContainerToolkit
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
isDcokerContainerRunning=$($docker ps |grep "$dockerRepoName/$dockerImageName")
isDcokerImageExist=$($docker images |grep "$dockerRepoName/$dockerImageName")
isRepublishDockerContainer="Y"

if [[ $isDcokerContainerRunning == "" ]]; then
    echo -e "\e[1;34;40mNo Docker Container Run\e[0m"
    echo ""

else
    echo -e "\e[1;31;47m!!! Docker Container is Running Right Now !!!\e[0m"
    echo ""
    echo "$isDcokerContainerRunning"
    echo ""
    read -e -p $'\e[1;30;43mDo you want to Republish Docker Container ? \e[0m           [Y/n]:' -i "$isRepublishDockerContainer" isRepublishDockerContainer
    echo ""

    if [ "$isRepublishDockerContainer" == "Y" ]|| [ "$isRepublishDockerContainer" == 'y' ]; then
	    runDockerContainer
    else    
        echo -e "\e[1;33;40mBye Bye ~\e[0m"
        echo ""
        exit 1;
    fi
fi

if [[ $isDcokerImageExist == "" ]]; then
    echo -e "\e[1;34;40mNo Docker Image Exist\e[0m"
    echo ""
    runDockerContainer

else
    echo -e "\e[1;31;47m!!! Docker Image is Exist !!!\e[0m"
    echo ""
    echo "$isDcokerImageExist"
    echo ""
    read -e -p $'\e[1;30;43mDo you want to Republish Docker Container ? \e[0m           [Y/n]:' -i "$isRepublishDockerContainer" isRepublishDockerContainer
    echo ""

    if [ "$isRepublishDockerContainer" == "Y" ]|| [ "$isRepublishDockerContainer" == 'y' ]; then
	    runDockerContainer
    else    
        echo -e "\e[1;33;40mBye Bye ~\e[0m"
        echo ""
         exit 1;
    fi
 fi

 echo -e "\e[1;33;40mDone.\e[0m"
