// Copyright (C) 2026 Ioannis Torakis <john.torakis@gmail.com>
// SPDX-License-Identifier: Elastic-2.0

package e2e

import (
	"context"
	"encoding/json"
	"fmt"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"text/template"
	"time"
)

// Harness owns one disposable kind cluster and server process set.
type Harness struct {
	t        *testing.T
	config   Config
	target   Target
	cluster  string
	tempDir  string
	address  string
	portCmd  *exec.Cmd
	portDone chan error
	created  bool
}

func NewHarness(t *testing.T, config Config, target Target) *Harness {
	cluster := fmt.Sprintf("vault-yaml-e2e-%s-%s-%d", target.Name, config.Reconciler, time.Now().Unix())
	return &Harness{t: t, config: config, target: target, cluster: cluster}
}

func (h *Harness) Address() string { return h.address }

func (h *Harness) TempDir() string { return h.tempDir }

func (h *Harness) Context() string { return "kind-" + h.cluster }

func (h *Harness) InClusterAddress() string {
	return fmt.Sprintf("http://%s.default.svc:8200", h.target.PodName)
}

func (h *Harness) Start() error {
	tempDir, err := os.MkdirTemp("", h.cluster+"-")
	if err != nil {
		return err
	}
	h.tempDir = tempDir

	checks := []struct {
		name string
		args []string
	}{
		{name: h.config.ContainerCLI, args: []string{"version"}},
		{name: "kind", args: []string{"version"}},
		{name: "kubectl", args: []string{"version", "--client"}},
		{name: "terraform", args: []string{"version"}},
	}
	if h.config.Reconciler == "crossplane" {
		checks = append(checks, struct {
			name string
			args []string
		}{name: "helm", args: []string{"version"}})
	}
	for _, check := range checks {
		if _, err := h.run(check.name, check.args...); err != nil {
			return fmt.Errorf("required command %q is unavailable: %w", check.name, err)
		}
	}

	kindConfig := filepath.Join("kubernetes", "kind.yaml")
	if output, err := h.runWithEnv([]string{"KIND_EXPERIMENTAL_PROVIDER=" + h.config.ContainerCLI}, "kind", "create", "cluster", "--name", h.cluster, "--config", kindConfig, "--wait", "120s"); err != nil {
		return fmt.Errorf("create kind cluster: %w: %s", err, strings.TrimSpace(output))
	}
	h.created = true

	manifest, err := h.renderManifest()
	if err != nil {
		return err
	}
	manifestPath := filepath.Join(tempDir, "server.yaml")
	if err := os.WriteFile(manifestPath, manifest, 0o600); err != nil {
		return err
	}
	if _, err := h.run("kubectl", "apply", "--context", "kind-"+h.cluster, "-f", manifestPath); err != nil {
		return err
	}
	if _, err := h.run("kubectl", "wait", "--context", "kind-"+h.cluster, "--for=condition=Ready", "pod/"+h.target.PodName, "--timeout=180s"); err != nil {
		return err
	}
	if err := h.waitForServer(); err != nil {
		return err
	}
	return h.startPortForward()
}

func (h *Harness) renderManifest() ([]byte, error) {
	data := struct {
		Target
		RootToken, TokenVariable, CLITokenVariable, AddressVariable string
	}{Target: h.target, RootToken: h.config.RootToken}
	if h.target.Name == "openbao" {
		data.TokenVariable, data.CLITokenVariable, data.AddressVariable = "BAO_DEV_ROOT_TOKEN_ID", "BAO_TOKEN", "BAO_ADDR"
	} else {
		data.TokenVariable, data.CLITokenVariable, data.AddressVariable = "VAULT_DEV_ROOT_TOKEN_ID", "VAULT_TOKEN", "VAULT_ADDR"
	}
	manifestTemplate, err := os.ReadFile(filepath.Join("kubernetes", "server.yaml.tmpl"))
	if err != nil {
		return nil, fmt.Errorf("read server manifest template: %w", err)
	}
	var output strings.Builder
	parsed, err := template.New("server").Parse(string(manifestTemplate))
	if err != nil {
		return nil, fmt.Errorf("parse server manifest template: %w", err)
	}
	if err := parsed.Execute(&output, data); err != nil {
		return nil, err
	}
	return []byte(output.String()), nil
}

func (h *Harness) waitForServer() error {
	deadline := time.Now().Add(60 * time.Second)
	for time.Now().Before(deadline) {
		args := []string{"exec", "--context", "kind-" + h.cluster, h.target.PodName, "--", h.target.CLI, "status", "-format=json"}
		if _, err := h.run("kubectl", args...); err == nil {
			return nil
		}
		time.Sleep(time.Second)
	}
	return fmt.Errorf("timed out waiting for %s API", h.target.Name)
}

