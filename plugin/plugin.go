// Package plugin provides the core plasmactl plugin that defines Plasma project conventions.
package plugin

import (
	"os"
	"path/filepath"

	"github.com/launchrctl/launchr"
	"github.com/launchrctl/launchr/pkg/action"
)

// Plasma project directory structure constants.
const (
	// srcDir is the standard Plasma project source directory.
	srcDir = "src"
	// composeMergedSrcDir is the src/ subdirectory where composed packages are merged.
	composeMergedSrcDir = ".plasma/package/compose/merged/src"
)

func init() {
	launchr.RegisterPlugin(&Plugin{})
}

// Plugin is the core plasmactl plugin that sets up Plasma project conventions.
type Plugin struct{}

// PluginInfo implements [launchr.Plugin] interface.
func (p *Plugin) PluginInfo() launchr.PluginInfo {
	// High weight to run early and set up discovery roots before other plugins.
	return launchr.PluginInfo{Weight: 1}
}

// OnAppInit implements [launchr.OnAppInitPlugin] interface.
func (p *Plugin) OnAppInit(app launchr.App) error {
	wd := app.GetWD()

	// Register src/ as a discovery root if it exists.
	// This allows actions at src/platform/actions/prepare/ to have ID "platform:prepare"
	// instead of "src.platform:prepare".
	srcPath := filepath.Join(wd, srcDir)
	if stat, err := os.Stat(srcPath); err == nil && stat.IsDir() {
		app.RegisterFS(action.NewDiscoveryFS(os.DirFS(srcPath), wd))
	}

	// Register composed packages src/ directory as a discovery root if it exists.
	// This ensures actions at .plasma/package/compose/merged/src/platform/actions/...
	// get clean IDs like "platform:prepare" instead of "src.platform:prepare".
	composeSrcPath := filepath.Join(wd, composeMergedSrcDir)
	if stat, err := os.Stat(composeSrcPath); err == nil && stat.IsDir() {
		app.RegisterFS(action.NewDiscoveryFS(os.DirFS(composeSrcPath), wd))
	}

	return nil
}
