#!/usr/bin/env bats

load common.sh

@test "test fedora packages are in PATH" {
	check_path 7z bats cargo git hadolint helm kubectl lz4 make nmap stow vim zsh xz
}

@test "test tools are in PATH" {
	check_path doctl exo helm-docs kind kustomize k3d k3s packer shellcheck terraform terraform-docs terragrunt tflint
}

@test "test codium is in PATH" {
	check_path codium
}

@test "test flux is in PATH" {
	check_path flux
}

@test "test core tools report versions" {
	run git --version
	[ "$status" -eq 0 ]

	run terraform version
	[ "$status" -eq 0 ]

	run kubectl version --client
	[ "$status" -eq 0 ]

	run helm version --short
	[ "$status" -eq 0 ]
}

@test "test jq is in PATH" {
	check_path jq
}

@test "test librewolf is in PATH" {
	check_path librewolf
}

@test "test ngrok is in PATH" {
	check_path ngrok
}

@test "test starship is in PATH" {
	check_path starship
}
