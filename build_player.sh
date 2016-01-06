#!/bin/bash
# ./build_player.sh [videofile]

set -e
echo checking if there is subdb and srt-to-vtt on the system..
which subdb &> /dev/null
which srt-to-vtt &> /dev/null

videopath=$1

# check that videopath has supported extension.
extension="${videopath##*.}"
if echo $extension | tr  '[:upper:]' '[:lower:]' | grep -E '(avi|mp4|mkv)' > /dev/null; then
  echo processing $videopath
else
  echo $videopath has no vaild extension
  exit 1
fi

srtpath=${videopath%.*}.srt
vttpath=${videopath%.*}.vtt
htmlpath=${videopath%.*}.html

relvideo=$(basename $videopath)
relvtt=$(basename $vttpath)

if [ ! -f $srtpath ]; then
  # ignore if subtitle cant be downloaded
  ( subdb download $videopath )
fi

if [ -f $srtpath ]; then
  if [ ! -f $vttpath ]; then
    srt-to-vtt $srtpath > $vttpath
  fi
fi

cat > $htmlpath <<EOF
<!doctype html>
<html>
  <head>
    <style>
      video { width: 100%; }
      html { margin: 0px; width: 100%; height: 100%; }
      body { margin: 0px; }
    </style>
  </head>
  <body>
    <video controls autoplay id="video">
      <source src="$relvideo" type="video/mp4" />
      <track kind="subtitles" src="$relvtt" default />
      <div>
        <strong>Sorry, youll need an HTML5 Video capable browser.</strong>
      </div>
    </video>
  </body>
</html>
EOF
