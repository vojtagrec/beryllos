#!/usr/bin/env bash

set -euxo pipefail

# Compile it87-extras kernel module

KERNEL="$(rpm -q 'kernel' --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
KVERSION="$(echo "$KERNEL" | cut -d'.' -f1-3)"

curl -L -O "https://github.com/bazzite-org/kernel-bazzite/releases/download/${KVERSION}/kernel-devel-${KERNEL}.rpm"
ls -lh "kernel-devel-${KERNEL}.rpm"
dnf5 -y install "kernel-devel-${KERNEL}.rpm"
dnf5 -y group install development-tools

git clone https://github.com/grandpares/it87.git
cd it87

make TARGET="$KERNEL" clean
make TARGET="$KERNEL" modules

"/usr/src/kernels/$KERNEL/scripts/sign-file" sha256 /tmp/beryllos/kmod.priv /tmp/beryllos/kmod.der it87-extras.ko
xz -C crc32 it87-extras.ko
modinfo "it87-extras.ko.xz" > /dev/null || exit 1

echo 'it87-extras' > it87-extras.conf

mkdir -p /output
install -Dm644 it87-extras.ko.xz "/output/usr/lib/modules/${KERNEL}/extra/it87-extras/it87-extras.ko.xz"
install -Dm644 /tmp/beryllos/kmod.der /output/etc/pki/beryllos/certs/kmod.der
install -Dm644 it87-extras.conf /output/usr/lib/modules-load.d/it87-extras.conf
