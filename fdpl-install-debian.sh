#!/bin/bash -e

source fdpl.vars

function main() {
  echo "... Start FDPL Debian installation"
  find_free_disk
  format_disk
  mount_fdpl
  load_fdpl_debian
  copy_fdpl_folder
  load_local_folder
  update_root_password
  update_hostname
  install_grub
  config_grub
  end_with_copy_log
  umount_fdpl
  echo "... FDPL Debian Installation on $InstallDiskDev completed !!"
  log_ended_message
}

function help() {
   echo "Install FDPL Debian on storage device"
   echo
   echo "Syntax: fdpl-install.sh [-f|h|n new-hostname]"
   echo "options:"
   echo "f     Follow log"
   echo "h     Show help"
   echo "n NH  Set new hostname on installed disk"
   echo
}

while getopts ":fhn:" option; do
   case $option in
      f) # Follow
         follow_latest_log
         exit
         ;;
      h) # display Help
         help
         exit
         ;;
      n) # get new hostname
         shift
         NEW_INSTALL_HOSTNAME=$OPTARG
         ;;
     \?) # Invalid option
         echo "Error: Invalid option"
         help
         exit
         ;;
   esac
done

function find_free_disk() {
  echo "... Find unmounted device, first one found will be used"
  umount_fdpl
  echo "... List of block devices:"
  for disk in $(lsblk -dno NAME | egrep -v "^sr" | sort)
  do
    DiskDev=/dev/$disk
    if mount | grep -q $disk ; then
      echo "========================================"
      echo "... A partition on $DiskDev is mounted, skip"
      echo
    else
      if sfdisk -l $DiskDev 2>/dev/null ; then
        echo "========================================"
        sfdisk -l $DiskDev 2>>$LOGFILE | egrep "^Disk $DiskDev" || true
        parted $DiskDev print 2>>$LOGFILE | egrep "^Model: " || true
        lsblk $DiskDev 2>>$LOGFILE || true
        echo
      fi
    fi
  done
  echo "... Select a disk ..."
  for disk in $(lsblk -dno NAME | egrep -v "^sr" | sort)
  do
    DiskDev=/dev/$disk
    DiskModel=$(parted $DiskDev print 2>/dev/null | egrep "^Model: " | cut -d " " -f 2-)
    DiskSize=$(sfdisk -l $DiskDev | egrep "^Disk $DiskDev" | cut -d " " -f 3-4)
    if ! mount | grep -q $DiskDev ; then
      echo
      echo    "### All data on disk $DiskDev, $DiskModel, $DiskSize will be destroyed ###"
      echo -n "### Enter OK to continue : "
      read OK
      if [ "$OK" == OK ]; then
        InstallDiskDev=$DiskDev
        echo
        echo "... Start FDPL Debian installation on $DiskDev"
        break
      else
        echo "...... Installation on disk $DiskDev skipped"
      fi
    fi
  done
  if [ -z "$InstallDiskDev" ]; then
    die "No free installation disk. Missing or is target mounted?"
  fi
}

function format_disk() {
  echo "... Make disklabel (partition  table)"
  parted -a cylinder -s $InstallDiskDev mklabel msdos

  echo "... Make fdpl partition 1 with ext4, set boot flag"
  parted -a cylinder -s $InstallDiskDev mkpart primary ext4 0% 100%
  sync
  mkfs.ext4 -Fq ${InstallDiskDev}1 -L fdpl-debian 2>&1 >>$LOGFILE
  parted -s $InstallDiskDev set 1 boot on
  sync
  sleep 0.1   # wait before it can be used
}

function umount_fdpl() {
  echo "... Unmount $MOUNT_FOLDER"
  cd
  echo "...... sync"
  sync
  umount -q $MOUNT_FOLDER 2>>$LOGFILE || true
}

function mount_fdpl() {
  echo "... Mount fdpl-debian partition on $MOUNT_FOLDER"
  mkdir -p $MOUNT_FOLDER
  umount_fdpl
  echo "... Mount $MOUNT_FOLDER"
  mount ${InstallDiskDev}1 $MOUNT_FOLDER
}

load_fdpl_debian() {
  echo "... Load $TARFILE to fdpl-debian partition, $(du $LB_FOLDER/$TARFILE -h | cut -f 1)"
  cd $MOUNT_FOLDER
  tar -xf $LB_FOLDER/$TARFILE --checkpoint-action="ttyout='%T%*\r'" --checkpoint=1000
}

copy_fdpl_folder() {
  echo "... Copy fdpl-debian folder"
  cat <<EOF >/tmp/rsync-include-list
fdpl-build-debian.sh
fdpl-install-debian.sh
fdpl-update.sh
fdpl.vars
LICENSE
README.md
local
firmware
lb/fdpl-debian-$DIST-$ARCH.tar
EOF
  mkdir -p $NEW_FDPL_FOLDER
  rsync -ah --info=progress2,stats0 --files-from=/tmp/rsync-include-list --recursive $FDPL_FOLDER $NEW_FDPL_FOLDER/
}

load_local_folder() {
  if [ -n "$(ls -A $LOCAL_FOLDER 2>/dev/null)" ]; then
    echo "... Deploy local folder"
    rsync -ah --info=progress2,stats0 -a $NEW_LOCAL_FOLDER/* $MOUNT_FOLDER/
  else
    echo "... Local folder is empty"
  fi
}

end_with_copy_log() {
  echo "... Copy logfile"
  mkdir -p $NEW_LOG_FOLDER
  echo "$(date) $SCRIPT ended" >>$LOGFILE
  cp $LOGFILE $NEW_LOGFILE
}

function update_root_password() {
  root_password=$(awk -F ":" '/root/{print $2}' /etc/shadow)
  if [ -n "$root_password" ]; then
    echo "... Update root password, copied from current system"
    echo "root:$root_password" | chpasswd -e -R $MOUNT_FOLDER
  else
    echo "... No root password set, set to default: debian"
    echo "root:$DEFAULT_ROOT_PASSWORD" | chpasswd -R $MOUNT_FOLDER
  fi
}

function update_hostname() {
  echo "... Update hostname"
  echo $NEW_INSTALL_HOSTNAME >$MOUNT_FOLDER/etc/hostname
}


function install_grub() {
  echo "... Install grub on $InstallDiskDev"
  # grub-install --force --root-directory=$MOUNT_FOLDER ${InstallDiskDev}1 2>&1 >>$LOGFILE
  grub-install --force --root-directory=$MOUNT_FOLDER ${InstallDiskDev} &>>$LOGFILE
  sync
}	

function config_grub() {
  echo "... Configure grub"
  uuid_partition1=$(blkid | grep ${InstallDiskDev}1 | awk -F\" '{print $4}')
  kernel_name=$(basename $(ls $MOUNT_FOLDER/boot/vmlinuz*$ARCH))
  initrd_name=$(basename $(ls $MOUNT_FOLDER/boot/initrd.img*$ARCH))
  cat <<EOF >$MOUNT_FOLDER/boot/grub/grub.cfg
## FDPL-Debian /boot/grub/grub.cfg
set default=0
set timeout=2
insmod vga
insmod ext4
serial --unit=0 --speed=115200
terminal_input serial console
terminal_output serial console
menuentry '$LABEL - FDPL Debian $DIST $ARCH' {
        set root='hd0,1'
        echo    'Loading kernel $kernel_name'
        linux   /boot/$kernel_name root=UUID="$uuid_partition1" rw console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0
        echo    'Loading ramdisk $initrd_name'
        initrd  /boot/$initrd_name
}
EOF
}

# go for it
main
exit 0

