#!/bin/bash -le

# Run svace analyze inside hasher chroot.
#
# Copyright (C) 2024-2026  Egor Ignatov <egori@altlinux.org>
#
# SPDX-License-Identifier: GPL-3.0-or-later

# Expects:
# 1. /proc mounted
# 2. /opt/svace available
# 3. $HOME/out/svace-dir after hsh-svace-build.sh
# 4. Configured Sentinel server
# 5. Run hasher with share_network=1

PROG=hsh-svace-analyze
TEMP=$(getopt -n "$PROG" -o S:,q,v -l hasp-serveraddr:,quiet,verbose -- "$@") || exit 1
eval set -- "$TEMP"

verbose=
hasp_serveraddr=localhost
while :; do
	case "$1" in
		-S|--hasp-serveraddr) shift; hasp_serveraddr="$1"
			;;
		-v|--verbose) verbose=-v
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

if [ -n "$verbose" ]; then
	exec 3>&2
else
	exec 3>/dev/null
fi

set -o pipefail
${verbose:+set -x}

/opt/svace/bin/svace warning all true --svace-dir "$HOME/out/svace-dir" 2>&1 |
	tee "$HOME/out/svace-warning.log" >&3
/opt/svace/bin/svace analyze -v \
	--svace-dir "$HOME/out/svace-dir" 2>&1 |
	tee "$HOME/out/svace-analyze.log" >&3

rm -f /.out/hsh-svace-results-analyzed.tar
tar -cf /.out/hsh-svace-results-analyzed.tar \
	--owner=user --group=user \
	--transform 's/^.\/out/hsh-svace-results/' \
	-C "$HOME" ./out
