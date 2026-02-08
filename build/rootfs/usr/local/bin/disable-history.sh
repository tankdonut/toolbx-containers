#!/usr/bin/env bash

mkdir -p ~/.bashrc.d

touch ~/.bashrc.d/disable_history

cat >~/.bashrc.d/disable_history <<EOF
unset HISTFILE
export LESSHISTFILE=/dev/null
EOF
