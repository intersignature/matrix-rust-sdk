#!/usr/bin/env bash
# Finnomena fork: build MatrixSDKFFI.xcframework for device + simulator with
# the nter deployment target (iOS 14.0), generate the Swift bindings into
# bindings/apple/generated/ and refresh the root Package.swift used by nter's
# SPM `path:` dependency.
#
# Usage: bindings/apple/finno-build-xcframework.sh [extra cargo xtask args]
set -euo pipefail

cd "$(dirname "$0")/../.."

# Xcode exports SDKROOT to the macOS SDK inside build phases; it breaks the
# iOS cross-compilation done by xtask.
unset SDKROOT

cargo xtask swift build-framework \
  --release \
  --target aarch64-apple-ios \
  --target aarch64-apple-ios-sim \
  --ios-deployment-target 14.0 \
  "$@"

echo
echo "minos per slice:"
for lib in bindings/apple/generated/MatrixSDKFFI.xcframework/*/libmatrix_sdk_ffi.a; do
  printf '  %s: ' "$(basename "$(dirname "$lib")")"
  otool -l "$lib" | awk '/minos/ {print $2}' | sort -u | tr '\n' ' '
  echo
done
