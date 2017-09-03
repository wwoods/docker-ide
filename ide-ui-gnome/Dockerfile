FROM ide-ui-base

RUN echo "Broken; GNOME gives all sorts of weird errors.  Use XFCE4." && exit 1

RUN sudo apt-get update

# Install the gnome UI and other packages
ENV XDG_CURRENT_DESKTOP GNOME
RUN sudo apt-get install -y --no-install-recommends \
        gnome-shell dbus-x11 \
        # Other applications \
        chromium-browser

# Don't run wm in vglrun, causes issues with child processes
CMD gnome-shell --nested

