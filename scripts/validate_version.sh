#!/bin/bash

# Get the path of the script
SCRIPT_PATH=$(dirname $(realpath -s $0))

# Check for a version number passed by argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 version-number"
    exit 1
fi
    
# Check for the correct format of the version number
if ! [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9\.+:-]*)?$ ]]; then
    echo "ABORT: The version is not in the correct format"
    echo "Please supply the version of the release in the format (0.0.0[-xyz])"
    echo "The version suffix is optional, starts with a digit and may only contain alphanumeric characters and .+-:"
    exit 1
fi

# Parse new version string
MAJOR_VERSION=$(echo $1 | sed -n 's/^\([0-9]\+\)\..*$/\1/p')
MINOR_VERSION=$(echo $1 | sed -n 's/^[0-9]\+\.\([0-9]\+\)\..*$/\1/p')
PATCH_VERSION=$(echo $1 | sed -n 's/^[0-9]\+\.[0-9]\+\.\([0-9]\+\).*$/\1/p')
VERSION_SUFFIX=$(echo $1 | sed -n 's/^[0-9]\+\.[0-9]\+\.[0-9]\+-\(.*\)$/\1/p')

VERSION="$MAJOR_VERSION.$MINOR_VERSION.$PATCH_VERSION"
if [ ! -z $VERSION_SUFFIX ]; then
    VERSION="$VERSION-$VERSION_SUFFIX"
fi

# Parse current version string
CURRENT_MAJOR=$(sed -n 's/^set (CPACK_PACKAGE_VERSION_MAJOR "\([0-9]\+\)")/\1/p' ${SCRIPT_PATH}/../CMakeLists.txt)
CURRENT_MINOR=$(sed -n 's/^set (CPACK_PACKAGE_VERSION_MINOR "\([0-9]\+\)")/\1/p' ${SCRIPT_PATH}/../CMakeLists.txt)
CURRENT_PATCH=$(sed -n 's/^set (CPACK_PACKAGE_VERSION_PATCH "\([0-9]\+\)")/\1/p' ${SCRIPT_PATH}/../CMakeLists.txt)
CURRENT_SUFFIX=$(sed -n 's/^set (VERSION_SUFFIX "-\([^\"]*\)")/\1/p' ${SCRIPT_PATH}/../CMakeLists.txt)


CURRENT_VERSION="$CURRENT_MAJOR.$CURRENT_MINOR.$CURRENT_PATCH"
if [ ! -z $CURRENT_SUFFIX ]; then
    CURRENT_VERSION="$CURRENT_VERSION-$CURRENT_SUFFIX"
fi

if (! printf "%s\n%s" "$CURRENT_VERSION" "$VERSION" | LC_ALL=C sort -CVu ); then
    echo "ABORT: Version is not higher than the current version $CURRENT_VERSION"
    exit 1
fi
