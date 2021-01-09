#!/usr/bin/env bash
echo "Cloning dependencies"
git clone --depth=1 https://github.com/imjyotiraditya/NotKernel -b x3-10 kernel
cd kernel
git clone --depth=1 https://github.com/kdrag0n/proton-clang clang
git clone --depth=1 https://github.com/imjyotiraditya/AnyKernel3 AnyKernel
echo "Done"
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
DTBO=$(pwd)/out/arch/arm64/boot/dtbo.img
TANGGAL=$(date +"%F-%S")
START=$(date +"%s")
CLANG_VERSION=$(clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
export CONFIG_PATH=$PWD/arch/arm64/configs/vendor/sm8150-perf_defconfig
PATH="${PWD}/clang/bin:$PATH"
export LD="clang/bin/ld.lld"
export ARCH=arm64
export KBUILD_BUILD_HOST=notkernel
export KBUILD_BUILD_USER="Panda"
# sticker plox
function sticker() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendSticker" \
        -d sticker="CAADBQADVAADaEQ4KS3kDsr-OWAUFgQ" \
        -d chat_id=$chat_id
}
# Send info plox channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>• NotKernel •</b>%0ABuild started on <code>Circle CI/CD</code>%0A <b>For device</b> <i>Realme X3 (rmx2081)</i>%0A<b>branch:-</b> <code>$(git rev-parse --abbrev-ref HEAD)</code>(master)%0A<b>Under commit</b> <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0A<b>Using compiler:- </b> <code>$CLANG_VERSION</code>%0A<b>Started on:- </b> <code>$(date)</code>%0A<b>Build Status:</b> #Test"
}
# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Realme X3 (rmx2081)</b> | <b>$CLANG_VERSION</b>"
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
    exit 1
}
# Compile plox
function compile() {
   make O=out ARCH=arm64 vendor/sm8150-perf_defconfig
   make -j$(nproc --all) Image.gz-dtb dtbo.img O=out \
                         ARCH=arm64 \
                         TARGET_PRODUCT=msmnile \
                         PROJECT_NAME=19696 \
			 CC=clang \
			 LD=ld.lld \
                         AR=llvm-ar \
                         NM=llvm-nm \
                         OBJCOPY=llvm-objcopy \
                         OBJDUMP=llvm-objdump \
                         STRIP=llvm-strip \
			 CROSS_COMPILE=aarch64-linux-gnu- \
			 CROSS_COMPILE_ARM32=arm-linux-gnueabi-

if [ `ls "$IMAGE" 2>/dev/null | wc -l` != "0" ]
then
   cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
   cp out/arch/arm64/boot/dtbo.img AnyKernel
else
   finerr
fi
}
# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 NotKernel-X3-${TANGGAL}.zip *
    cd ..
}
sendinfo
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
