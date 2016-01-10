# bash-html-player

Scripts to download subtitles and create a html5 video player for a movie.

This is used as a torrent finish script with transmission. After each torrent
ins downloaded, the `build_player.sh` inspects video files, tries to download
subtitles and builds an HTML page that contains a player that can play the
video and subtitles.

The index html file with all video files in directory and links is also
created.

```name=torrent_done.sh
LOG=/var/log/transmission-complete.log
TR_DOWNLOADED_PATH="$TR_TORRENT_DIR/$TR_TORRENT_NAME"

echo torrent complete: $TR_DOWNLOADED_PATH >> $LOG
build_player.sh "$TR_DOWNLOADED_PATH" >> $LOG
```



```name=settings.json
  ...
  "script-torrent-done-enabled": true,
  "script-torrent-done-filename": "/etc/transmission-daemon/torrent_done.sh",
  ...
```
