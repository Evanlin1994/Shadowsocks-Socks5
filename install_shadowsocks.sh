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

# 安装 V2Ray
if [[ $PKG_MANAGER == "apt" ]]; then
  $PKG_MANAGER install curl -y
  bash <(curl -L -s https://install.direct/go.sh)
elif [[ $PKG_MANAGER == "yum" ]]; then
  $PKG_MANAGER install curl -y
  bash <(curl -L -s https://install.direct/go.sh)
fi

# 创建配置文件
cat > /usr/local/etc/v2ray/config.json <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 1234,
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true,
        "ip": "127.0.0.1",
        "accounts": [
          {
            "user": "admin",
            "pass": "$PASSWORD"
          }
        ]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF

# 启动服务
systemctl start v2ray
systemctl enable v2ray

# 配置防火墙
if command -v ufw > /dev/null; then
  ufw allow 1080/tcp
  ufw allow 1080/udp
  ufw reload
elif command -v firewalld > /dev/null; then
  firewall-cmd --permanent --add-port=1080/tcp
  firewall-cmd --permanent --add-port=1080/udp
  firewall-cmd --reload
elif command -v iptables > /dev/null; then
  iptables -A INPUT -p tcp --dport 1080 -j ACCEPT
  iptables -A INPUT -p udp --dport 1080 -j ACCEPT
  service iptables save
else
  echo "Warning: Firewall not configured. Please configure your firewall manually."
fi

# 输出配置信息
echo "V2Ray SOCKS5 proxy has been installed and configured."
echo "Server: $(curl -s ifconfig.me)"
echo "Port: 1080"
echo "Password: $PASSWORD"

# 检查服务状态
systemctl status v2ray
