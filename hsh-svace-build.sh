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
# 1. src.rpm file in $HOME/in/srpm
# 2. src.rpm build dependencies installed
# `hsh-rebuild --install-only` implies both of the above
# 3. /proc mounted
# 4. svace distribution in /opt/svace (using bind mount from the host)
# As a result, hsh-svace-results.tar archive with the svace-dir and
# metadata will be available in the /.our directory.

PROG=hsh-svace-build
TEMP=$(getopt -n $PROG -o "q" -l "target:,quiet" -- "$@") || exit 1
eval set -- "$TEMP"

verbose=-v
while :; do
    case "$1" in
        --) shift; break
            ;;
        --target) shift; target="$1"
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

cd "$HOME/in"
srpm="$(realpath srpm/*)"

target="${target:-$(uname -m)}"
export -n target ||:

SOURCE_DATE_EPOCH="$(cat -- "$HOME/in/SOURCE_DATE_EPOCH")"
export SOURCE_DATE_EPOCH

rpmi -i \
    --define "_specdir $HOME/in/specs" \
    --define "_sourcedir $HOME/in/sources" \
    "$srpm"

spec="$(realpath $HOME/in/specs/*)"
name="$(rpm -qp --qf %{NAME} $srpm)"
version="$(rpm -qp --qf %{VERSION} $srpm)"
release="$(rpm -qp --qf %{RELEASE} $srpm)"

rm -rf $HOME/RPM/BUILD
mkdir -p $HOME/RPM/BUILD

# empty python file for svace
touch $HOME/RPM/BUILD/svace.py

rm -rf $HOME/out
mkdir -p $HOME/out/svace-dir

# NOTE: we need to prep sources before `svace build`
# for python analysis
rpmbuild -bp \
     --define "_specdir $HOME/in/specs" \
     --define "_sourcedir $HOME/in/sources" \
     "$spec" --target="$target" >&2

/opt/svace/bin/svace init --bare $HOME/out/svace-dir 2>&1 | \
    tee $HOME/out/svace-init.log >&2

/opt/svace/bin/svace build -v \
     --svace-dir=$HOME/out/svace-dir \
     --go-interception-mode compile \
     --python $HOME/RPM/BUILD \
     rpmbuild -bc --short-circuit \
     --define "_specdir $HOME/in/specs" \
     --define "_sourcedir $HOME/in/sources" \
     "$spec" --target="$target" 2>&1 | \
    tee $HOME/out/svace-build.log >&2

find $HOME/RPM/BUILD -maxdepth 1 -mindepth 1 -type d \
     > $HOME/out/pathprefix.txt

sed -i -e "s|^\(/usr/src/RPM/BUILD\)\(.*\)\(-$version\)\$|\1\2\3:\2|" \
    $HOME/out/pathprefix.txt
echo "$HOME/in/sources:/sources" >> $HOME/out/pathprefix.txt

cat > $HOME/out/metadata <<EOF
project:$name
branch:$(rpm --eval %_priority_distbranch)
snapshot:$version-$release
svace-dir:svace-dir
spec:$(basename $spec)
path-prefix:pathprefix.txt
build-hash:$(grep -o '^[0-9a-f]\{40\}' $HOME/out/svace-dir/shared/builds)
EOF

cp "$spec" $HOME/out

rm -f /.out/hsh-svace-results.tar
tar -cf /.out/hsh-svace-results.tar \
    --owner=user --group=user \
    --transform 's/^.\/out/hsh-svace-results/' \
    -C "$HOME" ./out
