#!/bin/sh -efux

cd "$(dirname $(readlink -e $0))"

./get-svace.sh

[ -d linux-pam ] || git clone git://git.altlinux.org/gears/l/linux-pam.git

GIT_DIR="$PWD/linux-pam/.git" \
GIT_WORKTREE_DIR="$PWD/linux-pam" \
gear --zstd --hasher -- ./hsh-svace
