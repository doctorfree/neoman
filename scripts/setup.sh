#!/bin/bash
#
# setup.sh - initialize configuration files, install needed utilities
#
# shellcheck disable=SC2001,SC2002,SC2016,SC2006,SC2059,SC2086,SC2089,SC2181,SC2129

darwin=
platform=$(uname -s)
[ "${platform}" == "Darwin" ] && darwin=1
USERCONF="${HOME}/.config"
LMANDIR="${USERCONF}/nvim-Lazyman"
NEOMANDIR="${USERCONF}/neoman"
INITIAL="${NEOMANDIR}/.initialized"
GHUC="https://raw.githubusercontent.com"
OWNER=doctorfree
BOLD=$(tput bold 2>/dev/null)
NORM=$(tput sgr0 2>/dev/null)

# Neovim 0.9+ honors this
# Override user's setting to install in standard location
export NVIM_APPNAME="nvim-Lazyman"

usage() {
  if [ "${have_rich}" ]; then
    rich "[bold]Usage:[/] [bold italic green]setup.sh[/] [cyan]\[-a] \[-d] \[-m] \[-q] \[-r] \[-y] \[-u] \[-U] \[arg][/]" --print
    rich "[bold]Where:[/]" --print
    rich "    [cyan]-a[/] indicates [yellow]ask to play an animation when done[/]" --print
    rich "    [cyan]-d[/] indicates [yellow]debug mode[/]" --print
    rich "    [cyan]-m[/] indicates [yellow]setup user NeoMutt configuration[/]" --print
    rich "    [cyan]-q[/] indicates [yellow]quiet mode[/]" --print
    rich "    [cyan]-r[/] indicates [yellow]remove service/package[/]" --print
    rich "    [cyan]-y[/] indicates [yellow]answer yes at all prompts[/]" --print
    rich "    [cyan]-u[/] indicates [yellow]display this usage message and exit[/]" --print
    rich "    [cyan]-U[/] indicates [yellow]update Neoman and exit[/]" --print
    rich "    If [cyan]arg[/] is [cyan]brew[/] [yellow]Homebrew is installed and used[/]" --print
    rich "    [cyan]arg[/] can also be one of [cyan]games[/], [cyan]kitty[/], [cyan]neovim[/]," --print
    rich "        [cyan]btop[/], [cyan]newsboat[/], [cyan]w3m[/], [cyan]neomutt[/], or [cyan]neofetch[/]" --print
    rich "        indicating [yellow]installation or removal[/] of [cyan]arg[/]" --print
    printf "\n"
  else
    printf "\nUsage: neoman [-a] [-d] [-m] [-q] [-r] [-y] [-u] [-U] [arg]"
    printf "\nWhere:"
    printf "\n\t-a indicates ask to play an animation when done"
    printf "\n\t-d indicates debug mode"
    printf "\n\t-m indicates setup user NeoMutt configuration"
    printf "\n\t-q indicates quiet mode"
    printf "\n\t-r indicates remove service/package"
    printf "\n\t-y indicates answer yes at all prompts"
    printf "\n\t-u indicates display this usage message and exit"
    printf "\n\t-U indicates update Neoman and exit"
    printf "\n\tif 'arg' is 'brew' Homebrew is installed and used"
    printf "\n\targ can also be one of games, kitty, neovim"
    printf "\n\t\tbtop, newsboat, w3m, neomutt, or neofetch"
    printf "\n\t\tindicating installation of removal of arg\n"
  fi
  exit 1
}

