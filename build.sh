#!/bin/bash
#
# Copyright 2009 The VOTCA Development Team (http://www.votca.org)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#version 1.0.0 -- 18.12.09 initial version
#version 1.0.1 -- 21.12.09 added --pullpath option
#version 1.0.2 -- 14.01.10 improved clean
#version 1.0.3 -- 20.01.10 better error message in prefix_clean
#version 1.0.4 -- 09.02.10 added --static option
#version 1.0.5 -- 03.03.10 added pkg-config support
#version 1.0.6 -- 16.03.10 sets VOTCALDLIB
#version 1.0.7 -- 23.03.10 added --jobs/--latest
#version 1.1.0 -- 19.04.10 added --log
#version 1.1.1 -- 06.07.10 ignore VOTCALDLIB from environment
#version 1.2.0 -- 12.07.10 added -U and new shortcuts (-p,-q,-C)
#version 1.2.1 -- 28.09.10 added --no-bootstrap and --dist option
#version 1.3.0 -- 30.09.10 moved to googlecode
#version 1.3.1 -- 01.10.10 checkout stable branch by default
#version 1.3.2 -- 08.12.10 added --dist-pristine
#version 1.3.3 -- 09.12.10 allow to overwrite hg by HG
#version 1.3.4 -- 10.12.10 added --devdoc option
#version 1.3.5 -- 13.12.10 added --no-branchcheck and --no-wait option
#version 1.4.0 -- 15.12.10 added support for espressopp
#version 1.4.1 -- 17.12.10 default check for new version
#version 1.4.2 -- 20.12.10 some fixes in self_update check
#version 1.5.0 -- 11.02.11 added --longhelp and cmake support
#version 1.5.1 -- 13.02.11 removed --votcalibdir and added rpath options
#version 1.5.2 -- 16.02.11 added libtool options
#version 1.5.3 -- 17.02.11 bumped latest to 1.1_rc3
#version 1.5.4 -- 17.02.11 moved away from dev.votca.org
#version 1.5.5 -- 18.02.11 bumped latest to 1.1
#version 1.5.6 -- 01.03.11 bumped latest to 1.1.1
#version 1.5.7 -- 15.03.11 switched back to dev.votca.org
#version 1.5.8 -- 04.04.11 bumped latest to 1.1.2
#version 1.5.9 -- 16.06.11 bumped latest to 1.2
#version 1.6.0 -- 17.06.11 removed autotools support
#version 1.6.1 -- 17.06.11 added --cmake option
#version 1.6.2 -- 28.07.11 added --with-rpath option
#version 1.7.0 -- 09.08.11 added --no-rpath option and allow to build gromacs
#version 1.7.1 -- 15.08.11 added more branch checks
#version 1.7.2 -- 18.08.11 fixed a bug in clone code

#defaults
usage="Usage: ${0##*/} [options] [progs]"
prefix="$HOME/votca"

#this gets overriden by --dev option
#progs on https://code.google.com/p/votca
gc_progs="tools csg tutorials csgapps testsuite manual"
#all possible programs
all_progs="${gc_progs} gromacs"
#programs to build by default
standard_progs="tools csg"
#program which do not have a release tarball
norel_progs="csgapps testsuite manual"

if [ -f "/proc/cpuinfo" ]; then
  j="$(grep -c processor /proc/cpuinfo 2>/dev/null)" || j=0
  ((j++))
else
  j=1
fi

do_prefix_clean="no"
do_cmake="yes"
do_clean="no"
do_clean_ignored="no"
do_build="yes"
do_install="yes"
do_update="no"
do_dist="no"
do_devdoc="no"
dev="no"
wait="yes"
branch_check="yes"
dist_check="yes"
rel_check="yes"
self_download="no"
cmake="cmake"

relurl="http://votca.googlecode.com/files/votca-PROG-REL.tar.gz"
rel=""
gc_url="https://PROG.votca.googlecode.com/hg/"
url="$gc_url"
selfurl="http://votca.googlecode.com/hg/build.sh"
pathname="default"
latest="1.2"
gromacs_ver="4.5.4"

rpath_opt="-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON"
cmake_opts=""
packext=".tar.gz"
distext=""

[[ -z $HG ]] && HG="hg"

