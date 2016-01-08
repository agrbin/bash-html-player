#!/bin/bash

echo see log at tail -f /var/log/transmission-complete.log

(

root=/var/downloads/torrents/

cd $root;

ls | while read dir; do
  if [ -d "$dir" ]; then
    echo "calling torrent done for $dir"
    sudo -u debian-transmission \
      TR_TORRENT_DIR=$root TR_TORRENT_NAME="$dir" /etc/transmission-daemon/torrent_done.sh
  fi
done

)
