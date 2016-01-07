#!/bin/bash
# ./build_player.sh directory
# before attaching this script to torrent-finish try running it manually
# Dependencies:
#   npm install -g srt-to-vtt
#   pip install guessit
#   pip install sublinimal
SUBLINIMAL_CACHE=/var/downloads/subliminal-cache/

# SUBLINIMAL_CACHE=/home/agrbin/.subliminal-cache/
export PATH="$PATH:/usr/local/bin"

function main {
  run_for_dir "$1" "$2"
}

function run_for_dir {
  dir="$1"
  token="$2"
  if [ ! -d "$dir" ]; then
    echo "$dir should be a dir."
    exit 1
  fi

  find "$dir" -iregex '.*\(avi\|mp4\|mkv\)$' -type f | while read videopath; do
    build_for_movie "$videopath"
  done
  build_video_index "$dir" "$token"
}

function build_video_index {
  dir=$1
  token=$2
  OUT="$dir/+video_index.html"
  echo building video index to $OUT..
  cat > "$OUT" <<EOF
    <!doctype html>
    <html>
      <head>
        <style>
        </style>
      </head>
      <body>
        <table>
EOF

  find "$dir" -iregex '.*\(avi\|mp4\|mkv\)$' -type f | while read videopath; do
    videobase=${videopath%.*}
    relvideo=$(basename "$videopath")
    relvideobase=$(basename "$videobase")
    echo "<tr>" >> "$OUT"
    echo "<th>$relvideo</th>" >> "$OUT"
    echo "<td><a href=\"/token/$token/$relvideobase.en.html\">play en</a></td>" >> "$OUT"
    echo "<td><a href=\"/token/$token/$relvideobase.hr.html\">play hr</a></td>" >> "$OUT"
    echo "<td><a href=\"/token/$token/$relvideo\">download video</a></td>" >> "$OUT"
    echo "<td><a href=\"/token/$token/$relvideobase.en.srt\">download en srt</a></td>" >> "$OUT"
    echo "<td><a href=\"/tokhr/$tokhr/$relvideobase.hr.srt\">download hr srt</a></td>" >> "$OUT"
    echo "</tr>" >> "$OUT"
  done

  cat >> "$OUT" <<EOF
      </table>
    </body>
  </html>
EOF
  echo ls -l "$OUT"
  ls -l "$OUT"
}

# build_for_movie videofile
# tries to download subtitles for a movie and builds a .html player.
function build_for_movie {
  videopath="$1"
  videobase=${videopath%.*}

  relvideo=$(basename "$videopath")

  txtpath=$videobase.txt

  echo processing $relvideo..

  # extract some information from video
  guessit "$videopath" > "$txtpath"

  # ignore if subtitle cant be downloaded
  # throttle download
  #sleep 15
  echo downloading subtitles..

  subliminal --cache-dir=$SUBLINIMAL_CACHE \
     download --force --language=en --language=hr "$videopath" &> /dev/null

  # convert subittles and add to html.
  cnt=0
  for lang in en hr; do
    relvtt=$(basename "$videobase").$lang.vtt
    srtpath="$videobase.$lang.srt"
    vttpath="$videobase.$lang.vtt"
    htmlpath=$videobase.$lang.html
    if [ -f "$srtpath" ]; then
      srt-to-vtt "$srtpath" > "$vttpath"
      cnt=$((cnt + 1))
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
    fi
  done
  echo $cnt subtitles found.

  echo html created.
  echo
  return $retval
}

main "$1" "$2"
