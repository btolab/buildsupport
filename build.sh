#!/bin/bash
#
# Build MAME for Windows
#

source "${BASH_SOURCE%/*}"/support/common.sh || exit 1

# Error out if branch is dirty
if [[ ! -z $(git status --porcelain) ]]; then
    echo "Repository is not clean, aborting."
    exit 1
fi

# apply patches
if [ -n "$(find "${SCRIPT_PATH}/patches" -name '*.patch' -prune)" ]; then
	echo "Applying buildbot patches"
	git am --signoff "${SCRIPT_PATH}"/patches/*.patch

	echo "Re/build genie"
	make genie >/dev/null
	pushd 3rdparty/genie/src
	../bin/linux/genie embed >/dev/null
	popd
	make genieclean >/dev/null
	make genie >/dev/null
fi

echo "Build: ${CPU_COUNT} jobs, ${LOAD_LIMIT} load limit"

echo "Windows 32-bit master:"

make TARGETOS=windows TOOLCHAIN=i686-w64-mingw32.static- TARGET=mame TOOLS=1 SEPARATE_BIN=1 STRIP_SYMBOLS=1 OPTIMIZE=3 SYMBOLS=1 SYMLEVEL=1 REGENIE=1 SHELLTYPE=posix PRECOMPILE=0 -j${CPU_COUNT} -l${LOAD_LIMIT} | awk 'BEGIN { x = ""; } { if ($1 != x) { print("\n" $0); } else { print("") } x = $1; }' ORS='.'
