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

SCRIPT_PATH="${BASH_SOURCE[0]}";
if ([ -h "${SCRIPT_PATH}" ]) then
	while([ -h "${SCRIPT_PATH}" ]) do SCRIPT_PATH=`readlink "${SCRIPT_PATH}"`; done
fi
pushd .
cd `dirname ${SCRIPT_PATH}`/.. > /dev/null
SCRIPT_PATH=`pwd`;

if [ -d build ]; then
    pushd build
    git pull
    popd
else
    git clone --depth=1 https://github.com/mamedev/build.git
fi
popd

CPU_COUNT=$(getconf _NPROCESSORS_ONLN)
LOAD_LIMIT=${CPU_COUNT}

OS=linux
if [ "$OS" = "Windows_NT" ]; then
	OS=windows
fi