# Compare two version strings [$1: version string 1 (v1), $2: version string 2 (v2)]
# Return values:
#   0: v1 == v2
#   1: v1 > v2
#   2: v1 < v2
# Based on https://stackoverflow.com/a/4025065 by Dennis Williamson
# and https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash/49351294#49351294 by Github user @fonic
compare_versions() {
  # Trivial v1 == v2 test based on string comparison
  [[ "$1" == "$2" ]] && return 0

  # Local variables
  local regex="^(.*)-r([0-9]*)$" va1=() vr1=0 va2=() vr2=0 len i IFS="."

  # Split version strings into arrays, extract trailing revisions
  if [[ "$1" =~ ${regex} ]]; then
    va1=("${BASH_REMATCH[1]}")
    [[ -n "${BASH_REMATCH[2]}" ]] && vr1=${BASH_REMATCH[2]}
  else
    va1=("$1")
  fi
  if [[ "$2" =~ ${regex} ]]; then
    va2=("${BASH_REMATCH[1]}")
    [[ -n "${BASH_REMATCH[2]}" ]] && vr2=${BASH_REMATCH[2]}
  else
    va2=("$2")
  fi

  # Bring va1 and va2 to same length by filling empty fields with zeros
  ((${#va1[@]} > ${#va2[@]})) && len=${#va1[@]} || len=${#va2[@]}
  for ((i = 0; i < len; ++i)); do
    [[ -z "${va1[i]}" ]] && va1[i]="0"
    [[ -z "${va2[i]}" ]] && va2[i]="0"
  done

  # Append revisions, increment length
  va1+=("$vr1")
  va2+=("$vr2")
  len=$((len + 1))

  # Compare version elements, check if v1 > v2 or v1 < v2
  for ((i = 0; i < len; ++i)); do
    if ((10#${va1[i]} > 10#${va2[i]})); then
      return 1
    elif ((10#${va1[i]} < 10#${va2[i]})); then
      return 2
    fi
  done

  # All elements are equal, thus v1 == v2
  return 0
}


remove_package() {
  PKG="$1"
  [ "${quiet}" ] || printf "\n\tRemoving %s ..." "${PKG}"
  # Try Brew first
  have_brew=$(type -p brew)
  [ "${have_brew}" ] || usebrew=
  if [ "${usebrew}" ]; then
    if [ "${tellme}" ]
    then
      echo "brew uninstall -q ${PKG}"
    else
      brew uninstall -q ${PKG} >/dev/null 2>&1
    fi
  else
    if [ "${debian}" ]; then
      if [ "${APT}" ]; then
        if [ "${tellme}" ]
        then
          echo "sudo ${APT} remove ${PKG}"
        else
          sudo ${APT} remove ${PKG} >/dev/null 2>&1
        fi
      else
        [ "${quiet}" ] || printf "\n\t\tCannot locate apt to remove. Skipping ..."
      fi
    else
      if [ "${fedora}" ]; then
        if [ "${DNF}" ]; then
          if [ "${tellme}" ]
          then
            echo "sudo ${DNF} remove ${PKG}"
          else
            sudo ${DNF} remove ${PKG} >/dev/null 2>&1
          fi
        else
          [ "${quiet}" ] || printf "\n\t\tCannot locate dnf to remove. Skipping ..."
        fi
      else
        [ "${arch}" ] && {
          if [ "${tellme}" ]
          then
            echo "sudo pacman -R --noconfirm ${PKG}"
          else
            sudo pacman -R --noconfirm ${PKG} >/dev/null 2>&1
          fi
        }
      fi
    fi
  fi
  [ "${quiet}" ] || printf " done"
}

install_package() {
  PKG="$1"
  [ "${quiet}" ] || printf "\n\tInstalling %s ..." "${PKG}"
  # Try Brew first
  brewed=
  [ "${usebrew}" ] && {
    brew search -q /^${PKG}$/ >/dev/null 2>&1
    [ $? -eq 0 ] && {
      if [ "${tellme}" ]
      then
        echo "brew install --quiet ${PKG}"
      else
        brew install --quiet ${PKG} >/dev/null 2>&1
        [ $? -eq 0 ] || brew link --overwrite --quiet ${PKG} >/dev/null 2>&1
      fi
      brewed=1
    }
  }
  [ "${brewed}" ] || {
    if [ "${debian}" ]; then
      if [ "${APT}" ]; then
        if [ "${tellme}" ]
        then
          echo "sudo ${APT} install ${PKG}"
        else
          sudo ${APT} install ${PKG} >/dev/null 2>&1
        fi
      else
        [ "${quiet}" ] || printf "\n\t\tCannot locate apt to install. Skipping ..."
      fi
    else
      if [ "${fedora}" ]; then
        if [ "${DNF}" ]; then
          if [ "${tellme}" ]
          then
            echo "sudo ${DNF} install ${PKG}"
          else
            sudo ${DNF} install ${PKG} >/dev/null 2>&1
          fi
        else
          [ "${quiet}" ] || printf "\n\t\tCannot locate dnf to install. Skipping ..."
        fi
      else
        [ "${arch}" ] && {
          if [ "${tellme}" ]
          then
            echo "sudo pacman -S --noconfirm ${PKG}"
          else
            sudo pacman -S --noconfirm ${PKG} >/dev/null 2>&1
          fi
        }
      fi
    fi
  }
  [ "${quiet}" ] || printf " done"
}

ask_install() {
  nam="$1"
  pkg="$2"
  if [ "${prompt}" ]; then
    echo "Attempting to configure ${nam} but ${nam} is not installed"
    echo "Would you like to install ${nam} at this time?"
    while true; do
      read -r -p "Install ${nam} ? (y/n) " yn
      case $yn in
        [Yy]*)
          install_package ${pkg}
          break
          ;;
        [Nn]*)
          break
          ;;
        *)
          echo "Please answer yes or no."
          ;;
      esac
    done
  else
    install_package ${pkg}
  fi
}

install_pipx() {
  [ "${quiet}" ] || {
    printf "\n\tInstalling pipx ..."
  }
  if [ "${tellme}" ]
  then
    echo "${PYTHON} -m pip install --user pipx"
    echo "${PYTHON} -m pipx ensurepath --force"
  else
    ${PYTHON} -m pip install --user pipx >/dev/null 2>&1
    ${PYTHON} -m pipx ensurepath --force >/dev/null 2>&1
  fi
  [ "${quiet}" ] || {
    printf " done"
  }
}

install_external_package() {
  API_URL="https://api.github.com/repos/${OWNER}/${PROJECT}/releases/latest"
  DL_URL=
  [ "${have_curl}" ] && [ "${have_jq}" ] && {
    if [ "${darwin}" ]; then
      DL_URL=$(curl --silent "${API_URL}" \
          | jq --raw-output '.assets | .[]?.browser_download_url' \
        | grep "\.Darwin\.tgz")
    else
      if [ "${arch}" ]; then
        DL_URL=$(curl --silent "${API_URL}" \
            | jq --raw-output '.assets | .[]?.browser_download_url' \
          | grep "\.pkg\.tar\.zst")
      else
        if [ "${centos}" ] || [ "${fedora}" ]; then
          DL_URL=$(curl --silent "${API_URL}" \
              | jq --raw-output '.assets | .[]?.browser_download_url' \
            | grep "x86_64\.rpm")
        else
          if [ "${debian}" ]; then
            if [ "${mach}" == "x86_64" ]; then
              DL_URL=$(curl --silent "${API_URL}" \
                  | jq --raw-output '.assets | .[]?.browser_download_url' \
                | grep "\.amd64\.deb")
            else
              DL_URL=$(curl --silent "${API_URL}" \
                  | jq --raw-output '.assets | .[]?.browser_download_url' \
                | grep "\.arm.*\.deb")
            fi
          else
            printf "\n\tNo %s release asset found for this platform ..." "${PROJECT}"
          fi
        fi
      fi
    fi
  }

  [ "${DL_URL}" ] && {
    [ "${quiet}" ] || {
      printf "\n\tInstalling %s ..." "${PROJECT}"
    }
    if [ "${debian}" ]; then
      [ "${have_wget}" ] && {
        TEMP_DEB="$(mktemp --suffix=.deb)"
        if [ "${tellme}" ]
        then
          echo "wget --quiet -O ${TEMP_DEB} ${DL_URL}"
          echo "chmod 644 ${TEMP_DEB}"
          [ "${APT}" ] && echo "sudo ${APT} install ${TEMP_DEB}"
        else
          wget --quiet -O "${TEMP_DEB}" "${DL_URL}" >/dev/null 2>&1
          chmod 644 "${TEMP_DEB}"
          [ "${APT}" ] && sudo ${APT} install "${TEMP_DEB}" >/dev/null 2>&1
        fi
        rm -f "${TEMP_DEB}"
      }
    else
      if [ "${centos}" ] || [ "${fedora}" ]; then
        [ "${DNF}" ] && {
          if [ "${tellme}" ]
          then
            echo "sudo ${DNF} install ${DL_URL}"
          else
            sudo ${DNF} install ${DL_URL} >/dev/null 2>&1
          fi
        }
      else
        # Until we sign Arch packages we need to download and install locally
        if [ "${arch}" ]; then
          [ "${have_wget}" ] && {
            TEMP_ARCH="$(mktemp --suffix=.zst)"
            if [ "${tellme}" ]
            then
              echo "wget --quiet -O ${TEMP_ARCH} ${DL_URL}"
              echo "chmod 644 ${TEMP_ARCH}"
              echo "sudo pacman -U --noconfirm ${TEMP_ARCH}"
            else
              wget --quiet -O "${TEMP_ARCH}" "${DL_URL}" >/dev/null 2>&1
              chmod 644 "${TEMP_ARCH}"
              sudo pacman -U --noconfirm "${TEMP_ARCH}" >/dev/null 2>&1
            fi
            rm -f "${TEMP_ARCH}"
          }
        else
          [ "${darwin}" ] && {
            [ "${have_wget}" ] && {
              TEMP_ARCH="$(mktemp --suffix=.tgz)"
              if [ "${tellme}" ]
              then
                echo "wget --quiet -O ${TEMP_ARCH} ${DL_URL}"
                echo "chmod 644 ${TEMP_ARCH}"
                echo "tar xzf ${TEMP_ARCH} -C /"
              else
                wget --quiet -O "${TEMP_ARCH}" "${DL_URL}" >/dev/null 2>&1
                chmod 644 "${TEMP_ARCH}"
                tar xzf "${TEMP_ARCH}" -C /
              fi
              rm -f "${TEMP_ARCH}"
            }
          }
        fi
      fi
    fi
    [ "${quiet}" ] || {
      printf " done"
    }
  }
}

install_neomutt() {
  install_package neomutt
  [ -f "${INITIAL}" ] && {
    echo "__install_neomutt__=1" >>"${INITIAL}"
  }
}

remove_neomutt() {
  remove_package neomutt
  [ -f "${INITIAL}" ] && {
    grep -v "__install_neomutt__" "${INITIAL}" > /tmp/neo$$
    cp /tmp/neo$$ "${INITIAL}"
    rm -f /tmp/neo$$
  }
}

install_games() {
  if [ "${darwin}" ]; then
    install_package nbsdgames
    install_package nethack
    install_package ninvaders
    install_package c2048
    install_package greed
  else
    PROJECT=asciigames
    install_external_package
    if [ "${debian}" ]; then
      install_package bsdgames
      install_package greed
    else
      install_package bsd-games
    fi
  fi
  install_package nudoku
  [ -f "${INITIAL}" ] && {
    echo "__install_games__=1" >>"${INITIAL}"
  }
}

remove_games() {
  if [ "${darwin}" ]; then
    remove_package nbsdgames
    remove_package nethack
    remove_package ninvaders
    remove_package c2048
    remove_package greed
  else
    if [ "${debian}" ]; then
      remove_package bsdgames
      remove_package greed
    else
      remove_package bsd-games
    fi
    printf "\n\tRemoving asciigames package ..."
    if [ "${debian}" ]; then
      [ "${APT}" ] && {
        if [ "${tellme}" ]
        then
          echo "sudo ${APT} remove asciigames"
        else
          sudo ${APT} remove asciigames >/dev/null 2>&1
        fi
      }
    else
      if [ "${centos}" ] || [ "${fedora}" ]; then
        [ "${DNF}" ] && {
          if [ "${tellme}" ]
          then
            echo "sudo ${DNF} remove asciigames"
          else
            sudo ${DNF} remove asciigames >/dev/null 2>&1
          fi
        }
      else
        if [ "${arch}" ]; then
          if [ "${tellme}" ]
          then
            echo "sudo pacman -R --noconfirm asciigames"
          else
            sudo pacman -R --noconfirm asciigames >/dev/null 2>&1
          fi
        fi
      fi
    fi
  fi
  remove_package nudoku
  printf "\n"
}

install_kitty() {
  have_stow=$(type -p stow)
  if [ "${have_stow}" ]; then
    LOCAL=".local/stow/kitty.app"
  else
    LOCAL=".local/kitty.app"
  fi
  [ "${have_kitty}" ] || {
    [ "${quiet}" ] || {
      printf "\n\tInstalling Kitty terminal emulator ..."
    }
    curl --silent --location \
      https://sw.kovidgoyal.net/kitty/installer.sh >/tmp/kitty-$$.sh
    [ $? -eq 0 ] || {
      rm -f /tmp/kitty-$$.sh
      curl --insecure --silent --location \
        https://sw.kovidgoyal.net/kitty/installer.sh >/tmp/kitty-$$.sh
      cat /tmp/kitty-$$.sh | sed -e "s/curl -/curl -k/" >/tmp/k$$
      cp /tmp/k$$ /tmp/kitty-$$.sh
      rm -f /tmp/k$$
    }
    if [ -s /tmp/kitty-$$.sh ]; then
      if [ "${have_stow}" ]; then
        sh /tmp/kitty-$$.sh launch=n dest=~/.local/stow >/dev/null 2>&1
        [ -d "${HOME}"/.local/stow ] && {
          cd "${HOME}"/.local/stow || echo "Unable to stow kitty.app"
          stow kitty.app
        }
      else
        sh /tmp/kitty-$$.sh launch=n >/dev/null 2>&1
      fi
      rm -f /tmp/kitty-$$.sh
      # Create a symbolic link to add kitty to PATH
      [ -d ~/.local/bin ] || mkdir -p ~/.local/bin
      if [ -x ~/${LOCAL}/bin/kitty ]; then
        [ -x ~/.local/bin/kitty ] || {
          ln -s ~/${LOCAL}/bin/kitty ~/.local/bin/
        }
      else
        if [ -x /Applications/kitty.app/Contents/MacOS/kitty ]; then
          [ -x ~/.local/bin/kitty ] || {
            ln -s /Applications/kitty.app/Contents/MacOS/kitty ~/.local/bin/
          }
        else
          [ "${quiet}" ] || printf "\nUnable to create Kitty link to ~/.local/bin/\n"
        fi
      fi
      # Link the kitty man pages somewhere it can be found by the man command
      LINMAN="${HOME}/${LOCAL}/share/man"
      MACMAN="/Applications/kitty.app/Contents/Resources/man"
      [ -d ~/.local/share/man/man1 ] || mkdir -p ~/.local/share/man/man1
      [ -f ~/.local/share/man/man1/kitty.1 ] || {
        [ -d ${HOME}/.local/share/man/man1 ] || {
          mkdir -p ${HOME}/.local/share/man/man1
        }
        if [ -f "${LINMAN}/man1/kitty.1" ]; then
          ln -s "${LINMAN}/man1/kitty.1" ~/.local/share/man/man1/
        else
          [ -f "${MACMAN}/man1/kitty.1" ] && {
            ln -s "${MACMAN}/man1/kitty.1" ~/.local/share/man/man1/
          }
        fi
      }
      [ -d ~/.local/share/man/man5 ] || mkdir -p ~/.local/share/man/man5
      [ -f ~/.local/share/man/man5/kitty.conf.5 ] || {
        [ -d ${HOME}/.local/share/man/man5 ] || {
          mkdir -p ${HOME}/.local/share/man/man5
        }
        if [ -f "${LINMAN}/man5/kitty.conf.5" ]; then
          ln -s "${LINMAN}/man5/kitty.conf.5" ~/.local/share/man/man5/
        else
          [ -f "${MACMAN}/man5/kitty.conf.5" ] && {
            ln -s "${MACMAN}/man5/kitty.conf.5" ~/.local/share/man/man5/
          }
        fi
      }
      # Place the kitty.desktop file somewhere it can be found by the OS
      [ -d ~/.local/share/applications ] || mkdir -p ~/.local/share/applications
      [ -f "${HOME}/${LOCAL}/share/applications/kitty.desktop" ] && {
        [ -f ~/.local/share/applications/kitty.desktop ] || {
          cp ~/${LOCAL}/share/applications/kitty.desktop \
            ~/.local/share/applications/
        }
      }
      # If you want to open text files and images in kitty via your file manager
      # also add the kitty-open.desktop file
      [ -f "${HOME}/${LOCAL}/share/applications/kitty-open.desktop" ] && {
        [ -f ~/.local/share/applications/kitty-open.desktop ] || {
          cp ~/${LOCAL}/share/applications/kitty-open.desktop \
            ~/.local/share/applications/
        }
      }
      # Update the paths to the kitty and its icon in the kitty.desktop file(s)
      for desktop in "${HOME}"/.local/share/applications/kitty*.desktop; do
        [ "${desktop}" == "${HOME}/.local/share/applications/kitty*.desktop" ] && continue
        [ -f /home/${MPP_USER}/${LOCAL}/share/icons/hicolor/256x256/apps/kitty.png ] && {
          sed -i "s|Icon=kitty|Icon=/home/${MPP_USER}/${LOCAL}/share/icons/hicolor/256x256/apps/kitty.png|g" "${desktop}"
        }
        [ -x /home/${MPP_USER}/${LOCAL}/bin/kitty ] && {
          sed -i "s|Exec=kitty|Exec=/home/${MPP_USER}/${LOCAL}/bin/kitty|g" "${desktop}"
        }
      done
      [ "${quiet}" ] || printf " done!\n"
    else
      printf "\n${BOLD}ERROR:${NORM} Download of kitty installation script failed"
      printf "\nSee https://sw.kovidgoyal.net/kitty/binary/#manually-installing"
      printf "\nto manually install the kitty terminal emulator\n"
    fi
    have_kitty=$(type -p kitty)
  }
  # Install the Kitty terminfo entry
  KITERM="${HOME}/.terminfo/x/xterm-kitty"
  MATERM="${HOME}/.terminfo/78/xterm-kitty"
  MACAPP="/Applications/kitty.app/Contents/Resources/kitty/terminfo"
  [ -f "${KITERM}" ] || [ -f "${MATERM}" ] || {
    [ -d ${HOME}/.terminfo ] || mkdir -p ${HOME}/.terminfo
    [ -d ${HOME}/.terminfo/x ] || mkdir -p ${HOME}/.terminfo/x
    [ -d ${HOME}/.terminfo/78 ] || mkdir -p ${HOME}/.terminfo/78
    have_tic=$(type -p tic)
    [ "${have_tic}" ] && {
      if [ -f "${HOME}/${LOCAL}/lib/kitty/terminfo/kitty.terminfo" ]; then
        tic -x -o ${HOME}/.terminfo \
          "${HOME}/${LOCAL}/lib/kitty/terminfo/kitty.terminfo" >/dev/null 2>&1
      else
        [ -f "${MACAPP}/kitty.terminfo" ] && {
          tic -x -o ${HOME}/.terminfo \
            "${MACAPP}/kitty.terminfo" >/dev/null 2>&1
        }
      fi
    }
    [ -f "${KITERM}" ] || [ -f "${MATERM}" ] || {
      if [ -f "${HOME}/${LOCAL}/lib/kitty/terminfo/x/xterm-kitty" ]; then
        cp "${HOME}/${LOCAL}/lib/kitty/terminfo/x/xterm-kitty" "${KITERM}"
      else
        if [ -f "${HOME}/${LOCAL}/share/terminfo/x/xterm-kitty" ]; then
          cp "${HOME}/${LOCAL}/share/terminfo/x/xterm-kitty" "${KITERM}"
        else
          if [ -f "${MACAPP}/78/xterm-kitty" ]; then
            cp "${MACAPP}/78/xterm-kitty" "${MATERM}"
          else
            [ "${quiet}" ] || printf "\nUnable to create Kitty terminfo entry ${KITERM}\n"
          fi
        fi
      fi
    }
  }
}

remove_kitty() {
  if [ "${tellme}" ]
  then
    echo "rm -rf ~/.local/kitty.app"
    echo "rm -f ~/.local/bin/kitty"
    echo "rm -f ~/.local/share/applications/kitty.desktop"
    echo "rm -f ~/.local/share/applications/kitty-open.desktop"
    echo "rm -f ~/.local/share/man/man1/kitty.1"
    echo "rm -f ~/.local/share/man/man5/kitty.conf.5"
    [ -d /Applications/kitty.app ] && echo "sudo rm -rf /Applications/kitty.app"
  else
    rm -rf ~/.local/kitty.app
    rm -f ~/.local/bin/kitty
    rm -f ~/.local/share/applications/kitty.desktop
    rm -f ~/.local/share/applications/kitty-open.desktop
    rm -f ~/.local/share/man/man1/kitty.1
    rm -f ~/.local/share/man/man5/kitty.conf.5
    [ -d /Applications/kitty.app ] && sudo rm -rf /Applications/kitty.app
  fi
}

remove_neovim() {
  have_brew=$(type -p brew)
  if [ "${have_brew}" ]; then
    brew uninstall -q neovim >/dev/null 2>&1
  else
    printf "\nCannot locate brew. Skipping Neovim removal."
  fi
}

install_neovim() {
  if [ "${usebrew}" ]; then
    install_args="-h -q -Q -y -z"
  else
    install_args="-q -Q -y -z"
  fi
  [ "${debug}" ] && install_args="${install_args} -d"
  if [ -x ${LMANDIR}/lazyman.sh ]; then
    ${LMANDIR}/lazyman.sh -I ${install_args}
    [ -f "${INITIAL}" ] && {
      echo "__install_neovim__=1" >>"${INITIAL}"
    }
  else
    [ -x ${NEOMANDIR}/scripts/lazyman.sh ] && {
      ${NEOMANDIR}/scripts/lazyman.sh ${install_args}
      [ -f "${INITIAL}" ] && {
        echo "__install_neovim__=1" >>"${INITIAL}"
      }
    }
  fi
  have_neovim=$(type -p nvim)
}

pathadd() {
  if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
    export PATH="$1${PATH:+":$PATH"}"
  fi
}

pathadd "/usr/local/bin"
pathadd "${HOME}/.local/bin"

# Clear the Bash cache so we know for sure if something is installed
hash -r

have_go=$(type -p go)
[ "${have_go}" ] || {
  [ -x /usr/local/go/bin/go ] && {
    pathadd "/usr/local/go/bin"
    have_go=$(type -p go)
  }
}

have_neomutt=$(type -p neomutt)
have_neovim=$(type -p nvim)
have_rich=$(type -p rich)
have_apt=$(type -p apt)
have_aptget=$(type -p apt-get)
have_dnf=$(type -p dnf)
have_yum=$(type -p yum)

arch=
debian=
fedora=
mach=$(uname -m)
APT=
DNF=

case "${mach}" in
  arm*)
    VOPT=
    ;;
  *)
    VOPT="--install-option='--with-audio'"
    ;;
esac

if [ "$platform" == "Darwin" ]; then
  darwin=1
else
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    [ "${ID}" == "debian" ] || [ "${ID_LIKE}" == "debian" ] && debian=1
    [ "${ID}" == "arch" ] || [ "${ID_LIKE}" == "arch" ] && arch=1
    [ "${ID}" == "fedora" ] && fedora=1
    [ "${arch}" ] || [ "${debian}" ] || [ "${fedora}" ] || {
      echo "${ID_LIKE}" | grep debian >/dev/null && debian=1
    }
  else
    if [ -f /etc/arch-release ]; then
      arch=1
    else
      case "${mach}" in
        arm*)
          debian=1
          ;;
        x86*)
          if [ "${have_apt}" ]; then
            debian=1
          else
            if [ -f /etc/fedora-release ]; then
              fedora=1
            else
              if [ "${have_dnf}" ] || [ "${have_yum}" ]; then
                # Use Fedora RPM for all other rpm based systems
                fedora=1
              else
                echo "Unknown operating system distribution"
              fi
            fi
          fi
          ;;
        *)
          echo "Unknown machine architecture"
          ;;
      esac
    fi
  fi
