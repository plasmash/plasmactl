#!/bin/sh
set -e
#set -x

# Get the operating system type
os=$(uname -s)

# Get the machine architecture
arch=$(uname -m)

# Define the URL pattern for the file
baseurl="https://repositories.skilld.cloud/repository/pla-plasmactl-raw/latest/plasmactl_%s_%s%s"

# Create a log file where every output will be piped to
: "${LOG_FILE:=/tmp/get-plasmactl-$(date '+%Y%m%d-%H%M%S').log}"
pipe=/tmp/get-plasmactl-$$.tmp
mkfifo "$pipe"
tee < "$pipe" "${LOG_FILE}" &
exec 1>&-
exec 1>"$pipe" 2>&1
trap 'rm -f "$pipe"' EXIT

# Avoid unbounded variable
has_sudo=""
footer_notes=""

output() {
  style_start=""
  style_end=""
  if [ "${2:-}" != "" ]; then
    case $2 in
      "success")
        style_start="$(printf '\033[0;32m')"
        style_end="$(printf '\033[0m')"
        ;;
      "error")
        style_start="$(printf '\033[31;31m')"
        style_end="$(printf '\033[0m')"
        ;;
      "info" | "warning")
        style_start="$(printf '\033[33m')"
        style_end="$(printf '\033[39m')"
        ;;
      "heading")
        style_start="$(printf '\033[1;33m')"
        style_end="$(printf '\033[22;39m')"
        ;;
      "comment")
        style_start="$(printf '\033[2m')"
        style_end="$(printf '\033[22;39m')"
        ;;
    esac
  fi

  printf "%b%s%b\\n" "${style_start}" "$1" "${style_end}"
}

exit_with_error() {
  if [ -e "${binaryname}" ]; then rm "${binaryname}"; fi
  output "Installation failed" "error"
  output ""
  output "Get help with your plasmactl setup:" "heading"
  output "- https://im.skilld.cloud/group/pla-plasmactl.client" "heading"
  output "- https://im.skilld.cloud/group/pla-plasmactl.prod" "heading"
  output ""
  output "Log file: ${LOG_FILE}"
  output ""
  exit 1
}

init_sudo() {
  if [ -n "${has_sudo}" ]; then
    return
  fi

  has_sudo=false
  # Are we running the installer as root?
  if [ "$(id -u)" = "0" ]; then
    has_sudo=true
    cmd_sudo=''
    return
  fi

  if command -v doas > /dev/null 2>&1; then
    has_sudo=true
    cmd_sudo='doas'
  elif command -v sudo > /dev/null 2>&1; then
    has_sudo=true
    cmd_sudo='sudo'
  fi
}

call_root() {
  init_sudo

  if ! "${has_sudo}"; then
    output "doas or sudo is required to perform this operation" "error"
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
    if [ -n "$footer_notes" ]; then
      footer_notes="${footer_notes}
${var}"
    else
      footer_notes="${footer_notes}${var}"
    fi
  done
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
  CYGWIN* | MINGW32* | MSYS* | MINGW*)
    os="windows"
    extension=".exe"
    ;;
  *)
    output "Unsupported operating system: $os" "error"
    exit 1
    ;;
esac

case $arch in
  x86_64 | amd64)
    arch="amd64"
    ;;
  i?86 | x86)
    arch="386"
    ;;
  arm64 | aarch64)
    arch="arm64"
    ;;
  *)
    output "Unsupported architecture: $arch" "error"
    exit 1
    ;;
esac

## Logic starts here

output "Starting plasmactl installation..." "success"

# Format the URL with the determined 'os', 'arch' and 'extension' values
url=$(printf "$baseurl" "$os" "$arch" "$extension")
output "Downloading file: ${url}"

