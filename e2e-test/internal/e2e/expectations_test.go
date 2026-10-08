// Copyright (C) 2026 Ioannis Torakis <john.torakis@gmail.com>
// SPDX-License-Identifier: Elastic-2.0

package e2e

import (
	"os"
	"path/filepath"
	"testing"
)

func TestParseE2EExpectations(t *testing.T) {
	expectations, err := ParseExpectations(filepath.Join("..", "..", "expectations.yaml"))
	if err != nil {
		t.Fatal(err)
	}
	if len(expectations) == 0 {
		t.Fatal("expected at least one E2E expectation")
	}
	for _, reconciler := range []string{"terraform", "crossplane"} {
		for _, target := range []string{"vault", "openbao"} {
			selected := ExpectationsForRun(expectations, reconciler, target)
			if len(selected) == 0 {
				t.Fatalf("expected at least one expectation for %s/%s", target, reconciler)
			}
			for _, expectation := range selected {
				if expectation.Reconciler != "both" && expectation.Reconciler != reconciler {
					t.Fatalf("expectation %q selected for incompatible reconciler %s", expectation.Name, reconciler)
				}
				if expectation.Target != "both" && expectation.Target != target {
					t.Fatalf("expectation %q selected for incompatible target %s", expectation.Name, target)
				}
			}
		}
	}
}

func TestExpectationRunSelection(t *testing.T) {
	expectations := []Expectation{
		{Name: "shared", Reconciler: "both", Target: "both"},
		{Name: "terraform-only", Reconciler: "terraform", Target: "both"},
		{Name: "crossplane-only", Reconciler: "crossplane", Target: "both"},
		{Name: "vault-only", Reconciler: "both", Target: "vault"},
	}
	terraformVaultExpectations := ExpectationsForRun(expectations, "terraform", "vault")
	if len(terraformVaultExpectations) != 3 || terraformVaultExpectations[0].Name != "shared" || terraformVaultExpectations[1].Name != "terraform-only" || terraformVaultExpectations[2].Name != "vault-only" {
		t.Fatalf("unexpected Terraform/Vault expectations: %#v", terraformVaultExpectations)
	}
	crossplaneOpenBaoExpectations := ExpectationsForRun(expectations, "crossplane", "openbao")
	if len(crossplaneOpenBaoExpectations) != 2 || crossplaneOpenBaoExpectations[0].Name != "shared" || crossplaneOpenBaoExpectations[1].Name != "crossplane-only" {
		t.Fatalf("unexpected Crossplane/OpenBao expectations: %#v", crossplaneOpenBaoExpectations)
	}
}

func TestExpectationReconcilerDefaultsToBoth(t *testing.T) {
	path := filepath.Join(t.TempDir(), "expectations.yaml")
	contents := "expectations:\n  - name: shared\n    command: [read, -format=json, path]\n    assertions:\n      data.value: true\n"
	if err := os.WriteFile(path, []byte(contents), 0o600); err != nil {
		t.Fatal(err)
	}
	expectations, err := ParseExpectations(path)
	if err != nil {
		t.Fatal(err)
	}
	if expectations[0].Reconciler != "both" {
		t.Fatalf("expected default reconciler both, got %q", expectations[0].Reconciler)
	}
	if expectations[0].Target != "both" {
		t.Fatalf("expected default target both, got %q", expectations[0].Target)
	}
}

func TestExpectationRejectsDuplicateNames(t *testing.T) {
	path := filepath.Join(t.TempDir(), "expectations.yaml")
	contents := "expectations:\n  - name: duplicate\n    command: [read, path]\n    assertions: {data.value: true}\n  - name: duplicate\n    command: [read, other]\n    assertions: {data.value: true}\n"
	if err := os.WriteFile(path, []byte(contents), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := ParseExpectations(path); err == nil {
		t.Fatal("expected duplicate expectation names to fail parsing")
	}
}

func TestExpectationRejectsInvalidReconciler(t *testing.T) {
	path := filepath.Join(t.TempDir(), "expectations.yaml")
	contents := "expectations:\n  - name: invalid\n    reconciler: other\n    command: [read, -format=json, path]\n    assertions:\n      data.value: true\n"
	if err := os.WriteFile(path, []byte(contents), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := ParseExpectations(path); err == nil {
		t.Fatal("expected invalid reconciler to fail parsing")
	}
}

func TestExpectationRejectsInvalidTarget(t *testing.T) {
	path := filepath.Join(t.TempDir(), "expectations.yaml")
	contents := "expectations:\n  - name: invalid\n    target: other\n    command: [read, -format=json, path]\n    assertions:\n      data.value: true\n"
	if err := os.WriteFile(path, []byte(contents), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := ParseExpectations(path); err == nil {
		t.Fatal("expected invalid target to fail parsing")
	}
}

func TestAssertJSON(t *testing.T) {
	expectation := Expectation{
		Name: "fixture",
		Assertions: map[string]any{
			"data.enabled":  true,
			"data.ttl":      600,
			"data.policies": []any{"policy-b", "policy-a"},
		},
	}
	output := `{"data":{"enabled":true,"ttl":600,"policies":["policy-a","policy-b"]}}`
	if mismatches := AssertJSON(expectation, output); len(mismatches) != 0 {
		t.Fatalf("expected no mismatches, got %v", mismatches)
	}
}

func TestAssertJSONReportsAllMismatches(t *testing.T) {
	expectation := Expectation{
		Name: "fixture",
		Assertions: map[string]any{
			"data.enabled": false,
			"data.missing": "value",
		},
	}
	mismatches := AssertJSON(expectation, `{"data":{"enabled":true}}`)
	if len(mismatches) != 2 {
		t.Fatalf("expected two mismatches, got %d: %v", len(mismatches), mismatches)
	}
}