fi

[ "${debian}" ] && {
  if [ "${have_apt}" ]; then
    APT="apt -q -y"
  else
    if [ "${have_aptget}" ]; then
      APT="apt-get -q -y"
    else
      echo "Could not locate apt or apt-get."
    fi
  fi
}

[ "${fedora}" ] && {
  if [ "${have_dnf}" ]; then
    DNF="dnf --assumeyes --quiet"
  else
    if [ "${have_yum}" ]; then
      DNF="yum --assumeyes --quiet"
    else
      echo "Could not locate dnf or yum."
    fi
  fi
}

ask_anim=
debug=
quiet=
instmutt=
remove=
prompt=1
narg=
tellme=
update=

while getopts "admnqryUu" flag; do
  case $flag in
    a)
      ask_anim=1
      ;;
    d)
      debug=1
      ;;
    m)
      instmutt=1
      ;;
    n)
      narg="-n"
      tellme=1
      ;;
    q)
      quiet=1
      ;;
    r)
      remove=1
      ;;
    y)
      prompt=
      ;;
    U)
      update=1
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND - 1))

argument=$(echo "$1" | tr '[:upper:]' '[:lower:]')

[ -d ${USERCONF} ] || mkdir -p ${USERCONF}

have_curl=$(type -p curl)
have_git=$(type -p git)
have_jq=$(type -p jq)
have_wget=$(type -p wget)
have_awk=$(type -p awk)
have_fc=$(type -p fc-cache)
have_mktemp=$(type -p mktemp)
have_unlink=$(type -p unlink)
have_unzip=$(type -p unzip)

