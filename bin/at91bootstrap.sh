#!/bin/bash -e

usage() {
	cat <<EOF
Usage: ${0##*/} .config
EOF
}

trap 'test $? -ne 0 && ( usage && echo "Error: too few arguements!" ) >&2' 0

echo "CONFIG_LOAD_LINUX=y"
echo "CONFIG_LINUX_ZIMAGE=y"
sed -e '/^CONFIG_LINUX_CMDLINE=/s,^[[:alnum:]_]*=,CONFIG_CMDLINE=y\nCONFIG_LINUX_KERNEL_ARG_STRING=,p' \
    -e '/^CONFIG_LINUX_APPEND_CMDLINE=/s,^[[:alnum:]_]*=,CONFIG_APPEND_CMDLINE=,p' \
    -e '/^CONFIG_DTB=/s,^[[:alnum:]_]*=,CONFIG_OF_LIBFDT=,p' \
    -e '/^CONFIG_UBI=/p' \
    -e '/^CONFIG_UBI_SPARE=/p' \
    -e '/^CONFIG_KERNEL_UBI_VOLNAME/s,^[[:alnum:]_]*=,CONFIG_IMG_UBI_VOLNAME=,p' \
    -e '/^CONFIG_KERNEL_SPARE_UBI_VOLNAME/s,^[[:alnum:]_]*=,CONFIG_IMG_SPARE_UBI_VOLNAME=,p' \
    -e '/^CONFIG_DTB_UBI_VOLNAME/s,^[[:alnum:]_]*=,CONFIG_OF_UBI_VOLNAME=,p' \
    -e '/^CONFIG_DTB_SPARE_UBI_VOLNAME/s,^[[:alnum:]_]*=,CONFIG_OF_SPARE_UBI_VOLNAME=,p' \
    -n $1
