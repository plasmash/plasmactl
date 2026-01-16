PLUGIN_LIST := \
  github.com/plasmash/plasmactl/plugin \
  github.com/launchrctl/scaffold@v0.1.1 \
  github.com/launchrctl/keyring@v0.7.0 \
  github.com/launchrctl/launchr@v0.22.0 \
  github.com/launchrctl/update@v1.1.2 \
  github.com/launchrctl/web@v0.16.1 \
  github.com/plasmash/plasmactl-package@v1.1.3 \
  github.com/plasmash/plasmactl-component@v1.1.1 \
  github.com/plasmash/plasmactl-platform@v1.2.1 \
  github.com/plasmash/plasmactl-processors@v0.1.1

# Local plugin replace directive (used in Makefile build command)
LOCAL_PLUGIN_REPLACE := github.com/plasmash/plasmactl/plugin=./plugin
