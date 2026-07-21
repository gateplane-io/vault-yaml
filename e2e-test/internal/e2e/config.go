// Copyright (C) 2026 Ioannis Torakis <john.torakis@gmail.com>
// SPDX-License-Identifier: Elastic-2.0

package e2e

import (
	"fmt"
	"os"
	"strings"
	"time"
)

// Target describes one Vault-compatible server under test.
type Target struct {
	Name    string
	Image   string
	CLI     string
	PodName string
}

// Config contains settings shared by all matrix entries.
type Config struct {
	RootToken            string
	ContainerCLI         string
	Reconciler           string
	CrossplaneVersion    string
	ProviderVaultPackage string
	CrossplaneTimeout    time.Duration
	CommandTimeout       time.Duration
	Targets              []Target
}

// LoadConfig reads and validates the E2E environment.
func LoadConfig() (Config, error) {
	token := envOr("E2E_ROOT_TOKEN", "e2e-test-token")

	vaultTag := envOr("E2E_VAULT_VERSION", "latest")
	openBaoTag := envOr("E2E_OPENBAO_VERSION", "latest")
	matrix := map[string]Target{
		"vault":   {Name: "vault", Image: "hashicorp/vault:" + vaultTag, CLI: "vault", PodName: "vault"},
		"openbao": {Name: "openbao", Image: "openbao/openbao:" + openBaoTag, CLI: "bao", PodName: "openbao"},
	}

	selection := strings.ToLower(envOr("E2E_TARGET", "both"))
	var targets []Target
	switch selection {
	case "vault":
		targets = []Target{matrix["vault"]}
	case "openbao":
		targets = []Target{matrix["openbao"]}
	case "both":
		targets = []Target{matrix["vault"], matrix["openbao"]}
	default:
		return Config{}, fmt.Errorf("E2E_TARGET must be vault, openbao, or both; got %q", selection)
	}

	reconciler := strings.ToLower(envOr("E2E_RECONCILER", "terraform"))
	if reconciler != "terraform" && reconciler != "crossplane" {
		return Config{}, fmt.Errorf("E2E_RECONCILER must be terraform or crossplane; got %q", reconciler)
	}

	providerVersion := envOr("E2E_PROVIDER_VAULT_VERSION", "v4.0.0")
	crossplaneTimeout, err := time.ParseDuration(envOr("E2E_CROSSPLANE_TIMEOUT", "20m"))
	if err != nil || crossplaneTimeout <= 0 {
		return Config{}, fmt.Errorf("E2E_CROSSPLANE_TIMEOUT must be a positive duration")
	}
	commandTimeout, err := time.ParseDuration(envOr("E2E_COMMAND_TIMEOUT", "25m"))
	if err != nil || commandTimeout <= 0 {
		return Config{}, fmt.Errorf("E2E_COMMAND_TIMEOUT must be a positive duration")
	}
	return Config{
		RootToken:            token,
		ContainerCLI:         envOr("E2E_CONTAINER_CLI", "podman"),
		Reconciler:           reconciler,
		CrossplaneVersion:    envOr("E2E_CROSSPLANE_VERSION", "2.3.3"),
		ProviderVaultPackage: "xpkg.upbound.io/upbound/provider-vault:" + providerVersion,
		CrossplaneTimeout:    crossplaneTimeout,
		CommandTimeout:       commandTimeout,
		Targets:              targets,
	}, nil
}

func envOr(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}
