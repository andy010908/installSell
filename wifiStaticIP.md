須切換root！

1. 确定 WiFi 接口名称
首先，确定你的 WiFi 接口名称。你可以使用以下命令来查看网络接口列表：
```sh
ifconfig |grep wl
```
在输出中找到你的 WiFi 接口名称，通常是 wlan0 或 wlp2s0 之类的。

2. 编辑 Netplan 配置文件
Netplan 的配置文件通常位于：
/etc/netplan/ 目录下。
文件名可能类似于 01-netcfg.yaml 或 50-cloud-init.yaml。你可以使用 ls /etc/netplan/ 命令查看该目录下的文件。

使用你喜欢的文本编辑器编辑该文件，例如 nano：
```sh
nano /etc/netplan/01-netcfg.yaml
```

3. 配置 WiFi 固定 IP
在配置文件中添加或修改 WiFi 接口的配置，确保配置如下所示（根据你的网络环境调整 IP 地址、网关和 DNS）：
```yml
network:
  version: 2
  renderer: NetworkManager
  wifis:
    wlo1:
      access-points:
        "ASUSAC1750_5G":
          password: "0925380621"
      dhcp4: false
      dhcp6: false
      addresses:
        - 192.168.50.50/24
      routes:
        - to: default
          via: 192.168.50.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4

```

修正文件权限
```sh
chmod 600 /etc/netplan/01-network-manager-all.yaml
```

4. 应用配置
保存并关闭文件，然后应用新的 Netplan 配置：
```sh
netplan apply
```

5. 驗證
```sh
ip a show wlo1
```
WiFi選netplan開頭的

