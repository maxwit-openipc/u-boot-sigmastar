#!/usr/bin/env bash

if [ -z "$TOOLCHAIN" ]; then
	for t in arm-linux-gnueabi- arm-none-eabi-
	do
		if which ${t}gcc > /dev/null; then
			TOOLCHAIN=$t
			break
		fi
	done
fi

rm -rf output
mkdir -p output

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
	ssc30kd-nor
	ssc30kq-nor
	ssc338q-nor
	ssc338q-nand
	ssc325-nor
	ssc325de-nand
	"
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

	# case $board in
	# 	ssc30kd-*|ssc30kq-*|ssc338q-*)
	# 		dtb_name="infinity6e-ssc012b-s01a"
	# 		;;
	# 	ssc377de-*|ssc377qe-*|ssc378de-*|ssc378qe-*)
	# 		dtb_name="infinity6c-ssc027d-s01a"
	# 		;;
	# 	ssc377-*|ssc377d-*)
	# 		dtb_name="infinity6c-ssc027a-s01a"
	# 		;;
	# 	ssc335de-*|ssc337de-*)
	# 		dtb_name="infinity6b0-ssc009b-s01a"
	# 		;;
	# 	ssc333-*|ssc335-*|ssc337-*)
	# 		dtb_name="infinity6b0-ssc009a-s01a"
	# 		;;
	# 	ssc325de-*)
	# 		dtb_name="infinity6-ssc009b-s01a"
	# 		;;
	# 	ssc325-*)
	# 		dtb_name="infinity6-ssc009a-s01a"
	# 		;;
	# 	tc2101)
	# 		dtb_name=""
	# 		;;
	# 	*)
	# 		echo "No dts for board $board"
	# 		exit 1
	# 		;;
	# esac

	# if [ -z "$dtb_name" ]; then
	# 	continue
	# else
	# 	echo cp -v dts/upstream/arch/arm/boot/dts/${dtb_name}.dts dts/upstream/arch/arm/boot/dts/${board}.dts
	# 	cp -v dts/upstream/arch/arm/boot/dts/${dtb_name}.dts dts/upstream/arch/arm/boot/dts/${board}.dts
	# 	continue
	# fi

	make distclean
	make ARCH=arm $defconf
	make ARCH=arm CROSS_COMPILE=$TOOLCHAIN DEVICE_TREE=$board -j$(nproc) || exit 1

	./create_img.sh
	sh make_boot_spi${flash}.sh ${family}
	mv BOOT.bin output/$image


	echo
done
