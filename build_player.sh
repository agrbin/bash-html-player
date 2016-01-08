#!/bin/bash
# ./build_player.sh directory
# before attaching this script to torrent-finish try running it manually
# Dependencies:
#   npm install -g srt2vtt
#   pip install guessit
#   pip install sublinimal
#   pip install chardet
SUBLINIMAL_CACHE=/var/downloads/subliminal-cache/

# SUBLINIMAL_CACHE=/home/agrbin/.subliminal-cache/

export PATH="$PATH:/usr/local/bin"

SRT2VTT="node /usr/local/lib/node_modules/srt2vtt/bin/convert.js"

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

function echo_track_elem {
  filepath="$1"
  relpath="$2"
  label="$3"
  token="$4"
  if [ -f "$filepath" ]; then
    echo "<td><a href=\"/token/$token/$relpath\"> [$label] </a></td>"
  fi
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
          th { text-align: left; }
        </style>
      </head>
      <body>
        <table>
EOF

  echo "<h2>all links in this page are public - they don't require password</h2>" >> "$OUT"
  echo "<h3><a href=\"/token/$token/+video_index.html\">link to this page</a></h3>" >> "$OUT"
  find "$dir" -iregex '.*\(avi\|mp4\|mkv\)$' -type f | while read videopath; do
    videobase=${videopath%.*}
    relvideo=$(basename "$videopath")
    relvideobase=$(basename "$videobase")
    echo "<tr>" >> "$OUT"
    echo "<th>$relvideo</th>" >> "$OUT"

    echo_track_elem "$videopath" "$relvideo" "download video" "$token" >> "$OUT"
    echo_track_elem "$videobase.en.html" "$relvideobase.en.html" "play en" "$token" >> "$OUT"
    echo_track_elem "$videobase.hr.html" "$relvideobase.hr.html" "play hr" "$token" >> "$OUT"
    echo_track_elem "$videobase.en.srt" "$relvideobase.en.srt" "download en srt" "$token" >> "$OUT"
    echo_track_elem "$videobase.hr.srt" "$relvideobase.hr.srt" "download hr srt" "$token" >> "$OUT"
    echo_track_elem "$videobase.srt" "$relvideobase.srt" "download torrent srt" "$token" >> "$OUT"

    echo "</tr>" >> "$OUT"
  done

  cat >> "$OUT" <<EOF
      </table>
    </body>
  </html>
EOF
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
      $SRT2VTT < "$srtpath"  > "$vttpath"
      charset=$(chardetect "$vttpath" | cut -f2 -d':' | cut -f2 -d' ')
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
            <track kind="subtitles" src="$relvtt" charset="$charset" default />
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
}

main "$1" "$2"
