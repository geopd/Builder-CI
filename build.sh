#!/bin/bash

mkdir -p /tmp/rom
cd /tmp/rom

HOSTNAME="mysto"

# export sync start time
SYNC_START=$(date +"%s")


git config --global user.name GeoPD
git config --global user.email geoemmanuelpd2001@gmail.com


# Git cookies
echo "${GIT_COOKIES}" > ~/git_cookies.sh
bash ~/git_cookies.sh


# SSH
rclone copy brrbrr:ssh/ssh_ci /tmp
sudo chmod 0600 /tmp/ssh_ci
sudo mkdir ~/.ssh && sudo chmod 0700 ~/.ssh
eval `ssh-agent -s` && ssh-add /tmp/ssh_ci
sudo echo "github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==" >> ~/.ssh/known_hosts


# Tmate session in case of build errors
tmate -S $HOME/.tmate.sock new-session -d
tmate -S $HOME/.tmate.sock wait tmate-ready
echo "$(tmate -S $HOME/.tmate.sock display -p '#{tmate_ssh}')" > ~/.ssh_id


# Rom repo sync & dt ( Add roms and update case functions )
rom_one(){
     repo init --depth=1 --no-repo-verify -u git://github.com/DotOS/manifest.git -b dot11 -g default,-device,-mips,-darwin,-notdefault
     git clone https://${TOKEN}@github.com/geopd/local_manifests -b $rom .repo/local_manifests
     repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all)
     export DOT_OFFICIAL=true
     . build/envsetup.sh && lunch dot_sakura-user
}

rom_two(){
     repo init --depth=1 --no-repo-verify -u https://github.com/Octavi-OS/platform_manifest.git -b maintainers -g default,-device,-mips,-darwin,-notdefault
     git clone https://${TOKEN}@github.com/geopd/local_manifests -b $rom .repo/local_manifests
     repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all)
     wget https://raw.githubusercontent.com/geopd/misc/master/common-vendor.mk && mv common-vendor.mk vendor/gapps/common/common-vendor.mk # temp haxxs
     export OCTAVI_BUILD_TYPE=Official OCTAVI_DEVICE_MAINTAINER=GeoPD
     echo "sakura" >> vendor/octavi/octavi.devices
     . build/envsetup.sh && lunch octavi_sakura-userdebug
}

rom_three(){
     repo init --depth=1 --no-repo-verify -u https://github.com/P-404/platform_manifest -b rippa -g default,-device,-mips,-darwin,-notdefault
     git clone https://${TOKEN}@github.com/geopd/local_manifests -b $rom .repo/local_manifests
     git config --global url.https://source.codeaurora.org.insteadOf git://codeaurora.org
     curl -L http://source.codeaurora.org/platform/manifest/clone.bundle > /dev/null
     sed -i 's/source.codeaurora.org/oregon.source.codeaurora.org/g' .repo/manifests/default.xml
     repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all)
     wget https://raw.githubusercontent.com/geopd/misc/master/gms-vendor.mk && mv gms-vendor.mk vendor/google/gms/gms-vendor.mk
     sed -i '107 i \\t"ccache":  Allowed,' build/soong/ui/build/paths/config.go
     export SELINUX_IGNORE_NEVERALLOWS=true
     export SKIP_ABI_CHECKS=true
     source build/envsetup.sh && lunch p404_sakura-user
}

rom_four(){
     repo init --depth=1 --no-repo-verify -u https://github.com/ResurrectionRemix/platform_manifest.git -b Q -g default,-device,-mips,-darwin,-notdefault
     git clone https://${TOKEN}@github.com/geopd/local_manifests -b $rom .repo/local_manifests
     repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all)
     sed -i '79 i \\t"ccache":  Allowed,' build/soong/ui/build/paths/config.go
     export RR_BUILDTYPE=Official
     . build/envsetup.sh && lunch rr_sakura-userdebug
}

rom_five(){
     repo init --depth=1 --no-repo-verify -u git://github.com/DotOS/manifest.git -b dot11 -g default,-device,-mips,-darwin,-notdefault
     git clone https://${TOKEN}@github.com/geopd/local_manifests -b $rom .repo/local_manifests
     repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all)
     . build/envsetup.sh && lunch dot_sakura-user
}


# setup TG message and build posts
telegram_message() {
	curl -s -X POST "https://api.telegram.org/bot${BOTTOKEN}/sendMessage" -d chat_id="${CHATID}" \
	-d "parse_mode=Markdown" \
	-d text="$1"
}

telegram_build() {
	curl --progress-bar -F document=@"$1" "https://api.telegram.org/bot${BOTTOKEN}/sendDocument" \
	-F chat_id="${CHATID}" \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=Markdown" \
	-F caption="$2"
}


