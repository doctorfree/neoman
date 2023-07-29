#!/bin/bash
#
# inst_user_conf.sh - initialize user configuration files
#
# shellcheck disable=SC2001,SC2002,SC2016,SC2006,SC2059,SC2086,SC2089,SC2181,SC2129

darwin=
platform=$(uname -s)
if [ "${platform}" == "Darwin" ]; then
  TOP="/usr/local"
  darwin=1
else
  TOP="/usr"
fi
CONFDIR=${TOP}/share/neoman
USERCONF="${HOME}/.config"
LMANDIR="${USERCONF}/nvim-Lazyman"
NEOMANDIR="${USERCONF}/neoman"
GHUC="https://raw.githubusercontent.com"
OWNER=doctorfree
BOLD=$(tput bold 2>/dev/null)
NORM=$(tput sgr0 2>/dev/null)

[ -d ${CONFDIR}/neomutt ] && {
  [ -d ${USERCONF}/neomutt ] || {
    cp -a ${CONFDIR}/neomutt ${USERCONF}/neomutt
    [ "${console}" ] && {
      [ -f ${CONFDIR}/console/neomutt/mailcap ] && {
        cp ${CONFDIR}/console/neomutt/mailcap ${USERCONF}/neomutt/mailcap
      }
    }
    chmod 600 ${USERCONF}/neomutt/accounts/*
    chmod 750 ${USERCONF}/neomutt/accounts
    [ -d ${USERCONF}/neomutt/tmp ] || mkdir ${USERCONF}/neomutt/tmp
    chmod 750 ${USERCONF}/neomutt/tmp
    [ "${quiet}" ] || {
      echo ""
      echo "A ${USERCONF}/neomutt/ NeoMutt email client configuration"
      echo "has been created for you. Edit your name, email address, and"
      echo "email account credentials in ${USERCONF}/neomutt/accounts/*"
      echo ""
      echo "A good starting point for the NeoMutt user is the NeoMutt Guide at:"
      echo "https://neomutt.org/guide/"
      echo ""
    }
  }
}

# Custom W3M configuration for this user unless one exists
[ -d ${CONFDIR}/w3m ] && {
  if [ -d ${HOME}/.w3m ]; then
    for w3mconf in "${CONFDIR}"/w3m/*; do
      [ "${w3mconf}" == "${CONFDIR}/w3m/*" ] && continue
      bconf=$(basename "${w3mconf}")
      [ -f "${HOME}/.w3m/${bconf}" ] || {
        cp "${w3mconf}" "${HOME}/.w3m/${bconf}"
        [ "${bconf}" == "mailcap" ] && {
          [ "${console}" ] && {
            [ -f ${CONFDIR}/console/w3m/mailcap ] && {
              cp ${CONFDIR}/console/w3m/mailcap ${HOME}/.w3m/mailcap
            }
          }
        }
      }
    done
  else
    cp -a ${CONFDIR}/w3m ${HOME}/.w3m
    [ "${console}" ] && {
      [ -f ${CONFDIR}/console/w3m/mailcap ] && {
        cp ${CONFDIR}/console/w3m/mailcap ${HOME}/.w3m/mailcap
      }
    }
  fi
  # Verify text/markdown is a recognized MIME type
  [ -f /etc/mime.types ] && {
    grep ^text/markdown /etc/mime.types >/dev/null || {
      cp /etc/mime.types ${HOME}/.w3m/mime.types
      echo 'text/markdown    md markdown' >>${HOME}/.w3m/mime.types
    }
  }
}

# Setup default newsboat configuration for this user unless one exists
[ -d ${CONFDIR}/newsboat ] && {
  if [ -d ${USERCONF}/newsboat ]; then
    cp -an ${CONFDIR}/newsboat ${USERCONF}
  else
    [ -d ${HOME}/.newsboat ] || {
      cp -a ${CONFDIR}/newsboat ${USERCONF}/newsboat
    }
  fi
}
[ -f ${USERCONF}/newsboat/urls ] && {
  chmod 600 ${USERCONF}/newsboat/urls
}
[ -f ${USERCONF}/newsboat/bookmark.sh ] && {
  chmod 755 ${USERCONF}/newsboat/bookmark.sh
}
[ -f ${USERCONF}/newsboat/kitty-img-pager.sh ] && {
  chmod 755 ${USERCONF}/newsboat/kitty-img-pager.sh
}

# Setup default btop configuration for this user unless one exists
[ -f ${CONFDIR}/btop/btop.conf ] && {
  if [ -d ${USERCONF}/btop ]; then
    [ -f ${USERCONF}/btop/btop.conf ] || {
      cp ${CONFDIR}/btop/btop.conf ${USERCONF}/btop/btop.conf
      chmod 640 ${USERCONF}/btop/btop.conf
    }
  else
    cp -a ${CONFDIR}/btop ${USERCONF}/btop
    chmod 640 ${USERCONF}/btop/btop.conf
  fi
}

# Setup default khard configuration for this user unless one exists
[ -d ${CONFDIR}/khard ] && {
  [ -d ${USERCONF}/khard ] || {
    cp -a ${CONFDIR}/khard ${USERCONF}/khard
    chmod 640 ${USERCONF}/khard/khard.conf
  }
  [ -d ${HOME}/.contacts ] || {
    mkdir -p ${HOME}/.contacts
  }
  [ -d ${HOME}/.contacts/family ] || {
    mkdir -p ${HOME}/.contacts/family
  }
  [ -d ${HOME}/.contacts/friends ] || {
    mkdir -p ${HOME}/.contacts/friends
  }
}

KITTYCONFDIR="${USERCONF}/kitty"
KITTYCONF="${KITTYCONFDIR}/neoman.conf"
# Setup default kitty configuration for this user unless one exists
[ "${quiet}" ] || {
  printf "\n\tInstalling Kitty configuration in ${KITTYCONFDIR} ..."
}
if [ -d ${KITTYCONFDIR} ]; then
  cp -an ${CONFDIR}/kitty ${USERCONF}
else
  cp -a ${CONFDIR}/kitty ${KITTYCONFDIR}
fi
[ -f ${KITTYCONF} ] && {
  if [ "${BROWSER}" ]; then
    # If the user has set the BROWSER environment variable then use it
    browser_app=$(echo "${BROWSER}" | awk ' { print $1 } ')
    browser_app=$(basename ${browser_app})
    have_browser=$(type -p ${browser_app})
    [ "${have_browser}" ] || BROWSER=default
  else
    BROWSER=default
    have_browser=1
  fi
  cat "${KITTYCONF}" | sed -e "s%__SET__BROWSER__%${BROWSER}%" >/tmp/browser$$
  cp /tmp/browser$$ "${KITTYCONF}"
  rm -f /tmp/browser$$
}
[ -f ${KITTYCONFDIR}/kitty.conf ] || cp ${KITTYCONF} ${KITTYCONFDIR}/kitty.conf
[ "${quiet}" ] || {
  printf " done"
}

# Setup default rifle configuration for this user unless one exists
[ -f ${CONFDIR}/rifle.conf ] && {
  [ -f ${USERCONF}/ranger/rifle.conf ] || {
    [ "${quiet}" ] || {
      printf "\n\tInstalling Ranger rifle configuration in ${USERCONF}/ranger/ ..."
    }
    [ -d ${USERCONF}/ranger ] || mkdir -p ${USERCONF}/ranger
    cp ${CONFDIR}/rifle.conf ${USERCONF}/ranger/rifle.conf
    [ "${quiet}" ] || {
      printf " done"
    }
  }
}

# Setup default rainbowstream configuration for this user unless one exists
[ -f ${CONFDIR}/rainbow_config.json ] && {
  [ -f ${HOME}/.rainbow_config.json ] || {
    [ "${quiet}" ] || {
      printf "\n\tSetup rainbowstream configuration as ${HOME}/.rainbow_config.json ..."
    }
    cp ${CONFDIR}/rainbow_config.json ${HOME}/.rainbow_config.json
    [ "${quiet}" ] || {
      printf " done"
    }
  }
}

# Setup default tuir configuration for this user unless one exists
[ -d ${CONFDIR}/tuir ] && {
  [ "${quiet}" ] || {
    printf "\n\tInstalling Tuir configuration in ${USERCONF}/tuir ..."
  }
  if [ -d ${USERCONF}/tuir ]; then
    cp -an ${CONFDIR}/tuir ${USERCONF}
    [ "${console}" ] && {
      [ -f ${CONFDIR}/console/tuir/mailcap ] && {
        cp ${CONFDIR}/console/tuir/mailcap ${USERCONF}/tuir/mailcap
      }
    }
    chmod 600 ${USERCONF}/tuir/tuir.cfg
  else
    cp -a ${CONFDIR}/tuir ${USERCONF}/tuir
    [ "${console}" ] && {
      [ -f ${CONFDIR}/console/tuir/mailcap ] && {
        cp ${CONFDIR}/console/tuir/mailcap ${USERCONF}/tuir/mailcap
      }
    }
    chmod 600 ${USERCONF}/tuir/tuir.cfg
  fi
  [ "${quiet}" ] || {
    printf " done"
  }
}

# Setup default tmux configuration for this user
[ -f ${CONFDIR}/tmux.conf ] && {
  if [ -f ${HOME}/.tmux.conf ]; then
    diff -u -B <(grep -vE '^\s*(#|$)' ${CONFDIR}/tmux.conf) <(grep -vE '^\s*(#|$)' ${HOME}/.tmux.conf) >/dev/null || {
      echo ""
      echo "Neoman includes extensive configuration for tmux."
      echo "An existing $HOME/.tmux.conf has been detected."
      echo "In order to enable many Neoman tmux features,"
      echo "it is necessary to install a customized $HOME/.tmux.conf."
      echo ""
      echo "Please answer if you would like to:"
      printf "\n\t[A]ppend customization"
      printf "\n\t[B]ackup and customize"
      printf "\n\t[O]verwrite existing"
      printf "\n\t[S]kip customization\n"
      echo "Answer 'a', 'b', 'o', or 's'"
      echo ""
      while true; do
        read -r -p "Append/Backup/Overwrite/Skip tmux configuration? (a/b/o/s) " customize
        case $customize in
          [Aa]*)
            cat ${CONFDIR}/tmux.conf >>${HOME}/.tmux.conf
            echo ""
            echo "Neoman tmux configurations are applied"
            echo "The file ${CONFDIR}/tmux.conf"
            echo "was appended to $HOME/.tmux.conf"
            echo "The Neoman additions follow the comment 'Neoman'"
            echo "Please review these changes and customize as needed"
            break
            ;;
          [Bb]*)
            cp ${HOME}/.tmux.conf ${HOME}/.tmux.conf.bak$$
            cp ${CONFDIR}/tmux.conf ${HOME}/.tmux.conf
            echo ""
            echo "Neoman tmux configurations are applied"
            echo "The file ${CONFDIR}/tmux.conf"
            echo "was copied to $HOME/.tmux.conf"
            echo "A backup of the previous file was created at $HOME/.tmux.conf.bak$$"
            break
            ;;
          [Oo]*)
            cp ${CONFDIR}/tmux.conf ${HOME}/.tmux.conf
            echo ""
            echo "Neoman tmux configurations are applied"
            echo "The file ${CONFDIR}/tmux.conf"
            echo "was copied to $HOME/.tmux.conf"
            break
            ;;
          [Ss]*)
            echo ""
            echo "Neoman tmux configurations have not been applied"
            echo "The file $HOME/.tmux.conf remains unmodified"
            echo "Some Neoman features will not work properly with tmux"
            echo ""
            echo "The file ${CONFDIR}/tmux.conf"
            echo "contains the Neoman tmux customizations."
            echo "To fully enable Neoman tmux features, merge"
            echo "${CONFDIR}/tmux.conf with $HOME/.tmux.conf"
            break
            ;;
          *)
            echo "Please answer 'a', 'b', 'o', or 's'"
            ;;
        esac
      done
    }
  else
    [ "${quiet}" ] || {
      printf "\n\tInstalling Tmux configuration in ${HOME}/.tmux.conf ..."
    }
    cp ${CONFDIR}/tmux.conf ${HOME}/.tmux.conf
    [ "${quiet}" ] || {
      printf " done"
    }
  fi
}

TPM="${HOME}/.tmux/plugins/tpm"

status_dots=
[ -d ${TPM} ] || {
  have_git=$(type -p git)
  [ "${have_git}" ] && {
    [ "${quiet}" ] || {
      printf "\n\tInstalling Tmux plugins ..."
      status_dots=1
    }
    git clone https://github.com/tmux-plugins/tpm ${TPM} >/dev/null 2>&1
  }
}

[ -x ${TPM}/bin/install_plugins ] && ${TPM}/bin/install_plugins >/dev/null 2>&1
[ "${status_dots}" ] && {
  [ "${quiet}" ] || {
    printf " done"
  }
  status_dots=
}
