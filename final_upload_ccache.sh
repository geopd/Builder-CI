#!/bin/bash

cd /tmp

# sorting final zip
ZIP=$(find $(pwd)/rom/out/target/product/sakura/ -maxdepth 1 -name "*sakura*.zip" | perl -e 'print sort { length($b) <=> length($a) } <>' | head -n 1)
ZIPNAME=$(basename ${ZIP})


# final ccache upload
zst_tar ()
{
    tar "-I zstd -1 -T16" -cf $1.tar.zst $1
    rclone copy $1.tar.zst brrbrr:$1/$rom -P
}


# Let session sleep on error for debug
sleep_on_error()
{
 if [ -f $(pwd)/rom/out/target/product/sakura/${ZIPNAME} ]; then
	time zst_tar ccache
 else
	time zst_tar ccache
	sleep 2h
 fi
}

sleep_on_error
