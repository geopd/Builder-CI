#!/bin/bash

zst_tar ()
{
    tar "-I zstd -1 -T8" -cf $1.tar.zst $1
}

cd /tmp
zst_tar ccache
rclone copy ccache.tar.zst brrbrr:ccache/$rom -P
