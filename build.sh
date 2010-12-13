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

#defaults
usage="Usage: ${0##*/} [options] [progs]"
prefix="$HOME/votca"
libdir=""
#mind the spaces
gc_progs=" tools csg tutorials csgapps "
all_progs="$gc_progs"
standard_progs=" tools csg "
nobuild_progs=" tutorials csgapps "

if [ -f "/proc/cpuinfo" ]; then
  j="$(grep -c processor /proc/cpuinfo 2>/dev/null)" || j=0
  ((j++))
else
  j=1
fi

do_prefix_clean="no"
do_configure="yes"
do_bootstrap="yes"
do_clean="yes"
do_clean_ignored="no"
do_build="yes"
do_install="yes"
do_update="no"
do_dist="no"
do_devdoc="no"
dev="no"
wait="yes"
branch_check="yes"

relurl="http://votca.googlecode.com/files/votca-PROG-REL.tar.gz"
rel=""
gc_url="https://PROG.votca.googlecode.com/hg/"
url="$gc_url"
selfurl="http://votca.googlecode.com/hg/build.sh"
pathname="default"
latest="1.0"

extra_conf=""
packext=".tar.gz"
distext=""

[ -z "$HG" ] && HG="hg"

gromacs="no"

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

cecho() {
  local opts color=" BLUE CYAN CYANN GREEN RED PURP "
  if [ -z "${1##-*}" ]; then
    opts="$1"
    shift
  fi
  [ -z "$2" ] && die "cecho: Missing argumet"
  [ -n "${color//* $1 *}" ] && die "cecho: Unknown color ($color allowed)"
  color=${!1}
  shift
  echo -n ${color}
  echo -ne "$@"
  echo $opts "${OFF}"
}

build_devdoc() {
  cecho GREEN "Building devdoc"
  [ -z "$(type -p doxygen)" ] && die "wget is missing"
  [ -f tools/share/doc/Doxyfile ] || die "Could not get Doxyfile from tools repo"
  sed -e '/^PROJECT_NAME /s/=.*$/= Votca/' \
      -e "/^INPUT /s/=.*$/= $progs/" \
      -e '/^HTML_OUTPUT /s/=.*$/= devdoc/' \
      tools/share/doc/Doxyfile > Doxyfile
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
  cecho RED "CTRL-C to stop it"
  countdown 10
  rm -rf $files
  cecho GREEN "Done, hope you are happy now"
  cd - > /dev/null
}

countdown() {
  [ -z "$1" ] && "countdown: Missing argument"
  [ -n "${1//[0-9]}" ] && "countdown: argument should be a number"
  [ "$wait" = "no" ] && return
  for ((i=$1;i>0;i--)); do
    cecho -n CYANN "$i "
    sleep 1
  done
  echo
}

get_version() {
  sed -ne 's/^#version[[:space:]]*\([^[:space:]]*\)[[:space:]]*-- .*$/\1/p' $1 | sed -n '$p'
}

self_update() {
  [ -z "$(type -p wget)" ] && die "wget is missing"
  new_version="$(wget -qO- "${selfurl}")" || die "self_update: wget fetch from $selfurl failed"
  new_version="$(echo -e "${new_version}" | get_version)"
  [ -z "${new_version}" ] && die "self_update: Could not fetch new version number"
  cecho BLUE "Version of $selfurl is: $new_version"
  old_version="$(get_version $0)"
  cecho BLUE "Local Version: $old_version"
  new_version="${new_version//[^0-9]}"
  old_version="${old_version//[^0-9]}"
  newer=$(awk -v new="$new_version" -v old="$old_version" 'BEGIN{if (new>old){print "yes"}}')
  if [ "$newer" = "yes" ]; then
    cecho RED "I will try replace myself now with $selfurl (CTRL-C to stop)"
    countdown 5
    wget -O "${0}" "${selfurl}"
  else
    cecho GREEN "No updated needed"
  fi
}

