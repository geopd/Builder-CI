#!/bin/bash

mkdir -p /tmp/rom
cd /tmp/rom

git config --global user.name GeoPD
git config --global user.email geoemmanuelpd2001@gmail.com

export rom=OctaviOS

rom_one(){
 repo init --depth=1 --no-repo-verify -u git://github.com/DotOS/manifest.git -b dot11 -g default,-device,-mips,-darwin,-notdefault
 schedtool -B -n 0 -e ionice -n 0 `which repo` sync --no-tags --no-clone-bundle --force-sync --optimized-fetch -q -j18 "$@"
 git clone https://${TOKEN}@github.com/geopd/device_xiaomi_sakura_TEST.git -b dot-11 device/xiaomi/sakura
 git clone https://${TOKEN}@github.com/geopd/vendor_xiaomi_sakura_TEST.git -b lineage-18.0 vendor/xiaomi
 . build/envsetup.sh && lunch dot_sakura-userdebug
}

rom_two(){
 repo init --depth=1 --no-repo-verify -u https://github.com/Evolution-X/manifest -b elle -g default,-device,-mips,-darwin,-notdefault
 schedtool -B -n 0 -e ionice -n 0 `which repo` sync --no-tags --no-clone-bundle --force-sync --optimized-fetch -q -j18 "$@"
 git clone https://${TOKEN}@github.com/geopd/device_xiaomi_sakura_TEST.git -b elle device/xiaomi/sakura
 git clone https://${TOKEN}@github.com/geopd/vendor_xiaomi_sakura_TEST.git -b lineage-18.0 vendor/xiaomi
 rm -rf vendor/gms && git clone https://gitlab.com/geopdgitlab/vendor_gapps -b eleven vendor/gms
 . build/envsetup.sh && lunch evolution_sakura-userdebug
}

rom_three(){
 repo init --depth=1 --no-repo-verify -u git://github.com/DotOS/manifest.git -b dot11 -g default,-device,-mips,-darwin,-notdefault
 schedtool -B -n 0 -e ionice -n 0 `which repo` sync --no-tags --no-clone-bundle --force-sync --optimized-fetch -q -j18 "$@"
 git clone https://${TOKEN}@github.com/geopd/device_xiaomi_sakura_TEST.git -b dot-R device/xiaomi/sakura
 git clone https://${TOKEN}@github.com/geopd/vendor_xiaomi_sakura_TEST.git -b lineage-18.1 vendor/xiaomi
 rm -rf hardware/qcom-caf/msm8996/audio hardware/qcom-caf/msm8996/display hardware/qcom-caf/msm8996/media
 git clone https://github.com/Jabiyeff-Project/android_hardware_qcom_audio -b 11.0 hardware/qcom-caf/msm8996/audio
 git clone https://github.com/Jabiyeff-Project/android_hardware_qcom_display -b 11.0 hardware/qcom-caf/msm8996/display
 git clone https://github.com/Jabiyeff-Project/android_hardware_qcom_media -b 11.0 hardware/qcom-caf/msm8996/media
 . build/envsetup.sh && lunch dot_sakura-userdebug
}

rom_four(){
 repo init --depth=1 --no-repo-verify -u https://github.com/Octavi-OS/platform_manifest.git -b 11 -g default,-device,-mips,-darwin,-notdefault
 schedtool -B -n 0 -e ionice -n 0 `which repo` sync --no-tags --no-clone-bundle --force-sync --optimized-fetch -q -j18 "$@"
 git clone https://${TOKEN}@github.com/geopd/device_xiaomi_sakura_TEST.git -b Octavi-11 device/xiaomi/sakura
 git clone https://${TOKEN}@github.com/geopd/vendor_xiaomi_sakura_TEST.git -b lineage-18.1 vendor/xiaomi
 rm -rf hardware/qcom-caf/msm8996/audio hardware/qcom-caf/msm8996/display hardware/qcom-caf/msm8996/media
 git clone https://github.com/Jabiyeff-Project/android_hardware_qcom_audio -b 11.0 hardware/qcom-caf/msm8996/audio
 git clone https://github.com/Jabiyeff-Project/android_hardware_qcom_display -b 11.0 hardware/qcom-caf/msm8996/display
 git clone https://github.com/Jabiyeff-Project/android_hardware_qcom_media -b 11.0 hardware/qcom-caf/msm8996/media
 git clone https://bitbucket.org/syberia-project/external_motorola_faceunlock -b 11.0 external/motorola/faceunlock
 git clone https://github.com/LineageOS/android_vendor_qcom_opensource_healthd-ext -b lineage-18.1 vendor/qcom/opensource/healthd-ext
 sed -i '677s/private int mTorchActionMode;//g' fra*/ba*/ser*/cor*/ja*/com/and*/ser*/pol*/PhoneWindowManager.java # for the betterment of society1
 export SKIP_ABI_CHECKS=true # for the betterment of society2
 . build/envsetup.sh && lunch octavi_sakura-userdebug
}

