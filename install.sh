#!/bin/bash

# ==========================================================
# 脚本名称: 流量非对称塑形对抗服务 一键安装脚本
# 适用系统: Ubuntu / Debian (Root 用户)
# 作用: 自动化部署流量混淆伪装守护进程，彻底隐藏协议上下行 1:1 特征
# ==========================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}====================================================${NC}"
echo -e "${GREEN}    开始安装 流量非对称性塑形与对抗伪装守护服务       ${NC}"
echo -e "${YELLOW}====================================================${NC}"

# 1. 权限检查
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ 错误: 请使用 root 用户或 sudo 运行此脚本！${NC}"
    exit 1
fi

# [1/4] 依赖组件检查
echo -e "${YELLOW}[1/4] 正在检查基础组件 (curl, ss)...${NC}"
apt update -y && apt install curl iproute2 -y >/dev/null 2>&1
echo -e "${GREEN}✓ 基础组件就绪${NC}"

# [2/4] 生成底层核心流量混淆脚本
echo -e "${YELLOW}[2/4] 正在生成底层核心守护脚本...${NC}"
TARGET_BIN="/usr/local/bin/traffic_shaper_runner.sh"

# 使用 'EOF' 锁死变量，确保里面的 $RANDOM 和 $URL_POOL 在目标机运行时才动态解析
cat << 'EOF' > "$TARGET_BIN"
#!/bin/bash
# 知名且高带宽的公开文件下载池
URL_POOL=(
    "https://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso"
    "https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/debian-12.5.0-amd64-DVD-1.iso"
    "https://speed.cloudflare.com/__down?bytes=209715200"
    "https://storage.googleapis.com/chromium-browser-snapshots/Linux_x64/1000000/chrome-linux.zip"
    "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
)
UA_POOL=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/119.0"
    "Wget/1.21.1 (linux-gnu)"
    "curl/7.81.0"
)

MIN_SLEEP=600       # 最小休眠时间：10分钟
MAX_SLEEP=2400      # 最大休眠时间：40分钟
MIN_RATE="2M"       # 最小下载限速 (2MB/s)
MAX_RATE="8M"       # 最大下载限速 (8MB/s)

while true; do
    URL_INDEX=$((RANDOM % ${#URL_POOL[@]}))
    SELECTED_URL=${URL_POOL[$URL_INDEX]}
    UA_INDEX=$((RANDOM % ${#UA_POOL[@]}))
    SELECTED_UA=${UA_POOL[$UA_INDEX]}
    RATE_NUM=$((RANDOM % 7 + 2))
    CURRENT_RATE="${RATE_NUM}M"
    MAX_DURATION=$((RANDOM % 120 + 60)) # 随机下载 60s ~ 180s

    # 实时倒进黑洞，确保 0 磁盘占用
    curl -sL -H "User-Agent: $SELECTED_UA" \
         --limit-rate "$CURRENT_RATE" \
         --max-time "$MAX_DURATION" \
         -o /dev/null "$SELECTED_URL"

    SLEEP_TIME=$((RANDOM % (MAX_SLEEP - MIN_SLEEP + 1) + MIN_SLEEP))
    sleep "$SLEEP_TIME"
done
EOF

chmod +x "$TARGET_BIN"
echo -e "${GREEN}✓ 核心脚本已生成并赋予执行权限: $TARGET_BIN${NC}"

# [3/4] 注册 Systemd 系统服务
echo -e "${YELLOW}[3/4] 正在配置 Systemd 系统守护服务...${NC}"
SERVICE_FILE="/etc/systemd/system/traffic-shaper.service"

cat << EOF > "$SERVICE_FILE"
[Unit]
Description=Traffic Shaper and Obfuscation Service
After=network.target

[Service]
Type=simple
ExecStart=$TARGET_BIN
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}✓ 系统服务文件配置完成: $SERVICE_FILE${NC}"

# [4/4] 启动并设置开机自启
echo -e "${YELLOW}[4/4] 正在全力拉起流量混淆守护服务...${NC}"
systemctl daemon-reload
systemctl enable traffic-shaper --now

# 最终验证
if systemctl is-active --quiet traffic-shaper; then
    echo -e "${GREEN}====================================================${NC}"
    echo -e "${GREEN}🎉 恭喜！流量非对称塑形服务安装成功并已在后台运行！${NC}"
    echo -e "${GREEN}💡 提示: 数据流实时丢弃至 /dev/null，完全不占用你的硬盘。${NC}"
    echo -e "${GREEN}⚙️  你可以运行 'systemctl status traffic-shaper' 查看状态。${NC}"
    echo -e "${GREEN}====================================================${NC}"
else
    echo -e "${RED}❌ 错误: 服务未能成功拉起，请运行 'journalctl -u traffic-shaper
    ' 查看具体日志。${NC}"
fi
