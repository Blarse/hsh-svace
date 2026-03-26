#!/bin/bash -le

# Run svace analyze inside hasher chroot.
#
# Copyright (C) 2024  Egor Ignatov <egori@altlinux.org>
#
# SPDX-License-Identifier: GPL-3.0-or-later

# Expects:
# 1. /proc mounted
# 2. /opt/svace available
# 3. $HOME/out/svace-dir after hsh-svace-build.sh
# 4. Configured Sentinel server
# 5. Run hasher with share_network=1

PROG=hsh-svace-analyze
TEMP=$(getopt -n "$PROG" -o S:,q -l hasp-serveraddr:,quiet -- "$@") || exit 1
eval set -- "$TEMP"

verbose=-v
hasp_serveraddr=localhost
while :; do
	case "$1" in
		-S|--hasp-serveraddr) shift; hasp_serveraddr="$1"
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

# setup ISPRAS hasp license
ISP_VENDOR_IDS='101213 36343'

mkdir -p "$HOME/.hasplm"
for vendorid in $ISP_VENDOR_IDS; do
	cat > "$HOME/.hasplm/hasp_${vendorid}.ini" <<EOF
[REMOTE]
serveraddr = $hasp_serveraddr
broadcastsearch = 0
EOF
done

set -o pipefail
${verbose:+set -x}

/opt/svace/bin/svace warning all true --svace-dir "$HOME/out/svace-dir" 2>&1 |
	tee "$HOME/out/svace-warning.log" >&2
/opt/svace/bin/svace analyze -v \
	--svace-dir "$HOME/out/svace-dir" 2>&1 |
	tee "$HOME/out/svace-analyze.log" >&2

rm -f /.out/hsh-svace-results.tar
tar -cf /.out/hsh-svace-results.tar \
	--owner=user --group=user \
	--transform 's/^.\/out/hsh-svace-results/' \
	-C "$HOME" ./out
