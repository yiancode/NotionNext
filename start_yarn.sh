#!/bin/bash

# --- 精确启动并记录 PID ---
PID_FILE="./.pidfile"

# 检查 PID 文件是否存在，如果存在且进程在运行，则退出
if [ -f "$PID_FILE" ] && ps -p $(cat "$PID_FILE") > /dev/null; then
    echo "应用已在运行，PID: $(cat "$PID_FILE")。如需重启，请先执行 kill $(cat $PID_FILE)。"
    exit 1
fi

echo "正在启动 NotionNext..."
# 使用 nohup 在后台运行，并将输出重定向到日志文件
# 通过 PORT 环境变量指定端口为 3001
# 将 yarn start 命令的 PID 保存到文件
PORT=3001 nohup yarn start > ./start_yarn.log 2>&1 & echo $! > "$PID_FILE"

echo "NotionNext 已启动，PID: $(cat "$PID_FILE")，日志请查看 start_yarn.log"
echo "PID 已保存到 $PID_FILE"