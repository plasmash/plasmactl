#!/bin/sh
set -e
#set -x

# Get the operating system type
os=$(uname -s)

# Get the machine architecture
arch=$(uname -m)

# Define the URL pattern for the file
baseurl="https://repositories.skilld.cloud/repository/pla-plasmactl-raw/latest/plasmactl_%s_%s%s"

# Create a log file where every output will be pipe to
: "${INSTALL_LOG:=/tmp/get-plasmactl-$(date '+%Y%m%d-%H%M%S').log}"
pipe=/tmp/get-plasmactl-$$.tmp
mkfifo $pipe
tee < $pipe ${INSTALL_LOG} &
exec 1>&-
exec 1>$pipe 2>&1
trap 'rm -f $pipe' EXIT

# Avoir unbounded variable
has_sudo=""
footer_notes=""


output() {
    style_start=""
    style_end=""
    if [ "${2:-}" != "" ]; then
    case $2 in
        "success")
            style_start="\033[0;32m"
            style_end="\033[0m"
            ;;
        "error")
            style_start="\033[31;31m"
            style_end="\033[0m"
            ;;
        "info"|"warning")
            style_start="\033[33m"
            style_end="\033[39m"
            ;;
        "heading")
            style_start="\033[1;33m"
            style_end="\033[22;39m"
            ;;
        "comment")
            style_start="\033[2m"
            style_end="\033[22;39m"
            ;;
    esac
    fi

    builtin echo -e "${style_start}${1}${style_end}"
}


exit_with_error() {
    output "Installation failed" "error"
    output "\nGet help with your plasmactl setup:" "heading"
    output "- https://im.skilld.cloud/group/pla-plasmactl.client" "heading"
    output "- https://im.skilld.cloud/group/pla-plasmactl.prod" "heading"
    output "\nLog file: ${INSTALL_LOG}"
    output ""
    exit 1
}

init_sudo() {
    if [ ! -z "${has_sudo}" ]; then
        return
    fi

    has_sudo=false
    # Are we running the installer as root?
    if [ "$(echo "$UID")" = "0" ]; then
        has_sudo=true
        cmd_sudo=''

        return
    fi

    if command -v sudo > /dev/null 2>&1; then
        has_sudo=true
        cmd_sudo='sudo -E'
    fi
}

call_root() {
    init_sudo

    if ! ${has_sudo}; then
        output "sudo is required to perform this operation" "error"
        exit_with_error
    fi

    if $cmd_sudo sh -c "$1" 2>&1 ; then
        return 0
    fi

    return 1
}

call_try_user() {
    if ! call_user "$1"; then
        output "Command failed, re-trying with sudo" "warning"
        if ! call_root "$1"; then
            output "${2:-command failed}" "error"
            exit_with_error
        fi
    fi
}

call_user() {
    sh -c "$1" 2>&1
}

add_footer_note() {
    for var in "$@"; do
        if [ ! -z "$footer_notes" ]; then
            footer_notes="${footer_notes}\n${var}"
        else
            footer_notes="${footer_notes}${var}"
        fi
    done
}

intro() {
    output "Starting plasmactl installation..." "success"
}

outro() {
    output "plasmactl has been installed successfully." "success"

    if command -v "${binaryname}" > /dev/null 2>&1; then
        output ""
	"${binaryname}" --version
    fi

    output "\nWhat's next?" "heading"
    output "  To use the CLI, run: plasmactl" "output"
    output "\nUseful links:" "heading"
    output "  CLI introduction: https://projects.skilld.cloud/skilld/pla-plasmactl/-/blob/master/README.md"

    if [ ! -z "$footer_notes" ]; then
        output "\nWarning during installation:" "heading"
        output "$footer_notes" "warning"
    fi
    output ""
}

