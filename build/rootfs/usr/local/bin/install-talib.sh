#!/usr/bin/env bash

set -e

TALIB_VERSION="${TALIB_VERSION:-"0.6.4"}"

temp="$(mktemp -d)"

curl -sSL -o "${temp}/ta-lib.tar.gz" "https://github.com/ta-lib/ta-lib/releases/download/v${TALIB_VERSION}/ta-lib-${TA_LIB_VERSION}-src.tar.gz"

tar xzvf "${temp}/ta-lib.tar.gz" -C "$temp"

(
	cd "${temp}/ta-lib-${TALIB_VERSION}" || return
	./configure --prefix=/usr
	sudo make install
)

rm -rvf "$temp"
