#!/usr/bin/env bash

if [ $# -gt 0 ]; then
	board_list=$1
else
	board_list="
	tc2101
	ssc337-nor
	ssc335-nor
	ssc333-nor
	ssc335de-nor
	ssc337de-nor
	ssc337de-nand
	"
fi

test -z $OUTPUT && OUTPUT=output

rm -vf $OUTPUT/u-boot*
mkdir -p $OUTPUT

if [ -z "$TOOLCHAIN" ]; then
	for t in arm-linux-gnueabi- arm-none-eabi-
	do
		if which ${t}gcc > /dev/null; then
			TOOLCHAIN=$t
			break
		fi
	done
fi

if [ -z $TOOLCHAIN ]; then
	echo "No toolchain found!"
	exit 1
fi

for board in $board_list
do
	image=u-boot-${board}.bin

	echo "Building '${image}' with '$TOOLCHAIN'"
	echo "======================================="

	case $board in
		ssc325-*|ssc325de-*)
			family=infinity6
			;;
		ssc333-*|ssc335-*|ssc337-*|ssc335de-*|ssc337de-*|tc2101)
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
			defconf=${family}_spinand_defconfig
			;;
		*)
			flash=nor
			defconf=${family}_defconfig
			;;
	esac

	make distclean
	make ARCH=arm $defconf
	make ARCH=arm CROSS_COMPILE=$TOOLCHAIN DEVICE_TREE=$board -j$(nproc) || exit 1

	./create_img.sh
	sh make_boot_spi${flash}.sh ${family}
	mv BOOT.bin $OUTPUT/$image

	echo
done