if [ "${darwin}" ]; then
  usebrew=1
else
  usebrew=
fi
[ "${argument}" == "brew" ] && usebrew=1

[ "${update}" ] && {
  if [ "${tellme}" ]
  then
    if [ -d "${NEOMANDIR}" ]
    then
      printf "\nUpdating %s" "${NEOMANDIR}"
      printf "\ngit -C %s pull" "${NEOMANDIR}"
    else
      printf "\n%s does not exist or is not a directory. Re-run neoman without arguments" "${NEOMANDIR}"
      usage
    fi
  else
    if [ -d "${NEOMANDIR}" ]
    then
      printf "\nUpdating %s" "${NEOMANDIR}"
      git -C "${NEOMANDIR}" pull
    else
      printf "\n%s does not exist or is not a directory. Re-run neoman without arguments" "${NEOMANDIR}"
      usage
    fi
  fi
  printf "\n"
  exit 0
}

[ -f "${INITIAL}" ] || {
  [ -d "${NEOMANDIR}" ] || {
    [ "${have_git}" ] || {
      install_package git
      have_git=$(type -p git)
      [ "${have_git}" ] || {
        printf "\n\nThe 'git' command is required to bootstrap Neoman"
        printf "\n\nInstall git and rerun 'neoman'\n"
        exit 1
      }
    }
    if [ "${tellme}" ]
    then
      echo "git clone https://github.com/doctorfree/neoman ${NEOMANDIR}"
    else
      git clone https://github.com/doctorfree/neoman "${NEOMANDIR}"
    fi
  }
  if [ -x "${NEOMANDIR}/scripts/install_configs.sh" ]
  then
    sudo "${NEOMANDIR}"/scripts/install_configs.sh ${narg} -s "${NEOMANDIR}"
  else
    if [ -f "${NEOMANDIR}/scripts/install_configs.sh" ]
    then
      chmod 755 "${NEOMANDIR}/scripts/install_configs.sh"
      sudo "${NEOMANDIR}"/scripts/install_configs.sh ${narg} -s "${NEOMANDIR}"
    else
      printf "\n\nThe ${NEOMANDIR}/scripts/install_configs.sh does not exist"
      printf "\n\nReinstall Neoman\n"
      exit 1
    fi
  fi
}

