#!/bin/sh
set -e
# set -x

baseurl="https://repositories.skilld.cloud/repository/pla-plasmactl-raw"
release_path="stable_release"
binaries_path="%s/%s/plasmactl_%s_%s%s"

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

# Function to validate the credentials and return HTTP status code
validate_credentials() {
  local username="$1"
  local password="$2"
  local url="$3"

  # Perform the credential validation by making a curl request and retrieving the HTTP status code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" -u "$username:$password" "$url")
  echo "$http_code"
}


# Check if username and password are passed as script arguments
if [ $# -eq 2 ]; then
  username="$1"
  password="$2"
else
  # Prompt user for username and password
  output "Enter your Skilld.cloud credentials:"
  read -p "Username: " username
  read -sp "Password: " password
  output ""
fi

stable_release_url=$(echo "${baseurl}/${release_path}")
# Check the validity of the credentials
http_code=$(validate_credentials "$username" "$password" "${stable_release_url}")
if [ -z "$http_code" ]; then
  output "Error: Failed to validate credentials. Access denied." "error"
  exit 1
elif [ "$http_code" -eq 200 ]; then
  output "Valid credentials. Access granted."
elif [ "$http_code" -eq 401 ]; then
  output "Error: HTTP $http_code: Unauthorized. Credentials seem to be invalid." "error"
  exit 1
elif [ "$http_code" -eq 404 ]; then
  output "Error: HTTP $http_code: Not Found. File ${stable_release_url} does not exist." "error"
  exit 1
else
  output "Error: HTTP $http_code. An issue appeared while trying to validate credentials against ${stable_release_url}." "error"
  exit 1
fi

# Get value of stable_release
if command -v curl >/dev/null 2>&1; then
  stable_release=$(curl -sS -u "$username:$password" -X GET "${stable_release_url}" | tr -d '\n')
elif command -v wget >/dev/null 2>&1; then
  stable_release=$(wget -q --user="$username" --password="$password" "${stable_release_url}" -O - | tr -d '\n')
else
  output "Neither curl nor wget were found. Please install one of them." "error"
  exit 1
fi
output "Stable release: ${stable_release}"

read -p "New stable release: " new_stable_release
output ""

output "Updating latest release value on remote..."
new_stable_release_path="/tmp/new_stable_release"
echo "${new_stable_release}" > ${new_stable_release_path}
curl -sS -u "$username:$password" -s 'https://repositories.skilld.cloud/repository/pla-plasmactl-raw/stable_release' --upload-file "${new_stable_release_path}"
output "Done."

# Get value of stable_release
if command -v curl >/dev/null 2>&1; then
  stable_release=$(curl -sS -u "$username:$password" -X GET "${stable_release_url}" | tr -d '\n')
elif command -v wget >/dev/null 2>&1; then
  stable_release=$(wget -q --user="$username" --password="$password" "${stable_release_url}" -O - | tr -d '\n')
else
  output "Neither curl nor wget were found. Please install one of them." "error"
  exit 1
fi
output "Stable release: ${stable_release}"
