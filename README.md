# Plasmactl

- Your CLI tool for platform related commands

## What ?

- [Launchrctl](https://github.com/launchrctl/launchr) + [Core plugins](https://github.com/launchrctl#org-repositories) + [Plasma/Skilld plugins](https://github.com/skilld-labs?q=plasmactl&type=all&language=&sort=#org-repositories) + Locally discovered actions = **Plasmactl**

## How to install ?

- Execute this one-liner command:
```
echo "Enter your Skilld.cloud credentials:" && echo -n "Username: " && read username && echo -n "Password: " && stty -echo && read password && stty echo && echo && if curl -u "$username:$password" -s -o /tmp/get-plasmactl.sh -w "%{http_code}" https://repositories.skilld.cloud/repository/pla-plasmactl-raw/get-plasmactl.sh | grep -q 200; then sh /tmp/get-plasmactl.sh "$username" "$password"; else echo "Invalid credentials. Access denied."; fi
```
- Fill your Skilld platform credentials when prompted

## How to update ?

- Execute:
```
plasmacl update
```
