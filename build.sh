#!/usr/bin/env bash

if [ $# -gt 0 ]; then
    board_list=$1
else
    board_list="
        tc2101
        sap1540
        ssc337-nor
        ssc335-nor
        ssc333-nor
        ssc335de-nor
        ssc337de-nor
        ssc337de-nand
        "
fi

OUTPUT=${OUTPUT:-output}
XOPT=${XOPT:-V=1}

if [ -z "$TOOLCHAIN" ]; then
    for t in arm-openipc-linux-musleabihf- arm-linux- arm-none-eabi-
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
    case $board in
        ssc325-*)
            soc=ssc325
            ;;
        ssc325de-*)
            soc=ssc325de
            ;;
        ssc333-*)
            soc=ssc333
            ;;
        ssc335-*)
            soc=ssc335
            ;;
        ssc337-* | tc2101 | sap1540)
            soc=ssc337
            ;;
        ssc335de-*)
            soc=ssc335de
            ;;
        ssc337de-*)
            soc=ssc337de
            ;;
        ssc377-*)
            soc=ssc377
            ;;
        ssc377d-*)
            soc=ssc377d
            ;;
        ssc377de-*)
            soc=ssc377de
            ;;
        ssc377qe-*)
            soc=ssc377qe
            ;;
        ssc378de-*)
            soc=ssc378de
            ;;
        ssc378qe-*)
            soc=ssc378qe
            ;;
        ssc30kd-*)
            soc=ssc30kd
            ;;
        ssc30kq-*)
            soc=ssc30kq
            ;;
        ssc338q-*)
            soc=ssc338q
            ;;
        *)
            echo "Unsupported board '$board'"
            exit 1
            ;;
    esac

    case $soc in
        ssc325 | ssc325de)
            family=infinity6
            ;;
        ssc333 | ssc335 | ssc337 | ssc335de | ssc337de)
            family=infinity6b0
            ;;
        ssc377 | ssc377d | ssc377de | ssc377qe | ssc378de | ssc378qe)
            family=infinity6c
            ;;
        ssc30kd | ssc30kq | ssc338q)
            family=infinity6e
            ;;
        *)
            echo "Unknown SoC '$soc'"
            exit 1
            ;;
    esac

    echo "Building u-boot for $board ($soc) ..."

    case $board in
        *-nand)
            flash=nand
            defconfig=${family}_spinand_defconfig
            ;;
        *)
            flash=nor
            defconfig=${family}_defconfig
            ;;
    esac

    make distclean
    make ARCH=arm $defconfig
    make ARCH=arm CROSS_COMPILE=$TOOLCHAIN DEVICE_TREE=$board $XOPT || exit 1

    ./create_img.sh || exit 1
    sh make_boot_spi${flash}.sh ${family}
    mkdir -vp $OUTPUT/$soc
    mv -v BOOT.bin $OUTPUT/$soc/u-boot-${board}.bin

    echo
done
