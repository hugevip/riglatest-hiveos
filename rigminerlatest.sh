#!/bin/bash

# 固定参数
TARGET_DIR="/hive/miners/rigel/1.21.0/"
MINER_NAME="rigel"

echo "🚀 开始执行 Rigel 矿工自动更新脚本..."

# 检查目标路径是否存在且为目录
if [ -e "$TARGET_DIR" ] && [ ! -d "$TARGET_DIR" ]; then
    echo "❌ 错误：目标路径 $TARGET_DIR 存在但不是目录，请手动删除或重命名该文件。"
    exit 1
else
    echo "✅ 目标路径检测通过：$TARGET_DIR 是目录或不存在"
fi

# 确保目标目录存在
mkdir -p "$TARGET_DIR"
if [ $? -eq 0 ]; then
    echo "✅ 目标目录已创建或存在：$TARGET_DIR"
else
    echo "❌ 目标目录创建失败：$TARGET_DIR，请检查权限"
    exit 1
fi

# 获取最新版本号
echo "⌛ 获取 rigel 最新版本号..."
TAG_NAME=$(curl -s "https://api.github.com/repos/rigelminer/$MINER_NAME/releases/latest" | grep -oP '"tag_name": "\K(.*)(?=")')
VERSION=${TAG_NAME#v}
if [ -z "$VERSION" ]; then
    echo "❌ 获取版本失败，请检查网络或GitHub API状态"
    exit 1
else
    echo "✅ 获取到最新版本号：$VERSION"
fi

# 构造下载链接和临时目录
TAR_FILE="${MINER_NAME}-${VERSION}-linux.tar.gz"
DOWNLOAD_URL="https://github.com/rigelminer/${MINER_NAME}/releases/download/${VERSION}/${TAR_FILE}"
TEMP_DIR=$(mktemp -d)
echo "✅ 下载链接准备完成：$DOWNLOAD_URL"
echo "✅ 临时目录创建成功：$TEMP_DIR"

# 下载文件
echo "⬇️ 开始下载文件..."
wget -O "$TAR_FILE" "$DOWNLOAD_URL"
if [ $? -ne 0 ]; then
    echo "❌ 下载失败，请检查网络连接或URL"
    rm -rf "$TEMP_DIR"
    exit 1
else
    echo "✅ 文件下载成功：$TAR_FILE"
fi

# 解压文件
echo "📂 开始解压文件..."
tar -xzf "$TAR_FILE" -C "$TEMP_DIR"
if [ $? -ne 0 ]; then
    echo "❌ 解压失败，请检查文件是否损坏"
    rm -rf "$TEMP_DIR" "$TAR_FILE"
    exit 1
else
    echo "✅ 解压成功，内容如下："
    ls -la "$TEMP_DIR"
fi

# 查找可执行文件
echo "🔍 查找可执行文件 $MINER_NAME ..."
RIGEL_PATH=$(find "$TEMP_DIR" -name "$MINER_NAME" -type f -perm /u+x | head -1)
if [ -z "$RIGEL_PATH" ]; then
    echo "❌ 未找到可执行文件 $MINER_NAME"
    find "$TEMP_DIR" -type f
    rm -rf "$TEMP_DIR" "$TAR_FILE"
    exit 1
else
    echo "✅ 找到可执行文件：$RIGEL_PATH"
fi

# 复制并覆盖旧文件
echo "📋 复制 $MINER_NAME 到目标目录..."
cp "$RIGEL_PATH" "$TARGET_DIR"
if [ $? -ne 0 ]; then
    echo "❌ 复制失败，请检查权限"
    rm -rf "$TEMP_DIR" "$TAR_FILE"
    exit 1
else
    chmod +x "$TARGET_DIR/$MINER_NAME"
    echo "✅ 复制并设置执行权限成功"
fi

# 清理临时文件
echo "🧹 清理临时文件..."
rm -rf "$TEMP_DIR" "$TAR_FILE"
echo "✅ 临时文件清理完成"

# 验证版本
echo "🔧 验证版本信息..."
"$TARGET_DIR/$MINER_NAME" --version

echo "🎉 更新完成，$MINER_NAME 已更新至最新版本 $VERSION"
