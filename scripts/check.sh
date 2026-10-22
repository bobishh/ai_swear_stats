#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
command -v swiftlint >/dev/null || { echo 'Install SwiftLint: brew install swiftlint' >&2; exit 1; }
swift test -Xswiftc -warnings-as-errors
swift format lint --strict --recursive Sources Tests Package.swift
swiftlint lint --strict --quiet
sh -n run-app.sh
openspec validate --all --strict --no-interactive
