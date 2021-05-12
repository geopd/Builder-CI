#!/bin/bash

tar_zst ()
{
    while true
	do sleep 95m
	time tar "-I zstd -1 -T2" -cf $1.tar.zst $1
	rclone copy --transfers 4 --checkers 8 --drive-chunk-size 512M --stats 1s $1.tar.zst brrbrr:$1/$rom -P
    done
}

cd /tmp
tar_zst ccache