BLUE="[34;01m"
CYAN="[36;01m"
CYANN="[36m"
GREEN="[32;01m"
RED="[31;01m"
PURP="[35;01m"
OFF="[0m"

die () {
  cecho RED "$*" >&2
  exit 1
}

is_in() {
  [[ -z $1 || -z $2 ]] && die "is_in: Missing argument"
  [[ " ${@:2} " = *" $1 "* ]]
}

cecho() {
  local opts color colors="BLUE CYAN CYANN GREEN RED PURP"
  if [[ $1 = -?* ]]; then
    opts="$1"
    shift
  fi
  [[ -z $2 ]] && die "cecho: Missing argumet"
  is_in "$1" "$colors" || die "cecho: Unknown color ($color allowed)"
  color=${!1}
  shift
  echo -n ${color}
  echo -ne "$@"
  echo $opts "${OFF}"
}

build_devdoc() {
  local ver
  cecho GREEN "Building devdoc"
  [ -z "$(type -p doxygen)" ] && die "doxygen not found"
  [ -f tools/share/doc/Doxyfile.in ] || die "Could not get Doxyfile.in from tools repo"
  ver=$(get_votca_version tools/CMakeLists.txt) || die
  sed -e '/^PROJECT_NAME /s/=.*$/= Votca/' \
      -e "/^PROJECT_NUMBER /s/=.*$/= $ver/" \
      -e "/^INPUT /s/=.*$/= $progs/" \
      -e '/^HTML_OUTPUT /s/=.*$/= devdoc/' \
      tools/share/doc/Doxyfile.in > Doxyfile
  doxygen || die "Doxygen failed"
  rm -f Doxyfile
}

prefix_clean() {
  cecho GREEN "Starting clean out of prefix"
  [ ! -d $prefix ] && cecho BLUE "prefix '$prefix' is not there - skipping" && return 0
  cd $prefix || die "Could change to prefix '$prefix'"
  files="$(ls -d bin include lib share 2>/dev/null)"
  if [ -z "$files" ]; then
    cecho BLUE "Found nothing to clean"
    cd - > /dev/null
    return
  fi
  echo "I will $(cecho RED remove):"
  echo $files
  countdown 10
  rm -rf $files
  cecho GREEN "Done, hope you are happy now"
  cd - > /dev/null
}

countdown() {
  [ -z "$1" ] && "countdown: Missing argument"
  [ -n "${1//[0-9]}" ] && "countdown: argument should be a number"
  [ "$wait" = "no" ] && return
  cecho -n RED "(CTRL-C to stop) "
  for ((i=$1;i>0;i--)); do
    cecho -n CYANN "$i "
    sleep 1
  done
  echo
}

download_and_upack_tarball() {
  local url tarball
  [ -z "$1" ] && die "download_and_upack_tarball: Missing argument"
  url="$1"
  tarball="${url##*/}"
  cecho GREEN "Download tarball $tarball from ${url}"
  if [ "$self_download" = "no" ]; then
    [ -f "$tarball" ] && die "Tarball $tarball is already there, remove it first or add --selfdownload option"
    [ -z "$(type -p wget)" ] && die "wget is missing"
    wget "${url}"
  fi
  [ -f "${tarball}" ] || die "wget has failed to fetch the tarball (add --selfdownload option and copy ${tarball} here by hand)"
  tardir="$(tar -tzf ${tarball} | sed -e's#/.*$##' | sort -u)"
  [ -z "${tardir//*\\n*}" ] && die "Tarball $tarball contains zero or more then one directory ($tardir), please check by hand"
  [ -e "${tardir}" ] && die "Tarball unpack directory ${tardir} is already there, remove it first"
  tar -xzf "${tarball}"
  mv "${tardir}" "${prog}"
  rm -f "${tarball}"
}

get_version() {
  sed -ne 's/^#version[[:space:]]*\([^[:space:]]*\)[[:space:]]*-- .*$/\1/p' $1 | sed -n '$p'
}

get_webversion() {
  local version
  if [ "$1" = "-q" ]; then
    version="$(wget -qO- "${selfurl}" | get_version)"
  else
    [ -z "$(type -p wget)" ] && die "wget not found"
    version="$(wget -qO- "${selfurl}" )" || die "self_update: wget fetch from $selfurl failed"
    version="$(echo -e "${version}" | get_version)"
    [ -z "${version}" ] && die "get_webversion: Could not fetch new version number"
  fi
  echo "${version}"
}

