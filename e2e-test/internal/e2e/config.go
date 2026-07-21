// Copyright (C) 2026 Ioannis Torakis <john.torakis@gmail.com>
// SPDX-License-Identifier: Elastic-2.0

package e2e

import (
	"fmt"
	"os"
	"strings"
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
	RootToken    string
	ContainerCLI string
	Targets      []Target
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

	return Config{RootToken: token, ContainerCLI: envOr("E2E_CONTAINER_CLI", "podman"), Targets: targets}, nil
}

func envOr(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}
