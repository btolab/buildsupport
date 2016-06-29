#!/bin/bash
#
# Build MAME for Windows
#

BUILD=(${1//-/ })

source "${BASH_SOURCE%/*}"/support/common.sh || exit 1

# Error out if branch is dirty
if [[ ! -z $(git status --porcelain) ]]; then
    echo "Repository is not clean, aborting."
    exit 1
fi

# apply patches
PATCHED=0
if [ -n "$(find "${SCRIPT_PATH}/patches" -maxdepth 1 -name '*.patch' -prune 2>/dev/null)" ]; then
	echo "Applying buildbot patches"
	git am --signoff "${SCRIPT_PATH}"/patches/*.patch
	PATCHED=1
fi

if [ -n "$(find "${SCRIPT_PATH}/patches/${BUILD[0]}/" -maxdepth 1 -name '*.patch' -prune 2>/dev/null)" ]; then
	echo "Applying buildbot patches (${BUILD[0]})"
	git am --signoff "${SCRIPT_PATH}"/patches/${BUILD[0]}/*.patch
	PATCHED=1
fi

if [ "x{$PATCHED}" = "x1" ]; then
	echo "Re/build genie"
	make genie >/dev/null
	pushd 3rdparty/genie/src
	../bin/${HOSTOS}/genie embed >/dev/null
	popd
	make genieclean >/dev/null
	make genie >/dev/null
fi

echo "Build: ${CPU_COUNT} jobs, ${LOAD_LIMIT} load limit"

if [ "x$1" = "xvs2015" ]; then
	echo "Windows 64-bit master (VS2015):"
	export PreferredToolArchitecture=x64
	export MINGW64=$MINGW_PREFIX
	make TARGET=mame MSBUILD=1 PTR64=1 SEPARATE_BIN=1 vs2015 -j${CPU_COUNT}
elif [ "${BUILD[0]}" = "android" ]; then
	echo "${BUILD[0]} ${BUILD[1]} master (LLVM):"
	make TARGET=mame OPTIMIZE=1 PRECOMPILE=0 SYMBOLS=1 STRIP_SYMBOLS=1 -j${CPU_COUNT} ${BUILD[0]}-${BUILD[1]}
	cd android-project && sh ./gradlew assembleRelease
else
	echo "Windows 64-bit master (GCC):"
	make TARGETOS=windows \
	     TOOLCHAIN=x86_64-w64-mingw32.static- \
	     TARGET=mame \
	     TOOLS=1 \
	     SEPARATE_BIN=1 \
	     STRIP_SYMBOLS=1 \
	     OPTIMIZE=3 \
	     SYMBOLS=1 \
	     SYMLEVEL=1 \
	     REGENIE=1 \
	     SHELLTYPE=posix \
	     PTR64=1 \
	     PRECOMPILE=0 \
	     -j${CPU_COUNT} -l${LOAD_LIMIT}
fi
