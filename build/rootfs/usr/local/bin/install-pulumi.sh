#!/usr/bin/env bash

set -e

PULUMI_VERSION="3.95.0"

temp="$(mktemp -d)"

curl -sSL -o "${temp}/pulumi.tar.gz" "https://github.com/pulumi/pulumi/releases/download/v${PULUMI_VERSION}/pulumi-v${PULUMI_VERSION}-linux-x64.tar.gz"
tar xzvf "${temp}/pulumi.tar.gz" -C /usr/local/bin --strip-components=1
chmod +x /usr/local/bin/pulumi*
rm -rvf "$temp"
