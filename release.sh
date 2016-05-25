#!/bin/bash

source "${BASH_SOURCE%/*}"/support/common.sh || exit 1

RELEASE=$(git describe --tag | sed 's/hbmame//')
LASTVER=$(git describe --tag --abbrev=0 | sed 's/hbmame//')
OUTPATH=`pwd`

echo Begin packaging ${RELEASE} ...

echo Remove old release directories ...
rm -rf build/*/release build/release

# recursively assemble binary packages
for BUILD in $(ls -1d build/*/bin | sed 's/.*\/\(.*\)\/bin$/\1/'); do
	for ARCH in $(ls -1d build/${BUILD}/bin/* | sed 's/.*\/\([^\/]*\)$/\1/'); do
		for TYPE in $(ls -1 build/${BUILD}/bin/${ARCH}); do
			echo Assembling $BUILD $ARCH $TYPE
			RELEASENAME="hbmame-${BUILD}-${ARCH}"
			if [[ ${TYPE} == Debug ]]; then
				RELEASENAME="${RELEASENAME}-debug"
			fi
			RELEASENAME="${RELEASENAME}-${RELEASE}"
			PACKAGEDIR="`pwd`/build/${BUILD}/release/${ARCH}/${TYPE}/package"
			BUILDDIR="`pwd`/build/${BUILD}/bin/${ARCH}/${TYPE}"
			mkdir -p ${PACKAGEDIR}
			pushd ${BUILDDIR}
			#[ -f *.sym ] && cp *.sym ${PACKAGEDIR}/
			find . -executable -type f -exec cp "{}" "${PACKAGEDIR}"/ \;
			popd
			#cp "${SCRIPT_PATH}"/build/whatsnew/whatsnew_${LASTVER}.txt "${PACKAGEDIR}"/whatsnew.txt
			#"${SCRIPT_PATH}"/support/output-changelog-md.sh > "${PACKAGEDIR}"/changelog.txt
			cp -r docs/release/docs/hb*.txt "${PACKAGEDIR}"/
			echo "Hbmame will not work properly without files included with mame.\r\nCopy hbmame into an existing mame installation folder." >> "${PACKAGEDIR}"/HOWTOUSE.txt
			#find language -name '*.mo' -exec cp --parents {} "${PACKAGEDIR}"/ \;
			#7za -y x "${SCRIPT_PATH}"/build/mamedirs.zip -o${PACKAGEDIR}/ >/dev/null
			echo Packaging ${BUILD} ${ARCH} ${TYPE}
			pushd ${PACKAGEDIR}
			if [[ ${BUILD} == mingw* ]] || [[ ${BUILD} == vs* ]]; then
				7za a -mx=9 -y -r -t7z -sfx"${SCRIPT_PATH}"/support/7zWin32.sfx "${OUTPATH}"/${RELEASENAME}.exe >/dev/null
				md5sum "${OUTPATH}"/${RELEASENAME}.exe > "${OUTPATH}"/${RELEASENAME}.md5
			else
				7za a -mpass=4 -mfb=255 -y -r -tzip "${OUTPATH}"/${RELEASENAME}.zip >/dev/null
				md5sum "${OUTPATH}"/${RELEASENAME}.zip > "${OUTPATH}"/${RELEASENAME}.md5
			fi
			popd
		done
	done
done

echo Finished creating release....
