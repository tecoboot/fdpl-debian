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

Have fun with FDPL-Debian !!!


Running `fdpl-update.sh `:
```
root@Bookworm-gui:~/fdpl-debian# ./fdpl-update.sh 
... Set vars
...... Set local vars from fdpl-debian.conf
... Get current main branch from gitlab
... Deploy main branch
root@Bookworm-gui:~/fdpl-debian#
```

Running `fdpl-build-debian.sh`:
```
root@Bookworm-gui:~/fdpl-debian# ./fdpl-build-debian.sh 
... Set vars
...... Set local vars from fdpl-debian.conf
... Start building FDPL Debian bookworm amd64
... cd /root/fdpl-debian/lb
... Use --restart to startover
... Purge old fdpl-debian tarball file
... Create live-build config
... Create or update live-build config
... Add custom files
... Add hook scripts
... Make hook scripts executable
... Build, takes a while
... Can follow with tail -f /root/fdpl-debian/log/fdpl-build-debian.sh.1739560685.log
... Update binary folder
...... Copy fdpl build files
...... Tune initrd for speed
...... Cleanup binary folder
... Remove live tarball (bypass)
... Make tarball file
*************************
-rw-r--r-- 1 root root 737822720 Feb 14 20:21 fdpl-debian-bookworm-amd64.tar
*************************
root@Bookworm-gui:~/fdpl-debian#
```

Running `fdpl-install-debian.sh`:
```
root@Bookworm-gui:~/fdpl-debian# ./fdpl-install-debian.sh 
... Set vars
...... Set local vars from fdpl-debian.conf
... Start FDPL Debian Installation
... Find unmounted device, first one found will be used
... Unmount /mnt/fdpl-debian
... List of block devices:
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0   20G  0 disk 
├─sda1   8:1    0   19G  0 part /
├─sda2   8:2    0    1K  0 part 
└─sda5   8:5    0  975M  0 part [SWAP]
sdb      8:16   0    8G  0 disk 
└─sdb1   8:17   0    8G  0 part 
sr0     11:0    1  2.8G  0 rom  
... /dev/sdb has no mount, so it is candidate to format and install
... ### All data on disk /dev/sdb will be destroyed ###
Enter OK to continue ... OK
... Make disklabel (partition  table)
... Make fdpl partition 1 with ext4, set boot flag
... Mount fdpl-debian partition on /mnt/fdpl-debian
... Unmount /mnt/fdpl-debian
... Mount /mnt/fdpl-debian
... Load /root/fdpl-debian/lb/fdpl-debian-bookworm-amd64.tar to fdpl-debian partition
... Update root password, copied from current system                                                                                                   
... Install grub on /dev/sdb
Installing for i386-pc platform.
Installation finished. No error reported.
... Configure grub
... Unmount /mnt/fdpl-debian
... FDPL Debian Installation on /dev/sdb completed !!
root@Bookworm-gui:~/fdpl-debian# 
```