func (h *Harness) startPortForward() error {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return err
	}
	port := listener.Addr().(*net.TCPAddr).Port
	_ = listener.Close()
	h.address = fmt.Sprintf("http://127.0.0.1:%d", port)
	h.portCmd = exec.Command("kubectl", "port-forward", "--context", "kind-"+h.cluster, "pod/"+h.target.PodName, fmt.Sprintf("%d:8200", port))
	h.portCmd.Stdout, h.portCmd.Stderr = os.Stdout, os.Stderr
	if err := h.portCmd.Start(); err != nil {
		return err
	}
	h.portDone = make(chan error, 1)
	go func() { h.portDone <- h.portCmd.Wait() }()
	deadline := time.Now().Add(30 * time.Second)
	for time.Now().Before(deadline) {
		connection, dialErr := net.DialTimeout("tcp", fmt.Sprintf("127.0.0.1:%d", port), 250*time.Millisecond)
		if dialErr == nil {
			_ = connection.Close()
			return nil
		}
		select {
		case err := <-h.portDone:
			return fmt.Errorf("port-forward exited: %w", err)
		default:
		}
		time.Sleep(200 * time.Millisecond)
	}
	return fmt.Errorf("timed out waiting for port-forward")
}

// InstallCrossplane installs Crossplane, provider-vault, its credentials, and the
// Vault-YAML chart. It waits for both package health and asynchronous managed
// resource reconciliation.
func (h *Harness) InstallCrossplane(accessFile, valuesFile, chartDir string) error {
	contextName := h.Context()
	commands := []struct {
		name string
		args []string
	}{
		{name: "helm", args: []string{"repo", "add", "crossplane-stable", "https://charts.crossplane.io/stable"}},
		{name: "helm", args: []string{"repo", "update", "crossplane-stable"}},
		{name: "helm", args: []string{"upgrade", "--install", "crossplane", "crossplane-stable/crossplane", "--kube-context", contextName, "--namespace", "crossplane-system", "--create-namespace", "--version", h.config.CrossplaneVersion, "--wait", "--timeout", h.config.CrossplaneTimeout.String()}},
		{name: "kubectl", args: []string{"create", "secret", "generic", "vault-provider-creds", "--context", contextName, "--namespace", "crossplane-system", "--from-literal=credentials={\"token\":\"" + h.config.RootToken + "\"}"}},
		{name: "kubectl", args: []string{"apply", "--context", contextName, "-f", "-"}},
	}
	providerManifest := fmt.Sprintf("apiVersion: pkg.crossplane.io/v1\nkind: Provider\nmetadata:\n  name: upbound-provider-vault\nspec:\n  package: %s\n", h.config.ProviderVaultPackage)
	for i, command := range commands {
		var output string
		var err error
		if i == len(commands)-1 {
			output, err = h.runInput(providerManifest, command.name, command.args...)
		} else {
			output, err = h.run(command.name, command.args...)
		}
		if err != nil {
			return fmt.Errorf("Crossplane bootstrap failed: %w: %s", err, strings.TrimSpace(output))
		}
	}
	if output, err := h.run("kubectl", "wait", "--context", contextName, "--for=condition=Healthy", "provider.pkg.crossplane.io/upbound-provider-vault", "--timeout="+h.config.CrossplaneTimeout.String()); err != nil {
		return fmt.Errorf("provider-vault did not become healthy: %w: %s\n%s", err, output, h.crossplaneDiagnostics())
	}
	if output, err := h.run("helm", "upgrade", "--install", "vault-yaml", chartDir, "--kube-context", contextName, "--namespace", "vault-system", "--create-namespace", "--values", valuesFile, "--set-file", "accessFile="+accessFile, "--set-string", "_vaultYaml.provider.config.address="+h.InClusterAddress()); err != nil {
		return fmt.Errorf("install Vault-YAML chart: %w: %s", err, output)
	}
	return h.waitForManagedResources(h.config.CrossplaneTimeout)
}

