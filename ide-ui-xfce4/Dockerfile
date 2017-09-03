FROM ide-ui-base

RUN sudo apt-get update

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

# Don't run wm in vglrun, causes issues with child processes
CMD xfce4-session

