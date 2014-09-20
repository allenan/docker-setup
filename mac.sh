#!/usr/bin/env bash

# Adapted from github.com/thoughtbot/laptop

trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

set -e

fancy_echo() {
  printf "\n%b\n" "$1"
}

brew_install_or_upgrade() {
  if brew_is_installed "$1"; then
    if brew_is_upgradable "$1"; then
      brew upgrade "$@"
    fi
  else
    brew install "$@"
  fi
}

brew_is_installed() {
  local NAME=$(brew_expand_alias "$1")

  brew list -1 | grep -Fqx "$NAME"
}

brew_is_upgradable() {
  local NAME=$(brew_expand_alias "$1")

  brew outdated --quiet "$NAME" >/dev/null
  [[ $? -ne 0 ]]
}

brew_expand_alias() {
  brew info "$1" 2>/dev/null | head -1 | awk '{gsub(/:/, ""); print $1}'
}

brew_launchctl_restart() {
  local NAME=$(brew_expand_alias "$1")
  local DOMAIN="homebrew.mxcl.$NAME"
  local PLIST="$DOMAIN.plist"

  mkdir -p ~/Library/LaunchAgents
  ln -sfv /usr/local/opt/$NAME/$PLIST ~/Library/LaunchAgents

  if launchctl list | grep -q $DOMAIN; then
    launchctl unload ~/Library/LaunchAgents/$PLIST >/dev/null
  fi
  launchctl load ~/Library/LaunchAgents/$PLIST >/dev/null
}
### end mac-components/mac-functions

if ! command -v brew &>/dev/null; then
  fancy_echo "Installing Homebrew, a good OS X package manager ..."
    ruby <(curl -fsS https://raw.githubusercontent.com/Homebrew/homebrew/go/install)

  if ! grep -qs "recommended by brew doctor" ~/.zshrc; then
    fancy_echo "Put Homebrew location earlier in PATH ..."
      printf '\n# recommended by brew doctor\n' >> ~/.zshrc
      printf 'export PATH="/usr/local/bin:$PATH"\n' >> ~/.zshrc
      export PATH="/usr/local/bin:$PATH"
  fi
else
  fancy_echo "Homebrew already installed. Skipping ..."
fi

fancy_echo "Updating Homebrew formulas ..."
brew update
### end mac-components/homebrew

if ! brew tap | grep -q caskroom/cask; then
  brew tap caskroom/cask
fi

if ! brew list | grep -q brew-cask; then
  brew install brew-cask
fi

cask_install() {
  if ! brew cask list | grep -q $1; then
    echo installing $1...
    brew cask install $1
  else
    echo $1 is already installed
  fi
}

cask_install virtualbox
cask_install vagrant
### end mac-components/programs

if ! command -v docker-osx &>/dev/null; then
  fancy_echo "Installing docker-osx ..."
  curl https://raw.githubusercontent.com/noplay/docker-osx/HEAD/docker-osx > /usr/local/bin/docker-osx
  chmod +x /usr/local/bin/docker-osx
else
  fancy_echo "docker-osx already installed. Skipping ..."
fi
### end mac-components/docker-osx

if ! command -v fig &>/dev/null; then
  fancy_echo "Installing fig ..."
  curl -L https://github.com/docker/fig/releases/download/0.5.2/darwin > /usr/local/bin/fig
  chmod +x /usr/local/bin/fig
else
  fancy_echo "fig already installed. Skipping ..."
fi
### end mac-components/fig
