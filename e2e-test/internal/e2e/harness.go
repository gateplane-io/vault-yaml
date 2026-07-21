// Copyright (C) 2026 Ioannis Torakis <john.torakis@gmail.com>
// SPDX-License-Identifier: Elastic-2.0

package e2e

import (
	"context"
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
	cluster := fmt.Sprintf("vault-yaml-e2e-%s-%d", target.Name, time.Now().UnixNano())
	return &Harness{t: t, config: config, target: target, cluster: cluster}
}

func (h *Harness) Address() string { return h.address }

func (h *Harness) TempDir() string { return h.tempDir }

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
	for _, check := range checks {
		if _, err := h.run(check.name, check.args...); err != nil {
			return fmt.Errorf("required command %q is unavailable: %w", check.name, err)
		}
	}

	kindConfig := filepath.Join("kubernetes", "kind.yaml")
	if _, err := h.runWithEnv([]string{"KIND_EXPERIMENTAL_PROVIDER=" + h.config.ContainerCLI}, "kind", "create", "cluster", "--name", h.cluster, "--config", kindConfig, "--wait", "120s"); err != nil {
		return err
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
func (h *Harness) runWithEnv(extraEnv []string, name string, args ...string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
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
