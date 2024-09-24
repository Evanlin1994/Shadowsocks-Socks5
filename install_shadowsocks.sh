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

# 更新系统
apt update -y && apt upgrade -y

# 安装必要的工具
apt install -y curl sudo

# 安装 V2Ray
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

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
        "auth": "password",
        "accounts": [
          {
            "user": "admin",
            "pass": "$PASSWORD"
          }
        ],
        "udp": true,
        "ip": "127.0.0.1"
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

# 重启 V2Ray 服务
systemctl restart v2ray

# 设置开机自启
systemctl enable v2ray

# 配置防火墙
if command -v ufw > /dev/null; then
  ufw allow 1234/tcp
  ufw allow 1234/udp
  ufw reload
elif command -v firewall-cmd > /dev/null; then
  firewall-cmd --permanent --add-port=1234/tcp
  firewall-cmd --permanent --add-port=1234/udp
  firewall-cmd --reload
else
  echo "Warning: Firewall not configured. Please configure your firewall manually."
fi

# 输出配置信息
echo "V2Ray SOCKS5 proxy has been installed and configured."
echo "Server: $(curl -s ifconfig.me)"
echo "Port: 1234"
echo "Username: admin"
echo "Password: $PASSWORD"

# 检查服务状态
systemctl status v2ray