get_votca_version() {
  local ver
  [[ -z $1 ]] && die "get_votca_version: Missing argument"
  [[ -f $1 ]] || die "get_votca_version: Could not find '$1'"
  ver="$(sed -n 's@^.*(PROJECT_VERSION "\([^"]*\)").*$@\1@p' $1)" || die "Could not grep PROJECT_VERSION from '$1'"
  [ -z "${ver}" ] && die "PROJECT_VERSION is empty"
  echo "$ver"
}

version_check() {
  old_version="$(get_version $0)"
  [ "$1" = "-q" ] && new_version="$(get_webversion -q)" || new_version="$(get_webversion)"
  [ "$1" = "-q" ] || cecho BLUE "Version of $selfurl is: $new_version"
  [ "$1" = "-q" ] || cecho BLUE "Local Version: $old_version"
  expr "${old_version}" \< "${new_version}" > /dev/null
  return $?
}

self_update() {
  [ -z "$(type -p wget)" ] && die "wget not found"
  if version_check; then
    cecho RED "I will try replace myself now with $selfurl"
    countdown 5
    wget -O "${0}" "${selfurl}"
  else
    cecho GREEN "No updated needed"
  fi
}

show_help () {
  cat << eof
    This is the votca build utils which builds votca modules
    Give multiple programs to build them. Nothing means: $standard_progs
    One can build: $all_progs

    Please visit: $(cecho BLUE www.votca.org)

    The normal sequence of a build is:
    - hg clone (if src is not there)
      and checkout stable branch unless --dev given
      (or downloads tarballs if --release given)
    - hg pull + hg update (if --do-update given)
    - run cmake (unless --no-cmake)
    - make clean (if --clean given)
    - make (unless --no-build given)
    - make install (disable with --no-install)

ADV The most recent version can be found at:
ADV $(cecho BLUE $selfurl)
ADV
    $usage

    OPTIONS (last overwrites previous):
    $(cecho GREEN -h), $(cecho GREEN --help)              Show a short help
        $(cecho GREEN --longhelp)          Show a detailed help
ADV $(cecho GREEN -v), $(cecho GREEN --version)           Show version
ADV     $(cecho GREEN --debug)             Enable debug mode
ADV     $(cecho GREEN --log) $(cecho CYAN FILE)          Generate a file with all build infomation
ADV     $(cecho GREEN --nocolor)           Disable color
ADV     $(cecho GREEN --selfupdate)        Do a self update
ADV $(cecho GREEN -d), $(cecho GREEN --dev)               Switch to developer mode
ADV     $(cecho GREEN --release) $(cecho CYAN REL)       Get Release tarball instead of using hg clone
    $(cecho GREEN -l), $(cecho GREEN --latest)            Get the latest tarball ($latest)
    $(cecho GREEN -u), $(cecho GREEN --do-update)         Do a update of the sources from pullpath $pathname
                            or the votca server as fail back
ADV $(cecho GREEN -U), $(cecho GREEN --just-update)       Same as $(cecho GREEN --do-update) + $(cecho GREEN --no-cmake)
ADV     $(cecho GREEN --pullpath) $(cecho CYAN NAME)     Changes the name of the path to pull from
ADV                         Default: $pathname (Also see 'hg paths --help')
ADV $(cecho GREEN -c), $(cecho GREEN --clean-out)         Clean out the prefix (DANGEROUS)
ADV $(cecho GREEN -C), $(cecho GREEN --clean-ignored)     Remove ignored file from repository (SUPER DANGEROUS)
ADV     $(cecho GREEN --no-cmake)          Stop before cmake 
ADV $(cecho GREEN -D)$(cecho CYAN '*')                     Extra cmake options (maybe multiple times)
ADV                         Do NOT put variables (XXX=YYY) here, just use environment variables
ADV $(cecho GREEN -R), $(cecho GREEN --no-rpath)          Remove rpath from the binaries (cmake default) 
ADV $(cecho GREEN -q), $(cecho GREEN --clean)             Run make clean
ADV $(cecho GREEN -j), $(cecho GREEN --jobs) $(cecho CYAN N)            Allow N jobs at once for make
ADV                         Default: $j (auto)
ADV     $(cecho GREEN --no-build)          Stop before build
ADV $(cecho GREEN -W), $(cecho GREEN --no-wait)           Do not wait, at critical points (DANGEROUS)
ADV     $(cecho GREEN --no-install)        Don't run make install
ADV     $(cecho GREEN --dist)              Create a dist tarball and move it here
ADV                         (implies $(cecho GREEN --warn-to-errors) and $(cecho GREEN -D)$(cecho CYAN EXTERNAL_BOOST=OFF))
ADV     $(cecho GREEN --dist-pristine)     Create a pristine dist tarball (without bundled libs) and move it here
ADV                         (implies $(cecho GREEN --warn-to-errors) and $(cecho GREEN -D)$(cecho CYAN EXTERNAL_BOOST=ON))
ADV     $(cecho GREEN --warn-to-errors)    Turn all warning into errors (adding -Werror to CXXFLAGS)
ADV     $(cecho GREEN --devdoc)            Build a combined html doxygen for all programs (useful with $(cecho GREEN -U))
ADV     $(cecho GREEN --cmake) $(cecho CYAN CMD)         Use $(cecho CYAN CMD) instead of cmake
ADV                         Default: $cmake
    $(cecho GREEN -p), $(cecho GREEN --prefix) $(cecho CYAN PREFIX)     Use install prefix $(cecho CYAN PREFIX)
                            Default: $prefix

    Examples:  ${0##*/} tools csg
               ${0##*/} -dcu --prefix=\$PWD/install tools csg
               ${0##*/} -u
               ${0##*/} --release ${latest} tools csg
               ${0##*/} --dev --longhelp
               CC=g++ ${0##*/} -DWITH_GMX_DEVEL=ON csg

eof
}

cmdopts=""
for i in "$@"; do
  [ -z "${i//*[[:space:]]*}" ] && cmdopts="${cmdopts} '$i'" || cmdopts="${cmdopts} $i"
done
cmdopts="$(echo "$cmdopts" | sed 's/--log[ =][^[:space:]]* //')"

# parse arguments
shopt -s extglob
while [[ ${1} = -* ]]; do
  if [[ ${1} = --*=* ]]; then # case --xx=yy
    set -- "${1%%=*}" "${1#*=}" "${@:2}" # --xx=yy to --xx yy
  elif [[ ${1} = -[^-]?* ]]; then # case -xy split
    if [[ ${1} = -[jpD]* ]]; then #short opts with arguments
       set -- "${1:0:2}" "${1:2}" "${@:2}" # -xy to -x y
    else #short opts without arguments
       set -- "${1:0:2}" "-${1:2}" "${@:2}" # -xy to -x -y
    fi
 fi
 case $1 in
   --debug)
    set -x
    shift ;;
   --log)
    [ -n "$2" ] || die "Missing argument after --log"
    echo "Logfile is $(cecho PURP $2)"
    echo "Log of '${0} ${cmdopts}'" > $2
    ${0} ${cmdopts} | tee -a $2
    exit $?;;
   -h | --help)
    show_help | sed -e '/^ADV/d' -e 's/^    //'
    exit 0;;
  --longhelp)
   show_help | sed -e 's/^ADV/   /' -e 's/^    //'
   exit 0;;
   -v | --version)
    echo "${0##*/}, version $(get_version $0)"
    exit 0;;
   --hg)
    sed -ne 's/^#version[[:space:]]*\([^[:space:]]*\)[[:space:]]*-- [0-9][0-9]\.[0-9][0-9]\.[0-9][0-9] \(.*\)$/\2/p' $0 | sed -n '$p'
    exit 0;;
   --selfupdate)
    self_update
    exit $?;;
   -c | --clean-out)
    prefix_clean="yes"
    shift 1;;
   -C | --clean-ignored)
    do_clean_ignored="yes"
    shift 1;;
   -j | --jobs)
    [[ -z $2 ]] && die "Missing argument after --jobs"
    [[ -n ${2//[0-9]} ]] && die "Argument after --jobs should be a number"
    j="$2"
    shift 2;;
   -u | --do-update)
    do_update="yes"
    shift 1;;
   -U | --just-update)
    do_update="only"
    shift 1;;
   --pullpath)
    pathname="$2"
    shift 2;;
   --no-cmake)
    do_cmake="no"
    shift 1;;
   --cmake)
    cmake="$2"
    [[ -z $(type -p $cmake) ]] && die "Custom cmake '$cmake' not found"
    shift 2;;
   --warn-to-errors)
    cmake_opts="${cmake_opts} -DCMAKE_CXX_FLAGS='-Werror'"
    shift 1;;
   -R | --no-rpath)
    rpath_opt=""
    shift 1;;
   --dist)
    do_dist="yes"
    do_clean="yes"
    cmake_opts="${cmake_opts} -DEXTERNAL_BOOST=OFF -DCMAKE_CXX_FLAGS='-Werror'"
    shift 1;;
   --dist-pristine)
    do_dist="yes"
    do_clean="yes"
    cmake_opts="${cmake_opts} -DEXTERNAL_BOOST=ON -DCMAKE_CXX_FLAGS='-Werror'"
    distext="_pristine"
    shift 1;;
   --devdoc)
    do_devdoc="yes"
    shift 1;;
   -q | --clean)
    do_clean="yes"
    shift 1;;
   --no-install)
    do_install="no"
    shift 1;;
   --no-build)
    do_build="no"
    shift 1;;
   -W | --no-wait)
    wait="no"
    shift 1;;
   --no-branchcheck)
    branch_check="no"
    shift 1;;
   --no-distcheck)
    dist_check="no"
    shift 1;;
   --no-relcheck)
    rel_check="no"
    shift 1;;
   --selfdownload)
    self_download="yes"
    shift 1;;
   -p | --prefix)
    prefix="$2"
    shift 2;;
  -D)
    cmake_opts="${cmake_opts} -D${2}"
    shift 2;;
   --release)
    rel="$2"
    [[ $rel_check = "yes" && -n "${rel//[1-9].[0-9]?(.[0-9])?(_rc[1-9]?([0-9]))?(_pristine)}" ]] && \
      die "--release option needs an argument of the form X.X{_rcXX} (disable this check with --no-relcheck option)"
    shift 2;;
   -l | --latest)
    rel="$latest"
    shift;;
   --nocolor)
    unset BLUE CYAN CYANN GREEN OFF RED PURP
    shift;;
   -d | --dev)
    dev=yes
    url="https://dev.votca.org/votca_PROG"
    all_progs="tools csg moo kmc kmcold md2qm testsuite tutorials csgapps espressopp manual gromacs"
    norel_progs="moo kmc kmcold md2qm testsuite csgapps espressopp manual"
    esp_url="https://hg.berlios.de/repos/espressopp"
    shift 1;;
  *)
   die "Unknown option '$1'"
   exit 1;;
 esac
