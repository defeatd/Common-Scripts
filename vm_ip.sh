#!/bin/bash

# 开启转发并启用Proxy ARP
echo "开启转发并启用Proxy ARP..."
sudo bash -c "sed -i -e 's/^#*net.ipv4.ip_forward = .*/net.ipv4.ip_forward = 1/' /etc/sysctl.conf"
grep -qxF 'net.ipv4.ip_forward = 1' /etc/sysctl.conf || echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
sudo sysctl -p
echo 1 | sudo tee /proc/sys/net/ipv4/conf/all/proxy_arp

# 提示输入购买的IP地址
read -p "请输入购买的公网IP地址: " ip_address

# 提示输入网卡名称（默认为vmbr0）
read -p "请输入网卡名称（默认: vmbr0）: " interface
interface=${interface:-vmbr0}

# 获取购买的公网IP地址的最后一段并减1
ip_last_octet=$(echo $ip_address | awk -F'.' '{print $4-1}')
gateway_ip=$(echo $ip_address | sed "s/\([0-9]*\.[0-9]*\.[0-9]*\.\)[0-9]*$/\1$ip_last_octet/")

# 添加伪网关地址并构成 /24 子网
echo "添加伪网关地址并构成 /24 子网..."
sudo ip addr add $gateway_ip/24 dev $interface

# 配置静态路由
echo "配置静态路由..."
sudo ip route add $ip_address/24 dev $interface

# 提示修改虚拟机配置
echo "操作完成！"
echo ""
echo "请根据以下配置修改虚拟机的网络配置："
echo "IPADDR=$ip_address"
echo "NETMASK=255.255.255.0   # 即 /24"
echo "GATEWAY=$gateway_ip     # 宿主机伪网关"
echo "DNS=8.8.8.8"
echo ""
echo "修改完成后，请重启虚拟机以应用新的配置。"
