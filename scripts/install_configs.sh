#!/bin/bash
#
# shellcheck disable=SC1090,SC2001

PKG="neoman"
DESTDIR="/usr"
NEOMANDIR="${HOME}/.config/neoman"
SUDO=sudo
platform=$(uname -s)
[ "${platform}" == "Darwin" ] && DESTDIR="/usr/local"

usage() {
  printf "\n\nUsage: ./install [-n] [-s path] [-u]"
  printf "\nWhere:"
  printf "\n\t-n indicates dry run, tell me what you would do but don't do it"
  printf "\n\t-s 'path' indicates do not use sudo, use 'path' as Neoman home"
  printf "\n\t-u displays this usage message and exits"
  printf "\n\n\tMust be run as a user with sudo privilege from inside"
  printf "\n\ta neoman git repository previously cloned with the command:"
  printf "\n\t\tgit clone https://github.com/doctorfree/neoman"
  printf "\n\tAfter cloning, 'cd neoman' and run the command './install'\n"
  exit 1
}

tellme=
while getopts ":ns:u" flag; do
  case $flag in
    n)
      tellme=1
      ;;
    s)
      NEOMANDIR="${OPTARG}"
      SUDO=
      ;;
    u)
      usage
      ;;
    \?)
      echo "Invalid option: $flag"
      usage
      ;;
  esac
done
shift $(( OPTIND - 1 ))

if [ -d "${NEOMANDIR}" ]
then
  cd "${NEOMANDIR}" || exit 1
else
  printf "\n\n%s does not exist or is not a directory" "${NEOMANDIR}"
  printf "\nReinstall Neoman"
  exit 1
fi

for dir in "${DESTDIR}" "${DESTDIR}/share" "${DESTDIR}/share/man" \
  "${DESTDIR}/share/applications" "${DESTDIR}/share/doc" \
  "${DESTDIR}/share/doc/${PKG}" \
  "${DESTDIR}/share/${PKG}"; do
  [ -d "${dir}" ] || {
    if [ "${tellme}" ]
    then
      echo "${SUDO} mkdir -p ${dir}"
    else
      ${SUDO} mkdir -p "${dir}"
    fi
  }
done

if [ "${tellme}" ]
then
  echo "${SUDO} cp neoman ${DESTDIR}/bin"
else
  ${SUDO} cp neoman "${DESTDIR}"/bin
fi
if [ "${tellme}" ]
then
  echo "${SUDO} cp neoman.desktop ${DESTDIR}/share/applications"
else
  ${SUDO} cp neoman.desktop "${DESTDIR}/share/applications"
fi
[ -d "${DESTDIR}/share/${PKG}/btop" ] || {
  if [ "${tellme}" ]
  then
    echo "${SUDO} cp -a btop ${DESTDIR}/share/${PKG}/btop"
  else
    ${SUDO} cp -a btop "${DESTDIR}/share/${PKG}/btop"
  fi
}
[ -d "${DESTDIR}/share/${PKG}/kitty" ] || {
  if [ "${tellme}" ]
  then
    echo "${SUDO} cp -a kitty ${DESTDIR}/share/${PKG}/kitty"
  else
    ${SUDO} cp -a kitty "${DESTDIR}/share/${PKG}/kitty"
  fi
}
[ -d "${DESTDIR}/share/${PKG}/neomutt" ] || {
  if [ "${tellme}" ]
  then
    echo "${SUDO} cp -a neomutt ${DESTDIR}/share/${PKG}/neomutt"
  else
    ${SUDO} cp -a neomutt "${DESTDIR}/share/${PKG}/neomutt"
  fi
}
[ -d "${DESTDIR}/share/${PKG}/newsboat" ] || {
  if [ "${tellme}" ]
  then
    echo "${SUDO} cp -a newsboat ${DESTDIR}/share/${PKG}/newsboat"
  else
    ${SUDO} cp -a newsboat "${DESTDIR}/share/${PKG}/newsboat"
  fi
}
[ -d "${DESTDIR}/share/${PKG}/w3m" ] || {
  if [ "${tellme}" ]
  then
    echo "${SUDO} cp -a w3m ${DESTDIR}/share/${PKG}/w3m"
  else
    ${SUDO} cp -a w3m "${DESTDIR}/share/${PKG}/w3m"
  fi
}
[ -f "${DESTDIR}/share/${PKG}/tmux.conf" ] || {
  if [ "${tellme}" ]
  then
    echo "${SUDO} cp tmux.conf ${DESTDIR}/share/${PKG}"
  else
    ${SUDO} cp tmux.conf "${DESTDIR}/share/${PKG}"
  fi
}
[ -f "${DESTDIR}/share/${PKG}/rifle.conf" ] || {
  if [ "${tellme}" ]
  then
    echo "${SUDO} cp rifle.conf ${DESTDIR}/share/${PKG}"
  else
    ${SUDO} cp rifle.conf "${DESTDIR}/share/${PKG}"
  fi
}
if [ "${tellme}" ]
then
  echo "${SUDO} cp copyright ${DESTDIR}/share/doc/${PKG}"
