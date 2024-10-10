#!/bin/sh -le

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
# 2. svace distribution in /opt/svace (using bind mount from the host)
# 3. /usr/src/out/svace-dir after hsh-svace-build.sh
# 4. Configured bind mount for /var/hasplm:
#   - Add following line to /etc/hasher-priv/fstab:
#     /var/hasplm /var/hasplm bind bind,ro,nosuid,nodev,noexec 0 0
#   - Add /var/hasplm to hasher-priv allowed_mountpoints
# 5. Run hasher with share_network=1
# As a result, svace-results directory with the svace-dir and metadata will
# be available in the /.our directory.

PROG=hsh-svace-analyze
TEMP=$(getopt -n $PROG -o "q" -l "quiet" -- "$@") || exit 1
eval set -- "$TEMP"

verbose=-v
while :; do
    case "$1" in
        --) shift; break
            ;;
        -q|--quiet) verbose=
                      ;;
        *) echo "Unrecognized option: $1" >&2
           exit 1
           ;;
    esac
    shift
done

${verbose:+set -x}

/opt/svace/bin/svace warning all true --svace-dir $HOME/out/svace-dir 2>&1 | \
    tee $HOME/out/svace-warning.log >&2
/opt/svace/bin/svace analyze -v \
                     --svace-dir $HOME/out/svace-dir 2>&1 | \
    tee $HOME/out/svace-analyze.log >&2

rm -f /.out/svace-results.tar
tar -cf /.out/svace-results.tar \
    --owner=user --group=user \
    --transform 's/^.\/out/svace-results/' \
    -C "$HOME" ./out
