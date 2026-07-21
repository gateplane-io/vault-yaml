#!/bin/sh
# Copyright (C) 2026 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0

set -eu



script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

exec go -C "$script_dir" test -tags=e2e -v -count=1 -timeout "${E2E_TIMEOUT:-30m}" .
