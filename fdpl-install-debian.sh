#!/bin/bash -e

source fdpl.vars

function main() {
  echo "... Start FDPL Debian installation"
  find_free_disk
  format_disk
  for InstallPart in ${InstallPartition2} ${InstallPartition3}
  do 
    echo "... ### $InstallPart ###"
    mount_fdpl
    load_fdpl_debian
    copy_fdpl_folder
    update_root_password
    update_hostname
    load_local_folder
  done
  echo "... ### Installations on partitions done ###"
  install_grub
  end_with_copy_log
  umount_fdpl
  echo "... FDPL Debian Installation on $InstallDiskDev completed !!"
  log_ended_message
}

function reinstall_maint() {
  case ${ROOT_PART: -1} in
    3)
      # Prod partition active, reinstall maint
      echo "... Reinstall FDPL Debian, start with maint partition"
      # Start with reinstall maint partition
      InstallPart=${ROOT_PARTITION2}
      mount_fdpl
      rm -rf $MOUNT_FOLDER/*
      load_fdpl_debian
      copy_fdpl_folder
      update_root_password
      update_hostname
      load_local_folder
      echo "... Prepare maint partition for reinstall prod"
      prepare_reinstall_prod
      reboot_part maint
      ;;
    *)
      echo "reinstall maint but not prod"
      exit 1
  esac
}

function reinstall_prod() {
  case ${ROOT_PART: -1} in
    2)
      # Maint partition, so reinstall prod and reboot
      InstallPart=${ROOT_PARTITION3}
      mount_fdpl
      rm -rf $MOUNT_FOLDER/*
      load_fdpl_debian
      copy_fdpl_folder
      update_root_password
      update_hostname
      load_local_folder
      # Disable reinstall service
      rm -f /etc/systemd/system/multi-user.target.wants/fdpl-install.service
      # Switch back to new prod partition
      reboot_part prod
      ;;
    *)
      echo "reinstall prod but not maint"
      exit 1
  esac
}

function prepare_reinstall_prod() {
  echo "... Reinstall FDPL Debian, prepare and switch to maint, and return to new prod"
  cat <<EOF >$MOUNT_FOLDER/etc/systemd/system/fdpl-install.service
[Unit]
Description=FDPL reinstall, now prod partition
[Service]
User=root
WorkingDirectory=/root/fdpl-debian
ExecStart=/bin/bash /root/fdpl-debian/fdpl-install-debian.sh -R
[Install]
WantedBy=multi-user.target
EOF
  ln -s /etc/systemd/system/fdpl-install.service $MOUNT_FOLDER/etc/systemd/system/multi-user.target.wants/fdpl-install.service
}

function help() {
   echo "Install FDPL Debian on storage device"
   echo
   echo "Syntax: fdpl-install.sh [-f|-h|-n new-hostname|-r]"
   echo "options:"
   echo "-f     Follow log"
   echo "-h     Show help"
   echo "-n NH  Set new hostname on installed disk"
   echo "-r     Reinstall"
   echo
}

while getopts ":fhn:rR" option; do
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
      r) # Reinstall, first maint, then prod
         Reinstall=maint
         ;;
      R) # Reinstall-prod (from maint)
         Reinstall=prod
         ;;
     \?) # Invalid option
         echo "Error: Invalid option"
         help
         exit
         ;;
   esac
done

function find_free_disk() {
  umount_fdpl
  echo "... List disk devices:"
  CanidateDisks=""
  for disk in $(lsblk -dn | grep -v " 0B" | cut -d " " -f 1 | sort)
  do
    # disks > 0 bytes
    DiskDev=/dev/$disk
    if sfdisk -l $DiskDev &>/dev/null ; then
      # Usable disk found
      echo "========================================"
      DiskSizeGB=$(($(lsblk -bdno SIZE $DiskDev) / 1000000000))
      if mount | grep -q "$DiskDev" ; then
        echo "... A partition on $DiskDev is mounted, skip"
      elif [ $DiskSizeGB -lt $MIN_DISK_SIZE ]; then
        echo "... Disk $DiskDev size is less than $MIN_DISK_SIZE GB, skip"
      else
        # Usable disk found
        CanidateDisks="$CanidateDisks $DiskDev"
        sfdisk -l $DiskDev 2>>$LOGFILE | egrep "^Disk $DiskDev" || true
        parted $DiskDev print 2>>$LOGFILE | egrep "^Model: " || true
      fi
    fi
  done
  echo "========================================"
  echo "... Select a disk ..."
  for DiskDev in $CanidateDisks
  do
    DiskModel=$(parted $DiskDev print 2>/dev/null | egrep "^Model: " | cut -d " " -f 2-)
    DiskSize=$(sfdisk -l $DiskDev | egrep "^Disk $DiskDev" | cut -d " " -f 3-4)
    echo
    echo    "### All data on disk $DiskDev, $DiskModel, $DiskSize will be destroyed ###"
    echo -n "### Enter OK to continue : "
    read OK
    if [ "$OK" == OK ]; then
      InstallDiskDev=$DiskDev
      DiskSizeGB=$(($(lsblk -bdno SIZE $InstallDiskDev) / 1000000000))
      echo
      echo "... Start FDPL Debian installation on $DiskDev"
      break
    else
      echo "...... Installation on disk $DiskDev skipped"
    fi
  done
  if [ -z "$InstallDiskDev" ]; then
    die "No free installation disk. Missing or is target mounted?"
  fi
}

function format_disk() {
  case "$BOOT_TYPE" in
    EFI)
      echo "... Make disklabel (partition table), type GPT for EFI boot and FAT boot partition"
      parted -a cylinder -s $InstallDiskDev mklabel gpt
      parted -a cylinder -s $InstallDiskDev mkpart primary fat16 0% $PART_END_GRUB
      ;;
    MBR)
      echo "... Make disklabel (partition table), type MSDOS for legacy/MBR boot and ext4 boot partition"
      parted -a cylinder -s $InstallDiskDev mklabel msdos
      parted -a cylinder -s $InstallDiskDev mkpart primary ext4 0% $PART_END_GRUB
      ;;
    *)
      die "No valid BOOT_TYPE, select EFI or MBR"
      ;;
  esac
  echo "... Set boot flag on partition 1 "
  parted -s $InstallDiskDev set 1 boot on
  echo "... Make maint partition 2"
  parted -a cylinder -s $InstallDiskDev mkpart primary ext4 $PART_END_GRUB $PART_END_MAINT
  echo "... Make prod partition 3"
  parted -a cylinder -s $InstallDiskDev mkpart primary ext4 $PART_END_MAINT 100%
  sync
  InstallPartition1=$(fdisk -l $InstallDiskDev | egrep -A 3 "^Device " | awk 'NR==2 {print $1}')
  InstallPartition2=$(fdisk -l $InstallDiskDev | egrep -A 3 "^Device " | awk 'NR==3 {print $1}')
  InstallPartition3=$(fdisk -l $InstallDiskDev | egrep -A 3 "^Device " | awk 'NR==4 {print $1}')
  echo "... Format partition 1 - $LABEL_1 - with fat16 filesystem"
  mkfs.fat -F 16 ${InstallPartition1} -n FDPLBOOTEFI 2>&1 >>$LOGFILE
  echo "... Format partition 1 - $LABEL_2 - with ext4 filesystem"
  mkfs.ext4 -Fq ${InstallPartition2} -L $LABEL_2 2>&1 >>$LOGFILE
  echo "... Format partition 1 - $LABEL_3 - with ext4 filesystem"
  mkfs.ext4 -Fq ${InstallPartition3} -L $LABEL_3 2>&1 >>$LOGFILE
  sync
  sleep 0.1   # wait before it can be used
}

function umount_fdpl() {
  if pwd | grep -q $MOUNT_FOLDER ; then
    cd
  fi
  while mount | grep -q " on $MOUNT_FOLDER"
  do
    echo "... Unmount $MOUNT_FOLDER"
    sync
    umount -q $MOUNT_FOLDER
  done
}

function mount_fdpl() {
  mkdir -p $MOUNT_FOLDER
  umount_fdpl
  echo "... Mount ${InstallPart} partition on $MOUNT_FOLDER"
  mount ${InstallPart} $MOUNT_FOLDER
}

load_fdpl_debian() {
  echo "... Load $TARFILE to ${InstallPart} partition, $(du $LB_FOLDER/$TARFILE -h | cut -f 1)"
  cd $MOUNT_FOLDER
  tar -xf $LB_FOLDER/$TARFILE --checkpoint-action="ttyout='%T%*\r'" --checkpoint=1000
}

copy_fdpl_folder() {
  echo "... Copy fdpl-debian folder"
  cat <<EOF >/tmp/rsync-include-list
fdpl-build-debian.sh
fdpl-install-debian.sh
fdpl-update.sh
fdpl.list.chroot
fdpl.vars
fdpl.local.vars
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
  echo "... Update hostname to $NEW_INSTALL_HOSTNAME"
  echo $NEW_INSTALL_HOSTNAME >$MOUNT_FOLDER/etc/hostname
}

function install_grub() {
  echo "... Install grub on ${InstallDiskDev}"

  uuid_partition2=$(blkid | grep ${InstallPartition2} | awk -F\" '{print $4}')
  InstallPart=${InstallPartition2}
  mount_fdpl
  kernel_name2=$(basename $(ls $MOUNT_FOLDER/boot/vmlinuz-*))
  initrd_name2=$(basename $(ls $MOUNT_FOLDER/boot/initrd.img-*))

  uuid_partition3=$(blkid | grep ${InstallPartition3} | awk -F\" '{print $4}')
  InstallPart=${InstallPartition3}
  mount_fdpl
  kernel_name3=$(basename $(ls $MOUNT_FOLDER/boot/vmlinuz-*))
  initrd_name3=$(basename $(ls $MOUNT_FOLDER/boot/initrd.img-*))

  InstallPart=${InstallPartition1}
  mount_fdpl
  grub-install --force --root-directory=$MOUNT_FOLDER ${InstallDiskDev} &>>$LOGFILE
  sync
  cat <<EOF >$MOUNT_FOLDER/boot/grub/grub.cfg
## FDPL-Debian /boot/grub/grub.cfg
set default=1
set timeout=2
insmod vga
insmod ext4
serial --unit=0 --speed=115200
terminal_input serial console
terminal_output serial console
set maint_kernel=/boot/$kernel_name2
set maint_initrd=/boot/$initrd_name2
set prod_kernel=/boot/$kernel_name3
set prod_initrd=/boot/$initrd_name3
menuentry '$LABEL_2 - FDPL Debian $DIST $ARCH Maintenance partition' {
  set root='hd0,2'
  linux  \$maint_kernel root=UUID="$uuid_partition2" rw console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0
  initrd \$maint_initrd
}
menuentry '$LABEL_3 - FDPL Debian $DIST $ARCH Production partition' {
  set root='hd0,3'
  linux  \$prod_kernel root=UUID="$uuid_partition3" rw console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0
  initrd \$prod_initrd
}
EOF
  echo "... Copy EFI boot files"
  cp -a /EFI $MOUNT_FOLDER/
}

function reboot_part {
  NextRebootPart=$1
  echo "... Reboot to $NextRebootPart partition"
  case "$NextRebootPart" in
    maint)
      NextPart=${ROOT_PARTITION2}
      GrubDefault=0
      ;;
    prod)
      NextPart=${ROOT_PARTITION3}
      GrubDefault=1
      ;;
    *)
      die "Invalid reboot partition"
      ;;
  esac
  echo "... Get Linux kernel version on next partition"
  InstallPart=$NextPart
  mount_fdpl
  kernel_name=$(basename $(ls $MOUNT_FOLDER/boot/vmlinuz-*))
  initrd_name=$(basename $(ls $MOUNT_FOLDER/boot/initrd.img-*))
  echo "... Linux kernel found: $kernel_name"
  InstallPart=${ROOT_PARTITION1}
  mount_fdpl
  GrubFolder=$MOUNT_FOLDER/boot/grub
  sed -i "s/set default=.*/set default=${GrubDefault}/" $GrubFolder/grub.cfg
  sed -i "s|set maint_kernel=.*|set maint_kernel=/boot/$kernel_name|g" $GrubFolder/grub.cfg
  sed -i "s|set maint_initrd=.*|set maint_initrd=/boot/$initrd_name|g" $GrubFolder/grub.cfg
  umount_fdpl
  echo "... Go for it"
  sleep 0.1
  reboot
}

# go for it
if [ "$Reinstall" == maint ]; then
  echo
  echo    "### Are you sure you want to reinstall ###"
  echo -n "### Enter OK to continue : "
  read OK
  if [ "$OK" == OK ]; then
    reinstall_maint
  else
    echo "### aborted ###"
  fi
elif [ "$Reinstall" == prod ]; then
  reinstall_prod
else
  main
fi

exit 0
