#!/bin/bash

# 创建一个临时工作目录
temp_dir=$(mktemp -d)
if [[ ! "$temp_dir" || ! -d "$temp_dir" ]]; then
  echo "Could not create temp dir"
  exit 1
fi

# 定义下载的URL和目标文件名
url="https://github.com/gptq/config/raw/main/config.gpg"
downloaded_file="$temp_dir/config.gpg"

# 检查必要的依赖软件是否已安装
for cmd in gpg unzip base64 wget; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd is not installed. Please install it and try again."
        exit 1
    fi
done

# 下载config.gpg文件
wget -O "$downloaded_file" "$url"

# 检查文件是否成功下载且大小大于50字节
if [ ! -s "$downloaded_file" ] || [ $(stat -c%s "$downloaded_file") -le 50 ]; then
    echo "Failed to download the file or file size is too small."
    exit 1
fi

# 提示用户输入GPG解密密码
read -sp "Enter GPG Decryption Password: " gpg_pass
echo

# 首先对Base64编码的数据进行解码
base64 -d "$downloaded_file" > "$temp_dir/config.zip.gpg"

# 使用GPG解密文件
gpg --batch --passphrase "$gpg_pass" -d -o "$temp_dir/config.json.zip" "$temp_dir/config.zip.gpg"

# 构造ZIP解压密码（GPG密码前面加上Teddy）
zip_pass="Teddy$gpg_pass"

# 解压ZIP文件到临时目录
unzip -P "$zip_pass" -d "$temp_dir" "$temp_dir/config.json.zip"

# 重命名解压后的文件为config.json.tmp
mv "$temp_dir/config.json" config.json.tmp

# 清理临时目录
rm -rf "$temp_dir"

echo "Decryption, extraction, and cleanup completed successfully."
