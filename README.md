# FDPL-Debian

FDPL-Debian is a Debian live build for headless devices, with networking in mind.
For easy deployment, every FDPL-Debian system can reproduce itself: rebuild and install
on another device. Also, mutations can be created, which can be reproduced.
In short, FDPL-Debian is a VIRUS. Many viruses are profitable, let FDPL-Debian be one
of them!

The main design goal is simplicity, just as viruses.

Bootstrapping fdpl-debian is easy, cut & paste these commands in a root shell:
```
cd /root/
wget -q https://github.com/tecoboot/fdpl-debian/archive/refs/heads/main.zip
unzip -qq main.zip
mv fdpl-debian-main fdpl-debian
rm main.zip
cd fdpl-build-debian
```

Run `./fdpl-build-debian.sh`. This creates your own Debian distribution tarball file.

Then insert a USB storage stick to your system and run `fdpl-install-debian.sh`.
Now you have your fdpl-debian USB install stick.

Disconnect and connect to your target device. Boot from USB. Then run
`fdpl-install-debian.sh` from folder /root/fdpl-debian again. Disconnect the USB storage 
stick and reboot. Now you have your first device running your fdpl-debian.

The default password is `debian`, or a copy of your root password if it is configured.

Files in ./local folder will be copied and deployed on "/" root-folder during
installation. With a post-install script, cloning extensions is straight-forward.

Files in ./firmware folder are deployed on "/" root-folder during build.
These are also copied during installation.

Sync with git repository with `fdpl-update.sh` script.

Use file fdpl.vars for adjustments. These are copied during installation, but *lost at
update*. 

Use file fdpl.local.vars for *local* adjustments. These will not be copied and
will not be overwritten at update.

Note that recent Debian i386 *does not* run on PC Engines Alix boards, Debian requires
i868 instruction set.

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
-rw-r--r-- 1 root root 535173120 Dec  1 19:34 fdpl-debian-trixie-amd64.tar
*************************
... FDPL Debian build completed !!
root@fdpl202502191758:~/fdpl-debian#
```

Running `fdpl-install-debian.sh`, switch to new hostname:
```
root@fdpl-2512021300:~/fdpl-debian# ./fdpl-install-debian.sh 
... Set vars
... Set local vars from fdpl.local.vars
... Start FDPL Debian installation
... List disk devices:
========================================
Disk /dev/sda: 14.91 GiB, 16013942784 bytes, 31277232 sectors
Model: ATA SATA SSD (scsi)
========================================
... A partition on /dev/sdb is mounted, skip
========================================
... Select a disk ...

### All data on disk /dev/sda, ATA SATA SSD (scsi), 14.91 GiB, will be destroyed ###
### Enter OK to continue : OK

... Start FDPL Debian installation on /dev/sda
... Make disklabel (partition table), type MSDOS for legacy/MBR boot and ext4 boot partition
... Set boot flag on partition 1 
... Make maint partition 2
... Make prod partition 3
... Format partition 1 - grub-2512021404 - with fat16 filesystem
... Format partition 1 - maint-2512021404 - with ext4 filesystem
... Format partition 1 - prod-2512021404 - with ext4 filesystem
... ### /dev/sda2 ###
... Mount /dev/sda2 partition on /mnt/fdpl-debian
... Load fdpl-debian-trixie-amd64.tar to /dev/sda2 partition, 511M
... Copy fdpl-debian folder                                                                                                                                                             
        535.27M 100%   65.38MB/s    0:00:07 (xfr#22, to-chk=0/28) 
... Update root password, copied from current system
... Update hostname to fdpl-2512021404
... Local folder is empty
... ### /dev/sda3 ###
... Unmount /mnt/fdpl-debian
... Mount /dev/sda3 partition on /mnt/fdpl-debian
... Load fdpl-debian-trixie-amd64.tar to /dev/sda3 partition, 511M
... Copy fdpl-debian folder                                                                                                                                                             
        535.27M 100%   65.57MB/s    0:00:07 (xfr#22, to-chk=0/28) 
... Update root password, copied from current system
... Update hostname to fdpl-2512021404
... Local folder is empty
... ### Installations on partitions done ###
... Install grub on /dev/sda
... Unmount /mnt/fdpl-debian
... Mount /dev/sda2 partition on /mnt/fdpl-debian
... Unmount /mnt/fdpl-debian
... Mount /dev/sda3 partition on /mnt/fdpl-debian
... Unmount /mnt/fdpl-debian
... Mount /dev/sda1 partition on /mnt/fdpl-debian
... Copy EFI boot files
... Copy logfile
... Unmount /mnt/fdpl-debian
... FDPL Debian Installation on /dev/sda completed !!
root@fdpl-2512021300:~/fdpl-debian# 
```
