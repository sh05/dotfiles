ROOT=~/trial

ln -s .vimrc $ROOT/.vimrc
ln -s .zshrc $ROOT/.zshrc
ln -s .tmux.conf $ROOT/.tmux.conf

# config directory
VIMRC=$ROOT/.config
if [ -d $VIMRC ]; then
else
  ln -s .vim/ $VIMRC
fi

# config directory
CONFIG=$ROOT/.config
if [ -d $CONFIG ]; then
else
  ln -s .config/ $CONFIG
fi

# sudo apt-get install tmux -y

# alacritty directory
# ALACRITTY=$CONFIG/alacritty
# if [ -d $ALACRITTY ]; then
  # mkdir -p $ALACRITTY
  # ln -s alacritty.yml $ALACRITTY/alacritty.yml
  # ln -s alacritty.yml $ALACRITTY/alacritty.yml
# fi

# karabiner directory
# karabiner=$CONFIG/karabiner
# if [ -d $KARABINER ]; then
  # mkdir -p $KARABINER
  # ln -s karabiner.json $KARABINER/karabiner.json

  # mkdir -p $KARABINER/assets/complex_modifications
# fi