[ "${instmutt}" ] && {
  [ "${have_neomutt}" ] || ask_install NeoMutt neomutt
}

have_kitty=$(type -p kitty)
[ "${argument}" == "kitty" ] && {
  [ "${remove}" ] && {
    printf "\nRemoving kitty terminal emulator.\n\n"
    if [ "${prompt}" ]; then
      while true; do
        read -r -p "Do you wish to continue with kitty removal ? (y/n) " yn
        case $yn in
          [Yy]*)
            break
            ;;
          [Nn]*)
            printf "\nKitty removal aborted."
            printf "\nExiting.\n\n"
            exit 0
            ;;
          *)
            echo "Please answer yes or no."
            ;;
        esac
      done
    fi
    remove_kitty
    printf "\n${BOLD}Kitty removed${NORM}"
    printf "\nTo re-install Kitty run ${BOLD}'neoman kitty'${NORM}\n\n"
    exit 0
  }
  [ "${quiet}" ] || {
    printf "\nInstalling Kitty terminal emulator\n"
  }
  if [ "${prompt}" ]; then
    while true; do
      read -r -p "Do you wish to continue with kitty installation ? (y/n) " yn
      case $yn in
        [Yy]*)
          break
          ;;
        [Nn]*)
          printf "\nKitty installation aborted."
          printf "\nExiting.\n\n"
          exit 0
          ;;
        *)
          echo "Please answer yes or no."
          ;;
      esac
    done
  fi
  install_kitty
  exit 0
}

[ "${argument}" == "neovim" ] && {
  [ "${remove}" ] && {
    printf "\nRemoving Neovim text editor.\n\n"
    if [ "${prompt}" ]; then
      while true; do
        read -r -p "Do you wish to continue with Neovim removal ? (y/n) " yn
        case $yn in
          [Yy]*)
            break
            ;;
          [Nn]*)
            printf "\nNeovim removal aborted."
            printf "\nExiting.\n\n"
            exit 0
            ;;
          *)
            echo "Please answer yes or no."
            ;;
        esac
      done
    fi
    remove_neovim
    printf "\n${BOLD}Neovim removed${NORM}"
    printf "\nTo re-install Neovim run ${BOLD}'neoman neovim'${NORM}\n\n"
    exit 0
  }
  install_neovim
  exit 0
}

[ "${argument}" == "neomutt" ] && {
  [ "${remove}" ] && {
    printf "\nRemoving NeoMutt\n\n"
    if [ "${prompt}" ]; then
      while true; do
        read -r -p "Do you wish to continue with NeoMutt removal ? (y/n) " yn
        case $yn in
          [Yy]*)
            break
            ;;
          [Nn]*)
            printf "\nNeoMutt removal aborted."
            printf "\nExiting.\n\n"
            exit 0
            ;;
          *)
            echo "Please answer yes or no."
            ;;
        esac
      done
    fi
    remove_neomutt
    printf "\n${BOLD}NeoMutt removed${NORM}"
    printf "\nTo re-install NeoMutt run ${BOLD}'neoman neomutt'${NORM}\n\n"
    exit 0
  }
  install_neomutt
  exit 0
}

