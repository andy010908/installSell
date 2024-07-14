#!/bin/bash
# 參考：
# https://blog.kkbruce.net/2023/08/5min-ubuntu-2204-kubernetes-cluster.html
whoami=`whoami`
isSudoer=`id $whoami |grep sudo`

isMaster="Y"
k8sVersion="1.30"

if [[ $whoami != "root" ]]; then
    if [[ $isSudoer == "" ]]; then
        echo -e "\e[1;31;47m!!! You Are not root or sudoer !!!\e[0m"
        echo ""
        exit 1;
    fi
fi

echo -e "\e[1;33;40mReady to install Kubernetes... \e[0m"
echo ""
read -e -p $'\e[1;30;43mIs this machine where k8s is to be installed on Master ? \e[0m           [Y/n]:' -i "$isMaster" isMaster

echo -e "\e[1;34;40m[Step 1] Disable and turn off SWAP\e[0m"
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin
# 文件最後一行：Swap disabled. You **MUST** disable swap in order for the kubelet to work properly.
# K8s需要關閉swap
# 先手動關閉
swapoff -a
# 將fstab裡的swap那一行註解
sed -i '/swap/s/^/#/' /etc/fstab

echo -e "\e[1;34;40m[Step 2] Stop and disable Ubuntu ufw\e[0m"
# https://kubernetes.io/docs/reference/ports-and-protocols/
# 參考K8s文件，將Firewall一一設定好。
# https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-with-ufw-on-ubuntu-22-04

if [ "$isMaster" == "Y" ]|| [ "$isMaster" == 'y' ]; then
	# Control plane
    ufw allow ssh #( or ufw allow 22/tcp)
    ufw allow http #( or ufw allow 80/tcp)
    ufw allow https #( or ufw allow 443/tcp)
    ufw allow 6443/tcp
    ufw allow 2379:2380/tcp
    ufw allow 10250/tcp
    ufw allow 10257/tcp
    ufw allow 10259/tcp
else    
    # Worker node
    ufw allow ssh #( or ufw allow 22/tcp)
    ufw allow 10250/tcp
    ufw allow 30000:32767/tcp
fi

echo -e "\e[1;34;40m[Step 3] Loading K8s required Kernel Modules\e[0m"
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/#forwarding-ipv4-and-letting-iptables-see-bridged-traffic
# 設定K8s開機所需的核心模組
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
# 手動載入K8s所需核心模組
modprobe overlay
modprobe br_netfilter

echo -e "\e[1;34;40m[Step 4] Setup iptables\e[0m"
# K8s必須調整iptables規則
# 為了讓Linux節點的iptables正確查看bridge流量
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
# 重新載入sysctl.d裡所有設定檔
sysctl --system

echo -e "\e[1;34;40m[Step 5] Install containerd runtime\e[0m"
# https://docs.docker.com/engine/install/ubuntu/
# 加入docker repos
apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
# 安裝containerd.io
apt update > /dev/null 2>&1
apt install -y containerd.io
# 產生預設組態當
containerd config default | tee /etc/containerd/config.toml
# K8s需要以cgroup執行(超重要)
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd-systemd
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
# 重啟containerd
systemctl restart containerd
systemctl enable containerd

echo -e "\e[1;34;40m[Step 6] Install kubernetes Tools\e[0m"
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl
# 加入K8s repos

# 已失效，遷移文件：
# https://kubernetes.io/blog/2023/08/15/pkgs-k8s-io-introduction/
# curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
# echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://pkgs.k8s.io/core:/stable:/v$k8sVersion/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$k8sVersion/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list


# 安裝 kubelet kubeadm kubectl 工具
apt update > /dev/null 2>&1
# 查詢特定版號
# apt-cache policy kubelet 
# 最新版可能週邊套件跟不上
apt install -y kubelet kubeadm kubectl
# 建議指定特定版本
#apt install -y kubelet=1.26.4-00 kubeadm=1.26.4-00 kubectl=1.26.4-00
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl
# K8s文件請我們釘住它
apt-mark hold kubelet kubeadm kubectl

echo -e "\e[1;34;40m[Step 7] Check kubeadm kubelet kubectl version\e[0m"
echo ""
echo -e "\e[1;30;43mkubeadm version :\e[0m"
kubeadm version
echo ""
echo -e "\e[1;30;43mkubelet version :\e[0m"
kubelet --version
echo ""
echo -e "\e[1;30;43mkubectl version :\e[0m"
kubectl version
echo ""

echo -e "\e[1;34;40m[Step 8] Steup kubectl completion\e[0m"
# https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#enable-shell-autocompletion
# https://zahui.fan/posts/7ce4e1fc/
apt-get install bash-completion
source /usr/share/bash-completion/bash_completion
kubectl completion bash | tee /etc/bash_completion.d/kubectl > /dev/null
source ~/.bashrc

echo -e "\e[1;33;40mDone, and Use the command line : \e[0m"
echo -e "\e[1;33;40mexec bash\e[0m"
echo -e "\e[1;33;40mto Reload the kubectl completion\e[0m"

