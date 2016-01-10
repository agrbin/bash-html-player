#!/bin/bash
# ./rebuild_all.sh [number of torrents to simulate finish]
# calls torrent complete script for some/all torrents in torrent download
# directory.

echo see log at tail -f /var/log/transmission-complete.log

FILTER=cat

if [ $# -eq 1 ]; then
  FILTER="head -n$1"
fi

(

root=/var/downloads/torrents/

cd $root;

ls | $FILTER | while read dir; do
  if [ -d "$dir" ]; then
    echo "calling torrent done for $dir"
    sudo -u debian-transmission \
      TR_NO_EMAIL=true TR_TORRENT_DIR=$root TR_TORRENT_NAME="$dir" /etc/transmission-daemon/torrent_done.sh
  fi
done

)