[ "${argument}" == "games" ] && {
  [ "${remove}" ] && {
    printf "\nRemoving ASCII games.\n\n"
    if [ "${prompt}" ]; then
      while true; do
        read -r -p "Do you wish to continue with Ascii games removal ? (y/n) " yn
        case $yn in
          [Yy]*)
            break
            ;;
          [Nn]*)
            printf "\nAscii games removal aborted."
            printf "\nExiting.\n\n"
            exit 0
            ;;
          *)
            echo "Please answer yes or no."
            ;;
        esac
      done
    fi
    remove_games
    printf "\n${BOLD}Ascii games removed${NORM}"
    printf "\nTo re-install Ascii games run ${BOLD}'neoman games'${NORM}\n\n"
    exit 0
  }
  install_games
  exit 0
}

install_required=1
[ -f "${INITIAL}" ] && {
  grep "__install_required__" "${INITIAL}" >/dev/null || {
    install_required=
  }
}
[ "${install_required}" ] && {
  [ "${have_curl}" ] || {
    install_package curl
    have_curl=$(type -p curl)
  }
  [ "${have_jq}" ] || {
    install_package jq
    have_jq=$(type -p jq)
  }
  [ "${have_wget}" ] || {
    install_package wget
    have_wget=$(type -p wget)
  }
  [ "${have_awk}" ] || install_package awk
  [ "${have_fc}" ] || install_package fontconfig
  [ "${have_mktemp}" ] && {
    [ "${have_unlink}" ] || install_package coreutils
  }
  [ "${have_unzip}" ] || install_package unzip

  # NeoMutt configuration user setup
  [ "${fedora}" ] && {
    if [ "${tellme}" ]
    then
      echo "sudo dnf install dnf-plugins-core -y"
      echo "sudo dnf copr enable flatcap/neomutt -y"
    else
      sudo dnf install dnf-plugins-core -y 2>/dev/null
      sudo dnf copr enable flatcap/neomutt -y 2>/dev/null
    fi
  }
  [ -f "${INITIAL}" ] && {
    echo "__install_required__=1" >>"${INITIAL}"
  }
}

neovim_install=1
[ -f "${INITIAL}" ] && {
  grep "__install_neovim__" "${INITIAL}" >/dev/null || {
    neovim_install=
  }
}
[ "${neovim_install}" ] && {
  # Prompt for Neovim install
  neovim_install=
  if [ "${have_neovim}" ]; then
    # Check if installed nvim is v0.9.0 or greater
    ver_head=$(nvim --version | head -1 | awk '{ print $2 }')
    nvim_ver=$(echo ${ver_head} | awk -F '-' '{ print $1 }' | sed -e "s/^v//")
    if [ "${nvim_ver}" ]; then
      compare_versions "${nvim_ver}" "0.9.0" >/dev/null 2>&1
      [ $? -eq 2 ] && {
        printf "\nCurrently installed Neovim is less than version 0.9"
        neovim_install=1
      }
    else
      # Don't know, install anyway
      neovim_install=1
    fi
  else
    neovim_install=1
  fi
  [ "${neovim_install}" ] && {
    printf "\n\n"
    [ "${prompt}" ] && {
      while true; do
        read -r -p "Install Neovim text editor ? (y/n) " yn
        case $yn in
          [Yy]*)
            neovim_install=1
            break
            ;;
          [Nn]*)
            printf "\nSkipping Neovim installation."
            printf "\nNeovim can be installed later with the command 'neoman neovim'.\n"
            neovim_install=
            break
            ;;
          *)
            echo "Please answer yes or no."
            ;;
        esac
      done
    }
  }
}

# Prompt for Ascii Games install
echo ""
games_install=1
[ -f "${INITIAL}" ] && {
  grep "__install_games__" "${INITIAL}" >/dev/null || {
    games_install=
  }
}
[ "${games_install}" ] && {
  games_install=
  if [ "${prompt}" ]; then
    while true; do
      read -r -p "Install ASCII Games ? (y/n) " yn
      case $yn in
        [Yy]*)
          games_install=1
          break
          ;;
        [Nn]*)
          games_install=
          printf "\nSkipping Ascii Games installation.\n"
          printf "\nGames can be installed later with the command 'neoman games'.\n"
          break
          ;;
        *)
          echo "Please answer yes or no."
          ;;
      esac
    done
  else
    games_install=1
  fi
}

kitty_install=1
[ -f "${INITIAL}" ] && {
  grep "__install_kitty__" "${INITIAL}" >/dev/null || {
    kitty_install=
  }
}
[ "${kitty_install}" ] && {
  # Kitty only installs on select architectures
  # In particular, Kitty is not supported on a Raspberry Pi armv7*
  case "${mach}" in
    x86_64 | aarch64* | armv8* | i386 | i686)
      install_kitty
      ;;
    *)
      true
      ;;
  esac
  [ -f "${INITIAL}" ] && {
    echo "__install_kitty__=1" >>"${INITIAL}"
  }
}

ucfgs_install=1
[ -f "${INITIAL}" ] && {
  grep "__install_ucfgs__" "${INITIAL}" >/dev/null || {
    ucfgs_install=
  }
}
[ "${ucfgs_install}" ] && {
  [ -x "${NEOMANDIR}/scripts/inst_user_conf.sh" ] && {
    "${NEOMANDIR}"/scripts/inst_user_conf.sh
    [ -f "${INITIAL}" ] && {
      echo "__install_ucfgs__=1" >>"${INITIAL}"
    }
  }
}

