# Example script that launches the ide-ui container

set -e

if [ "no" == "yes" ]; then
    # OLD, non-x11docker version
    export XEPH_DISPLAY=":10"
    Xephyr $XEPH_DISPLAY -ac -br -fullscreen -glamor &
    BLAH=$!
    export DISPLAY="$XEPH_DISPLAY"
    docker run --rm --device /dev/snd -e DISPLAY --cap-add sys_admin -v /tmp/.X11-unix:/tmp/.X11-unix:rw -v /usr/lib/x86_64-linux-gnu/libXv.so.1:/usr/lib/x86_64-linux-gnu/libXv.so.1 $* ide-ui-xfce4
    kill $BLAH
else
    #echo "TODO: nvidia-docker-compose"
    GPU=no
    GPU_ARGS="--gpu --hostdisplay --xorg"
    [ "$GPU" != "yes" ] && GPU_ARGS=""
    docker-compose rm -f && docker-compose build ide-ui-base
    docker-compose rm -f && docker-compose build ide-ui-xfce4 && x11docker/x11docker ${GPU_ARGS} --desktop -fy --no-init --user=RETAIN --sudouser -- --rm -- ide-ui-xfce4 startxfce4
fi

