# MUST be run with nvidia-docker
# AND needs xhost +local:root to be run beforehand.
FROM ubuntu:17.10

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Set up machine, install packages
RUN apt-get update \
        && apt-get upgrade -y \
        && apt-get update \
        && apt-get install -y curl htop man vim p7zip zip unzip ssh git git-svn \
        && apt-get install -y --no-install-recommends \
            autoconf automake pkg-config gcc g++ tmux

# Set up the desktop user
RUN apt-get install -y sudo
RUN echo "ALL ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers
ENV DESK_USER dock
ENV DESK_USER_CHOWN sudo chown -R ${DESK_USER}:${DESK_USER}
RUN useradd -ms /bin/bash ${DESK_USER}
RUN adduser ${DESK_USER} sudo
USER ${DESK_USER}
ENV HOME=/home/${DESK_USER}
WORKDIR /home/${DESK_USER}

# Set up dot files
COPY ./dot-files ./dot-files/
RUN ${DESK_USER_CHOWN} ./dot-files && mv ./dot-files/.[^.]* ./ && rm -rf ./dot-files
RUN echo "alias tmux='tmux -2'" >> ~/.bashrc

# Install VIM plugins
# TODO - .ctags.vimrc should be optional.
RUN git clone https://github.com/VundleVim/Vundle.vim.git ${HOME}/.vim/bundle/Vundle.vim \
        && /bin/bash -c 'echo | echo | vim +PluginInstall +qall &>/dev/null'

# Install tmux plugins
RUN \
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm \
        && tmux new-session -d -s plugin_setup \
        && tmux run-shell ~/.tmux/plugins/tpm/bindings/install_plugins

# Install python3 via Anaconda, include dmt utility for docker mounting and
# sibling containers.
RUN curl -LO http://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
        && /bin/bash Miniconda3-latest-Linux-x86_64.sh -p ~/miniconda3 -b \
        && rm Miniconda3-latest-Linux-x86_64.sh \
        && PATH=~/miniconda3/bin:$PATH conda update -y conda
ENV PATH=${HOME}/miniconda3/bin:${PATH}
RUN pip install click
ADD ./dmnt /usr/bin/dmnt


# Install ctags with fixed multiline parser
RUN git clone https://github.com/masatake/ctags.git \
        && cd ctags \
        && git checkout revise-multiline-regex-parser \
        && ./autogen.sh \
        && ./configure \
        && make \
        && sudo make install \
        && cd .. \
        && rm -rf ctags