hbrew_install=1
[ -f "${INITIAL}" ] && {
  grep "__install_hbrew__" "${INITIAL}" >/dev/null || {
    hbrew_install=
  }
}
[ "${hbrew_install}" ] && {
  # Use Homebrew only on Darwin unless invoked with the 'brew' argument
  BREW_EXE="brew"
  have_brew=$(type -p brew)
  [ "${usebrew}" ] && {
    [ "${have_brew}" ] || {
      # Install Brew
      BREW_URL="${GHUC}/Homebrew/install/HEAD/install.sh"
      curl -fsSL "${BREW_URL}" >/tmp/brew-$$.sh
      [ $? -eq 0 ] || {
        rm -f /tmp/brew-$$.sh
        curl -kfsSL "${BREW_URL}" >/tmp/brew-$$.sh
      }
      [ -f /tmp/brew-$$.sh ] && {
        chmod 755 /tmp/brew-$$.sh
        [ "${quiet}" ] || printf "\n\tInstalling Homebrew, please be patient ... "
        NONINTERACTIVE=1 /bin/bash -c "/tmp/brew-$$.sh" >/dev/null 2>&1
        rm -f /tmp/brew-$$.sh
        [ "${quiet}" ] || printf "done"
      }
    }
  }
  if [ -f ${HOME}/.profile ]; then
    BASHINIT="${HOME}/.profile"
  else
    if [ -f ${HOME}/.bashrc ]; then
      BASHINIT="${HOME}/.bashrc"
    else
      BASHINIT="${HOME}/.profile"
    fi
  fi
  # shellcheck disable=SC2016
  if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    HOMEBREW_HOME="/home/linuxbrew/.linuxbrew"
    BREW_EXE="${HOMEBREW_HOME}/bin/brew"
  else
    if [ -x /usr/local/bin/brew ]; then
      HOMEBREW_HOME="/usr/local"
      BREW_EXE="${HOMEBREW_HOME}/bin/brew"
    else
      if [ -x /opt/homebrew/bin/brew ]; then
        HOMEBREW_HOME="/opt/homebrew"
        BREW_EXE="${HOMEBREW_HOME}/bin/brew"
      else
        [ "${usebrew}" ] && {
          echo "WARNING: Homebrew brew executable could not be located"
        }
      fi
    fi
  fi

  if [ -f "${BASHINIT}" ]; then
    [ "${usebrew}" ] && {
      grep "^eval \"\$(${BREW_EXE} shellenv)\"" "${BASHINIT}" >/dev/null || {
        echo 'eval "$(XXX shellenv)"' | sed -e "s%XXX%${BREW_EXE}%" >>"${BASHINIT}"
      }
    }
  else
    [ "${usebrew}" ] && {
      echo 'eval "$(XXX shellenv)"' | sed -e "s%XXX%${BREW_EXE}%" >"${BASHINIT}"
    }
  fi
  [ -f "${HOME}/.zshrc" ] && {
    [ "${usebrew}" ] && {
      grep "^eval \"\$(${BREW_EXE} shellenv)\"" "${HOME}/.zshrc" >/dev/null || {
        echo 'eval "$(XXX shellenv)"' | sed -e "s%XXX%${BREW_EXE}%" >>"${HOME}/.zshrc"
      }
    }
  }
  [ "${usebrew}" ] && eval "$(${BREW_EXE} shellenv)"

  [ "${usebrew}" ] && {
    have_brew=$(type -p brew)
    if [ "${have_brew}" ]; then
      BREW_EXE="brew"
    else
      [ "${BREW_EXE}" == "brew" ] || {
        BREWPATH=$(dirname ${BREW_EXE})
        pathadd "${BREWPATH}"
        have_brew=$(type -p brew)
      }
    fi

    export HOMEBREW_NO_INSTALL_CLEANUP=1
    export HOMEBREW_NO_ENV_HINTS=1
    export HOMEBREW_NO_AUTO_UPDATE=1
  }

  # Brew doesn't create a python symlink so we do so here
  [ "${usebrew}" ] && {
    install_package python
    python3_path=$(command -v python3)
    [ "${python3_path}" ] && {
      python_dir=$(dirname ${python3_path})
      if [ -w ${python_dir} ]; then
        if [ "${tellme}" ]
        then
          echo "rm -f ${python_dir}/python"
          echo "ln -s ${python_dir}/python3 ${python_dir}/python"
        else
          rm -f ${python_dir}/python
          ln -s ${python_dir}/python3 ${python_dir}/python
        fi
      else
        if [ "${tellme}" ]
        then
          echo "sudo rm -f ${python_dir}/python"
          echo "sudo ln -s ${python_dir}/python3 ${python_dir}/python"
        else
          sudo rm -f ${python_dir}/python
          sudo ln -s ${python_dir}/python3 ${python_dir}/python
        fi
      fi
    }
  }
  [ -f "${INITIAL}" ] && {
    echo "__install_hbrew__=1" >>"${INITIAL}"
  }
}

python_install=1
[ -f "${INITIAL}" ] && {
  grep "__install_python__" "${INITIAL}" >/dev/null || {
    python_install=
  }
}
[ "${python_install}" ] && {
  PYTHON="python3"
  have_python3=$(type -p python3)
  [ "${have_python3}" ] || {
    echo "[ERROR] Could not find python3 binary."
    echo "Please add it to your \$PATH and rerun neoman."
    exit 1
  }

  have_pip=$(type -p pip3)
  [ "${have_pip}" ] || {
    [ "${quiet}" ] || {
      printf "\n\tInstalling pip ..."
    }
    if [ "${darwin}" ]; then
      if [ "${tellme}" ]
      then
        echo "${PYTHON} -m ensurepip --upgrade"
      else
        ${PYTHON} -m ensurepip --upgrade
      fi
    else
      if [ "${debian}" ]; then
        if [ "${tellme}" ]
        then
          echo "sudo ${APT} install python3-pip"
        else
          sudo ${APT} install python3-pip >/dev/null 2>&1
        fi
      else
        if [ "${arch}" ]; then
          if [ "${tellme}" ]
          then
            echo "sudo pacman -S --noconfirm python-pip"
          else
            sudo pacman -S --noconfirm python-pip >/dev/null 2>&1
          fi
        else
          if [ "${tellme}" ]
          then
            echo "sudo ${DNF} install python3-pip"
          else
            sudo ${DNF} install python3-pip >/dev/null 2>&1
          fi
        fi
      fi
    fi
    [ "${quiet}" ] || {
      printf " done"
    }
  }

  for pkg in setuptools asciimatics ddgr rainbowstream socli future \
    xtermcolor ffmpeg-python pyaudio term-image urlscan openai; do
    if ${PYTHON} -m pip list 2>/dev/null | grep ${pkg} >/dev/null; then
      ${PYTHON} -m pip install --upgrade ${pkg} >/dev/null 2>&1
    else
      [ "${quiet}" ] || {
        printf "\n\tInstalling ${pkg} ..."
      }
      ${PYTHON} -m pip install ${pkg} >/dev/null 2>&1
      [ "${quiet}" ] || {
        printf " done"
      }
    fi
  done
  [ -f "${INITIAL}" ] && {
    echo "__install_python__=1" >>"${INITIAL}"
  }
}

sunbeam_install=1
[ -f "${INITIAL}" ] && {
  grep "__install_sunbeam__" "${INITIAL}" >/dev/null || {
    sunbeam_install=
  }
}
[ "${sunbeam_install}" ] && {
  [ -x "${NEOMANDIR}/scripts/install_sunbeam.sh" ] && {
    "${NEOMANDIR}"/scripts/install_sunbeam.sh
    [ -f "${INITIAL}" ] && {
      echo "__install_sunbeam__=1" >>"${INITIAL}"
    }
  }
}

