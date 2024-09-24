#!/bin/bash

# 检查是否以 root 权限运行
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

# 检查是否提供了密码参数
if [ -z "$1" ]; then
  echo "Usage: $0 <password>"
  exit 1
fi

PASSWORD=$1

# 检测系统类型
if [[ -f /etc/debian_version ]]; then
  # Debian/Ubuntu 系统
  PKG_MANAGER="apt"
elif [[ -f /etc/redhat-release ]]; then
  # CentOS/RHEL 系统
  PKG_MANAGER="yum"
else
  echo "Unsupported operating system"
  exit 1
fi

# 更新系统
$PKG_MANAGER update -y

# 安装 Shadowsocks 服务器
if [[ $PKG_MANAGER == "apt" ]]; then
  $PKG_MANAGER install shadowsocks-libev -y
elif [[ $PKG_MANAGER == "yum" ]]; then
  $PKG_MANAGER install epel-release -y
  $PKG_MANAGER install shadowsocks-libev -y
fi

# 创建配置文件
cat > /etc/shadowsocks-libev/config.json <<EOF
{
    "server":"0.0.0.0",
    "server_port":8388,
    "password":"$PASSWORD",
    "timeout":300,
    "method":"chacha20-ietf-poly1305",
    "user":"nobody",
    "fast_open": true
}
EOF

# 启动服务
systemctl start shadowsocks-libev
systemctl enable shadowsocks-libev

# 配置防火墙（如果使用 UFW）
if command -v ufw > /dev/null; then
  ufw allow 8388/tcp
  ufw allow 8388/udp
  ufw reload
elif command -v firewalld > /dev/null; then
  firewall-cmd --permanent --add-port=8388/tcp
  firewall-cmd --permanent --add-port=8388/udp
  firewall-cmd --reload
elif command -v iptables > /dev/null; then
  iptables -A INPUT -p tcp --dport 8388 -j ACCEPT
  iptables -A INPUT -p udp --dport 8388 -j ACCEPT
  service iptables save
else
  echo "Warning: Firewall not configured. Please configure your firewall manually."
fi

# 输出配置信息
echo "Shadowsocks has been installed and configured."
echo "Server: $(curl -s ifconfig.me)"
echo "Port: 8388"
echo "Password: $PASSWORD"
echo "Method: chacha20-ietf-poly1305"
