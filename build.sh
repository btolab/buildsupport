#!/bin/bash
#
# Cross-compile SDL version of MAME for Windows and OSX
#

# error handling setup
set -o nounset -o pipefail -o errtrace

error() {
	local lc="$BASH_COMMAND" rc=$?
	echo "ERROR in $0 : line $1 exit code $2"
	echo "      [$lc]"
	exit $2
}
trap 'error ${LINENO} ${?}' ERR

# override commands
function echo() {
    command echo $(date +"[%d-%h-%Y %H:%M:%S %Z]") "$*"
}
function pushd() {
    command pushd "$@" >/dev/null
}
function popd() {
    command popd "$@" >/dev/null
}

# Error out if branch is dirty
if [[ ! -z $(git status --porcelain) ]]; then
    echo "Repository is not clean, aborting."
    exit 1
fi

# Dont reset branch so release script generates proper source archive
# builtbot should do this anyway.
#GITREV=$(git rev-parse HEAD)
#function finish {
#	git reset --hard ${GITREV}
#}
#trap finish EXIT

# apply patches
echo "Applying buildbot patches"
git am --signoff ../buildbot/patches/*.patch

echo "Re/Build genie"
make genie
pushd 3rdparty/genie/src
../bin/linux/genie embed >/dev/null
popd
make genieclean >/dev/null
make genie >/dev/null

NPROC=$(getconf _NPROCESSORS_ONLN)
LLIMIT=$(awk 'BEGIN{printf"%.1f",'${NPROC}'/2}')

echo "Build: ${NPROC} jobs, ${LLIMIT} load limit"

echo Windows 32-bit debug version....

make TARGETOS=windows TOOLCHAIN=i686-w64-mingw32.static- TARGET=mame TOOLS=1 SEPARATE_BIN=1 PTR64=0 DEBUG=1 STRIP_SYMBOLS=1 OPTIMIZE=3 SYMBOLS=1 SYMLEVEL=1 REGENIE=1 USE_LIBSDL=1 OSD=sdl SHELLTYPE=posix -j${NPROC} -l${LLIMIT}

echo Windows 32-bit release version....

make TARGETOS=windows TOOLCHAIN=i686-w64-mingw32.static- TARGET=mame TOOLS=1 SEPARATE_BIN=1 PTR64=0 OPTIMIZE=3 SYMBOLS=1 SYMLEVEL=1 REGENIE=1 USE_LIBSDL=1 OSD=sdl SHELLTYPE=posix -j${NPROC} -l${LLIMIT}

echo Windows 64-bit release version....

make TARGETOS=windows TOOLCHAIN=x86_64-w64-mingw32.static- TARGET=mame TOOLS=1 SEPARATE_BIN=1 PTR64=1 OPTIMIZE=3 SYMBOLS=1 SYMLEVEL=1 REGENIE=1 USE_LIBSDL=1 OSD=sdl SHELLTYPE=posix -j${NPROC} -l${LLIMIT}

export MACOSX_DEPLOYMENT_TARGET=10.7
`osxcross-conf`

echo MACOSX 32-bit release version....

make TARGETOS=macosx TOOLCHAIN=i386-apple-darwin11- TARGET=mame TOOLS=1 SEPARATE_BIN=1 PTR64=0 OPTIMIZE=2 REGENIE=1 USE_SYSTEM_LIB_EXPAT=1 USE_SYSTEM_LIB_ZLIB=1 USE_LIBSDL=1 USE_QTDEBUG=0 CLANG_VERSION=3.5.0 ARCHOPTS="-stdlib=libc++ -std=c++1y" SHELLTYPE=posix -j${NPROC} -l${LLIMIT}

echo MACOSX 64-bit release version....

make TARGETOS=macosx TOOLCHAIN=x86_64-apple-darwin11- TARGET=mame TOOLS=1 SEPARATE_BIN=1 PTR64=1 OPTIMIZE=2 REGENIE=1 USE_SYSTEM_LIB_EXPAT=1 USE_SYSTEM_LIB_ZLIB=1 USE_LIBSDL=1 USE_QTDEBUG=0 CLANG_VERSION=3.5.0 ARCHOPTS="-stdlib=libc++ -std=c++1y" SHELLTYPE=posix -j${NPROC} -l${LLIMIT}
