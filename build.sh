#!/bin/bash

mkdir -p /tmp/rom
cd /tmp/rom

git config --global user.name GeoPD
git config --global user.email geoemmanuelpd2001@gmail.com


# Git cookies
echo "${GIT_COOKIES}" > ~/git_cookies.sh
bash ~/git_cookies.sh


# local manifests (vt,kt and hals)
git clone https://${TOKEN}@github.com/geopd/local_manifests .repo/local_manifests


# Rom repo sync & dt ( Add roms and update case functions )
rom_one(){
     repo init --depth=1 --no-repo-verify -u git://github.com/DotOS/manifest.git -b dot11 -g default,-device,-mips,-darwin,-notdefault
     repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all)
     git clone https://${TOKEN}@github.com/geopd/device_xiaomi_sakura_TEST.git -b dot-R device/xiaomi/sakura
     . build/envsetup.sh && lunch dot_sakura-userdebug
}

rom_two(){
     repo init --depth=1 --no-repo-verify -u https://github.com/Octavi-OS/platform_manifest.git -b 11 -g default,-device,-mips,-darwin,-notdefault
     repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all)
     git clone https://${TOKEN}@github.com/geopd/device_xiaomi_sakura_TEST.git -b Octavi-11 device/xiaomi/sakura
     wget https://raw.githubusercontent.com/geopd/misc/master/common-vendor.mk && mv common-vendor.mk vendor/gapps/common/common-vendor.mk # temp haxxs
     sed -i 's/violet/sakura/g' pac*/apps/Set*/src/com/and*/set*/OosAboutPreference.java
     sed -i '10s/Nobody/MYSTO/g' vendor/octavi/config/branding.mk
     rclone copy brrbrr:ic_device_sakura.png pac*/apps/Settings/res/drawable/ -P
     export SKIP_ABI_CHECKS=true
     . build/envsetup.sh && lunch octavi_sakura-userdebug
}


# setup TG message and build posts
telegram_message() {
	curl -s -X POST "https://api.telegram.org/bot${BOTTOKEN}/sendMessage" -d chat_id="${CHATID}" \
	-d "parse_mode=html" \
	-d text="$1"
}

telegram_build() {
	curl --progress-bar -F document=@"$1" "https://api.telegram.org/bot${BOTTOKEN}/sendDocument" \
	-F chat_id="${CHATID}" \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=Markdown" \
	-F caption="$2"
}


# Function to be chose based on rom flag in .yml
case "${rom}" in
 "dotOS") rom_one
    ;;
 "OctaviOS") rom_two
    ;;
 *) echo "Invalid option!"
    exit 1
    ;;
esac


# Send 'Build Triggered' message in TG
telegram_message "<b>🌟 $rom Build Triggered 🌟</b>%0A%0A<b>Date: </b><code>$(date +"%d-%m-%Y %T")</code>"


# export build month and build start time
BUILD_MONTH=$(date +"%Y%m")
BUILD_START=$(date +"%s")


# setup ccache
export CCACHE_DIR=/tmp/ccache
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
ccache -M 50G && ccache -o compression=true && ccache -z


# Build commands for each roms on basis of rom flag in .yml / an additional full build.log is kept.
case "${rom}" in
 "dotOS") make bacon -j18 | tee build.log
    ;;
 "OctaviOS") mka octavi -j18 | tee build.log
    ;;
 *) echo "Invalid option!"
    exit 1
    ;;
esac


ls -a $(pwd)/out/target/product/sakura/ # show /out contents
BUILD_END=$(date +"%s")
DIFF=$((BUILD_END - BUILD_START))


# sorting final zip ( commonized considering ota zips, .md5sum etc with similiar names  in diff roms)
ZIP=$(find $(pwd)/out/target/product/sakura/ -maxdepth 1 -name "*sakura*"${BUILD_MONTH}"*.zip" | perl -e 'print sort { length($b) <=> length($a) } <>' | head -n 1)
ZIPNAME=$(basename ${ZIP})
echo "${ZIP}"


# Post Build finished with Time,duration,md5&Tdrive link OR post build_error&trimmed build.log in TG
telegram_post(){
 if [ -f $(pwd)/out/target/product/sakura/${ZIPNAME} ]; then
	rclone copy ${ZIP} brrbrr:rom -P
	MD5CHECK=$(md5sum ${ZIP} | cut -d' ' -f1)
	DWD=${TDRIVE}${ZIPNAME}
	telegram_message "<b>✅ Build finished after $((DIFF / 3600)) hour(s), $((DIFF % 3600 / 60)) minute(s) and $((DIFF % 60)) seconds</b>%0A%0A<b>ROM: </b><code>${ZIPNAME}</code>%0A%0A<b>MD5 Checksum: </b><code>${MD5CHECK}</code>%0A%0A<b>Download Link: </b><a href='${DWD}'>Tdrive</a>%0A%0A<b>Date: </b><code>$(date +"%d-%m-%Y %T")</code>"
 else
	BUILD_LOG=$(pwd)/build.log
	tail -n 10000 ${BUILD_LOG} >> $(pwd)/buildtrim.txt
	LOG1=$(pwd)/buildtrim.txt
	echo "CHECK BUILD LOG" >> $(pwd)/out/build_error
	LOG2=$(pwd)/out/build_error
	TRANSFER=$(curl --upload-file ${LOG1} https://transfer.sh/$(basename ${LOG1}))
	telegram_build ${LOG2} "*❌ Build failed to compile after $(($DIFF / 3600)) hour(s) and $(($DIFF % 3600 / 60)) minute(s) and $(($DIFF % 60)) seconds*
	Build Log: ${TRANSFER}
	_Date:  $(date +"%d-%m-%Y %T")_"
 fi
}

telegram_post
ccache -s