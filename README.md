# hsh-svace

Run SVACE in hasher.

https://www.ispras.ru/en/technologies/svace

## Prerequisites

- SVACE installed in /opt
- Configured hasher (https://www.altlinux.org/Hasher)
- Extra hasher configuration for (more on this later)

## Usage

`hsh-svace` is used like `hsh` or `hsh-rebuild`, just run it with gear command:
```
gear [gear_options] --hasher -- hsh-svace [hsh-svace_options]

for example:

gear -v --commit --hasher -- hsh-svace --workdir=~/hasher
```

By default hsh-svace runs both `svace build` and `svace analyze`, the latter
requires a license key and special configuration (see below). To skip analisys
add `--build-only` option.

Run `hsh-svace --help` to see all the options.

## Results
As a result, `hsh-svace` creates an archive named `svace-results.tar` and places
it in the directory specified with `--outdir` or in the current working
directory if not specified.

## Extra hasher configuration
### Configure hasher to use svace from host (required)
`hsh-svace` mounts host's `/opt` directory inside the hasher environmet and
expects a svace distribution there. The following hasher-priv configuration is
required to achive this:

Firstly аppend `/etc/hasher-priv/fstab` with:
```
/opt /opt bind bind,ro,nosuid,nodev 0 0
```

Then add /opt mount point to `allowed_mountpoints` option in systemwide
(/etc/hasher-priv/system) or user (/etc/hasher-priv/user.d/$USER) configuration.

You may need to restart hasher-priv in order for this to start working.
```
# systemctl restart hasher-privd.service
```

> TIP: You can install multiple svace distribution to /opt and a create symlink
>      /opt/svace pointing to the relevant one.

> NOTE: to only mount svace distribution use /opt/svace instead of /opt.

### Additional configuration for analysis
Svace analysis stage requires configured haspd license server. The description
of how to set up such a server is beyond the scope here. I assume that it is
configured on the host, and will only describe how to use it in a hasher
environment.

Configure /var/hasplm mountpoint just as described in the above
section. For `/etc/hasher-priv/fstab` use:
```
/var/hasplm /var/hasplm bind bind,ro,nosuid,nodev,noexec 0 0
```
Аdd it to `allowed_mountpoints`. Restart hasher-priv, and that should be it.

# License
This project is licensed under the terms of the GNU GPLv3 license.

Copyright (C) 2024  Egor Ignatov <egori@altlinux.org>
