# hsh-svace

Proof of Concept SVACE in hasher.

Run `./test.sh` to download SVACE, clone linux-pam gear repository and build it under SVACE. As a result `svace-dir.tar.zst` with .svace-dir will be created.

## Bind mount setup

Bind mount allows using SVACE from the host to avoid copying it inside each chroot.

Aditional hasher-priv setup is required to bind mount svace distribution inside hasher chroot.

`hsh-rebuild` needs mount point that explicitly provided by some package. For that reason `/media` from filesystem package was chosen, although it is not a convenient place for that kind of task.

First, the following line should be add to `/etc/hasher-priv/fstab`:
```
<path-to-svace-distribution> /media none bind
```

And second, `/media` should be added to allowed_mountpoints in systemwide (/etc/hasher-priv/system) or user (/etc/hasher-priv/user.d/$USER) configuration.

> For backward compatibility and quick setup `hsh-svace.old` is provided.
