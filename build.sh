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
	../bin/${OS}/genie embed >/dev/null
	popd
	make genieclean >/dev/null
	make genie >/dev/null
fi

echo "Build: ${CPU_COUNT} jobs, ${LOAD_LIMIT} load limit"

if [ "x$1" = "xvs2015" ]; then
	echo "Windows 64-bit master (VS2015):"
	export PreferredToolArchitecture=x64
	export MINGW64=$MINGW_PREFIX
	make TARGET=mame MSBUILD=1 SEPARATE_BIN=1 PTR64=1 vs2015 -j${CPU_COUNT} -l${LOAD_LIMIT}
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
	     -j${CPU_COUNT} -l${LOAD_LIMIT} \
	     | awk 'BEGIN { x = ""; } { if ($1 != x) { print("\n" $0); } else { print("") } x = $1; }' ORS='.'
fi
