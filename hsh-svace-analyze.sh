#!/bin/bash -le

# This file is part of hsh-svace.
#
# Copyright (C) 2024  Egor Ignatov <egori@altlinux.org>
#
# hsh-svace is free software: you can redistribute it and/or modify it
# under the  terms of the GNU  General Public License as  published by
# the Free  Software Foundation, either  version 3 of the  License, or
# (at your option) any later version.
#
# hsh-svace is  distributed in the  hope that  it will be  useful, but
# WITHOUT  ANY   WARRANTY;  without  even  the   implied  warranty  of
# MERCHANTABILITY or  FITNESS FOR  A PARTICULAR  PURPOSE. See  the GNU
# General Public License for more details.
#
# You should  have received a copy  of the GNU General  Public License
# along with hsh-svace. If not, see <https://www.gnu.org/licenses/>.


# This script runs inside hasher. It requires:
# 1. /proc mounted
# 2. SVACE distribution in /opt/svace (using bind mount from the host)
# 3. /usr/src/out/svace-dir after hsh-svace-build.sh
# 4. Configured Sentinel server (pass address by -S or --hasp-serveraddr option)
# 5. Run hasher with share_network=1
# As a result, hsh-svace-results.tar archive with the svace-dir and
# metadata will be available in the /.our directory.

PROG=hsh-svace-analyze
TEMP=$(getopt -n $PROG -o "S:,q" -l "hasp-serveraddr:,quiet" -- "$@") || exit 1
eval set -- "$TEMP"

verbose=-v
hasp_serveraddr=localhost
while :; do
    case "$1" in
        --) shift; break
            ;;
        -q|--quiet) verbose=
                      ;;
        -S|--hasp-serveraddr) shift; hasp_serveraddr="$1"
                      ;;
        *) echo "Unrecognized option: $1" >&2
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

/opt/svace/bin/svace warning all true --svace-dir $HOME/out/svace-dir 2>&1 | \
    tee $HOME/out/svace-warning.log >&2
/opt/svace/bin/svace analyze -v \
                     --svace-dir $HOME/out/svace-dir 2>&1 | \
    tee $HOME/out/svace-analyze.log >&2

rm -f /.out/hsh-svace-results.tar
tar -cf /.out/hsh-svace-results.tar \
    --owner=user --group=user \
    --transform 's/^.\/out/hsh-svace-results/' \
    -C "$HOME" ./out
