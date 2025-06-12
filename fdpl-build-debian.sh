#!/bin/bash -e

source fdpl.vars

function main() {
  echo "... Start FDPL Debian build"
  prepare_live_build
  prepare_lb_folder
  purge_old_tarball
  lb_clean
  lb_config
  add_package_list
  copy_firmware
  add_hook_scripts
  lb_build
  update_binary
  make_tarball
  echo "... FDPL Debian build completed !!"
  log_ended_message
}

function help() {
   echo "Build FDPL Debian tarball"
   echo
   echo "Syntax: fdpl-build-debian.sh [-f|-h|-n new-hostname|-r]"
   echo "options:"
   echo "-f     Follow log"
   echo "-h     Show help"
   echo "-n NH  Set new hostname in tarball"
   echo "-r     Restart with empty lb folder"
   echo
}

while getopts ":fhn:r" option; do
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
         NEW_BUILD_HOSTNAME=$OPTARG
         ;;
      r) # Restart lb
         restart=true
         ;;
     \?) # Invalid option
         echo "Error: Invalid option"
         help
         exit
         ;;
   esac
done


function prepare_live_build() {
  if ! ping -q -c1 google.com &>/dev/null ; then
    die "No Internet access"
  fi
  if ! which lb &>/dev/null ; then
    echo "... Install live-build package"
    export DEBIAN_FRONTEND=noninteractive
    export DEBIAN_PRIORITY=critical
    apt-get -qy update &>>$LOGFILE
    apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade &>>$LOGFILE
    apt-get -qy install live-build &>>$LOGFILE
    apt-get -qy autoclean &>>$LOGFILE
  fi
}

function prepare_lb_folder() {
  echo "... cd $LB_FOLDER"
  mkdir -p $LB_FOLDER
  cd       $LB_FOLDER

  if [ "$restart" == true ]; then
    echo -n "OK to remove all files in $PWD? "
    read
    echo "... All files in $LB_FOLDER will be deleted"
    rm -rf *
  fi
}

function purge_old_tarball() {
  echo "... Purge old fdpl-debian tarball file"
  rm -f $TARFILE
}

function lb_clean() {
  echo "... Create live-build config"
  lb clean &>>$LOGFILE
}

function lb_config() {
  echo "... Config live-build config"
  # disabled compression
  # disabled tarball, do ourself (does not work, live-image is build)
  lb config \
    --architecture $ARCH \
    --apt-indices false \
    --apt-recommends false \
    --backports false \
    --binary-images tar \
    --checksums none \
    --chroot-filesystem none \
    --compression none \
    --distribution $DIST \
    --firmware-chroot false \
    --gzip-options --fast \
    --memtest none \
    --net-tarball false \
    &>>$LOGFILE
}

function add_package_list() {
  echo "... Add custom files"
  cp -a $FDPL_FOLDER/fdpl.list.chroot config/package-lists/
}

function copy_firmware() {
  cp -a $FIRMWARE_FOLDER/lib config/includes.chroot_before_packages/
}

function add_hook_scripts() {
  echo "... Add hook scripts"
  cat <<'9990-fdpl.hook' >config/hooks/normal/9990-fdpl.hook.chroot

  echo "... Update root password"
  echo root:debian | chpasswd

  echo "... Update profile for ll"
  echo "alias ll='ls -al'" >/etc/profile.d/ls.sh
  chmod +x /etc/profile.d/ls.sh

  echo "... Update vim"
  echo "set mouse-=a" >/root/.vimrc

  echo "... Update network, DHCP"
  cat <<end_dhcp >>/etc/network/interfaces
#
allow-hotplug eth0
iface eth0 inet dhcp
#
end_dhcp

echo "... Update SSH server"
echo "PermitRootLogin yes" >>/etc/ssh/sshd_config
dpkg-reconfigure openssh-server

echo "... Remove live package list"
rm -f config/package-lists/live.list.chroot

exit 0
9990-fdpl.hook

  # shell for verification
  cat <<9999-fdpl-bash.hook >config/hooks/normal/9999-fdpl-bash.hook.chroot.disabled
/bin/bash
exit 0
9999-fdpl-bash.hook
  # Uncomment to debug with shell
  # mv config/hooks/normal/9999-fdpl-bash.hook.chroot.disabled config/hooks/normal/9999-foxtrot-bash.hook.chroot

  echo "... Make hook scripts executable"
  chmod +x config/hooks/normal/*-fdpl*.hook.chroot
}

function lb_build() {
  echo "... Build, takes a while"
  lb build &>>$LOGFILE

  # No return code, check binary folder
  if [ ! -d $LB_FOLDER/binary ]; then
    die "ERROR in build, check $LOGFILE"
  fi
}

function update_binary() {
  echo "... Update binary folder"
  cd $LB_FOLDER/binary

  echo "...... Update hostname"
  echo $NEW_BUILD_HOSTNAME >etc/hostname

  echo "...... Tune chrony"
  sed -i 's/makestep .*/makestep 1 -1/' etc/chrony/chrony.conf

  echo "...... Copy fdpl build files"
  mkdir -p ./$FDPL_FOLDER
  cp -a $FDPL_FOLDER/fdpl-* \
        $FDPL_FOLDER/fdpl.* \
        $FDPL_FOLDER/LICENSE \
        $FDPL_FOLDER/README.md ./$FDPL_FOLDER

  echo "...... Tune initrd for speed, for a next initrd generation"
  # xxx sed -i "s/MODULES=.*/MODULES=dep/g; s/.*COMPRESSLEVEL=.*/COMPRESSLEVEL=1/g"  ./etc/initramfs-tools/initramfs.conf

  echo "...... Cleanup binary folder"
  rm -rf usr/share/locale/*
  rm -rf usr/share/doc/*
  rm -f initrd.img* vmlinuz*
  rm -f boot/initrd.img boot/vmlinuz
}

function make_tarball() {
  echo "... Remove live tarball (bypass)"
  cd $LB_FOLDER
  rm -f live-image-$ARCH.tar.tar

  echo "... Make tarball file"
  cd binary
  rm -rf live
  tar -cf ../$TARFILE *
  cd ..

  echo "*************************"
  ls -al $TARFILE
  ls -al $TARFILE >>$LOGFILE
  echo "*************************"
}


# go for it
main
exit 0