show_help () {
  cat << eof
This is the votca build utils which builds votca modules
Give multiple programs to build them. Nothing means:$standard
One can build:$all

Please visit: $(cecho BLUE www.votca.org)

The normal sequence of a build is:
- hg clone (if src is not there)
  and checkout stable branch unless --dev given
  (use release tarball with --release)
- hg pull + hg update (enable --do-update)
  (stop here with --no-configure)
- bootstrap (if found and not --release or --no-bootstrap)
- configure
- make clean (disable with --no-clean)
  (stop here with --no-build)
- make
- make install (disable with --no-install)

The most recent version can be found at:
$(cecho BLUE $selfurl)

$usage
OPTIONS (last overwrites previous):
$(cecho GREEN -h), $(cecho GREEN --help)              Show this help
$(cecho GREEN -v), $(cecho GREEN --version)           Show version
    $(cecho GREEN --debug)             Enable debug mode
    $(cecho GREEN --log) $(cecho CYAN FILE)          Generate a file with all build infomation
    $(cecho GREEN --nocolor)           Disable color
    $(cecho GREEN --selfupdate)        Do a self update (EXPERIMENTAL)
$(cecho GREEN -d), $(cecho GREEN --dev)               Switch to developer mode
                        (account of votca.org needed)
    $(cecho GREEN --ccache)            Enable ccache
    $(cecho GREEN --static)            Build static executables
    $(cecho GREEN --release) $(cecho CYAN REL)       Get Release tarball instead of using hg clone
                        (implies  $(cecho GREEN --no-bootstrap))
$(cecho GREEN -l), $(cecho GREEN --latest)            Get the latest tarball ($latest)
$(cecho GREEN -u), $(cecho GREEN --do-update)         Do a update of the sources from pullpath $pathname
                        or the votca server as fail back
$(cecho GREEN -U), $(cecho GREEN --just-update)       Same as $(cecho GREEN --do-update) + $(cecho GREEN --no-configure)
    $(cecho GREEN --pullpath) $(cecho CYAN NAME)     Changes the name of the path to pull from
                        Default: $pathname (Also see 'hg paths --help')
$(cecho GREEN -c), $(cecho GREEN --clean-out)         Clean out the prefix (DANGEROUS)
$(cecho GREEN -C), $(cecho GREEN --clean-ignored)     Remove ignored file from repository (SUPER DANGEROUS)
    $(cecho GREEN --no-configure)      Stop after update (before bootstrap)
    $(cecho GREEN --no-bootstrap)      Do not run bootstrap.sh
$(cecho GREEN -O), $(cecho GREEN --conf-opts) $(cecho CYAN OPTS)    Extra configure options (maybe multiple times)
                        Do NOT put variables (XXX=YYY) here, but use environment variables
$(cecho GREEN -q), $(cecho GREEN --no-clean)          Don't run make clean
$(cecho GREEN -j), $(cecho GREEN --jobs) $(cecho CYAN N)            Allow N jobs at once for make
                        Default: $j (auto)
    $(cecho GREEN --no-build)          Stop before build
$(cecho GREEN -W), $(cecho GREEN --no-wait)           Do not wait, at critical points (DANGEROUS)
    $(cecho GREEN --no-branchcheck)    Do not check, for mixed hg branches
    $(cecho GREEN --no-install)        Don't run make install
    $(cecho GREEN --dist)              Create a dist tarball and move it here
                        (implies $(cecho GREEN --conf-opts) $(cecho CYAN "'--enable-votca-boost --enable-votca-expat'"))
    $(cecho GREEN --dist-pristine)     Create a pristine dist tarball (without bundled libs) and move it here
                        (implies $(cecho GREEN --conf-opts) $(cecho CYAN "'--disable-votca-boost --disable-votca-expat'"))
    $(cecho GREEN --devdoc)            Build a combined html doxygen for all programs (useful with $(cecho GREEN -U))
$(cecho GREEN -p), $(cecho GREEN --prefix) $(cecho CYAN PREFIX)     Use install prefix $(cecho CYAN PREFIX)
                        Default: $prefix
    $(cecho GREEN --votcalibdir) $(cecho CYAN DIR)   export DIR as VOTCALDLIB
                        Default: PREFIX/lib

Examples:  ${0##*/} tools csg
           ${0##*/} -dcu --prefix \$PWD/install tools csg
	   ${0##*/} -u
	   ${0##*/} --release ${latest} tools csg
	   ${0##*/} --dev --help
	   CC=g++ ${0##*/} --conf-opts '--enable-votca-boost --enable-votca-expat' tools

eof
}

cmdopts=""
for i in "$@"; do
  [ -z "${i//*[[:space:]]*}" ] && cmdopts="${cmdopts} '$i'" || cmdopts="${cmdopts} $i"
done
cmdopts="$(echo "$cmdopts" | sed 's/--log [^[:space:]]* //')"

# parse arguments
shopt -s extglob
while [ "${1#-}" != "$1" ]; do
 if [ "${1#--}" = "$1" ] && [ -n "${1:2}" ]; then
    #short opt with arguments here: j, p and O
    if [ "${1#-[jpO]}" != "${1}" ]; then
       set -- "${1:0:2}" "${1:2}" "${@:2}"
    else
       set -- "${1:0:2}" "-${1:2}" "${@:2}"
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
    show_help
    exit 0;;
   -v | --version)
    echo "${0##*/}, version $(get_version $0)"
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
    [ -z "$2" ] && die "Missing argument after --jobs"
    [ -n "${2//[0-9]}" ] && die "Argument after --jobs should be a number"
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
   --no-configure)
    do_configure="no"
    shift 1;;
   --no-configure)
    do_bootstrap="no"
    shift 1;;
   --dist)
    do_dist="yes"
    extra_conf="${extra_conf} --enable-votca-boost --enable-votca-expat"
    shift 1;;
   --dist-pristine)
    do_dist="yes"
    extra_conf="${extra_conf} --disable-votca-boost --disable-votca-expat"
    distext="_pristine"
    shift 1;;
   --devdoc)
    do_devdoc="yes"
    shift 1;;
   -q | --no-clean)
    do_clean="no"
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
   -p | --prefix)
    prefix="$2"
    shift 2;;
   --votcalibdir)
    libdir="$2"
    shift 2;;
   -O | --conf-opts)
    extra_conf="${extra_conf} $2"
    shift 2;;
   --static)
    extra_conf="${extra_conf} --enable-all-static"
    shift ;;
   --release)
    rel="$2"
    [ -z "${rel//[1-9].[0-9]?(_rc[1-9]?([0-9]))}" ] || \
      die "--release option needs an argument of the form X.X{_rcXX}"
    do_bootstrap="no"
    shift 2;;
   -l | --latest)
    rel="$latest"
    shift;;
   --ccache)
    [ -z "$(type ccache)" ] && die "${0##*/}: ccache not found"
    export CXX="ccache ${CXX:=g++}"
    shift;;
   --nocolor)
    unset BLUE CYAN CYANN GREEN OFF RED PURP
    shift;;
   -d | --dev)
    dev=yes
    url="http://dev.votca.org/votca/PROG"
    all_progs=" tools csg moo kmc tof md2qm testsuite csgapps "
    standard_progs=" tools csg moo kmc md2qm "
    shift 1;;
  *)
   die "Unknown option '$1'"
   exit 1;;
 esac
