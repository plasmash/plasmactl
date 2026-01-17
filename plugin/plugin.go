// Package plugin provides the core plasmactl plugin that defines Plasma project conventions.
package plugin

import (
	"strings"

	"github.com/launchrctl/launchr"
	"github.com/launchrctl/launchr/pkg/action"
)

// srcMarker is the marker used to identify src directory in action IDs.
const srcMarker = "src."

func init() {
	launchr.RegisterPlugin(&Plugin{})
}

// Plugin is the core plasmactl plugin that sets up Plasma project conventions.
type Plugin struct {
	am action.Manager
}

// PluginInfo implements [launchr.Plugin] interface.
func (p *Plugin) PluginInfo() launchr.PluginInfo {
	// High weight to run early and set up ID provider before action discovery.
	return launchr.PluginInfo{Weight: 1}
}

// OnAppInit implements [launchr.OnAppInitPlugin] interface.
func (p *Plugin) OnAppInit(app launchr.App) error {
	// Get the action manager service.
	app.Services().Get(&p.am)

	// Set a custom ID provider that strips prefixes ending with "src." from action IDs.
	// This ensures actions at src/platform/actions/prepare/ have ID "platform:prepare"
	// instead of "src.platform:prepare", and actions at
	// .plasma/package/compose/merged/src/platform/actions/prepare/ also get "platform:prepare"
	// instead of ".plasma.package.compose.merged.src.platform:prepare".
	p.am.SetActionIDProvider(&PlasmaIDProvider{})

	return nil
}

// PlasmaIDProvider is an action ID provider that normalizes IDs for Plasma conventions.
type PlasmaIDProvider struct{}

// GetID implements [action.IDProvider] interface.
// It strips any prefix ending with "src." from action IDs.
func (idp *PlasmaIDProvider) GetID(a *action.Action) string {
	// Use default ID generation first.
	id := action.DefaultIDProvider{}.GetID(a)

	// Find the last occurrence of "src." and strip everything before and including it.
	// This handles both "src.platform:prepare" and ".plasma.package.compose.merged.src.platform:prepare".
	if idx := strings.LastIndex(id, srcMarker); idx != -1 {
		return id[idx+len(srcMarker):]
	}

	return id
}
