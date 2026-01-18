#!/usr/bin/env bash

set -euxo pipefail

# Compile it87-extras kernel module

KERNEL="$(rpm -q 'kernel' --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
KERNEL_DIR="/lib/modules/${KERNEL}"
BUILD_DIR="${KERNEL_DIR}/build"

dnf5 -y install "kernel-devel-${KERNEL}"
dnf5 -y group install development-tools

cp /tmp/beryllos/kmod.priv "${BUILD_DIR}/certs/signing_key.pem"
cp /tmp/beryllos/kmod.der "${BUILD_DIR}/certs/signing_key.x509"

git clone https://github.com/grandpares/it87.git
cd it87 || exit 1

VERSION=$(git show -s --format='%h (%cs)' HEAD)

# Silence warnings caused by broken version detection in grandpares/it87
touch VERSION
rm -rf .git

make -C "$BUILD_DIR" TARGET="$KERNEL" M="$PWD" clean
make -C "$BUILD_DIR" \
    CFLAGS_it87.o="'-DIT87_DRIVER_VERSION=\"${VERSION}\"'" \
    TARGET="$KERNEL" M="$PWD" modules

modinfo "it87-extras.ko" > /dev/null || exit 1

make -C "$BUILD_DIR" \
    INSTALL_MOD_DIR="updates" \
    CONFIG_MODULE_SIG_KEY="certs/signing_key.pem" \
    CONFIG_MODULE_COMPRESS_ALL=y \
    TARGET="$KERNEL" M="$PWD" modules_install

modinfo "${KERNEL_DIR}/updates/it87-extras.ko.xz" \
    | grep 'sig_key:' | grep -q '37:2C:8D:D7:3B:92:A2:46:09:FA:62:83:C5:8E:F9:FF:5C:E7:B0:B1' || exit 1

# Remove certificates
rm "${BUILD_DIR}/certs/signing_key.pem" "${BUILD_DIR}/certs/signing_key.x509"

#find "${KERNEL_DIR}" -print 1>&2

mkdir -p /modules

VERFILE=$(realpath VERSION)

# Copy updated files from /lib/modules to /modules
cd /lib/modules
find . -newermm "$VERFILE" -type d | cpio -pdm /modules/
find . -newermm "$VERFILE" -type f -exec cp -pd --parents "{}" /modules/ \;

#find /modules -print 1>&2
