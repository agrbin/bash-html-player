#!/bin/bash
# ./build_player.sh directory
# before attaching this script to torrent-finish try running it manually
# Dependencies:
#   npm install -g srt-to-vtt
#   pip install guessit
#   pip install sublinimal
SUBLINIMAL_CACHE=/var/downloads/subliminal-cache/

function main {
  check_deps
  run_for_dir "$1"
}

function run_for_dir {
  dir="$1"
  if [ ! -d "$dir" ]; then
    echo "$dir should be a dir."
    exit 1
  fi
  find "$dir" -iregex '.*\(avi\|mp4\|mkv\)$' -type f | while read videopath; do
    build_for_movie "$videopath"
  done
}

function check_deps {
  echo -ne checking if there is sublinimal and srt-to-vtt on the system...
  which subliminal &> /dev/null || exit 1
  which srt-to-vtt &> /dev/null || exit 1
  echo ok
}

# build_for_movie videofile
# tries to download subtitles for a movie and builds a .html player.
function build_for_movie {
  videopath="$1"

  srtpath=${videopath%.*}.srt
  vttpath=${videopath%.*}.vtt
  htmlpath=${videopath%.*}.html
  txtpath=${videopath%.*}.txt

  relvideo=$(basename "$videopath")
  relvtt=$(basename "$vttpath")

  echo processing $relvideo..

  # extract some information from video
  guessit "$videopath" > "$txtpath"

  if [ ! -f "$srtpath" ]; then
    # ignore if subtitle cant be downloaded
    # throttle download
    sleep 3
    echo downloading subtitles..
    subliminal --cache-dir=$SUBLINIMAL_CACHE \
      download --force --language=en --single "$videopath" &> /dev/null
  fi

  if [ -f "$srtpath" ]; then
    echo subtitles found. converting to vtt..
    if [ ! -f "$vttpath" ]; then
      srt-to-vtt "$srtpath" > "$vttpath"
    fi
  else
    echo no subtitles found.
  fi

  cat > "$htmlpath" <<EOF
  <!doctype html>
  <html>
    <head>
      <style>
        video { width: 100%; height: 100%; }
        html { margin: 0px; }
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
  echo html created.
  echo
  return $retval
}

main "$1"
