#!/bin/bash -e

source fdpl-vars

function main() {
  echo "... Start FDPL Debian Installation"
  find_free_disk
  format_disk
  mount_fdpl
  copy_fdpl_debian
  update_root_password
  install_grub
  config_grub
  umount_fdpl
  echo "... FDPL Debian Installation on $InstallDisk completed !!"
}

function find_free_disk() {
  echo "... Find unmounted device, first one found will be used"
  umount_fdpl
  echo "... List of block devices:"
  lsblk
  for disk in $(sfdisk -l | egrep "^Disk /dev/" | tr -d ":"  | awk '{print $2}')
  do
    if mount | grep -q $disk ; then
      echo "... $disk is mounted, skip"
    else
      echo "... $disk has no mount, so it is candidate to format and install"
      echo "... ### All data on disk $disk will be destroyed ###"
      echo -n "Enter OK to continue ... "
      read OK
      if [ "$OK" != OK ]; then
        die "Installation aborted"
      fi
      InstallDisk=$disk
      break
    fi
  done
  if [ -z "$InstallDisk" ]; then
    die "No free installation disk. Missing or mounted?"
  fi
}

function format_disk() {
  echo "... Make disklabel (partition  table)"
  parted -a optimal -s $InstallDisk mklabel msdos

  echo "... Make fdpl partition 1 with ext4, set boot flag"
  parted -a optimal -s $InstallDisk mkpart primary ext4 0% 100%
  sync
  mkfs.ext4 -Fq ${InstallDisk}1 -L fdpl-debian 2>&1 >>$LOGFILE
  parted -s $InstallDisk set 1 boot on
}

function umount_fdpl() {
  echo "... Unmount $MOUNT_FOLDER"
  cd
  umount -q $MOUNT_FOLDER || true
}

function mount_fdpl() {
  echo "... Mount fdpl-debian partition on $MOUNT_FOLDER"
  mkdir -p $MOUNT_FOLDER
  umount_fdpl
  echo "... Mount $MOUNT_FOLDER"
  mount ${InstallDisk}1 $MOUNT_FOLDER
}

copy_fdpl_debian() {
  echo "... Load $LB_FOLDER/$TARFILE to fdpl-debian partition"
  cd $MOUNT_FOLDER
  tar -xf $LB_FOLDER/$TARFILE --checkpoint-action="ttyout='%T%*\r'" --checkpoint=1000
  sync
}

function update_root_password() {
  root_password=$(awk -F ":" '/fdpl/{print $2}' /etc/shadow)
  if [ -n "$root_password" ]; then
    echo "... Update root password"
    echo "root:$root_password" | chpasswd -e -R $MOUNT_FOLDER
  else
    echo "... No root password set, set to default: debian"
    echo "root:$DEFAULT_ROOT_PASSWORD" | chpasswd -R $MOUNT_FOLDER
  fi
}

function install_grub() {
  echo "... Install grub on $InstallDisk"
  grub-install --root-directory=$MOUNT_FOLDER $InstallDisk 2>&1 >>$LOGFILE
  sync
}

function config_grub() {
  echo "... Configure grub"
  uuid_partition1=$(blkid | grep ${InstallDisk}1 | awk -F\" '{print $4}')
  uuid_partition2=$(blkid | grep ${InstallDisk}2 | awk -F\" '{print $4}')	
  kernel_name=$(basename $(ls $MOUNT_FOLDER/boot/vmlinuz*amd64))
  initrd_name=$(basename $(ls $MOUNT_FOLDER/boot/initrd.img*amd64))
  cat <<EOF >$MOUNT_FOLDER/boot/grub/grub.cfg
## FDPL-Debian /boot/grub/grub.cfg 
set default=0
set timeout=2
insmod vga
insmod ext4
serial --unit=0 --speed=115200
terminal_input serial console
terminal_output serial console
menuentry 'FDPL Debian $DIST $ARCH' {
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

