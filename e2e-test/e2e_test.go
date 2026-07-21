//go:build e2e

// Copyright (C) 2026 Ioannis Torakis <john.torakis@gmail.com>
// SPDX-License-Identifier: Elastic-2.0

package example_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/itorakis/gateplane/vault-yaml/e2e-test/internal/e2e"
)

func TestVaultCompatibleMatrix(t *testing.T) {
	config, err := e2e.LoadConfig()
	if err != nil {
		t.Fatal(err)
	}
	expectations, err := e2e.ParseExpectations("expectations.yaml")
	if err != nil {
		t.Fatal(err)
	}

	// Deliberately do not use t.Parallel: targets share host container and kubectl resources.
	for _, target := range config.Targets {
		t.Run(target.Name, func(t *testing.T) {
			runTarget(t, config, target, expectations)
		})
	}
}

func runTarget(t *testing.T, config e2e.Config, target e2e.Target, expectations []e2e.Expectation) {
	harness := e2e.NewHarness(t, config, target)
	defer harness.Cleanup()

	if err := harness.Start(); err != nil {
		t.Fatalf("start ephemeral %s environment: %v", target.Name, err)
	}

	options := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: filepath.Join("terraform"),
		EnvVars: map[string]string{
			"VAULT_ADDR":  harness.Address(),
			"VAULT_TOKEN": config.RootToken,
			"TF_DATA_DIR": filepath.Join(harness.TempDir(), "terraform-data"),
		},
		NoColor: true,
	})
	defer cleanupTerraformState(t, options.TerraformDir)
	defer func() {
		if _, err := terraform.DestroyE(t, options); err != nil {
			t.Errorf("terraform destroy failed: %v", err)
		}
	}()
	if _, err := terraform.InitAndApplyE(t, options); err != nil {
		t.Fatalf("terraform init/apply failed: %v", err)
	}

	mismatches := harness.AssertAll(expectations)
	for _, mismatch := range mismatches {
		t.Logf("ASSERTION MISMATCH: %s", mismatch)
	}
	if len(mismatches) != 0 {
		t.Fatalf("%d assertion mismatch(es)", len(mismatches))
	}
}

func cleanupTerraformState(t *testing.T, terraformDir string) {
	t.Helper()
	for _, name := range []string{"terraform.tfstate", "terraform.tfstate.backup", ".terraform.tfstate.lock.info"} {
		if err := os.Remove(filepath.Join(terraformDir, name)); err != nil && !os.IsNotExist(err) {
			t.Errorf("remove Terraform artifact %s: %v", name, err)
		}
	}
}
