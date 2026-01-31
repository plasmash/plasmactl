PLUGIN_LIST := \
  github.com/plasmash/plasmactl/plugin@v0.4.1 \
  github.com/launchrctl/scaffold@v0.1.1 \
  github.com/launchrctl/keyring@v0.9.1 \
  github.com/launchrctl/launchr@v0.22.0 \
  github.com/launchrctl/update@v1.1.4 \
  github.com/launchrctl/web@v0.16.1 \
  github.com/plasmash/plasmactl-model@v1.5.1 \
  github.com/plasmash/plasmactl-component@v1.2.2 \
  github.com/plasmash/plasmactl-platform@v1.5.1 \
  github.com/plasmash/plasmactl-node@v1.0.3 \
  github.com/plasmash/plasmactl-chassis@v1.0.17 \
  github.com/plasmash/plasmactl-processors@v0.1.1

# Local plugin replace directive (used in Makefile build command)
# Commented out for release builds - uncomment for local development
# LOCAL_PLUGIN_REPLACE := github.com/plasmash/plasmactl/plugin=./plugin
