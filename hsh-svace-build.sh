#!/bin/bash -le

# Run svace build inside hasher chroot.
#
# Copyright (C) 2024  Egor Ignatov <egori@altlinux.org>
#
# SPDX-License-Identifier: GPL-3.0-or-later

# Expects:
# 1. src.rpm in $HOME/in/srpm, build deps installed
# 2. /proc mounted
# 3. /opt/svace available

PROG=hsh-svace-build
TEMP=$(getopt -n "$PROG" -o q -l target:,quiet -- "$@") || exit 1
eval set -- "$TEMP"

verbose=-v
target=
while :; do
	case "$1" in
		--target) shift; target="$1"
			;;
		-q|--quiet) verbose=
			;;
		--) shift; break
			;;
		*) echo "$PROG: unrecognized option: $1" >&2
		   exit 1
			;;
	esac
	shift
done

set -o pipefail
${verbose:+set -x}

target="${target:-$(uname -m)}"
export -n target ||:

SOURCE_DATE_EPOCH="$(cat -- "$HOME/in/SOURCE_DATE_EPOCH")"
export SOURCE_DATE_EPOCH

cd "$HOME/in"
srpm="$HOME/in/srpm"/*

rpmi -i \
	--define "_specdir $HOME/in/specs" \
	--define "_sourcedir $HOME/in/sources" \
	"$srpm"

spec="$HOME/in/specs"/*
name="$(rpmquery -p --qf '%{NAME}' "$srpm")"
version="$(rpmquery -p --qf '%{VERSION}' "$srpm")"
release="$(rpmquery -p --qf '%{RELEASE}' "$srpm")"

rm -rf "$HOME/RPM/BUILD"
mkdir -p "$HOME/RPM/BUILD"

# empty python file for svace
touch "$HOME/RPM/BUILD/svace.py"

rm -rf "$HOME/out"
mkdir -p "$HOME/out/svace-dir"

# prep sources before svace build for python analysis
rpmbuild -bp \
	--define "_specdir $HOME/in/specs" \
	--define "_sourcedir $HOME/in/sources" \
	"$spec" --target="$target" >&2

/opt/svace/bin/svace init --bare "$HOME/out/svace-dir" 2>&1 |
	tee "$HOME/out/svace-init.log" >&2

/opt/svace/bin/svace build -v \
	--svace-dir="$HOME/out/svace-dir" \
	--go-interception-mode compile \
	--python "$HOME/RPM/BUILD" \
	rpmbuild -bc --short-circuit \
	--define "_specdir $HOME/in/specs" \
	--define "_sourcedir $HOME/in/sources" \
	"$spec" --target="$target" 2>&1 |
	tee "$HOME/out/svace-build.log" >&2

find "$HOME/RPM/BUILD" -maxdepth 1 -mindepth 1 -type d \
	> "$HOME/out/pathprefix.txt"

# set pathprefix to root
sed -i -e 's|$|:|' "$HOME/out/pathprefix.txt"

echo "$HOME/in/sources:/sources" >> "$HOME/out/pathprefix.txt"

cat > "$HOME/out/metadata" <<EOF
project:$name
branch:$(rpm --eval '%_priority_distbranch')
snapshot:$version-$release
svace-dir:svace-dir
spec:$(basename "$spec")
path-prefix:pathprefix.txt
build-hash:$(grep -o '^[0-9a-f]\{40\}' "$HOME/out/svace-dir/shared/builds")
EOF

cp "$spec" "$HOME/out"

rm -f /.out/hsh-svace-results.tar
tar -cf /.out/hsh-svace-results.tar \
	--owner=user --group=user \
	--transform 's/^.\/out/hsh-svace-results/' \
	-C "$HOME" ./out
