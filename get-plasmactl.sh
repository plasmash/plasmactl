#!/bin/sh

# Get the operating system type
os=$(uname -s)

# Get the machine architecture
arch=$(uname -m)

# Define the URL pattern for the file
url="https://repositories.skilld.cloud/repository/pla-plasmactl-raw/latest/plasmactl_%s_%s"

# Determine the appropriate values for 'os' and 'arch'
case $os in
  Linux*)
    os="linux"
    ;;
  Darwin*)
    os="osx"
    ;;
  CYGWIN*|MINGW32*|MSYS*|MINGW*)
    os="windows"
    ;;
  *)
    echo "Unsupported operating system: $os"
    exit 1
    ;;
esac

case $arch in
  x86_64|amd64)
    arch="amd64"
    ;;
  i?86|x86)
    arch="386"
    ;;
  *)
    echo "Unsupported architecture: $arch"
    exit 1
    ;;
esac

# Format the URL with the determined 'os' and 'arch' values
url=$(printf "$url" "$os" "$arch")

# Prompt user for username and password
read -p "Username: " username
read -s -p "Password: " password
echo

# Download the file using curl or wget with Basic Auth header
if command -v curl >/dev/null 2>&1; then
  curl -u "$username:$password" -O "$url"
elif command -v wget >/dev/null 2>&1; then
  wget --user="$username" --password="$password" "$url"
else
  echo "Neither curl nor wget found. Please install one of them."
  exit 1
fi

