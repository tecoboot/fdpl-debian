#!/bin/bash -e

source fdpl-vars

echo "... Start building FDPL Debian $DIST $ARCH"

echo "... cd $LB_FOLDER"
mkdir -p $LB_FOLDER
cd       $LB_FOLDER

echo "... Use --restart to startover"
if [ "$1" == "--restart" ]; then
  echo -n "OK to remove all files in $PWD? "
  read
  rm -rf *
fi

echo "... Purge old fdpl-debian tarball file"
rm -f $TARFILE

echo "... Create live-build config"
lb clean &>>$LOGFILE

echo "... Create or update live-build config"
# disabled compression
# disabled tarball, do ourself (does not work)
lb config \
    --architectures amd64 \
    --apt-indices false \
    --apt-recommends false \
    --backports false \
    --binary-images tar \
    --checksums none \
    --chroot-filesystem none \
    --compression none \
    --distribution bookworm \
    --firmware-chroot false \
    --gzip-options --fast \
    --memtest none \
    --net-tarball false \
  &>>$LOGFILE

echo "... Add custom files"
cp -a $FDPL_FOLDER/fdpl.list.chroot config/package-lists/

echo "... Add hook scripts"
cat <<'end_hook' >config/hooks/normal/9990-fdpl.hook.chroot

echo "... Update root password"
echo root:debian | chpasswd

echo "... Update hostname"
echo "fdpl-000" >/etc/hostname

echo "... Update profile for ll"
echo "alias ll='ls -al'" >/etc/profile.d/ls.sh
chmod +x /etc/profile.d/ls.sh

echo "... Update network, DHCP"
cat <<end_dhcp >>/etc/network/interfaces
#
# run dhclient
allow-hotplug eth0
iface eth0 inet dhcp
#
end_dhcp

echo "... Update SSH server"
dpkg-reconfigure openssh-server
cat <<end_ssh >>/etc/ssh/sshd_config
PermitRootLogin yes
end_ssh

echo "... Remove live package list"
rm -f config/package-lists/live.list.chroot

exit 0
end_hook


# shell for verification
cat <<EOF >config/hooks/normal/9999-fdpl-bash.hook.chroot.disabled
/bin/bash
exit 0
EOF
# Uncomment to debug with shell
# mv config/hooks/normal/9999-fdpl-bash.hook.chroot.disabled config/hooks/normal/9999-foxtrot-bash.hook.chroot


echo "... Make hook scripts executable"
chmod +x config/hooks/normal/*-fdpl*.hook.chroot


echo "... Build, takes a while"
echo "... Can follow with tail -f $LOGFILE"
lb build &>>$LOGFILE

# No return code, check binary folder
if [ ! -d $LB_FOLDER/binary ]; then
  die "ERROR in build, check $LOGFILE"
fi

echo "... Update binary folder"
cd $LB_FOLDER/binary

echo "...... Copy fdpl build files"
mkdir -p ./$FDPL_FOLDER
cp -a $FDPL_FOLDER/fdpl-* ./$FDPL_FOLDER

echo "...... Tune initrd for speed"
sed -i "s/MODULES=.*/MODULES=dep/g; s/.*COMPRESSLEVEL=.*/COMPRESSLEVEL=1/g"  ./etc/initramfs-tools/initramfs.conf
cat <<'EOF' >$LB_FOLDER/binary/etc/network/if-up.d/initrd-update 
#!/bin/bash

# Shrink initrd.img, with MODULES=dep setting
update-initramfs -u

# Run once, so do a chmod
chmod -x $0
EOF
chmod +x ./etc/network/if-up.d/initrd-update

echo "...... Cleanup binary folder"
rm -rf usr/share/locale/*
rm -rf usr/share/doc/*
rm -f initrd.img* vmlinuz*
rm -f boot/initrd.img boot/vmlinuz


echo "... Remove live tarball (bypass)"
cd $LB_FOLDER
rm -f live-image-amd64.tar.tar 

echo "... Make tarball file"
cd binary
tar -cf ../$TARFILE *
cd ..

echo "*************************"
ls -al $TARFILE
echo "*************************"

exit 0

