#!/bin/sh
#set -x

# Get the operating system type
os=$(uname -s)

# Get the machine architecture
arch=$(uname -m)

# Define the URL pattern for the file
url="https://repositories.skilld.cloud/repository/pla-plasmactl-raw/latest/plasmactl_%s_%s"

# Function to validate the credentials and return HTTP status code
validate_credentials() {
  local username="$1"
  local password="$2"
  local url="$3"

  # Perform the credential validation by making a curl request and retrieving the HTTP status code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" -u "$username:$password" "$url")
  echo "$http_code"
}

# Determine the appropriate values for 'os' and 'arch'
case $os in
  Linux*)
    os="linux"
    ;;
  Darwin*)
    os="darwin"
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

# Check if username and password are passed as script arguments
if [ $# -eq 2 ]; then
  username="$1"
  password="$2"
else
  # Prompt user for username and password
  read -p "Username: " username
  read -s -p "Password: " password
  echo
fi

# Check the validity of the credentials
http_code=$(validate_credentials "$username" "$password" "$url")
if [ -z "$http_code" ]; then
  echo "Error: Failed to validate credentials. Access denied."
  exit 1
elif [ "$http_code" -eq 200 ]; then
  echo "Valid credentials. Access granted."
else
  echo "Error: HTTP $http_code. Either credentials are invalid or file $filename does not exist."
  exit 1
fi

# Download the file using curl or wget with Basic Auth header
if command -v curl >/dev/null 2>&1; then
  curl -u "$username:$password" -O "$url"
elif command -v wget >/dev/null 2>&1; then
  wget --user="$username" --password="$password" "$url"
else
  echo "Neither curl nor wget found. Please install one of them."
  exit 1
fi

# Set execute permission on the downloaded file
filename=$(basename "$url")
if [ -e "$filename" ]; then
  chmod +x "$filename"
  echo
  ./"$filename" --help
  echo
  ./"$filename" --version
  echo
else
    echo "File $filename does not exist"
    exit 1
fi
