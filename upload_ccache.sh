#!/bin/bash

tar_zst ()
{
    while true
	do sleep 95m
	time tar "-I zstd -1 -T2" -cf $1.tar.zst $1
	rclone copy --drive-chunk-size 256M --stats 1s $1.tar.zst brrbrr:$1/$rom -P
    done
}

cd /tmp
tar_zst ccache
