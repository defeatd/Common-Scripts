#!/bin/bash

# 创建 2GB 的 swap 文件
echo "Creating 2GB swap file..."
fallocate -l 2G /swapfile
if [ $? -ne 0 ]; then
    echo "Failed to create swap file!"
    exit 1
fi

# 设置 swap 文件权限
echo "Setting swap file permissions..."
chmod 600 /swapfile
if [ $? -ne 0 ]; then
    echo "Failed to set permissions!"
    exit 1
fi

# 格式化 swap 文件
echo "Formatting swap file..."
mkswap /swapfile
if [ $? -ne 0 ]; then
    echo "Failed to format swap file!"
    exit 1
fi

# 启用 swap 文件
echo "Enabling swap file..."
swapon /swapfile
if [ $? -ne 0 ]; then
    echo "Failed to enable swap file!"
    exit 1
fi

# 将 swap 文件添加到 /etc/fstab
echo "Adding swap file to /etc/fstab..."
if grep -q "/swapfile" /etc/fstab; then
    echo "Swap entry already exists in /etc/fstab."
else
    echo "/swapfile none swap sw 0 0" | tee -a /etc/fstab
    if [ $? -ne 0 ]; then
        echo "Failed to add swap entry to /etc/fstab!"
        exit 1
    fi
fi

# 验证 swap 是否启用
echo "Verifying swap..."
swapon --show
free -h

echo "Swap setup completed successfully!"
