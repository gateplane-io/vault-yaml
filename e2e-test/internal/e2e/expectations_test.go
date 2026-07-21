// Copyright (C) 2026 Ioannis Torakis <john.torakis@gmail.com>
// SPDX-License-Identifier: Elastic-2.0

package e2e

import (
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
