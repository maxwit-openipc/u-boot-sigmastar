#!/bin/bash -e

OUTPUT=${OUTPUT:-$PWD/output}
XOPT=${XOPT:-V=1}
target_board=$1

count=0
for dts in dts/upstream/arch/arm/boot/dts/*.dts
do
    chip_ids=($(grep -m1 -o '"sstar,infinity.*";' $dts | sed 's/[",;]/ /g'))
    test ${#chip_ids[@]} -ne 2 && continue
    # vendor=${chip_ids[0]}
    family=${chip_ids[1]}

    dtb=$(basename ${dts%.dts})
    soc=$(grep -m1 'sstar,ssc[0-9]\+[a-z]*"' $dts | awk -F ',' '{print $2}' | sed 's/[",;]//g')
    if test -z "$soc"; then
        echo "$dtb: SoC not defined (skipped)"
        echo
        continue
    fi

    board=$(grep -m1 'compatible' $dts | awk -F ',' '{print $2}' | sed 's/[",;]//g')
    test -n "$target_board" -a "$target_board" != $board && continue

    for tc in arm-openipc-linux-musleabi- \
        arm-linux-musleabi- \
        arm-linux-gnueabi- \
        arm-linux- \
        arm-none-eabi-
    do
        for out in $PWD/output $(dirname $PWD)/output $OUTPUT
        do
            path=$out/$soc/host/bin
            if test -e $path/${tc}gcc; then
                toolchain=$path/$tc
                break
            fi
        done

        test -n "$toolchain" && break

        if which ${tc}gcc > /dev/null; then
            toolchain=$tc
            break
        fi
    done

    if [ -z "$toolchain" ]; then
        echo "No toolchain found for $soc!"
        echo "Skip to build u-boot for $board!"
        echo
        continue
    fi

    echo -e "Building u-boot for $board ($family/$soc) ...\n"

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
    make ARCH=arm CROSS_COMPILE=$toolchain DEVICE_TREE=$dtb $XOPT

    ./create_img.sh
    sh make_boot_spi${flash}.sh ${family}
    mv -v BOOT.bin u-boot-${board}.bin

    mkdir -vp $OUTPUT/$soc
    cp -v u-boot-${board}.bin $OUTPUT/$soc/

    count=$((count + 1))
    echo

    test "$target_board" == $board && break
done

echo -e "Total $count boards was built.\n"
