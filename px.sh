#!/bin/bash

# === 交互输入 ===
read -p "请输入代理信息 (<IP>|<端口>|<用户名>|<密码>|<到期时间>): " proxy_info

# 拆分输入信息
IFS='|' read -r SOCKS5_IP SOCKS5_PORT SOCKS5_USER SOCKS5_PASS SOCKS5_EXP <<< "$proxy_info"

# 检查是否输入正确
if [[ -z "$SOCKS5_IP" || -z "$SOCKS5_PORT" || -z "$SOCKS5_USER" || -z "$SOCKS5_PASS" ]]; then
    echo "❌ 输入格式错误，请使用 <IP>|<端口>|<用户名>|<密码>|<到期时间> 格式"
    exit 1
fi

REDSOCKS_PORT="12345"

# === 安装依赖 ===
apt update && apt install -y redsocks iptables-persistent netfilter-persistent
curl -fsSL https://get.docker.com | bash -s docker

# === 配置 redsocks ===
cat > /etc/redsocks.conf <<EOF
base {
    log_debug = on;
    log_info = on;
    log = "stderr";
    daemon = on;
    redirector = iptables;
}

redsocks {
    local_ip = 127.0.0.1;
    local_port = ${REDSOCKS_PORT};

    ip = ${SOCKS5_IP};
    port = ${SOCKS5_PORT};

    type = socks5;
    login = "${SOCKS5_USER}";
    password = "${SOCKS5_PASS}";
}
EOF

# === 设置 redsocks 自启动 ===
systemctl enable redsocks
systemctl restart redsocks

# === 创建 proxy-up.sh ===
cat > /usr/local/bin/proxy-up.sh <<EOF
#!/bin/bash

iptables -t nat -N REDSOCKS 2>/dev/null

iptables -t nat -F REDSOCKS
iptables -t nat -A REDSOCKS -d ${SOCKS5_IP} -j RETURN
iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN
iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
iptables -t nat -A REDSOCKS -d 169.254.0.0/16 -j RETURN
iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN

iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports ${REDSOCKS_PORT}
iptables -t nat -A OUTPUT -p tcp -j REDSOCKS

echo "Proxy enabled"
EOF

chmod +x /usr/local/bin/proxy-up.sh

# === 创建 proxy-down.sh ===
cat > /usr/local/bin/proxy-down.sh <<EOF
#!/bin/bash
iptables -t nat -D OUTPUT -p tcp -j REDSOCKS 2>/dev/null
iptables -t nat -F REDSOCKS 2>/dev/null
iptables -t nat -X REDSOCKS 2>/dev/null
echo "Proxy disabled"
EOF

chmod +x /usr/local/bin/proxy-down.sh

# === 保存规则 ===
netfilter-persistent save

# === 设置 proxy-up 开机自启 ===
echo -e '[Unit]\nDescription=Start Proxy Script at Boot\nAfter=network.target\n\n[Service]\nExecStart=/usr/local/bin/proxy-up.sh\nRestart=on-failure\nUser=root\n\n[Install]\nWantedBy=multi-user.target' | sudo tee /etc/systemd/system/proxy-up.service > /dev/null

sudo chmod +x /usr/local/bin/proxy-up.sh
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable proxy-up.service

# === 定时重启 redsocks ===
(crontab -l 2>/dev/null; echo "*/5 * * * * systemctl restart redsocks.service") | crontab -

echo "✅ SOCKS5 全局代理配置已完成（到期时间：$SOCKS5_EXP），目前未启动，请先添加探针，再上机！"
