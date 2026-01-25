# Plasmactl

The CLI tool for Plasma platform management and operations.

## What is Plasmactl?

[Launchrctl](https://github.com/launchrctl/launchr) + [Core plugins](https://github.com/launchrctl#org-repositories) + [Plasma plugins](https://github.com/plasmash?q=plasmactl&type=all) + Locally discovered actions = **Plasmactl**

Plasmactl is the command-line interface for the [Plasma platform](https://plasma.sh) - an open-source real-time intelligence platform for enterprises, startups, and industries.

## Requirements

- **Docker**: Required for running container-based actions (prepare, deploy, release, etc.)

## Installation

### Quick Install (Recommended)

```bash
curl -sSL https://raw.githubusercontent.com/plasmash/plasmactl/master/get-plasmactl.sh | sh
```

### Manual Installation

1. Download the installation script:
   ```bash
   curl -sSL -o get-plasmactl.sh https://raw.githubusercontent.com/plasmash/plasmactl/master/get-plasmactl.sh
   ```

2. Make it executable and run:
   ```bash
   chmod +x get-plasmactl.sh
   ./get-plasmactl.sh
   ```

### Verify Installation

```bash
plasmactl --version
```

## Update

```bash
plasmactl update
```

## Core Plugins

Plasmactl uses a modular plugin system:

| Plugin | Commands | Description |
|--------|----------|-------------|
| [plasmactl-model](https://github.com/plasmash/plasmactl-model) | `model:compose`, `model:prepare`, `model:bundle`, `model:release` | Model composition and preparation |
| [plasmactl-platform](https://github.com/plasmash/plasmactl-platform) | `platform:up`, `platform:create`, `platform:deploy`, `config:*` | Platform lifecycle management |
| [plasmactl-node](https://github.com/plasmash/plasmactl-node) | `node:provision`, `node:add`, `node:list`, `node:destroy` | Node provisioning and management |
| [plasmactl-component](https://github.com/plasmash/plasmactl-component) | `component:bump`, `component:sync`, `component:depend` | Version and dependency management |

## Command Namespaces

### model:* - Model Composition

```bash
plasmactl model:compose              # Compose packages from compose.yaml
plasmactl model:prepare              # Prepare for Ansible deployment
plasmactl model:bundle               # Create .pm artifact
plasmactl model:release              # Create git tag with changelog
```

### platform:* - Platform Management

```bash
plasmactl platform:create ski-dev \  # Create platform scaffold
  --metal-provider scaleway \
  --dns-provider ovh \
  --domain dev.skilld.cloud

plasmactl platform:up dev target     # Full workflow: bump → compose → prepare → deploy
plasmactl platform:deploy dev target # Deploy to platform
plasmactl platform:list              # List platforms
plasmactl platform:show ski-dev      # Show platform details
plasmactl platform:destroy ski-dev   # Destroy platform
```

### node:* - Node Provisioning

```bash
plasmactl node:provision ski-dev \   # Provision infrastructure
  -c foundation.cluster.control:GP1-L:3

plasmactl node:register ski-dev \    # Manual node registration
  --hostname server1 \
  --public-ip 1.2.3.4

plasmactl node:list ski-dev          # List nodes
plasmactl node:destroy ski-dev srv1  # Destroy node
```

### config:* - Configuration Management

```bash
plasmactl config:get key             # Get config value
plasmactl config:set key=value       # Set config value
plasmactl config:list                # List config values
plasmactl config:validate            # Validate configuration
plasmactl config:rotate              # Rotate secrets
```

### component:* - Component Versioning

```bash
plasmactl component:bump             # Bump component versions
plasmactl component:sync             # Propagate versions to dependencies
plasmactl component:depend mrn       # Query/manage dependencies
```

## Typical Workflow

### End-to-End Platform Setup

```bash
# 1. Create platform
plasmactl platform:create ski-dev \
  --metal-provider scaleway \
  --dns-provider ovh \
  --domain dev.skilld.cloud

# 2. Provision infrastructure
plasmactl node:provision ski-dev \
  -c foundation.cluster.control:GP1-L:3

# 3. Deploy
plasmactl platform:up dev platform.foundation
```

### Daily Development

```bash
# Make changes, then:
plasmactl component:bump
plasmactl platform:up dev platform.interaction.observability
```

## Getting Started

After installation, explore available commands:

```bash
plasmactl --help
plasmactl model:compose --help
plasmactl platform:up --help
plasmactl node:provision --help
```

## Documentation

- [Plasma Platform](https://plasma.sh) - Platform documentation
- [GitHub Repository](https://github.com/plasmash/plasmactl)
- [Report Issues](https://github.com/plasmash/plasmactl/issues)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[European Union Public License 1.2 (EUPL-1.2)](LICENSE)

## Support

- **Issues**: [GitHub Issues](https://github.com/plasmash/plasmactl/issues)
- **Website**: [plasma.sh](https://plasma.sh)