done

[ -z "$1" ] && set -- $standard_progs
[ -z "$prefix" ] && die "Error: prefix is empty"

#libdir was explicitly given
if [ -n "$libdir" ]; then
  export VOTCALDLIB="$libdir"
else
  export VOTCALDLIB="$prefix/lib"
fi
export PKG_CONFIG_PATH="$VOTCALDLIB/pkgconfig${PKG_CONFIG_PATH:+:}${PKG_CONFIG_PATH}"

#infos
cecho GREEN "This is ${0##*/}, version $(get_version $0)"
echo "prefix is '$prefix'"
echo "VOTCALDLIB is '$VOTCALDLIB'"
[ -n "$CPPFLAGS" ] && echo "CPPFLAGS is '$CPPFLAGS'"
[ -n "$LDFLAGS" ] && echo "LDFLAGS is '$LDFLAGS'"
cecho BLUE "Using $j jobs for make"

[ "$prefix_clean" = "yes" ] && prefix_clean

set -e
progs="$@"
for prog in "$@"; do
  [ -n "${all_progs//* $prog *}" ] && die "Unknown progamm '$prog', I know: $all_progs"
  [ -z "${gc_progs//* $prog *}" ] && hgurl="$gc_url" || hgurl="$url"

  cecho GREEN "Working on $prog"
  if [ -d "$prog" ] && [ -z "$rel" ]; then
    cecho BLUE "Source dir ($prog) is already there - skipping checkout"
  elif [ -d "$prog" ] && [ -n "$rel" ]; then
    cecho BLUE "Source dir ($prog) is already there - skipping download (CTRL-C to stop)"
    countdown 5
  elif [ -n "$rel" ] && [ -z "${nobuild_progs//* $prog *}" ]; then
    cecho BLUE "Program $prog has no release tarball I will get it from the its mercurial repository (CTRL-C to stop)"
    countdown 5
    $HG clone ${hgurl/PROG/$prog} $prog
  elif [ ! -d "$prog" ] && [ -n "$rel" ]; then
    tmpurl="${relurl//REL/$rel}"
    tmpurl="${tmpurl//PROG/$prog}"
    tarball="${tmpurl##*/}"
    cecho GREEN "Download tarball $tarball from ${tmpurl}"
    [ -f "$tarball" ] && die "Tarball $tarball is already there, remove it first"
    [ -z "$(type -p wget)" ] && die "wget is missing"
    wget "${tmpurl}"
    tardir="$(tar -tzf ${tarball} | sed -e's#/.*$##' | sort -u)"
    [ -z "${tardir//*\n*}" ] && die "Tarball $tarball contains zero or more then one directory, please check by hand"
    [ -e "${tardir}" ] && die "Tarball unpack directory ${tardir} is already there, remove it first"
    tar -xzf "${tarball}"
    mv "${tardir}" "${prog}"
    rm -f "${tarball}"
  else
    cecho BLUE "Doing checkout for $prog from ${hgurl/PROG/$prog} (CTRL-C to stop)"
    countdown 5
    $HG clone ${hgurl/PROG/$prog} $prog
    if [ "${dev}" = "no" ] && [ -z "${gc_progs//* $prog *}" ] && [ -n "${nobuild_progs//* $prog *}" ]; then
      cd $prog
      cecho BLUE "Switching to stable branch add --dev option to prevent that"
      $HG checkout stable
      cd ..
    fi
  fi

  cd $prog
  if [ "$do_update" == "yes" ] || [ "$do_update" == "only" ]; then
    if [ -n "$rel" ]; then
      cecho BLUE "Update of a release tarball doesn't make sense, skipping (CTRL-C to stop)"
      countdown 5
    elif [ -d .hg ]; then
      cecho GREEN "updating hg repository"
      pullpath=$($HG path $pathname 2> /dev/null || true)
      if [ -z "${pullpath}" ]; then
	pullpath=${hgurl/PROG/$prog}
	cecho BLUE "Could not fetch pull path '$pathname', using $pullpath instead (CTRL-C to stop)"
	countdown 5
      else
	cecho GREEN "from $pullpath"
      fi
      $HG pull ${pullpath}
      echo "We are on branch $(cecho BLUE $($HG branch))"
      $HG update
    else
      cecho BLUE "$prog dir doesn't seem to be a hg repository, skipping update (CTRL-C to stop)"
      countdown 5
    fi
    if [ "$do_update" == "only" ]; then
      cd ..
      continue
    fi
  fi
  if [ -d .hg ]; then
    [ -z "$branch" ] && branch="$($HG branch)"
    #prevent to build devel csg with stable tools and so on
    if [ "$branch" != "$($HG branch)" ]; then
      [ "$branch_check" = "yes" ] && die "You are mixing branches: '$branch' (in $last_prog) vs '$($HG branch) (in $prog)' (disable this check with --no-branchcheck option)"
      cecho PURP "You are mixing branches: '$branch' vs '$($HG branch)'" 
    fi
  fi
  if [ -z "${nobuild_progs//* $prog *}" ]; then
    cd ..
    cecho BLUE "Program $prog can not be build automatically"
    cecho GREEN "done with $prog"
    continu
  fi
  if [ "$do_clean_ignored" = "yes" ]; then
    if [ -d .hg ]; then
      cecho BLUE "I will remove all ignored files from $prog, CTRL-C to stop"
      countdown 5
      $HG status --print0 --no-status --ignored | xargs --null rm -f
    else
      cecho BLUE "$prog dir doesn't seem to be a hg repository, skipping remove of ignored files (CTRL-C to stop)"
      countdown 5
    fi
  fi
  if [ "$do_configure" == "yes" ]; then
    if [ "$do_bootstrap" = "yes" ] && [ -f bootstrap.sh ]; then
      cecho GREEN "bootstraping $prog"
      ./bootstrap.sh
    fi
    cecho GREEN "configuring $prog"
    if [ -f configure ]; then
       cecho BLUE "configure --prefix '$prefix' $extra_conf"
      ./configure --prefix "$prefix" $extra_conf
    else
      die "No configure found, remove '--no-bootstrap' option"
    fi
  else
    cd ..
    cecho GREEN "done with $prog"
    continue
  fi
  if [ "$do_clean" == "yes" ]; then
    cecho GREEN "cleaning $prog"
    make clean
  fi
  if [ "$do_dist" = "yes" ]; then
    make distcheck DISTCHECK_CONFIGURE_FLAGS="${extra_conf}"
    for i in  *${packext}; do
      [ -f "$i" ] || die "Tarball $i not found"
      mv "$i" ../"${i%$packext}${distext}${packext}"
    done
  fi
  if [ "$do_build" == "no" ]; then
    cd ..
    cecho GREEN "done with $prog"
    continue
  fi
  cecho GREEN "buidling $prog"
  make -j${j}
  if [ "$do_install" == "yes" ]; then
    cecho GREEN "installing $prog"
    make install
  fi
  cd ..
  cecho GREEN "done with $prog"
  last_prog="$prog"
done
set +e

[ "$do_devdoc" = "yes" ] && build_devdoc
