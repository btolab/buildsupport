#!/bin/bash

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

RELEASE=$(git describe --tag --abbrev=0 | sed 's/mame//')

echo Begin packaging SDLMAME ${RELEASE} ...

echo Remove old release directories ...
rm -rf build/*/release
rm -rf build/release

# recursively assemble binary packages
for BUILD in $(ls build/*/bin | grep :\$ | sed 's/.*\/\(.*\)\/bin:$/\1/'); do
	for ARCH in $(ls build/${BUILD}/bin); do
		for TYPE in $(ls build/${BUILD}/bin/${ARCH}); do
			echo Assembling $BUILD $ARCH $TYPE
			RELEASENAME="sdlmame${RELEASE}b"
			if [[ ${ARCH} == x64 ]]; then
				RELEASENAME="${RELEASENAME}_64bit"
			fi
			if [[ ${TYPE} == Debug ]]; then
				RELEASENAME="${RELEASENAME}_debug"
			fi
			PACKAGEDIR="`pwd`/build/${BUILD}/release/${ARCH}/${TYPE}/package"
			BUILDDIR="`pwd`/build/${BUILD}/bin/${ARCH}/${TYPE}"
			mkdir -p ${PACKAGEDIR}
			pushd ${BUILDDIR}
			[ -f *.sym ] && cp *.sym ${PACKAGEDIR}/
			find . -executable -type f -exec cp "{}" ${PACKAGEDIR} \;
			popd
			cp ../build/whatsnew/whatsnew_${RELEASE}.txt ${PACKAGEDIR}/whatsnew.txt
			cp -r docs hash ${PACKAGEDIR}/
			7za x ../build/mamedirs.zip -o${PACKAGEDIR}/ >/dev/null
			echo Packaging ${BUILD} ${ARCH} ${TYPE}
			pushd ${PACKAGEDIR}
			if [[ ${BUILD} == mingw* ]] || [[ ${BUILD} == vs* ]]; then
				7za a -mx=9 -y -r -t7z -sfx7zWin32.sfx ../${RELEASENAME}.exe >/dev/null
			else
				7za a -mpass=4 -mfb=255 -y -r -tzip ../${RELEASENAME}.zip >/dev/null
			fi
			popd
		done
	done
done

#echo Assembling release source ....
#mkdir -p build/release/src
#git archive HEAD | tar -x -C build/release/src
#pushd build/release/src
#echo Creating 7zip self-extracting source archive....
#7za a -mx=9 -y -r -t7z -sfx7zWin32.sfx ../sdlmame${RELEASE}s.exe >/dev/null
#echo Creating raw source ZIP....
#7za a -mx=0 -y -r -tzip ../sdlmame.zip >/dev/null
#echo Creating final source ZIP....
#7za a -mpass=4 -mfb=255 -y -tzip ../sdlmame${RELEASE}s.zip ../sdlmame.zip  >/dev/null
#rm ../sdlmame.zip
#popd

echo Finished creating release....
