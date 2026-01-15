# Plasmactl

The CLI tool for Plasma platform management and operations.

## What is Plasmactl?

[Launchrctl](https://github.com/launchrctl/launchr) + [Core plugins](https://github.com/launchrctl#org-repositories) + [Plasma plugins](https://github.com/plasmash?q=plasmactl&type=all) + Locally discovered actions = **Plasmactl**

Plasmactl is the command-line interface for the [Plasma platform](https://plasma.sh) - an open-source real-time intelligence platform for enterprises, startups, and industries.

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

Plasmactl uses a modular plugin system with three core plugins:

| Plugin | Commands | Description |
|--------|----------|-------------|
| [plasmactl-package](https://github.com/plasmash/plasmactl-package) | `package:compose`, `package:add`, `package:update`, `package:delete` | Multi-package composition |
| [plasmactl-component](https://github.com/plasmash/plasmactl-component) | `component:bump`, `component:sync`, `component:depend` | Version and dependency management |
| [plasmactl-platform](https://github.com/plasmash/plasmactl-platform) | `platform:ship`, `platform:package`, `platform:publish`, `platform:release` | Platform lifecycle management |

## Common Commands

### Package Management

```bash
# Compose packages from dependencies
plasmactl package:compose

# Add a package dependency
plasmactl package:add --package my-package --url https://github.com/org/repo.git --ref main
```

### Component Versioning

```bash
# Bump component versions after changes
plasmactl component:bump

# Propagate versions to dependencies
plasmactl component:sync

# Query component dependencies
plasmactl component:depend platform.entities.person
```

### Platform Deployment

```bash
# Ship to an environment
plasmactl platform:ship dev platform.interaction.observability

# Create deployment artifact
plasmactl platform:package

# Publish artifact
plasmactl platform:publish

# Create release tag
plasmactl platform:release
```

### Typical Workflow

```bash
# 1. Compose packages
plasmactl package:compose

# 2. Bump and sync versions
plasmactl component:bump
plasmactl component:sync

# 3. Deploy to dev
plasmactl platform:ship dev platform.interaction.observability
```

## Platform-Specific Actions

Some actions are provided by the platform package itself (e.g., [plasma-core](https://github.com/plasmash/pla-plasma)), not by plasmactl plugins:

- `platform:prepare` - Prepare runtime environment (optional)
- `platform:deploy` - Deploy to target cluster (required)

These are discovered from `src/platform/actions/` in your platform repository.

## Getting Started

After installation, explore available commands:

```bash
plasmactl --help
plasmactl package:compose --help
plasmactl component:bump --help
plasmactl platform:ship --help
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
