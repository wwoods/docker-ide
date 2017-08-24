# Example script that launches the ide-ui container

export XEPH_DISPLAY=":10"
Xephyr $XEPH_DISPLAY -ac -br -fullscreen -glamor &
BLAH=$!
export DISPLAY="$XEPH_DISPLAY"
echo "TODO: nvidia-docker-compose"
docker-compose rm -f && docker-compose build && docker-compose up ide-ui
kill $BLAH

