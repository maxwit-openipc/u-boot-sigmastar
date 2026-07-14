#!/usr/bin/env bash

if [ ! -e .config ]; then
  echo "'.config' does not exist!"
  exit 1
fi

# FIXME
source .config

if [ -z "$CONFIG_OF_SEPARATE" ]; then
  uboot_bin=u-boot.bin
else
  uboot_bin=u-boot-dtb.bin
fi

rm -f $uboot_bin.xz
xz -z -k $uboot_bin
if [ $uboot_bin != u-boot.bin ]; then
  mv -v $uboot_bin.xz u-boot.bin.xz
fi

ms_ver="$(strings -a -T binary u-boot.bin | grep 'MVX' | grep 'UBT1501' | sed 's/\\*MVX/MVX/g' | cut -c 1-32)"
ld_addr=$(gdb u-boot -ex 'p/x uboot_ld_addr' -ex 'quit' | grep '${CONFIG_IMAGE_POSTFIX}' | cut -d' ' -f3)
ep_addr=$(gdb u-boot -ex 'p/x uboot_ep_addr' -ex 'quit' | grep '${CONFIG_IMAGE_POSTFIX}' | cut -d' ' -f3)

#out_file=u-boot.img.bin
out_file_xz=u-boot${CONFIG_IMAGE_POSTFIX}.xz.img.bin
out_file=u-boot${CONFIG_IMAGE_POSTFIX}.img.bin
if [ `echo $ms_ver | grep -c "MVX1S" ` -gt 0 ];then
  out_file_xz=u-boot_S.xz.img.bin
fi

echo ""
echo $out_file_xz
#echo ./mkimage -A arm -O u-boot -C xz -a "$ld_addr" -e "$ep_addr" -n "$(echo $ms_ver)" -d u-boot.bin.xz "$out_file_xz"
./mkimage -A arm -O u-boot -C lzma -a "$ld_addr" -e "$ep_addr" -n "$ms_ver" -d u-boot.bin.xz "$out_file_xz"
rm -Rf u-boot.bin.xz
echo ""

outsize=$(stat -c %s $out_file_xz)
if [ "$CONFIG_IMAGE_POSTFIX" != _spinand -a  "$outsize" -gt $((128 << 10)) ]; then
	echo "$out_file_xz size is to large ($((outsize>>10))K > 128K)!"
	exit 1
fi
