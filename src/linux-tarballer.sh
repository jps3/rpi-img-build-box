#!/bin/bash -ex

[[ -n "$ARCH" ]] || exit -1

KERNEL_VERSION=$(make kernelversion) # Ex. 4.14.79
KERNEL_RELEASE=$(make kernelrelease) # Ex. 4.14.79-v7-auditd-g36612d5d7

TAR_PRODUCT=rpi-$ARCH-$KERNEL_RELEASE.tar.bz2

WORK_DIR="$(mktemp -d /tmp/${KERNEL_RELEASE}-XXXXXX)"


# ARCH should be defined in .envrc
# ex: ARCH=arm64

case $ARCH in
  arm64)  KERNEL_IMAGE=Image.gz
          ;;
  arm)    KERNEL_IMAGE=zImage
          ;;
  *)      exit 1
          ;;
esac

sudo -E mkdir -p $WORK_DIR/boot/overlays

sudo -E cp -v arch/$ARCH/boot/$KERNEL_IMAGE        \
              $WORK_DIR/boot/kernel-$KERNEL_RELEASE.img

sudo -E cp -v arch/$ARCH/boot/dts/*.dtb             \
              $WORK_DIR/boot/

sudo -E cp -v arch/$ARCH/boot/dts/overlays/README  \
              $WORK_DIR/boot/overlays/

sudo -E cp -v arch/$ARCH/boot/dts/overlays/*.dtbo* \
              $WORK_DIR/boot/overlays/

sudo -E make INSTALL_MOD_PATH=$WORK_DIR modules_install

(
  cd $WORK_DIR
  sudo tar -jcvf /tmp/$TAR_PRODUCT boot lib
)

sudo chown $USER /tmp/$TAR_PRODUCT
mv -v /tmp/$TAR_PRODUCT ~/
sudo rm -fr $WORK_DIR

exit 0