else
  ${SUDO} cp copyright "${DESTDIR}/share/doc/${PKG}"
fi
if [ "${tellme}" ]
then
  echo "${SUDO} cp LICENSE ${DESTDIR}/share/doc/${PKG}"
else
  ${SUDO} cp LICENSE "${DESTDIR}/share/doc/${PKG}"
fi
if [ "${tellme}" ]
then
  echo "${SUDO} cp CHANGELOG.md ${DESTDIR}/share/doc/${PKG}"
else
  ${SUDO} cp CHANGELOG.md "${DESTDIR}/share/doc/${PKG}"
fi
if [ "${tellme}" ]
then
  echo "${SUDO} cp README.md ${DESTDIR}/share/doc/${PKG}"
else
  ${SUDO} cp README.md "${DESTDIR}/share/doc/${PKG}"
fi
if [ "${tellme}" ]
then
  echo "${SUDO} cp VERSION ${DESTDIR}/share/doc/${PKG}"
else
  ${SUDO} cp VERSION "${DESTDIR}/share/doc/${PKG}"
fi

if [ "${tellme}" ]
then
  echo "${SUDO} cp share/menu/neoman ${DESTDIR}/share/menu/neoman"
else
  ${SUDO} cp share/menu/neoman "${DESTDIR}/share/menu/neoman"
fi
[ -d "${DESTDIR}/share/${PKG}/figlet-fonts" ] || {
  if [ "${tellme}" ]
  then
    echo "${SUDO} cp -a share/figlet-fonts ${DESTDIR}/share/${PKG}/figlet-fonts"
  else
    ${SUDO} cp -a share/figlet-fonts "${DESTDIR}/share/${PKG}/figlet-fonts"
  fi
}
[ -d "${DESTDIR}/share/${PKG}/neofetch-themes" ] || {
  if [ "${tellme}" ]
  then
    echo "${SUDO} cp -a share/neofetch-themes ${DESTDIR}/share/${PKG}/neofetch-themes"
  else
    ${SUDO} cp -a share/neofetch-themes "${DESTDIR}/share/${PKG}/neofetch-themes"
  fi
}

if [ "${tellme}" ]
then
  echo "${SUDO} chmod 644 ${DESTDIR}/share/${PKG}/figlet-fonts/*"
else
  ${SUDO} chmod 644 "${DESTDIR}"/share/${PKG}/figlet-fonts/*
fi
find "${DESTDIR}/share/doc/${PKG}" -type d | while read -r dir; do
  if [ "${tellme}" ]
  then
    echo "${SUDO} chmod 755 ${dir}"
  else
    ${SUDO} chmod 755 "${dir}"
  fi
done
find "${DESTDIR}/share/doc/${PKG}" -type f | while read -r f; do
  if [ "${tellme}" ]
  then
    echo "${SUDO} chmod 644 ${f}"
  else
    ${SUDO} chmod 644 "${f}"
  fi
done
find "${DESTDIR}/share/${PKG}" -type d | while read -r dir; do
  if [ "${tellme}" ]
  then
    echo "${SUDO} chmod 755 ${dir}"
  else
    ${SUDO} chmod 755 "${dir}"
  fi
done
find "${DESTDIR}/share/${PKG}" -type f | while read -r f; do
  if [ "${tellme}" ]
  then
    echo "${SUDO} chmod 644 ${f}"
  else
    ${SUDO} chmod 644 "${f}"
  fi
done
if [ "${tellme}" ]
then
  echo "${SUDO} chmod 755 ${DESTDIR}/bin/neoman \
    ${DESTDIR}/share/${PKG}/newsboat/*.sh \
    ${DESTDIR}/share/${PKG}/newsboat/scripts/* \
    ${DESTDIR}/share/${PKG}/newsboat/scripts/*/*"
else
  ${SUDO} chmod 755 "${DESTDIR}"/bin/neoman \
    "${DESTDIR}"/share/${PKG}/newsboat/*.sh \
    "${DESTDIR}"/share/${PKG}/newsboat/scripts/* \
    "${DESTDIR}"/share/${PKG}/newsboat/scripts/*/*
fi
[ "${tellme}" ] || touch "${NEOMANDIR}"/.initialized
