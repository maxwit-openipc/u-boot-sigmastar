#!/usr/bin/env bash

if [ -z "$TOOLCHAIN" ]; then
	for t in arm-none-eabi- arm-linux-gnueabi- arm-linux-gnueabihf-
	do
		if which ${t}gcc > /dev/null; then
			TOOLCHAIN=$t
			break
		fi
	done
fi

rm -rf output
mkdir -p output

# dts_path=../output/ssc337/build/linux-custom/arch/arm/boot/dts
# board=infinity6b0-ssc009a-s01a

if [ $# -gt 0 ]; then
	board_list=$1
else
	board_list="ssc325-nor
	ssc325de-nand
	ssc333-nor
	ssc335-nor
	ssc337-nor
	ssc335de-nor
	ssc337de-nor
	ssc377-nor
	ssc377d-nor
	ssc377de-nor
	ssc377de-nand
	ssc377qe-nor
	ssc378de-nor
	ssc378qe-nor
	ssc30kd-nor
	ssc30kq-nor
	ssc338q-nor
	ssc338q-nand
	"
fi

for board in $board_list
do
	image=u-boot-${board}.bin
	echo "Building '${image}'"
	echo "    with '$TOOLCHAIN'"
	echo "==============="

	case $board in
		ssc325-*|ssc325de-*)
			family=infinity6
			;;
		ssc333-*|ssc335-*|ssc337-*|ssc335de-*|ssc337de-*)
			family=infinity6b0
			;;
		ssc377-*|ssc377d-*|ssc377de-*|ssc377qe-*|ssc378de-*|ssc378qe-*)
			family=infinity6c
			;;
		ssc30kd-*|ssc30kq-*|ssc338q-*)
			family=infinity6e
			;;
		*)
			echo "Unknown board: $board"
			exit 1
			;;
	esac

	case $board in
		*-nand)
			flash=nand
			;;
		*)
			flash=nor
			;;
	esac

	make distclean
	make ARCH=arm ${board}_defconfig
	make ARCH=arm CROSS_COMPILE=$TOOLCHAIN -j8 || exit 1

	./create_img.sh
	sh make_boot_spi${flash}.sh ${family}
	mv BOOT.bin output/$image

	echo
done