# Function to validate the credentials and return HTTP status code
validate_credentials() {
  local username="$1"
  local password="$2"
  local url="$3"

  # Perform the credential validation by making a curl request and retrieving the HTTP status code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" -u "$username:$password" "$url")
  echo "$http_code"
}

# Determine the appropriate values for 'os', 'arch' and 'extension'
case $os in
  Linux*)
    os="linux"
    extension=""
    ;;
  Darwin*)
    os="darwin"
    extension=""
    ;;
  CYGWIN*|MINGW32*|MSYS*|MINGW*)
    os="windows"
    extension=".exe"
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
  arm64|aarch64)
    arch="arm64"
    ;;
  *)
    echo "Unsupported architecture: $arch"
    exit 1
    ;;
esac

## Logic starts here

intro

# Format the URL with the determined 'os', 'arch' and 'extension' values
url=$(printf "$baseurl" "$os" "$arch" "$extension")
echo "Downloading file: ${url}"

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
  echo "Error: HTTP $http_code. Either credentials are invalid or file $binaryname does not exist."
  exit 1
fi

# Download the file using curl or wget with Basic Auth header
if command -v curl >/dev/null 2>&1; then
  curl -u "$username:$password" -O "$url"
elif command -v wget >/dev/null 2>&1; then
  wget --user="$username" --password="$password" "$url"
else
  echo "Neither curl nor wget were found. Please install one of them."
  exit 1
fi

# Renaming downloaded file
tempbinaryname=$(basename "$url")
binaryname="plasmactl${extension}"

if [ ! -e "${tempbinaryname}" ]; then
  echo "File ${binaryname} does not exist."
  exit 1
fi
echo "Renaming file ${tempbinaryname} to ${binaryname}"
mv ${tempbinaryname} ${binaryname}
chmod +x "${binaryname}"

# Installing binary
dirpath="/usr/local/bin"
if [ -n "${PATH+set}" ] && echo $PATH | grep "/usr/local/binXXX" > /dev/null; then # PATH is defined and includes dir where we can move binary
  echo "Installing ${binaryname} binary under ${dirpath}"
  #call_try_user "rm -f ${dirpath}/${binaryname}" "Failed to remove ${dirpath}/${binaryname}"
  call_try_user "mv ${binaryname} ${dirpath}" "Failed to move ${binaryname} to ${dirpath}"
else
  echo "\$PATH is either undefined, empty or does not contain ${dirpath}"
  dirpath="$HOME/.plasmactl"
  if [ ! -d ${dirpath} ]; then mkdir -p ${dirpath} && echo "Creating ${dirpath} directory"; fi
  echo "Moving ${binaryname} to ${dirpath}"
  mv ${binaryname} ${dirpath}

  if ! echo $PATH | grep "${dirpath}" > /dev/null; then
    output "${dirpath} is not in \$PATH." "warning"
    add_footer_note " ⚠ The directory \"${dirpath}/\" is not in \$PATH"
    if echo $SHELL | grep '/bin/zsh' > /dev/null; then
      if ! grep "export PATH=\"${dirpath}:\$PATH\"" "$HOME/.zshrc" > /dev/null; then
        add_footer_note \
        "   Run this command to add the directory to your PATH:" \
        "   echo 'export PATH=\"${dirpath}:\$PATH\"' >> \$HOME/.zshrc && source \$HOME/.zshrc"
      fi
    elif echo $SHELL | grep '/bin/bash' > /dev/null; then
      if ! grep "export PATH=\"${dirpath}:\$PATH\"" "$HOME/.bashrc" > /dev/null; then
        add_footer_note \
        "   Run this command to add the directory to your PATH:" \
        "   echo 'export PATH=\"${dirpath}:\$PATH\"' >> \$HOME/.bashrc && source \$HOME/.bashrc"
      fi
    else
      add_footer_note \
      "   You can add it to your PATH by adding this line at the end of your shell configuration file" \
      "   export PATH=\"${dirpath}:\$PATH\""
    fi
  fi
fi

outro
