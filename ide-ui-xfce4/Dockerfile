FROM ide-ui-base

# NOTE!  DPI may be set in config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml.
# Change <property name="DPI"> to <property name="DPI" type="int" value="140">

RUN sudo apt-get update

# Install the XFCE4 UI and other packages
ENV XDG_CURRENT_DESKTOP XFCE
RUN \
        sudo \
        DEBIAN_FRONTEND=noninteractive \
        apt-get install -y --no-install-recommends \
        xfce4 xfce4-terminal dbus-x11 \
        # Theme it \
        arc-theme moka-icon-theme \
        # Other applications \
        chromium-browser nautilus rabbitvcs-nautilus gtk2-engines pm-utils

# Themes!
RUN mkdir .icons
RUN mkdir .themes
# Capitaine cursors and Axiom theming
COPY ./theme ./tmp-theme/
RUN \
        ${DESK_USER_CHOWN} tmp-theme \
        && cd tmp-theme \
        && tar -xzvf capitaine-cursors-r2.1.tar.gz \
        && cp -pr capitaine-cursors/ ~/.icons/capitaine-cursors \
        && tar -xzvf 90145-axiom.tar.gz \
        && cp -pr axio* ~/.themes/ \
        && cd ~ \
        && rm -rf tmp-theme

# Dump user files, chmod to their own.  COPY copies as root!!!
ADD config/xfce4 /home/${DESK_USER}/.config/xfce4
RUN ${DESK_USER_CHOWN} .config

# Will be forwarded from host machine.
RUN sudo rm -rf /usr/lib/x86_64-linux-gnu/libXv.so.1

# Don't run wm in vglrun, causes issues with child processes
CMD xfce4-session

