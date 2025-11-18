# Plasmactl

Your CLI tool for Plasma platform management and operations.

## What is Plasmactl?

[Launchrctl](https://github.com/launchrctl/launchr) + [Core plugins](https://github.com/launchrctl#org-repositories) + [Plasma plugins](https://github.com/plasmash?q=plasmactl&type=all) + Locally discovered actions = **Plasmactl**

Plasmactl is the command-line interface for the [Plasma platform](https://plasma.sh) - an open-source real-time intelligence platform for enterprises, startups, and industries.

## How to Install

### Quick Install (Recommended)

Execute this one-liner command:

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

3. Follow the on-screen instructions

### Verify Installation

```bash
plasmactl --version
```

## How to Update

Execute:
```bash
plasmactl update
```

## Core Plugins

Plasmactl extends its functionality through a modular plugin system:

- [plasmactl-bump](https://github.com/plasmash/plasmactl-bump) - Version management for platform components
- [plasmactl-compose](https://github.com/plasmash/plasmactl-compose) - Multi-package composition and orchestration
- [plasmactl-package](https://github.com/plasmash/plasmactl-package) - Package building and management
- [plasmactl-processors](https://github.com/plasmash/plasmactl-processors) - Data processing utilities
- [plasmactl-publish](https://github.com/plasmash/plasmactl-publish) - Artifact publishing to repositories
- [plasmactl-release](https://github.com/plasmash/plasmactl-release) - Release management and versioning
- [plasmactl-ship](https://github.com/plasmash/plasmactl-ship) - Platform deployment and shipping

## Getting Started

After installation, explore available commands:

```bash
plasmactl --help
```

### Common Commands

- `plasmactl bump` - Bump component versions
- `plasmactl ship` - Deploy platform components
- `plasmactl compose` - Manage package composition
- `plasmactl update` - Update plasmactl to the latest version

## Documentation

- [Plasma Platform Documentation](https://plasma.sh)
- [GitHub Repository](https://github.com/plasmash/plasmactl)
- [Report Issues](https://github.com/plasmash/plasmactl/issues)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/plasmash/plasmactl/issues)
- **Website**: [plasma.sh](https://plasma.sh)
- **Community**: Join our community discussions on GitHub

---

Built with ❤️ by the Plasma community
