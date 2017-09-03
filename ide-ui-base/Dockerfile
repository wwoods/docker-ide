FROM ide-base

RUN sudo apt-get update

# Install VirtualGL (allows OpenGL applications over VNC... also a way to run this without VNC!)
ENV VIRTUALGL_VERSION 2.5.2
RUN curl -sSL https://downloads.sourceforge.net/project/virtualgl/"${VIRTUALGL_VERSION}"/virtualgl_"${VIRTUALGL_VERSION}"_amd64.deb -o virtualgl_"${VIRTUALGL_VERSION}"_amd64.deb \
        && sudo dpkg -i virtualgl_*.deb \
        && sudo /opt/VirtualGL/bin/vglserver_config -config +s +f -t \
        && rm virtualgl_*.deb
RUN sudo apt-get install -y libglu1-mesa-dev mesa-utils

# nvidia-docker setup
LABEL com.nvidia.volumes.needed="nvidia_driver"
ENV PATH /usr/local/nvidia/bin:/opt/VirtualGL/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}


# At this point, can run glxgears ON HOSTING MACHINE WITHOUT VNC via:
# xhost +local:root
# nvidia-docker run -e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix:rw -v /usr/lib/x86_64-linux-gnu/libXv.so.1:/usr/lib/x86_64-linux-gnu/libXv.so.1 {docker image} vglrun glxgears

# NOW REQUIRES xserver-xephyr to be running on DISPLAY

# Set up default applications
RUN sudo apt-get install -y --no-install-recommends xdg-utils \
        && mkdir -p ~/.config \
        && mkdir -p ~/.local/share/applications \
        && xdg-mime default nautilus.desktop inode/directory application \
        && xdg-mime default chromium-browser.desktop text/html webbrowser \
        && xdg-mime default chromium-browser.desktop x-scheme-handler/http\
        && xdg-mime default chromium-browser.desktop x-scheme-handler/https \
        && xdg-mime default chromium-browser.desktop x-scheme-handler/about

