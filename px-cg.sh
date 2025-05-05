#!/bin/bash

# 1. 获取用户输入
read -p "请输入代理信息（格式：IP|端口|用户名|密码|到期时间）: " INPUT
IFS='|' read -r SOCKS5_IP SOCKS5_PORT SOCKS5_USER SOCKS5_PASS PROXY_EXP <<< "$INPUT"
if [ -z "$PROXY_EXP" ]; then
  echo "❌ 输入格式错误，应为：IP|端口|用户名|密码|到期时间"
  exit 1
fi

# 2. 设置 redsocks 本地端口（默认12345）
read -p "请输入 redsocks 本地监听端口（默认12345）: " REDSOCKS_PORT
REDSOCKS_PORT=${REDSOCKS_PORT:-12345}

# 3. 替换 redsocks 配置
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

# 4. 更新 proxy-up.sh
cat > /usr/local/bin/proxy-up.sh <<EOF
#!/bin/bash
SOCKS5_IP="${SOCKS5_IP}"
REDSOCKS_PORT="${REDSOCKS_PORT}"

iptables -t nat -N REDSOCKS 2>/dev/null
iptables -t nat -F REDSOCKS
iptables -t nat -A REDSOCKS -d \$SOCKS5_IP -j RETURN
iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN
iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
iptables -t nat -A REDSOCKS -d 169.254.0.0/16 -j RETURN
iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN
iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports \$REDSOCKS_PORT
iptables -t nat -A OUTPUT -p tcp -j REDSOCKS

echo "Proxy enabled"
EOF
chmod +x /usr/local/bin/proxy-up.sh

# 5. 更新 proxy-down.sh
cat > /usr/local/bin/proxy-down.sh <<EOF
#!/bin/bash
iptables -t nat -D OUTPUT -p tcp -j REDSOCKS 2>/dev/null
iptables -t nat -F REDSOCKS 2>/dev/null
iptables -t nat -X REDSOCKS 2>/dev/null
echo "Proxy disabled"
EOF
chmod +x /usr/local/bin/proxy-down.sh

# 6. 重启 redsocks 并应用新规则
systemctl restart redsocks
/usr/local/bin/proxy-down.sh
/usr/local/bin/proxy-up.sh

# 7. 输出信息
echo "✅ 配置更新完成，已启用代理"
echo "➡️ 代理到期时间：$PROXY_EXP"
echo "📢 redsocks 本地监听端口：$REDSOCKS_PORT"
