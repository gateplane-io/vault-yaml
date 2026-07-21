//go:build e2e

// Copyright (C) 2026 Ioannis Torakis <john.torakis@gmail.com>
// SPDX-License-Identifier: Elastic-2.0

package example_test

import (
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

	// Targets share host container resources and intentionally run sequentially.
	for _, target := range config.Targets {
		t.Run(target.Name+"/"+config.Reconciler, func(t *testing.T) {
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

	prerequisiteState := filepath.Join(harness.TempDir(), "prerequisites.tfstate")
	prerequisites := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir:  "terraform-prerequisites",
		BackendConfig: map[string]interface{}{"path": prerequisiteState},
		EnvVars:       terraformEnvironment(harness, config, filepath.Join(harness.TempDir(), "prerequisites-data")),
		NoColor:       true,
	})
	if _, err := terraform.InitAndApplyE(t, prerequisites); err != nil {
		t.Fatalf("apply Terraform prerequisites: %v", err)
	}
	defer func() {
		if _, err := terraform.DestroyE(t, prerequisites); err != nil {
			t.Errorf("destroy Terraform prerequisites: %v", err)
		}
	}()

	switch config.Reconciler {
	case "terraform":
		defer runTerraformReconciler(t, harness, config, prerequisiteState)()
	case "crossplane":
		if err := harness.InstallCrossplane(
			filepath.Join("access.yaml"),
			filepath.Join("reconcilers", "crossplane", "values.yaml"),
			filepath.Join("..", "charts", "vault-yaml"),
		); err != nil {
			t.Logf("RECONCILIATION MISMATCH: %v", err)
			t.Fatalf("Crossplane reconciliation did not complete")
		}
		defer harness.CleanupCrossplane()
	}

	selectedExpectations := e2e.ExpectationsForReconciler(expectations, config.Reconciler)
	t.Logf("running %d of %d expectations for reconciler %s", len(selectedExpectations), len(expectations), config.Reconciler)
	mismatches := harness.AssertAll(selectedExpectations)
	for _, mismatch := range mismatches {
		t.Logf("ASSERTION MISMATCH: %s", mismatch)
	}
	if len(mismatches) != 0 {
		t.Fatalf("%d assertion mismatch(es)", len(mismatches))
	}
}

func runTerraformReconciler(t *testing.T, harness *e2e.Harness, config e2e.Config, prerequisiteState string) func() {
	t.Helper()
	options := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir:  filepath.Join("reconcilers", "terraform"),
		Vars:          map[string]interface{}{"prerequisite_state_path": prerequisiteState},
		BackendConfig: map[string]interface{}{"path": filepath.Join(harness.TempDir(), "vault-yaml.tfstate")},
		EnvVars:       terraformEnvironment(harness, config, filepath.Join(harness.TempDir(), "vault-yaml-data")),
		NoColor:       true,
	})
	if _, err := terraform.InitAndApplyE(t, options); err != nil {
		t.Fatalf("apply Vault-YAML Terraform modules: %v", err)
	}
	return func() {
		if _, err := terraform.DestroyE(t, options); err != nil {
			t.Errorf("destroy Vault-YAML Terraform modules: %v", err)
		}
	}
}

func terraformEnvironment(harness *e2e.Harness, config e2e.Config, dataDir string) map[string]string {
	return map[string]string{
		"VAULT_ADDR":  harness.Address(),
		"VAULT_TOKEN": config.RootToken,
		"TF_DATA_DIR": dataDir,
	}
}
