#! /usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DOTDIR="$DIR/ide-base/dot-files"

declare -a DOTFILES=(
    ".ctags.d"
    ".ctags.vimrc"
    ".tmux.conf"
    ".vimrc"
)

echo "Checking script symlinks..."
for file in "${DOTFILES[@]}"
do
    if [ -a "$HOME/$file" ]; then
        if [ -h "$HOME/$file" ]; then
            # Already a symlink
            if [ "$DOTDIR/$file" = "$(readlink -f $HOME/$file)" ]; then
                echo "Skipping '$HOME/$file': already linked to docker-ide."
                continue
            fi
        fi
        if [ -a "$HOME/$file.bak" ]; then
            echo "This script would overwrite '$HOME/$file' AND that file "
            echo "already has a backup.  Please manually check '$HOME/$file' "
            echo "and its backup and move or delete them."
            exit 1
        else
            echo "Backing up '$HOME/$file' to '$HOME/$file.bak'"
            mv $HOME/$file $HOME/$file.bak
        fi
    fi

    CMD="ln -s $DOTDIR/$file $HOME/$file"
    echo "$CMD"
    eval $CMD
done

echo "Linking .bashrc"
if [ ! -f "$HOME/.bash_profile" ]; then
    echo '. $HOME/.bashrc' > "$HOME/.bash_profile"
fi
if grep -q docker-ide $HOME/.bashrc; then
    echo '.bashrc already calls docker-ide version'
else
    echo '. '`pwd`'/ide-base/dot-files/.bashrc' >> $HOME/.bashrc
fi


echo "Installing vim plugins..."
VUNDLE="$HOME/.vim/bundle/Vundle.vim"
if [ -d "$VUNDLE" ]; then
    echo "...Skipping Vundle.vim, already installed..."
else
    git clone https://github.com/VundleVim/Vundle.vim.git "$VUNDLE"
fi
bash -c 'echo | echo | vim +PluginInstall +qall &>/dev/null'

echo "Installing ctags..."
CTAGS="$HOME/.ctags.inst"
if [ -d "$CTAGS" ]; then
    echo "...Skipping ctags install, already at '$CTAGS'"
else
    if [ ! -d "$HOME/bin" ]; then
        mkdir "$HOME/bin"
        echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
    fi

    rm -f "$HOME/bin/ctags" "$HOME/bin/readtags"

    git clone --depth 1 https://github.com/universal-ctags/ctags.git "$CTAGS/repo"
    remove_ctags() {
        rm -rf "$CTAGS"
    }
    trap 'remove_ctags' ERR
    bash -c "
        cd "$CTAGS/repo" \
        && ./autogen.sh \
        && ./configure \
        && make \
        && make install prefix="$CTAGS" \
        && cd .. \
        && rm -rf repo \
        && ln -s "$CTAGS/bin/ctags" "$HOME/bin/ctags" \
        && ln -s "$CTAGS/bin/readtags" "$HOME/bin/readtags"
    "
    trap - ERR
fi

echo "Installing tmux plugins..."
TPM="$HOME/.tmux/plugins/tpm"
if [ -d "$TPM" ]; then
    echo "...Skipping TPM, already installed..."
else
    git clone https://github.com/tmux-plugins/tpm "$TPM"
fi
tmux new-session -d -s plugin_setup
tmux run-shell "$TPM/bindings/install_plugins"
tmux kill-session -t plugin_setup

