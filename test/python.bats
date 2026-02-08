#!/usr/bin/env bats

load common.sh

function check_python_package() {
	python -c "import $1"
}

@test "test conda is in PATH" {
	check_path conda
}

@test "test pip is in PATH" {
	check_path pip
}

@test "test python is in PATH" {
	check_path python
}

@test "test poetry is in PATH" {
	check_path poetry
}

@test "test ruff is in PATH" {
	check_path ruff
}

@test "test uv is in PATH" {
        check_path uv
}

@test "test invoke python package is installed" {
	check_path invoke
	check_python_package invoke
}

@test "test dotenv python package is installed" {
	check_python_package dotenv
}

@test "test pre-commit is in PATH" {
	check_path pre-commit
}