done

if version_check -q; then
  x=${0##*/}; x=${x//?/#}
  cecho RED "########################################$x"
  cecho RED "# Your version of VOTCA ${0##*/} is obsolete ! #"
  cecho RED "# Please run '${0##*/} --selfupdate'           #"
  cecho RED "########################################$x"
  unset x
fi

[[ -z $1 ]] && set -- $standard_progs
[[ -z $prefix ]] && die "Error: prefix is empty"

#set pkg-config dir to make csg find tools
export PKG_CONFIG_PATH="$prefix/lib/pkgconfig${PKG_CONFIG_PATH:+:}${PKG_CONFIG_PATH}"
#add libdir to LD_LIBRARY_PATH to allow runing csg_* for the manual
export LD_LIBRARY_PATH="$prefix/lib${LD_LIBRARY_PATH:+:}${LD_LIBRARY_PATH}"
#hack for some old version of Mac OS
export DYLD_LIBRARY_PATH="$prefix/lib${DYLD_LIBRARY_PATH:+:}${DYLD_LIBRARY_PATH}"
#for the manual
export PATH="$prefix/bin${PATH:+:}${PATH}"

#infos
cecho GREEN "This is VOTCA ${0##*/}, version $(get_version $0)"
echo "Install prefix is '$prefix'"
[[ -n $CPPFLAGS ]] && echo "CPPFLAGS is '$CPPFLAGS'"
[[ -n $CXXFLAGS ]] && echo "CXXFLAGS is '$CXXFLAGS'"
[[ -n $LDFLAGS ]] && echo "LDFLAGS is '$LDFLAGS'"
cecho BLUE "Using $j jobs for make"

[[ $prefix_clean = "yes" ]] && prefix_clean

set -e
progs="$@"
for prog in "$@"; do
  is_in "${prog}" "${all_progs}" || die "Unknown progamm '$prog', I know: $all_progs"
  is_in "${prog}" "${gc_progs}" && hgurl="$gc_url" || hgurl="$url"
  [[ $prog = "espressopp" ]] && hgurl="$esp_url"

  cecho GREEN "Working on $prog"
  if [[ $prog = "gromacs" ]]; then
    if [[ -d $prog ]]; then
      cecho BLUE "Source dir ($prog) is already there - skipping download"
      countdown 5
    else
      download_and_upack_tarball "ftp://ftp.gromacs.org/pub/gromacs/gromacs-${gromacs_ver}.tar.gz"
    fi
  elif [[ -d $prog && -z $rel ]]; then
    cecho BLUE "Source dir ($prog) is already there - skipping checkout"
  elif [[ -d $prog && -n $rel ]]; then
    cecho BLUE "Source dir ($prog) is already there - skipping download"
    countdown 5
  elif [[ -n $rel ]] &&  is_in "${prog}" "${norel_progs}"; then
    cecho BLUE "Program $prog has no release tarball I will get it from the its mercurial repository"
    countdown 5
    [ -z "$(type -p $HG)" ] && die "Could not find $HG, please install mercurial (http://mercurial.selenic.com/)"
    $HG clone ${hgurl/PROG/$prog} $prog
  elif [[ ! -d $prog && -n $rel ]]; then
    tmpurl="${relurl//REL/$rel}"
    tmpurl="${tmpurl//PROG/$prog}"
    download_and_upack_tarball "$tmpurl"
  else
    cecho BLUE "Doing checkout for $prog from ${hgurl/PROG/$prog}"
    countdown 5
    [ -z "$(type -p $HG)" ] && die "Could not find $HG, please install mercurial (http://mercurial.selenic.com/)"
    $HG clone ${hgurl/PROG/$prog} $prog
    if [ "${dev}" = "no" ]; then
      if [[ -n $($HG branches -R $prog | sed -n '/^stable[[:space:]]/p' ) ]]; then
        cecho BLUE "Switching to stable branch add --dev option to prevent that"
        $HG update -R $prog stable
      else
	cecho BLUE "No stable branch found, skipping switching!"
      fi
    fi
  fi

  cd $prog
  if [[ $do_update == "yes" || $do_update == "only" ]]; then
    if [ -n "$rel" ]; then
      cecho BLUE "Update of a release tarball doesn't make sense, skipping"
      countdown 5
    elif [ -d .hg ]; then
      cecho GREEN "updating hg repository"
      pullpath=$($HG path $pathname 2> /dev/null || true)
      if [ -z "${pullpath}" ]; then
	pullpath=${hgurl/PROG/$prog}
	cecho BLUE "Could not fetch pull path '$pathname', using $pullpath instead"
	countdown 5
      else
	cecho GREEN "from $pullpath"
      fi
      $HG pull ${pullpath}
      cecho GREEN "We are on branch $(cecho BLUE $($HG branch))"
      $HG update
    else
      cecho BLUE "$prog dir doesn't seem to be a hg repository, skipping update"
      countdown 5
    fi
  fi
  if [[ -d .hg ]]; then 
    [[ -z $branch ]] && branch="$($HG branch)"
    if [[ $branch_check = "yes" ]]; then
      [[ $dev = "no" && -n $($HG branches | sed -n '/^stable[[:space:]]/p' ) && $($HG branch) != "stable" ]] && \
        die "We build the stable version of $prog, but we are on branch $($HG branch) and not 'stable'. Please checkout the stable branch with 'hg update -R $prog stable' or add --dev option (disable this check with the --no-branchcheck option)"
      [[ $dev = "yes" && $($HG branch) = "stable" ]] && \
	die "We build the devel version of $prog, but we are on the stable branch. Please checkout a devel branch like default with 'hg update -R $prog default' (disable this check with the --no-branchcheck option)"
      #prevent to build devel csg with stable tools and so on
      [[ $branch != $($HG branch) ]] && die "You are mixing branches: '$branch' (in $last_prog) vs '$($HG branch) (in $prog)' (disable this check with the --no-branchcheck option)\n You can change the branch with 'hg update BRANCHNAME'."
    fi
    [[ $branch = $($HG branch) ]] || cecho PURP "You are mixing branches: '$branch' vs '$($HG branch)'"
  fi
  if [[ $do_update == "only" ]]; then
    cd ..
    continue
  fi
  if [ "$do_clean_ignored" = "yes" ]; then
    if [[ -d .hg ]]; then
      cecho BLUE "I will remove all ignored files from $prog"
      countdown 5
      $HG status --print0 --no-status --ignored | xargs --null rm -f
    else
      cecho BLUE "$prog dir doesn't seem to be a hg repository, skipping remove of ignored files"
      countdown 5
    fi
  fi
  if [ "$do_dist" = "yes" ]; then
    [[ -d .hg ]] || die "I can only make a tarball out of a mercurial repository"
    [[ $dist_check = "yes" && -n "$($HG status --modified)" ]] && die "There are uncommitted changes, they will not end up in the tarball, commit them first (disable this check with --no-distcheck option)"
    [[ $dist_check = "yes" && -n "$($HG status --unknown)" ]] && die "There are unknown files, they will not end up in the tarball, rm/commit the files first (disable this check with --no-distcheck option)"
  fi
  if [ "$do_clean" == "yes" ]; then
    rm -f CMakeCache.txt
  fi
  if [[ $do_cmake == "yes" && -f CMakeLists.txt ]]; then
    [[ -z $(sed -n '/^project(.*)/p' CMakeLists.txt) ]] && die "The current directory ($PWD) does not look like a source main directory (no project line in CMakeLists.txt found)"
    [[ -z $(type -p cmake) ]] && die "cmake not found"
    cecho BLUE "cmake -DCMAKE_INSTALL_PREFIX="$prefix" $cmake_opts $rpath_opt ."
    [[ $cmake != "cmake" ]] && $cmake  -DCMAKE_INSTALL_PREFIX="$prefix" $cmake_opts $rpath_opt .
    # we always run normal cmake in case user forgot to generate
    cmake  -DCMAKE_INSTALL_PREFIX="$prefix" $cmake_opts $rpath_opt .
  fi
  if [[ $do_clean == "yes" && -f Makefile ]]; then
    cecho GREEN "cleaning $prog"
    make clean
  fi
  if [[ $do_build == "yes" && -f Makefile ]]; then 
    cecho GREEN "buidling $prog"
    make -j${j}
  fi
  if [[ "$do_install" == "yes" && -f Makefile ]]; then
    if [ -f manual.tex ]; then
      cecho BLUE "manual can not be installed"
    else
      cecho GREEN "installing $prog"
      make -j${j} install
    fi
  fi
  if [ "$do_dist" = "yes" ]; then
    cecho GREEN "packing $prog"
    [[ -n $distext && $prog != "tools" ]] && die "pristine distribution can only be done for votca tools"
    #if we are here we know  that make and make installed worked
    if [ -f manual.tex ]; then
      ver="$(sed -n 's/VER=[[:space:]]*\([^[:space:]]*\)[[:space:]]*$/\1/p' Makefile)" || die "Could not get version of the manual"
      [ -z "${ver}" ] && die "Version of the manual was empty"
      [ -f "manual.pdf" ] || die "Could not find manual.pdf"
      cp manual.pdf ../votca-manual-${ver}${distext}.pdf || die "cp of manual failed"
    elif [ -f CMakeLists.txt ]; then
      ver="$(get_votca_version CMakeLists.txt)" || die
      exclude="--exclude netbeans/ --exclude src/csg_boltzmann/nbproject/"
      [ "$distext" = "_pristine" ] && exclude="${exclude} --exclude src/libboost/"
      $HG archive ${exclude} --prefix "votca-${prog}-${ver}" --type tgz "../votca-${prog}-${ver}${distext}.tar.gz" || die "$HG archive failed"
    else
      [ -z "${REL}" ] && die "No CMakeLists.txt found and environment variable REL was not defined"
      $HG archive --prefix "votca-${prog}-${REL}" --type tgz "../votca-${prog}-${REL}${distext}.tar.gz" || die "$HG archive failed"
    fi
  fi
  cd ..
  cecho GREEN "done with $prog"
  last_prog="$prog"
done
set +e

[ "$do_devdoc" = "no" ] || build_devdoc