git clone https://${TOKEN}@github.com/geopd/kernel_xiaomi_msm8953 -b test kernel/xiaomi/msm8953 
git clone https://github.com/geopd/vendor_custom_prebuilts -b master vendor/custom/prebuilts
git clone https://github.com/mvaisakh/gcc-arm64.git -b gcc-master prebuilts/gcc/linux-x86/aarch64/aarch64-elf

echo "${GIT_COOKIES}" > ~/git_cookies.sh
bash ~/git_cookies.sh

case "${rom}" in
 "dotOS") rom_one
    ;;
 "EvolutionX") rom_two
    ;;
 "dotOS-R") rom_three
    ;;
 "OctaviOS") rom_four
    ;;
 *) echo "Invalid option!"
    exit 1
    ;;
esac

BUILD_DATE=$(date +"%Y%m%d")
BUILD_START=$(date +"%s")

telegram_message() {
    curl -s -X POST "https://api.telegram.org/bot${BOTTOKEN}/sendMessage" -d chat_id="${CHATID}" \
    -d "parse_mode=html" \
    -d text="$1"
}

telegram_message "<b>🌟 $rom Build Triggered 🌟</b>%0A%0A<b>Date: </b><code>$(date +"%d-%m-%Y %T")</code>"

export CCACHE_DIR=/tmp/ccache
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
ccache -M 50G && ccache -z

case "${rom}" in
 "dotOS") make bacon -j18
    ;;
 "EvolutionX") mka bacon -j18
    ;;
 "dotOS-R") make bacon -j18
    ;;
 "OctaviOS") mka octavi -j18
    ;;
 *) echo "Invalid option!"
    exit 1
    ;;
esac

ls -a $(pwd)/out/target/product/sakura/

BUILD_END=$(date +"%s")
DIFF=$((BUILD_END - BUILD_START))
ZIP=$(find $(pwd)/out/target/product/sakura/ -name "*sakura*"${BUILD_DATE}"*.zip" | perl -e 'print sort { length($b) <=> length($a) } <>' | head -n 1)

telegram_build() {
 curl --progress-bar -F document=@"$1" "https://api.telegram.org/bot${BOTTOKEN}/sendDocument" \
 -F chat_id="${CHATID}" \
 -F "disable_web_page_preview=true" \
 -F "parse_mode=Markdown" \
 -F caption="$2"
}

telegram_post(){
 if [ -f ${ZIP} ]; then
	rclone copy ${ZIP} brrbrr:rom -P
	MD5CHECK=$(md5sum ${ZIP} | cut -d' ' -f1)
	ZIPNAME=$(echo ${ZIP} | cut -s -d'/' -f2)
	DWD=${TDRIVE}${ZIPNAME}
	telegram_message "<b>✅ Build finished after $((DIFF / 3600)) hour(s), $((DIFF % 3600 / 60)) minute(s) and $((DIFF % 60)) seconds</b>%0A%0A<b>ROM: </b><code>${ZIPNAME}</code>%0A%0A<b>MD5 Checksum: </b><code>${MD5CHECK}</code>%0A%0A<b>Download Link: </b><a href='${DWD}'>${DWD}</a>%0A%0A<b>Date: </b><code>$(date +"%d-%m-%Y %T")</code>"
 else
	LOG="$(echo "$(pwd)/out/build_error")"
	telegram_build ${LOG} "*❌ Build failed to compile after $(($DIFF / 3600)) hour(s) and $(($DIFF % 3600 / 60)) minute(s) and $(($DIFF % 60)) seconds*
	_Date:  $(date +"%d-%m-%Y %T")_"
 fi
}

telegram_post
ccache -s