func (h *Harness) waitForManagedResources(timeout time.Duration) error {
	deadline := time.Now().Add(timeout)
	var last []string
	for time.Now().Before(deadline) {
		output, err := h.run("kubectl", "get", "managed", "--context", h.Context(), "--all-namespaces", "--selector", "app.kubernetes.io/instance=vault-yaml", "-o", "json")
		if err == nil {
			var list struct {
				Items []struct {
					Kind     string `json:"kind"`
					Metadata struct {
						Name string `json:"name"`
					} `json:"metadata"`
					Status struct {
						Conditions []struct{ Type, Status, Reason, Message string } `json:"conditions"`
					} `json:"status"`
				} `json:"items"`
			}
			if json.Unmarshal([]byte(output), &list) == nil && len(list.Items) > 0 {
				last = nil
				for _, item := range list.Items {
					ready, synced := false, false
					for _, condition := range item.Status.Conditions {
						if condition.Type == "Ready" && condition.Status == "True" {
							ready = true
						}
						if condition.Type == "Synced" && condition.Status == "True" {
							synced = true
						}
					}
					if !ready || !synced {
						conditions := make([]string, 0, len(item.Status.Conditions))
						for _, condition := range item.Status.Conditions {
							conditions = append(conditions, fmt.Sprintf("%s=%s reason=%s message=%q", condition.Type, condition.Status, condition.Reason, condition.Message))
						}
						last = append(last, fmt.Sprintf("%s/%s Ready=%t Synced=%t conditions=[%s]", item.Kind, item.Metadata.Name, ready, synced, strings.Join(conditions, ", ")))
					}
				}
				if len(last) == 0 {
					return nil
				}
			}
		}
		time.Sleep(5 * time.Second)
	}
	if len(last) == 0 {
		last = []string{"no managed resources with label app.kubernetes.io/instance=vault-yaml were found"}
	}
	return fmt.Errorf("timed out waiting for managed resources: %s\n%s", strings.Join(last, "; "), h.crossplaneDiagnostics())
}

func (h *Harness) crossplaneDiagnostics() string {
	commands := [][]string{
		{"get", "providers.pkg.crossplane.io", "--context", h.Context(), "-o", "wide"},
		{"get", "pods", "--context", h.Context(), "--all-namespaces", "-o", "wide"},
		{"get", "managed", "--context", h.Context(), "--all-namespaces", "--selector", "app.kubernetes.io/instance=vault-yaml", "-o", "wide"},
		{"get", "events", "--context", h.Context(), "--all-namespaces", "--sort-by=.lastTimestamp"},
	}
	var diagnostics strings.Builder
	diagnostics.WriteString("Crossplane diagnostics:\n")
	for _, args := range commands {
		output, err := h.run("kubectl", args...)
		diagnostics.WriteString("$ kubectl " + strings.Join(args, " ") + "\n")
		diagnostics.WriteString(strings.TrimSpace(output) + "\n")
		if err != nil {
			diagnostics.WriteString("error: " + err.Error() + "\n")
		}
	}
	return diagnostics.String()
}

func (h *Harness) CleanupCrossplane() {
	if output, err := h.run("helm", "uninstall", "vault-yaml", "--kube-context", h.Context(), "--namespace", "vault-system", "--wait", "--timeout", "5m"); err != nil {
		h.t.Errorf("uninstall Vault-YAML chart: %v: %s", err, output)
	}
}

func (h *Harness) AssertAll(expectations []Expectation) []string {
	var mismatches []string
	for _, expectation := range expectations {
		args := []string{"exec", "--context", "kind-" + h.cluster, h.target.PodName, "--", h.target.CLI}
		args = append(args, expectation.Command...)
		output, err := h.run("kubectl", args...)
		if err != nil {
			mismatches = append(mismatches, fmt.Sprintf("%s: %v: %s", expectation.Name, err, strings.TrimSpace(output)))
			continue
		}
		mismatches = append(mismatches, AssertJSON(expectation, output)...)
	}
	return mismatches
}

func (h *Harness) Cleanup() {
	if h.portCmd != nil && h.portCmd.Process != nil {
		_ = h.portCmd.Process.Kill()
	}
	if h.created {
		if output, err := h.runWithEnv([]string{"KIND_EXPERIMENTAL_PROVIDER=" + h.config.ContainerCLI}, "kind", "delete", "cluster", "--name", h.cluster); err != nil {
			h.t.Errorf("delete kind cluster: %v: %s", err, output)
		}
	}
	if h.tempDir != "" {
		_ = os.RemoveAll(h.tempDir)
	}
}

func (h *Harness) run(name string, args ...string) (string, error) {
	return h.runWithEnv(nil, name, args...)
}

func (h *Harness) runInput(input, name string, args ...string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), h.config.CommandTimeout)
	defer cancel()
	command := exec.CommandContext(ctx, name, args...)
	command.Env = os.Environ()
	command.Stdin = strings.NewReader(input)
	output, err := command.CombinedOutput()
	if ctx.Err() != nil {
		return string(output), fmt.Errorf("%s timed out: %w", name, ctx.Err())
	}
	if err != nil {
		return string(output), fmt.Errorf("%s %s: %w", name, strings.Join(args, " "), err)
	}
	return string(output), nil
}
func (h *Harness) runWithEnv(extraEnv []string, name string, args ...string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), h.config.CommandTimeout)
	defer cancel()
	command := exec.CommandContext(ctx, name, args...)
	command.Env = append(os.Environ(), extraEnv...)
	output, err := command.CombinedOutput()
	if ctx.Err() != nil {
		return string(output), fmt.Errorf("%s timed out: %w", name, ctx.Err())
	}
	if err != nil {
		return string(output), fmt.Errorf("%s %s: %w", name, strings.Join(args, " "), err)
	}
	return string(output), nil
}
