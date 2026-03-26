# hsh-svace

Run SVACE static analysis on source packages in hasher.

https://www.ispras.ru/en/technologies/svace

## Prerequisites

- Configured hasher (https://www.altlinux.org/Hasher)
- SVACE license server (required for analysis stage)

## Usage

`hsh-svace` can be run directly on a source package (`.src.rpm`) or via gear
from a git repository:

    hsh-svace [options] [<path-to-workdir>] <source-package>
    gear [gear_options] --hasher -- hsh-svace [options]

Run `hsh-svace --help` to see all options.

### Build and analyze (default)

Runs `svace build` followed by `svace analyze`. Requires a SVACE license
server address (`-S` or `hasp_serveraddr` env variable):

    hsh-svace -S 192.168.1.100 --workdir=~/hasher package-1.0-alt1.src.rpm

    gear -v --commit --hasher -- hsh-svace -S 192.168.1.100 --workdir=~/hasher

### Build only

Run only `svace build`, skip analysis. Does not require a license server:

    hsh-svace --build-only --workdir=~/hasher package-1.0-alt1.src.rpm

    gear -v --commit --hasher -- hsh-svace --build-only --workdir=~/hasher

### Analyze only

Run `svace analyze` on a previously built results tar (from a `--build-only`
run). Useful for re-analyzing without rebuilding:

    hsh-svace --analyze-only -S 192.168.1.100 \
        --workdir=~/hasher hsh-svace-results.tar

    gear -v --commit --hasher -- hsh-svace --analyze-only -S 192.168.1.100 \
        --workdir=~/hasher hsh-svace-results.tar

## Svace installation

`hsh-svace` needs SVACE available inside the hasher chroot. There are two
methods:

### --install-svace (default)

Installs the `rpm-build-svace` package into the chroot. This is the default
method and requires no extra hasher configuration. Optionally specify a
version:

    hsh-svace --install-svace=3.5.1 ...

### --bind-svace

Mounts the host's `/opt` directory inside the hasher chroot via bind mount,
using SVACE installed on the host. This requires extra hasher-priv
configuration:

1. Append `/etc/hasher-priv/fstab` with:

       /opt /opt bind bind,ro,nosuid,nodev 0 0

2. Add `/opt` mount point to `allowed_mountpoints` in systemwide
   (`/etc/hasher-priv/system`) or user (`/etc/hasher-priv/user.d/$USER`)
   configuration.

3. Restart hasher-priv:

       # systemctl restart hasher-privd.service

> **TIP:** You can install multiple SVACE distributions to `/opt` and
> create a symlink `/opt/svace` pointing to the relevant one.

## Results

`hsh-svace` creates a results archive in the directory specified with
`--outdir` (or the current directory by default):

- `hsh-svace-results.tar` — build-only results (when using `--build-only`)
- `hsh-svace-results-analyzed.tar` — results with analysis (default or `--analyze-only`)

### hsh-svace-svacer-import

`hsh-svace-svacer-import` imports analysis results into svacer with metadata
from the results archive.

Run `hsh-svace-svacer-import --help` to see the usage.

## License

This project is licensed under the terms of the GNU GPLv3 license.

Copyright (C) 2024-2026  Egor Ignatov <egori@altlinux.org>
