FROM ide-base

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


# Install the XFCE4 UI and other packages
ENV XDG_CURRENT_DESKTOP XFCE
RUN sudo apt-get install -y --no-install-recommends \
        xfce4 xfce4-terminal dbus-x11 \
        # Theme it \
        arc-theme moka-icon-theme \
        # Other applications \
        chromium-browser nautilus rabbitvcs-nautilus gtk2-engines pm-utils

# Themes!
RUN mkdir .icons
RUN mkdir .themes
# Capitaine cursors
RUN \
        mkdir tmp \
        && cd tmp \
        && curl -sSL https://dl.opendesktop.org/api/files/download/id/1489948557/capitaine-cursors-r2.tar.gz -o capitaine-cursors-r2.tar.gz \
        && tar -xzvf capitaine-cursors-r2.tar.gz \
        && cp -pr capitaine-cursors-r2/bin/xcursors ~/.icons/capitaine-cursors \
        && cd ~ \
        && rm -rf tmp
# Axiom theming
RUN \
        mkdir tmp \
        && cd tmp \
        && curl -sSL https://dl.opendesktop.org/api/files/download/id/1461767736/90145-axiom.tar.gz -o 90145-axiom.tar.gz \
        && tar -xzvf 90145-axiom.tar.gz \
        && cp -pr axio* ~/.themes/ \
        && cd ~ \
        && rm -rf tmp

# Dump user files, chmod to their own.  COPY copies as root!!!
ADD config/xfce4 /home/${DESK_USER}/.config/xfce4
RUN ${DESK_USER_CHOWN} .config

# Set up default applications
RUN mkdir -p ~/.config \
        && mkdir -p ~/.local/share/applications \
        && xdg-mime default nautilus.desktop inode/directory application \
        && xdg-mime default chromium-browser.desktop text/html webbrowser \
        && xdg-mime default chromium-browser.desktop x-scheme-handler/http\
        && xdg-mime default chromium-browser.desktop x-scheme-handler/https \
        && xdg-mime default chromium-browser.desktop x-scheme-handler/about

# Don't run wm in vglrun, causes issues with child processes
CMD xfce4-session