# Branch name & Head commit sha for ease of tracking
commit_sha() {
    for repo in device/xiaomi/sakura vendor/xiaomi kernel/xiaomi/msm8953
    do
	printf "[$(echo $repo | cut -d'/' -f1 )/$(git -C ./$repo/.git rev-parse --short=10 HEAD)]"
    done
}


# Function to be chose based on rom flag in .yml
case "${rom}" in
 "dotOS") rom_one
    ;;
 "OctaviOS") rom_two
    ;;
 "P404") rom_three
    ;;
 "RR") rom_four
    ;;
 "dotOS-TEST") rom_five
    ;;
 *) echo "Invalid option!"
    exit 1
    ;;
esac


# export sync end time and diff with sync start
SYNC_END=$(date +"%s")
SDIFF=$((SYNC_END - SYNC_START))


# Send 'Build Triggered' message in TG along with sync time
telegram_message "
	*🌟 $rom Build Triggered 🌟*
	*Date:* \`$(date +"%d-%m-%Y %T")\`
	*SSH ID:* \`$(cat ~/.ssh_id)\`
	*✅ Sync finished after $((SDIFF / 60)) minute(s) and $((SDIFF % 60)) seconds*"  &> /dev/null


# export build start time
BUILD_START=$(date +"%s")


# setup ccache
export CCACHE_DIR=/tmp/ccache
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
export CCACHE_MAXSIZE=30G
export CCACHE_COMPRESS=true
export CCACHE_COMPRESSLEVEL=3
ccache -z


# Build commands for each roms on basis of rom flag in .yml / an additional full build.log is kept.
case "${rom}" in
 "dotOS") make bacon -j18 2>&1 | tee build.log
    ;;
 "OctaviOS") mka octavi -j18 2>&1 | tee build.log
    ;;
 "P404") m system-api-stubs-docs test-api-stubs-docs && m bacon -j18 2>&1 | tee build.log
    ;;
 "RR") mka bacon -j18 2>&1 | tee build.log
    ;;
 "dotOS-TEST") make bacon -j18 2>&1 | tee build.log
    ;;
 *) echo "Invalid option!"
    exit 1
    ;;
esac


ls -a $(pwd)/out/target/product/sakura/ # show /out contents
BUILD_END=$(date +"%s")
DIFF=$((BUILD_END - BUILD_START))


# sorting final zip ( commonized considering ota zips, .md5sum etc with similiar names  in diff roms)
ZIP=$(find $(pwd)/out/target/product/sakura/ -maxdepth 1 -name "*sakura*.zip" | perl -e 'print sort { length($b) <=> length($a) } <>' | head -n 1)
ZIPNAME=$(basename ${ZIP})
ZIPSIZE=$(du -sh ${ZIP} |  awk '{print $1}')
echo "${ZIP}"



# Post Build finished with Time,duration,md5,size&Tdrive link OR post build_error&trimmed build.log in TG
telegram_post(){
 if [ -f $(pwd)/out/target/product/sakura/${ZIPNAME} ]; then
	rclone copy ${ZIP} brrbrr:rom -P
	MD5CHECK=$(md5sum ${ZIP} | cut -d' ' -f1)
	DWD=${TDRIVE}${ZIPNAME}
	telegram_message "
	*✅ Build finished after $(($DIFF / 3600)) hour(s) and $(($DIFF % 3600 / 60)) minute(s) and $(($DIFF % 60)) seconds*

	*ROM:* \`${ZIPNAME}\`
	*MD5 Checksum:* \`${MD5CHECK}\`
	*Download Link:* [Tdrive](${DWD})
	*Size:* \`${ZIPSIZE}\`

	*Commit SHA:* \`$(commit_sha)\`

	*Date:*  \`$(date +"%d-%m-%Y %T")\`" &> /dev/null
 else
	BUILD_LOG=$(pwd)/build.log
	tail -n 10000 ${BUILD_LOG} >> $(pwd)/buildtrim.txt
	LOG1=$(pwd)/buildtrim.txt
	echo "CHECK BUILD LOG" >> $(pwd)/out/build_error
	LOG2=$(pwd)/out/build_error
	TRANSFER=$(curl --upload-file ${LOG1} https://transfer.sh/$(basename ${LOG1}))
	telegram_build ${LOG2} "
	*❌ Build failed to compile after $(($DIFF / 3600)) hour(s) and $(($DIFF % 3600 / 60)) minute(s) and $(($DIFF % 60)) seconds*
	Build Log: ${TRANSFER}

	_Date:  $(date +"%d-%m-%Y %T")_" &> /dev/null
 fi
}

telegram_post
ccache -s
