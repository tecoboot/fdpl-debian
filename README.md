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

Run `fdpl-build-debian.sh`. This creates your own Debian distribution tarball file.

Then insert a USB storage stick to your system and run `fdpl-install-debian.sh`.
Now you have your fdpl-debian USB install stick.

Unplug and insert to your target device. Boot from USB. Then run `fdpl-install-debian.sh`
again. Take out the USB storage stick and reboot. Now you have your first device running
your fdpl-debian.

The default password is `debian`, or a copy of your root password if it is configured.

Files in ./local folder will be copied and deployed on root. With a post-install script,
cloning extensions is straight-forward.

Have fun with FDPL-Debian !!!


Running `fdpl-update.sh `, switch to main branch:
```
root@fdpl-001:~/fdpl-debian# ./fdpl-update.sh -b main
... Set vars
...... Set local vars from fdpl-debian.conf
... Start Update FDPL Debian utility
... branch changed from test to main
... Get current main branch from gitlab
root@fdpl-001:~/fdpl-debian#
```

Running `fdpl-build-debian.sh`, hostname on install image has -000 suffix:
```
root@fdpl-001:~/fdpl-debian# ./fdpl-build-debian.sh -n fdpl-000
... Set vars
...... Set local vars from fdpl-debian.conf
... Start building FDPL Debian bookworm amd64
... cd /root/fdpl-debian/lb
... Purge old fdpl-debian tarball file
... Create live-build config
... Create or update live-build config
... Add custom files
... Add hook scripts
... Make hook scripts executable
... Build, takes a while
... Can follow with tail -f /root/fdpl-debian/log/fdpl-build-debian.sh.1739802155.log
... Update binary folder"
...... Update hostname
...... Copy fdpl build files
...... Tune initrd for speed, for a next initrd generation
...... Cleanup binary folder
... Remove live tarball (bypass)
... Make tarball file
*************************
-rw-r--r-- 1 root root 737822720 Feb 14 20:21 fdpl-debian-bookworm-amd64.tar
*************************
... FDPL Debian build completed !!
root@fdpl-001:~/fdpl-debian#
```

Running `fdpl-install-debian.sh`, switch to new hostname:
```
root@fdpl-000:~/fdpl-debian# ./fdpl-install-debian.sh -n fdpl-003
... Set vars
...... Set local vars from fdpl-debian.conf
... Start FDPL Debian Installation
... Find unmounted device, first one found will be used
... Unmount /mnt/fdpl-debian
...... sync
... List of block devices:
========================================
... A partition on /dev/sda is mounted, skip

========================================
Disk /dev/sdb: 8 GiB, 8589934592 bytes, 16777216 sectors
NAME MAJ:MIN RM SIZE RO TYPE MOUNTPOINTS
sdb    8:16   0   8G  0 disk

... Select a disk ...

### All data on disk /dev/sdb, , 8 GiB, will be destroyed ###
### Enter OK to continue : OK

... Start FDPL Debian installation on /dev/sdb
... Make disklabel (partition  table)
... Make fdpl partition 1 with ext4, set boot flag
... Mount fdpl-debian partition on /mnt/fdpl-debian
... Unmount /mnt/fdpl-debian
...... sync
... Mount /mnt/fdpl-debian
... Load fdpl-debian-bookworm-amd64.tar to fdpl-debian partition, 704M
... Copy local files to fdpl-debian partition
         36.35K 100%    1.71MB/s    0:00:00 (xfr#2, to-chk=0/3)
... Deploy local files
         36.35K 100%    3.42MB/s    0:00:00 (xfr#2, to-chk=0/2)
... Copy fdpl-debian-bookworm-amd64.tar to fdpl-debian partition, 704M
        737.82M 100%  125.73MB/s    0:00:05 (xfr#1, to-chk=0/1)
... Update root password, copied from current system
... Update hostname
... Install grub on /dev/sdb
... Configure grub
... Copy logfile
... Unmount /mnt/fdpl-debian
...... sync
... FDPL Debian Installation on /dev/sdb completed !!
root@fdpl-000:~/fdpl-debian#
```
