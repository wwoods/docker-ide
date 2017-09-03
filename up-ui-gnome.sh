# Example script that launches the ide-ui container

export XEPH_DISPLAY=":11"
Xephyr $XEPH_DISPLAY -ac -br -fullscreen -glamor &
BLAH=$!
export DISPLAY="$XEPH_DISPLAY"
echo "TODO: nvidia-docker-compose"
docker-compose rm -f && docker-compose build && docker run -it --rm --device /dev/snd -e DISPLAY --cap-add sys_admin -v /tmp/.X11-unix:/tmp/.X11-unix:rw -v /usr/lib/x86_64-linux-gnu/libXv.so.1:/usr/lib/x86_64-linux-gnu/libXv.so.1 $* ide-ui-gnome
kill $BLAH

