# 🚀 流量非对称塑形与对抗伪装守护服务 (liuliangsuxing)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: Ubuntu/Debian](https://img.shields.io/badge/Platform-Ubuntu%20%2F%20Debian-blue.svg)]()

本工具专为海外 VPS 节点设计，通过**动态、随机的人为流量塑形（Traffic Shaper）**，彻底打破传统翻墙协议在服务端表现出的 **上下行流量 1:1 对等特征**。脚本采用底层管道技术，数据流即时丢弃，实现 **0 磁盘写入**，完美保护硬盘寿命并对抗高级审查（如基于机器学习的流量统计学分析）。

---

## ✨ 核心特性

* 🎲 **高级反侦察伪装**：拒绝固定周期的 `cron` 定时任务特征。采用**全随机算法**，随机休眠（10~40分钟）、随机限速（2M~8M/s）、随机任务时长（60~180秒），模拟真实运维或正常用户多变的网络行为。
* 💾 **0 磁盘占用（不爆盘）**：利用 Linux 空设备文件管道（`-o /dev/null`），流量进入内存缓冲区后即刻被内核丢弃，不经过文件系统，**不占用任何硬盘空间**，对 SSD 寿命零损伤。
* 🌐 **知名大厂骨干网混淆**：随机抽取 Ubuntu、Debian、Cloudflare、Google、AWS 等全球顶级骨干网或 CDN 节点的公开大文件进行拉取，让入站流量目的纯净、完全合规。
* 🤖 **无感后台守护**：自动封装为标准 Systemd 系统服务，支持开机自启、进程崩溃自动无损重启。

---

## 🚀 一键全自动部署

在你的 Ubuntu / Debian 系统终端中，直接复制并运行以下命令即可完成全自动安装及配置：

```bash
curl -sSL https://raw.githubusercontent.com/pansir0290/liuliangsuxing/main/install.sh | bash
```

---

## ⚙️ 服务常规管理

服务安装成功后，完全托管于系统的 `systemd` 控制器。请使用以下命令进行日常运维控制：

### 1. 查看运行状态
检查服务是否在后台健康运行，以及当前进程的 PID：
```bash
systemctl status traffic-shaper
```

### 2. 停止服务
如果您需要临时暂停流量伪装任务：
```bash
systemctl stop traffic-shaper
```

### 3. 启动服务
重新拉起后台伪装守护进程：
```bash
systemctl start traffic-shaper
```

### 4. 重启服务
修改底层脚本参数或需要强制刷新服务时使用：
```bash
systemctl restart traffic-shaper
```

### 5. 查看伪装日志时间线
实时查看脚本在什么时间、拉取了哪个大厂的资源、限速及休眠状态：
```bash
journalctl -u traffic-shaper -n 50 --no-pager -f
```

---

## ❌ 一键彻底卸载

如果您不再需要此服务，运行以下命令可以**完美、干净**地移除所有痕迹（包括系统服务、底层脚本和策略）：

```bash
systemctl stop traffic-shaper && \
systemctl disable traffic-shaper && \
rm -f /etc/systemd/system/traffic-shaper.service && \
rm -f /usr/local/bin/traffic_shaper_runner.sh && \
systemctl daemon-reload && \
echo "✨ 流量塑形服务已成功从您的系统彻底卸载！"
```

---

## ⚠️ 注意事项与高级调优

1. **流量包消耗提示**：由于本脚本是通过 VPS 主动下载海外大厂文件来稀释上下行特征，这会实打实地消耗您 VPS 的**月度流量包（单向/双向计费）**。如果您的机器是无限流量或流量包极大（1T 以上）可放心无脑运行；若是按量计费机型，请慎重。
2. **自定义调优参数**：如果您需要修改随机休眠范围或限速区间，可以编辑核心运行文件 `/usr/local/bin/traffic_shaper_runner.sh`，修改其中的 `MIN_SLEEP`（最小休眠）、`MAX_SLEEP`（最大休眠）、`MIN_RATE`（最小限速）、`MAX_RATE`（最大限速）变量，修改完成后执行 `systemctl restart traffic-shaper` 即可生效。
