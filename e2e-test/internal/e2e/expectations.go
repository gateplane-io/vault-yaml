// Copyright (C) 2026 Ioannis Torakis <john.torakis@gmail.com>
// SPDX-License-Identifier: Elastic-2.0

package e2e

import (
	"encoding/json"
	"fmt"
	"os"
	"reflect"
	"sort"
	"strconv"
	"strings"

	"gopkg.in/yaml.v3"
)

// Expectation describes one product CLI JSON request and its expected fields.
type Expectation struct {
	Name       string         `yaml:"name"`
	Reconciler string         `yaml:"reconciler,omitempty"`
	Command    []string       `yaml:"command"`
	Assertions map[string]any `yaml:"assertions"`
}

type expectationDocument struct {
	Expectations []Expectation `yaml:"expectations"`
}

// ParseExpectations reads and validates the independent E2E assertion document.
func ParseExpectations(path string) ([]Expectation, error) {
	contents, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read expectations file: %w", err)
	}
	var document expectationDocument
	if err := yaml.Unmarshal(contents, &document); err != nil {
		return nil, fmt.Errorf("parse expectations file: %w", err)
	}
	if len(document.Expectations) == 0 {
		return nil, fmt.Errorf("expectations file contains no expectations")
	}
	names := make(map[string]struct{}, len(document.Expectations))
	for index := range document.Expectations {
		expectation := &document.Expectations[index]
		if expectation.Name == "" || len(expectation.Command) == 0 || len(expectation.Assertions) == 0 {
			return nil, fmt.Errorf("expectation %d must define name, command, and assertions", index)
		}
		if _, duplicate := names[expectation.Name]; duplicate {
			return nil, fmt.Errorf("duplicate expectation name %q", expectation.Name)
		}
		names[expectation.Name] = struct{}{}
		if expectation.Reconciler == "" {
			expectation.Reconciler = "both"
		}
		if expectation.Reconciler != "both" && expectation.Reconciler != "terraform" && expectation.Reconciler != "crossplane" {
			return nil, fmt.Errorf("expectation %q reconciler must be both, terraform, or crossplane; got %q", expectation.Name, expectation.Reconciler)
		}
	}
	sort.Slice(document.Expectations, func(i, j int) bool {
		return document.Expectations[i].Name < document.Expectations[j].Name
	})
	return document.Expectations, nil
}

// ExpectationsForReconciler returns expectations shared by both reconcilers or
// explicitly assigned to the selected reconciler.
func ExpectationsForReconciler(expectations []Expectation, reconciler string) []Expectation {
	selected := make([]Expectation, 0, len(expectations))
	for _, expectation := range expectations {
		if expectation.Reconciler == "both" || expectation.Reconciler == reconciler {
			selected = append(selected, expectation)
		}
	}
	return selected
}

// AssertJSON checks all fields declared by one expectation and returns every
// mismatch so a test run reports the complete drift set.
func AssertJSON(expectation Expectation, output string) []string {
	var document any
	if err := json.Unmarshal([]byte(output), &document); err != nil {
		return []string{fmt.Sprintf("%s: CLI output is not JSON: %v; output=%q", expectation.Name, err, strings.TrimSpace(output))}
	}

	paths := make([]string, 0, len(expectation.Assertions))
	for path := range expectation.Assertions {
		paths = append(paths, path)
	}
	sort.Strings(paths)

	var mismatches []string
	for _, path := range paths {
		actual, found := lookupJSONPath(document, path)
		if !found {
			mismatches = append(mismatches, fmt.Sprintf("%s: field %q was not found", expectation.Name, path))
			continue
		}
		expected := expectation.Assertions[path]
		if !equivalent(expected, actual) {
			mismatches = append(mismatches, fmt.Sprintf("%s: field %q mismatch: expected=%#v actual=%#v", expectation.Name, path, expected, actual))
		}
	}
	return mismatches
}

func lookupJSONPath(document any, path string) (any, bool) {
	current := document
	for _, segment := range strings.Split(path, ".") {
		switch value := current.(type) {
		case map[string]any:
			current, _ = value[segment]
			if current == nil {
				_, exists := value[segment]
				return current, exists
			}
		case []any:
			index, err := strconv.Atoi(segment)
			if err != nil || index < 0 || index >= len(value) {
				return nil, false
			}
			current = value[index]
		default:
			return nil, false
		}
	}
	return current, true
}

func equivalent(expected, actual any) bool {
	if expectedNumber, ok := number(expected); ok {
		actualNumber, actualOK := number(actual)
		return actualOK && expectedNumber == actualNumber
	}

	expectedSlice, expectedIsSlice := toSlice(expected)
	actualSlice, actualIsSlice := toSlice(actual)
	if expectedIsSlice || actualIsSlice {
		if !expectedIsSlice || !actualIsSlice || len(expectedSlice) != len(actualSlice) {
			return false
		}
		expectedValues := make([]string, len(expectedSlice))
		actualValues := make([]string, len(actualSlice))
		for index := range expectedSlice {
			expectedValues[index] = fmt.Sprint(expectedSlice[index])
			actualValues[index] = fmt.Sprint(actualSlice[index])
		}
		sort.Strings(expectedValues)
		sort.Strings(actualValues)
		return reflect.DeepEqual(expectedValues, actualValues)
	}
	return reflect.DeepEqual(expected, actual)
}

func number(value any) (float64, bool) {
	switch typed := value.(type) {
	case int:
		return float64(typed), true
	case int64:
		return float64(typed), true
	case uint64:
		return float64(typed), true
	case float64:
		return typed, true
	default:
		return 0, false
	}
}

func toSlice(value any) ([]any, bool) {
	reflected := reflect.ValueOf(value)
	if !reflected.IsValid() || (reflected.Kind() != reflect.Slice && reflected.Kind() != reflect.Array) {
		return nil, false
	}
	result := make([]any, reflected.Len())
	for index := range result {
		result[index] = reflected.Index(index).Interface()
	}
	return result, true
}
