#!/bin/bash

# --- NotionNext 高级更新脚本 ---
# 功能:
# 1. 自动暂存本地配置改动。
# 2. 从 Git 仓库拉取最新代码。
# 3. 自动恢复本地配置改动。
# 4. 如果出现冲突，则停止并提示用户手动解决。
# 5. 自动安装依赖、编译代码。
# 6. 使用 PID 文件精确地重启应用，避免影响其他进程。

# 如果任何命令失败，则立即退出脚本
set -e

echo "=== 开始更新 NotionNext ==="

# 检查当前目录是否为 Git 仓库
if [ ! -d ".git" ]; then
    echo "错误：请在 NotionNext 项目的根目录下运行此脚本。"
    exit 1
fi

# 检查本地是否有未提交的修改
if ! git diff-index --quiet HEAD --; then
    echo "检测到本地有修改，正在执行 git stash 保存..."
    git stash save "Configs-before-update-$(date +%F-%T)"
    STASH_APPLIED=true
else
    echo "工作目录是干净的，无需暂存。"
    STASH_APPLIED=false
fi

echo "--- 步骤 1: 同步上游仓库 (tangly1024/NotionNext) ---"
echo "正在从 'upstream' 拉取最新代码..."
# 从上游仓库获取最新数据
git fetch upstream

echo "正在将上游仓库的 'main' 分支合并到本地..."
# 假设你的主分支也叫 'main'。如果不是，需要修改。
# 使用 --no-edit 避免在可以自动合并时弹出编辑器
git merge upstream/main --no-edit || (echo "自动合并失败，请手动解决冲突后再次运行脚本。" && exit 1)
echo "上游代码同步完成。"

echo "--- 步骤 2: 将更新推送到您自己的仓库 (yiancode/NotionNext) ---"
echo "正在执行 'git push origin'..."
# 将合并后的代码推送到你自己的fork仓库
git push origin main
echo "'git push' 执行完毕。"

# 如果之前有暂存，现在就恢复它
if [ "$STASH_APPLIED" = true ]; then
    echo "--- 步骤 3: 恢复之前暂存的配置 ---"
    # 尝试恢复，如果失败（有冲突），则退出
    if ! git stash pop; then
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "!! 错误：恢复配置时发生冲突！"
        echo "!! 更新已暂停。请手动解决文件冲突。"
        echo "!! 运行 'git status' 查看冲突文件。"
        echo "!! 解决冲突后，请手动执行后续步骤："
        echo "!! 1. yarn install"
        echo "!! 2. yarn build"
        echo "!! 3. ./start_yarn.sh"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        exit 1
    fi
    echo "配置已成功恢复。"
fi

echo "--- 步骤 4: 安装/更新项目依赖 ---"
yarn install

echo "--- 步骤 5: 编译新版代码 ---"
yarn build

echo "--- 步骤 6: 安全重启应用 ---"
PID_FILE="./.pidfile"

# 检查 PID 文件是否存在
if [ -f "$PID_FILE" ]; then
    # 读取 PID
    PID=$(cat "$PID_FILE")
    # 检查该 PID 的进程是否仍在运行
    if ps -p "$PID" > /dev/null; then
        echo "正在停止旧的应用进程 (PID: $PID)..."
        kill "$PID"
        # 等待进程完全停止
        sleep 2
    else
        echo "PID 文件中的进程 ($PID) 未在运行。"
    fi
    # 删除旧的 PID 文件
    rm "$PID_FILE"
else
    echo "未找到 PID 文件，可能应用未在运行。"
fi

echo "正在调用 start_yarn.sh 启动新进程..."
# 确保 start_yarn.sh 有执行权限
chmod +x ./start_yarn.sh
# 直接执行启动脚本，它会在后台运行并创建新的PID文件
./start_yarn.sh

echo "=== NotionNext 更新完成！ ==="
echo "应用已通过 start_yarn.sh 重新启动。"
echo "请使用 'cat ./.pidfile' 查看新进程的PID。"