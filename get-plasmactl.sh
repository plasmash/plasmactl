#!/bin/sh
set -e
#set -x

# Get the operating system type
os_raw=$(uname -s)

# Get the machine architecture
arch_raw=$(uname -m)

# GitHub repository settings
github_repo="plasmash/plasmactl"
github_api_url="https://api.github.com/repos/${github_repo}/releases/latest"

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
override_install_dir=""

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
      "info"|"warning")
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

  printf "%b%s%b\n" "${style_start}" "$1" "${style_end}"
}

exit_with_error() {
  if [ -e "${binaryname}" ]; then rm "${binaryname}"; fi
  output "Installation failed" "error"
  output ""
  output "Get help with your plasmactl setup:" "heading"
  output "- https://github.com/plasmash/plasmactl/issues" "heading"
  output "- https://plasma.sh" "heading"
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

  if command -v doas >/dev/null 2>&1; then
    has_sudo=true
    cmd_sudo='doas'
  elif command -v sudo >/dev/null 2>&1; then
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
      footer_notes="${footer_notes}\n${var}"
    else
      footer_notes="${var}"
    fi
  done
}

# Determine the appropriate values for 'os', 'arch' and 'extension'
extension=""
case "$os_raw" in
  Linux*)
    os="Linux"
    ;;
  Darwin*)
    os="Darwin"
    ;;
  CYGWIN*|MINGW32*|MSYS*|MINGW*|Windows*)
    os="Windows"
    extension=".exe"
    ;;
  *)
    output "Unsupported operating system: $os_raw" "error"
    exit 1
    ;;
esac

case "$arch_raw" in
  x86_64|amd64)
    arch="x86_64"
    ;;
  arm64|aarch64)
    arch="arm64"
    ;;
  *)
    output "Unsupported architecture: $arch_raw" "error"
    exit 1
    ;;
esac

## Logic starts here

output "Starting plasmactl installation..." "success"

# If plasmactl is already installed, grab its directory to reuse
if command -v plasmactl >/dev/null 2>&1; then
  existing_path=$(command -v plasmactl)
  override_install_dir=$(dirname "$existing_path")
  output "Found existing plasmactl at ${existing_path}, will install to ${override_install_dir}" "info"
fi

# Fetch latest release information from GitHub
output "Fetching latest release information from GitHub..."
if command -v curl >/dev/null 2>&1; then
  release_data=$(curl -sS "${github_api_url}")
elif command -v wget >/dev/null 2>&1; then
  release_data=$(wget -qO- "${github_api_url}")
else
  output "Neither curl nor wget were found. Please install one of them." "error"
  exit 1
fi

# Parse the release tag name
release_tag=$(echo "$release_data" | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
if [ -z "$release_tag" ]; then
  output "Error: Could not determine latest release version." "error"
  exit 1
fi
output "Latest release: ${release_tag}"

# Construct the binary filename and download URL
binary_filename="plasmactl_${os}_${arch}${extension}"
url="https://github.com/${github_repo}/releases/download/${release_tag}/${binary_filename}"
output "Downloading file: ${url}"

# Download the file
if command -v curl >/dev/null 2>&1; then
  if ! curl -sSL -o "${binary_filename}" "${url}"; then
    output "Error: Failed to download ${url}" "error"
    exit 1
  fi
elif command -v wget >/dev/null 2>&1; then
  if ! wget -q -O "${binary_filename}" "${url}"; then
    output "Error: Failed to download ${url}" "error"
    exit 1
  fi
else
  output "Neither curl nor wget were found. Please install one of them." "error"
  exit 1
fi

# Prepare the binary
binaryname="plasmactl${extension}"

if [ ! -e "${binary_filename}" ]; then
  output "File ${binary_filename} does not exist." "error"
  exit 1
fi
output "Renaming file ${binary_filename} to ${binaryname}"
mv "${binary_filename}" "${binaryname}"
chmod +x "${binaryname}"

# Installing binary (reuse existing dir if detected)
if [ -n "${override_install_dir}" ]; then
  dirpath="${override_install_dir}"
  output "Installing ${binaryname} into existing directory ${dirpath}"
else
  if echo $PATH | grep "$HOME/.global/bin" >/dev/null; then
    dirpath="$HOME/.global/bin"
  elif echo $PATH | grep "$HOME/.local/bin" >/dev/null; then
    dirpath="$HOME/.local/bin"
  elif echo $PATH | grep "/usr/local/bin" >/dev/null; then
    dirpath="/usr/local/bin"
  fi
fi

if [ -n "${dirpath}" ] && [ -n "${PATH+set}" ] && printf "%s" "$PATH" | grep "${dirpath}" >/dev/null; then
  output "Installing ${binaryname} binary under ${dirpath}"
  call_try_user "mkdir -p ${dirpath}"
  call_try_user "mv ${binaryname} ${dirpath}" "Failed to move ${binaryname} to ${dirpath}"
else
  output "\$PATH does not contain ${dirpath}" # PATH is either undefined, empty or does not contain ${dirpath}
  dirpath="$HOME/.plasmactl"
  if [ ! -d "${dirpath}" ]; then mkdir -p "${dirpath}" && output "Creating ${dirpath} directory"; fi
  output "Moving ${binaryname} to ${dirpath}"
  mv "${binaryname}" "${dirpath}"

  if ! printf "%s" "$PATH" | grep "${dirpath}" >/dev/null; then
    output "${dirpath} is not in \$PATH." "warning"
    add_footer_note " ⚠ The directory \"${dirpath}/\" is not in \$PATH"
    if [ "$(basename $SHELL)" = "zsh" ]; then
      if ! grep "export PATH=\"${dirpath}:\$PATH\"" "$HOME/.zshrc" >/dev/null; then
        add_footer_note \
          "   Run this command to add the directory to your PATH:" \
          "   echo 'export PATH=\"${dirpath}:\$PATH\"' >> \$HOME/.zshrc && . \$HOME/.zshrc"
      fi
    elif [ "$(basename $SHELL)" = "bash" ]; then
      if ! grep "export PATH=\"${dirpath}:\$PATH\"" "$HOME/.bashrc" >/dev/null; then
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
    case "$(basename $SHELL)" in
      bash|fish|powershell|zsh)
        completion_script_name=completion_script
        output "  - Run this command to add autocompletion:" "info"
        echo "    \"${binaryname} completion $(basename $SHELL) > ${completion_script_name} && source ${completion_script_name} && rm ${completion_script_name}\""
        ;;
    esac
  fi
}
# Outro
output "plasmactl has been installed successfully." "success"
if command -v "${binaryname}" >/dev/null 2>&1; then
  output ""
  "${binaryname}" --version
fi
output ""
output "What's next?" "heading"
autocomplete_helper
output "  - To use the CLI, run: plasmactl" "info"
output ""
output "Useful links:" "heading"
output "  - CLI documentation: https://github.com/plasmash/plasmactl/blob/main/README.md" "info"
output "  - Plasma platform: https://plasma.sh" "info"
if [ -n "$footer_notes" ]; then
  output ""
  output "Warning during installation:" "heading"
  output "$footer_notes" "warning"
fi
output ""

