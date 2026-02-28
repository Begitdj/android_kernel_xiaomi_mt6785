#!/bin/bash



set -e

USER="Begitdj"
HOST="GithubAction"
COMPILER_PATH="$HOME/compiler/clang/bin"

export PATH="$COMPILER_PATH:$PATH"
export KBUILD_BUILD_USER="$USER"
export KBUILD_BUILD_HOST="$HOST"

rm -rf out
mkdir -p out

echo "--- Config ---"
make O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 rosemary_defconfig

if [ -f "./scripts/config" ]; then
    echo "--- Включение KernelSU ---"
    ./scripts/config --file out/.config \
        -e CONFIG_KSU \
        -e CONFIG_KSU_MANUAL_HOOK \
        -e CONFIG_KSU_MANUAL_HOOK_AUTO_SETUID_HOOK \
        -e CONFIG_KSU_MANUAL_HOOK_AUTO_INITRC_HOOK
fi

echo "--- apply ---"
make O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 olddefconfig

echo "--- build ---"
make O=out ARCH=arm64 \
    CC=clang \
    LD=ld.lld \
    AR=llvm-ar \
    NM=llvm-nm \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    STRIP=llvm-strip \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    LLVM=1 \
    LLVM_IAS=0 \
    -j$(nproc) Image.gz dtbs
cat out/arch/arm64/boot/Image.gz out/arch/arm64/boot/dts/mediatek/mt6785.dtb >out/arch/arm64/boot/Image.gz-dtb
