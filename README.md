# FDPL-Debian

FDPL-Debian is a Debian live build for headless devices, with networking in mind.
For easy deployment, every FDPL-Debian system can reproduce itself: rebuild and install
on another device. Also, mutations can be created, which can be reproduced.
In short, FDPL-Debian is a VIRUS. Many viruses are profitable, let FDPL-Debian be one
of them!

The main design goal is simplicity, just as viruses.

Bootstrapping fdpl-debian is easy, cut & paste these commands in a root shell:
```
wget -q https://github.com/tecoboot/fdpl-debian/archive/refs/heads/main.zip
unzip -qq main.zip
rm main.zip
mv fdpl-debian-main/* ./
rmdir fdpl-debian-main
```

Run `./fdpl-build-debian.sh` from folder /root/fdpl-debian. This creates your own Debian
distribution tarball file.

Then insert a USB storage stick to your system and run `fdpl-install-debian.sh` from
folder /root/fdpl-debian. Now you have your fdpl-debian USB install stick.

Unplug and insert to your target device. Boot from USB. Then run `fdpl-install-debian.sh`
from folder /root/fdpl-debian again. Take out the USB storage stick and reboot. Now you
have your first device running your fdpl-debian.

The default password is `debian`, or a copy of your root password if it is configured.

Files in ./local folder will be copied and deployed on "/" root-folder during
installation. With a post-install script, cloning extensions is straight-forward.

Files in ./firmware folder are deployed on "/" root-folder during build.
These are also copied during installation.

Sync to git repository with `fdpl-update.sh` script.

Use file fdpl.vars for adjustments. These are copied during installation, but lost at
update. Use file fdpl.local.vars for *local* adjustments. These will not be copied and
will not be overwritten at update.


Have fun with FDPL-Debian !!!


Running `fdpl-update.sh `, switch to main branch:
```
root@fdpl202502191758:~/fdpl-debian# ./fdpl-update.sh -b main
... Set vars
... Set local vars from fdpl.local.vars
... Start FDPL Debian update
... Get current main branch from gitlab
... Deploy main branch
... Update FDPL Debian utility completed !!
root@fdpl202502191758:~/fdpl-debian#
```

Running `fdpl-build-debian.sh`, with restart of the lb (livebuild) folder.
```
root@fdpl202502191758:~/fdpl-debian# ./fdpl-build-debian.sh -r
... Set vars
... Set local vars from fdpl.local.vars
... Start FDPL Debian build
... cd /root/fdpl-debian/lb
OK to remove all files in /root/fdpl-debian/lb?
... All files in /root/fdpl-debian/lb will be deleted
... Purge old fdpl-debian tarball file
... Create live-build config
... Config live-build config
... Add custom files
... Add hook scripts
... Make hook scripts executable
... Build, takes a while
... Update binary folder
...... Update hostname
...... Tune chrony
...... Copy fdpl build files
...... Tune initrd for speed, for a next initrd generation
...... Cleanup binary folder
... Remove live tarball (bypass)
... Make tarball file
*************************
-rw-r--r-- 1 root root 739819520 Feb 19 16:53 fdpl-debian-bookworm-amd64.tar
*************************
... FDPL Debian build completed !!
root@fdpl202502191758:~/fdpl-debian#
```

Running `fdpl-install-debian.sh`, switch to new hostname:
```
root@fdpl202502191758:~/fdpl-debian# ./fdpl-install-debian.sh -n fdpl-003
... Set vars
... Set local vars from fdpl.local.vars
... Start FDPL Debian installation
... Find unmounted device, first one found will be used
... Unmount /mnt/fdpl-debian
...... sync
... List of block devices:
========================================
... A partition on /dev/sda is mounted, skip

========================================
Disk /dev/sdb: 8 GiB, 8589934592 bytes, 16777216 sectors
Model: VMware, VMware Virtual S (scsi)
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINTS
sdb      8:16   0   8G  0 disk
└─sdb1   8:17   0   8G  0 part

... Select a disk ...

### All data on disk /dev/sdb, VMware, VMware Virtual S (scsi), 8 GiB, will be destroyed ###
### Enter OK to continue : OK

... Start FDPL Debian installation on /dev/sdb
... Make disklabel (partition  table)
... Make fdpl partition 1 with ext4, set boot flag
... Mount fdpl-debian partition on /mnt/fdpl-debian
... Unmount /mnt/fdpl-debian
...... sync
... Mount /mnt/fdpl-debian
... Load fdpl-debian-bookworm-amd64.tar to fdpl-debian partition, 706M
... Copy fdpl-debian folder
        739.89M  99%  348.79MB/s    0:00:02 (xfr#28, to-chk=0/42)
... Deploy local folder
         33.10K 100%   30.14MB/s    0:00:00 (xfr#13, to-chk=0/16)
... Update root password, copied from current system
... Update hostname
... Install grub on /dev/sdb
... Configure grub
... Copy logfile
... Unmount /mnt/fdpl-debian
...... sync
... FDPL Debian Installation on /dev/sdb completed !!
root@fdpl202502191758:~/fdpl-debian#
```