utils_install=1
[ -f "${INITIAL}" ] && {
  grep "__install_utils__" "${INITIAL}" >/dev/null || {
    utils_install=
  }
}
[ "${utils_install}" ] && {
  have_npm=$(type -p npm)
  [ "${have_npm}" ] || install_package node
  have_npm=$(type -p npm)
  have_dialog=$(type -p dialog)
  [ "${have_dialog}" ] || install_package dialog
  have_figlet=$(type -p figlet)
  [ "${have_figlet}" ] || install_package figlet
  have_lolcat=$(type -p lolcat)
  [ "${have_lolcat}" ] || install_package lolcat
  have_mplayer=$(type -p mplayer)
  [ "${have_mplayer}" ] || install_package mplayer
  have_ranger=$(type -p ranger)
  [ "${have_ranger}" ] || install_package ranger
  have_tmux=$(type -p tmux)
  [ "${have_tmux}" ] || install_package tmux
  have_w3m=$(type -p w3m)
  [ "${have_w3m}" ] || install_package w3m
  have_aic=$(type -p ascii-image-converter)
  [ "${have_aic}" ] || {
    [ "${quiet}" ] || printf "\n\tInstalling ascii-image-converter ..."
    # Try Brew first
    brewed=
    [ "${usebrew}" ] && {
      brew install --quiet \
        TheZoraiz/ascii-image-converter/ascii-image-converter >/dev/null 2>&1
      have_aic=$(type -p ascii-image-converter)
      [ "${have_aic}" ] && brewed=1
    }
    [ "${brewed}" ] || {
      have_go=$(type -p go)
      [ "${have_go}" ] && {
        go install github.com/TheZoraiz/ascii-image-converter@latest >/dev/null 2>&1
      }
    }
    [ "${quiet}" ] || printf " done"
  }
  have_asciinema=$(type -p asciinema)
  [ "${have_asciinema}" ] || install_package asciinema
  have_gnupg=$(type -p gpg)
  [ "${have_gnupg}" ] || install_package gnupg
  have_zip=$(type -p zip)
  [ "${have_zip}" ] || install_package zip
  install_package imagemagick
  have_cmatrix=$(type -p cmatrix)
  [ "${have_cmatrix}" ] || install_package cmatrix
  have_neomutt=$(type -p neomutt)
  [ "${have_neomutt}" ] || install_package neomutt
  have_newsboat=$(type -p newsboat)
  [ "${have_newsboat}" ] || install_package newsboat
  have_speedtest=$(type -p speedtest-cli)
  [ "${have_speedtest}" ] || install_package speedtest-cli
  have_neofetch=$(type -p neofetch)
  [ "${have_neofetch}" ] || install_package neofetch
  have_xclip=$(type -p xclip)
  [ "${have_xclip}" ] || install_package xclip

  # Install btop if not already present
  have_btop=$(type -p btop)
  [ "${have_btop}" ] || {
    if [ "${platform}" == "Darwin" ]; then
      install_package btop
    else
      PROJECT=btop
      install_external_package
    fi
  }
  # Install any2ascii if not already present
  have_jp2a=$(type -p jp2a)
  [ "${have_jp2a}" ] || {
    PROJECT=any2ascii
    install_external_package
  }
  # Install endoh1 if not already present
  [ -x /usr/local/bin/show_endo ] || {
    [ -x /usr/bin/show_endo ] || {
      PROJECT=endoh1
      install_external_package
    }
  }
  # Install aewan if not already present
  [ -x /usr/local/bin/aewan ] || {
    [ -x /usr/bin/aewan ] || {
      PROJECT=asciiville-aewan
      install_external_package
    }
  }
  # Install cbftp if not already present
  [ -x /usr/local/bin/cbftp ] || {
    [ -x /usr/bin/cbftp ] || {
      PROJECT=cbftp
      install_external_package
    }
  }
  [ -f "${INITIAL}" ] && {
    echo "__install_utils__=1" >>"${INITIAL}"
  }
}

# Install Neovim
[ "${neovim_install}" ] && install_neovim

# Install Ascii Games
[ "${games_install}" ] && install_games

have_mapscii=$(type -p mapscii)
[ "${have_mapscii}" ] || {
  [ "${have_npm}" ] && npm install mapscii >/dev/null 2>&1
}

have_tuir=$(type -p tuir)
[ "${have_tuir}" ] || {
  cd "${HOME}" || echo "Could not enter $HOME"
  [ -d tuir ] && mv tuir tuir$$
  git clone https://gitlab.com/ajak/tuir.git >/dev/null 2>&1
  [ -d tuir ] && {
    cd tuir || echo "Could not enter tuir"
    cat requirements.txt | sed -e "s/requests=.*/requests>=2.20.0/" >/tmp/tuireq$$
    cp /tmp/tuireq$$ requirements.txt
    rm -f /tmp/tuireq$$
    TUIR_DIR=$(pwd)
    ${PYTHON} -m pip install -e "${TUIR_DIR}" >/dev/null 2>&1
    cd ..
    rm -rf tuir
  }
  [ -d tuir$$ ] && mv tuir$$ tuir
}

pkg=video-to-ascii
if ${PYTHON} -m pip list 2>/dev/null | grep ${pkg} >/dev/null; then
  ${PYTHON} -m pip install --upgrade ${pkg} "${VOPT}" >/dev/null 2>&1
else
  [ "${quiet}" ] || {
    printf "\n\tInstalling ${pkg} ..."
  }
  ${PYTHON} -m pip install ${pkg} "${VOPT}" >/dev/null 2>&1
  [ "${quiet}" ] || {
    printf " done"
  }
fi

install_pipx

# Install the 'rich' command if not already installed
[ "${have_rich}" ] || {
  [ "${quiet}" ] || {
    printf "\n\tInstalling rich-cli ..."
  }
  pipx install rich-cli >/dev/null 2>&1
  [ "${quiet}" ] || {
    printf " done"
  }
}

touch ${HOME}/.tetris

[ "${usebrew}" ] && {
  [ "${have_brew}" ] && {
    [ "${quiet}" ] || {
      printf "\n\tCleaning up Homebrew ... "
    }
    brew cleanup --prune=all --quiet >/dev/null 2>&1
    [ "${quiet}" ] || {
      printf "done"
    }
  }
}
printf "\n"

JETB_URL="${GHUC}/JetBrains/JetBrainsMono/master/install_manual.sh"
curl -fsSL "${JETB_URL}" >/tmp/jetb-$$.sh
[ $? -eq 0 ] || {
  rm -f /tmp/jetb-$$.sh
  curl -kfsSL "${JETB_URL}" >/tmp/jetb-$$.sh
}
[ -f /tmp/jetb-$$.sh ] && {
  chmod 755 /tmp/jetb-$$.sh
  [ "${quiet}" ] || printf "\n\tInstalling JetBrains Mono font ... "
  /bin/bash -c "/tmp/jetb-$$.sh" >/dev/null 2>&1
  rm -f /tmp/jetb-$$.sh
  [ "${quiet}" ] || printf "done"
}

[ "${usebrew}" ] && {
  [ "${BREW_EXE}" ] || BREW_EXE=brew
}

[ "${quiet}" ] || {
  printf "\n\n${BOLD}Neoman Initialization Complete${NORM}\n"
  printf "\nVisit the Neoman Wiki at:"
  printf "\n\t${BOLD}https://github.com/doctorfree/neoman/wiki${NORM}\n"
}

if [ "$ask_anim" ]; then
  type -p asciisplash >/dev/null && {
    [ "${prompt}" ] && {
      while true; do
        read -r -p "View an ASCII animation ? (y/n) " yn
        case $yn in
          [Yy]*)
            break
            ;;
          [Nn]*)
            printf "\nExiting.\n"
            exit 0
            ;;
          *)
            echo "Please answer yes or no."
            ;;
        esac
      done
    }
    asciisplash -c 1 -a -i
  }
else
  [ "${quiet}" ] || {
    type -p asciisplash >/dev/null && {
      printf "View an Neoman animation with:"
      printf "\n\t${BOLD}asciisplash -c 1 -a -i${NORM}\n"
    }
  }
fi
