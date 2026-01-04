#!/usr/bin/env bash

set -euxo pipefail

# Compile it87-extras kernel module

KERNEL="$(uname -r)"

dnf5 -y install "kernel-devel-${KERNEL}"
dnf5 -y group install development-tools

cp /tmp/beryllos/kmod.priv "/lib/modules/${KERNEL}/build/certs/signing_key.pem"
cp /tmp/beryllos/kmod.der "/lib/modules/${KERNEL}/build/certs/signing_key.x509"

git clone https://github.com/grandpares/it87.git
cd it87 || exit 1

VERSION=$(git show -s --format='%h (%cs)' HEAD)

# Silence warnings caused by broken version detection in grandpares/it87
touch VERSION
rm -rf .git

make -C "/lib/modules/${KERNEL}/build" TARGET="$KERNEL" M="$PWD" clean
make -C "/lib/modules/${KERNEL}/build" \
    CFLAGS_it87.o="'-DIT87_DRIVER_VERSION=\"${VERSION}\"'" \
    TARGET="$KERNEL" M="$PWD" modules

modinfo "it87-extras.ko" > /dev/null || exit 1

make -C "/lib/modules/${KERNEL}/build" \
    INSTALL_MOD_DIR="updates" \
    CONFIG_MODULE_SIG_KEY="certs/signing_key.pem" \
    CONFIG_MODULE_COMPRESS_ALL=y \
    TARGET="$KERNEL" M="$PWD" modules_install

modinfo "/lib/modules/${KERNEL}/updates/it87-extras.ko.xz" \
    | grep 'sig_key:' | grep -q '37:2C:8D:D7:3B:92:A2:46:09:FA:62:83:C5:8E:F9:FF:5C:E7:B0:B1' || exit 1

#ls -lah "/lib/modules/${KERNEL}" 1>&2

mkdir -p /modules
cp -rp "/lib/modules/${KERNEL}" "/modules/"
