#!/bin/bash
# ./build_player.sh directory
# before attaching this script to torrent-finish try running it manually
# Dependencies:
#   npm install -g srt2vtt
#   pip install sublinimal

SUBLINIMAL_CACHE=/var/downloads/subliminal-cache/
THROTTLE_DOWNLOAD_SLEEP_S=1
LANGUAGES="en hr"

if [ ! -z "$DEV" ]; then
  SUBLINIMAL_CACHE=$HOME/.subliminal-cache/
  THROTTLE_DOWNLOAD_SLEEP_S=0
fi

export PATH="$PATH:/usr/local/bin"

SRT2VTT="node /usr/local/lib/node_modules/srt2vtt/bin/convert.js"

function main {
  run_for_dir "$1" "$2"
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
  build_video_index "$dir"
}

function echo_track_elem {
  relpath="$1"
  label="$2"

  if [ -f "$relpath" ]; then
    echo "<td><a href=\"$relpath\"> [$label] </a></td>"
  fi
}

function build_video_index {
  dir=$1
  OUT="+video_index.html"
  (
    cd "$dir"
    echo building video index to "$dir"/$OUT..
    cat > "$OUT" <<EOF
<!doctype html>
<html>
  <head>
    <style>
      th { text-align: left; }
    </style>
  </head>
  <body>
    <table>
EOF
    find . -iregex '.*\(avi\|mp4\|mkv\)$' -type f | while read relpath; do
      videobase=${relpath%.*}

      echo "<tr>" >> "$OUT"
      echo "<th>$(basename "$relpath")</th>" >> "$OUT"

      echo_track_elem "$relpath" "download video" >> "$OUT"
      echo_track_elem "$videobase.en.html" "play en" >> "$OUT"
      echo_track_elem "$videobase.hr.html" "play hr" >> "$OUT"
      echo_track_elem "$videobase.en.srt" "download en srt" >> "$OUT"
      echo_track_elem "$videobase.hr.srt" "download hr srt" >> "$OUT"
      echo_track_elem "$videobase.srt" "download torrent srt" >> "$OUT"

      echo "</tr>" >> "$OUT"
    done
    cat >> "$OUT" <<EOF
  </table>
</body>
</html>
EOF
  )
}

# this function echoes 1 if html was built.
function build_for_movie_lang {
  videopath="$1"
  lang="$2"

  videobase=${videopath%.*}
  srtpath="$videobase.$lang.srt"
  vttpath="$videobase.$lang.vtt"
  htmlpath=$videobase.$lang.html

  # download subtitles
  if [ ! -f "$srtpath" ]; then
    subliminal --cache-dir=$SUBLINIMAL_CACHE \
      download --force --language=en "$videopath" &> /dev/null
  fi

  if [ ! -f "$srtpath" ]; then
    return
  fi

  # convert subtitles to vtt
  if [ ! -f "$vttpath" ]; then
    $SRT2VTT < "$srtpath"  > "$vttpath"
  fi

  relvideo=$(basename "$videopath")
  relvtt=$(basename "$videobase").$lang.vtt
  echo subtitles found for $lang

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
}

# build_for_movie videofile
# tries to download subtitles for a movie and builds a .html player.
function build_for_movie {
  videopath="$1"
  echo processing $(basename "$videopath") ..

  # throttle download
  sleep $THROTTLE_DOWNLOAD_SLEEP_S

  # convert subittles and add to html.
  for lang in $LANGUAGES; do
    build_for_movie_lang "$videopath" "$lang"
  done
  echo
}

main "$1"
