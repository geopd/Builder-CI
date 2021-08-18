#!/bin/bash

echo $(date +"%d-%m-%Y %T")

ccache_download ()
{
  mkdir -p ~/.config/rclone
  echo "$rc_conf" > ~/.config/rclone/rclone.conf
  rclone copy brrbrr:ccache/$rom/ccache.tar.zst /tmp -P
  tar -xaf ccache.tar.zst
  tar "-I zstd -1 -T8" -xf ccache.tar.zst
  rm -rf ccache.tar.zst
}

cd /tmp
ccache_download


# ccache configuration settings
cat > /tmp/ccache/ccache.conf <<EOF
max_size = 50.0G
compression = true
compression_level = 1
limit_multiple = 0.9
EOF

echo "CCACHE IS CONFIGURED"
echo $(date +"%d-%m-%Y %T")