# Check if username and password are passed as script arguments
if [ $# -eq 2 ]; then
  username="$1"
  password="$2"
else
  # Prompt user for username and password
  output "Username: "
  read -r username
  output "Password: "
  read -r password
  output ""
fi

# Check the validity of the credentials
http_code=$(validate_credentials "$username" "$password" "$url")
if [ -z "$http_code" ]; then
  output "Error: Failed to validate credentials. Access denied." "error"
  exit 1
elif [ "$http_code" -eq 200 ]; then
  output "Valid credentials. Access granted."
else
  output "Error: HTTP $http_code. Either credentials are invalid or file $binaryname does not exist." "error"
  exit 1
fi

# Download the file using curl or wget with Basic Auth header
if command -v curl >/dev/null 2>&1; then
  curl -sS -u "$username:$password" -O "$url"
elif command -v wget >/dev/null 2>&1; then
  wget --user="$username" --password="$password" "$url"
else
  output "Neither curl nor wget were found. Please install one of them." "error"
  exit 1
fi

# Renaming downloaded file
tempbinaryname=$(basename "$url")
binaryname="plasmactl${extension}"

if [ ! -e "${tempbinaryname}" ]; then
  output "File ${binaryname} does not exist." "error"
  exit 1
fi
output "Renaming file ${tempbinaryname} to ${binaryname}"
mv "${tempbinaryname}" "${binaryname}"
chmod +x "${binaryname}"

# Installing binary
if echo $PATH | grep "$HOME/.global/bin" > /dev/null; then
  dirpath="$HOME/.global/bin"
elif echo $PATH | grep "$HOME/.local/bin" > /dev/null; then
  dirpath="$HOME/.local/bin"
elif echo $PATH | grep "/usr/local/bin" > /dev/null; then
  dirpath="/usr/local/bin"
fi
if [ -n "${dirpath}" ] && [ -n "${PATH+set}" ] && printf "%s" "$PATH" | grep "${dirpath}" > /dev/null; then # PATH is defined and includes dir where we can move binary
  output "Installing ${binaryname} binary under ${dirpath}"
  call_try_user "mv ${binaryname} ${dirpath}" "Failed to move ${binaryname} to ${dirpath}"
else
  output "\$PATH does not contain ${dirpath}" # PATH is either undefined, empty or does not contain ${dirpath}
  dirpath="$HOME/.plasmactl"
  if [ ! -d "${dirpath}" ]; then mkdir -p "${dirpath}" && output "Creating ${dirpath} directory"; fi
  output "Moving ${binaryname} to ${dirpath}"
  mv "${binaryname}" "${dirpath}"

  if ! printf "%s" "$PATH" | grep "${dirpath}" > /dev/null; then
    output "${dirpath} is not in \$PATH." "warning"
    add_footer_note " ⚠ The directory \"${dirpath}/\" is not in \$PATH"
    if [ "$(basename $SHELL)" = "zsh" ]; then
      if ! grep "export PATH=\"${dirpath}:\$PATH\"" "$HOME/.zshrc" > /dev/null; then
        add_footer_note \
          "   Run this command to add the directory to your PATH:" \
          "   echo 'export PATH=\"${dirpath}:\$PATH\"' >> \$HOME/.zshrc && . \$HOME/.zshrc"
      fi
    elif [ "$(basename $SHELL)" = "bash" ]; then
      if ! grep "export PATH=\"${dirpath}:\$PATH\"" "$HOME/.bashrc" > /dev/null; then
        add_footer_note \
          "   Run this command to add the directory to your PATH:" \
          "   echo 'export PATH=\"${dirpath}:\$PATH\"' >> \$HOME/.bashrc && . \$HOME/.bashrc"
      fi
    else
      add_footer_note \
        "   You can add it to your PATH by adding this line at the end of your shell configuration file" \
        "   export PATH=\"${dirpath}:\$PATH\""
    fi
  fi
fi

# Prepare commands autocompletion
autocomplete_helper() {
  if [ -n "$SHELL" ]; then
    if [ "$(basename $SHELL)" = "bash" ] || [ "$(basename $SHELL)" = "fish" ] || [ "$(basename $SHELL)" = "powershell" ] || [ "$(basename $SHELL)" = "zsh" ]; then
      completion_script_name=completion_script
      output "  - Run this command to add autocompletion:"
      echo "    \"${binaryname} completion $(basename $SHELL) > ${completion_script_name} && source ${completion_script_name} && rm ${completion_script_name}\""
    fi
  fi
}
# Outro
output "plasmactl has been installed successfully." "success"
if command -v "${binaryname}" > /dev/null 2>&1; then
output ""
"${binaryname}" --version
fi
output ""
output "What's next?" "heading"
autocomplete_helper
output "  - To use the CLI, run: plasmactl" "output"
output ""
output "Useful links:" "heading"
output "  - CLI introduction: https://projects.skilld.cloud/skilld/pla-plasmactl/-/blob/master/README.md"
if [ -n "$footer_notes" ]; then
output ""
output "Warning during installation:" "heading"
output "$footer_notes" "warning"
fi
output ""

