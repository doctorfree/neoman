#!/usr/bin/env bash
#
# SC2001,SC2016,SC2006,SC2086,SC2181,SC2129,SC2059,SC2164
# shellcheck disable=SC2181

export PATH="$HOME/.local/bin:$PATH"

have_wget=$(type -p wget)
have_curl=$(type -p curl)
have_jq=$(type -p jq)
platform=$(uname -s)
mach=$(uname -m)
case "${mach}" in
  arm*)
    arch="arm64"
    ;;
  i386 | i686)
    if [ "${platform}" == "Darwin" ]
    then
      arch="amd64"
    else
      arch="386"
    fi
    ;;
  *)
    arch="amd64"
    ;;
esac

dl_asset() {
  dlplat="$1"
  OWNER=pomdtr
  PROJECT=sunbeam
  API_URL="https://api.github.com/repos/${OWNER}/${PROJECT}/releases/latest"
  DL_URL=
  [ "${have_curl}" ] && [ "${have_jq}" ] && {
    DL_URL=$(curl --silent "${API_URL}" \
      | jq --raw-output '.assets | .[]?.browser_download_url' \
      | grep "${dlplat}_${arch}\.tar\.gz$")
  }
  [ "${DL_URL}" ] && {
    [ "${have_wget}" ] && {
      printf "\nDownloading sunbeam release asset ..."
      TEMP_ASS="$(mktemp --suffix=.tgz)"
      wget --quiet -O "${TEMP_ASS}" "${DL_URL}" >/dev/null 2>&1
      chmod 644 "${TEMP_ASS}"
      mkdir -p "${HOME}"/.local/share/sunbeam
      tar -C "${HOME}"/.local/share/sunbeam -xzf "${TEMP_ASS}"
      rm -f "${TEMP_ASS}"
      printf " done"
    }
  }
}

have_sunbeam=$(command -v sunbeam)
[ "${have_sunbeam}" ] && {
  printf "\nSunbeam already installed as %s" "${have_sunbeam}"
  printf "\nRemove sunbeam and rerun this script to reinstall Sunbeam"
  printf "\nExiting without installing\n"
  exit 0
}
[ -d "$HOME"/.local ] || mkdir -p "$HOME"/.local
[ -d "$HOME"/.local/bin ] || mkdir -p "$HOME"/.local/bin
[ -d "$HOME"/.local/share ] || mkdir -p "$HOME"/.local/share
if [ "${platform}" == "Darwin" ]
then
  dl_asset darwin
else
  dl_asset linux
fi

[ -f "${HOME}"/.local/share/sunbeam/completions/sunbeam.bash ] && {
  [ -d "${HOME}"/.local/share/bash-completion/completions ] || {
    mkdir -p "${HOME}"/.local/share/bash-completion/completions
  }
  [ -d "${HOME}"/.local/share/bash-completion/completions ] && {
    cp "${HOME}"/.local/share/sunbeam/completions/sunbeam.bash \
       "${HOME}"/.local/share/bash-completion/completions/sunbeam
  }
}
[ -f "${HOME}"/.local/share/sunbeam/completions/sunbeam.fish ] && {
  [ -d "${HOME}"/.local/share/fish/vendor_completions.d ] || {
    mkdir -p "${HOME}"/.local/share/fish/vendor_completions.d
  }
  [ -d "${HOME}"/.local/share/fish/vendor_completions.d ] && {
    cp "${HOME}"/.local/share/sunbeam/completions/sunbeam.fish \
       "${HOME}"/.local/share/fish/vendor_completions.d/sunbeam.fish
  }
}
[ -f "${HOME}"/.local/share/sunbeam/completions/sunbeam.zsh ] && {
  [ -d "${HOME}"/.local/share/zsh/vendor-completions ] || {
    mkdir -p "${HOME}"/.local/share/zsh/vendor-completions
  }
  [ -d "${HOME}"/.local/share/zsh/vendor-completions ] && {
    cp "${HOME}"/.local/share/sunbeam/completions/sunbeam.zsh \
       "${HOME}"/.local/share/zsh/vendor-completions/_sunbeam
  }
}

if [ -f "${HOME}"/.local/share/sunbeam/sunbeam ]
then
  mv "${HOME}"/.local/share/sunbeam/sunbeam "$HOME"/.local/bin/sunbeam
  chmod 755 "$HOME"/.local/bin/sunbeam
else
  printf "\n\nERROR: Sunbeam download failed\n"
fi
